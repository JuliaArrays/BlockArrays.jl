struct BlockIndices{N,R<:NTuple{N,OrdinalRange{Int,Int}}} <: AbstractBlockArray{BlockIndex{N},N}
  indices::R
end
Base.axes(a::BlockIndices) = map(Base.axes1, a.indices)
BlockIndices(a::AbstractArray) = BlockIndices(axes(a))

function Base.getindex(a::BlockIndices{N}, index::Vararg{Integer,N}) where {N}
    return BlockIndex(findblockindex.(axes(a), index))
end

function Base.view(a::BlockIndices{N}, block::Block{N}) where {N}
    return viewblock(a, block)
end

function viewblock(a::BlockIndices, block)
    range = Base.OneTo.(getindex.(blocklengths.(axes(a)), Int.(Tuple(block))))
    return block[range...]
end
