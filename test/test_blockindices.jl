using BlockArrays, FillArrays, OffsetArrays, Test
import BlockArrays: BlockAxis, BlockIndex, BlockIndexRange

@testset "Blocks" begin
    @test Int(Block(2)) === Integer(Block(2)) === Number(Block(2)) === 2
    @test Block((Block(3), Block(4))) === Block(3,4)
end

@testset "BlockIndex" begin
    @test Block(1)[1] == BlockIndex((1,),(1,))
    @test Block(1)[1:2] == BlockIndexRange(Block(1),(1:2,))
    @test Block(1,1)[1,1] == BlockIndex((1,1),(1,1))
    @test Block(1,1)[1:2,1:2] == BlockIndexRange(Block(1,1),(1:2,1:2))
end

@testset "BlockAxis" begin
    @testset "Block indexing" begin
        b = BlockAxis([1,2,3])
        @test b[Block(1)] == 1:1
        @test b[Block(2)] == 2:3
        @test b[Block(3)] == 4:6
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)
        b = BlockAxis(o)
        @test b[Block(-1)] == 1:2
        @test b[Block(0)] == 3:4
        @test b[Block(1)] == 5:7
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]

        b = BlockAxis([1,2,3],Base.IdentityUnitRange(-1:4))
        @test b[Block(1)] == -1:-1
        @test b[Block(2)] == 0:1
        @test b[Block(3)] == 2:4
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)    
        b = BlockAxis(o,Base.IdentityUnitRange(-3:3))
        @test b[Block(-1)] == -3:-2
        @test b[Block(0)] == -1:0
        @test b[Block(1)] == 1:3
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]        

        b = BlockAxis(Fill(3,1_000_000))
        @test b isa BlockAxis{StepRange{Int,Int},Base.OneTo{Int},Base.OneTo{Int}}
        @test b[Block(100_000)] == 299_998:300_000
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(1_000_001)]
    end

    @testset "findblock" begin
        b = BlockAxis([1,2,3])
        @test @inferred(findblock(b,1)) == Block(1)
        @test @inferred(findblockindex(b,1)) == Block(1)[1]
        @test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),1:6) == BlockIndex.([1,2,2,3,3,3], [1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,7)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,7)

        o = OffsetArray([2,2,3],-1:1)
        b = BlockAxis(o)
        @test @inferred(findblock(b,1)) == Block(-1)
        @test @inferred(findblockindex(b,1)) == Block(-1)[1]
        @test findblock.(Ref(b),1:7) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),1:7) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,8)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,8)

        b = BlockAxis([1,2,3],Base.IdentityUnitRange(-1:4))
        @test @inferred(findblock(b,-1)) == Block(1)
        @test @inferred(findblockindex(b,-1)) == Block(1)[1]
        @test findblock.(Ref(b),-1:4) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),-1:4) == BlockIndex.([1,2,2,3,3,3],[1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-2)
        @test_throws BoundsError findblock(b,5)
        @test_throws BoundsError findblockindex(b,-2)
        @test_throws BoundsError findblockindex(b,5)

        o = OffsetArray([2,2,3],-1:1)    
        b = BlockAxis(o,Base.IdentityUnitRange(-3:3))    
        @test @inferred(findblock(b,-3)) == Block(-1)    
        @test @inferred(findblockindex(b,-3)) == Block(-1)[1]
        @test findblock.(Ref(b),-3:3) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),-3:3) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-4)
        @test_throws BoundsError findblock(b,5) 
        @test_throws BoundsError findblockindex(b,-4)
        @test_throws BoundsError findblockindex(b,5)                   
        
        b = BlockAxis(Fill(3,1_000_000))
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
       b = BlockAxis([1,2,3]) 
       @test b[Block(3)[2]] == b[Block(3)][2] == 5
       @test b[Block(3)[2:3]] == b[Block(3)][2:3] == 5:6
    end

    @testset "BlockRange indexing" begin
       b = BlockAxis([1,2,3]) 
       b[Block.(1:2)]
       @test b[Block(3)[2]] == b[Block(3)][2] == 5
       @test b[Block(3)[2:3]] == b[Block(3)][2:3] == 5:6
    end

    @testset "misc" begin
        b = BlockAxis([1,2,3])
        @test Base.dataids(b) == Base.dataids(b.block_cumsum)
        @test_throws ArgumentError BlockAxis(b)

        o = OffsetArray([2,2,3],-1:1)
        @test_throws ArgumentError BlockAxis(o,Base.IdentityUnitRange(-4:3))
    end

    @testset "OneTo interface" begin
        b = Base.OneTo(5)
        @test blockaxes(b) == (Block.(1:1),)
        @test blocksize(b) == (1,)
        @test b[Block(1)] == b
        @test b[Block(1)[2]] == 2
        @test b[Block(1)[2:3]] == 2:3
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(2)]
        @test findblock(b,1) == Block(1)
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,6)
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

# @testset "BlockSizes / BlockIndices" begin
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