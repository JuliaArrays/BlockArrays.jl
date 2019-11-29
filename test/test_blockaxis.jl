using BlockArrays, FillArrays, OffsetArrays, Test
import BlockArrays: BlockAxis

@testset "BlockAxis" begin
    b = BlockAxis([1,2,3])
    @test b[Block(1)] == 1:1
    @test b[Block(2)] == 2:3
    @test b[Block(3)] == 4:6
    @test_throws BlockBoundsError b[Block(0)]
    @test_throws BlockBoundsError b[Block(4)]
    @test @inferred(findblock(b,1)) == Block(1)
    @test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
    @test_throws BoundsError findblock(b,0)
    @test_throws BoundsError findblock(b,7)

    o = OffsetArray([2,2,3],-1:1)
    b = BlockAxis(o)
    @test b[Block(-1)] == 1:2
    @test b[Block(0)] == 3:4
    @test b[Block(1)] == 5:7
    @test_throws BlockBoundsError b[Block(-2)]
    @test_throws BlockBoundsError b[Block(2)]
    @test @inferred(findblock(b,1)) == Block(-1)
    @test findblock.(Ref(b),1:7) == Block.([-1,-1,0,0,1,1,1])
    @test_throws BoundsError findblock(b,0)
    @test_throws BoundsError findblock(b,8)

    b = BlockAxis([1,2,3],Base.IdentityUnitRange(-1:4))
    @test b[Block(1)] == -1:-1
    @test b[Block(2)] == 0:1
    @test b[Block(3)] == 2:4
    @test_throws BlockBoundsError b[Block(0)]
    @test_throws BlockBoundsError b[Block(4)]
    @test @inferred(findblock(b,-1)) == Block(1)
    @test findblock.(Ref(b),-1:4) == Block.([1,2,2,3,3,3])
    @test_throws BoundsError findblock(b,-2)
    @test_throws BoundsError findblock(b,5)

    o = OffsetArray([2,2,3],-1:1)    
    b = BlockAxis(o,Base.IdentityUnitRange(-3:3))
    @test b[Block(-1)] == -3:-2
    @test b[Block(0)] == -1:0
    @test b[Block(1)] == 1:3
    @test_throws BlockBoundsError b[Block(-2)]
    @test_throws BlockBoundsError b[Block(2)]
    @test @inferred(findblock(b,-3)) == Block(-1)    
    @test findblock.(Ref(b),-3:3) == Block.([-1,-1,0,0,1,1,1])
    @test_throws BoundsError findblock(b,-2)
    @test_throws BoundsError findblock(b,5)    

    @test_throws ArgumentError BlockAxis(o,Base.IdentityUnitRange(-4:3))


    b = BlockAxis(Fill(3,1_000_000))
    @test b isa BlockAxis{StepRange{Int,Int},Base.OneTo{Int},Base.OneTo{Int}}
    @test b[Block(100_000)] == 299_998:300_000
    @test_throws BlockBoundsError b[Block(0)]
    @test_throws BlockBoundsError b[Block(1_000_001)]
    @test findblock(b, 1) == Block(1)
    @test findblock.(Ref(b),299_997:300_001) == Block.([99_999,100_000,100_000,100_000,100_001])
    @test_throws BoundsError findblock(b,0)
    @test_throws BoundsError findblock(b,3_000_001)    
end