# run simulation for range of performances for a single weather condition for a single route

using Distributed
@everywhere begin
    using DrWatson
    quickactivate(@__DIR__, "routing_analysis")
    include(srcdir()*"ensemble_routing.jl")
    include(srcdir()*"load_route_settings.jl")
    include(srcdir()*"load_weather.jl")
    include(srcdir()*"load_performance.jl")

    function vary_performance()
        t_inc = 48
        min_dist = 40.0
        ensemble = 1
        save_path = datadir()*"sims/vary_perf/"
        perfs, perf_names = generate_performance_types()
        weather_base_path = "/scratch/td7g11/era5/"
        weather_paths = [weather_base_path*"polynesia_2010_q1/polynesia_2010_q1.nc",
                         weather_base_path*"polynesia_2010_q2/polynesia_2010_q2.nc"]
        weather_names = ["2010_q1",
                         "2010_q2"]
        weather_times = [Dates.DateTime(2010, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 3, 31, 0, 0, 0),
                         Dates.DateTime(2010, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 6, 30, 0, 0, 0)]
        start_lon = -175.15
        start_lat = -21.21
        finish_lon = -149.42
        finish_lat = -17.67
        route_name = "Tongatapu_Tahiti"
        save_paths = []
        settings = []
        for p in eachindex(perfs)
            for w in eachindex(weather_times)
                save_path = save_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*route_name*"_ensemble_"*string(ensemble)*"_"*string(min_dist)
                push!(save_paths, save_path)
                setting = [weather_times[w], weather_paths[w], perfs[p], start_lon, finish_lon, start_lat, finish_lat, min_dist, ensemble]
                push!(settings, setting)
            end 
        end
        return save_paths, settings
    end
end


function run_ensemble_simulations(n)
    n += 0
    save_paths, settings = vary_performance()
    sendto(workers(), save_paths=save_paths)
    sendto(workers(), settings=settings)
    parallized_ensemble_weather_routing(save_paths[n], settings[n][1], settings[n][2], settings[n][3], settings[n][4], settings[n][5], settings[n][6], settings[n][7], settings[n][8], settings[n][9])
end

if isempty(ARGS) == false
    @show i = parse(Int64, ARGS[1]); sendto(workers(), i=i)
end

run_ensemble_simulations(i)
