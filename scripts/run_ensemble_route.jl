# load and run ensemble routing analysis
using Distributed
@everywhere begin
    using DrWatson
    quickactivate(@__DIR__, "routing_analysis")
    include(srcdir()*"ensemble_routing.jl")
    include(srcdir()*"load_route_settings.jl")
    include(srcdir()*"load_weather.jl")

    function test_dev_process()
        t_inc = 48
        min_dist = 50.0
        perfs, perf_names = sail_route.generate_performance_types()
        println(perfs)
    end
    test_dev_process()
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
