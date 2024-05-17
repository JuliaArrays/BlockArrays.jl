### Views

"""
    unblock(block_sizes, inds, I)

Returns the indices associated with a block as a `BlockSlice`.
"""
function unblock(A, inds, I)
    B = first(I)
    BlockSlice(B,inds[1][B])
end
# Allow `ones(2)[Block(1)[1:1], Block(1)[1:1]]` which is
# similar to `ones(2)[1:1, 1:1]`.
# Need to check the length of I in case its empty
unblock(A, ::Tuple{}, I) = BlockSlice(first(I),Base.OneTo(length(I[1])))

to_index(::Block) = throw(ArgumentError("Block must be converted by to_indices(...)"))
to_index(::BlockIndex) = throw(ArgumentError("BlockIndex must be converted by to_indices(...)"))
to_index(::BlockIndexRange) = throw(ArgumentError("BlockIndexRange must be converted by to_indices(...)"))
to_index(::BlockRange) = throw(ArgumentError("BlockRange must be converted by to_indices(...)"))


@inline to_indices(A, inds, I::Tuple{Block{1}, Vararg{Any}}) =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)
@inline to_indices(A, inds, I::Tuple{BlockRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)
@inline to_indices(A, inds, I::Tuple{BlockIndex{1}, Vararg{Any}}) =
    (inds[1][I[1]], to_indices(A, _maybetail(inds), tail(I))...)
@inline to_indices(A, inds, I::Tuple{BlockIndexRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)

# splat out higher dimensional blocks
# this mimics view of a CartesianIndex
@inline to_indices(A, inds, I::Tuple{Block, Vararg{Any}}) =
    to_indices(A, inds, (Block.(I[1].n)..., tail(I)...))
@inline to_indices(A, inds, I::Tuple{BlockIndex, Vararg{Any}}) =
    to_indices(A, inds, (BlockIndex.(I[1].I, I[1].α)..., tail(I)...))
@inline to_indices(A, inds, I::Tuple{BlockIndexRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockIndexRange.(Block.(I[1].block.n), tuple.(I[1].indices))..., tail(I)...))
@inline to_indices(A, inds, I::Tuple{BlockRange, Vararg{Any}}) =
    to_indices(A, inds, (BlockRange.(tuple.(I[1].indices))..., tail(I)...))

# In 0.7, we need to override to_indices to avoid calling linearindices
@inline to_indices(A, I::Tuple{BlockIndexRange, Vararg{Any}}) = to_indices(A, axes(A), I)
@inline to_indices(A, I::Tuple{Block, Vararg{Any}}) = to_indices(A, axes(A), I)
@inline to_indices(A, I::Tuple{BlockRange, Vararg{Any}}) = to_indices(A, axes(A), I)

@propagate_inbounds reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
    (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                            subidxs[1].block.indices),
                                            idxs[1].indices[subidxs[1].indices]),
                                reindex(tail(idxs), tail(subidxs))...)
@propagate_inbounds reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:Block}, Vararg{Any}}) =
    (BlockSlice(idxs[1].block[Int(subidxs[1].block)],
                                            idxs[1].indices[subidxs[1].indices]),
                                reindex(tail(idxs), tail(subidxs))...)

@propagate_inbounds reindex(idxs::Tuple{AbstractBlockedUnitRange, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:Block}, Vararg{Any}}) =
    (BlockSlice(subidxs[1].block,
                                            idxs[1][subidxs[1].block]),
                                reindex(tail(idxs), tail(subidxs))...)
# _splatmap taken from Base:
_splatmap(f, ::Tuple{}) = ()
_splatmap(f, t::Tuple) = (f(t[1])..., _splatmap(f, tail(t))...)

# De-reference blocks before creating a view to avoid taking `global2blockindex`
# path in `AbstractBlockStyle` broadcasting.
@propagate_inbounds function Base.unsafe_view(
        A::BlockArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    B = view(A, map(block, I)...)
    return view(B, _splatmap(x -> x.block.indices, I)...)
end

@propagate_inbounds function Base.unsafe_view(
        A::BlockedArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    return view(A.blocks, map(x -> x.indices, I)...)
end

@propagate_inbounds  function Base.unsafe_view(
        A::ReshapedArray{<:Any, N, <:AbstractBlockArray{<:Any, M}},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N, M}
    # Note: assuming that I[M+1:end] are verified to be singletons
    return reshape(view(A.parent, I[1:M]...), Val(N))
end

@propagate_inbounds  function Base.unsafe_view(
        A::Array{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    return view(A, map(x -> x.indices, I)...)
end

# make sure we reindex correctrly
@inline function Base._maybe_reindex(V, I::Tuple{BlockSlice{<:BlockIndexRange{1}}, Vararg{Any}}, ::Tuple{})
    @inbounds idxs = to_indices(V.parent, reindex(V.indices, I))
    view(V.parent, idxs...)
end


# BlockSlices map the blocks and the indices
# this is loosely based on Slice reindex in subarray.jl
@propagate_inbounds reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}}) =
    (BlockSlice(BlockRange(idxs[1].block.indices[1][Int.(subidxs[1].block)]),
                                            idxs[1].indices[subidxs[1].block]),
                                reindex(tail(idxs), tail(subidxs))...)


function reindex(idxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}},
        subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}})
        (idxs[1], reindex(tail(idxs), tail(subidxs))...)
end


#################
# support for pointers
#################

