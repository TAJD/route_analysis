using DrWatson
using sail_route, PyCall, Dates, Interpolations
rh = pyimport("routing_helper")

function load_era5_ensemble(path_nc, ens)
        wisp, widi, wh, wd, wp, time_values = rh.retrieve_era5_ensemble(path_nc, ens)
    time = [Dates.unix2datetime(Int64(i)) for i in time_values]
    return wisp, widi, wh, wd, wp, time
end


"""Generates the locations of points in a grid between the start and finish locations across the Earths surface."""
function generate_coords(lon1, lon2, lat1, lat2, n_ranks, n_nodes, dist)
    x, y = rh.return_co_ords(lon1, lon2, lat1, lat2, n_ranks, n_nodes, dist)
    return x, y
end


"""Regrids the weather data to a grid which is the same as the sailing domain."""
function regrid_domain(ds, req_lons, req_lats)
    values, lons, lats = rh.return_data(ds)
    req_lons = mod.(req_lons .+ 360.0, 360.0) 
    interp_values = zeros((size(values)[1], size(req_lons)[1], size(req_lons)[2]))
    knots = (lats[end:-1:1], lons)
    for i in 1:size(values)[1]
        itp = interpolate(knots, values[i, end:-1:1, :], Gridded(Linear()), )
        eptl  = extrapolate(itp, Line())
        interp_values[i, end:-1:1, :] = eptl.(req_lats, req_lons)
    end
    return interp_values
end


"""Generate domain information for routing problem."""
function generate_inputs(route, wisp, widi, wadi, wahi)
    y_dist = sail_route.haversine(route.lon1, route.lon2, route.lat1, route.lat2)[1]/(route.y_nodes+1) # in nm
    x, y = generate_coords(route.lon1, route.lon2, route.lat1, route.lat2, route.x_nodes, route.y_nodes, y_dist)
    wisp = regrid_domain(wisp, x, y)
    widi = regrid_domain(widi, x, y)
    wadi = regrid_domain(wadi, x, y)
    wahi = regrid_domain(wahi, x, y)
    return x, y, wisp, widi, wadi, wahi
end


min_dist = 20.0
lon1 = -171.75
lat1 = -13.917
lon2 = -158.07
lat2 = -19.59
n = sail_route.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
base_path = "/scratch/td7g11/era5/"
route = sail_route.Route(lon1, lon2, lat1, lat2, n, n)
weather = base_path*"polynesia_2004_q1/polynesia_2004_q1.nc"
ensemble = 0
wisp, widi, wahi, wadi, wapr, time_indexes = load_era5_ensemble(weather, ensemble)
x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
dims = size(wisp)
cusp, cudi = sail_route.return_current_vectors(y, dims[1])
start_time = Dates.DateTime(2004, 1, 1, 0, 0, 0)
boat_performance = datadir()*"performance/first40.csv"
twa, tws, perf = sail_route.load_file(boat_performance)
res = sail_route.typical_aerrtsen()
polar = sail_route.setup_perf_interpolation(tws, twa, perf)
sample_perf = sail_route.Performance(polar, 1.0, 1.0, res)
results = sail_route.route_solve(route, sample_perf, start_time, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
println(results)
