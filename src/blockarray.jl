# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed.


#######################
# UndefBlocksInitializer #
#######################

"""
    UndefBlocksInitializer

Singleton type used in block array initialization, indicating the
array-constructor-caller would like an uninitialized block array. See also
undef_blocks (@ref), an alias for UndefBlocksInitializer().

Examples

≡≡≡≡≡≡≡≡≡≡
```julia
julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockArray{Float32,2}:
 #undef  #undef  #undef  │  #undef  #undef
 ────────────────────────┼────────────────
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
 ```
"""
struct UndefBlocksInitializer end

"""
    undef_blocks

Alias for UndefBlocksInitializer(), which constructs an instance of the singleton
type UndefBlocksInitializer (@ref), used in block array initialization to indicate the
array-constructor-caller would like an uninitialized block array.

Examples

≡≡≡≡≡≡≡≡≡≡
```julia
julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockArray{Float32,2}:
 #undef  #undef  #undef  │  #undef  #undef
 ------------------------┼----------------
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
 ```
"""
const undef_blocks = UndefBlocksInitializer()

##############
# BlockArray #
##############

function _BlockArray end

"""
    BlockArray{T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:AbstractBlockSizes{N}} <: AbstractBlockArray{T, N}

A `BlockArray` is an array where each block is stored contiguously. This means that insertions and retrieval of blocks
can be very fast and non allocating since no copying of data is needed.

In the type definition, `R` defines the array type that holds the blocks, for example `Matrix{Matrix{Float64}}`.
"""
struct BlockArray{T, N, R <: AbstractArray{<:AbstractArray{T,N},N}, BS<:AbstractBlockSizes{N}} <: AbstractBlockArray{T, N}
    blocks::R
    block_sizes::BS

    global function _BlockArray(blocks::R, block_sizes::BS) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:AbstractBlockSizes{N}}
        new{T, N, R, BS}(blocks, block_sizes)
    end
end

# Auxilary outer constructors
function _BlockArray(blocks::R, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}}
    return _BlockArray(blocks, BlockSizes(block_sizes...))
end

const BlockMatrix{T, R <: AbstractMatrix{<:AbstractMatrix{T}}} = BlockArray{T, 2, R}
const BlockVector{T, R <: AbstractVector{<:AbstractVector{T}}} = BlockArray{T, 1, R}
const BlockVecOrMat{T, R} = Union{BlockMatrix{T, R}, BlockVector{T, R}}

################
# Constructors #
################

@inline _BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(R, BlockSizes(block_sizes...))

function _BlockArray(::Type{R}, block_sizes::BlockSizes{N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}}
    n_blocks = nblocks(block_sizes)
    blocks = R(undef, n_blocks)
    _BlockArray(blocks, block_sizes)
end

@inline undef_blocks_BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(R, block_sizes...)

"""
Constructs a `BlockArray` with uninitialized blocks from a block type `R` with sizes defind by `block_sizes`.

```jldoctest; setup = quote using BlockArrays end
julia> BlockArray(undef_blocks, Matrix{Float64}, [1,3], [2,2])
2×2-blocked 4×4 BlockArray{Float64,2}:
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
```
"""
@inline BlockArray(::UndefBlocksInitializer, ::Type{R}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{T,N}} =
    undef_blocks_BlockArray(Array{R,N}, block_sizes...)

@inline BlockArray{T}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N,R}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    undef_blocks_BlockArray(R, block_sizes...)


@generated function initialized_blocks_BlockArray(::Type{R}, block_sizes::BlockSizes{N}) where R<:AbstractArray{V,N} where {T,N,V<:AbstractArray{T,N}}
    return quote
        block_arr = _BlockArray(R, block_sizes)
        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            setblock!(block_arr, similar(V, blocksize(block_sizes, block_index)), block_index...)
        end

        return block_arr
    end
end


initialized_blocks_BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, BlockSizes(block_sizes...))

@inline BlockArray{T}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes)

@inline BlockArray{T, N}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes)

@inline BlockArray{T, N, R}(::UndefInitializer, block_sizes::BlockSizes{N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, block_sizes)

@inline BlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes...)

@inline BlockArray{T, N}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes...)

@inline BlockArray{T, N, R}(::UndefInitializer, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, block_sizes...)

