module TestBlockReduce

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

@testset "sum (#141)" begin
    data = reshape(collect(1:20), 4, 5)
    A = BlockArray(data, [1,3], [2,3])
    @test sum(A) == sum(data)
    @test sum(A; dims=1) == sum(data; dims=1)
    @test sum(A; dims=2) == sum(data; dims=2)
    @test blockisequal(axes(A,2), axes(sum(A; dims=1),2))
    @test blockisequal(axes(A,1), axes(sum(A; dims=2),1))
end

end # module
