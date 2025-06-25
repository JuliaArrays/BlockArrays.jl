module TestBlockIndices

using BlockArrays, FillArrays, Test, StaticArrays, ArrayLayouts
using OffsetArrays
import BlockArrays: BlockIndex, BlockIndexRange, BlockSlice

@testset "Blocks" begin
    @test Int(Block(2)) === Integer(Block(2)) === Number(Block(2)) === 2
    @test Tuple(Block(2,3)) === (Block(2),Block(3))
    @test Block((Block(3), Block(4))) === Block(3,4)
    @test Block() === Block(()) === Block{0}() === Block{0}(())
    @test Block(1) === Block((1,)) === Block{1}(1) === Block{1}((1,))
    @test Block(1,2) === Block((1,2)) === Block{2}(1,2) === Block{2}((1,2))

    @testset "Block iterator" begin
        B = Block(3)
        @test length(B) == 1
        @test eltype(B) == eltype(typeof(B)) == Block{1,Int}
        @test ndims(B) == ndims(Block{1,Int}) == 0
        @test !isempty(B)
        @test collect(B) == [B]
        @test B .+ 1 == Block(4)
        @test iterate(B) == (B, nothing)
        @test Int.(B) == 3
    end

    @testset "Block arithmetic" begin
        @test +(Block(1)) == Block(1)
        @test -(Block(1)) == Block(-1)
        @test Block(2) + Block(1) == Block(3)
        @test Block(2) + 1 == Block(3)
        @test 2 + Block(1) == Block(3)
        @test Block(2) - Block(1) == Block(1)
        @test Block(2) - 1 == Block(1)
        @test 2 - Block(1) == Block(1)
        @test 2*Block(1) == Block(2)
        @test Block(1)*2 == Block(2)

        @test isless(Block(1), Block(2))
        @test !isless(Block(1), Block(1))
        @test !isless(Block(2), Block(1))
        @test Block(1) < Block(2)
        @test Block(1) ≤ Block(1)
        @test Block(2) > Block(1)
        @test Block(1) ≥ Block(1)
        @test min(Block(1), Block(2)) == Block(1)
        @test max(Block(1), Block(2)) == Block(2)

        @test +(Block(1,2)) == Block(1,2)
        @test -(Block(1,2)) == Block(-1,-2)
        @test Block(1,2) + Block(2,3) == Block(3,5)
        @test Block(1,2) + 1 == Block(2,3)
        @test 1 + Block(1,2) == Block(2,3)
        @test oneunit(Block(1,2)) + Block(1,2) == Block(2,3)
        @test Block(2,3) - Block(1,2) == Block(1,1)
        @test Block(1,2) - 1 == Block(0,1)
        @test 1 - Block(1,2) == Block(0,-1)
        @test 2*Block(1,2) == Block(2,4)
        @test Block(1,2)*2 == Block(2,4)
        @test one(Block(1,2))*Block(1,2) == Block(1,2)
        @test one(Block(1,2))*Block(Int8(1)) === Block(Int8(1))

        @test isless(Block(1,1), Block(2,2))
        @test isless(Block(1,1), Block(2,1))
        @test !isless(Block(1,1), Block(1,1))
        @test !isless(Block(2,1), Block(1,1))
        @test Block(1,1) < Block(2,1)
        @test Block(1,1) ≤ Block(1,1)
        @test Block(2,1) > Block(1,1)
        @test Block(1,1) ≥ Block(1,1)
        @test min(Block(1,2), Block(2,2)) == Block(1,2)
        @test max(Block(1,2), Block(2,2)) == Block(2,2)

        @test convert(Int, Block(2)) == 2
        @test convert(Float64, Block(2)) == 2.0
        @test convert(Tuple, Block(2,3)) == (Block(2),Block(3))
        @test convert(Tuple{Vararg{Int}}, Block(2,3)) == (2,3)

        @test_throws MethodError convert(Int, Block(2,1))
        @test convert(Tuple{Int,Int}, Block(2,1)) == (2,1)
        @test convert(Tuple{Float64,Int}, Block(2,1)) == (2.0,1)

        @test Block(1)[:] ≡ Block(1)[Base.Slice(1:2)] ≡ Block(1)
    end

    @testset "BlockIndex" begin
        @test Block()[] == BlockIndex()
        @test Block(1)[1] == BlockIndex((1,),(1,))
        @test Block(1)[1:2] == BlockIndexRange(Block(1),(1:2,))
        @test Block(1,1)[1,1] == BlockIndex((1,1),(1,1)) == BlockIndex((1,1),(1,))
        @test Block(1,1)[1:2,1:2] == BlockIndexRange(Block(1,1),(1:2,1:2))
        @test Block(1)[1:3][1:2] == BlockIndexRange(Block(1),1:2)
        @test Block(1,1)[2:4,2:4][2:3,2:3] == BlockIndexRange(Block(1,1),(3:4,3:4))
        @test BlockIndexRange(Block(),())[] == BlockIndex()
        @test BlockIndex((2,2,2),(2,)) == BlockIndex((2,2,2),(2,1,)) == BlockIndex((2,2,2),(2,1,1))
        @test BlockIndex(2,(2,)) === BlockIndex((2,),(2,))
        @test BlockIndex(UInt(2),(2,)) === BlockIndex((UInt(2),),(2,))
        @test BlockIndex(Block(2),2) === BlockIndex(Block(2),(2,))
        @test BlockIndex(Block(2),UInt(2)) === BlockIndex(Block(2),(UInt(2),))
        @test copy(Block(1)[1:2]) === BlockIndexRange(Block(1),1:2)
    end

    @testset "BlockRange" begin
        @test Block.(2:5) isa BlockRange
        @test Block.(Base.OneTo(5)) isa BlockRange
        @test Block.(2:5) == [Block(2),Block(3),Block(4),Block(5)]
        b = Block.(2:5)
        @test Int.(b) === 2:5
        @test Base.OneTo.(1:5) isa Vector{Base.OneTo{Int}} #98
        @test Base.OneTo(5)[Block.(1:1)] === Base.OneTo(5)
        @test_throws BlockBoundsError Base.OneTo(5)[Block.(1:3)]

        @test intersect(Block.(2:5), Block.(3:6)) ≡ Block.(3:5)
    end

    @testset "view into CartesianIndices/ranges" begin
        r = 2:10
        @test view(r, Block(1)) === r
        @test_throws BlockBoundsError view(r, Block(2))
        C = CartesianIndices((2:10, 2:10))
        ==ᵥ = VERSION >= v"1.10" ? (===) : (==)

        @test view(C, Block(1,1)) ==ᵥ C
        @test view(C, Block(1), Block(1)) == C
        @test_throws BlockBoundsError view(C, Block(1), Block(2))
        @test_throws BlockBoundsError view(C, Block(1,2))

        B = BlockArray([1:3;], [2,1])
        Cb = CartesianIndices(B)
        @test view(Cb, Block(1)) ==ᵥ CartesianIndices((1:2,)) == Cb[Block(1)]
        @test view(Cb, Block(2)) ==ᵥ CartesianIndices((3:3,)) == Cb[Block(2)]

        B = BlockArray(reshape([1:9;],3,3), [2,1], [2,1])
        Cb = CartesianIndices(B)
        @test view(Cb, Block(1,1)) ==ᵥ CartesianIndices((1:2,1:2)) == Cb[Block(1,1)]
        @test view(Cb, Block(1,2)) ==ᵥ CartesianIndices((1:2, 3:3)) == Cb[Block(1,2)]
        @test view(Cb, Block(2,1)) ==ᵥ CartesianIndices((3:3,1:2)) == Cb[Block(2,1)]
        @test view(Cb, Block(2,2)) ==ᵥ CartesianIndices((3:3, 3:3)) == Cb[Block(2,2)]
        for i in 1:2, j in 1:2
            @test view(Cb, Block(j), Block(i)) ==ᵥ view(Cb, Block(j, i))
        end
        # ensure that calls with mismatched ndims don't error
        @test view(Cb, Block(1)) == view(Cb, to_indices(Cb, (Block(1),))...)
        @test reshape(view(Cb, Block(1), Block(1), Block(1)), 2, 2) == view(Cb, Block(1), Block(1))
    end

    @testset "print" begin
        @test sprint(show, "text/plain", Block()) == "Block()"
        @test sprint(show, "text/plain", Block(1)) == "Block(1)"
        @test sprint(show, "text/plain", Block(1,2)) == "Block(1, 2)"
        @test sprint(show, "text/plain", Block{0}()) == "Block()"
        @test sprint(show, "text/plain", Block{1}(1)) == "Block(1)"
        @test sprint(show, "text/plain", Block{2}(1,2)) == "Block(1, 2)"

        @test sprint(show, "text/plain", Block{0,BigInt}()) == "Block{0, BigInt}()"
        @test sprint(show, "text/plain", Block{1,BigInt}(1)) == "Block{1, BigInt}(1)"
        @test sprint(show, "text/plain", Block{2}(1,2)) == "Block(1, 2)"

        @test sprint(show, "text/plain", BlockIndex((1,2), (3,4))) == "Block(1, 2)[3, 4]"
        @test sprint(show, "text/plain", BlockArrays.BlockIndexRange(Block(1), 3:4)) == "Block(1)[3:4]"

        @test sprint(show, "text/plain", BlockRange()) == "BlockRange()"
        @test sprint(show, "text/plain", BlockRange(1:2)) == "BlockRange(1:2)"
        @test sprint(show, "text/plain", BlockRange(1:2, 2:3)) == "BlockRange(1:2, 2:3)"
        @test sprint(show, BlockRange(1:2, 2:3)) == "BlockRange(1:2, 2:3)"
    end
