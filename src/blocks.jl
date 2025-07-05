"""
    blocks(a::AbstractArray{T,N}) :: AbstractArray{<:AbstractArray{T,N},N}

Return the array-of-arrays view to `a` such that

```
blocks(a)[i₁, i₂, ..., iₙ] == a[Block(i₁), Block(i₂), ..., Block(iₙ)]
```

This function does not copy the blocks and give a mutable view to the original
array.  This is an "inverse" of [`mortar`](@ref).

# Examples
```jldoctest
julia> bs1 = permutedims(reshape([
               1ones(1, 3), 2ones(1, 2),
               3ones(2, 3), 4ones(2, 2),
           ], (2, 2)))
2×2 Matrix{Matrix{Float64}}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> a = mortar(bs1)
2×2-blocked 3×5 BlockMatrix{Float64}:
 1.0  1.0  1.0  │  2.0  2.0
 ───────────────┼──────────
 3.0  3.0  3.0  │  4.0  4.0
 3.0  3.0  3.0  │  4.0  4.0

julia> bs2 = blocks(a)
2×2 Matrix{Matrix{Float64}}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> bs1 == bs2
true

julia> bs2[1, 1] .*= 100;

julia> a  # in-place mutation is reflected to the block array
2×2-blocked 3×5 BlockMatrix{Float64}:
 100.0  100.0  100.0  │  2.0  2.0
 ─────────────────────┼──────────
   3.0    3.0    3.0  │  4.0  4.0
   3.0    3.0    3.0  │  4.0  4.0
```
"""
blocks(a::AbstractArray) = BlocksView(a)
blocks(a::BlockArray) = a.blocks
blocks(A::Adjoint) = adjoint(blocks(parent(A)))
blocks(A::Transpose) = transpose(blocks(parent(A)))
blocks(A::StridedArray) = BlockView(A)

# convert a tuple of BlockRange to a tuple of `AbstractUnitRange{Int}`
_block2int(B::Block{1}) = Int(B):Int(B)
_block2int(B::BlockRange{1}) = Int.(B)
_blockrange2int() = ()
_blockrange2int(A, B...) = tuple(_block2int(A.block), _blockrange2int(B...)...)

blocks(A::SubArray{<:Any,N,<:Any,<:NTuple{N,BlockSlice}}) where N =
    view(blocks(parent(A)), _blockrange2int(parentindices(A)...)...)

struct BlocksView{
    S,                            # eltype(eltype(BlocksView(...)))
    N,                            # ndims
    T<:AbstractArray{S,N},        # eltype(BlocksView(...)), i.e., block type
    B<:AbstractArray{S,N},        # array to be wrapped
} <: AbstractArray{T,N}
    array::B
end

BlocksView(a::AbstractArray{S,N}) where {S,N} =
    BlocksView{S,N,AbstractArray{eltype(a),N},typeof(a)}(a)
# Note: deciding concrete eltype of `BlocksView` requires some extra
# interface for `AbstractBlockArray`.

Base.IteratorEltype(::Type{<:BlocksView}) = Base.EltypeUnknown()

Base.size(a::BlocksView) = blocksize(a.array)
Base.axes(a::BlocksView) = map(br -> Int.(br), blockaxes(a.array))

# IndexCartesian implementations
@propagate_inbounds getindex(a::BlocksView{T,N}, i::Vararg{Int,N}) where {T,N} =
    view(a.array, Block.(i)...)
@propagate_inbounds function setindex!(a::BlocksView{T,N}, b, i::Vararg{Int,N}) where {T,N}
    copyto!(a[i...], b)
    a
end

# Like `BlocksView` but specialized for a single block
# in order to avoid unnecessary wrappers when accessing the block.
# Note that it does not check the array being wrapped actually
# only has a single block, and will interpret it as if it just has one block.
# By default, this is what gets constructed when calling `blocks(::StridedArray)`.
struct BlockView{
    S,                            # eltype(eltype(BlockView(...)))
    N,                            # ndims
    T<:AbstractArray{S,N},        # array to be wrapped
} <: AbstractArray{T,N}
    array::T
end

Base.size(a::BlockView) = map(one, size(a.array))

# IndexCartesian implementations
@propagate_inbounds function getindex(a::BlockView{T,N}, i::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(a, i...)
    a.array
end
@propagate_inbounds function setindex!(a::BlockView{T,N}, b, i::Vararg{Int,N}) where {T,N}
    copyto!(a[i...], b)
    a
end

"""
    blocksizes(A::AbstractArray)
    blocksizes(A::AbstractArray, d::Integer)

Return an iterator over the sizes of each block.
See also size and blocksize.

# Examples
```jldoctest
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockMatrix{Float64}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> blocksizes(A)
2×3 BlockArrays.BlockSizes{Tuple{Int64, Int64}, 2, BlockMatrix{Float64, Matrix{Matrix{Float64}}, Tuple{BlockedOneTo{Int64, Vector{Int64}}, BlockedOneTo{Int64, Vector{Int64}}}}}:
 (2, 1)  (2, 1)  (2, 1)
 (1, 1)  (1, 1)  (1, 1)

julia> blocksizes(A)[1,2]
(2, 1)

julia> blocksizes(A,2)
3-element Vector{Int64}:
 1
 1
 1
```
"""
blocksizes(A::AbstractArray) = BlockSizes(A)
@inline blocksizes(A::AbstractArray, d::Integer) = blocklengths(axes(A, d))

struct BlockSizes{T,N,A<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    array::A
end
BlockSizes(a::AbstractArray{<:Any,N}) where {N} =
    BlockSizes{Tuple{eltype.(axes(a))...},N,typeof(a)}(a)

size(bs::BlockSizes) = blocksize(bs.array)
axes(bs::BlockSizes) = map(br -> Int.(br), blockaxes(bs.array))
@propagate_inbounds getindex(a::BlockSizes{T,N}, i::Vararg{Int,N}) where {T,N} =
    size(view(a.array, Block.(i)...))
