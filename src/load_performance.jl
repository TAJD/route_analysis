using DrWatson, PyCall
perf = pyimport("routing_helper")

println(perf.generate_performance(120.0, [0.0, 5.0], 0.3))
