module TestBlockArraysAdapt

using BlockArrays, Adapt, Test

@testset "Adapt" begin
    @testset "Adapt Ranges" begin
        @test blockisequal(adapt(Array, blockedrange([2, 3])), blockedrange([2, 3]))
        @test blockisequal(adapt(Array, blockedrange(2, [2, 3])), blockedrange(2, [2, 3]))
    end

    @testset "Adapt Block Arrays" begin
        a = BlockArray(randn(4, 4), [2, 2], [2, 2])
        @test blockisequal(adapt(Array, a), a)
        @test blockisequal(adapt(Array, view(a, :, :)), a)

        a = BlockedArray(randn(4, 4), [2, 2], [2, 2])
        @test blockisequal(adapt(Array, a), a)
        @test blockisequal(adapt(Array, view(a, :, :)), a)
    end
end

end
