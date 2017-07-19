@testset "block view" begin
    A = BlockArray(ones(6),1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0

    A = PseudoBlockArray(ones(6),1:3)
    view(A, Block(2))[2] = 3.0
    @test A[3] == 3.0
end
