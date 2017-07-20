@testset "block view" begin
    A = BlockArray(ones(6),1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0

    # backend tests
    @test_throws ArgumentError Base.to_index(A, Block(1))

    A = PseudoBlockArray(ones(6),1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0


    # backend tests
    @test_throws ArgumentError Base.to_index(A, Block(1))

    A = BlockArray(ones(6,12),1:3,3:5)
    V = view(A,Block(2),Block(3))
    @test size(V) == (2,5)
    V[1,1] = 2
    @test A[2,8] == 2

    A = BlockArray(ones(6,6,6),1:3,1:3,1:3)
    V = view(A,Block(2),Block(3),Block(1))
    @test size(V) == (2,3,1)
    V[1,1,1] = 2
    @test A[2,4,1] == 2
end
