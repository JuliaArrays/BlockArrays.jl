using BlockArrays, LinearAlgebra, Test

using Aqua
@testset "Project quality" begin
    Aqua.test_all(BlockArrays, ambiguities=false)
end

using Documenter
@testset "docstrings" begin
    # don't test docstrings on old versions to avoid failures due to changes in types
    if VERSION >= v"1.9"
        DocMeta.setdocmeta!(BlockArrays, :DocTestSetup, :(using BlockArrays); recursive=true)
        doctest(BlockArrays)
    end
end

include("test_blockindices.jl")
include("test_blockarrays.jl")
include("test_blockviews.jl")
include("test_blocks.jl")
include("test_blockrange.jl")
include("test_blockarrayinterface.jl")
include("test_blockbroadcast.jl")
include("test_blocklinalg.jl")
include("test_blockproduct.jl")
include("test_blockreduce.jl")
include("test_blockdeque.jl")
include("test_blockcholesky.jl")
