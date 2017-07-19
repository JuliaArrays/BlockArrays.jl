
@testset "block indexing" begin
    BA_1 = BlockArray(Vector{Float64}, [1,2,3])
    a_1 = rand(2)
    BA_1[Block(2)] = a_1
    @test BA_1[BlockIndex(2, 1)] == a_1[1]
    @test BA_1[BlockIndex(2, 2)] == a_1[2]
    @test BA_1[Block(2)] == a_1
    @test BA_1[2] == a_1[1]
    @test_throws DimensionMismatch BA_1[Block(3)] = rand(4)
    @test_throws BlockBoundsError blockcheckbounds(BA_1, 4)
    @test_throws BlockBoundsError BA_1[Block(4)]

    BA_2 = BlockArray(Matrix{Float64}, [1,2], [3,4])
    a_2 = rand(1,4)
    BA_2[Block(1,2)] = a_2
    @test BA_2[Block(1,2)] == a_2
    BA_2[Block(1,2)] = a_2

    @test BA_2[1,5] == a_2[2]
    @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
end

@testset "misc block tests" begin
    for BlockType in (BlockArray, PseudoBlockArray)
        a_1 = rand(6)
        BA_1 = BlockType(a_1, [1,2,3])
        @test Array(BA_1) == a_1
        @test nblocks(BA_1) == (3,)
        @test nblocks(BA_1,1) == 3
        @test eltype(similar(BA_1, Float32)) == Float32
        q = rand(1)
        BA_1[Block(1)] = q
        BA_1[BlockIndex(3, 2)] = a_1[5]
        @test BA_1[Block(1)] == q
        if BlockType == PseudoBlockArray
            q2 = zeros(q)
            getblock!(q2, BA_1, 1)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(2), BA_1, 1)
            fill!(q2, 0)
            getblock!(q2, BA_1, 1)
            @test q2 == q
        end
        fill!(BA_1, 1.0)
        @test BA_1 == ones(size(BA_1))
        ran = rand(size(BA_1))
        copy!(BA_1, ran)
        @test BA_1 == ran

        a_1_sparse = sprand(6, 0.9)
        BA_1_sparse = BlockType(a_1_sparse, [1,2,3])
        @test Array(BA_1_sparse) == a_1_sparse
        BA_1_sparse[4] = 3.0
        @test BA_1_sparse[4] == 3.0


        a_2 = rand(3, 7)
        BA_2 = BlockType(a_2, [1,2], [3,4])
        @test Array(BA_2) == a_2
        @test nblocks(BA_2) == (2,2)
        @test nblocks(BA_2, 1) == 2
        @test nblocks(BA_2, 2, 1) == (2, 2)
        BA_2[BlockIndex((2,1), (2,2))] = a_2[3,2]
        @test eltype(similar(BA_2, Float32)) == Float32
        q = rand(1,4)
        BA_2[Block(1,2)] = q
        @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
        @test BA_2[Block(1,2)] == q
        if BlockType == PseudoBlockArray
            q2 = zeros(q)
            getblock!(q2, BA_2, 1, 2)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(1,5), BA_2, 1, 2)
        end
        fill!(BA_2, 1.0)
        @test BA_2 == ones(size(BA_2))
        ran = rand(size(BA_2))
        copy!(BA_2, ran)
        @test BA_2 == ran

        a_2_sparse = sprand(3, 7, 0.9)
        BA_2_sparse = BlockType(a_2_sparse, [1,2], [3,4])
        @test Array(BA_2_sparse) == a_2_sparse
        BA_2_sparse[1,2] = 3.0
        @test BA_2_sparse[1,2] == 3.0

        a_3 = rand(3, 7,4)
        BA_3 = BlockType(a_3, [1,2], [3,4], [1,2,1])
        @test Array(BA_3) == a_3
        @test nblocks(BA_3) == (2,2,3)
        @test nblocks(BA_3, 1) == 2
        @test nblocks(BA_3, 3, 1) == (3, 2)
        @test nblocks(BA_3, 3) == 3
        BA_3[BlockIndex((1,1,1), (1,1,1))] = a_3[1,1,1]
        @test eltype(similar(BA_3, Float32)) == Float32
        q = rand(1,4,2)
        BA_3[Block(1,2,2)] = q
        @test BA_3[Block(1,2,2)] == q
        if BlockType == PseudoBlockArray
            q3 = zeros(q)
            getblock!(q3, BA_3, 1, 2, 2)
            @test q3 == q
            @test_throws DimensionMismatch getblock!(zeros(1,3,2), BA_3, 1, 2,2)
        end
        fill!(BA_3, 1.0)
        @test BA_3 == ones(size(BA_3))
        ran = rand(size(BA_3))
        copy!(BA_3, ran)
        @test BA_3 == ran
    end
end

@testset "string" begin
    A = BlockArray(rand(4, 5), [1,3], [2,3]);
    buf = IOBuffer()
    Base.showerror(buf, BlockBoundsError(A, (3,2)))
    @test String(take!(buf)) == "BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [3,2]"
end

if isdefined(Base, :flatten)
    flat = Base.flatten
else
    flat = Base.Iterators.flatten
end


replstrmime(x) = stringmime("text/plain", x)
@test replstrmime(BlockArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])) == "2×2-blocked 4×4 BlockArrays.BlockArray{Int64,2,Array{Int64,2}}:\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"


@testset "AbstractVector{Int} blocks" begin
    A = BlockArray(ones(6,6),1:3,1:3)
    @test A[1,1] == 1
    @test A[Block(2,3)] == ones(2,3)

    A = BlockArray(Matrix{Float64},1:3,1:3)
    A[Block(2,3)] = ones(2,3)
    @test A[Block(2,3)] == ones(2,3)
end
