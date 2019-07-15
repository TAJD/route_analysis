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


function investigate_performance_variation(n, min_dist)
    save_paths, settings = vary_performance()
    sim_times = [DateTime(t) for t in settings[n][1]]
    n_time = length(sim_times)
    n_perfs = length(settings[n][3])
    nodes = SailRoute.calc_nodes(settings[n][4], settings[n][5], settings[n][6], settings[n][7], min_dist)
    route = SailRoute.Route(settings[n][4], settings[n][5], settings[n][6], settings[n][7], nodes, nodes)
    start_time = sim_times[1]
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(settings[n][2], settings[n][9])
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = SailRoute.return_current_vectors(y, dims[1])    
    start_time_idx = SailRoute.time_to_index(start_time, sim_times)
    earliest_times = fill(Inf, size(x))
    prev_node = zero(x)
    node_indices = reshape(1:length(x), size(x))
    arrival_time = Inf
    final_node = 0
    earliest_times = fill(Inf, size(x))
    idx_range = size(x)[2]
    idy_range = size(x)[1]
    @simd for idx in 1:idx_range
        d, b = SailRoute.haversine(route.lon1, route.lat1, x[1, idx], y[1, idx])
        wd_int = widi[start_time_idx, idx, 1]
        ws_int = wisp[start_time_idx, idx, 1]
        cs_int = cusp[start_time_idx, idx, 1]
        cd_int = cudi[start_time_idx, idx, 1]
        wadi_int = wadi[start_time_idx, idx, 1]
        if isnan(wadi_int) == true
            wadi_int = cd_int
        end
        wahi_int = wahi[start_time_idx, idx, 1]
        if isnan(wahi_int) == true
            wahi_int = 0.0
        end

        speed = SailRoute.cost_function(settings[n][3][1], cd_int, cs_int,
                                        wd_int, ws_int, wadi_int, wahi_int, b)
        @show speed, wd_int, ws_int
        if speed >= 0.0
            earliest_times[1, idx] = d/speed
        end
    end
    # return results
    earliest_times
end

