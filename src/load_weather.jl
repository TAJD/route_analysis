using Dates, Interpolations, Statistics, StatsBase, PyCall, Distributed, SharedArrays, ProgressMeter
rh = pyimport("routing_helper")


function load_era5_ensemble(path_nc, ens)
    wisp, widi, wh, wd, wp, time_values = rh.retrieve_era5_ensemble(path_nc, ens)
    time = [Dates.unix2datetime(Int64(i)) for i in time_values]
    return wisp, widi, wh, wd, wp, time
end


function generate_coords(lon1, lon2, lat1, lat2, n_ranks, n_nodes, dist)
    x, y = rh.return_co_ords(lon1, lon2, lat1, lat2, n_ranks, n_nodes, dist)
    return Float32.(x), Float32.(y)
end


@fastmath function regrid_domain(ds, x, y)
    data, lons, lats = rh.return_data(ds)
    req_lons = mod.(x .+ 360.0, 360.0)
    time_indexes = [x for x in 1:size(data)[1]]
    interp_values = Array{Float32}(undef, size(data)[1], size(x)[1], size(x)[1])
    knots = (time_indexes, lats[end:-1:1], lons)
    itp = interpolate(knots, data[:, end:-1:1, :], Gridded(Linear()))
    ept1 = extrapolate(itp, Flat())
    for t in time_indexes
        for i in 1:size(y)[1]
            for j in 1:size(x)[1]
                interp_values[t, j, i] = ept1(t, y[i, j], x[i, j])
            end
        end
    end
    return interp_values
end


function generate_inputs(route, wisp, widi, wadi, wahi)
    y_dist = SailRoute.haversine(route.lon1, route.lon2, route.lat1, route.lat2)[1]/(route.y_nodes+1)
    x, y = generate_coords(route.lon1, route.lon2, route.lat1, route.lat2, route.x_nodes, route.y_nodes, y_dist)
    wisp = regrid_domain(wisp, x, y)
    wisp = wisp.*0.51444444444444
    widi = regrid_domain(widi, x, y)
    for i in eachindex(widi)
        if widi[i] < 0.0
            widi[i] += 360.0
        end
    end
    wadi = regrid_domain(wadi, x, y)
    wahi = regrid_domain(wahi, x, y)
    return x, y, Float32.(wisp), Float32.(widi), Float32.(wadi), Float32.(wahi)
end


function generate_sample_weather_scenarios(t_inc)
    base_path = "/scratch/td7g11/era5/"
    paths = [base_path*"2005_q1/polynesia_2005_q1.nc",
            base_path*"2005_q2/polynesia_2005_q2.nc"]
    names = ["2005_q1",
            "2005_q2"]
    times = [Dates.DateTime(2005, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 3, 31, 0, 0, 0),
            Dates.DateTime(2005, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 6, 30, 0, 0, 0)
    ]
    return paths, names, times
end

