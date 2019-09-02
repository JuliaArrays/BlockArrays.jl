# Note: Functions surrounded by a comment blocks are there because `Vararg` is sitll allocating.
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

```jldoctest
julia> using BlockArrays, Random, SparseArrays

julia> Random.seed!(12345);

julia> A = PseudoBlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 PseudoBlockArray{Float64,2}:
 0.562714  0.371605  │  0.381128
 ────────────────────┼──────────
 0.849939  0.283365  │  0.365801

julia> A = PseudoBlockArray(sprand(6, 0.5), [3,2,1])
3-blocked 6-element PseudoBlockArray{Float64,1,SparseVector{Float64,Int64},BlockArrays.BlockSizes{1,Tuple{Array{Int64,1}}}}:
 0.0                
 0.5865981007905481
 0.0                
 ───────────────────
 0.05016684053503706
 0.0
 ───────────────────
 0.0
```
"""
struct PseudoBlockArray{T, N, R<:AbstractArray{T,N}, BS<:AbstractBlockSizes{N}} <: AbstractBlockArray{T, N}
    blocks::R
    block_sizes::BS
    PseudoBlockArray{T,N,R,BS}(blocks::R, block_sizes::BS) where {T,N,R,BS<:AbstractBlockSizes{N}} =
        new{T,N,R,BS}(blocks, block_sizes)
end

const PseudoBlockMatrix{T} = PseudoBlockArray{T, 2}
const PseudoBlockVector{T} = PseudoBlockArray{T, 1}
const PseudoBlockVecOrMat{T} = Union{PseudoBlockMatrix{T}, PseudoBlockVector{T}}

# Auxiliary outer constructors
@inline PseudoBlockArray(blocks::R, block_sizes::BS) where {T,N,R<:AbstractArray{T,N},BS<:AbstractBlockSizes{N}} =
    PseudoBlockArray{T, N, R,BS}(blocks, block_sizes)

@inline PseudoBlockArray(blocks::AbstractArray{T, N}, block_sizes::Vararg{Vector{Int}, N}) where {T, N} =
    PseudoBlockArray(blocks, BlockSizes(block_sizes...))

PseudoBlockArray(blocks::AbstractArray{T, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray(blocks, Vector{Int}.(block_sizes)...)

@inline PseudoBlockArray{T}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N} =
    PseudoBlockArray(similar(Array{T, N}, size(block_sizes)), block_sizes)

@inline PseudoBlockArray{T, N}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N} =
    PseudoBlockArray{T}(undef, block_sizes)

@inline PseudoBlockArray{T, N, R}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N, R <: AbstractArray{T, N}} =
    PseudoBlockArray(similar(R, size(block_sizes)), block_sizes)

@inline PseudoBlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray{T}(undef, BlockSizes(block_sizes...))

@inline PseudoBlockArray{T, N}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    PseudoBlockArray{T, N}(undef, BlockSizes(block_sizes...))

@inline PseudoBlockArray{T, N, R}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R <: AbstractArray{T, N}} =
    PseudoBlockArray{T, N, R}(undef, BlockSizes(block_sizes...))


PseudoBlockVector(blocks::AbstractVector, block_sizes::AbstractBlockSizes{1}) = PseudoBlockArray(blocks, block_sizes)
PseudoBlockVector(blocks::AbstractVector, block_sizes::AbstractVector{Int}) = PseudoBlockArray(blocks, block_sizes)
PseudoBlockMatrix(blocks::AbstractMatrix, block_sizes::AbstractBlockSizes{2}) = PseudoBlockArray(blocks, block_sizes)
PseudoBlockMatrix(blocks::AbstractMatrix, block_sizes::Vararg{AbstractVector{Int},2}) = PseudoBlockArray(blocks, block_sizes...)

# Convert AbstractArrays that conform to block array interface
convert(::Type{PseudoBlockArray{T,N,R,BS}}, A::PseudoBlockArray{T,N,R,BS}) where {T,N,R,BS} = A
convert(::Type{PseudoBlockArray{T,N,R}}, A::PseudoBlockArray{T,N,R}) where {T,N,R} = A
convert(::Type{PseudoBlockArray{T,N}}, A::PseudoBlockArray{T,N}) where {T,N} = A
convert(::Type{PseudoBlockArray{T}}, A::PseudoBlockArray{T}) where {T} = A
convert(::Type{PseudoBlockArray}, A::PseudoBlockArray) = A

PseudoBlockArray{T, N}(A::AbstractArray{T2, N}) where {T,T2,N} =
    PseudoBlockArray(Array{T, N}(A), blocksizes(A))
PseudoBlockArray{T1}(A::AbstractArray{T2, N}) where {T1,T2,N} = PseudoBlockArray{T1, N}(A)
PseudoBlockArray(A::AbstractArray{T, N}) where {T,N} = PseudoBlockArray{T, N}(A)

convert(::Type{PseudoBlockArray{T, N}}, A::AbstractArray{T2, N}) where {T,T2,N} =
    PseudoBlockArray(convert(Array{T, N}, A), blocksizes(A))
convert(::Type{PseudoBlockArray{T1}}, A::AbstractArray{T2, N}) where {T1,T2,N} =
    convert(PseudoBlockArray{T1, N}, A)
convert(::Type{PseudoBlockArray}, A::AbstractArray{T, N}) where {T,N} =
    convert(PseudoBlockArray{T, N}, A)

copy(A::PseudoBlockArray) = PseudoBlockArray(copy(A.blocks), copy(A.block_sizes))

###########################
# AbstractArray Interface #
###########################

function Base.similar(block_array::PseudoBlockArray{T,N}, ::Type{T2}) where {T,N,T2}
    PseudoBlockArray(similar(block_array.blocks, T2), copy(blocksizes(block_array)))
end

@inline function Base.getindex(block_arr::PseudoBlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr.blocks[i...]
    return v
end


@inline function Base.setindex!(block_arr::PseudoBlockArray{T, N}, v, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr.blocks[i...] = v
    return block_arr
end

################################
# AbstractBlockArray Interface #
################################
@inline blocksizes(block_array::PseudoBlockArray) = block_array.block_sizes

############
# Indexing #
############

@inline function Base.getindex(block_arr::PseudoBlockArray{T,N}, blockindex::BlockIndex{N}) where {T,N}
    I = blockindex2global(blocksizes(block_arr), blockindex)
    @boundscheck checkbounds(block_arr.blocks, I...)
    @inbounds v = block_arr.blocks[I...]
    return v
end

@inline function getblock(block_arr::PseudoBlockArray{T,N}, block::Vararg{Integer, N}) where {T,N}
    range = globalrange(blocksizes(block_arr), block)
    return block_arr.blocks[range...]
end

@inline function _check_getblock!(blockrange, x, block_arr::PseudoBlockArray{T,N}, block::NTuple{N, Integer}) where {T,N}
    for i in 1:N
        if size(x, i) != length(blockrange[i])
            throw(DimensionMismatch(string("tried to assign ", blocksize(block_arr, block), " block to $(size(x)) array")))
        end
    end
end


@generated function getblock!(x, block_arr::PseudoBlockArray{T,N}, block::Vararg{Integer, N}) where {T,N}
    return quote
        blockrange = globalrange(blocksizes(block_arr), block)
        @boundscheck _check_getblock!(blockrange, x, block_arr, block)

        arr = block_arr.blocks
        @nexprs $N d -> k_d = 1
        @inbounds begin
            @nloops $N i (d->(blockrange[d])) (d-> k_{d-1}=1) (d-> k_d+=1) begin
                (@nref $N x k) = (@nref $N arr i)
            end
        end
        return x
    end
end

@inline function Base.setindex!(block_arr::PseudoBlockArray{T,N}, v, blockindex::BlockIndex{N}) where {T,N}
    I = blockindex2global(blocksizes(block_arr), blockindex)
    @boundscheck checkbounds(block_arr.blocks, I...)
    @inbounds block_arr.blocks[I...] = v
    return block_arr
end

@inline function _check_setblock!(blockrange, x, block_arr::PseudoBlockArray{T,N}, block::NTuple{N, Integer}) where {T,N}
    blocksizes = blocksize(block_arr, block)
    for i in 1:N
        if size(x, i) != blocksizes[i]
            throw(DimensionMismatch(string("tried to assign $(size(x)) array to ", blocksizes, " block")))
        end
    end
end

@generated function setblock!(block_arr::PseudoBlockArray{T, N}, x, block::Vararg{Integer, N}) where {T,N}
    return quote
        blockrange = globalrange(blocksizes(block_arr), block)
        @boundscheck _check_setblock!(blockrange, x, block_arr, block)
        arr = block_arr.blocks
        @nexprs $N d -> k_d = 1
        @inbounds begin
            @nloops $N i (d->(blockrange[d])) (d-> k_{d-1}=1) (d-> k_d+=1) begin
                (@nref $N arr i) = (@nref $N x k)
            end
        end
    end
end


########
# Misc #
########

function Base.Array(block_array::PseudoBlockArray)
    return block_array.blocks
end

function copyto!(block_array::PseudoBlockArray{T, N, R}, arr::R) where {T,N,R <: AbstractArray}
    copyto!(block_array.blocks, arr)
end

function Base.copy(block_array::PseudoBlockArray{T, N, R}) where {T,N,R <: AbstractArray}
    copy(block_array.blocks)
end

function Base.fill!(block_array::PseudoBlockArray, v)
    fill!(block_array.blocks, v)
    block_array
end

function lmul!(α::Number, block_array::PseudoBlockArray)
    lmul!(α, block_array.blocks)
    block_array
end

function rmul!(block_array::PseudoBlockArray, α::Number)
    rmul!(block_array.blocks, α)
    block_array
end


###########################
# Strided Array interface #
###########################

Base.strides(A::PseudoBlockArray) = strides(A.blocks)
Base.stride(A::PseudoBlockArray, i::Integer) = stride(A.blocks, i)
Base.unsafe_convert(::Type{Ptr{T}}, A::PseudoBlockArray) where T = Base.unsafe_convert(Ptr{T}, A.blocks)
