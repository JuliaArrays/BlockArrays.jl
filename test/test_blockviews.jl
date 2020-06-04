using BlockArrays, Test, Base64

@testset "Block Views" begin
    @testset "block slice" begin
        A = BlockArray(1:6,1:3)
        b = parentindices(view(A, Block(2)))[1] # A BlockSlice

        @test first(b) == 2
        @test last(b) == 3
        @test length(b) == 2
        @test step(b) == 1
        @test Base.unsafe_length(b) == 2
        @test axes(b) == (Base.OneTo(2),)
        @test Base.axes1(b) == Base.OneTo(2)
        @test Base.unsafe_indices(b) == (Base.OneTo(2),)
        @test size(b) == (2,)
        @test collect(b) == [2,3]
        @test b[1] == 2
        @test b[1:2] == 2:3
    end

    @testset "block view" begin
        A = BlockArray(collect(1:6), 1:3)
        @test view(A, Block(2)) == [2,3]
        view(A, Block(2))[2] = -1
        @test A[3] == -1

        # backend tests
        @test_throws ArgumentError Base.to_index(A, Block(1))

        A = PseudoBlockArray(collect(1:6), 1:3)
        @test view(A, Block(2)) == [2,3]
        view(A, Block(2))[2] = -1
        @test A[3] == -1


        # backend tests
        @test_throws ArgumentError Base.to_index(A, Block(1))

        A = BlockArray(reshape(collect(1:(6*12)),6,12), 1:3, 3:5)
        V = view(A, Block(2), Block(3))
        @test size(V) == (2, 5)
        V[1,1] = -1
        @test A[2,8] == -1

        V = view(A, Block(3, 2))
        @test size(V) == (3, 4)
        V[2,1] = -2
        @test A[5,4] == -2

        # test mixed blocks and other indices
        @test view(A, Block(2), 2) == [8,9]
        @test similar(A, (Base.OneTo(5), axes(A,2))) isa BlockArray{Int}
        @test view(A, Block(2), :) == A[2:3,:]

        @test view(A, 2, Block(1)) == [2,8,14]
        @test view(A, :, Block(1)) == A[:,1:3]

        @test view(V, Block(1, 1)) ≡ V

        @test_throws BlockBoundsError view(V, Block(1,2))
        @test_throws BlockBoundsError view(V, Block(2,1))


        A = BlockArray(reshape(collect(1:(6^3)),6,6,6), 1:3, 1:3, 1:3)
        V = view(A, Block(2), Block(3), Block(1))
        @test size(V) == (2, 3, 1)
        V[1,1,1] = -3
        @test A[2,4,1] == -3

        V = view(A,Block(1,1,1))
        @test size(V) == (1,1,1)
        V[1,1,1] = -4
        @test A[1,1,1] == -4

        # blocks mimic CartesianIndex in views
        V = view(A,Block(1,1),Block(2))
        @test size(V) == (1,1,2)
        V[1,1,1] = -5
        @test A[1,1,2] == -5

        V = view(A,Block(2),Block(1,1))
        @test size(V) == (2,1,1)
        V[1,1,1] = -6
        @test A[2,1,1] == -6

        # test mixed blocks and other indices
        @test view(A, Block(1), Block(2), 1) == A[1:1,2:3,1]
        @test view(A, Block(1,2), 1) == A[1:1,2:3,1]
        @test view(A, Block(1), 2, 1) == A[1:1,2,1]
        @test view(A, 1, Block(2), 1) == A[1,2:3,1]
        @test view(A, 1, 2, Block(2)) == A[1,2,2:3]
    end

    @testset "block view pointers" begin
        A = BlockArray(reshape(Vector{Float64}(1:(6^2)),6,6), 1:3, 1:3)

        V = view(A, Block(1,2))
        @test Base.unsafe_convert(Ptr{Float64}, V) == Base.unsafe_convert(Ptr{Float64}, A.blocks[1,2])
        @test unsafe_load(pointer(V)) == V[1,1]


        A = PseudoBlockArray(reshape(Vector{Float64}(1:(6^2)),6,6), 1:3, 1:3)

        V = view(A, Block(1,2))
        @test Base.unsafe_convert(Ptr{Float64}, V) == Base.unsafe_convert(Ptr{Float64}, view(A.blocks, 1:1, 2:3))
        @test unsafe_load(pointer(V)) == V[1,1]

        V = view(A, Block(2), 2:3)
        @test Base.unsafe_convert(Ptr{Float64}, V) == Base.unsafe_convert(Ptr{Float64}, view(A.blocks, 2:3, 2:3))
        @test unsafe_load(pointer(V)) == V[1,1]

        V = view(A, 2:3, Block(2))
        @test Base.unsafe_convert(Ptr{Float64}, V) == Base.unsafe_convert(Ptr{Float64}, view(A.blocks, 2:3, 2:3))
        @test unsafe_load(pointer(V)) == V[1,1]
    end

    @testset "block indx range of block range" begin
        A = PseudoBlockArray(collect(1:6), 1:3)
        V = view(A, Block.(1:2))
        @test V == 1:3
        @test axes(V,1) isa BlockArrays.BlockedUnitRange
        @test blockaxes(V,1) == Block.(1:2)
        @test view(V, Block(2)[1:2]) == [2,3]
        V = view(A, Block.(2:3))
        @test V == 2:6
        @test view(V, Block(2)[1:2]) == [4,5]
    end

    @testset "subarray implements block interface" begin
        A = PseudoBlockArray(reshape(Vector{Float64}(1:(6^2)),6,6), 1:3, 1:3)

        V = view(A, Block(2,3))
        @test PseudoBlockArray(V) isa PseudoBlockArray
        @test BlockArray(V) isa BlockArray
        @test PseudoBlockArray(V) == BlockArray(V) == V

        V = view(A, Block(2), Block.(2:3))
        @test PseudoBlockArray(V) isa PseudoBlockArray
        @test BlockArray(V) isa BlockArray
        @test PseudoBlockArray(V) == BlockArray(V) == V
        @test blocksize(V) == (1,2)

        V = view(A, Block.(2:3), Block(3))
        @test PseudoBlockArray(V) isa PseudoBlockArray
        @test BlockArray(V) isa BlockArray
        @test PseudoBlockArray(V) == BlockArray(V) == V
        @test blocksize(V) == (2,1)

        V = view(A, Block.(2:3), Block.(1:2))
        @test PseudoBlockArray(V) isa PseudoBlockArray
        @test BlockArray(V) isa BlockArray
        @test PseudoBlockArray(V) == BlockArray(V) == V
        @test blocksize(V) == (2,2)
    end

    @testset "Block-BlockRange blocks" begin
        A = BlockArray([1 2 3; 4 5 6; 7 8 9], 1:2, 1:2)
        V = view(A,Block(1),Block.(1:2))
        W = view(A,Block.(1:2),Block(1))
        @test blocks(V) == blocks(A)[1:1,1:2]
        @test blocks(W) == blocks(A)[1:2,1:1]
        if VERSION ≥ v"1.2"
            @test stringmime("text/plain", V) == "1×3 view(::BlockArray{$Int,2,Array{Array{$Int,2},2},Tuple{BlockedUnitRange{Array{$Int,1}},BlockedUnitRange{Array{$Int,1}}}}, BlockSlice(Block(1),1:1), BlockSlice(Block{1,$Int}[Block(1), Block(2)],1:1:3)) with eltype $Int with indices Base.OneTo(1)×1:1:3:\n 1  │  2  3"
            @test stringmime("text/plain", W) == "3×1 view(::BlockArray{$Int,2,Array{Array{$Int,2},2},Tuple{BlockedUnitRange{Array{$Int,1}},BlockedUnitRange{Array{$Int,1}}}}, BlockSlice(Block{1,$Int}[Block(1), Block(2)],1:1:3), BlockSlice(Block(1),1:1)) with eltype $Int with indices 1:1:3×Base.OneTo(1):\n 1\n ─\n 4\n 7"
        end
    end

    @testset "getindex with BlockRange" begin
        A = BlockArray(randn(6), 1:3)
        @test A[Block.(2:3)] isa BlockArray
        @test A[Block.(2:3)] == A[2:end]
        A = PseudoBlockArray(randn(6), 1:3)
        @test A[Block.(2:3)] isa PseudoBlockArray
        @test A[Block.(2:3)] == A[2:end]
    end
end