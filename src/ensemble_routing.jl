using Distributed
@everywhere begin
    using DrWatson
    using sail_route
    using ParallelDataTransfer
    using BenchmarkTools
    using Printf
    using Dates
    using CSV
    using DataFrames
    using SharedArrays
    using HDF5
    println("packages loaded")
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
        n = sail_route.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
        results = SharedArray{Float64, 2}(n_time, n_perfs)
        x_results = SharedArray{Float64, 3}(n_time, n_perfs, n)
        y_results = SharedArray{Float64, 3}(n_time, n_perfs, n)
        et_results = SharedArray{Float64, 4}(n_time, n_perfs, n, n)
        wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era5_ensemble(weather, ensemble)
        x, y, wisp, widi, wadi, wahi = sail_route.generate_inputs(route, wisp, widi, wadi, wahi)
        dims = size(wisp)
        cusp, cudi = sail_route.return_current_vectors(y, dims[1])
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
end

