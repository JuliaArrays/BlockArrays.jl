@testset "eachblock" begin
    v = Array(reshape(1:6, (2, 3)))
    A = BlockArray(v, [1,1], [2,1])
    B = PseudoBlockArray(v, [1,1], [2,1])

    # test that contents match
    @test collect(eachblock(A)) == collect(eachblock(B)) == A.blocks

    # test that eachblock returns views
    first(eachblock(A))[1,2] = 0
    @test A[1,2] == 0
    first(eachblock(B))[1,2] = 0
    @test B[1,2] == 0
end
