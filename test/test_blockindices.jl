using BlockArrays, FillArrays, OffsetArrays, Test, Base64, StaticArrays, ArrayLayouts
import BlockArrays: BlockIndex, BlockIndexRange, BlockSlice

@testset "Blocks" begin
    @test Int(Block(2)) === Integer(Block(2)) === Number(Block(2)) === 2
    @test Block((Block(3), Block(4))) === Block(3,4)

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
        @test Block(2,3) - Block(1,2) == Block(1,1)
        @test Block(1,2) - 1 == Block(0,1)
        @test 1 - Block(1,2) == Block(0,-1)
        @test 2*Block(1,2) == Block(2,4)
        @test Block(1,2)*2 == Block(2,4)

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

        @test_throws MethodError convert(Int, Block(2,1))
        @test convert(Tuple{Int,Int}, Block(2,1)) == (2,1)
        @test convert(Tuple{Float64,Int}, Block(2,1)) == (2.0,1)

        @test Block(1)[:] ≡ Block(1)[Base.Slice(1:2)] ≡ Block(1)
    end

    @testset "BlockIndex" begin
        @test Block(1)[1] == BlockIndex((1,),(1,))
        @test Block(1)[1:2] == BlockIndexRange(Block(1),(1:2,))
        @test Block(1,1)[1,1] == BlockIndex((1,1),(1,1))
        @test Block(1,1)[1:2,1:2] == BlockIndexRange(Block(1,1),(1:2,1:2))
        @test Block(1)[1:3][1:2] == BlockIndexRange(Block(1),1:2)
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
end

