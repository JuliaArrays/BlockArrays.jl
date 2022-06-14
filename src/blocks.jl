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
Base.axes(a::BlocksView) = map(br -> only(br.indices), blockaxes(a.array))

#=
This is broken for now. See: https://github.com/JuliaArrays/BlockArrays.jl/issues/120
# IndexLinear implementations
@propagate_inbounds Base.getindex(a::BlocksView, i::Int) = view(a.array, Block(i))
@propagate_inbounds Base.setindex!(a::BlocksView, b, i::Int) = copyto!(a[i], b)
=#

# IndexCartesian implementations
@propagate_inbounds Base.getindex(a::BlocksView{T,N}, i::Vararg{Int,N}) where {T,N} =
    view(a.array, Block.(i)...)
@propagate_inbounds Base.setindex!(a::BlocksView{T,N}, b, i::Vararg{Int,N}) where {T,N} =
    copyto!(a[i...], b)

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
