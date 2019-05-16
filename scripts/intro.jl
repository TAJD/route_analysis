using DrWatson
quickactivate(@__DIR__, "routing_analysis")
using Revise, PyCall, sail_route 

include(scriptdir()*"/load_performance_data.jl")

data = load_tong()
println(data)
