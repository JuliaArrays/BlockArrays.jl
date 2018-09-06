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

    ## views of views
    # here we want to ensure that the view collapses
    A = BlockArray(collect(1:10), 1:4)
    V = view(view(A, Block.(2:4)), Block(2))
    @test parent(V) == A
    @test parentindices(V)[1] isa BlockArrays.BlockSlice{Block{1,Int}}
    @test V == view(A, Block.(2:4))[Block(2)] == [4,5,6]

    V = view(view(A, Block.(2:4)), Block.(1:2))
    @test parent(V) == A
    @test parentindices(V)[1] isa BlockArrays.BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}
    @test V == view(A, Block.(2:4))[Block.(1:2)] == Vector(2:6)

    A = BlockArray(reshape(collect(1:(6*12)),6,12), 1:3, 3:5)
    V = view(view(A, Block.(2:3), Block.(1:3)), Block(2), Block(2))
    @test parent(V) == A
    @test parentindices(V)[1] isa BlockArrays.BlockSlice{Block{1,Int}}
    @test parentindices(V)[1].block == Block(3)
    @test all(ind -> ind isa BlockArrays.BlockSlice, parentindices(V))
    @test V == view(A, Block.(2:3), Block.(1:3))[Block(2,2)] ==  A[Block(3, 2)]


    V = view(view(A, Block.(1:3), Block.(2:3)), Block.(1:2), Block(2))
    @test parent(V) == A
    @test all(ind -> ind isa BlockArrays.BlockSlice, parentindices(V))
    @test V ==  A[Block.(1:2), Block(3)]

    V = view(view(A, Block.(1:3), Block.(2:3)), Block.(1:2), Block.(1:2))
    @test parent(V) == A
    @test all(ind -> ind isa BlockArrays.BlockSlice, parentindices(V))
    @test V ==  A[Block.(1:2), Block.(2:3)]
end


@testset "block index range" begin
	B = Block(2)
	Bi = B[2:3]

	@test Block(Bi) == B
	@test collect(Bi) == [BlockIndex((2,), 2), BlockIndex((2,), 3)]

	A = PseudoBlockArray(rand(4), [1,3])

	@test BlockArrays._unblock(BlockArrays.blocksizes(A).cumul_sizes[1], (Bi,)) ==
			BlockArrays.unblock(A, axes(A), (Bi, )) == BlockArrays.BlockSlice(Bi, 3:4) ==
			parentindices(view(A, Bi))[1] == BlockArrays.BlockSlice(Bi, 3:4)

	@test A[Bi] == A[3:4]

    A = PseudoBlockArray(rand(4,4), [1,3],[2,2])
	@test A[Bi,Block(1)] == A[3:4,1:2]
    @test A[Bi,Block(1)[2:2]] == A[3:4,2:2]
end
