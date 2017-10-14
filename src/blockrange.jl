doc"""
    BlockRange(startblock, stopblock)

represents a cartesian range of blocks.

The relationship between `Block` and `BlockRange` mimicks the relationship between
`CartesianIndex` and `CartesianRange`.
"""
struct BlockRange{N,R<:NTuple{N,AbstractUnitRange{Int}}}
    indices::R
end


# The following is adapted from Julia v0.7 base/multidimensional.jl
# definition of CartesianRange

BlockRange(::Tuple{}) = BlockRange{0,typeof(())}(())
BlockRange(inds::NTuple{N,AbstractUnitRange{Int}}) where {N} =
    BlockRange{N,typeof(inds)}(inds)
BlockRange(inds::Vararg{AbstractUnitRange{Int},N}) where {N} =
    BlockRange(inds)
BlockRange(inds::NTuple{N,AbstractUnitRange{<:Integer}}) where {N} =
    BlockRange(map(r->convert(AbstractUnitRange{Int}, r), inds))
BlockRange(inds::Vararg{AbstractUnitRange{<:Integer},N}) where {N} =
    BlockRange(inds)

BlockRange(index::Block) = BlockRange(index.n)
BlockRange(sz::NTuple{N,<:Integer}) where {N} = BlockRange(map(Base.OneTo, sz))
BlockRange(inds::NTuple{N,Union{<:Integer,AbstractUnitRange{<:Integer}}}) where {N} =
    BlockRange(map(i->first(i):last(i), inds))

colon(start::Block{1}, stop::Block{1}) = BlockRange((first(start.n):first(stop.n),))
colon(start::Block, stop::Block) = throw(ArgumentError("Use `BlockRange` to construct a cartesian range of blocks"))
broadcast(::typeof(Block), range::UnitRange) = Block(first(range)):Block(last(range))

eltype(R::BlockRange) = eltype(typeof(R))
eltype(::Type{BlockRange{N}}) where {N} = Block{N,Int}
eltype(::Type{BlockRange{N,R}}) where {N,R} = Block{N,Int}
iteratorsize(::Type{<:BlockRange}) = Base.HasShape()

@inline function start(iter::BlockRange)
    iterfirst, iterlast = first(iter), last(iter)
    if any(map(>, iterfirst.n, iterlast.n))
        return iterlast+1
    end
    iterfirst
end
@inline function next(iter::BlockRange, state)
    state, Block(inc(state.n, first(iter).n, last(iter).n))
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
@inline done(iter::BlockRange, state) = state.n[end] > last(iter.indices[end])

# 0-d cartesian ranges are special-cased to iterate once and only once
start(iter::BlockRange{0}) = false
next(iter::BlockRange{0}, state) = Block(), true
done(iter::BlockRange{0}, state) = state

size(iter::BlockRange) = map(dimlength, first(iter).n, last(iter).n)
dimlength(start, stop) = stop-start+1

length(iter::BlockRange) = prod(size(iter))

first(iter::BlockRange) = Block(map(first, iter.indices))
last(iter::BlockRange)  = Block(map(last, iter.indices))
