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

getindex(b::BlockAxis, K::BlockIndex{1}) = b[Block(K.I[1])][K.α[1]]
getindex(b::BlockAxis, K::BlockIndexRange{1}) = b[K.block][K.indices[1]]

function findblock(b::BlockAxis, k::Integer)
    @boundscheck k in b.axis || throw(BoundsError(b,k))
    Block(searchsortedfirst(b.block_cumsum, k-first(b.axis)+1))
end

Base.dataids(b::BlockAxis) = Base.dataids(b.block_cumsum)