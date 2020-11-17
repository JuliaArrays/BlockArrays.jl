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
unblock(A, ::Tuple{}, I) = BlockSlice(first(I),Base.OneTo(1))

to_index(::Block) = throw(ArgumentError("Block must be converted by to_indices(...)"))
to_index(::BlockIndex) = throw(ArgumentError("BlockIndex must be converted by to_indices(...)"))
to_index(::BlockIndexRange) = throw(ArgumentError("BlockIndexRange must be converted by to_indices(...)"))
to_index(::BlockRange) = throw(ArgumentError("BlockRange must be converted by to_indices(...)"))


@inline to_indices(A, inds, I::Tuple{Block{1}, Vararg{Any}}) =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)
@inline to_indices(A, inds, I::Tuple{BlockRange{1,R}, Vararg{Any}}) where R =
    (unblock(A, inds, I), to_indices(A, _maybetail(inds), tail(I))...)
@inline to_indices(A, inds, I::Tuple{BlockIndex{1}, Vararg{Any}}) where R =
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

if VERSION >= v"1.2-"  # See also `reindex` definitions in views.jl
    reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                                subidxs[1].block.indices),
                                                idxs[1].indices[subidxs[1].indices]),
                                    reindex(tail(idxs), tail(subidxs))...))
else  # if VERSION >= v"1.2-"
    reindex(V, idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{<:BlockIndexRange}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(BlockIndexRange(Block(idxs[1].block.indices[1][Int(subidxs[1].block.block)]),
                                                                subidxs[1].block.indices),
                                                idxs[1].indices[subidxs[1].indices]),
                                        reindex(V, tail(idxs), tail(subidxs))...))
end  # if VERSION >= v"1.2-"


# _splatmap taken from Base:
_splatmap(f, ::Tuple{}) = ()
_splatmap(f, t::Tuple) = (f(t[1])..., _splatmap(f, tail(t))...)

# De-reference blocks before creating a view to avoid taking `global2blockindex`
# path in `AbstractBlockStyle` broadcasting.
@inline function Base.unsafe_view(
        A::BlockArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    B = getblock(A, map(x -> Int(x.block.block), I)...)
    return view(B, _splatmap(x -> x.block.indices, I)...)
end

@inline function Base.unsafe_view(
        A::PseudoBlockArray{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    return view(A.blocks, map(x -> x.indices, I)...)
end

@inline function Base.unsafe_view(
        A::ReshapedArray{<:Any, N, <:AbstractBlockArray{<:Any, M}},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N, M}
    @_propagate_inbounds_meta
    # Note: assuming that I[M+1:end] are verified to be singletons
    return reshape(view(A.parent, I[1:M]...), Val(N))
end

@inline function Base.unsafe_view(
        A::Array{<:Any, N},
        I::Vararg{BlockSlice{<:BlockIndexRange{1}}, N}) where {N}
    @_propagate_inbounds_meta
    return view(A, map(x -> x.indices, I)...)
end


# The first argument for `reindex` is removed as of
# https://github.com/JuliaLang/julia/pull/30789 in Julia `Base`.  So,
# we define 2-arg `reindex` for Julia 1.2 and later.
if VERSION >= v"1.2-"
    # BlockSlices map the blocks and the indices
    # this is loosely based on Slice reindex in subarray.jl
    reindex(idxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{<:BlockRange}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(BlockRange(idxs[1].block.indices[1][Int.(subidxs[1].block)]),
                                                idxs[1].indices[subidxs[1].indices]),
                                    reindex(tail(idxs), tail(subidxs))...))

    reindex(idxs::Tuple{BlockSlice{BlockRange{1,Tuple{UnitRange{Int}}}}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}}) =
        (@_propagate_inbounds_meta; (BlockSlice(Block(idxs[1].block.indices[1][Int(subidxs[1].block)]),
                                                idxs[1].indices[subidxs[1].indices]),
                                    reindex(tail(idxs), tail(subidxs))...))

    function reindex(idxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}})
            (idxs[1], reindex(tail(idxs), tail(subidxs))...)
    end
else  # if VERSION >= v"1.2-"
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

    function reindex(V, idxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}},
            subidxs::Tuple{BlockSlice{Block{1,Int}}, Vararg{Any}})
        subidxs[1].block == Block(1) || throw(BoundsError(V, subidxs[1].block))
        (idxs[1], reindex(V, tail(idxs), tail(subidxs))...)
    end
end  # if VERSION >= v"1.2-"


#################
# support for pointers
#################

const BlockOrRangeIndex = Union{RangeIndex, BlockSlice}

## BlockSlice1 is a convenience for views
const BlockSlice1 = BlockSlice{Block{1,Int},UnitRange{Int}}

block(A::BlockSlice) = block(A.block)
block(A::Block) = A

getblock(A::SubArray{<:Any,N,<:Any,NTuple{N,BlockSlice1}}) where N =
    getblock(parent(A), Int.(block.(parentindices(A)))...)
getblock(A::Adjoint, k::Int, j::Int) = getblock(parent(A), j, k)'
getblock(A::Transpose, k::Int, j::Int) = transpose(getblock(parent(A), j, k))

strides(A::SubArray{<:Any,N,<:BlockArray,NTuple{N,BlockSlice1}}) where N =
    strides(getblock(A))

for Adj in (:Transpose, :Adjoint)
    @eval strides(A::SubArray{<:Any,N,<:$Adj{<:Any,<:BlockArray},NTuple{N,BlockSlice1}}) where N =
        strides(getblock(A))
end


unsafe_convert(::Type{Ptr{T}}, V::SubArray{T, N, <:Any, <:NTuple{N, BlockSlice1}}) where {T,N} =
    unsafe_convert(Ptr{T}, getblock(parent(V), Int.(Block.(parentindices(V)))...))

unsafe_convert(::Type{Ptr{T}}, V::SubArray{T,N,PseudoBlockArray{T,N,AT},<:Tuple{Vararg{BlockOrRangeIndex}}}) where {T,N,AT} =
    unsafe_convert(Ptr{T}, V.parent) + (Base.first_index(V)-1)*sizeof(T)


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