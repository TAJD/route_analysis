using DrWatson, Test, SailRoute

include(srcdir("load_weather.jl"))


@testset "Test weather interpolation" begin
    path_nc = datadir()*"/test_weather_data/polynesia_2004.nc"
    wisp, widi, wh, wd, wp, times = load_era5_ensemble(path_nc, 2)
    data, lons, lats = rh.return_data(wisp)
    lon1 = -175.15
    lat1 = -21.21
    lon2 = -149.42
    lat2 = -17.67
    min_dist = 200.0
    n = SailRoute.calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    route = SailRoute.Route(lon1, lon2, lat1, lat2, n, n)
    x, y = generate_coords(lon1, lon2, lat1, lat2, n, n, min_dist)
    x_corrected = mod.(x .+ 360.0, 360.0)
    wisp_interpolated = regrid_domain(wisp, x_corrected, y)
    @test wisp_interpolated[1, 1, 1] ≈ wisp.interp(time=times[1], latitude=y[1, 1], longitude=x_corrected[1, 1]).data[1]
    @test wisp_interpolated[2, 2, 2] ≈ wisp.interp(time=times[2], latitude=y[2,2], longitude=x_corrected[2,2]).data[1]
    @test wisp_interpolated[1, 1, 2] ≈ wisp.interp(time=times[1], latitude=y[1, 2], longitude=x_corrected[1, 2]).data[1]
    @test wisp_interpolated[1, 2, 1] ≈ wisp.interp(time=times[1], latitude=y[2, 1], longitude=x_corrected[2, 1]).data[1]
    @test wisp_interpolated[2, 1, 1] ≈ wisp.interp(time=times[2], latitude=y[1,1], longitude=x_corrected[1,1]).data[1]
end