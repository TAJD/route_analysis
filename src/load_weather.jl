using Dates, Interpolations, PyCall, CSV, SailRoute, LinearAlgebra
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
    knots = (time_indexes, lats[end:-1:1], lons) # knot vectors must be sorted in ascending order
    itp = interpolate(knots, data[:, end:-1:1, :], Gridded(Linear()))
    ept1 = extrapolate(itp, Flat())
    for t in time_indexes
        for i in 1:size(y)[1]
            for j in 1:size(x)[1]
                interp_values[t, i, j] = ept1(t, y[i, j], x[i, j]) #check the locations to make sure the values are going in the correct locations
            end
        end
    end
    return interp_values
end

function generate_grid_euc(start_lon, start_lat, finish_lon, finish_lat, nodes)
    dist = norm([start_lon, start_lat]-[finish_lon, finish_lat])
    spacing = dist/(nodes+1)
    alpha = atan(finish_lat-start_lat, finish_lon-start_lon)
    x_dist = spacing
    y_dist = spacing
    grid_x = reshape(start_lon.+[i*x_dist for j in range(0, length=nodes).-(nodes-1)/2 for i in range(1, length=nodes)], (nodes, nodes))
    grid_y = reshape(start_lat.+[j*y_dist for j in range(0, length=nodes).-(nodes-1)/2 for i in range(1, length=nodes)], (nodes, nodes))
    rot_grid_x = [SailRoute.rotate_point(start_lon, start_lat, x, y, alpha, true) for (x, y) in zip(grid_x,grid_y)]
    rot_grid_y = [SailRoute.rotate_point(start_lon, start_lat, x, y, alpha, false) for (x, y) in zip(grid_x,grid_y)]
    return rot_grid_x[end:-1:1,end:-1:1], rot_grid_y[end:-1:1,end:-1:1]
end

function generate_inputs(route, wisp, widi, wadi, wahi)
    x, y = generate_grid_euc(route.lon1, route.lat1, route.lon2, route.lat2, route.x_nodes)
    wisp = regrid_domain(wisp, x, y)
    wisp = wisp.*1.9438444924406 # convert from m/s to knots
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



"""Load current data for mid Pacific. Returns two extrapolate types which return the current speed and direction as a function of Latitude."""
function load_current_data()
    path = datadir()*"/current_data/"
    m_path = path*"meridional.csv"
    z_path = path*"zonal.csv"
    meridional = convert(Matrix{Float32}, CSV.read(m_path, delim=',', datarow=1))
    zonal = convert(Matrix{Float32}, CSV.read(z_path, delim=',', datarow=1))
    meridional[:, 1] *= (0.01*1.9438444924406) # convert from cm/s to knots
    zonal[:, 1] *= (0.01*1.9438444924406)
    meridional = meridional[end:-1:1, :]
    zonal = zonal[end:-1:1, :]
    merid_interp = interpolate((meridional[:, 2],), meridional[:, 1], Gridded(Linear()))
    merid = extrapolate(merid_interp, Line())  
    zonal_interp = interpolate((zonal[:, 2],), zonal[:, 1], Gridded(Linear()))
    zonal = extrapolate(zonal_interp, Line())  
    lats = collect(LinRange(-25, 25, 80))
    merid_sp = merid.(lats)
    zonal_sp = zonal.(lats)
    r = zeros(size(lats))
    theta = zeros(size(lats))
    r = [SailRoute.calc_polars(merid_sp[i], zonal_sp[i])[1] for i in eachindex(lats)]
    theta = [SailRoute.calc_polars(merid_sp[i], zonal_sp[i])[2] for i in eachindex(lats)]
    r_interp = interpolate((lats,), r, Gridded(Linear()))
    r_final = extrapolate(r_interp, Line()) 
    theta_interp = interpolate((lats,), theta, Gridded(Linear()))
    theta_final = extrapolate(theta_interp, Line())
    return r_final, theta_final
end


"""Return arrays of current speed and direction as a function of Latitude and length of weather scenario."""
function return_current_vectors(y, t_length)
    cusp = zeros((t_length, size(y)[1], size(y)[2]))
    cudi = zeros((t_length, size(y)[1], size(y)[2]))
    r, theta = load_current_data()
    for i in 1:t_length
        cusp[i, :, :] = r.(y)
        cudi[i, :, :] = theta.(y)
    end
    return Float32.(cusp), Float32.(cudi)
end
