# load and run ensemble routing analysis
using Distributed
@everywhere begin
    using DrWatson
    quickactivate(@__DIR__, "routing_analysis")
    include(srcdir("ensemble_routing.jl"))
    include(srcdir("load_route_settings.jl"))
    include(srcdir("load_weather.jl"))
    include(srcdir("load_performance.jl"))


    """ 
        generate_complete_settings

    Generate a list of complete settings from the constituent smaller lists of settings.
    """
    function generate_complete_settings()
        min_dist = 40.0 # 20.0
        t_inc = 48  # 24
        base_path = datadir()*"sims/"
        perfs, perf_names = generate_performance_types()
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


        """Test the running of ensemble simulations in parallel.

    Ensembles are iterated over in series. To make it parallel the ensemble would need to be included within the settings.
        """
        function test_ensembles_parallized(n)
            t_inc = 48
            min_dist = 50.0
        perfs, perf_names = sail_route.generate_performance_types()
        weather_paths, weather_names, weather_times = generate_weather_scenarios(48)
        start_loc_names, finish_loc_names, start_lat, start_lon, finish_lat, finish_lon = generate_route_settings()
        sendto(workers(), n=n, times = weather_times[n],
               weather_path = weather_paths[n],
               perf = perfs)
        sendto(workers(), lon1 = start_lon[n], lon2 = finish_lon[n],
                         lat1 = start_lat[n], lat2 = finish_lat[n])
        base_path = ENV["HOME"]*"/sail_route_old/development/polynesian/ensemble_testing/trial_results/"
        sendto(workers(), min_dist=min_dist)
        for ensemble_no = 0:9
            save_path = base_path*"_"*weather_names[n]*"_"*perf_names[n]*"_"*start_loc_names[n]*"_"*finish_loc_names[n]*"_ensemble_"*string(ensemble_no)
            println(save_path)
            sendto(workers(), save_path=save_path)
            parallized_ensemble_weather_routing(save_path, weather_times[n], weather_paths[n], perfs, start_lon[n], finish_lon[n], start_lat[n], finish_lat[n], min_dist, ensemble_no)
        end
    end
    # test_ensembles_parallized(10.0)
end


"""
    interrogate_ensemble_parallization(n)

Function to print the input settings to parallization routine.
"""
function interrogate_ensemble_parallization(n)
    save_paths, settings = generate_complete_settings()
    sendto(workers(), save_paths=save_paths)
    sendto(workers(), settings=settings)
    println("Save path; ", save_paths[n])
    println("1, weather times ", size(settings[n][1]))
    println("2, weather_paths ", settings[n][2])
    println("3, perfs ", size(settings[n][3]))
    println("4, start_lon ", size(settings[n][4]))
    println("5, finish_lon ", size(settings[n][5]))
    println("6, start_lat ", size(settings[n][6]))
    println("7, finish_lat ", size(settings[n][7]))
    println("8, min_dist ", size(settings[n][8]))
    println("9, ensemble_no ", size(settings[n][9]))
end


"""
    run_ensemble_simulations(n)

Function to iterate over all the provided simulation settings.
"""
function run_ensemble_simulations(n)
    n += 0
    save_paths, settings = generate_complete_settings()
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
run_ensemble_simulations(i)
