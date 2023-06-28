# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed

####################
# PseudoBlockArray #
####################

"""
    PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N}

A `PseudoBlockArray` is similar to a [`BlockArray`](@ref) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand `Array` on a `PseudoBlockArray` is instead instant since
it just returns the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `PseudoBlockArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `Array`.

# Examples
```jldoctest
julia> PseudoBlockArray(reshape([1:6;], 2, 3), [1,1], [2,1])
2×2-blocked 2×3 PseudoBlockMatrix{Int64}:
 1  3  │  5
 ──────┼───
 2  4  │  6

julia> PseudoBlockArray([1:6;], [3,2,1])
3-blocked 6-element PseudoBlockVector{Int64}:
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
struct PseudoBlockArray{T, N, R<:AbstractArray{T,N}, BS<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractBlockArray{T, N}
    blocks::R
    axes::BS
    function PseudoBlockArray{T,N,R,BS}(blocks::R, axes::BS) where {T,N,R,BS<:NTuple{N,AbstractUnitRange{Int}}}
        checkbounds(blocks,axes...)
        return new{T,N,R,BS}(blocks, axes)
    end
end

const PseudoBlockMatrix{T} = PseudoBlockArray{T, 2}
const PseudoBlockVector{T} = PseudoBlockArray{T, 1}
const PseudoBlockVecOrMat{T} = Union{PseudoBlockMatrix{T}, PseudoBlockVector{T}}

# Auxiliary outer constructors
@inline PseudoBlockArray(blocks::R, baxes::BS) where {T,N,R<:AbstractArray{T,N},BS<:NTuple{N,AbstractUnitRange{Int}}} =
    PseudoBlockArray{T, N, R,BS}(blocks, baxes)

@inline PseudoBlockArray{T}(blocks::R, baxes::BS) where {T,N,R<:AbstractArray{T,N},BS<:NTuple{N,AbstractUnitRange{Int}}} =
    PseudoBlockArray{T, N, R,BS}(blocks, baxes)

@inline PseudoBlockArray{T}(blocks::AbstractArray{<:Any,N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N} =
    PseudoBlockArray{T}(convert(AbstractArray{T,N}, blocks), baxes)

@inline PseudoBlockArray(blocks::PseudoBlockArray, baxes::BS) where {N,BS<:NTuple{N,AbstractUnitRange{Int}}} =
    PseudoBlockArray(blocks.blocks, baxes)

@inline PseudoBlockArray{T}(blocks::PseudoBlockArray, baxes::BS) where {T,N,BS<:NTuple{N,AbstractUnitRange{Int}}} =
    PseudoBlockArray{T}(blocks.blocks, baxes)

PseudoBlockArray(blocks::AbstractArray{T, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray(blocks, map(blockedrange,block_sizes))

PseudoBlockArray{T}(blocks::AbstractArray{<:Any, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray{T}(blocks, map(blockedrange,block_sizes))

@inline PseudoBlockArray{T,N,R,BS}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N,R,BS<:NTuple{N,AbstractUnitRange{Int}}} =
    PseudoBlockArray{T,N,R,BS}(R(undef, length.(baxes)), convert(BS, baxes))

@inline PseudoBlockArray{T}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N} =
    PseudoBlockArray(similar(Array{T, N}, length.(baxes)), baxes)

@inline PseudoBlockArray{T, N}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N} =
    PseudoBlockArray{T}(undef, baxes)

@inline PseudoBlockArray{T, N, R}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N, R <: AbstractArray{T, N}} =
    PseudoBlockArray(similar(R, length.(baxes)), baxes)

@inline PseudoBlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray{T}(undef, map(blockedrange,block_sizes))

@inline PseudoBlockArray{T, N}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray{T, N}(undef, map(blockedrange,block_sizes))

@inline PseudoBlockArray{T, N, R}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R <: AbstractArray{T, N}} =
    PseudoBlockArray{T, N, R}(undef, map(blockedrange,block_sizes))


PseudoBlockVector(blocks::AbstractVector, baxes::Tuple{AbstractUnitRange{Int}}) = PseudoBlockArray(blocks, baxes)
PseudoBlockVector(blocks::AbstractVector, block_sizes::AbstractVector{Int}) = PseudoBlockArray(blocks, block_sizes)
PseudoBlockMatrix(blocks::AbstractMatrix, baxes::NTuple{2,AbstractUnitRange{Int}}) = PseudoBlockArray(blocks, baxes)
PseudoBlockMatrix(blocks::AbstractMatrix, block_sizes::Vararg{AbstractVector{Int},2}) = PseudoBlockArray(blocks, block_sizes...)

PseudoBlockArray{T}(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = PseudoBlockArray{T}(Matrix(λ, map(length,baxes)...), baxes)
PseudoBlockArray{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{Int}, 2}) where T = PseudoBlockArray{T}(λ, map(blockedrange,block_sizes))
PseudoBlockArray(λ::UniformScaling{T}, block_sizes::Vararg{AbstractVector{Int}, 2}) where T = PseudoBlockArray{T}(λ, block_sizes...)
PseudoBlockArray(λ::UniformScaling{T}, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = PseudoBlockArray{T}(λ, baxes)
PseudoBlockMatrix(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) = PseudoBlockArray(λ, baxes)
PseudoBlockMatrix(λ::UniformScaling, block_sizes::Vararg{AbstractVector{Int},2}) = PseudoBlockArray(λ, block_sizes...)
PseudoBlockMatrix{T}(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = PseudoBlockArray{T}(λ, baxes)
PseudoBlockMatrix{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{Int},2}) where T = PseudoBlockArray{T}(λ, block_sizes...)


# Convert AbstractArrays that conform to block array interface
convert(::Type{PseudoBlockArray{T,N,R,BS}}, A::PseudoBlockArray{T,N,R,BS}) where {T,N,R,BS} = A
convert(::Type{PseudoBlockArray{T,N,R}}, A::PseudoBlockArray{T,N,R}) where {T,N,R} = A
convert(::Type{PseudoBlockArray{T,N}}, A::PseudoBlockArray{T,N}) where {T,N} = A
convert(::Type{PseudoBlockArray{T}}, A::PseudoBlockArray{T}) where {T} = A
convert(::Type{PseudoBlockArray}, A::PseudoBlockArray) = A

convert(::Type{PseudoBlockArray{T,N,R,BS}}, A::PseudoBlockArray) where {T,N,R,BS} =
    PseudoBlockArray{T,N,R,BS}(convert(R, A.blocks), convert(BS, A.axes))

convert(::Type{AbstractArray{T,N}}, A::PseudoBlockArray{T,N}) where {T,N} = A
convert(::Type{AbstractArray{V,N} where V}, A::PseudoBlockArray{T,N}) where {T,N} = A
convert(::Type{AbstractArray{T}}, A::PseudoBlockArray{T}) where {T} = A
convert(::Type{AbstractArray}, A::PseudoBlockArray) = A



PseudoBlockArray{T, N}(A::AbstractArray{T2, N}) where {T,T2,N} =
    PseudoBlockArray(Array{T, N}(A), axes(A))
PseudoBlockArray{T1}(A::AbstractArray{T2, N}) where {T1,T2,N} = PseudoBlockArray{T1, N}(A)
PseudoBlockArray{<:Any,N}(A::AbstractArray{T, N}) where {T,N} = PseudoBlockArray{T, N}(A)
PseudoBlockArray(A::AbstractArray{T, N}) where {T,N} = PseudoBlockArray{T, N}(A)

convert(::Type{PseudoBlockArray{T, N}}, A::AbstractArray{T2, N}) where {T,T2,N} =
    PseudoBlockArray(convert(Array{T, N}, A), axes(A))
convert(::Type{PseudoBlockArray{T1}}, A::AbstractArray{T2, N}) where {T1,T2,N} =
    convert(PseudoBlockArray{T1, N}, A)
convert(::Type{PseudoBlockArray}, A::AbstractArray{T, N}) where {T,N} =
    convert(PseudoBlockArray{T, N}, A)

AbstractArray{T}(A::PseudoBlockArray) where T = PseudoBlockArray(AbstractArray{T}(A.blocks), A.axes)
AbstractArray{T,N}(A::PseudoBlockArray) where {T,N} = PseudoBlockArray(AbstractArray{T,N}(A.blocks), A.axes)

copy(A::PseudoBlockArray) = PseudoBlockArray(copy(A.blocks), A.axes)

###########################
# AbstractArray Interface #
###########################

function Base.similar(block_array::PseudoBlockArray{T,N}, ::Type{T2}) where {T,N,T2}
    PseudoBlockArray(similar(block_array.blocks, T2), axes(block_array))
end

to_axes(r::AbstractUnitRange) = r
to_axes(n::Integer) = Base.oneto(n)

@inline Base.similar(block_array::Type{<:Array{T}}, axes::Tuple{BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:Array{T}}, axes::Tuple{BlockedUnitRange,BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:Array{T}}, axes::Tuple{Union{Integer,AbstractUnitRange{Int}},BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::Array, ::Type{T}, axes::Tuple{BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Array, ::Type{T}, axes::Tuple{BlockedUnitRange,BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Array, ::Type{T}, axes::Tuple{Union{Integer,AbstractUnitRange{Int}},BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::PseudoBlockArray, ::Type{T}, axes::Tuple{BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::PseudoBlockArray, ::Type{T}, axes::Tuple{BlockedUnitRange,BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::PseudoBlockArray, ::Type{T}, axes::Tuple{Union{Integer,AbstractUnitRange{Int}},BlockedUnitRange,Vararg{Union{Integer,AbstractUnitRange{Int}}}}) where T =
    PseudoBlockArray{T}(undef, map(to_axes,axes))

@inline @propagate_inbounds getindex(block_arr::PseudoBlockArray{T, N}, i::Vararg{Integer, N}) where {T,N} = block_arr.blocks[i...]
@inline @propagate_inbounds Base.setindex!(block_arr::PseudoBlockArray{T, N}, v, i::Vararg{Integer, N}) where {T,N} = setindex!(block_arr.blocks, v, i...)

################################
# AbstractBlockArray Interface #
################################
@inline axes(block_array::PseudoBlockArray) = block_array.axes

############
# Indexing #
############

@inline function viewblock(block_arr::PseudoBlockArray, block)
    range = getindex.(axes(block_arr), Block.(block.n))
    return view(block_arr.blocks, range...)
end

@inline @propagate_inbounds function _pseudoblockindex_getindex(block_arr, blockindex)
    I = getindex.(axes(block_arr), getindex.(Block.(blockindex.I), blockindex.α))
    block_arr.blocks[I...]
end

@inline getindex(block_arr::PseudoBlockArray{T,N}, blockindex::BlockIndex{N}) where {T,N} =
    _pseudoblockindex_getindex(block_arr, blockindex)


@inline getindex(block_arr::PseudoBlockVector{T}, blockindex::BlockIndex{1}) where T =
    _pseudoblockindex_getindex(block_arr, blockindex)

########
# Misc #
########

Base.Array(block_array::PseudoBlockArray) = Array(block_array.blocks)

function copyto!(block_array::PseudoBlockArray{T, N, R}, arr::R) where {T,N,R <: AbstractArray}
    copyto!(block_array.blocks, arr)
end

function copyto!(block_array::PseudoBlockArray{T, N, R}, arr::R) where {T,N,R <: LayoutArray}
    copyto!(block_array.blocks, arr)
end

function Base.copy(block_array::PseudoBlockArray{T, N, R}) where {T,N,R <: AbstractArray}
    copy(block_array.blocks)
end

function Base.fill!(block_array::PseudoBlockArray, v)
    fill!(block_array.blocks, v)
    block_array
end

function ArrayLayouts.lmul!(α::Number, block_array::PseudoBlockArray)
    lmul!(α, block_array.blocks)
    block_array
end

function ArrayLayouts.rmul!(block_array::PseudoBlockArray, α::Number)
    rmul!(block_array.blocks, α)
    block_array
end

_pseudo_reshape(block_array, axes) = PseudoBlockArray(reshape(block_array.blocks,map(length,axes)),axes)
Base.reshape(block_array::PseudoBlockArray, axes::NTuple{N,AbstractUnitRange{Int}}) where N =
    _pseudo_reshape(block_array, axes)
Base.reshape(parent::PseudoBlockArray, shp::Tuple{Union{Integer,Base.OneTo}, Vararg{Union{Integer,Base.OneTo}}}) =
    reshape(parent, Base.to_shape(shp))
Base.reshape(parent::PseudoBlockArray, dims::Tuple{Int,Vararg{Int}}) =
    Base._reshape(parent, dims)

function Base.showarg(io::IO, A::PseudoBlockArray, toplevel::Bool)
    if toplevel
        print(io, "PseudoBlockArray of ")
        Base.showarg(io, A.blocks, true)
    else
        print(io, "::PseudoBlockArray{…,")
        Base.showarg(io, A.blocks, false)
        print(io, '}')
    end
end
"""
resize!(a::PseudoBlockVector, N::Block) -> PseudoBlockVector

