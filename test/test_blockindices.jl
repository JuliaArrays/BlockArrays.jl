using BlockArrays, FillArrays, OffsetArrays, Test
import BlockArrays: BlockIndex, BlockIndexRange

@testset "Blocks" begin
    @test Int(Block(2)) === Integer(Block(2)) === Number(Block(2)) === 2
    @test Block((Block(3), Block(4))) === Block(3,4)

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
    end

    @testset "BlockIndex" begin
        @test Block(1)[1] == BlockIndex((1,),(1,))
        @test Block(1)[1:2] == BlockIndexRange(Block(1),(1:2,))
        @test Block(1,1)[1,1] == BlockIndex((1,1),(1,1))
        @test Block(1,1)[1:2,1:2] == BlockIndexRange(Block(1,1),(1:2,1:2))
    end

    @testset "BlockRange" begin
        @test Block.(2:5) isa BlockRange
        @test Block.(Base.OneTo(5)) isa BlockRange
        @test Block.(2:5) == [Block(2),Block(3),Block(4),Block(5)]
    end
end

@testset "CumsumBlockRange" begin
    @testset "Block indexing" begin
        b = BlockArrays.CumsumBlockRange([1,2,3])
        @test axes(b) == (b,)
        @test blockaxes(b,1) isa BlockRange

        @test @inferred(b[Block(1)]) == 1:1
        @test b[Block(2)] == 2:3
        @test b[Block(3)] == 4:6
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)
        b = BlockArrays.CumsumBlockRange(o)
        @test axes(b) == (b,)
        @test @inferred(b[Block(-1)]) == 1:2
        @test b[Block(0)] == 3:4
        @test b[Block(1)] == 5:7
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]

        b = BlockArrays.CumsumBlockRange(-1,[-1,1,4])
        @test axes(b,1) == BlockArrays.CumsumBlockRange([1,2,3])
        @test b[Block(1)] == -1:-1
        @test b[Block(2)] == 0:1
        @test b[Block(3)] == 2:4
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(4)]

        o = OffsetArray([2,2,3],-1:1)    
        b = BlockArrays.CumsumBlockRange(-3, cumsum(o) .- 4)
        @test axes(b,1) == BlockArrays.CumsumBlockRange([2,2,3])
        @test b[Block(-1)] == -3:-2
        @test b[Block(0)] == -1:0
        @test b[Block(1)] == 1:3
        @test_throws BlockBoundsError b[Block(-2)]
        @test_throws BlockBoundsError b[Block(2)]        

        b = BlockArrays.CumsumBlockRange(Fill(3,1_000_000))
        @test b isa BlockArrays.CumsumBlockRange{StepRange{Int,Int}}
        @test b[Block(100_000)] == 299_998:300_000
        @test_throws BlockBoundsError b[Block(0)]
        @test_throws BlockBoundsError b[Block(1_000_001)]
    end

    @testset "findblock" begin
        b = BlockArrays.CumsumBlockRange([1,2,3])
        @test @inferred(findblock(b,1)) == Block(1)
        @test @inferred(findblockindex(b,1)) == Block(1)[1]
        @test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),1:6) == BlockIndex.([1,2,2,3,3,3], [1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,7)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,7)

        o = OffsetArray([2,2,3],-1:1)
        b = BlockArrays.CumsumBlockRange(o)
        @test @inferred(findblock(b,1)) == Block(-1)
        @test @inferred(findblockindex(b,1)) == Block(-1)[1]
        @test findblock.(Ref(b),1:7) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),1:7) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,0)
        @test_throws BoundsError findblock(b,8)
        @test_throws BoundsError findblockindex(b,0)
        @test_throws BoundsError findblockindex(b,8)

        b = BlockArrays.CumsumBlockRange(-1,[-1,1,4])
        @test @inferred(findblock(b,-1)) == Block(1)
        @test @inferred(findblockindex(b,-1)) == Block(1)[1]
        @test findblock.(Ref(b),-1:4) == Block.([1,2,2,3,3,3])
        @test findblockindex.(Ref(b),-1:4) == BlockIndex.([1,2,2,3,3,3],[1,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-2)
        @test_throws BoundsError findblock(b,5)
        @test_throws BoundsError findblockindex(b,-2)
        @test_throws BoundsError findblockindex(b,5)

        o = OffsetArray([2,2,3],-1:1)    
        b = BlockArrays.CumsumBlockRange(-3, cumsum(o) .- 4) 
        @test @inferred(findblock(b,-3)) == Block(-1)    
        @test @inferred(findblockindex(b,-3)) == Block(-1)[1]
        @test findblock.(Ref(b),-3:3) == Block.([-1,-1,0,0,1,1,1])
        @test findblockindex.(Ref(b),-3:3) == BlockIndex.([-1,-1,0,0,1,1,1], [1,2,1,2,1,2,3])
        @test_throws BoundsError findblock(b,-4)
        @test_throws BoundsError findblock(b,5) 
        @test_throws BoundsError findblockindex(b,-4)
        @test_throws BoundsError findblockindex(b,5)                   
        
        b = BlockArrays.CumsumBlockRange(Fill(3,1_000_000))
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
       b = BlockArrays.CumsumBlockRange([1,2,3]) 
       @test b[Block(3)[2]] == b[Block(3)][2] == 5
       @test b[Block(3)[2:3]] == b[Block(3)][2:3] == 5:6
    end

    @testset "BlockRange indexing" begin
       b = BlockArrays.CumsumBlockRange([1,2,3]) 
       @test b[Block.(1:2)] == BlockArrays.CumsumBlockRange([1,2]) 
       @test b[Block.(1:3)] == b
       @test_throws BlockBoundsError b[Block.(0:2)]
       @test_throws BlockBoundsError b[Block.(1:4)]
    end

    @testset "misc" begin
        b = BlockArrays.CumsumBlockRange([1,2,3])
        @test axes(b) == Base.unsafe_indices(b) == (b,)
        @test Base.dataids(b) == Base.dataids(BlockArrays._block_cumsum(b))
        @test_throws ArgumentError BlockArrays.CumsumBlockRange(b)
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