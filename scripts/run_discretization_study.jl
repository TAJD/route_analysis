# run simulations to compare the performance of seafaring technology

using Distributed, ParallelDataTransfer
@everywhere begin
    using DrWatson
    quickactivate(pwd()*"/")
    include(srcdir("ensemble_routing.jl"))
    include(srcdir("load_route_settings.jl"))
    include(srcdir("load_weather.jl"))
    include(srcdir("load_performance.jl"))


    """Generate simulations to compare Tongiaki and Outrigger designs."""
    function generate_discretization_simulations(min_dist)
        t_inc = 24
        base_path = datadir()*"/sims/comparison/discretization/"
        perf_names = ["simulations"]
        res = SailRoute.typical_aerrtsen()
        perfs = [[SailRoute.Performance(load_boeckv2(), i, 1.0, res) for i in LinRange(0.5, 1.5, 21)]];
        weather_paths, weather_names, weather_times = generate_full_weather_scenarios(t_inc)
        start_loc_names, finish_loc_names, start_lat, start_lon, finish_lat, finish_lon = generate_route_settings()
        settings = []
        save_paths = []
        ensemble_no = 0
        for loc in eachindex(start_loc_names)
            for w in eachindex(weather_times)
                for p in eachindex(perfs)
                    save_path = base_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*start_loc_names[loc]*"_"*finish_loc_names[loc]*"_ensemble_"*string(ensemble_no)*"_"*string(min_dist)*"_"*string(t_inc)
                    push!(save_paths, save_path)
                    setting = [weather_times[w], weather_paths[w], perfs[p], start_lon[loc], finish_lon[loc], start_lat[loc], finish_lat[loc], min_dist, ensemble_no]
                    push!(settings, setting)
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
function run_discretization_simulations(min_dist)
    save_paths, settings = generate_discretization_simulations(min_dist)
    sendto(workers(), save_paths=save_paths)
    sendto(workers(), settings=settings)
    n = 1
    parallized_ensemble_weather_routing(save_paths[n], settings[n][1], settings[n][2],
                                        settings[n][3], settings[n][4], settings[n][5], settings[n][6],
                                        settings[n][7], settings[n][8], settings[n][9])
end


# # comment out these lines if running from bash script
if isempty(ARGS) == false
   @show min_dist = parse(Float64, ARGS[1]); sendto(workers(), min_dist=min_dist)
end
#
#i = 1; sendto(workers(), i=i)
#
run_discretization_simulations(min_dist)