end

@testset "BlockedUnitRange" begin
    @testset "promote" begin
        b = blockedrange(1, [1,2,3])
        @test promote(b, 1:2) == (1:6, 1:2)
        @test promote(b, Base.OneTo(2)) == (1:6, 1:2)
    end
    @testset "Block indexing" begin
        b = blockedrange(1, [1,2,3])
        @test axes(b) == (b,)
        @test blockaxes(b,1) isa BlockRange

        @test @inferred(b[Block(1)]) === 1:1
        @test b[Block(2)] === 2:3
        @test b[Block(3)] === 4:6
        @test @inferred(view(b, Block(3))) === 4:6
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]
        @test_throws BlockBoundsError view(b, Block(4))

        b = blockedrange(2, 1:3)
        bpart = @inferred(b[Block.(1:2)])
        @test bpart isa BlockedUnitRange
        @test bpart == blockedrange(2, 1:2)
        bpart = @inferred(b[Block.(Base.OneTo(2))])
        @test bpart isa BlockedUnitRange
        @test bpart == blockedrange(2, 1:2)
        bpart = @inferred(b[Block.(Base.OneTo(0))])
        @test bpart isa BlockedUnitRange
        @test bpart == blockedrange(2, 1:0)

        o = OffsetArray([2,2,3],-1:1)
        @test_throws ArgumentError blockedrange(1, o)

        b = BlockArrays._BlockedUnitRange(-1,[-1,1,4])
        @test axes(b,1) == blockedrange(1, [1,2,3])
        @test b[Block(1)] == -1:-1
        @test b[Block(2)] == 0:1
        @test b[Block(3)] == 2:4
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        b = BlockArrays._BlockedUnitRange(1, cumsum(Fill(3,1_000_000)))
        @test b isa BlockedUnitRange{Int,<:AbstractRange}
        @test b[Block(100_000)] == 299_998:300_000
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(1_000_001)]

        b = BlockRange((2:4, 3:4))
        @test b[2,2] === Block(3,4)
        @test b[axes(b)...] === b

        b = BlockRange(OffsetArrays.IdOffsetRange.((2:4, 3:5), 2))
        @test b[axes(b)...] === b

        b = BlockRange(3)
        for i in 1:3
            @test b[i] == Block(i)
        end

        B = mortar(fill(rand(1,1),2,2))
        br = BlockRange(B)
        @test collect(br) == [Block(Int(i),Int(j)) for i in blockaxes(B,1), j in blockaxes(B,2)]
    end

    @testset "firsts/lasts/lengths" begin
        b = blockedrange(1, [1,2,3])
        @test @inferred(blockfirsts(b)) == [1,2,4]
        @test @inferred(blocklasts(b)) == [1,3,6]
        @test @inferred(blocklengths(b)) == [1,2,3]

        o = blockedrange(1, Ones{Int}(10))
        @test @inferred(blocklasts(o)) == @inferred(blockfirsts(o)) == Base.OneTo(10)
        @test @inferred(blocklengths(o)) == Ones{Int}(10)

        f = blockedrange(1, Fill(2,5))
        @test @inferred(blockfirsts(f)) ≡ 1:2:9
        @test @inferred(blocklasts(f)) ≡ StepRangeLen(2,2,5)
        @test @inferred(blocklengths(f)) ≡ Fill(2,5)

        f = blockedrange(1, Zeros{Int}(2))
        @test @inferred(blockfirsts(f)) == [1,1]
        @test @inferred(blocklasts(f)) == [0,0]

        r = blockedrange(1, Base.OneTo(5))
        @test @inferred(blocklengths(r)) == 1:5
        @test @inferred(blocklasts(r)) == ArrayLayouts.RangeCumsum(Base.OneTo(5))

        r = blockedrange(2, 2:3:11)
        @test @inferred(blockfirsts(r)) == [2,4,9,17]
        @test @inferred(blocklengths(r)) == 2:3:11
    end

    @testset "convert" begin
        for elt in (Int, UInt)
            b = blockedrange(elt(1), Fill(elt(2),3))
            c = blockedrange(elt(1), elt[2,2,2])
            @test oftype(b, b) === b
            @test blockisequal(convert(BlockedUnitRange, Base.OneTo(5)), blockedrange(1, [5]))
            @test blockisequal(convert(BlockedUnitRange, Base.Slice(Base.OneTo(5))), blockedrange(1, [5]))
            @test blockisequal(convert(BlockedUnitRange, Base.IdentityUnitRange(-2:2)), BlockArrays._BlockedUnitRange(-2,[2]))
            @test convert(BlockedUnitRange{elt,Vector{elt}}, c) === c
            @test blockisequal(convert(BlockedUnitRange{Int,Vector{Int}}, b),b)
            @test blockisequal(convert(BlockedUnitRange{Int,Vector{Int}}, Base.OneTo(5)), blockedrange(1, [5]))
            @test blockisequal(convert(BlockedUnitRange, BlockedOneTo(1:3)), blockedrange(1, [1,1,1]))
        end
    end

    @testset "findblock" begin
        b = blockedrange(1, [1,2,3])
        @test @inferred(findblock(b,1)) == Block(1)
        @test @inferred(findblockindex(b,1)) == Block(1)[1]
        @test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),1:6) == BlockIndex.([1,2,2,3,3,3], [1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,7)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,7)

        b = BlockArrays._BlockedUnitRange(-1,[-1,1,4])
        @test @inferred(findblock(b,-1)) == Block(1)
        @test @inferred(findblockindex(b,-1)) == Block(1)[1]
        @test findblock.(Ref(b),-1:4) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),-1:4) == BlockIndex.([1,2,2,3,3,3],[1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-2)
        @test_throws BoundsError findblock(b,5)
        @test_throws BoundsError findblockindex(b,-2)
        @test_throws BoundsError findblockindex(b,5)

        b = blockedrange(1, Fill(3,1_000_000))
        @test @inferred(findblock(b, 1)) == Block(1)
        @test @inferred(findblockindex(b, 1)) == Block(1)[1]
        @test findblock.(Ref(b),299_997:300_001) == Block.([99_999,100_000,100_000,100_000,100_001])
        @test findblockindex.(Ref(b),299_997:300_001) == BlockIndex.([99_999,100_000,100_000,100_000,100_001],[3,1,2,3,1])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,3_000_001)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,3_000_001)
    end

    @testset "BlockIndex indexing" begin
        b = blockedrange(1, [1,2,3])
        @test b[Block(3)[2]] == b[Block(3)][2] == 5
        @test b[Block(3)[2:3]] == b[Block(3)][2:3] == 5:6
    end

    @testset "BlockRange indexing" begin
        b = blockedrange(1, [1,2,3])
        @test b[Block.(1:2)] == blockedrange(1, [1,2])
        @test b[Block.(1:3)] == b
        @test_throws BlockBoundsError b[Block.(0:2)]
        @test_throws BlockBoundsError b[Block.(1:4)]

        @testset "bug" begin
            b = blockedrange(1, 1:4)
            @test b[Block.(2:4)] == 2:10
            @test length(b[Block.(2:4)]) == 9
        end
    end

    @testset "misc" begin
        b = blockedrange(1, [1,2,3])
        @test axes(b) == Base.unsafe_indices(b) == (b,)
        @test Base.dataids(b) == Base.dataids(blocklasts(b))
        @test_throws ArgumentError BlockedUnitRange(b)

        @test summary(b) == "3-blocked 6-element BlockedUnitRange{$Int, Vector{$Int}}"
    end

    @testset "OneTo interface" begin
        b = Base.OneTo(5)
        @test blockaxes(b) == (Block.(1:1),)
        @test blocksize(b) == (1,)
        @test b[Block(1)] == b
        @test b[Block(1)[2]] == 2
        @test b[Block(1)[2:3]] == 2:3
        @test blockfirsts(b) == [1]
        @test blocklasts(b) == [5]
        @test blocklengths(b) == [5]
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(2)]
        @test findblock(b,1) == Block(1)
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,6)
        r = blockedrange(1, [1,2,2])
        @test sprint(show, "text/plain", r) == "$(summary(r)):\n 1\n ─\n 2\n 3\n ─\n 4\n 5"
    end

    @testset "BlockIndex type piracy (#108)" begin
        @test zeros()[] == 0.0
    end

    @testset "checkindex" begin
        b = blockedrange(1, [1,2,3])
        @test !checkindex(Bool, b, Block(0))
        @test checkindex(Bool, b, Block(1))
        @test checkindex(Bool, b, Block(3))
        @test !checkindex(Bool, b, Block(4))
        # treat b as the array, and check against the axis of b
        @test checkbounds(Bool, b, Block(1)[1])
        @test checkbounds(Bool, b, Block(1)[1:1])
        @test !checkbounds(Bool, b, Block(1)[2])
        @test checkbounds(Bool, b, Block(2)[1])
        @test checkbounds(Bool, b, Block(2)[1:2])
        @test !checkbounds(Bool, b, Block(2)[3])
        @test checkbounds(Bool, b, Block(3)[1])
        @test checkbounds(Bool, b, Block(3)[3])
        @test checkbounds(Bool, b, Block(3)[1:3])
        @test !checkbounds(Bool, b, Block(3)[4])
        @test !checkbounds(Bool, b, Block(0)[1])
        @test !checkbounds(Bool, b, Block(1)[0])
        # treat b as the axis
        @test checkindex(Bool, b, Block(1)[1])
        @test checkindex(Bool, b, Block(1)[1:1])
        @test !checkindex(Bool, b, Block(1)[2])
        @test checkindex(Bool, b, Block(2)[1])
        @test checkindex(Bool, b, Block(2)[1:2])
        @test !checkindex(Bool, b, Block(2)[3])
        @test checkindex(Bool, b, Block(3)[1])
        @test checkindex(Bool, b, Block(3)[3])
        @test checkindex(Bool, b, Block(3)[1:3])
        @test !checkindex(Bool, b, Block(3)[4])
        @test !checkindex(Bool, b, Block(0)[1])
        @test !checkindex(Bool, b, Block(1)[0])
    end

    @testset "Slice" begin
        b = blockedrange(1, [1,2,3])
        S = Base.Slice(b)
        @test blockaxes(S) == blockaxes(b)
        @test S[Block(2)] == 2:3
        @test S[Block.(1:2)] == 1:3
        @test axes(S) == axes(b)


        bs = BlockSlice(Block.(1:3), 1:6)
        @test b[bs] == b
    end

    @testset "StaticArrays" begin
        @test blockisequal(blockedrange(1, SVector(1,2,3)), blockedrange(1, [1,2,3]))
        # @test @allocated(blockedrange(SVector(1,2,3))) == 0
    end

    @testset "Tuples" begin
        # we support Tuples in addition to SVectors for InfiniteArrays.jl, which has
        # infinite block sizes
        s = blockedrange(1, (5,big(100_000_000)^2))
        @test blocklengths(s) == [5,big(100_000_000)^2]
        @test blockaxes(s) == (Block.(1:2),)
        @test findblock(s,3) == Block(1)
        @test findblock(s,big(100_000_000)) == Block(2)
    end