const BlockOrRangeIndex = Union{RangeIndex, BlockSlice}

## BlockSlice1 is a convenience for views
const BlockSlice1 = BlockSlice{Block{1,Int}}

block(A::BlockSlice) = block(A.block)
block(A::Block) = A

# unwind BLockSlice1 for AbstractBlockArray
@inline view(block_arr::AbstractBlockArray{<:Any,N}, blocks::Vararg{BlockSlice1, N}) where N =
    view(block_arr, map(block,blocks)...)

const BlockSlices = Union{Base.Slice,BlockSlice{<:BlockRange{1}}}
# view(V::SubArray{<:Any,N,NTuple{N,BlockSlices}},

_block_reindex(b::BlockSlice, i::Block{1}) = b.block[Int(i)]
_block_reindex(b::Slice, i::Block{1}) = i

@inline view(V::SubArray{<:Any,N,<:AbstractBlockArray,<:NTuple{N,BlockSlices}}, block::Block{N}) where N =
    view(parent(V), _block_reindex.(parentindices(V), Block.(block.n))...)
@inline view(V::SubArray{<:Any,N,<:AbstractBlockArray,<:NTuple{N,BlockSlices}}, block::Vararg{Block{1},N}) where N =
    view(parent(V), _block_reindex.(parentindices(V), block)...)
@inline view(V::SubArray{<:Any,1,<:AbstractBlockArray,<:Tuple{BlockSlices}}, block::Block{1}) =
    view(parent(V), _block_reindex(parentindices(V)[1], block))




function view(A::Adjoint{<:Any,<:BlockMatrix}, b::Block{2})
    k, j = b.n
    view(parent(A), Block(j), Block(k))'
end
function view(A::Transpose{<:Any,<:BlockMatrix}, b::Block{2})
    k, j = b.n
    transpose(view(parent(A), Block(j), Block(k)))
end

function view(A::Adjoint{<:Any,<:BlockVector}, b::Block{2})
    @boundscheck blockcheckbounds(A, b)
    k, j = b.n
    view(parent(A), Block(j))'
end
function view(A::Transpose{<:Any,<:BlockVector}, b::Block{2})
    @boundscheck blockcheckbounds(A, b)
    k, j = b.n
    transpose(view(parent(A), Block(j)))
end

view(A::AdjOrTrans{<:Any,<:BlockArray}, K::Block{1}, J::Block{1}) = view(A, Block(Int(K), Int(J)))

@propagate_inbounds getindex(v::LinearAlgebra.AdjOrTransAbsVec, ::Colon, is::AbstractArray{<:Block{1}}) = LinearAlgebra.wrapperop(v)(v.parent[is])


unsafe_convert(::Type{Ptr{T}}, V::SubArray{T,N,BlockedArray{T,N,AT},<:Tuple{Vararg{BlockOrRangeIndex}}}) where {T,N,AT} =
    unsafe_convert(Ptr{T}, V.parent) + (Base.first_index(V)-1)*sizeof(T)

# support for strided array interface for subblocks. Typically
# these aren't needed as `view(A, Block(K))` will return the block itself,
# not a `SubArray`, but currently `view(view(A, Block.(1:3)), Block(2))` does
# not.

strides(A::SubArray{<:Any,N,<:BlockArray,<:NTuple{N,BlockSlice1}}) where N =
    strides(view(parent(A), block.(parentindices(A))...))

for Adj in (:Transpose, :Adjoint)
    @eval strides(A::SubArray{<:Any,N,<:$Adj{<:Any,<:BlockArray},<:NTuple{N,BlockSlice1}}) where N =
        strides(view(parent(A), block.(parentindices(A))...))
end

unsafe_convert(::Type{Ptr{T}}, V::SubArray{T, N, <:BlockArray, <:NTuple{N, BlockSlice1}}) where {T,N} =
    unsafe_convert(Ptr{T}, view(parent(V), block.(parentindices(V))...))
Base.elsize(::Type{<:SubArray{T, N, <:BlockArray{T, N, <:AbstractArray{Block}}, <:NTuple{N, BlockSlice1}}}) where {T,N,Block} =
    Base.elsize(Block)


# The default blocksize(V) is slow for views as it calls axes(V), which
# allocates. Here we work around this.

_sub_blocksize() = ()
_sub_blocksize(ind::BlockSlice{<:BlockRange{1}}, inds...) = tuple(length(ind.block),_sub_blocksize(inds...)...)
_sub_blocksize(ind::BlockSlice{<:Block{1}}, inds...) = tuple(1,_sub_blocksize(inds...)...)
_sub_blocksize(ind::AbstractVector, inds...) = tuple(blocksize(ind,1),_sub_blocksize(inds...)...)
_sub_blocksize(ind::Integer, inds...) = _sub_blocksize(inds...)
blocksize(V::SubArray) = _sub_blocksize(parentindices(V)...)
blocksize(V::SubArray, i::Int) = _sub_blocksize(parentindices(V)[i])[1]

function hasmatchingblocks(V::SubArray{<:Any,2,<:Any,<:NTuple{2,BlockSlice{<:BlockRange{1}}}})
    a,b = axes(parent(V))
    kr,jr = parentindices(V)
    KR,JR = (kr.block),(jr.block)
    length(KR) == length(JR) || return false
    for (K,J) in zip(KR,JR)
        length(a[K]) == length(b[J]) || return false
    end
    true
end
