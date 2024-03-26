struct BlockIndices{N,R<:NTuple{N,OrdinalRange{Int,Int}}} <: AbstractBlockArray{BlockIndex{N},N}
  indices::R
end
Base.axes(a::BlockIndices) = map(Base.axes1, a.indices)
BlockIndices(a::AbstractArray) = BlockIndices(axes(a))

function to_blockindex(a::AbstractUnitRange, index::Integer)
    axis_blockindex = findblockindex(only(axes(a)), index)
    if !isone(first(a)) && block(axis_blockindex) == Block(1)
        axis_blockindex = block(axis_blockindex)[blockindex(axis_blockindex) + first(a) - one(eltype(a))]
    end
    return axis_blockindex
end

function Base.getindex(a::BlockIndices{N}, index::Vararg{Integer,N}) where {N}
    return BlockIndex(to_blockindex.(a.indices, index))
end

function Base.view(a::BlockIndices{N}, block::Block{N}) where {N}
    return viewblock(a, block)
end

function Base.view(a::BlockIndices, block::Vararg{Block{1}})
  return view(a, Block(block))
end

function viewblock(a::BlockIndices, block)
    range = Base.OneTo.(getindex.(blocklengths.(axes(a)), Int.(Tuple(block))))
    return block[range...]
end