Resize `a` to contain the first `N` blocks, returning a new `PseudoBlockVector` sharing
memory with `a`. If `N` is smaller than the current
collection block length, the first `N` blocks will be retained. `N` is not allowed to be larger.
"""
function resize!(a::PseudoBlockVector, N::Block{1})
    ax = axes(a,1)
    if iszero(Int(N))
        PseudoBlockVector(resize!(a.blocks, 0), (ax[Block.(Base.OneTo(0))],))
    else
        PseudoBlockVector(resize!(a.blocks, last(ax[N])), (ax[Block.(Base.OneTo(Int(N)))],))
    end
end



###########################
# Strided Array interface #
###########################

Base.strides(A::PseudoBlockArray) = strides(A.blocks)
Base.stride(A::PseudoBlockArray, i::Integer) = stride(A.blocks, i)
Base.unsafe_convert(::Type{Ptr{T}}, A::PseudoBlockArray) where T = Base.unsafe_convert(Ptr{T}, A.blocks)
Base.elsize(::Type{<:PseudoBlockArray{T,N,R}}) where {T,N,R} = Base.elsize(R)

###
# col/rowsupport
###

colsupport(A::PseudoBlockArray, j) = colsupport(A.blocks, j)
rowsupport(A::PseudoBlockArray, j) = rowsupport(A.blocks, j)

###
# zeros/ones
###

for op in (:zeros, :ones)
    @eval $op(::Type{T}, axs::Tuple{BlockedUnitRange,Vararg{Any}}) where T = PseudoBlockArray($op(T, map(length,axs)...), axs)
end

Base.replace_in_print_matrix(f::PseudoBlockVecOrMat, i::Integer, j::Integer, s::AbstractString) =
    Base.replace_in_print_matrix(f.blocks, i, j, s)


LinearAlgebra.norm(A::PseudoBlockArray, p::Real=2) = norm(A.blocks, p)
