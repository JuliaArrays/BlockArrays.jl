function to_blockindex(a::AbstractUnitRange, index::Integer)
    axis_blockindex = findblockindex(only(axes(a)), index)
    if !isone(first(a)) && block(axis_blockindex) == Block(1)
        axis_blockindex = block(axis_blockindex)[blockindex(axis_blockindex) + first(a) - one(eltype(a))]
    end
    return axis_blockindex
end

function blockedunitrange_getindex(a::BlockedUnitRange, indices::AbstractUnitRange)
  first_block = block(to_blockindex(a, first(indices)))
  last_block = block(to_blockindex(a, last(indices)))
  lasts = [blocklasts(a)[Int(first_block):(Int(last_block) - 1)]; last(indices)]
  return BlockArrays._BlockedUnitRange(first(indices), lasts)
end

function _BlockIndices end

struct BlockIndices{N,R<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractBlockArray{BlockIndex{N},N}
  first::NTuple{N,Int}
  indices::R
  global function _BlockIndices(first::NTuple{N,Int}, indices::NTuple{N,AbstractUnitRange{Int}}) where {N}
      return new{N,typeof(indices)}(first, indices)
  end
end
function Base.axes(a::BlockIndices)
  return map(Base.axes1, blockedunitrange_getindex.(a.indices, (:).(a.first, last.(a.indices))))
end
function BlockIndices(indices::Tuple{Vararg{AbstractUnitRange{Int},N}}) where {N}
    first = ntuple(_ -> 1, Val(N))
    return _BlockIndices(first, indices)
end
BlockIndices(a::AbstractArray) = BlockIndices(axes(a))

function Base.getindex(a::BlockIndices{N}, index::Vararg{Integer,N}) where {N}
    return BlockIndex(to_blockindex.(a.indices, index .+ a.first .- 1))
end

function Base.view(a::BlockIndices{N}, block::Block{N}) where {N}
    return viewblock(a, block)
end

function Base.view(a::BlockIndices{1}, block::Block{1})
    return viewblock(a, block)
end

function Base.view(a::BlockIndices{N}, block::Vararg{Block{1},N}) where {N}
    return view(a, Block(block))
end

function viewblock(a::BlockIndices, block)
    range = Base.OneTo.(getindex.(blocklengths.(axes(a)), Int.(Tuple(block))))
    return block[range...]
end

function Base.view(a::BlockIndices{N}, indices::Vararg{BlockIndexRange{1},N}) where {N}
    return view(a, BlockIndexRange(Block(block.(indices)), only.(getfield.(indices, :indices))))
end

function Base.view(a::BlockIndices{N}, indices::BlockIndexRange{N}) where {N}
    a_block = a[block(indices)]
    return block(a_block)[getindex.(a_block.indices, indices.indices)...]
end

# Circumvent that this is getting hijacked to call `a[block(indices)][indices.indices...]`,
# which hits the bug https://github.com/JuliaArrays/BlockArrays.jl/issues/355.
function Base.getindex(a::BlockIndices{N}, indices::BlockIndexRange{N}) where {N}
    return view(a, indices)
end

function Base.view(a::BlockIndices{N}, indices::Vararg{AbstractUnitRange,N}) where {N}
    offsets = a.first .- ntuple(_ -> 1, Val(N))
    firsts = first.(indices) .+ offsets
    inds = blockedunitrange_getindex.(a.indices, Base.OneTo.(last.(indices) .+ offsets))
    return _BlockIndices(firsts, inds)
end

# Ranges that result in contiguous slices, and therefore preserve `BlockIndices`.
const BlockOrUnitRanges = Union{AbstractUnitRange,CartesianIndices{1},Block{1},BlockRange{1},BlockIndexRange{1}}

function Base.view(a::BlockIndices{N}, indices::Vararg{BlockOrUnitRanges,N}) where {N}
    return view(a, to_indices(a, indices)...)
end

function Base.view(a::BlockIndices{N}, indices::CartesianIndices{N}) where {N}
    return view(a, to_indices(a, (indices,))...)
end

# For some reason this doesn't call `view` automatically.
function Base.getindex(a::BlockIndices{N}, indices::CartesianIndices{N}) where {N}
    return view(a, to_indices(a, (indices,))...)
end

function Base.view(a::BlockIndices{N}, indices::BlockRange{N}) where {N}
    return view(a, to_indices(a, (indices,))...)
end

# For some reason this doesn't call `view` automatically.
function Base.getindex(a::BlockIndices{N}, indices::BlockRange{N}) where {N}
    return view(a, to_indices(a, (indices,))...)
end
