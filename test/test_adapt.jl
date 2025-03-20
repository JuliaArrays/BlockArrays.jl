module TestBlockArraysAdapt

using BlockArrays, Adapt, Test

@testset "Adapt" begin
    @testset "Adapt Ranges" begin
        @test blockisequal(adapt(Array, blockedrange([2, 3])), blockedrange([2, 3]))
        @test blockisequal(adapt(Array, blockedrange(2, [2, 3])), blockedrange(2, [2, 3]))
    end

    @testset "Adapt Block Arrays" begin
        A = BlockArray(randn(4, 4), [2, 2], [2, 2])
        Ã = adapt(Array, A)
        @test Ã == A
        @test Ã isa BlockArray{Float64}
        @test blockisequal(axes(Ã), axes(A))
        V = view(A, :, :)
        Ṽ = adapt(Array, V)
        @test Ṽ  == V
        @test Ṽ isa SubArray
        @test parent(Ṽ) isa BlockArray{Float64}
        @test blockisequal(axes(parent(Ṽ)), axes(A))

        A = BlockedArray(randn(4, 4), [2, 2], [2, 2])
        Ã = adapt(Array, A)
        @test Ã == A
        @test Ã isa BlockedArray{Float64}
        @test blockisequal(axes(Ã), axes(A))
        V = view(A, :, :)
        Ṽ = adapt(Array, V)
        @test Ṽ  == V
        @test Ṽ isa SubArray
        @test parent(Ṽ) isa BlockedArray{Float64}
        @test blockisequal(axes(parent(Ṽ)), axes(A))
    end
end

end
