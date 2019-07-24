#!/bin/bash


export PATH="/scratch/td7g11/julia/julia-1.1.0/bin/:${PATH}"

for i in $(seq 40 48)
do
    julia -p 10 scripts/run_single_route.jl $i
done
