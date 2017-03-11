using BlockArrays
using BenchmarkTools
using FileIO

include("generate_report.jl")

const SUITE = BenchmarkGroup()

g = addgroup!(SUITE, "indexing")
# g_block = addgroup!(SUITE, "blockindexing")
g_size = addgroup!(SUITE, "size")

for n = (5,)
    block_vec = BlockArray(rand(n),       [1,3,1])
    block_mat = BlockArray(rand(n,n),     [1,3,1], [4,1])
    block_arr = BlockArray(rand(n,n,n),   [1,3,1], [4,1], [3, 2])
    g["getindex", "vector", n] = @benchmarkable getindex($block_vec, 3)
    g["getindex", "matrix", n] = @benchmarkable getindex($block_mat, 3, 2)
    g["getindex", "rank3", n]  = @benchmarkable getindex($block_arr, 3, 2 ,3)
    
    g["setindex!", "vector", n] = @benchmarkable setindex!($block_vec, 3)
    g["setindex!", "matrix", n] = @benchmarkable setindex!($block_mat, 3, 2)
    g["setindex!", "rank3", n]  = @benchmarkable setindex!($block_arr, 3, 2 ,3)

    g_size["vector", n] = @benchmarkable size($block_vec)
    g_size["matrix", n] = @benchmarkable size($block_mat)
    g_size["rank3", n]  = @benchmarkable size($block_arr)
end


function run_benchmarks(name, tagfilter = @tagged ALL)
    const paramspath = joinpath(dirname(@__FILE__), "params.jld")
    if !isfile(paramspath)
        println("Tuning benchmarks...")
        tune!(SUITE, verbose=true)
        JLD.save(paramspath, "SUITE", params(SUITE))
    end
    loadparams!(SUITE, JLD.load(paramspath, "SUITE"), :evals, :samples)
    results = run(SUITE[tagfilter], verbose = true, seconds = 2)
    JLD.save(joinpath(dirname(@__FILE__), name * ".jld"), "results", results)
end

function generate_report(v1, v2)
    v1_res = load(joinpath(dirname(@__FILE__), v1 * ".jld"), "results")
    v2_res = load(joinpath(dirname(@__FILE__), v2 * ".jld"), "results")
    open(joinpath(dirname(@__FILE__), "results_$(v1)_$(v2).md"), "w") do f
        printreport(f, judge(minimum(v1_res), minimum(v2_res)); iscomparisonjob = true)
    end
end

function generate_report(v1)
    v1_res = load(joinpath(dirname(@__FILE__), v1 * ".jld"), "results")
    open(joinpath(dirname(@__FILE__), "results_$(v1).md"), "w") do f
        printreport(f, minimum(v1_res); iscomparisonjob = false)
    end
end

