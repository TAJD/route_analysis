#!/usr/bin/env julia


using DrWatson, Test
quickactivate(pwd()*"/")
using SailRoute, SafeTestsets
println("Starting tests")


@time @safetestset "Wind interpolation" begin include("test_wind.jl") end