function generate_full_weather_scenarios(t_inc)
    base_path = "/scratch/td7g11/era5/"
    paths = [base_path*"polynesia_2004_q1/polynesia_2004_q1.nc",
             base_path*"polynesia_2004_q2/polynesia_2004_q2.nc",
             base_path*"polynesia_2004_q3/polynesia_2004_q3.nc",
             base_path*"polynesia_2004_q4/polynesia_2004_q4.nc",
             base_path*"2005_q1/polynesia_2005_q1.nc",
             base_path*"2005_q2/polynesia_2005_q2.nc",
             base_path*"polynesia_2005_q3/polynesia_2005_q3.nc",
             base_path*"polynesia_2005_q4/polynesia_2005_q4.nc",
             base_path*"polynesia_2010_q1/polynesia_2010_q1.nc",
             base_path*"polynesia_2010_q2/polynesia_2010_q2.nc",
             base_path*"polynesia_2010_q3/polynesia_2010_q3.nc",
             base_path*"polynesia_2010_q4/polynesia_2010_q4.nc",
             base_path*"polynesia_2011_q1/polynesia_2011_q1.nc",
             base_path*"polynesia_2011_q2/polynesia_2011_q2.nc",
             base_path*"polynesia_2011_q3/polynesia_2011_q3.nc",
             base_path*"polynesia_2011_q4/polynesia_2011_q4.nc",
             base_path*"polynesia_1995_q1/polynesia_1995_q1.nc",
             base_path*"polynesia_1995_q2/polynesia_1995_q2.nc",
             base_path*"polynesia_1995_q3/polynesia_1995_q3.nc",
             base_path*"polynesia_1995_q4/polynesia_1995_q4.nc",
             base_path*"polynesia_1996_q1/polynesia_1996_q1.nc",
             base_path*"polynesia_1996_q2/polynesia_1996_q2.nc",
             base_path*"polynesia_1996_q3/polynesia_1996_q3.nc",
             base_path*"polynesia_1996_q4/polynesia_1996_q4.nc",
             base_path*"polynesia_1997_q1/polynesia_1997_q1.nc",
             base_path*"polynesia_1997_q2/polynesia_1997_q2.nc",
             base_path*"polynesia_1997_q3/polynesia_1997_q3.nc",
             base_path*"polynesia_1997_q4/polynesia_1997_q4.nc",
             base_path*"polynesia_1998_q1/polynesia_1998_q1.nc",
             base_path*"polynesia_1998_q2/polynesia_1998_q2.nc",
             base_path*"polynesia_1998_q3/polynesia_1998_q3.nc",
             base_path*"polynesia_1998_q4/polynesia_1998_q4.nc"
             ]
    names = ["2004_q1",
            "2004_q2",
            "2004_q3",
            "2004_q4",
            "2005_q1",
            "2005_q2",
            "2005_q3",
            "2005_q4",
            "2010_q1",
            "2010_q2",
            "2010_q3",
            "2010_q4",
            "2011_q1",
            "2011_q2",
            "2011_q3",
            "2011_q4",
            "1995_q1",
            "1995_q2",
            "1995_q3",
            "1995_q4",
            "1996_q1",
            "1996_q2",
            "1996_q3",
            "1996_q4",
            "1997_q1",
            "1997_q2",
            "1997_q3",
            "1997_q4",
            "1998_q1",
            "1998_q2",
            "1998_q3",
            "1998_q4"]
    times = [Dates.DateTime(2004, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 3, 31, 0, 0, 0),
            Dates.DateTime(2004, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 6, 30, 0, 0, 0),
            Dates.DateTime(2004, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 9, 30, 0, 0, 0),
            Dates.DateTime(2004, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 12, 31, 0, 0, 0),
            Dates.DateTime(2005, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 3, 31, 0, 0, 0),
            Dates.DateTime(2005, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 6, 30, 0, 0, 0),
            Dates.DateTime(2005, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 9, 30, 0, 0, 0),
            Dates.DateTime(2005, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2005, 12, 31, 0, 0, 0),
            Dates.DateTime(2010, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 3, 31, 0, 0, 0),
            Dates.DateTime(2010, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 6, 30, 0, 0, 0),
            Dates.DateTime(2010, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 9, 30, 0, 0, 0),
            Dates.DateTime(2010, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 12, 31, 0, 0, 0),
            Dates.DateTime(2011, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2011, 3, 31, 0, 0, 0),
            Dates.DateTime(2011, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2011, 6, 30, 0, 0, 0),
            Dates.DateTime(2011, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2011, 9, 30, 0, 0, 0),
            Dates.DateTime(2011, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2011, 12, 31, 0, 0, 0),
            Dates.DateTime(1995, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1995, 3, 31, 0, 0, 0),
            Dates.DateTime(1995, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1995, 6, 30, 0, 0, 0),
            Dates.DateTime(1995, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1995, 9, 30, 0, 0, 0),
            Dates.DateTime(1995, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1995, 12, 31, 0, 0, 0),
            Dates.DateTime(1996, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1996, 3, 31, 0, 0, 0),
            Dates.DateTime(1996, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1996, 6, 30, 0, 0, 0),
            Dates.DateTime(1996, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1996, 9, 30, 0, 0, 0),
            Dates.DateTime(1996, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1996, 12, 31, 0, 0, 0),
            Dates.DateTime(1997, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 3, 31, 0, 0, 0),
            Dates.DateTime(1997, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 6, 30, 0, 0, 0),
            Dates.DateTime(1997, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 9, 30, 0, 0, 0),
            Dates.DateTime(1997, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 12, 31, 0, 0, 0),
            Dates.DateTime(1998, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1998, 3, 31, 0, 0, 0),
            Dates.DateTime(1998, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1998, 6, 30, 0, 0, 0),
            Dates.DateTime(1998, 7, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1998, 9, 30, 0, 0, 0),
            Dates.DateTime(1998, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1998, 12, 31, 0, 0, 0)
    ]
    return paths, names, times
end


