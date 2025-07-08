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
    B<:AbstractArray{S,N},   # array to be wrapped
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

#=
This is broken for now. See: https://github.com/JuliaArrays/BlockArrays.jl/issues/120
# IndexLinear implementations
@propagate_inbounds getindex(a::BlocksView, i::Int) = view(a.array, Block(i))
@propagate_inbounds setindex!(a::BlocksView, b, i::Int) = copyto!(a[i], b)
=#

# IndexCartesian implementations
@propagate_inbounds getindex(a::BlocksView{T,N}, i::Vararg{Int,N}) where {T,N} =
    view(a.array, Block.(i)...)
@propagate_inbounds function setindex!(a::BlocksView{T,N}, b, i::Vararg{Int,N}) where {T,N}
    copyto!(a[i...], b)
    a
end

# AbstractArray version of `Iterators.product`.
# https://en.wikipedia.org/wiki/Cartesian_product
# https://github.com/lazyLibraries/ProductArrays.jl
# https://github.com/JuliaData/SplitApplyCombine.jl#productviewf-a-b
# https://github.com/JuliaArrays/MappedArrays.jl/pull/42
struct ProductArray{T,N,V<:Tuple{Vararg{AbstractVector,N}}} <: AbstractArray{T,N}
    vectors::V
end
ProductArray(vectors::Vararg{AbstractVector,N}) where {N} =
    ProductArray{Tuple{map(eltype, vectors)...},N,typeof(vectors)}(vectors)
Base.size(p::ProductArray) = map(length, p.vectors)
Base.axes(p::ProductArray) = map(Base.axes1, p.vectors)
@propagate_inbounds getindex(p::ProductArray{T,N}, I::Vararg{Int,N}) where {T,N} =
    map((v, i) -> v[i], p.vectors, I)

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
2×3 BlockArrays.ProductArray{Tuple{Int64, Int64}, 2, Tuple{Vector{Int64}, Vector{Int64}}}:
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
blocksizes(A::AbstractArray) = ProductArray(map(blocklengths, axes(A))...)
@inline blocksizes(A::AbstractArray, d::Integer) = blocklengths(axes(A, d))

"""
    blocklengths(A::AbstractArray)

Return an iterator over the lengths of each block.
See also blocksizes.

# Examples
```jldoctest
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockMatrix{Float64}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> blocklengths(A)
2×3 BlockArrays.BlockLengths{Int64, 2, BlockMatrix{Float64, Matrix{Matrix{Float64}}, Tuple{BlockedOneTo{Int64, Vector{Int64}}, BlockedOneTo{Int64, Vector{Int64}}}}}:
 2  2  2
 1  1  1

julia> blocklengths(A)[1,2]
2
```
"""
blocklengths(A::AbstractArray) = BlockLengths(A)
blocklengths(A::AbstractVector) = map(length, blocks(A))

struct BlockLengths{T,N,A<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    array::A
end
BlockLengths(a::AbstractArray{<:Any,N}) where {N} =
    BlockLengths{typeof(length(a)),N,typeof(a)}(a)

size(bs::BlockLengths) = blocksize(bs.array)
axes(bs::BlockLengths) = map(br -> Int.(br), blockaxes(bs.array))
@propagate_inbounds getindex(a::BlockLengths{T,N}, i::Vararg{Int,N}) where {T,N} =
    length(view(a.array, Block.(i)...))

"""
    eachblockaxes(A::AbstractArray)
    eachblockaxes(A::AbstractArray, d::Integer)

Return an iterator over the axes of each block.
See also blocksizes and blocklengths.

# Examples
```jldoctest
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockMatrix{Float64}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> eachblockaxes(A)
2×3 BlockArrays.ProductArray{Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}, 2, Tuple{Vector{Base.OneTo{Int64}}, Vector{Base.OneTo{Int64}}}}:
 (Base.OneTo(2), Base.OneTo(1))  (Base.OneTo(2), Base.OneTo(1))  (Base.OneTo(2), Base.OneTo(1))
 (Base.OneTo(1), Base.OneTo(1))  (Base.OneTo(1), Base.OneTo(1))  (Base.OneTo(1), Base.OneTo(1))

julia> eachblockaxes(A)[1,2]
(Base.OneTo(2), Base.OneTo(1))

julia> eachblockaxes(A,2)
3-element Vector{Base.OneTo{Int64}}:
 Base.OneTo(1)
 Base.OneTo(1)
 Base.OneTo(1)
```
"""
eachblockaxes(A::AbstractArray) =
    ProductArray(map(ax -> map(Base.axes1, blocks(ax)), axes(A))...)
eachblockaxes(A::AbstractArray, d::Integer) = map(Base.axes1, blocks(axes(A, d)))
eachblockaxes1(A::AbstractArray) = map(Base.axes1, blocks(Base.axes1(A)))
