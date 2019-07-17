#!/usr/bin/env julia


using DrWatson, Test
quickactivate(pwd()*"/")
using SailRoute, SafeTestsets
println("Starting tests")


@time @safetestset "Weather interpolation" begin include("test_weather.jl") end
