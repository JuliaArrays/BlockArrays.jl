@testset "block range" begin
    # test backend code
    @test BlockRange((1:3),) == BlockRange{1,Tuple{UnitRange{Int}}}((1:3,))
    @test BlockRange(1:3) == BlockRange((1:3),)
    @test_throws ArgumentError Block(1,1):Block(2,2)

    @test eltype(Block.(1:2)) == Block{1,Int}
    @test eltype(typeof(Block.(1:2))) == Block{1,Int}
    @test eltype(BlockRange{1}) == Block{1,Int}
    @test Block(1):Block(3) == BlockRange((1:3,))
    @test Block.(1:3) == BlockRange((1:3,))
    @test Int.(BlockRange((1:3,))) == 1:3

    @test collect(Block(1):Block(2)) == Block.([1,2])

    @test_throws ArgumentError Block(1,1):Block(2,2)
    @test_throws ArgumentError Base.to_index(Block(1):Block(2))

    A = BlockArray(collect(1:6), 1:3)
    view(A, Block.(1:2)) == [1,2,3]
    A[Block.(1:2)] == [1,2,3]

    A = BlockArray(reshape(collect(1:(6*12)),6,12), 1:3, 3:5)


    @test view(A, Block.(1:2), Block.(1:2)) == A[1:3,1:7]
    @test A[Block.(1:2), Block.(1:2)] == A[1:3,1:7]
    @test A[BlockRange((1:2,1:2))] == A[1:3,1:7]

    @test view(A, Block.(1:2), Block(1)) == A[1:3,1:3]
    @test A[Block.(1:2), Block(1)] == A[1:3,1:3]

    @test view(A, Block.(1:2), 1) == A[1:3,1]
    @test A[Block.(1:2), 1] == A[1:3,1]

    @test view(A, Block(1), Block.(1:2)) == A[1:1,1:7]
    @test A[1, Block.(1:2)] == A[1,1:7]

    B = BlockRange((1:2,1:2))
    @test collect(B) == [Block(1,1) Block(1,2); Block(2,1) Block(2,2)]
end


using BlockArrays
    import BlockArrays: _cumul_sizes
A = BlockArray(collect(1:6), 1:3)
    V = view(A, Block.(1:2))
    BlockArrays.to_indices(V, (Block(1),))
A = V“
    V = A
    j = 1
    sl = parentindexes(V)[j]

    A = parent(V)
    _cumul_sizes(A, j)

sl.block.indices
ret .- ret[1] .+ 1
BlockArrays._cumul_sizes(A, 1)

cie

parent(A)
inds, I = (indices(A),(Block.(1:2),))
typeof(A)
BlockArrays.unblock(A, inds, I)

N = 1
BlockArrays._unblock(BlockArrays._cumul_sizes(A, N - length(inds) + 1), I)
BlockArrays._cumul_sizes(A, 1 - length(inds) + 1)


typeof(A)
parentindexes(V)
