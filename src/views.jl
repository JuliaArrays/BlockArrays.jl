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



function unblock(block_sizes, I)
    B = first(I)
    BlockSlice(B,
            first(globalrange(block_sizes,(first(B.n),))))
end

@inline to_indices(A, inds, I::Tuple{Block, Vararg{Any}}) =
    (unblock(A.block_sizes, I), to_indices(A, _maybetail(inds), tail(I))...)