end

@testset "BlockedOneTo" begin
    @testset "constructor" begin
        @test blockedrange((2,3)) isa BlockedOneTo{Int, NTuple{2,Int}}
        @test blockedrange([2,3]) == blockedrange((2,3)) == 1:5
    end

    @testset "promote" begin
        b = blockedrange([1,2,3])
        @test promote(b, 1:2) == (1:6, 1:2)
        @test promote(b, Base.OneTo(2)) == (1:6, 1:2)
    end
    @testset "Block indexing" begin
        b = blockedrange([1,2,3])
        @test axes(b) == (b,)
        @test blockaxes(b,1) isa BlockRange

        @test @inferred(b[Block(1)]) === 1:1
        @test b[Block(2)] === 2:3
        @test b[Block(3)] === 4:6
        @test @inferred(view(b, Block(3))) === 4:6
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]
        @test_throws BlockBoundsError view(b, Block(4))

        b = BlockedOneTo([0,1,4])
        @test axes(b,1) == blockedrange([0,1,3])
        @test b[Block(1)] == 1:0
        @test b[Block(2)] == 1:1
        @test b[Block(3)] == 2:4
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        b = blockedrange(1,Fill(3,1_000_000))
        @test b isa BlockedUnitRange{Int,<:AbstractRange}
        @test b[Block(100_000)] == 299_998:300_000
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(1_000_001)]

        b = BlockRange((2:4, 3:4))
        @test b[2,2] === Block(3,4)
        @test b[axes(b)...] === b

        b = BlockRange(OffsetArrays.IdOffsetRange.((2:4, 3:5), 2))
        @test b[axes(b)...] === b

        b = BlockRange(3)
        for i in 1:3
            @test b[i] == Block(i)
        end

        B = mortar(fill(rand(1,1),2,2))
        br = BlockRange(B)
        @test collect(br) == [Block(Int(i),Int(j)) for i in blockaxes(B,1), j in blockaxes(B,2)]
    end

    @testset "firsts/lasts/lengths" begin
        b = blockedrange([1,2,3])
        @test @inferred(blockfirsts(b)) == [1,2,4]
        @test @inferred(blocklasts(b)) == [1,3,6]
        @test @inferred(blocklengths(b)) == [1,2,3]

        o = blockedrange(Ones{Int}(10))
        @test @inferred(blocklasts(o)) == @inferred(blockfirsts(o)) == Base.OneTo(10)
        @test @inferred(blocklengths(o)) == Ones{Int}(10)

        f = blockedrange(Fill(2,5))
        @test @inferred(blockfirsts(f)) ≡ 1:2:9
        @test @inferred(blocklasts(f)) ≡ StepRangeLen(2,2,5)
        @test @inferred(blocklengths(f)) ≡ Fill(2,5)

        f = blockedrange(Zeros{Int}(2))
        @test @inferred(blockfirsts(f)) == [1,1]
        @test @inferred(blocklasts(f)) == [0,0]

        r = blockedrange(Base.OneTo(5))
        @test @inferred(blocklengths(r)) == 1:5
        @test @inferred(blocklasts(r)) == ArrayLayouts.RangeCumsum(Base.OneTo(5))

        r = blockedrange(2:3:11)
        @test @inferred(blockfirsts(r)) == [1,3,8,16]
        @test @inferred(blocklengths(r)) == 2:3:11
    end

    @testset "convert" begin
        b = blockedrange(1, Fill(2,3))
        c = blockedrange(1, [2,2,2])
        @test convert(BlockedUnitRange, b) === b
        @test blockisequal(convert(BlockedUnitRange, Base.OneTo(5)), blockedrange([5]))
        @test blockisequal(convert(BlockedUnitRange, Base.Slice(Base.OneTo(5))), blockedrange([5]))
        @test blockisequal(convert(BlockedUnitRange, Base.IdentityUnitRange(-2:2)), BlockArrays._BlockedUnitRange(-2,[2]))
        @test convert(BlockedUnitRange{Int,Vector{Int}}, c) === c
        @test blockisequal(convert(BlockedUnitRange{Int,Vector{Int}}, b),b)
        @test blockisequal(convert(BlockedUnitRange{Int,Vector{Int}}, Base.OneTo(5)), blockedrange([5]))

        b = blockedrange(Fill(2,3))
        c = blockedrange([2,2,2])
        @test convert(BlockedOneTo, b) === b
        @test convert(typeof(b), b) === b
        @test convert(BlockedOneTo, c) === c
        @test convert(typeof(c), c) === c
        function test_type_and_blockequal(T, r, res)
            s = convert(T, r)
            @test s isa T
            @test blockisequal(r, res)
        end
        test_type_and_blockequal(BlockedOneTo, Base.OneTo(5), blockedrange([5]))
        test_type_and_blockequal(BlockedOneTo, Base.Slice(Base.OneTo(5)), blockedrange([5]))
        test_type_and_blockequal(BlockedOneTo{Int,Vector{Int}}, b, b)
        test_type_and_blockequal(BlockedOneTo{Int,Vector{Int}}, Base.OneTo(5), blockedrange([5]))
        test_type_and_blockequal(BlockedOneTo, blockedrange(1, [1,1,1]), blockedrange([1,1,1]))
    end

    @testset "findblock" begin
        b = blockedrange([1,2,3])
        @test @inferred(findblock(b,1)) == Block(1)
        @test @inferred(findblockindex(b,1)) == Block(1)[1]
        @test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),1:6) == BlockIndex.([1,2,2,3,3,3], [1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,7)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,7)

        o = OffsetArray([2,2,3],-1:1)
        @test_throws ArgumentError blockedrange(o)

        b = blockedrange(Fill(3,1_000_000))
        @test @inferred(findblock(b, 1)) == Block(1)
        @test @inferred(findblockindex(b, 1)) == Block(1)[1]
        @test findblock.(Ref(b),299_997:300_001) == Block.([99_999,100_000,100_000,100_000,100_001])
        @test findblockindex.(Ref(b),299_997:300_001) == BlockIndex.([99_999,100_000,100_000,100_000,100_001],[3,1,2,3,1])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,3_000_001)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,3_000_001)
    end

    @testset "BlockedOneTo indexing" begin
        b1 = blockedrange(1:3)
        b2 = blockedrange(1:2)
        @test b1[b2] == b2
        @test_throws BoundsError b1[blockedrange(1:4)]
    end

    @testset "BlockIndex indexing" begin
        b = blockedrange([1,2,3])
        @test b[Block(3)[2]] == b[Block(3)][2] == 5
        @test b[Block(3)[2:3]] == b[Block(3)][2:3] == 5:6
    end

    @testset "BlockRange indexing" begin
        b = blockedrange([1,2,3])
        @test b[Block.(1:2)] == blockedrange([1,2])
        @test b[Block.(1:3)] == b
        @test_throws BlockBoundsError b[Block.(0:2)]
        @test_throws BlockBoundsError b[Block.(1:4)]

        @testset "bug" begin
            b = blockedrange(1:4)
            @test b[Block.(2:4)] == 2:10
            @test length(b[Block.(2:4)]) == 9
        end

        b = blockedrange(1:3)
        bpart = @inferred(b[Block.(1:2)])
        @test bpart isa BlockedUnitRange
        @test bpart == blockedrange(1:2)
        bpart = @inferred(b[Block.(1:0)])
        @test bpart isa BlockedUnitRange
        @test bpart == blockedrange(1:0)
        bpart = @inferred(b[Block.(Base.OneTo(2))])
        @test bpart isa BlockedOneTo
        @test bpart == blockedrange(1:2)
        bpart = @inferred(b[Block.(Base.OneTo(0))])
        @test bpart isa BlockedOneTo
        @test bpart == blockedrange(1:0)
    end

    @testset "misc" begin
        b = blockedrange([1,2,3])
        @test axes(b) == Base.unsafe_indices(b) == (b,)
        @test Base.dataids(b) == Base.dataids(blocklasts(b))
        @test_throws ArgumentError BlockedOneTo(b)

        @test summary(b) == "3-blocked 6-element BlockedOneTo{$Int, Vector{$Int}}"
    end

    @testset "OneTo interface" begin
        b = Base.OneTo(5)
        @test blockaxes(b) == (Block.(1:1),)
        @test blocksize(b) == (1,)
        @test b[Block(1)] == b
        @test b[Block(1)[2]] == 2
        @test b[Block(1)[2:3]] == 2:3
        @test blockfirsts(b) == [1]
        @test blocklasts(b) == [5]
        @test blocklengths(b) == [5]
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(2)]
        @test findblock(b,1) == Block(1)
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,6)
        r = blockedrange([1,2,2])
        @test sprint(show, "text/plain", r) == "$(summary(r)):\n 1\n ─\n 2\n 3\n ─\n 4\n 5"
    end

    @testset "checkindex" begin
        b = blockedrange([1,2,3])
        @test !checkindex(Bool, b, Block(0))
        @test checkindex(Bool, b, Block(1))
        @test checkindex(Bool, b, Block(3))
        @test !checkindex(Bool, b, Block(4))
        # treat b as the array, and check against the axis of b
        @test checkbounds(Bool, b, Block(1)[1])
        @test checkbounds(Bool, b, Block(1)[1:1])
        @test !checkbounds(Bool, b, Block(1)[2])
        @test checkbounds(Bool, b, Block(2)[1])
        @test checkbounds(Bool, b, Block(2)[1:2])
        @test !checkbounds(Bool, b, Block(2)[3])
        @test checkbounds(Bool, b, Block(3)[1])
        @test checkbounds(Bool, b, Block(3)[3])
        @test checkbounds(Bool, b, Block(3)[1:3])
        @test !checkbounds(Bool, b, Block(3)[4])
        @test !checkbounds(Bool, b, Block(0)[1])
        @test !checkbounds(Bool, b, Block(1)[0])
        # treat b as the axis
        @test checkindex(Bool, b, Block(1)[1])
        @test checkindex(Bool, b, Block(1)[1:1])
        @test !checkindex(Bool, b, Block(1)[2])
        @test checkindex(Bool, b, Block(2)[1])
        @test checkindex(Bool, b, Block(2)[1:2])
        @test !checkindex(Bool, b, Block(2)[3])
        @test checkindex(Bool, b, Block(3)[1])
        @test checkindex(Bool, b, Block(3)[3])
        @test checkindex(Bool, b, Block(3)[1:3])
        @test !checkindex(Bool, b, Block(3)[4])
        @test !checkindex(Bool, b, Block(0)[1])
        @test !checkindex(Bool, b, Block(1)[0])
    end

    @testset "Slice" begin
        b = blockedrange([1,2,3])
        S = Base.Slice(b)
        @test blockaxes(S) == blockaxes(b)
        @test S[Block(2)] == 2:3
        @test S[Block.(1:2)] == 1:3
        @test axes(S) == axes(b)


        bs = BlockSlice(Block.(1:3), 1:6)
        @test b[bs] == b
    end

    @testset "StaticArrays" begin
        @test blockisequal(blockedrange(SVector(1,2,3)), blockedrange([1,2,3]))
        # @test @allocated(blockedrange(SVector(1,2,3))) == 0
    end

    @testset "Tuples" begin
        # we support Tuples in addition to SVectors for InfiniteArrays.jl, which has
        # infinite block sizes
        s = blockedrange(1, (5,big(100_000_000)^2))
        @test eltype(s) === BigInt
        @test first(s) isa BigInt
        @test last(s) isa BigInt
        @test blocklengths(s) == [5,big(100_000_000)^2]
        @test eltype(blocklengths(s)) === BigInt
        @test blockaxes(s) == (Block.(1:2),)
        @test findblock(s,3) == Block(1)
        @test findblock(s,big(100_000_000)) == Block(2)

        r = blockedrange(1, (2, 2, 2))
        @test eltype(r) === Int
        @test first(r) === 1
        @test last(r) === 6
        @test length(r) === 6
        @test blockfirsts(r) === (1, 3, 5)
        @test blocklasts(r) === (2, 4, 6)
        @test blocklengths(r) == [2, 2, 2]
    end

    @testset "Empty Tuple" begin
        r = blockedrange(1, ())
        @test eltype(r) === Int
        @test first(r) === 1
        @test last(r) === 0
        @test length(r) === 0
        @test blockfirsts(r) === (1,)
        @test blocklasts(r) === ()
        @test blocklengths(r) == []
    end

    @testset "General element types" begin
        elt = UInt8
        r = blockedrange(one(elt), elt[2, 4])
        @test length(r) isa elt
        @test r isa BlockedUnitRange{elt}
        @test eltype(r) === elt
        @test r[Block(1):Block(2)] isa BlockedUnitRange{elt}
        @test r[Block(1):Block(1)] isa BlockedUnitRange{elt}
        @test r[Block(2):Block(2)] isa BlockedUnitRange{elt}
        @test r[Block(2):Block(1)] isa BlockedUnitRange{elt}
        @test r[BlockRange(Base.OneTo(0))] isa BlockedUnitRange{elt}
        @test r[BlockRange(Base.OneTo(1))] isa BlockedUnitRange{elt}
        @test r[BlockRange(Base.OneTo(2))] isa BlockedUnitRange{elt}
        @test r[Block(1)] isa UnitRange{elt}
        @test r[Block(2)] isa UnitRange{elt}
        @test eltype(blocklengths(r)) === elt
        @test first(r) isa elt
        @test last(r) isa elt
        for i in eachindex(r)
          @test r[i] isa elt
        end
        @test eltype(blockedrange(one(elt), Base.OneTo(elt(3)))) === elt
        @test eltype(blockedrange(one(elt), elt(1):elt(3))) === elt

        if VERSION >= v"1.7"
          # `cumsum(::Fill)` doesn't preserve element types properly.
          # That issue was fixed by this fix to `StepRangeLen`:
          # https://github.com/JuliaLang/julia/pull/41619
          # which is only available in Julia v1.7 and higher.
          r = blockedrange(one(elt), Fill(elt(2), 3))
          @test r isa BlockedUnitRange{elt,<:StepRangeLen{elt}}
          @test eltype(r) === elt
        end

        r = blockedrange(one(elt), Ones(elt, 3))
        @test r isa BlockedUnitRange{elt}
        @test eltype(r) === elt

        # TODO: Construct with `blockedrange(Fill(elt(1), 4))`?
        r = BlockArrays._BlockedUnitRange(one(elt), elt(1):elt(4))
        @test eltype(r) === elt
        @test eltype(blockfirsts(r)) === elt
        @test eltype(blocklasts(r)) === elt
        @test eltype(blocklengths(r)) === elt

        # TODO: Construct with `blockedrange(Ones(elt, 4))`?
        r = BlockArrays._BlockedUnitRange(one(elt), Base.OneTo(elt(4)))
        @test eltype(r) === elt
        @test eltype(blockfirsts(r)) === elt
        @test eltype(blocklasts(r)) === elt
        @test eltype(blocklengths(r)) === elt

        r = elt(1):elt(2)
        @test eltype(blockfirsts(r)) === elt
        @test eltype(blocklasts(r)) === elt
        @test eltype(blocklengths(r)) === elt
    end

    @testset "Promote element types" begin
        for r in (blockedrange(UInt8(1), UInt16[2, 4]), blockedrange(UInt16(1), UInt8[2, 4]))
            @test first(r) == 1
            @test last(r) == 6
            @test blockfirsts(r) == [1, 3]
            @test blocklasts(r) == [2, 6]
            @test eltype(r) === UInt16
            @test typeof(first(r)) === UInt16
            @test typeof(last(r)) === UInt16
            @test eltype(blockfirsts(r)) === UInt16
            @test eltype(blocklasts(r)) === UInt16
            @test eltype(blocklengths(r)) === UInt16
        end
    end

    @testset "Promote element Tuple types" begin
        r = BlockArrays._BlockedUnitRange((UInt8(2), UInt16(5)))
        @test eltype(r) == UInt16
        @test first(r) === UInt16(1)
        @test last(r) === UInt16(5)
        @test blockfirsts(r) === (UInt16(1), UInt16(3))
        @test blocklasts(r) === (UInt16(2), UInt16(5))
        @test blocklengths(r) == [UInt16(2), UInt16(3)]
        @test eltype(blocklengths(r)) === UInt16
    end

    @testset "show" begin
        b = blockedrange([1,2])
        @test repr(b) == "$BlockedOneTo($([1,3]))"
    end

    @testset "non-Int eltypes" begin
        @test blockedrange(UInt32[1,2]) isa BlockedOneTo{UInt32, Vector{UInt32}}
        @test blockedrange(UInt32[1,2]) == blockedrange([1,2])
        @test_throws ArgumentError BlockedOneTo([true])
    end
