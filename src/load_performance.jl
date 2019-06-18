using DrWatson, PyCall
perf = pyimport("routing_helper")

println(perf.generate_performance(120.0, [0.0, 5.0], 0.3))
println(perf.generate_circular_performance(120.0, [0.0, 5.0, 10.0, 20.0, 21.0], 0.3))
