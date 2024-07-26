# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed

####################
# BlockedArray #
####################

"""
    BlockedArray{T, N, R} <: AbstractBlockArray{T, N}

A `BlockedArray` is similar to a [`BlockArray`](@ref) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand `parent` on a `BlockedArray` is instead instant since
it just returns the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `BlockedArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `parent`.

# Examples
```jldoctest
julia> A = zeros(Int, 2, 3);

julia> B = BlockedArray(A, [1,1], [2,1])
2×2-blocked 2×3 BlockedMatrix{Int64}:
 0  0  │  0
 ──────┼───
 0  0  │  0

julia> parent(B) === A
true

julia> B[Block(1,1)] .= 4
1×2 view(::Matrix{Int64}, 1:1, 1:2) with eltype Int64:
 4  4

julia> A
2×3 Matrix{Int64}:
 4  4  0
 0  0  0
```
"""
struct BlockedArray{T, N, R<:AbstractArray{T,N}, BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} <: AbstractBlockArray{T, N}
    blocks::R
    axes::BS
    function BlockedArray{T,N,R,BS}(blocks::R, axes::BS) where {T,N,R,BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}}
        checkbounds(blocks,axes...)
        return new{T,N,R,BS}(blocks, axes)
    end
end

"""
    BlockedMatrix{T}

Alias for `BlockedArray{T, 2}`

```jldoctest
julia> A = reshape([1:6;], 2, 3)
2×3 Matrix{Int64}:
 1  3  5
 2  4  6

julia> BlockedMatrix(A, [1,1], [1,2])
2×2-blocked 2×3 BlockedMatrix{Int64}:
 1  │  3  5
 ───┼──────
 2  │  4  6
```
"""
const BlockedMatrix{T} = BlockedArray{T, 2}
"""
    BlockedVector{T}

Alias for `BlockedArray{T, 1}`

```jldoctest
julia> A = [1:6;]
6-element Vector{Int64}:
 1
 2
 3
 4
 5
 6

julia> BlockedVector(A, [3,2,1])
3-blocked 6-element BlockedVector{Int64}:
 1
 2
 3
 ─
 4
 5
 ─
 6
```
"""
const BlockedVector{T} = BlockedArray{T, 1}
const BlockedVecOrMat{T} = Union{BlockedMatrix{T}, BlockedVector{T}}

# Auxiliary outer constructors
BlockedArray(x::Number, ::Tuple{}) = x  # zero dimensional
@inline BlockedArray(blocks::R, baxes::BS) where {T,N,R<:AbstractArray{T,N},BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} =
    BlockedArray{T, N, R,BS}(blocks, baxes)

@inline BlockedArray{T}(blocks::R, baxes::BS) where {T,N,R<:AbstractArray{T,N},BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} =
    BlockedArray{T, N, R,BS}(blocks, baxes)

@inline BlockedArray{T}(blocks::AbstractArray{<:Any,N}, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where {T,N} =
    BlockedArray{T}(convert(AbstractArray{T,N}, blocks), baxes)

@inline BlockedArray(blocks::BlockedArray, baxes::BS) where {N,BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} =
    BlockedArray(blocks.blocks, baxes)

@inline BlockedArray{T}(blocks::BlockedArray, baxes::BS) where {T,N,BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} =
    BlockedArray{T}(blocks.blocks, baxes)

BlockedArray(blocks::AbstractArray{T, N}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockedArray(blocks, map(blockedrange,block_sizes))

BlockedArray{T}(blocks::AbstractArray{<:Any, N}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockedArray{T}(blocks, map(blockedrange,block_sizes))

@inline BlockedArray{T,N,R,BS}(::UndefInitializer, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where {T,N,R,BS<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}} =
    BlockedArray{T,N,R,BS}(R(undef, length.(baxes)), convert(BS, baxes))

@inline BlockedArray{T}(::UndefInitializer, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where {T, N} =
    BlockedArray(similar(Array{T, N}, length.(baxes)), baxes)

@inline BlockedArray{T, N}(::UndefInitializer, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where {T, N} =
    BlockedArray{T}(undef, baxes)

@inline BlockedArray{T, N, R}(::UndefInitializer, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where {T, N, R <: AbstractArray{T, N}} =
    BlockedArray(similar(R, length.(baxes)), baxes)

@inline BlockedArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockedArray{T}(undef, map(blockedrange,block_sizes))

@inline BlockedArray{T, N}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockedArray{T, N}(undef, map(blockedrange,block_sizes))

@inline BlockedArray{T, N, R}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R <: AbstractArray{T, N}} =
    BlockedArray{T, N, R}(undef, map(blockedrange,block_sizes))


BlockedVector(blocks::AbstractVector, baxes::Tuple{AbstractUnitRange{<:Integer}}) = BlockedArray(blocks, baxes)
BlockedVector(blocks::AbstractVector, block_sizes::AbstractVector{<:Integer}) = BlockedArray(blocks, block_sizes)
BlockedMatrix(blocks::AbstractMatrix, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer}, 2}}) = BlockedArray(blocks, baxes)
BlockedMatrix(blocks::AbstractMatrix, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) = BlockedArray(blocks, block_sizes...)

BlockedArray{T}(λ::UniformScaling, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer}, 2}}) where T = BlockedArray{T}(Matrix(λ, map(length,baxes)...), baxes)
BlockedArray{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) where T = BlockedArray{T}(λ, map(blockedrange,block_sizes))
BlockedArray(λ::UniformScaling{T}, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) where T = BlockedArray{T}(λ, block_sizes...)
BlockedArray(λ::UniformScaling{T}, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer}, 2}}) where T = BlockedArray{T}(λ, baxes)
BlockedMatrix(λ::UniformScaling, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer}, 2}}) = BlockedArray(λ, baxes)
BlockedMatrix(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) = BlockedArray(λ, block_sizes...)
BlockedMatrix{T}(λ::UniformScaling, baxes::Tuple{Vararg{AbstractUnitRange{<:Integer}, 2}}) where T = BlockedArray{T}(λ, baxes)
BlockedMatrix{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) where T = BlockedArray{T}(λ, block_sizes...)


