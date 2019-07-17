# run simulations to compare the performance of seafaring technology

using Distributed, ParallelDataTransfer
@everywhere begin
    using DrWatson
    quickactivate(pwd()*"/")
    include(srcdir()*"ensemble_routing.jl")
    include(srcdir()*"load_route_settings.jl")
    include(srcdir()*"load_weather.jl")
    include(srcdir()*"load_performance.jl")


    """Generate simulations to compare Tongiaki and Outrigger designs."""
    function generate_comparison_simulations()
        t_inc = 120
        min_dist = 40.0
        base_path = datadir()*"sims/comparison/"
        perf_names = ["simulations"]
        res = SailRoute.typical_aerrtsen()
        perfs = [[SailRoute.Performance(load_tong(), 1.0, 1.0, res), 
                SailRoute.Performance(load_boeckv2(), 1.0, 1.0, res)]];
        weather_paths, weather_names, weather_times = generate_full_weather_scenarios(t_inc)
        start_loc_names, finish_loc_names, start_lat, start_lon, finish_lat, finish_lon = generate_route_settings()
        settings = []
        save_paths = []
        for loc in eachindex(start_loc_names)
            for w in eachindex(weather_times)
                for p in eachindex(perfs)
                    for ensemble_no = 0:9
                        save_path = base_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*start_loc_names[loc]*"_"*finish_loc_names[loc]*"_ensemble_"*string(ensemble_no)*"_"*string(min_dist)
                        push!(save_paths, save_path)
                        setting = [weather_times[w], weather_paths[w], perfs[p], start_lon[loc], finish_lon[loc], start_lat[loc], finish_lat[loc], min_dist, ensemble_no]
                        push!(settings, setting)
                    end
                end
            end
        end
        println("Total number of settings: ", length(save_paths))
        return save_paths, settings
    end
end


"""
    run_ensemble_simulations(n)

Function to iterate over all the provided simulation settings.
"""
function run_ensemble_simulations(n)
    n += 0
    save_paths, settings = generate_comparison_simulations()
    sendto(workers(), save_paths=save_paths)
    sendto(workers(), settings=settings)
    parallized_ensemble_weather_routing(save_paths[n], settings[n][1], settings[n][2],
                                        settings[n][3], settings[n][4], settings[n][5], settings[n][6],
                                        settings[n][7], settings[n][8], settings[n][9])
end


# # comment out these lines if running from bash script
if isempty(ARGS) == false
   @show i = parse(Int64, ARGS[1]); sendto(workers(), i=i)
end
#
#i = 1; sendto(workers(), i=i)
#
#interrogate_ensemble_parallization(i)
# run_ensemble_simulations(i)