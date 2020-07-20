using BlockArrays, LinearAlgebra, Test

@testset "BlockArrays.jl" begin
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
    include("test_cholesky.jl")
end