end

@testset "BlockSlice" begin
    b = BlockSlice(Block(5),1:3)
    @test b[b] == b
    @test b[b] isa BlockSlice{<:BlockIndexRange}
    @test b[Base.Slice(1:3)] ≡ b
    @test b[1:2] ≡ b[1:2][1:2] ≡ BlockSlice(Block(5)[1:2],1:2)
    @test Block(b) ≡ Block(5)

    @testset "OneTo converts" begin
        for b in (BlockSlice(Block(1), 1:1), BlockSlice(Block.(1:1), 1:1), BlockSlice(Block(1)[1:1], 1:1))
            @test convert(typeof(b), Base.OneTo(1)) ≡ b
        end
    end

    @testset "view into CartesianIndices/ranges" begin
        C = CartesianIndices((1:3,))
        r = 1:2
        b = BlockSlice(Block(1), r)
        @test view(C, b) === view(C, r)
        @test view(1:10, b) === view(1:10, r)
        C = CartesianIndices((1:3, 1:3))
        @test view(C, b, b) === view(C, r, r)
    end
end

#=
[1,1  1,2] | [1,3  1,4  1,5]
--------------------------
[2,1  2,2] | [2,3  2,4  2,5]
[3,1  3,2] | [3,3  3,4  3,5]
----------------------------
[4,1  4,2] | [4,3  4,4  4,5]
[5,1  5,2] | [5,3  5,4  5,5]
[6,1  6,2] | [6,3  6,4  6,5]
=#

