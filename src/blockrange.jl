struct BlockRange{N,R<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractArray{Block{N,Int},N}
    indices::R
    BlockRange{N,R}(inds::R) where {N,R} = new{N,R}(inds)
end


# The following is adapted from Julia v0.7 base/multidimensional.jl
# definition of CartesianRange

# deleted code that isn't used, such as 0-dimensional case
"""
    BlockRange(startblock, stopblock)

represents a cartesian range of blocks.

The relationship between `Block` and `BlockRange` mimicks the relationship between
`CartesianIndex` and `CartesianRange`.
"""
BlockRange

BlockRange(inds::NTuple{N,AbstractUnitRange{Int}}) where {N} =
    BlockRange{N,typeof(inds)}(inds)
BlockRange(inds::Vararg{AbstractUnitRange{Int},N}) where {N} =
    BlockRange(inds)

(:)(start::Block{1}, stop::Block{1}) = BlockRange((first(start.n):first(stop.n),))
(:)(start::Block, stop::Block) = throw(ArgumentError("Use `BlockRange` to construct a cartesian range of blocks"))
Base.BroadcastStyle(::Type{<:BlockRange{1}}) = DefaultArrayStyle{1}()
broadcasted(::DefaultArrayStyle{1}, ::typeof(Block), r::UnitRange) = Block(first(r)):Block(last(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(Int), block_range::BlockRange{1}) = first(block_range.indices)


# AbstractArray implementation
axes(iter::BlockRange{N,R}) where {N,R} = map(axes1, iter.indices)
Base.IndexStyle(::Type{BlockRange{N,R}}) where {N,R} = IndexCartesian()
@inline function Base.getindex(iter::BlockRange{N,<:NTuple{N,Base.OneTo}}, I::Vararg{Int, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    Block(I)
end
@inline function Base.getindex(iter::BlockRange{N,R}, I::Vararg{Int, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    Block(I .- first.(axes1.(iter.indices)) .+ first.(iter.indices))
end


@inline function iterate(iter::BlockRange)
    iterfirst, iterlast = first(iter), last(iter)
    if any(map(>, iterfirst.n, iterlast.n))
        return nothing
    end
    iterfirst, iterfirst
end
@inline function iterate(iter::BlockRange, state)
    nextstate = Block(inc(state.n, first(iter).n, last(iter).n))
    nextstate.n[end] > last(iter.indices[end]) && return nothing
    nextstate, nextstate
end

# increment & carry
@inline inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
@inline inc(state::Tuple{Int}, start::Tuple{Int}, stop::Tuple{Int}) = (state[1]+1,)
@inline function inc(state, start, stop)
    if state[1] < stop[1]
        return (state[1]+1,tail(state)...)
    end
    newtail = inc(tail(state), tail(start), tail(stop))
    (start[1], newtail...)
end

# 0-d cartesian ranges are special-cased to iterate once and only once
iterate(iter::BlockRange{0}, done=false) = done ? nothing : (Block(), true)

size(iter::BlockRange) = map(dimlength, first(iter).n, last(iter).n)
dimlength(start, stop) = stop-start+1

length(iter::BlockRange) = prod(size(iter))

first(iter::BlockRange) = Block(map(first, iter.indices))
last(iter::BlockRange)  = Block(map(last, iter.indices))

@inline function in(i::Block{N}, r::BlockRange{N}) where {N}
    _in(true, i.n, first(r).n, last(r).n)
end
_in(b, ::Tuple{}, ::Tuple{}, ::Tuple{}) = b
@inline _in(b, i, start, stop) = _in(b & (start[1] <= i[1] <= stop[1]), tail(i), tail(start), tail(stop))
