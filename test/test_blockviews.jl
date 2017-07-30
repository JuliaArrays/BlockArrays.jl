


@testset "block slice" begin
    A = BlockArray(ones(6),1:3)
    b = parentindexes(view(A, Block(2)))[1] # A BlockSlice

    @test first(b) == 2
    @test last(b) == 3
    @test length(b) == 2
    @test Base.unsafe_length(b) == 2
    @test indices(b) == (Base.OneTo(2),)
    @test Base.indices1(b) == Base.OneTo(2)
    @test Base.unsafe_indices(b) == (Base.OneTo(2),)
    @test size(b) == (2,)
    @test collect(b) == [2,3]
    @test b[1] == 2
    @test b[1:2] == 2:3
end

@testset "block view" begin
    A = BlockArray(ones(6), 1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0

    # backend tests
    @test_throws ArgumentError Base.to_index(A, Block(1))

    A = PseudoBlockArray(ones(6), 1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0


    # backend tests
    @test_throws ArgumentError Base.to_index(A, Block(1))

    A = BlockArray(ones(6,12), 1:3, 3:5)
    V = view(A, Block(2), Block(3))
    @test size(V) == (2, 5)
    V[1,1] = 2
    @test A[2,8] == 2

    V = view(A, Block(3, 2))
    @test size(V) == (3, 4)
    V[2,1] = 3
    @test A[5,4] == 3

    A = BlockArray(ones(6,6,6), 1:3, 1:3, 1:3)
    V = view(A, Block(2), Block(3), Block(1))
    @test size(V) == (2, 3, 1)
    V[1,1,1] = 2
    @test A[2,4,1] == 2

    V = view(A,Block(1,1,1))
    @test size(V) == (1,1,1)
    V[1,1,1] = 4
    @test A[1,1,1] == 4

    # blocks mimic CartesianIndex in views
    V = view(A,Block(1,1),Block(2))
    @test size(V) == (1,1,2)
    V[1,1,1] = 5
    @test A[1,1,2] == 5

    V = view(A,Block(2),Block(1,1))
    @test size(V) == (2,1,1)
    V[1,1,1] = 6
    @test A[2,1,1] == 6
end
