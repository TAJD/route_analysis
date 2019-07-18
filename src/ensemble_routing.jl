using SailRoute
using ParallelDataTransfer
using Dates
using CSV
using DataFrames
using SharedArrays
using HDF5

# """Create a custom iterator which breaks up a range based on the processor number, return split along dimension 2"""
# function myrange(q::SharedArray) 
#     @show idx = indexpids(q)
#     if idx == 0 # This worker is not assigned a piece
#         return 1:0, 1:0
#     end
#     nchunks = length(procs(q))
#     splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
#     1:size(q,1), splits[idx]+1:splits[idx+1]
# end


"""Create a custom iterator which breaks up a range based on the processor number, return split along dimension 1"""
function myrange(q::SharedArray) 
    @show idx = indexpids(q)
    if idx == 0 # This worker is not assigned a piece
        return 1:0, 1:0
    end
    nchunks = length(procs(q))
    splits = [round(Int, s) for s in range(0, stop=size(q,1), length=nchunks+1)]
    splits[idx]+1:splits[idx+1], 1:size(q,2)
end

function route_solve_save_path_chunk!(results, t_range, p_range, 
                                        sim_times, perfs, 
                                        x_results, y_results, et_results,
                                        route, time_indexes, x, y,
                                        wisp, widi, wadi, wahi, cusp, cudi)
    @show t_range, p_range
    for t in t_range, p in p_range
        output = SailRoute.route_solve(route, perfs[p], sim_times[t],                                         time_indexes, x, y,
                                        wisp, widi, wadi, wahi, cusp, cudi)
        if isinf(output[1]) == true
            @show output[1]
            continue
        else 
            @show results[t, p] = output[1]
            x_results[t, p, :] = output[2][:, 1]
            y_results[t, p, :] = output[2][:, 2]
            et_results[t, p, :, :] = output[3]
            output = nothing
        end
    end
end


route_solve_shared_sp_chunk!(results, sim_times, perfs, x_results, y_results, et_results, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi) = route_solve_save_path_chunk!(results, myrange(results)..., sim_times, perfs, x_results, y_results, et_results, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)


    """
    parallized_ensemble_weather_routing(save_path, times, weather, perfs,
                                        lon1, lon2, lat1, lat2,
                                        min_dist, ensemble)


"""
function parallized_ensemble_weather_routing(save_path, times,
                                                weather, perfs,
                                                lon1, lon2, lat1, lat2,
                                                min_dist, ensemble)
    sim_times = [DateTime(t) for t in times]
    n_time = length(sim_times)
    n_perfs = length(perfs)
    results = SharedArray{Float64, 2}(n_time, n_perfs)
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    results = SharedArray{Float64, 2}(n_time, n_perfs)
    x_results = SharedArray{Float64, 3}(n_time, n_perfs, n)
    y_results = SharedArray{Float64, 3}(n_time, n_perfs, n)
    et_results = SharedArray{Float64, 4}(n_time, n_perfs, n, n)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])
    @sync begin
        @show for p in procs(results)
            @async remotecall_wait(route_solve_shared_sp_chunk!, p, results,
                                    times, perfs, x_results, y_results, et_results, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
        end
    end
    unix_times = [datetime2unix(t) for t in sim_times]
    println(save_path)
    println(results)
    h5open(save_path*".h5", "w") do file
        write(file, "start_times", unix_times)
        write(file, "journey_times", results)
        write(file, "x_results", x_results)
        write(file, "y_results", y_results)
        write(file, "et_results", et_results)
        write(file, "x_locations", x)
        write(file, "y_locations", y)
    end
end