function BlockArray(arr::AbstractArray{T, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T,N}
    for i in 1:N
        if sum(block_sizes[i]) != size(arr, i)
            throw(DimensionMismatch("block size for dimension $i: $(block_sizes[i]) does not sum to the array size: $(size(arr, i))"))
        end
    end
    BlockArray(arr, BlockSizes(block_sizes...))
end

@generated function BlockArray(arr::AbstractArray{T, N}, block_sizes::BlockSizes{N}) where {T,N}
    return quote
        block_arr = _BlockArray(Array{typeof(arr),N}, block_sizes)
        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            setblock!(block_arr, arr[indices...], block_index...)
        end

        return block_arr
    end
end

BlockVector(blocks::AbstractVector, block_sizes::AbstractBlockSizes{1}) = BlockArray(blocks, block_sizes)
BlockVector(blocks::AbstractVector, block_sizes::AbstractVector{Int}) = BlockArray(blocks, block_sizes)
BlockMatrix(blocks::AbstractMatrix, block_sizes::AbstractBlockSizes{2}) = BlockArray(blocks, block_sizes)
BlockMatrix(blocks::AbstractMatrix, block_sizes::Vararg{AbstractVector{Int},2}) = BlockArray(blocks, block_sizes...)

"""
    mortar(blocks::AbstractArray)
    mortar(blocks::AbstractArray{R, N}, sizes_1, sizes_2, ..., sizes_N)
    mortar(blocks::AbstractArray{R, N}, block_sizes::BlockSizes{N})

Construct a `BlockArray` from `blocks`.  `block_sizes` is computed from
`blocks` if it is not given.

# Examples
```jldoctest; setup = quote using BlockArrays end
julia> blocks = permutedims(reshape([
                  1ones(1, 3), 2ones(1, 2),
                  3ones(2, 3), 4ones(2, 2),
              ], (2, 2)))
2×2 Array{Array{Float64,2},2}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> mortar(blocks)
2×2-blocked 3×5 BlockArray{Float64,2}:
 1.0  1.0  1.0  │  2.0  2.0
 ───────────────┼──────────
 3.0  3.0  3.0  │  4.0  4.0
 3.0  3.0  3.0  │  4.0  4.0

julia> ans == mortar(
                  (1ones(1, 3), 2ones(1, 2)),
                  (3ones(2, 3), 4ones(2, 2)),
              )
true
```
"""
mortar(blocks::AbstractArray{R, N}, block_sizes::AbstractBlockSizes{N}) where {R, N} =
    _BlockArray(blocks, block_sizes)

mortar(blocks::AbstractArray{R, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {R, N} =
    _BlockArray(blocks, block_sizes...)

mortar(blocks::AbstractArray) = mortar(blocks, sizes_from_blocks(blocks))

sizes_from_blocks(blocks) = sizes_from_blocks(blocks, axes(blocks)) # allow overriding on axes

function sizes_from_blocks(blocks::AbstractArray{<:Any, N}, _) where N
    if length(blocks) == 0
        return zeros.(Int, size(blocks))
    end
    if !all(b -> ndims(b) == N, blocks)
        error("All blocks must have ndims consistent with ndims = $N of `blocks` array.")
    end
    fullsizes = map!(size, Array{NTuple{N,Int}, N}(undef, size(blocks)), blocks)
    block_sizes = ntuple(ndims(blocks)) do i
        [s[i] for s in view(fullsizes, ntuple(j -> j == i ? (:) : 1, ndims(blocks))...)]
    end
    checksizes(fullsizes, block_sizes)
    return BlockSizes(block_sizes...)
end

getsizes(block_sizes, block_index) = getindex.(block_sizes, block_index)

@generated function checksizes(fullsizes::Array{NTuple{N,Int}, N}, block_sizes::NTuple{N,Vector{Int}}) where N
    quote
        @nloops $N i fullsizes begin
            block_index = @ntuple $N i
            if fullsizes[block_index...] != getsizes(block_sizes, block_index)
                error("size(blocks[", strip(repr(block_index), ['(', ')']),
                      "]) (= ", fullsizes[block_index...],
                      ") is incompatible with expected size: ",
                      getsizes(block_sizes, block_index))
            end
        end
        return fullsizes
    end
end

"""
    mortar((block_11, ..., block_1m), ... (block_n1, ..., block_nm))

Construct a `BlockMatrix` with `n * m`  blocks.  Each `block_ij` must be an
`AbstractMatrix`.
"""
mortar(rows::Vararg{NTuple{M, AbstractMatrix}}) where M =
    mortar(permutedims(reshape(
        foldl(append!, rows, init=eltype(eltype(rows))[]),
        M, length(rows))))

# Convert AbstractArrays that conform to block array interface
convert(::Type{BlockArray{T,N,R}}, A::BlockArray{T,N,R}) where {T,N,R} = A
convert(::Type{BlockArray{T,N}}, A::BlockArray{T,N}) where {T,N} = A
convert(::Type{BlockArray{T}}, A::BlockArray{T}) where {T} = A
convert(::Type{BlockArray}, A::BlockArray) = A

BlockArray{T, N}(A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockArray(Array{T, N}(A), blocksizes(A))
BlockArray{T1}(A::AbstractArray{T2, N}) where {T1,T2,N} = BlockArray{T1, N}(A)
BlockArray(A::AbstractArray{T, N}) where {T,N} = BlockArray{T, N}(A)

convert(::Type{BlockArray{T, N}}, A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockArray(convert(Array{T, N}, A), blocksizes(A))
convert(::Type{BlockArray{T1}}, A::AbstractArray{T2, N}) where {T1,T2,N} =
    convert(BlockArray{T1, N}, A)
convert(::Type{BlockArray}, A::AbstractArray{T, N}) where {T,N} =
    convert(BlockArray{T, N}, A)

copy(A::BlockArray) = _BlockArray(copy.(A.blocks), copy(A.block_sizes))

################################
# AbstractBlockArray Interface #
################################
@inline blocksizes(block_array::BlockArray) = block_array.block_sizes

@inline function getblock(block_arr::BlockArray{T,N}, block::Vararg{Integer, N}) where {T,N}
    @boundscheck blockcheckbounds(block_arr, block...)
    block_arr.blocks[block...]
end

@inline function Base.getindex(block_arr::BlockArray{T,N}, blockindex::BlockIndex{N}) where {T,N}
    @boundscheck blockcheckbounds(block_arr, Block(blockindex.I))
    @inbounds block = getblock(block_arr, blockindex.I...)
    @boundscheck checkbounds(block, blockindex.α...)
    @inbounds v = block[blockindex.α...]
    return v
end


###########################
# AbstractArray Interface #
###########################

@inline function Base.similar(block_array::BlockArray{T,N}, ::Type{T2}) where {T,N,T2}
    _BlockArray(similar(block_array.blocks, Array{T2, N}), copy(blocksizes(block_array)))
end

@inline function Base.getindex(block_arr::BlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[global2blockindex(blocksizes(block_arr), i)]
    return v
end

@inline function Base.setindex!(block_arr::BlockArray{T, N}, v, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr[global2blockindex(blocksizes(block_arr), i)] = v
    return block_arr
end

############
# Indexing #
############

function _check_setblock!(block_arr::BlockArray{T, N}, v, block::NTuple{N, Integer}) where {T,N}
    for i in 1:N
        if size(v, i) != blocksize(block_arr, i, block[i])
            throw(DimensionMismatch(string("tried to assign $(size(v)) array to ", blocksize(block_arr, block), " block")))
        end
    end
end


@inline function setblock!(block_arr::BlockArray{T, N}, v, block::Vararg{Integer, N}) where {T,N}
    @boundscheck blockcheckbounds(block_arr, block...)
    @boundscheck _check_setblock!(block_arr, v, block)
    @inbounds block_arr.blocks[block...] = v
    return block_arr
end

@propagate_inbounds function Base.setindex!(block_array::BlockArray{T, N}, v, block_index::BlockIndex{N}) where {T,N}
    getblock(block_array, block_index.I...)[block_index.α...] = v
end

Base.dataids(arr::BlockArray) = (dataids(arr.blocks)..., dataids(arr.block_sizes)...)
# This is not entirely valid.  In principle, we have to concatenate
# all dataids of all blocks.  However, it makes `dataids` non-inferable.

########
# Misc #
########

@generated function Base.Array(block_array::BlockArray{T, N, R}) where {T,N,R}
    # TODO: This will fail for empty block array
    return quote
        block_sizes = blocksizes(block_array)
        arr = similar(block_array.blocks[1], size(block_array)...)
        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            arr[indices...] = getblock(block_array, block_index...)
        end

        return arr
    end
end

@generated function copyto!(block_array::BlockArray{T, N, R}, arr::R) where {T,N,R <: AbstractArray}
    return quote
        block_sizes = blocksizes(block_array)

        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            copyto!(getblock(block_array, block_index...), arr[indices...])
        end

        return block_array
    end
end

function Base.fill!(block_array::BlockArray, v)
    for block in block_array.blocks
        fill!(block, v)
    end
    block_array
end

function lmul!(α::Number, block_array::BlockArray)
    for block in block_array.blocks
        lmul!(α, block)
    end
    block_array
end

function rmul!(block_array::BlockArray, α::Number)
    for block in block_array.blocks
        rmul!(block, α)
    end
    block_array
end
