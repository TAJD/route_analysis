using DrWatson, PyCall, SailRoute, Dates
pyperf = pyimport("routing_helper")


"""Function to generate different synthetic performance envelopes.

Return the polars/performances in one array and the names in a second.
"""
function generate_canoe_performance_types()
    upwind_angle = LinRange(75, 160, 6)
    ratio = LinRange(0.2, 0.5, 4)
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    wave_resistance_model = SailRoute.typical_aerrtsen()
    polars = []
    polar_names = []
    for ua in upwind_angle
        for r in ratio
            tws, twa, perf = pyperf.generate_canoe_performance(ua, tws_speeds, r)
            polar = SailRoute.setup_perf_interpolation(tws, twa, perf)
            push!(polars, polar)
            polar_name = string(round(ua; digits=2))*"_"*string(round(r;digits=2))
            push!(polar_names, polar_name)
        end
    end
    names = []
    performances = []
    for p in eachindex(polars)
        push!(performances, [SailRoute.Performance(polars[p], unc, 1.0,
                             wave_resistance_model) for unc in LinRange(0.9, 1.1, 3)])
        push!(names, polar_names[p])
    end
    return performances, names
end


"""Generate simulation settings to study the influence of performance variation."""
function vary_performance()
    t_inc = 48
    min_dist = 40.0
    ensemble = 1
    save_path = datadir()*"/vary_perf_40/"
    perfs, perf_names = generate_canoe_performance_types()
    weather_base_path = "/scratch/td7g11/era5/"
    weather_paths = [weather_base_path*"polynesia_2004_q1/polynesia_2004_q1.nc",
                     weather_base_path*"polynesia_2004_q2/polynesia_2004_q2.nc"]
    weather_names = ["2004_q1",
                    "2004_q2"]
    weather_times = [Dates.DateTime(2004, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 3, 31, 0, 0, 0),
                     Dates.DateTime(2004, 4, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2004, 6, 30, 0, 0, 0)]
    # start_lon = -175.15
    # start_lat = -21.21
    # finish_lon = -149.42
    # finish_lat = -17.67
    # route_name = "Tongatapu_Tahiti"
    start_lon = 360-171.75
    start_lat = -13.6
    finish_lon = 360-159.79
    finish_lat = -18.85
    route_name = "Samoa_Aitiutaki"
    save_paths = []
    settings = []
    for p in eachindex(perfs)
        for w in eachindex(weather_times)
            fname = save_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*route_name*"_ensemble_"*string(ensemble)*"_"*string(min_dist)
            push!(save_paths, fname)
            setting = [weather_times[w], weather_paths[w], perfs[p], start_lon, finish_lon, start_lat, finish_lat, min_dist, ensemble]
            push!(settings, setting)
        end 
    end
    println(length(settings))
    return save_paths, settings
end


"""Generate simulation settings to study the influence of performance variation."""
function vary_performance_investigation()
    t_inc = 48
    min_dist = 40.0
    ensemble = 1
    save_path = datadir()*"/vary_perf_40/"
    perfs, perf_names = generate_canoe_performance_types()
    weather_base_path = "/scratch/td7g11/era5/"
    weather_paths = [weather_base_path*"polynesia_2010_q4/polynesia_2010_q4.nc",
                     weather_base_path*"polynesia_2011_q1/polynesia_2011_q1.nc",
                     weather_base_path*"polynesia_1997_q4/polynesia_1997_q4.nc",
                     weather_base_path*"polynesia_1998_q1/polynesia_1998_q1.nc"]
    weather_names = ["2010_q4",
                    "2011_q1",
                    "1997_q4",
                    "1998_q1"]
    weather_times = [Dates.DateTime(2010, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2010, 12, 31, 0, 0, 0),
                     Dates.DateTime(2011, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(2011, 3, 31, 0, 0, 0),
                     Dates.DateTime(1997, 10, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1997, 12, 31, 0, 0, 0),
                     Dates.DateTime(1998, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1998, 3, 31, 0, 0, 0)]
    # start_lon = -175.15
    # start_lat = -21.21
    # finish_lon = -149.42
    # finish_lat = -17.67
    # route_name = "Tongatapu_Tahiti"
    start_lon = 360-171.75
    start_lat = -13.6
    finish_lon = 360-159.79
    finish_lat = -18.85
    route_name = "Samoa_Aitiutaki"
    save_paths = []
    settings = []
    for p in eachindex(perfs)
        for w in eachindex(weather_times)
            fname = save_path*"_"*weather_names[w]*"_"*perf_names[p]*"_"*route_name*"_ensemble_"*string(ensemble)*"_"*string(min_dist)
            push!(save_paths, fname)
            setting = [weather_times[w], weather_paths[w], perfs[p], start_lon, finish_lon, start_lat, finish_lat, min_dist, ensemble]
            push!(settings, setting)
        end 
    end
    println(length(settings))
    return save_paths, settings
end


function load_tong_old_perf()
    path = datadir()*"/performance/tongiaki_vpp.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Matrix{Float64}, df)
    tws = Array{Float64}([0.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 14.0, 16.0, 20.0])
    twa = Array{Float64}([0.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0])
    return SailRoute.setup_perf_interpolation(tws, twa, perf)
end


function load_tong()
    path = datadir()*"/performance/tongiaki_201908.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Matrix{Float64}, df)
    tws = Array{Float64}([0.0, 4.0, 6.0, 8.0, 10.0, 12.0,  16.0, 20.0, 25.0, 30.0, 35.0])
    twa = Array{Float64}([0.0, 80.0, 90.0, 100.0, 110.0, 120.0,135.0,150.0,160.0,170.0])
    return SailRoute.setup_perf_interpolation(tws, twa, perf)
end


function load_boeckv2()
    path = datadir()*"/performance/boeck_v2.csv"
    df = CSV.read(path, delim=',', datarow=1)
    perf = convert(Matrix{Float64}, df)
    tws = Array{Float64}([0.0,5.832037,7.77605,9.720062,11.66407,13.60809,15.5521,17.49611])
    twa = Array{Float64}([0.0, 60.0, 75.0, 90.0, 110.0, 120.0, 150.0, 170.0])
    return SailRoute.setup_perf_interpolation(tws, twa, perf)
end
