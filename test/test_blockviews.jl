using BlockArrays, Test, Base64

@testset "Block Views" begin
    @testset "block slice" begin
        A = PseudoBlockArray(1:6,1:3)
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

        A = PseudoBlockArray(reshape(collect(1:(6*12)),6,12), 1:3, 3:5)
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
        @test similar(A, (Base.OneTo(5), axes(A,2))) isa PseudoBlockArray{Int}
        @test view(A, Block(2), :) == A[2:3,:]

        @test view(A, 2, Block(1)) == [2,8,14]
        @test view(A, :, Block(1)) == A[:,1:3]

        @test view(V, Block(1, 1)) ≡ V

        @test_throws BlockBoundsError view(V, Block(1,2))
        @test_throws BlockBoundsError view(V, Block(2,1))


        A = PseudoBlockArray(reshape(collect(1:(6^3)),6,6,6), 1:3, 1:3, 1:3)
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
        @test stringmime("text/plain", V) == "1×3 view(::BlockArray{$Int,2,Array{Array{$Int,2},2},$(typeof(axes(A)))}, BlockSlice(Block(1),1:1), BlockSlice(Block{1,$Int}[Block(1), Block(2)],1:1:3)) with eltype $Int with indices Base.OneTo(1)×1:1:3:\n 1  │  2  3"
        @test stringmime("text/plain", W) == "3×1 view(::BlockArray{$Int,2,Array{Array{$Int,2},2},$(typeof(axes(A)))}, BlockSlice(Block{1,$Int}[Block(1), Block(2)],1:1:3), BlockSlice(Block(1),1:1)) with eltype $Int with indices 1:1:3×Base.OneTo(1):\n 1\n ─\n 4\n 7"
    end

    @testset "getindex with BlockRange" begin
        A = BlockArray(randn(6), 1:3)
        @test A[Block.(2:3)] isa BlockArray
        @test A[Block.(2:3)] == A[2:end]
        A = PseudoBlockArray(randn(6), 1:3)
        @test A[Block.(2:3)] isa PseudoBlockArray
        @test A[Block.(2:3)] == A[2:end]
    end

    @testset "non-allocation blocksize" begin
        A = BlockArray(randn(5050), 1:100)
        @test blocksize(A) == (100,)
        @test @allocated(blocksize(A)) ≤ 40
        V = view(A, Block(3))
        @test blocksize(V) == (1,)
        @test @allocated(blocksize(V)) ≤ 40
        V = view(A, Block.(1:30))
        @test blocksize(V) == (30,)
        @test @allocated(blocksize(V)) ≤ 40
        V = view(A, 3:43)
        @test blocksize(V) == (1,)
        V = view(A, 5)
        @test blocksize(V) == ()

        A = BlockArray(randn(5050,21), 1:100, 1:6)
        @test blocksize(A) == (100,6)
        @test @allocated(blocksize(A)) ≤ 40
        V = view(A, Block(3,2))
        @test blocksize(V) == (1,1)
        @test @allocated(blocksize(V)) ≤ 40
        V = view(A, Block.(1:30), Block(3))
        @test blocksize(V) == (30,1)
        @test @allocated(blocksize(V)) ≤ 40
        V = view(A, Block.(1:30), Block.(1:3))
        @test blocksize(V) == (30,3)
        @test @allocated(blocksize(V)) ≤ 40
        V = view(A, 3:43,1:3)
        @test blocksize(V) == (1,1)
        V = view(A, 5, 1:3)
        @test blocksize(V) == (1,)
    end

    @testset "hasmatchingblocks" begin
        A = BlockArray{Int}(undef, 1:20, 1:20)
        B = BlockArray{Int}(undef, 1:3, fill(3,2))
        V = view(A,Block.(1:10),Block.(1:10))

        @test BlockArrays.hasmatchingblocks(A)
        @test BlockArrays.hasmatchingblocks(V)
        @test @allocated(BlockArrays.hasmatchingblocks(V)) == 0
        @test !BlockArrays.hasmatchingblocks(view(A,Block.(1:2),1:3))
        @test !BlockArrays.hasmatchingblocks(view(A,Block.(1:2),Block.(2:3)))

        @test BlockArrays.hasmatchingblocks(view(B,Block.(3:3),Block.(2:2)))
    end

    @testset "sub_materialize cases" begin
        a = BlockArray(randn(6), 1:3)
        b = PseudoBlockArray(randn(6), 1:3)
        @test a[Block.(1:2)] isa BlockArray
        @test b[Block.(1:2)] isa PseudoBlockArray
        @test a[1:3] isa Array
        @test b[1:3] isa Array
        A = BlockArray(randn(6,6), 1:3, fill(3,2))
        B = PseudoBlockArray(randn(6,6), 1:3, fill(3,2))
        @test A[Block.(1:2),Block.(1:2)] isa BlockArray
        @test B[Block.(1:2),Block.(1:2)] isa PseudoBlockArray
        @test A[Block.(1:2),1:3] isa PseudoBlockArray
        @test B[Block.(1:2),1:3] isa PseudoBlockArray
        @test A[1:3,Block.(1:2)] isa PseudoBlockArray
        @test B[1:3,Block.(1:2)] isa PseudoBlockArray
        @test A[Block.(1:2),:] isa BlockArray
        @test B[Block.(1:2),:] isa PseudoBlockArray
        @test blockisequal(axes(A,2),axes(A[Block.(1:2),:],2))
        @test blockisequal(axes(B,2),axes(B[Block.(1:2),:],2))
        @test A[:,Block.(1:2)] isa BlockArray
        @test B[:,Block.(1:2)] isa PseudoBlockArray
        @test blockisequal(axes(A,1),axes(A[:,Block.(1:2)],1))
        @test blockisequal(axes(B,1),axes(B[:,Block.(1:2)],1))
        @test A[:,:] isa BlockArray
        @test B[:,:] isa PseudoBlockArray
        @test blockisequal(axes(A),axes(A[:,:]))
        @test blockisequal(axes(B),axes(B[:,:]))
        @test A[1:3,1:3] isa Array
        @test B[1:3,1:3] isa Array
        A = BlockArray(randn(6,6,6), 1:3, fill(3,2),1:3)
        B = PseudoBlockArray(randn(6,6,6), 1:3, fill(3,2),1:3)
        @test A[Block.(1:2),Block.(1:2),Block.(1:2)] isa BlockArray
        @test B[Block.(1:2),Block.(1:2),Block.(1:2)] isa PseudoBlockArray
        @test A[1:3,Block.(1:2),1:3] isa BlockArray
        @test B[1:3,Block.(1:2),1:3] isa PseudoBlockArray
    end

    @testset "BlockArray BlockRange view" begin
        a = BlockArray(randn(6), 1:3)
        v = view(a, Block(3)[1:2])
        v[1] = 5
        @test a[4] == 5
    end

    @testset "types with custom views" begin
        a = mortar([7:9,5:6])
        v = view(a,Block.(1:2))
        @test a[Block(1)[1:3]] ≡ view(a,Block(1)[1:3]) ≡ view(v,Block(1)[1:3]) ≡ 7:9
    end
end