@testset "BlockedUnitRange" begin
    @testset "Block indexing" begin
        b = blockedrange([1,2,3])
        @test axes(b) == (b,)
        @test blockaxes(b,1) isa BlockRange

        @test @inferred(b[Block(1)]) == 1:1
        @test b[Block(2)] == 2:3
        @test b[Block(3)] == 4:6
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)
        b = blockedrange(o)
        @test axes(b) == (b,)
        @test @inferred(b[Block(-1)]) == 1:2
        @test b[Block(0)] == 3:4
        @test b[Block(1)] == 5:7
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]

        b = BlockArrays._BlockedUnitRange(-1,[-1,1,4])
        @test axes(b,1) == blockedrange([1,2,3])
        @test b[Block(1)] == -1:-1
        @test b[Block(2)] == 0:1
        @test b[Block(3)] == 2:4
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)
        b = BlockArrays._BlockedUnitRange(-3, cumsum(o) .- 4)
        @test axes(b,1) == blockedrange([2,2,3])
        @test b[Block(-1)] == -3:-2
        @test b[Block(0)] == -1:0
        @test b[Block(1)] == 1:3
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]

        b = blockedrange(Fill(3,1_000_000))
        @test b isa BlockedUnitRange{StepRange{Int,Int}}
        @test b[Block(100_000)] == 299_998:300_000
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(1_000_001)]
    end

    @testset "firsts/lasts/lengths" begin
        b = blockedrange([1,2,3])
        @test blockfirsts(b) == [1,2,4]
        @test blocklasts(b) == [1,3,6]
        @test blocklengths(b) == [1,2,3]

        o = blockedrange(Ones{Int}(10))
        @test blocklasts(o) ≡ blockfirsts(o) ≡ Base.OneTo(10)
        @test blocklengths(o) ≡ Ones{Int}(10)

        f = blockedrange(Fill(2,5))
        @test blockfirsts(f) ≡ 1:2:9
        @test blocklasts(f) ≡ 2:2:10
        @test blocklengths(f) ≡ Fill(2,5)

        r = blockedrange(Base.OneTo(5))
        @test blocklasts(r) ≡ ArrayLayouts.RangeCumsum(Base.OneTo(5))
    end

    @testset "convert" begin
        b = blockedrange(Fill(2,3))
        c = blockedrange([2,2,2])
        @test convert(BlockedUnitRange, b) === b
        @test blockisequal(convert(BlockedUnitRange, Base.OneTo(5)), blockedrange([5]))
        @test blockisequal(convert(BlockedUnitRange, Base.Slice(Base.OneTo(5))), blockedrange([5]))
        @test blockisequal(convert(BlockedUnitRange, Base.IdentityUnitRange(-2:2)), BlockArrays._BlockedUnitRange(-2,[2]))
        @test convert(BlockedUnitRange{Vector{Int}}, c) === c
        @test blockisequal(convert(BlockedUnitRange{Vector{Int}}, b),b)
        @test blockisequal(convert(BlockedUnitRange{Vector{Int}}, Base.OneTo(5)), blockedrange([5]))
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
        b = blockedrange(o)
        @test @inferred(findblock(b,1)) == Block(-1)
        @test @inferred(findblockindex(b,1)) == Block(-1)[1]
        @test findblock.(Ref(b),1:7) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),1:7) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,8)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,8)

        b = BlockArrays._BlockedUnitRange(-1,[-1,1,4])
        @test @inferred(findblock(b,-1)) == Block(1)
        @test @inferred(findblockindex(b,-1)) == Block(1)[1]
        @test findblock.(Ref(b),-1:4) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),-1:4) == BlockIndex.([1,2,2,3,3,3],[1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-2)
        @test_throws BoundsError findblock(b,5)
        @test_throws BoundsError findblockindex(b,-2)
        @test_throws BoundsError findblockindex(b,5)

        o = OffsetArray([2,2,3],-1:1)
        b = BlockArrays._BlockedUnitRange(-3, cumsum(o) .- 4)
        @test @inferred(findblock(b,-3)) == Block(-1)
        @test @inferred(findblockindex(b,-3)) == Block(-1)[1]
        @test findblock.(Ref(b),-3:3) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),-3:3) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-4)
        @test_throws BoundsError findblock(b,5)
        @test_throws BoundsError findblockindex(b,-4)
        @test_throws BoundsError findblockindex(b,5)

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
    end

    @testset "misc" begin
        b = blockedrange([1,2,3])
        @test axes(b) == Base.unsafe_indices(b) == (b,)
        @test Base.dataids(b) == Base.dataids(blocklasts(b))
        @test_throws ArgumentError BlockedUnitRange(b)

        @test summary(b) == "3-blocked 6-element BlockedUnitRange{Vector{$Int}}"
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
        @test stringmime("text/plain",blockedrange([1,2,2])) == "3-blocked 5-element BlockedUnitRange{Vector{$Int}}:\n 1\n ─\n 2\n 3\n ─\n 4\n 5"
    end

    @testset "BlockIndex type piracy (#108)" begin
        @test zeros()[] == 0.0
    end

    @testset "checkindex" begin
        b = blockedrange([1,2,3])
        @test !checkindex(Bool, b, Block(0))
        @test checkindex(Bool, b, Block(1))
        @test checkindex(Bool, b, Block(3))
        @test !checkindex(Bool, b, Block(4))
        @test checkbounds(Bool, b, Block(1)[1])
        @test !checkbounds(Bool, b, Block(1)[2])
        @test !checkbounds(Bool, b, Block(0)[1])
        @test !checkbounds(Bool, b, Block(1)[0])
    end

    @testset "Slice" begin
        b = blockedrange([1,2,3])
        S = Base.Slice(b)
        @test blockaxes(S) == blockaxes(b)
        @test S[Block(2)] == 2:3
        @test S[Block.(1:2)] == 1:3
        @test axes(S) == axes(b)
    end

    @testset "StaticArrays" begin
        @test blockisequal(blockedrange(SVector(1,2,3)), blockedrange([1,2,3]))
        @test @allocated(blockedrange(SVector(1,2,3))) == 0
    end

    @testset "Tuples" begin
        # we support Tuples in addition to SVectors for InfiniteArrays.jl, which has
        # infinite block sizes
        s = blockedrange((5,big(100_000_000)^2))
        @test blocklengths(s) == [5,big(100_000_000)^2]
        @test blockaxes(s) == (Block.(1:2),)
        @test findblock(s,3) == Block(1)
        @test findblock(s,big(100_000_000)) == Block(2)
    end
end

@testset "BlockSlice" begin
    b = BlockSlice(Block(5),1:3)
    @test b[Base.Slice(1:3)] ≡ b
    @test b[1:2] ≡ b[1:2][1:2] ≡ BlockSlice(Block(5)[1:2],1:2)
    @test Block(b) ≡ Block(5)

    @testset "OneTo converts" begin
        for b in (BlockSlice(Block(1), 1:1), BlockSlice(Block.(1:1), 1:1), BlockSlice(Block(1)[1:1], 1:1))
            @test convert(typeof(b), Base.OneTo(1)) ≡ b
        end
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
#     @test_throws BoundsError A[Block(3)[1:1]] # this is likely an error
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
    B = PseudoBlockArray(v, [1,1], [2,1])

    # test that contents match
    @test collect(eachblock(A)) == collect(eachblock(B)) == A.blocks

    # test that eachblock returns views
    first(eachblock(A))[1,2] = 0
    @test A[1,2] == 0
    first(eachblock(B))[1,2] = 0
    @test B[1,2] == 0
end