# @testset " BlockIndices" begin
#     A = BlockVector([1,2,3],[1,2])
#     @test A[Block(2)[2]] == 3
#     @test A[Block(2)[1:2]] == [2,3]
#     @test A[getindex.(Block.(1:2), 1)] == [1,2]

#     @test_throws BlockBoundsError A[Block(3)]
#     @test_throws BlockBoundsError A[Block(3)[1]]
#     @test_throws BoundsError A[Block(3)[1:1]] # this is likely an error
#     @test_throws BoundsError A[Block(2)[3]]
#     @test_throws BoundsError A[Block(2)[3:3]]
# end

@testset "sortedin" begin
    v = [1,3,4]
    @test BlockArrays.sortedin(1,v)
    @test !BlockArrays.sortedin(2,v)
    @test !BlockArrays.sortedin(0,v)
    @test !BlockArrays.sortedin(5,v)
end

@testset "eachblock" begin
    v = Array(reshape(1:6, (2, 3)))
    A = BlockArray(v, [1,1], [2,1])
    B = BlockedArray(v, [1,1], [2,1])

    # test that contents match
    @test collect(eachblock(A)) == collect(eachblock(B)) == A.blocks

    # test that eachblock returns views
    first(eachblock(A))[1,2] = 0
    @test A[1,2] == 0
    first(eachblock(B))[1,2] = 0
    @test B[1,2] == 0
end

@testset "blockisequal" begin
    B = BlockArray(rand(4,4), [1,3], [1,3])
    v = BlockArray(rand(4), [1,3])
    axB = axes(B)
    axv = axes(v)
    @test blockisequal(axB, axB)
    @test blockisequal(axv, axv)
    @test !blockisequal(axB, axv)
    @test !blockisequal(axv, axB)
end

@testset "BlockIndices" begin
    a = BlockedOneTo(1:3)
    @test a[[Block(1),Block(3)]] == a[Block.(1:2:3)] == [1,3]
end

end # module
