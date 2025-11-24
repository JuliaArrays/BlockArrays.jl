using BlockArrays, LinearAlgebra, Test

using Aqua
downstream_test = "--downstream_integration_test" in ARGS
@testset "Project quality" begin
    Aqua.test_all(BlockArrays, ambiguities=false,
        stale_deps=!downstream_test)
end

using Documenter
@testset "docstrings" begin
    # don't test docstrings on old versions to avoid failures due to changes in types
    if v"1.10" <= VERSION < v"1.11.0-"
        DocMeta.setdocmeta!(BlockArrays, :DocTestSetup, :(using BlockArrays); recursive=true)
        doctest(BlockArrays, manual=false)
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
include("test_blocksvd.jl")
include("test_blockproduct.jl")
include("test_blockreduce.jl")
include("test_blockdeque.jl")
include("test_blockcholesky.jl")
include("test_blockbanded.jl")
include("test_adapt.jl")
