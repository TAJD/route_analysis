using DrWatson
quickactivate(@__DIR__, "routing_analysis")
using Revise, sail_route


println(sail_route.typical_aerrtsen())
println(sail_route.generate_performance(120.0, [0.0, 5.0, 10.0, 20.0, 21.0], 0.3))
