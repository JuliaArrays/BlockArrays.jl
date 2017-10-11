doc"""
    BlockRange(startblock, stopblock)

represents a cartesian range of blocks.

The relationship between `Block` and `BlockRange` mimicks the relationship between
`CartesianIndex` and `CartesianRange`.
"""
struct BlockRange{I<:Block}
    start::I
    stop::I
end


colon(start::Block{1}, stop::Block{1}) = BlockRange(start, stop)
colon(start::Block, stop::Block) = throw(ArgumentError("Use `BlockRange` to construct a cartesian range of blocks"))
broadcast(::typeof(Block), range::UnitRange) = Block(first(range)):Block(last(range))

eltype(::Type{BlockRange{I}}) where I = I
eltype(::BlockRange{I}) where I = I

# BlockRange behaves like CartesianRange
for f in (:indices, :unsafe_indices, :indices1, :size, :length,
          :unsafe_length, :start)
    @eval $f(B::BlockRange) = $f(CartesianRange(CartesianIndex(B.start.n), CartesianIndex(B.stop.n)))
end

first(B::BlockRange) = B.start
last(B::BlockRange) = B.stop

function next(B::BlockRange, s)
    a, b = next(CartesianRange(CartesianIndex(B.start.n), CartesianIndex(B.stop.n)), s)
    Block(a.I), b
end
done(B::BlockRange, s) = done(CartesianRange(CartesianIndex(B.start.n), CartesianIndex(B.stop.n)), s)
