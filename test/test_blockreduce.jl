module TestBlockReduce

using BlockArrays, Test

@testset "foldl" begin
    x = mortar([rand(3), rand(2)])
    @test foldl(push!, x; init = []) == collect(x)

    x = BlockedVector(rand(3), [1, 2])
    @test foldl(push!, x; init = []) == collect(x)
end

@testset "reduce" begin
    x = mortar([rand(Int, 3), rand(Int, 2)])
    @test reduce(+, x) == sum(collect(x))

    x = BlockedVector(rand(Int, 3), [1, 2])
    @test reduce(+, x) == sum(collect(x))
end

@testset "sum (#141)" begin
    data = reshape(collect(1:20), 4, 5)
    A = BlockArray(data, [1,3], [2,3])
    @test @inferred(sum(A)) == sum(data)
    @test @inferred(mapreduce(identity, Base.add_sum, A)) == sum(data)
    @test mapreduce(identity, Base.add_sum, A; init=10) == sum(data; init=10)
    @test mapreduce(identity, Base.add_sum, A; dims=1) == sum(data; dims=1)
    @test @inferred(sum(abs2, A)) == sum(abs2, data)
    @test @inferred(mapreduce(abs2, Base.add_sum, A)) == sum(abs2, data)
    @test mapreduce(abs2, Base.add_sum, A; init=10) == sum(abs2, data; init=10)
    @test mapreduce(abs2, Base.add_sum, A; dims=2) == sum(abs2, data; dims=2)
    @test sum(A; init=10) == sum(data; init=10)
    @test sum(A; dims=1) == sum(data; dims=1)
    @test sum(A; dims=2) == sum(data; dims=2)
    @test blockisequal(axes(A,2), axes(sum(A; dims=1),2))
    @test blockisequal(axes(A,1), axes(sum(A; dims=2),1))

    smallints = BlockArray(fill(Int8(1), 4, 4), [2, 2], [1, 3])
    @test sum(smallints) === sum(Matrix(smallints)) === 16

    emptyblocks = BlockArray(zeros(0, 0), Int[], Int[])
    @test sum(emptyblocks) === 0.0
    @test sum(abs2, emptyblocks) === 0.0
    @test sum(emptyblocks; init=10.0) === 10.0

    v = BlockArray(collect(1:6), [2, 4])
    @test @inferred(sum(v)) == 21
    @test @inferred(mapreduce(identity, Base.add_sum, v)) == 21
    @test @inferred(sum(abs2, v)) == 91
    @test @inferred(mapreduce(abs2, Base.add_sum, v)) == 91
end

end # module
