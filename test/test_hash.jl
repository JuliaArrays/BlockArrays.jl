module TestHash

using BlockArrays, Test, Infinities

# A minimal infinite axis, after `test/testhelpers/InfiniteArrays.jl` in `Base`. It is inlined here
# rather than given its own file because `find_tests` would pick that file up as a test suite.
module InfiniteAxes
    using Infinities
    export OneToInf

    abstract type AbstractInfUnitRange{T<:Real} <: AbstractUnitRange{T} end
    Base.length(r::AbstractInfUnitRange) = ℵ₀
    Base.size(r::AbstractInfUnitRange) = (ℵ₀,)
    Base.last(r::AbstractInfUnitRange) = ℵ₀
    Base.IteratorSize(::Type{<:AbstractInfUnitRange}) = Base.IsInfinite()

    struct OneToInf{T<:Integer} <: AbstractInfUnitRange{T} end
    OneToInf() = OneToInf{Int}()
    Base.axes(r::OneToInf) = (r,)
    Base.first(r::OneToInf{T}) where {T} = oneunit(T)
    Base.getindex(r::OneToInf{T}, i::Integer) where {T} =
        (@boundscheck i > 0 || throw(BoundsError(r, i)); convert(T, i))
end
using .InfiniteAxes

@testset "hash" begin
    @testset "finite ranges hash as in Base" begin
        @test hash(blockedrange([2,3])) == hash(1:5)
        @test hash(blockedrange([2,3]), UInt(7)) == hash(1:5, UInt(7))
        @test hash(blockedrange(2, [2,3])) == hash(2:6)
        @test hash(Block(1):Block(3)) == hash([Block(1), Block(2), Block(3)])
    end

    @testset "infinite ranges" begin
        # blocks of length one, so that the cumulative lengths are the axis itself
        b = BlockedOneTo(OneToInf())
        @test hash(b) isa UInt
        @test hash(b) == hash(BlockedOneTo(OneToInf()))
        @test hash(b) == hash(BlockedOneTo(OneToInf{Int16}()))
        @test hash(b, UInt(7)) == hash(BlockedOneTo(OneToInf()), UInt(7))
        @test hash(b) ≠ hash(blockedrange([1,1,1]))

        br = BlockRange((OneToInf(),))
        @test hash(br) isa UInt
        @test hash(br) == hash(BlockRange((OneToInf(),)))
        @test hash(br) ≠ hash(Block(1):Block(3))
    end
end

end # module
