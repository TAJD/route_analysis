using DrWatson, PyCall, sail_route
pyperf = pyimport("routing_helper")


"""Function to generate different synthetic performance envelopes.

Return the polars/performances in one array and the names in a second.
"""
function generate_performance_types()
    upwind_angle = LinRange(60, 160, 4)
    ratio = LinRange(0.2, 0.3, 3)
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    wave_resistance_model = sail_route.typical_aerrtsen()
    polars = []
    polar_names = []
    for ua in upwind_angle
        for r in ratio
            tws, twa, perf = pyperf.generate_circular_performance(ua, tws_speeds, r)
            polar = sail_route.setup_perf_interpolation(tws, twa, perf)
            push!(polars, polar)
            polar_name = string(round(ua; digits=2))*"_"*string(r)
            push!(polar_names, polar_name)
        end
    end
    names = []
    performances = []
    for p in eachindex(polars)
        push!(performances, [sail_route.Performance(polars[p], unc, 1.0,
                             wave_resistance_model) for unc in LinRange(0.9, 1.1, 5)])
        push!(names, polar_names[p])
    end
    return performances, names
end

"""Generate synthetic canoe performances"""
function generate_canoe_performance_types()
    upwind_angle = LinRange(60, 160, 6)
    ratio = LinRange(0.2, 0.5, 9)
    tws_speeds = [0.0, 5.0, 10.0, 20.0, 25.0, 30.0, 31.0]
    wave_resistance_model = sail_route.typical_aerrtsen()
    polars = []
    polar_names = []
    for ua in upwind_angle
        for r in ratio
            tws, twa, perf = pyperf.generate_canoe_performance(ua, tws_speeds, r)
            polar = sail_route.setup_perf_interpolation(tws, twa, perf)
            push!(polars, polar)
            polar_name = string(round(ua; digits=2))*"_"*string(round(r;digits=2))
            push!(polar_names, polar_name)
        end
    end
    names = []
    performances = []
    for p in eachindex(polars)
        push!(performances, [sail_route.Performance(polars[p], unc, 1.0,
                             wave_resistance_model) for unc in LinRange(0.9, 1.1, 3)])
        push!(names, polar_names[p])
    end
    return performances, names
end


