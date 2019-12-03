abstract type AbstractBlockAxis <:AbstractUnitRange{Int} end

# interface
getindex(b::AbstractBlockAxis, K::Block{1}) = error("Override for $(typeof(b))")
getindex(b::AbstractVector, K::BlockIndex{1}) = b[Block(K.I[1])][K.α[1]]
getindex(b::AbstractVector, K::BlockIndexRange{1}) = b[K.block][K.indices[1]]

blockaxes(b::AbstractBlockAxis) = error("Override for $(typeof(b))")

function findblockindex(b::AbstractVector, k::Integer)
    K = findblock(b, k)
    K[searchsortedfirst(b[K], k)] # guaranteed to be in range
end

struct BlockAxis{CS,BS,AX} <: AbstractBlockAxis
    block_cumsum::CS
    block_axis::BS
    axis::AX
end

const DefaultBlockAxis = BlockAxis{Vector{Int},Base.OneTo{Int},Base.OneTo{Int}}

BlockAxis(::AbstractBlockAxis) = throw(ArgumentError("Forbidden due to ambiguity"))

@inline function _cumsum2BlockAxis(cs, axis) 
    last(cs) == length(axis) || throw(ArgumentError("Block sizes must match axis"))
    BlockAxis(cs, axes(cs,1), axis)
end
@inline _cumsum2BlockAxis(cs) = _cumsum2BlockAxis(cs, Base.OneTo(last(cs)))

@inline BlockAxis(blocks::AbstractVector{Int}) = _cumsum2BlockAxis(cumsum(blocks))
@inline BlockAxis(blocks::AbstractVector{Int}, axis)  = _cumsum2BlockAxis(cumsum(blocks), axis)

@inline _block_cumsum(a::BlockAxis) = a.block_cumsum

Base.convert(::Type{AbstractBlockAxis}, axis::AbstractBlockAxis) = axis
Base.convert(::Type{AbstractBlockAxis}, axis::AbstractUnitRange{Int}) = convert(BlockAxis, axis)
Base.convert(::Type{BlockAxis}, axis::BlockAxis) = axis
Base.convert(::Type{BlockAxis}, axis::AbstractUnitRange{Int}) = BlockAxis([length(axis)], axis)
Base.convert(::Type{BlockAxis}, axis::Base.Slice) = convert(BlockAxis, axis.indices)
Base.convert(::Type{BlockAxis}, axis::Base.IdentityUnitRange) = convert(BlockAxis, axis.indices)

"""
    blockaxes(A)

Return the tuple of valid block indices for array `A`.
"""
blockaxes(b::BlockAxis) = (Block.(b.block_axis),)
blockaxes(b::AbstractArray{<:Any,N}) where N = blockaxes.(axes(b), 1)

"""
    blockaxes(A, d)

Return the valid range of block indices for array `A` along dimension `d`.
```
"""
function blockaxes(A::AbstractArray{T,N}, d) where {T,N}
    @_inline_meta
    d::Integer <= N ? blockaxes(A)[d] : OneTo(1)
end

blocksize(A) = map(length, blockaxes(A))
blocksize(A,i) = length(blockaxes(A,i))
blocklength(t) = (@_inline_meta; prod(blocksize(t)))


for op in (:first, :last, :step)
    @eval $op(b::BlockAxis) = $op(b.axis)
end

function getindex(b::BlockAxis, K::Block{1})
    k = Int(K)
    bax = blockaxes(b,1)
    @boundscheck K in bax || throw(BlockBoundsError(b, k))
    s = first(b.axis)
    K == first(bax) && return s:s+first(b.block_cumsum)-1
    return s+b.block_cumsum[k-1]:s+b.block_cumsum[k]-1
end

function getindex(b::BlockAxis, KR::BlockRange{1})
    K = first(KR)
    J = last(KR)
    # @boundscheck K in blockaxes(b,1) || throw(
    # b.block_cumsum[
end

function findblock(b::BlockAxis, k::Integer)
    @boundscheck k in b.axis || throw(BoundsError(b,k))
    Block(searchsortedfirst(b.block_cumsum, k-first(b.axis)+1))
end

Base.dataids(b::BlockAxis) = Base.dataids(b.block_cumsum)


###
# BlockAxis interface
###
function getindex(b::AbstractUnitRange{Int}, K::Block{1})
    @boundscheck K == Block(1) || throw(BlockBoundsError(b, K))
    b
end

blockaxes(b::AbstractUnitRange{Int}) = (Block.(Base.OneTo(1)),)

function findblock(b::AbstractUnitRange{Int}, k::Integer)
    @boundscheck k in axes(b,1) || throw(BoundsError(b,k))
    Block(1)
end

_block_cumsum(a::AbstractUnitRange{Int}) = [length(a)]