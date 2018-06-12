"""
    BlockSlice(indices)

Represent an AbstractUnitRange of indices that attaches a block.

Upon calling `to_indices()`, Blocks are converted to BlockSlice objects to represent
the indices over which the Block spans.

This mimics the relationship between `Colon` and `Base.Slice`.
"""
struct BlockSlice{BB} <: AbstractUnitRange{Int}
    block::BB
    indices::UnitRange{Int}
end

Block(bs::BlockSlice{<:Block}) = bs.block


for f in (:axes, :unsafe_indices, :indices1, :first, :last, :size, :length,
          :unsafe_length, :start)
    @eval $f(S::BlockSlice) = $f(S.indices)
end

getindex(S::BlockSlice, i::Int) = getindex(S.indices, i)
show(io::IO, r::BlockSlice) = print(io, "BlockSlice(", r.block, ",", r.indices, ")")
next(S::BlockSlice, s) = next(S.indices, s)
done(S::BlockSlice, s) = done(S.indices, s)

function _unblock(cum_sizes, I::Tuple{Block{1, T},Vararg{Any}}) where {T}
    B = first(I)
    b = first(B.n)

    range = cum_sizes[b]:cum_sizes[b + 1] - 1

    BlockSlice(B, range)
end



function _unblock(cum_sizes, I::Tuple{BlockRange{1,R}, Vararg{Any}}) where {R}
    B = first(I)
    b_start = first(first(B.indices))
    b_stop = last(first(B.indices))

    range = cum_sizes[b_start]:cum_sizes[b_stop + 1] - 1

    BlockSlice(B, range)
end


@inline _cumul_sizes(A::AbstractArray, j) = A.block_sizes[j]

# For a SubArray, we need to shift the block indices appropriately
function _cumul_sizes(V::SubArray, j)
    sl = parentindices(V)[j]
    @assert sl isa BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}
    A = parent(V)
    ret = view(_cumul_sizes(A, j), sl.block.indices[1][1]:(sl.block.indices[1][end]+1))
    ret .- ret[1] .+ 1
end

"""
    unblock(block_sizes, inds, I)

Returns the indices associated with a block as a `BlockSlice`.
"""
unblock(A::AbstractArray{T,N}, inds, I) where {T, N} =
    _unblock(_cumul_sizes(A, N - length(inds) + 1), I)



to_index(::Block) = throw(ArgumentError("Block must be converted by to_indices(...)"))
to_index(::BlockRange) = throw(ArgumentError("BlockRange must be converted by to_indices(...)"))

@inline to_indices(A, inds, I::Tuple{Block{1}, Vararg{Any}}) =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, inds, (Block.(I[1].n)..., tail(I)...))

@inline to_indices(A, inds, I::Tuple{BlockRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{BlockRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockRange.(tuple.(I[1].indices))..., tail(I)...))


# In 0.7, we need to override to_indices to avoid calling linearindices
@inline to_indices(A, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, axes(A), I)

@inline to_indices(A, I::Tuple{BlockRange, Vararg{Any}}) =
    to_indices(A, axes(A), I)


# BlockSlices map the blocks and the indices
# this is loosely based on Slice reindex in subarray.jl
reindex(V, idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(BlockRange(idxs[1].block.indices[1][Int.(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                    reindex(V, tail(idxs), tail(subidxs))...))

reindex(V, idxs::Tuple{BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}}) =
    (@_propagate_inbounds_meta; (BlockSlice(Block(idxs[1].block.indices[1][Int(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].indices]),
                                    reindex(V, tail(idxs), tail(subidxs))...))




#################
# support for pointers
#################

const BlockOrRangeIndex = Union{RangeIndex, BlockSlice}

function unsafe_convert(::Type{Ptr{T}},
                        V::SubArray{T, N, BlockArray{T, N, AT}, NTuple{N, BlockSlice{Block{1,Int}}}}) where AT <: AbstractArray{T, N} where {T,N}
    unsafe_convert(Ptr{T}, parent(V).blocks[Int.(Block.(parentindices(V)))...])
end

unsafe_convert(::Type{Ptr{T}}, V::SubArray{T,N,PseudoBlockArray{T,N,AT},<:Tuple{Vararg{BlockOrRangeIndex}}}) where {T,N,AT} =
    unsafe_convert(Ptr{T}, V.parent) + (Base.first_index(V)-1)*sizeof(T)
