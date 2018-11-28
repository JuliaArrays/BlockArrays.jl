using BlockArrays

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

@testset "Array block interface" begin
    @test blocksizes(1) == BlockArrays.BlockSizes{0}()
    @test 1[Block()] == 1

    A = randn(5)
    @test blocksizes(A) == BlockArrays.BlockSizes([5])
    A[Block(1)] == A
    view(A,Block(1))[1] = 2
    @test A[1] == 2
    @test_throws BoundsError A[Block(2)]

    A = randn(5,5)
    @test A[Block(1,1)] == A
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

@testset "Adjoint/Transpose block arrays" begin
    A = PseudoBlockArray{ComplexF64}(undef, (1:4), (2:5))
    A .= randn.() .+ randn.().*im

    @test blocksizes(A') == BlockArrays.BlockSizes(2:5, 1:4)
    @test blocksizes(Transpose(A)) == BlockArrays.BlockSizes(2:5, 1:4)

    @test A'[Block(2,2)] == A[Block(2,2)]' == A[2:3,3:5]'
    @test transpose(A)[Block(2,2)] == transpose(A[2:3,3:5])
    @test A'[Block(2,3)] == A[Block(3,2)]'
    @test transpose(A)[Block(2,3)] == transpose(A[Block(3,2)])

    @test BlockArray(A') == A'
    @test BlockArray(transpose(A)) == transpose(A)
end
