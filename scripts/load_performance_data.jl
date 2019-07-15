using CSV

"""Generate the parameters to simulate for Polynesian colonisation voyages."""
function generate_colonisation_voyage_settings()
    start_locations_lat = [-13.917, -21.21]
    start_locations_lon = [-171.75, -175.15]
    finish_locations_lat = [-19.59, -17.53]
    finish_locations_lon = [-158.07, -149.83]
    start_location_names = ["upolu", "tongatapu"]
    finish_location_names = ["atiu", "moorea"]
    boat_performance = [load_tong(), load_boeckv2()]
    boat_performance_names = ["/tongiaki/", "/boeckv2/"]
    t_inc = 72
    month = 4
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 4, 1, 0, 0, 0)
    t_mid = Dates.DateTime(1985, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1985, 4, 1, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 4, 1, 0, 0, 0)
    weather_times = [t_low, t_mid, t_high]
    weather_names = ["low", "mid", "high"]
    weather_paths = [ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/polynesia_1976.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/med/1985/polynesia_1985.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/polynesia_1982.nc"]
    node_spacings = [20.0, 15.0, 12.5, 10.0] # 96 simulations
    simulation_settings = []
    save_paths = []
    for i in node_spacings
        for j in eachindex(start_location_names)
            for k in eachindex(finish_location_names)
                for l in eachindex(weather_names)
                    for m in eachindex(boat_performance_names)
                        push!(simulation_settings, [i, start_locations_lon[j], finish_locations_lon[k],
                                                    start_locations_lat[j], finish_locations_lat[k],
                                                    weather_paths[l], weather_times[l],
                                                    boat_performance[m]])
                        route_name = start_location_names[j]*"_to_"*finish_location_names[k]
                        path = boat_performance_names[m]*"_routing_"*route_name*"_"*repr(weather_times[l][1])*"_to_"*repr(weather_times[l][end])*"_"*repr(i)*"_nm.txt"
                        push!(save_paths, path)
                    end
                end
            end
        end
    end
    return simulation_settings, save_paths
end




"""Parameters to simulate early voyages."""
function generate_early_voyaging_settings()
    start_locations_lat = [-9.467, -17.733, -18.167, 13.917, -21.21]
    start_locations_lon = [-159.817, -168.317, -178.45, -171.75, -175.15]
    finish_locations_lat = [-17.733, -18.167, -13.917, -21.21]
    finish_locations_lon = [-168.317, -178.45, -171.75, -175.15]
    start_location_names = ["solomons", "vanuatu", "fiji", "fiji"]
    finish_location_names = ["vanuatu", "fiji", "upolu", "tonga"]nclude("performance/polar.jl")
    boat_performance = [load_tong(), load_boeckv2()]  #need to change this line here 
    boat_performance_names = ["/tongiaki/", "/boeckv2/"]
    t_inc = 6
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 12, 31, 0, 0, 0)
    t_mid = Dates.DateTime(1985, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1985, 12, 31, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 12, 31, 0, 0, 0)
    weather_times = [t_low, t_mid, t_high]
    weather_names = ["low", "mid", "high"]
    weather_paths = [ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/polynesia_1976.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/med/1985/polynesia_1985.nc",
                     ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/polynesia_1982.nc"]
    node_spacings = [20.0, 15.0, 12.5, 10.0]
    simulation_settings = []
    save_paths = []
    for i in eachindex(node_spacings)
        for j in eachindex(start_location_names)
            for l in eachindex(weather_names)
                for m in eachindex(boat_performance_names)
                    push!(simulation_settings, [node_spacings[i], start_locations_lon[j], finish_locations_lon[j],
                                                start_locations_lat[j], finish_locations_lat[j],
                                                weather_paths[l], weather_times[l],
                                                boat_performance[m]])
                    route_name = start_location_names[j]*"_to_"*finish_location_names[j]
                    path = boat_performance_names[m]*"_routing_"*route_name*"_"*repr(weather_times[l][1])*"_to_"*repr(weather_times[l][end])*"_"*repr(node_spacings[i])*"_nm.txt"
                    push!(save_paths, path)
                end
            end
        end
    end
    return simulation_settings, save_paths
end
