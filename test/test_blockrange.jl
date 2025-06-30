module TestBlockRange

using BlockArrays, Test

@testset "block range" begin
    # test backend code
    @test BlockRange((1:3,)) == BlockRange{1,Tuple{UnitRange{Int}}}((1:3,))
    @test BlockRange(1:3) === BlockRange(Base.OneTo(1))
    @test_throws ArgumentError Block(1,1):Block(2,2)

    @test eltype(Block.(1:2)) == Block{1,Int}
    @test eltype(typeof(Block.(1:2))) == Block{1,Int}
    @test eltype(BlockRange{1}) == Block{1,Int}
    @test Block(1):Block(3) == BlockRange((1:3,))
    @test Block.(1:3) == BlockRange((1:3,))

    @test collect(Block(1):Block(2)) == Block.([1,2])

    @test_throws ArgumentError Block(1,1):Block(2,2)
    @test_throws ArgumentError Base.to_index(Block(1):Block(2))

    A = BlockArray(1:6, 1:3)
    @test view(A, Block.(1:2)) == [1,2,3]
    @test A[Block.(1:2)] == [1,2,3]

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
    A = BlockArray((1:10), 1:4)
    @test view(view(A, Block.(2:4)), Block(2)) ≡ 4:6

    V = view(view(A, Block.(2:4)), Block.(1:2))
    @test parent(V) == A
    @test parentindices(V)[1] isa BlockArrays.BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}
    @test V == view(A, Block.(2:4))[Block.(1:2)] == Vector(2:6)

    A = BlockArray(reshape(collect(1:(6*12)),6,12), 1:3, 3:5)
    V = view(view(A, Block.(2:3), Block.(1:3)), Block(2), Block(2))
    @test V ≡ view(A, Block(3,2))
    @test V == view(A, Block.(2:3), Block.(1:3))[Block(2,2)] ==  A[Block(3, 2)]


    V = view(view(A, Block.(1:3), Block.(2:3)), Block.(1:2), Block(2))
    @test parent(V) == A
    @test all(ind -> ind isa BlockArrays.BlockSlice, parentindices(V))
    @test V ==  A[Block.(1:2), Block(3)]
    @test blockisequal(axes(V,1), axes(A,1)[Block.(1:2)])

    V = view(view(A, Block.(1:3), Block.(2:3)), Block.(1:2), Block.(1:2))
    @test parent(V) == A
    @test all(ind -> ind isa BlockArrays.BlockSlice, parentindices(V))
    @test V ==  A[Block.(1:2), Block.(2:3)]

    @testset "iterator" begin
        @test BlockRange(())[] == collect(BlockRange(()))[] == Block()
        @test BlockRange((1:3,)) == collect(BlockRange((1:3,))) == [Block(1),Block(2),Block(3)]
        @test BlockRange((1:3,1:2)) == collect(BlockRange((1:3,1:2)))
    end

    # non Int64 range
    r = blockedrange([Int32(1)])
    @test convert(AbstractUnitRange{Int64}, r) isa BlockedOneTo{Int64}
    v = mortar([[1]], (r,))
    @test Int.(v) == v

    r = blockedrange([Int32(1)])[Block(1):Block(1)]
    @test convert(AbstractUnitRange{Int64}, r) isa BlockedUnitRange{Int64}
    v = mortar([[1]], (r,))
    @test Int.(v) == v
end

@testset "block index range" begin
	B = Block(2)
	Bi = B[2:3]

	@test Block(Bi) == B
	@test collect(Bi) == [BlockIndex((2,), 2), BlockIndex((2,), 3)]

	A = BlockedArray(rand(4), [1,3])

	@test A[Bi] == A[3:4]

    A = BlockedArray(rand(4,4), [1,3],[2,2])
	@test A[Bi,Block(1)] == A[3:4,1:2]
    @test A[Bi,Block(1)[2:2]] == A[3:4,2:2]

    @testset "iterate" begin
        bi = Block(2)[2:3]
        @test bi == collect(bi) == [Block(2)[2], Block(2)[3]]
        @test length(bi) == 2
        @test first(bi) == Block(2)[2]
        @test last(bi) == Block(2)[3]
        bi = Block(1,2)[1:2,2:3]
        @test bi == collect(bi)
        @test size(bi) == (2,2)
    end
end

end # module
