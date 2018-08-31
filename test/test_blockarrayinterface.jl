struct PartiallyImplementedBlockVector <: AbstractBlockArray{Float64,1} end

@testset "partially implemented block array" begin
    # the error thrown before was incorrect
    A = PartiallyImplementedBlockVector()
    try
        getblock(A, 1)
    catch err
        @test err isa ErrorException && err.msg == "getblock for PartiallyImplementedBlockVector is not implemented"
    end
    try
        getblock!(zeros(5), A, Block(1))
    catch err
        @test err isa ErrorException && err.msg == "getblock! for PartiallyImplementedBlockVector is not implemented"
    end
    try
        BlockArrays.setblock!(A, zeros(5), Block(1))
    catch err
        @test err isa ErrorException && err.msg == "setblock! for PartiallyImplementedBlockVector is not implemented"
    end
    try
        BlockArrays.blocksize(A, 2)
    catch err
        @test err isa ErrorException && err.msg == "blocksizes for PartiallyImplementedBlockVector is not implemented"
    end
end
