"""
    BlockSlice(indices)

Represent an AbstractUnitRange of indices that attaches a block.

Upon calling `to_indices()`, Blocks are converted to BlockSlice objects to represent
the indices over which the Block spans.

This mimics the relationship between `Colon` and `Base.Slice`.
"""
struct BlockSlice <: AbstractUnitRange{Int}
    block::Block{1,Int}
    indices::UnitRange{Int}
end

for f in (:indices, :unsafe_indices, :indices1, :first, :last, :size, :length,
          :unsafe_length, :start)
    @eval $f(S::BlockSlice) = $f(S.indices)
end

getindex(S::BlockSlice, i::Int) = getindex(S.indices, i)
show(io::IO, r::BlockSlice) = print(io, "BlockSlice(", r.block, ",", r.indices, ")")
next(S::BlockSlice, s) = next(S.indices, s)
done(S::BlockSlice, s) = done(S.indices, s)


"""
    unblock(block_sizes, I)

Returns the indices associated with a block as a `BlockSlice`.
"""
function unblock(block_sizes::BlockSizes{N}, inds, I::Tuple{Block{1,T},Vararg{Any}}) where {N, T}
    B = first(I)
    b = first(B.n)
    # the size of inds tells us how many indices have been processed
    M = length(inds)
    J = N - M + 1

    range = block_sizes[J, b]:block_sizes[J, b + 1] - 1

    BlockSlice(B,range)
end

to_index(::Block) = throw(ArgumentError("blocks must be converted by to_indices(...)"))

@inline to_indices(A, inds, I::Tuple{Block{1}, Vararg{Any}}) =
    (unblock(A.block_sizes, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, inds, (Block.(I[1].n)..., tail(I)...))
