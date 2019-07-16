using DrWatson
quickactivate(@__DIR__, "routing_analysis")
include(srcdir("ensemble_routing.jl"))
include(srcdir("load_route_settings.jl"))
include(srcdir("load_weather.jl"))
include(srcdir("load_performance.jl"))


using SailRoute, PyCall, Dates, Interpolations, Statistics, Formatting, StatsBase, UnicodePlots, BenchmarkTools
rh = pyimport("routing_helper")


function dev_routing_example(min_dist, ensemble)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = sail_route.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    base_path = "/scratch/td7g11/era5/"
    route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
    quarter = "q2"
    year = "2005"
    weather = base_path*"polynesia_"*year*"_"*quarter*"/polynesia_"*year*"_"*quarter*".nc"
    start_time = Dates.DateTime(2005, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = sail_route.return_current_vectors(y, dims[1])
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    tws, twa, perf = rh.generate_circular_performance(90.0, tws_speeds, 0.3)
    polar = sail_route.setup_perf_interpolation(tws, twa, perf)
    res = sail_route.typical_aerrtsen()
    sample_perf = sail_route.Performance(polar, 1.0, 1.0, res);
    results = sail_route.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    lineplot(results[2][:, 1], results[2][:, 2])
    println(results[1])
end


function dev_routing_example(min_dist, ensemble, twa_min)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    base_path = "/scratch/td7g11/era5/"
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    quarter = "q2"
    year = "2005"
    weather = base_path*"polynesia_"*year*"_"*quarter*"/polynesia_"*year*"_"*quarter*".nc"
    start_time = Dates.DateTime(2005, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = SailRoute.return_current_vectors(y, dims[1])
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    tws, twa, perf = rh.generate_canoe_performance(twa_min, tws_speeds, 0.3, 1.0)
    polar = SailRoute.setup_perf_interpolation(tws, twa, perf)
    res = SailRoute.typical_aerrtsen()
    sample_perf = SailRoute.Performance(polar, 1.0, 1.0, res);
    results = SailRoute.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    println("twa_min = ", twa_min, " dist = ", min_dist, " ens = ", ensemble, " vt = ", results[1])
    return results
end


function investigate_performance_variation(n, min_dist, min_twa)
    save_paths, settings = vary_performance()
    times = [DateTime(t) for t in settings[n][1]]
    nodes = SailRoute.calc_nodes(settings[n][4], settings[n][5], settings[n][6], settings[n][7], min_dist)
    route = SailRoute.Route(settings[n][4], settings[n][5], settings[n][6], settings[n][7], nodes, nodes)
    start_time = times[n]
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(settings[n][2], settings[n][9])
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = SailRoute.return_current_vectors(y, dims[1])    
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
    return arrival_time, locs, earliest_times
end

