using DrWatson, LinearAlgebra
quickactivate(@__DIR__)
include(srcdir("ensemble_routing.jl"))
include(srcdir("load_route_settings.jl"))
include(srcdir("load_weather.jl"))
include(srcdir("load_performance.jl"))


using SailRoute, PyCall, Dates, Plots
unicodeplots()
rh = pyimport("routing_helper")


@time function dev_routing_example(min_dist, ensemble, twa_min, year)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    base_path = "/scratch/td7g11/era5/"
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    quarter = "q1"
    year_str = string(year)
    weather = base_path*"polynesia_"*year_str*"_"*quarter*"/polynesia_"*year_str*"_"*quarter*".nc"
    start_time = Dates.DateTime(year, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    tws, twa, perf = rh.generate_canoe_performance(twa_min, tws_speeds, 0.3, 1.0)
    polar = SailRoute.setup_perf_interpolation(tws, twa, perf)
    res = SailRoute.typical_aerrtsen()
    sample_perf = SailRoute.Performance(polar, 1.0, 1.0, res);
    results = SailRoute.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    println("twa_min = ", twa_min, " dist = ", min_dist, " ens = ", ensemble, " vt = ", results[1])
    return results[1], results[2], results[3], x, y
end


@time function dev_comparison_sims(min_dist, ensemble, year)
    # lon1 = -171.75
    # lat1 = -13.917
    # lon2 = -158.07
    # lat2 = -19.
    lat1, lon1 = -18.65, -173.98
    lat2, lon2 = -13.91, -171.75
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    base_path = "/scratch/td7g11/era5/"
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    quarter = "q1"
    year_str = string(year)
    weather = base_path*"polynesia_"*year_str*"_"*quarter*"/polynesia_"*year_str*"_"*quarter*".nc"
    start_time = Dates.DateTime(year, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    display(scatter(x, y, title="Grid generation example, min_dist = "*string(min_dist)))
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])
    # polar = load_boeckv2()
    polar =  load_tong()
    res = SailRoute.typical_aerrtsen()
    sample_perf = SailRoute.Performance(polar, 1.0, 1.0, res);
    results = SailRoute.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    return results[1], results[2], results[3], x, y
end


