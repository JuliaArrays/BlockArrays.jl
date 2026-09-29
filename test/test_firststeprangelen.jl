module TestFirstStepRangeLen

using BlockArrays, FillArrays, Test
using BlockArrays: FirstStepRangeLen, firststeprangelen

@testset "FirstStepRangeLen" begin
    r = FirstStepRangeLen(2, 5)

    @testset "construction" begin
        @test r == [2,4,6,8,10]
        @test FirstStepRangeLen{Int}(2, 5) ≡ r
        @test firststeprangelen(2, 5) ≡ r
        @test firststeprangelen(2, Int32(5)) isa StepRangeLen
        @test firststeprangelen(2, Int32(5)) == r
        @test_throws ArgumentError FirstStepRangeLen(2, -1)
    end

    @testset "properties" begin
        @test !isempty(r)
        @test isempty(FirstStepRangeLen(2, 0))
        @test step(r) == Base.step_hp(r) == 2
        @test length(r) == 5
        @test first(r) == 2
        @test last(r) == 10
        @test collect(r) == [2,4,6,8,10]
        @test r[2:3] == [4,6]
    end

    @testset "conversion" begin
        @test StepRangeLen(r) ≡ StepRangeLen(2, 2, 5)
        @test StepRangeLen{Float64}(r) == StepRangeLen(2.0, 2.0, 5)
        @test FillArrays.steprangelen(r) == 2:2:10
        @test FirstStepRangeLen(StepRangeLen(2, 2, 5)) ≡ r
        @test FirstStepRangeLen{Float64}(StepRangeLen(2, 2, 5)) ≡ FirstStepRangeLen(2.0, 5)
        @test FirstStepRangeLen(StepRangeLen(3, 2, 1)) ≡ FirstStepRangeLen(3, 1)
        @test_throws ArgumentError FirstStepRangeLen(StepRangeLen(1, 2, 5))
        @test FirstStepRangeLen{Int,Int}(r) ≡ r
        @test FirstStepRangeLen{Float64,Int}(r) ≡ FirstStepRangeLen(2.0, 5)
        @test FirstStepRangeLen{Float64}(r) ≡ FirstStepRangeLen(2.0, 5)
    end

    @testset "show" begin
        @test sprint(show, r) == "2:2:10"
        @test sprint(show, FirstStepRangeLen(0, 3)) == "FirstStepRangeLen(0, 0, 3)"
    end

    @testset "equality" begin
        @test r == FirstStepRangeLen(2, 5)
        @test r ≠ FirstStepRangeLen(2, 4)
        @test FirstStepRangeLen(2, 0) == FirstStepRangeLen(3, 0)
        @test r == 2:2:10
        @test 2:2:10 == r
        @test r == StepRangeLen(2, 2, 5)
        @test StepRangeLen(2, 2, 5) == r
    end

    @testset "promotion" begin
        @test promote_type(FirstStepRangeLen{Int,Int}, FirstStepRangeLen{Float64,Int}) == FirstStepRangeLen{Float64,Int}
        @test promote_type(FirstStepRangeLen{Int,Int}, StepRangeLen{Int,Int,Int,Int}) <: StepRangeLen
        @test promote_type(LinRange{Float64,Int}, FirstStepRangeLen{Float64,Int}) <: StepRangeLen
    end

    @testset "arithmetic" begin
        @test -r ≡ FirstStepRangeLen(-2, 5)
        @test r + r ≡ FirstStepRangeLen(4, 5)
        @test r - r ≡ FirstStepRangeLen(0, 5)
        @test_throws DimensionMismatch r + FirstStepRangeLen(2, 4)
        @test reverse(r) == [10,8,6,4,2]
    end

    @testset "broadcasting" begin
        @test (-).(r) ≡ FirstStepRangeLen(-2, 5)
        @test r .+ 1 == [3,5,7,9,11]
        @test 1 .+ r == [3,5,7,9,11]
        @test r .- 1 == [1,3,5,7,9]
        @test 1 .- r == [-1,-3,-5,-7,-9]
        @test 2 .* r ≡ r .* 2 ≡ FirstStepRangeLen(4, 5)
        @test r ./ 2 ≡ FirstStepRangeLen(1.0, 5)
        @test 2 .\ r ≡ FirstStepRangeLen(1.0, 5)
        @test big.(r) isa FirstStepRangeLen{BigInt}
        @test big.(r) == r
    end
end

end # module
