"""
    blocks(a::AbstractArray{T,N}) :: AbstractArray{<:AbstractArray{T,N},N}

Return the array-of-arrays view to `a` such that

```
blocks(a)[i₁, i₂, ..., iₙ] == a[Block(i₁), Block(i₂), ..., Block(iₙ)]
```

This function does not copy the blocks and give a mutable viwe to the original
array.  This is an "inverse" of [`mortar`](@ref).

# Examples
```jldoctest; setup = quote using BlockArrays end
julia> bs1 = permutedims(reshape([
               1ones(1, 3), 2ones(1, 2),
               3ones(2, 3), 4ones(2, 2),
           ], (2, 2)))
2×2 Array{Array{Float64,2},2}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> a = mortar(bs1)
2×2-blocked 3×5 BlockArray{Float64,2}:
 1.0  1.0  1.0  │  2.0  2.0
 ───────────────┼──────────
 3.0  3.0  3.0  │  4.0  4.0
 3.0  3.0  3.0  │  4.0  4.0

julia> bs2 = blocks(a)
2×2 Array{Array{Float64,2},2}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> bs1 == bs2
true

julia> bs2[1, 1] .*= 100;

julia> a  # in-place mutation is reflected to the block array
2×2-blocked 3×5 BlockArray{Float64,2}:
 100.0  100.0  100.0  │  2.0  2.0
 ─────────────────────┼──────────
   3.0    3.0    3.0  │  4.0  4.0
   3.0    3.0    3.0  │  4.0  4.0
```
"""
blocks(a::AbstractArray) = blocks(PseudoBlockArray(a, axes(a)))
blocks(a::AbstractBlockArray) = BlocksView(a)
blocks(a::BlockArray) = a.blocks

struct BlocksView{
    S,                            # eltype(eltype(BlocksView(...)))
    N,                            # ndims
    T<:AbstractArray{S,N},        # eltype(BlocksView(...)), i.e., block type
    B<:AbstractBlockArray{S,N},   # array to be wrapped
} <: AbstractArray{T,N}
    array::B
end

BlocksView(a::AbstractBlockArray{S,N}) where {S,N} =
    BlocksView{S,N,AbstractArray{eltype(a),N},typeof(a)}(a)
# Note: deciding concrete eltype of `BlocksView` requires some extra
# interface for `AbstractBlockArray`.

Base.IteratorEltype(::Type{<:BlocksView}) = Base.EltypeUnknown()

Base.size(a::BlocksView) = blocksize(a.array)
Base.axes(a::BlocksView) = map(br -> only(br.indices), blockaxes(a.array))

@propagate_inbounds _view(a::PseudoBlockArray, i::Block) = a[i]
@propagate_inbounds _view(a::AbstractBlockArray, i::Block) = view(a, i)

# IndexLinear implementations
@propagate_inbounds Base.getindex(a::BlocksView, i::Int) = _view(a.array, Block(i))
@propagate_inbounds Base.setindex!(a::BlocksView, b, i::Int) = copyto!(a[i], b)

# IndexCartesian implementations
@propagate_inbounds Base.getindex(a::BlocksView{T,N}, i::Vararg{Int,N}) where {T,N} =
    _view(a.array, Block(i...))
@propagate_inbounds Base.setindex!(a::BlocksView{T,N}, b, i::Vararg{Int,N}) where {T,N} =
    copyto!(a[i...])

function Base.showarg(io::IO, a::BlocksView, toplevel::Bool)
    if toplevel
        print(io, "blocks of ")
        Base.showarg(io, a.array, true)
    else
        print(io, "::BlocksView{…,")
        Base.showarg(io, a.array, false)
        print(io, '}')
    end
end
