using BlockArrays
using BenchmarkTools

include("generate_report.jl")

const SUITE = BenchmarkGroup()

g = addgroup!(SUITE, "indexing")
# g_block = addgroup!(SUITE, "blockindexing")
g_size = addgroup!(SUITE, "size")
g_metadata = addgroup!(SUITE, "metadata")
g_product = addgroup!(SUITE, "product")
g_broadcast = addgroup!(SUITE, "broadcast")
g_reduction = addgroup!(SUITE, "reduction")

for n = (5,)
    for BT in (BlockArray, BlockedArray)
        block_vec = BT(rand(n),       [1,3,1])
        block_mat = BT(rand(n,n),     [1,3,1], [4,1])
        block_arr = BT(rand(n,n,n),   [1,3,1], [4,1], [3, 2])
        g["getindex", nameof(BT), "vector", n] = @benchmarkable getindex($block_vec, 3)
        g["getindex", nameof(BT), "matrix", n] = @benchmarkable getindex($block_mat, 3, 2)
        g["getindex", nameof(BT), "rank3", n]  = @benchmarkable getindex($block_arr, 3, 2 ,3)

        g["setindex!", nameof(BT), "vector", n] = @benchmarkable setindex!($block_vec, 1, 3)
        g["setindex!", nameof(BT), "matrix", n] = @benchmarkable setindex!($block_mat, 1, 3, 2)
        g["setindex!", nameof(BT), "rank3", n]  = @benchmarkable setindex!($block_arr, 1, 3, 2 ,3)

        g_size[nameof(BT), "vector", n] = @benchmarkable size($block_vec)
        g_size[nameof(BT), "matrix", n] = @benchmarkable size($block_mat)
        g_size[nameof(BT), "rank3", n]  = @benchmarkable size($block_arr)
    end
end

blockkron_vector = Ref(BlockKron(1:10_000, 1:4, 1:3))
blockkron_matrix = Ref(BlockKron(
    reshape(1:800_000, 1_000, 800), reshape(1:20, 4, 5), reshape(1:6, 3, 2),
))
g_metadata["BlockKron", "axes", "vector"] = @benchmarkable axes($blockkron_vector[])
g_metadata["BlockKron", "axes", "matrix"] = @benchmarkable axes($blockkron_matrix[])

blocklasts_a = collect(2:2:20_000)
blocklasts_b = collect(3:3:30_000)
g_metadata["sortedunion", "vectors"] =
    @benchmarkable BlockArrays.sortedunion($blocklasts_a, $blocklasts_b)

khatri_block_sizes = fill(2, 10)
khatri_a = BlockArray(randn(20, 20), khatri_block_sizes, khatri_block_sizes)
khatri_b = BlockArray(randn(20, 20), khatri_block_sizes, khatri_block_sizes)
g_product["khatri_rao", "10x10", "2x2 blocks"] =
    @benchmarkable khatri_rao($khatri_a, $khatri_b)

broadcast_block_sizes = fill(4, 32)
broadcast_blocked_a = BlockedArray(randn(128, 128), broadcast_block_sizes, broadcast_block_sizes)
broadcast_blocked_b = BlockedArray(randn(128, 128), broadcast_block_sizes, broadcast_block_sizes)
broadcast_blocked_dest = similar(broadcast_blocked_a)
g_broadcast["in-place", "BlockedArray", "matching"] =
    @benchmarkable $broadcast_blocked_dest .= $broadcast_blocked_a .+ $broadcast_blocked_b

broadcast_block_a = BlockArray(randn(128, 128), broadcast_block_sizes, broadcast_block_sizes)
broadcast_block_b = BlockArray(randn(128, 128), broadcast_block_sizes, broadcast_block_sizes)
broadcast_block_dest = similar(broadcast_block_a)
g_broadcast["in-place", "BlockArray", "matching"] =
    @benchmarkable $broadcast_block_dest .= $broadcast_block_a .+ $broadcast_block_b

reduction_block_sizes = fill(4, 32)
reduction_block_array = BlockArray(randn(128, 128), reduction_block_sizes, reduction_block_sizes)
g_reduction["sum", "BlockArray", "matrix"] = @benchmarkable sum($reduction_block_array)
g_reduction["sum(abs2)", "BlockArray", "matrix"] =
    @benchmarkable sum(abs2, $reduction_block_array)


function run_benchmarks(name, tagfilter = @tagged ALL)
    paramspath = joinpath(@__DIR__, "params.json")
    if !isfile(paramspath)
        println("Tuning benchmarks...")
        tune!(SUITE, verbose=true)
        BenchmarkTools.save(paramspath, params(SUITE))
    end
    loadparams!(SUITE, only(BenchmarkTools.load(paramspath)), :evals, :samples)
    results = run(SUITE[tagfilter], verbose = true, seconds = 2)
    BenchmarkTools.save(joinpath(@__DIR__, name * ".json"), results)
end

function generate_report(v1, v2)
    v1_res = only(BenchmarkTools.load(joinpath(@__DIR__, v1 * ".json")))
    v2_res = only(BenchmarkTools.load(joinpath(@__DIR__, v2 * ".json")))
    open(joinpath(@__DIR__, "results_$(v1)_$(v2).md"), "w") do f
        printreport(f, judge(minimum(v1_res), minimum(v2_res)); iscomparisonjob = true)
    end
end

function generate_report(v1)
    v1_res = only(BenchmarkTools.load(joinpath(@__DIR__, v1 * ".json")))
    open(joinpath(@__DIR__, "results_$(v1).md"), "w") do f
        printreport(f, minimum(v1_res); iscomparisonjob = false)
    end
end
