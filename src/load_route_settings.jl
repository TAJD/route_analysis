
function generate_route_settings()
    start_loc_names = ["Vavau", "Tongatapu"]
    finish_loc_names = ["Upolu", "Tahiti"]
    start_lat = [-18.65, -21.21]
    start_lon = [-173.98, -175.15]
    finish_lat = [-13.91, -17.67]
    finish_lon = [-171.75, -149.42]
    return start_loc_names, finish_loc_names, start_lat, start_lon, finish_lat, finish_lon
end

function samoa_aituitaki_settings()
    start_loc_names = ["Samoa"]
    finish_loc_names = ["Aituitaki"]
    start_lon = [360-171.75]
    start_lat = [-13.6]
    finish_lon = [360-159.79]
    finish_lat = [-18.85]
    return start_loc_names, finish_loc_names, start_lat, start_lon, finish_lat, finish_lon
end

