using BlockArrays, Test
import BlockArrays: BlockSlice
import Base: first, last, getindex, step, @_inline_meta, @boundscheck

struct BlockAxis{CS,BS,AX} <: AbstractUnitRange{Int}
    block_cumsum::CS
    block_axis::BS
    axis::AX
end

function BlockAxis(blocks::AbstractVector{Int}) 
    cs = cumsum(blocks)
    BlockAxis(cs, axes(blocks)[1], Base.OneTo(last(cs)))
end

function BlockAxis(blocks::AbstractVector{Int}, axis) 
    cs = cumsum(blocks)
    last(cs) == length(axis) || throw(ArgumentError("Block sizes must match axis"))
    BlockAxis(cs, axes(blocks)[1], axis)
end

"""
    blockaxes(A)

Return the tuple of valid block indices for array `A`.
"""
blockaxes(b::BlockAxis) = (b.block_axis,)

"""
    blockaxes(A, d)

Return the valid range of block indices for array `A` along dimension `d`.
```
"""
function blockaxes(A::AbstractArray{T,N}, d) where {T,N}
    @_inline_meta
    d::Integer <= N ? blockaxes(A)[d] : OneTo(1)
end

for op in (:first, :last, :step)
    @eval $op(b::BlockAxis) = $op(b.axis)
end

function getindex(b::BlockAxis, K::Block)
    k = Int(K)
    bax = blockaxes(b,1)
    @boundscheck k in bax || throw(BlockBoundsError(b, k))
    s = first(b.axis)
    k == first(bax) && return s:s+first(b.block_cumsum)-1
    return s+b.block_cumsum[k-1]:s+b.block_cumsum[k]-1
end

function findblock(b::BlockAxis, k::Integer)
    @boundscheck k in b.axis || throw(BoundsError(b,k))
    Block(searchsortedfirst(b.block_cumsum, k))
end

K = Block(-1)
K

b[Block(4)]

K = Block(2)
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

using OffsetArrays, Debugger
o = OffsetArray([2,2,3],-1:1)
@enter searchsortedfirst(o,1)
b = BlockAxis(o)
@test b[Block(-1)] == 1:2
@test b[Block(0)] == 3:4
@test b[Block(1)] == 5:7
@test_throws BlockBoundsError b[Block(-2)]
@test_throws BlockBoundsError b[Block(2)]



@test @inferred(findblock(b,1)) == Block(1)
@test findblock.(Ref(b),1:6) == Block.([1,2,2,3,3,3])
@test_throws BoundsError findblock(b,0)
@test_throws BoundsError findblock(b,7)

import Base: IdentityUnitRange


b = BlockAxis([1,2,3],IdentityUnitRange(-1:4))
@test b[Block(1)] == -1:-1
@test b[Block(2)] == 0:1
@test b[Block(3)] == 2:4
@test_throws BlockBoundsError b[Block(0)]
@test_throws BlockBoundsError b[Block(4)]

b = BlockAxis(o,IdentityUnitRange(-3:3))
@test b[Block(-1)] == -3:-2
@test b[Block(0)] == -1:0
@test b[Block(1)] == 1:3
@test_throws BlockBoundsError b[Block(-2)]
@test_throws BlockBoundsError b[Block(2)]

@test_throws ArgumentError BlockAxis(o,IdentityUnitRange(-4:3))


using FillArrays

b = BlockAxis(Fill(3,1_000_000))
@test b isa BlockAxis{StepRange{Int,Int},Base.OneTo{Int},Base.OneTo{Int}}
@test b[Block(100_000)] == 299998:300000
@test searchsortedfirst(b.block_cumsum, 1) == 1
searchsortedfirst.(Ref(b.block_cumsum), 299997:300001) 
