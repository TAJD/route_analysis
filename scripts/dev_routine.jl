using DrWatson
quickactivate(@__DIR__, "routing_analysis")
include(srcdir()*"ensemble_routing.jl")
include(srcdir()*"load_route_settings.jl")
include(srcdir()*"load_weather.jl")
include(srcdir()*"load_performance.jl")


using sail_route, PyCall, Dates, Interpolations, Statistics, Formatting, StatsBase, UnicodePlots, BenchmarkTools
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
    @show weather
    @show mean(wisp)
    @show mean(widi)
    @show mean(wahi)
    @show mean(wadi)
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


#for i = 1:10
@time dev_routing_example(100.0, 1)
@time dev_routing_example(50.0, 1)
#@time dev_routing_example(40.0, 1)
#@time dev_routing_example(30.0, 1)
#@time dev_routing_example(20.0, 1)
#@time dev_routing_example(10.0, 1)
#end

