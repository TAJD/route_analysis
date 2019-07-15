# run simulation for range of performances for a single weather condition for a single route

using Distributed
@everywhere begin
    using DrWatson
end

@everywhere begin
    quickactivate(@__DIR__, "routing_analysis")
    include(srcdir("ensemble_routing.jl"))
    include(srcdir("load_route_settings.jl"))
    include(srcdir("load_weather.jl"))
    include(srcdir("load_performance.jl"))
end


function run_ensemble_simulations(n)
    n += 0
    save_paths, settings = vary_performance()
    sendto(workers(), save_paths=save_paths)
    sendto(workers(), settings=settings)
    parallized_ensemble_weather_routing(save_paths[n], settings[n][1], settings[n][2], settings[n][3], settings[n][4], settings[n][5], settings[n][6], settings[n][7], settings[n][8], settings[n][9])
end


if isempty(ARGS) == false
   @show i = parse(Int64, ARGS[1]); sendto(workers(), i=i)
end


run_ensemble_simulations(i)
