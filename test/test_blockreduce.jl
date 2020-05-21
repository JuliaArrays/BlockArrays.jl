using BlockArrays, Test

@testset "foldl" begin
    x = mortar([rand(3), rand(2)])
    @test foldl(push!, x; init = []) == collect(x)

    x = PseudoBlockVector(rand(3), [1, 2])
    @test foldl(push!, x; init = []) == collect(x)
end

@testset "reduce" begin
    x = mortar([rand(Int, 3), rand(Int, 2)])
    @test reduce(+, x) == sum(collect(x))

    x = PseudoBlockVector(rand(Int, 3), [1, 2])
    @test reduce(+, x) == sum(collect(x))
end
