# using Distributed, ParallelDataTransfer
# @everywhere begin
using DrWatson, Plots
unicodeplots()
# quickactivate(pwd()*"/")
include(srcdir()*"/ensemble_routing.jl")
include(srcdir()*"/load_route_settings.jl")
include(srcdir()*"/load_weather.jl")
include(srcdir()*"/load_performance.jl")


"""Generate simulation settings to study the influence of discretization on simulation results."""
function vary_performance()
    t_inc = 72
    min_dist = 30.0
    ensemble = 1
    save_path = datadir()*"/discretization/"
    perfs, perf_names = generate_canoe_performance_types()
    weather_base_path = "/scratch/td7g11/era5/"
    weather_paths = [weather_base_path*"polynesia_1997_q1/polynesia_1997_q1.nc",
                        weather_base_path*"polynesia_1997_q2/polynesia_1997_q2.nc"]
    weather_names = ["1997_q1",
                        "1997_q2"]
    weather_times = [Dates.DateTime(1997, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 3, 31, 0, 0, 0),
                        Dates.DateTime(1997, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 6, 30, 0, 0, 0)]
    start_lon = -175.15
    start_lat = -21.21
    finish_lon = -149.42
    finish_lat = -17.67
    route_name = "Tongatapu_Tahiti"
    save_paths = []
    settings = []
    for p in eachindex(perfs)
        for w in eachindex(weather_times)
            fname = save_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*route_name*"_ensemble_"*string(ensemble)*"_"*string(min_dist)
            push!(save_paths, fname)
            setting = [weather_times[w], weather_paths[w], perfs[p], start_lon, finish_lon, start_lat, finish_lat, min_dist, ensemble]
            push!(settings, setting)
        end 
    end
    println(length(settings))
    return save_paths, settings
end
# end


function discretization_study(min_dist, ensemble, year)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    save_path = "discretization/"*string(min_dist)*"_"*string(ensemble)*"_"*string(year)
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    base_path = "/scratch/td7g11/era5/"
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    quarter = "q2"
    year_str = string(year)
    weather = base_path*"polynesia_"*year_str*"_"*quarter*"/polynesia_"*year_str*"_"*quarter*".nc"
    start_time = Dates.DateTime(year, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])
    polar =  load_tong()
    res = SailRoute.typical_aerrtsen()
    sample_perf = SailRoute.Performance(polar, 1.0, 1.0, res);
    results = SailRoute.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
    h5open(datadir()*"/"*save_path*".h5", "w") do file
        write(file, "journey_times", results[1])
        write(file, "shortest_path", results[2])
        write(file, "earliest_times", results[3])
    end
    @show results[1]
    plot(results[2][:, 1], results[2][:, 2])
end


function run_discretization_study()
    min_dists = [75.0, 15.0, 10.0]
    for dm in min_dists
        discretization_study(dm, 1, 2010)
    end
end

run_discretization_study()