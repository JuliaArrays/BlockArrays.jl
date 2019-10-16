using BlockArrays, LinearAlgebra, Test

@testset "BlockArrays.jl" begin
    include("test_blockindices.jl")
    include("test_blockarrays.jl")
    include("test_blockviews.jl")
    include("test_blockrange.jl")
    include("test_blockarrayinterface.jl")
    include("test_blockbroadcast.jl")
end
