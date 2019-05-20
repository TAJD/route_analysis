using DrWatson
using sail_route, PyCall, Dates
rh = pyimport("routing_helper")

function load_era5_ensemble(path_nc, ens)
        wisp, widi, wh, wd, wp, time_values = rh.retrieve_era5_ensemble(path_nc, ens)
    time = [Dates.unix2datetime(Int64(i)) for i in time_values]
    return wisp, widi, wh, wd, wp, time
end



base_path = "/scratch/td7g11/era5/"
weather = base_path*"polynesia_2004_q1/polynesia_2004_q1.nc"
ensemble = 0
wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
# x, y, wisp, widi, wadi, wahi = sail_route.generate_inputs(route, wisp, widi, wadi, wahi)
