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

@testset "Triangular/Symmetric/Hermitian block arrays" begin
    A = PseudoBlockArray{ComplexF64}(undef, (1:4), (1:4))
    A .= randn.() .+ randn.().*im

    @test UpperTriangular(A)[Block(2,2)] == UpperTriangular(A[2:3,2:3])
    @test UpperTriangular(A)[Block(2,3)] == A[2:3,4:6]
    @test UpperTriangular(A)[Block(3,2)] == zeros(3,2)
    @test Symmetric(A)[Block(2,2)] == Symmetric(A[2:3,2:3])
    @test Symmetric(A)[Block(2,3)] == A[2:3,4:6]
    @test Symmetric(A)[Block(3,2)] == transpose(A[2:3,4:6])
    @test Hermitian(A)[Block(2,2)] == Hermitian(A[2:3,2:3])
    @test Hermitian(A)[Block(2,3)] == A[2:3,4:6]
    @test Hermitian(A)[Block(3,2)] == A[2:3,4:6]'
end
