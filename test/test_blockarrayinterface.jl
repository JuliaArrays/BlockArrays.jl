using BlockArrays, LinearAlgebra, Base64

struct PartiallyImplementedBlockVector <: AbstractBlockArray{Float64,1} end

@testset "partially implemented block array" begin
    # the error thrown before was incorrect
    A = PartiallyImplementedBlockVector()
    @test_throws(ErrorException("getblock for PartiallyImplementedBlockVector is not implemented"),
                getblock(A, 1))
    @test_throws(ErrorException("getblock! for PartiallyImplementedBlockVector is not implemented"),
        getblock!(zeros(5), A, Block(1)))
    @test_throws(ErrorException("setblock! for PartiallyImplementedBlockVector is not implemented"),
        BlockArrays.setblock!(A, zeros(5), Block(1)))
    @test_throws(ErrorException( "axes for PartiallyImplementedBlockVector is not implemented"),
        BlockArrays.axes(A))
end

@testset "Array block interface" begin
    @test 1[Block()] == 1

    A = randn(5)
    @test blocksize(A) == (1,)
    @test A[Block(1)] == A
    view(A,Block(1))[1] = 2
    @test A[1] == 2
    @test_throws BlockBoundsError A[Block(2)]

    A = randn(5,5)
    @test A[Block(1,1)] == A
end

@testset "Triangular/Symmetric/Hermitian block arrays" begin
    A = PseudoBlockArray{ComplexF64}(undef, (1:4), (1:4))
    A .= reshape(1:length(A), size(A))

    @test blocksize(UpperTriangular(A)) == blocksize(Symmetric(A)) == blocksize(A)
    @test UpperTriangular(A)[Block(2,2)] == UpperTriangular(A[2:3,2:3])
    @test UpperTriangular(A)[Block(2,3)] == A[2:3,4:6]
    @test UpperTriangular(A)[Block(3,2)] == zeros(3,2)
    @test Symmetric(A)[Block(2,2)] == Symmetric(A[2:3,2:3])
    @test Symmetric(A)[Block(2,3)] == A[2:3,4:6]
    @test Symmetric(A)[Block(3,2)] == transpose(A[2:3,4:6])
    @test Hermitian(A)[Block(2,2)] == Hermitian(A[2:3,2:3])
    @test Hermitian(A)[Block(2,3)] == A[2:3,4:6]
    @test Hermitian(A)[Block(3,2)] == A[2:3,4:6]'
    if VERSION ≥ v"1.2"
        @test stringmime("text/plain", UpperTriangular(A)) == "10×10 UpperTriangular{Complex{Float64},PseudoBlockArray{Complex{Float64},2,Array{Complex{Float64},2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}}} with indices 1:1:10×1:1:10:\n 1.0+0.0im  │  11.0+0.0im  21.0+0.0im  │  31.0+0.0im  41.0+0.0im  51.0+0.0im  │  61.0+0.0im  71.0+0.0im  81.0+0.0im   91.0+0.0im\n ───────────┼──────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────────────\n     ⋅      │  12.0+0.0im  22.0+0.0im  │  32.0+0.0im  42.0+0.0im  52.0+0.0im  │  62.0+0.0im  72.0+0.0im  82.0+0.0im   92.0+0.0im\n     ⋅      │       ⋅      23.0+0.0im  │  33.0+0.0im  43.0+0.0im  53.0+0.0im  │  63.0+0.0im  73.0+0.0im  83.0+0.0im   93.0+0.0im\n ───────────┼──────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────────────\n     ⋅      │       ⋅           ⋅      │  34.0+0.0im  44.0+0.0im  54.0+0.0im  │  64.0+0.0im  74.0+0.0im  84.0+0.0im   94.0+0.0im\n     ⋅      │       ⋅           ⋅      │       ⋅      45.0+0.0im  55.0+0.0im  │  65.0+0.0im  75.0+0.0im  85.0+0.0im   95.0+0.0im\n     ⋅      │       ⋅           ⋅      │       ⋅           ⋅      56.0+0.0im  │  66.0+0.0im  76.0+0.0im  86.0+0.0im   96.0+0.0im\n ───────────┼──────────────────────────┼──────────────────────────────────────┼─────────────────────────────────────────────────\n     ⋅      │       ⋅           ⋅      │       ⋅           ⋅           ⋅      │  67.0+0.0im  77.0+0.0im  87.0+0.0im   97.0+0.0im\n     ⋅      │       ⋅           ⋅      │       ⋅           ⋅           ⋅      │       ⋅      78.0+0.0im  88.0+0.0im   98.0+0.0im\n     ⋅      │       ⋅           ⋅      │       ⋅           ⋅           ⋅      │       ⋅           ⋅      89.0+0.0im   99.0+0.0im\n     ⋅      │       ⋅           ⋅      │       ⋅           ⋅           ⋅      │       ⋅           ⋅           ⋅      100.0+0.0im"
    end
end

@testset "Adjoint/Transpose block arrays" begin
    A = PseudoBlockArray{ComplexF64}(undef, (1:4), (2:5))
    A .= randn.() .+ randn.().*im

    @test blocksize(A') == (4,4)
    @test blocksize(Transpose(A)) == (4,4)

    @test A'[Block(2,2)] == A[Block(2,2)]' == A[2:3,3:5]'
    @test transpose(A)[Block(2,2)] == transpose(A[2:3,3:5])
    @test A'[Block(2,3)] == A[Block(3,2)]'
    @test transpose(A)[Block(2,3)] == transpose(A[Block(3,2)])

    @test BlockArray(A') == A'
    @test BlockArray(transpose(A)) == transpose(A)
end

@testset "Diagonal BlockArray" begin
    A = mortar(Diagonal(fill([1 2],2)))
    @test A isa BlockMatrix{Int,Diagonal{Matrix{Int}, Vector{Matrix{Int}}}}
    @test A[Block(1,2)] == [0 0]
    @test_throws BlockBoundsError A[Block(1,3)]
    @test A == [1 2 0 0; 0 0 1 2]
end

@testset "non-standard block axes" begin
    A = BlockArray([1 2; 3 4], Fill(1,2),Fill(1,2))
    @test A isa BlockMatrix{Int,Matrix{Matrix{Int}},NTuple{2,BlockedUnitRange{StepRange{Int64,Int64}}}}
    A = BlockArray([1 2; 3 4], Fill(1,2),[1,1])
    @test A isa BlockMatrix{Int,Matrix{Matrix{Int}},Tuple{BlockedUnitRange{StepRange{Int64,Int64}},BlockedUnitRange{Vector{Int}}}}
end