# Convert AbstractArrays that conform to block array interface
convert(::Type{BlockedArray{T,N,R,BS}}, A::BlockedArray{T,N,R,BS}) where {T,N,R,BS} = A
convert(::Type{BlockedArray{T,N,R}}, A::BlockedArray{T,N,R}) where {T,N,R} = A
convert(::Type{BlockedArray{T,N}}, A::BlockedArray{T,N}) where {T,N} = A
convert(::Type{BlockedArray{T}}, A::BlockedArray{T}) where {T} = A
convert(::Type{BlockedArray}, A::BlockedArray) = A

convert(::Type{BlockedArray{T,N,R,BS}}, A::BlockedArray) where {T,N,R,BS} =
    BlockedArray{T,N,R,BS}(convert(R, A.blocks), convert(BS, A.axes))

convert(::Type{AbstractArray{T,N}}, A::BlockedArray{T,N}) where {T,N} = A
convert(::Type{AbstractArray{V,N} where V}, A::BlockedArray{T,N}) where {T,N} = A
convert(::Type{AbstractArray{T}}, A::BlockedArray{T}) where {T} = A
convert(::Type{AbstractArray}, A::BlockedArray) = A



BlockedArray{T, N}(A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockedArray(Array{T, N}(A), axes(A))
BlockedArray{T1}(A::AbstractArray{T2, N}) where {T1,T2,N} = BlockedArray{T1, N}(A)
BlockedArray{<:Any,N}(A::AbstractArray{T, N}) where {T,N} = BlockedArray{T, N}(A)
BlockedArray(A::AbstractArray{T, N}) where {T,N} = BlockedArray{T, N}(A)

convert(::Type{BlockedArray{T, N}}, A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockedArray(convert(Array{T, N}, A), axes(A))
convert(::Type{BlockedArray{T1}}, A::AbstractArray{T2, N}) where {T1,T2,N} =
    convert(BlockedArray{T1, N}, A)
convert(::Type{BlockedArray}, A::AbstractArray{T, N}) where {T,N} =
    convert(BlockedArray{T, N}, A)

AbstractArray{T}(A::BlockedArray) where T = BlockedArray(AbstractArray{T}(A.blocks), A.axes)
AbstractArray{T,N}(A::BlockedArray) where {T,N} = BlockedArray(AbstractArray{T,N}(A.blocks), A.axes)

copy(A::BlockedArray) = BlockedArray(copy(A.blocks), A.axes)

Base.dataids(A::BlockedArray) = Base.dataids(A.blocks)

###########################
# AbstractArray Interface #
###########################

function Base.similar(block_array::BlockedArray{T,N}, ::Type{T2}) where {T,N,T2}
    BlockedArray(similar(block_array.blocks, T2), axes(block_array))
end

to_axes(r::AbstractUnitRange) = r
to_axes(n::Integer) = Base.oneto(n)

@inline Base.similar(block_array::Type{<:StridedArray{T}}, axes::Tuple{AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:StridedArray{T}}, axes::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:StridedArray{T}}, axes::Tuple{Union{Integer,AbstractUnitRange{<:Integer}},AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::StridedArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::StridedArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::StridedArray, ::Type{T}, axes::Tuple{Union{Integer,AbstractUnitRange{<:Integer}},AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::BlockedArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::BlockedArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::BlockedArray, ::Type{T}, axes::Tuple{Union{Integer,AbstractUnitRange{<:Integer}},AbstractBlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{<:Integer}}}}) where T =
    BlockedArray{T}(undef, map(to_axes,axes))

@propagate_inbounds getindex(block_arr::BlockedArray{T, N}, i::Vararg{Integer, N}) where {T,N} = block_arr.blocks[i...]
@propagate_inbounds function setindex!(block_arr::BlockedArray{T, N}, v, i::Vararg{Integer, N}) where {T,N}
    setindex!(block_arr.blocks, v, i...)
    block_arr
end

################################
# AbstractBlockArray Interface #
################################
@inline axes(block_array::BlockedArray) = block_array.axes

############
# Indexing #
############
@inline view(block_arr::BlockedArray{<:Any, 0}) = view(block_arr.blocks)

@inline function viewblock(block_arr::BlockedArray, block)
    range = getindex.(axes(block_arr), Block.(block.n))
    return view(block_arr.blocks, range...)
end

@propagate_inbounds function _blockedindex_getindex(block_arr, blockindex)
    I = getindex.(axes(block_arr), getindex.(Block.(blockindex.I), blockindex.α))
    block_arr.blocks[I...]
end

@propagate_inbounds getindex(block_arr::BlockedArray{T,N}, blockindex::BlockIndex{N}) where {T,N} =
    _blockedindex_getindex(block_arr, blockindex)


@propagate_inbounds getindex(block_arr::BlockedVector{T}, blockindex::BlockIndex{1}) where T =
    _blockedindex_getindex(block_arr, blockindex)

########
# Misc #
########

Base.parent(block_array::BlockedArray) = block_array.blocks

Base.Array(block_array::BlockedArray) = Array(block_array.blocks)

function copyto!(block_array::BlockedArray{T, N, R}, arr::R) where {T,N,R <: AbstractArray}
    copyto!(block_array.blocks, arr)
end

function copyto!(block_array::BlockedArray{T, N, R}, arr::R) where {T,N,R <: LayoutArray}
    copyto!(block_array.blocks, arr)
end

function Base.copy(block_array::BlockedArray{T, N, R}) where {T,N,R <: AbstractArray}
    copy(block_array.blocks)
end

function Base.fill!(block_array::BlockedArray, v)
    fill!(block_array.blocks, v)
    block_array
end

function ArrayLayouts.lmul!(α::Number, block_array::BlockedArray)
    lmul!(α, block_array.blocks)
    block_array
end

function ArrayLayouts.rmul!(block_array::BlockedArray, α::Number)
    rmul!(block_array.blocks, α)
    block_array
end

_blocked_reshape(block_array, axes) = BlockedArray(reshape(block_array.blocks,map(length,axes)),axes)
Base.reshape(block_array::BlockedArray, axes::Tuple{Vararg{AbstractUnitRange{<:Integer},N}}) where N =
    _blocked_reshape(block_array, axes)
Base.reshape(parent::BlockedArray, shp::Tuple{Union{Int,Base.OneTo}, Vararg{Union{Int,Base.OneTo}}}) =
    reshape(parent, Base.to_shape(shp))
Base.reshape(parent::BlockedArray, dims::Tuple{Int,Vararg{Int}}) =
    Base._reshape(parent, dims)

"""
    resize!(a::BlockedVector, N::Block) -> BlockedVector

Resize `a` to contain the first `N` blocks, returning a new `BlockedVector` sharing
memory with `a`. If `N` is smaller than the current
collection block length, the first `N` blocks will be retained. `N` is not allowed to be larger.
"""
function resize!(a::BlockedVector, N::Block{1})
    ax = axes(a,1)
    if iszero(Int(N))
        BlockedVector(resize!(a.blocks, 0), (ax[Block.(Base.OneTo(0))],))
    else
        BlockedVector(resize!(a.blocks, last(ax[N])), (ax[Block.(Base.OneTo(Int(N)))],))
    end
end



###########################
# Strided Array interface #
###########################

Base.strides(A::BlockedArray) = strides(A.blocks)
Base.stride(A::BlockedArray, i::Integer) = stride(A.blocks, i)
Base.unsafe_convert(::Type{Ptr{T}}, A::BlockedArray) where T = Base.unsafe_convert(Ptr{T}, A.blocks)
Base.elsize(::Type{<:BlockedArray{T,N,R}}) where {T,N,R} = Base.elsize(R)

###
# col/rowsupport
###

colsupport(A::BlockedArray, j) = colsupport(A.blocks, j)
rowsupport(A::BlockedArray, j) = rowsupport(A.blocks, j)

###
# zeros/ones
###

for op in (:zeros, :ones)
    @eval $op(::Type{T}, axs::Tuple{BlockedOneTo,Vararg{Union{Integer,AbstractUnitRange}}}) where T = BlockedArray($op(T, map(length,axs)...), axs)
end

Base.replace_in_print_matrix(f::BlockedVecOrMat, i::Integer, j::Integer, s::AbstractString) =
    Base.replace_in_print_matrix(f.blocks, i, j, s)


LinearAlgebra.norm(A::BlockedArray, p::Real=2) = norm(A.blocks, p)

###########################
# FillArrays interface #
###########################

FillArrays.getindex_value(P::BlockedArray) = FillArrays.getindex_value(P.blocks)