function investigate_performance_variation(n, min_dist, min_twa)
    save_paths, settings = vary_performance()
    times = [DateTime(t) for t in settings[n][1]]
    nodes = SailRoute.calc_nodes(settings[n][4], settings[n][5], settings[n][6], settings[n][7], min_dist)
    start_lat, start_lon = -18.65, -173.98
    finish_lat, finish_lon = -13.91, -171.75
    route = SailRoute.Route(start_lon, start_lat, finish_lon, finish_lat, nodes, nodes)
    start_time = times[n]
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(settings[n][2], settings[n][9])
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    scatter(x, y)
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])    
    start_time_idx = SailRoute.time_to_index(start_time, times)
    earliest_times = fill(Inf, size(x))
    prev_node = zero(x)
    node_indices = reshape(1:length(x), size(x))
    arrival_time = Inf
    final_node = 0
    idx_range = size(x)[2]
    idy_range = size(x)[1]
    performance = settings[n][3][1]
    @simd for idx in 1:idx_range
        d, b = SailRoute.haversine(route.lon1, route.lat1, x[1, idx], y[1, idx])
        wd_int = widi[start_time_idx, idx, 1]
        ws_int = wisp[start_time_idx, idx, 1]
        cs_int = cusp[start_time_idx, idx, 1]
        cd_int = cudi[start_time_idx, idx, 1]
        wadi_int = wadi[start_time_idx, idx, 1]
        wahi_int = wahi[start_time_idx, idx, 1]
        speed = SailRoute.cost_function(performance, cd_int, cs_int,
                                        wd_int, ws_int,
                                        wadi_int, wahi_int, b)
        earliest_times[1, idx] = d/speed
    end
    for idy in 1:idy_range-1
        for idx1 in 1:idx_range
            if isinf(earliest_times[idy, idx1]) == false
                t = start_time + SailRoute.convert_time(earliest_times[idy, idx1])
                t_idx = SailRoute.time_to_index(t, times)
                wd_int = widi[t_idx, idx1, idy]
                ws_int = wisp[t_idx, idx1, idy]
                wadi_int = wadi[t_idx, idx1, idy]
                wahi_int = wahi[t_idx, idx1, idy]
                cs_int = cusp[t_idx, idx1, idy]
                cd_int = cudi[t_idx, idx1, idy]
                @simd for idx2 in 1:idx_range
                    d, b = SailRoute.haversine(x[idy, idx1], y[idy, idx1],
                                        x[idy+1, idx2], y[idy+1, idx2])
                    speed = SailRoute.cost_function(performance, cd_int, cs_int,
                                                    wd_int, ws_int, wadi_int, wahi_int, b)
                    # @show speed, wd_int, ws_int
                    tt = earliest_times[idy, idx1] + d/speed
                    if earliest_times[idy+1, idx2] > tt
                        earliest_times[idy+1, idx2] = tt
                        prev_node[idy+1, idx2] = node_indices[idy, idx1]
                    end
                end
            end
        end
    end
    
    @simd for idx in 1:idx_range
        if isinf(earliest_times[end, idx]) == false
            d, b = SailRoute.haversine(x[end, idx], y[end, idx], route.lon2, route.lat2)
            t = start_time + SailRoute.convert_time(earliest_times[end, idx])
            t_idx = SailRoute.time_to_index(t, times)
            wd_int = widi[t_idx, idx, end]
            ws_int = wisp[t_idx, idx, end]
            wadi_int = wadi[t_idx, idx, end]
            wahi_int = wahi[t_idx, idx, end]
            cs_int = cusp[t_idx, idx, end]
            cd_int = cudi[t_idx, idx, end]
            speed = SailRoute.cost_function(performance, cd_int, cs_int,
                                wd_int, ws_int, wadi_int, wahi_int, b)
            tt = earliest_times[end, idx] + d/speed
            if arrival_time > tt
                arrival_time = tt
                final_node = node_indices[end, idx]
            end
        end
    end
    sp = SailRoute.shortest_path(node_indices, prev_node, [final_node])
    locs = SailRoute.get_locs(node_indices, sp, x, y)
    x_path = vcat([start_lon], locs[:, 1], [finish_lon])
    y_path = vcat([start_lat], locs[:, 2], [finish_lat])
    locs = hcat(x_path, y_path)
    return arrival_time, locs, earliest_times
end


function compare_grid_generation(min_dist)
    # start_lat, start_lon = -18.65, -173.98
    # finish_lat, finish_lon = -13.91, -171.75
    start_lon = -171.75
    start_lat = -13.917
    start_lon = -158.07
    finish_lat = -19.59
    # start_lat, start_lon = 0.0, 0.0
    # finish_lat, finish_lon = 0.0, 10.0
    nodes = SailRoute.calc_nodes(start_lon, start_lat, finish_lon, finish_lat, min_dist)
    route = SailRoute.Route(start_lon, start_lat, finish_lon, finish_lat, nodes, nodes)
    grid_x, grid_y = generate_grid_euc(route.lon1, route.lon2, route.lat1, route.lat2, route.x_nodes)
    scatter(grid_x, grid_y, title="Grid generation example, min_dist = "*string(min_dist))
    scatter!([start_lon], [start_lat])
    display(scatter!([finish_lon],[finish_lat]))
end

# arrival_time, locs, earliest_times = investigate_performance_variation(1, 100, 60.0)
# display(plot!(locs[:, 1], locs[:, 2], title="Vt = "*string(arrival_time/24.0)))
for i in LinRange(100.0, 10.0, 10)
    # compare_grid_generation(i)
    # arrival_time, locs, earliest_times, x, y = dev_comparison_sims(i, 1, 2004)
    # scatter(x, y)
    # display(plot!(locs[:, 1], locs[:, 2], title="Vt = "*string(arrival_time/24.0)))
    arrival_time, locs, earliest_times, x, y = dev_routing_example(i, 1, 40.0, 2004)
    scatter(x, y)
    display(plot!(locs[:, 1], locs[:, 2], title="Vt = "*string(arrival_time/24.0)))
end