# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed.


#######################
# UndefBlocksInitializer #
#######################

"""
    UndefBlocksInitializer

Singleton type used in block array initialization, indicating the
array-constructor-caller would like an uninitialized block array. See also
[`undef_blocks`](@ref), an alias for `UndefBlocksInitializer()`.

# Examples
```jldoctest
julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockMatrix{Float32}:
 #undef  #undef  #undef  │  #undef  #undef
 ────────────────────────┼────────────────
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```
"""
struct UndefBlocksInitializer end

"""
    undef_blocks

Alias for `UndefBlocksInitializer()`, which constructs an instance of the singleton
type [`UndefBlocksInitializer`](@ref), used in block array initialization to indicate the
array-constructor-caller would like an uninitialized block array.

# Examples
```jldoctest
julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockMatrix{Float32}:
 #undef  #undef  #undef  │  #undef  #undef
 ────────────────────────┼────────────────
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
    BlockArray{T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractBlockArray{T, N}

A `BlockArray` is an array where each block is stored contiguously. This means that insertions and retrieval of blocks
can be very fast and non allocating since no copying of data is needed.

In the type definition, `R` defines the array type that holds the blocks, for example `Matrix{Matrix{Float64}}`.
"""
struct BlockArray{T, N, R <: AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractBlockArray{T, N}
    blocks::R
    axes::BS

    global @inline _BlockArray(blocks::R, block_sizes::BS) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} =
        new{T, N, R, BS}(blocks, block_sizes)
end

# Auxiliary outer constructors
@inline _BlockArray(blocks::R, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(blocks, map(blockedrange, block_sizes))

# support non-concrete eltypes in blocks
_BlockArray(blocks::R, block_axes::BS) where {N, R<:AbstractArray{<:AbstractArray{V,N} where V,N}, BS<:NTuple{N,AbstractUnitRange{Int}}} =
    _BlockArray(convert(AbstractArray{AbstractArray{mapreduce(eltype,promote_type,blocks),N},N}, blocks), block_axes)
_BlockArray(blocks::R, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {N, R<:AbstractArray{<:AbstractArray{<:Any,N},N}} =
    _BlockArray(convert(AbstractArray{AbstractArray{mapreduce(eltype,promote_type,blocks),N},N}, blocks), block_sizes...)

const BlockMatrix{T, R <: AbstractMatrix{<:AbstractMatrix{T}}} = BlockArray{T, 2, R}
const BlockVector{T, R <: AbstractVector{<:AbstractVector{T}}} = BlockArray{T, 1, R}
const BlockVecOrMat{T, R} = Union{BlockMatrix{T, R}, BlockVector{T, R}}

################
# Constructors #
################

@inline _BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(R, map(blockedrange,block_sizes))

function _BlockArray(::Type{R}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}}
    n_blocks = map(blocklength,baxes)
    blocks = R(undef, n_blocks)
    _BlockArray(blocks, baxes)
end

@inline undef_blocks_BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(R, block_sizes...)

"""
    BlockArray(::UndefBlocksInitializer, ::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {N,R<:AbstractArray{<:Any,N}}

Construct a `N`-dim `BlockArray` with uninitialized blocks from a block type `R`, with sizes defined by `block_sizes`.
Each block **must** be allocated before being accessed.

# Examples
```jldoctest
julia> B = BlockArray(undef_blocks, Matrix{Float64}, [1,3], [2,2])
2×2-blocked 4×4 BlockMatrix{Float64}:
 #undef  #undef  │  #undef  #undef
 ────────────────┼────────────────
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef

julia> typeof(blocks(B))
Matrix{Matrix{Float64}} (alias for Array{Array{Float64, 2}, 2})

julia> using SparseArrays

julia> B = BlockArray(undef_blocks, SparseMatrixCSC{Float64,Int}, [1,3], [2,2]);

julia> typeof(blocks(B))
Matrix{SparseMatrixCSC{Float64, Int64}} (alias for Array{SparseMatrixCSC{Float64, Int64}, 2})
```

See also [`undef_blocks`](@ref), [`UndefBlocksInitializer`](@ref)
"""
@inline BlockArray(::UndefBlocksInitializer, ::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{T,N}} =
    undef_blocks_BlockArray(Array{R,N}, block_sizes...)

"""
    BlockArray{T}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T,N}

Construct a `N`-dim `BlockArray` with uninitialized blocks of type `Array{T,N}`, with sizes defined by `block_sizes`.
Each block **must** be allocated before being accessed.

# Examples
```jldoctest
julia> B = BlockArray{Float64}(undef_blocks, [1,2], [1,2])
2×2-blocked 3×3 BlockMatrix{Float64}:
 #undef  │  #undef  #undef
 ────────┼────────────────
 #undef  │  #undef  #undef
 #undef  │  #undef  #undef

julia> typeof(blocks(B))
Matrix{Matrix{Float64}} (alias for Array{Array{Float64, 2}, 2})

julia> B = BlockArray{Int8}(undef_blocks, [1,2])
2-blocked 3-element BlockVector{Int8}:
 #undef
 ──────
 #undef
 #undef

julia> typeof(blocks(B))
Vector{Vector{Int8}} (alias for Array{Array{Int8, 1}, 1})

julia> B[Block(1)] .= 2 # errors, as the block is not allocated yet
ERROR: UndefRefError: access to undefined reference
[...]

julia> B[Block(1)] = [1]; # assign an array to the block

julia> B[Block(2)] = [2,3];

julia> B
2-blocked 3-element BlockVector{Int8}:
 1
 ─
 2
 3
```

See also [`undef_blocks`](@ref), [`UndefBlocksInitializer`](@ref)
"""
@inline BlockArray{T}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N,R}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    undef_blocks_BlockArray(R, block_sizes...)

function initialized_blocks_BlockArray(::Type{R}, baxes::NTuple{N,AbstractUnitRange{Int}}) where R<:AbstractArray{V,N} where {T,N,V<:AbstractArray{T,N}}
    blocks = map(Iterators.product(map(x -> blockaxes(x,1), baxes)...)) do block_index
        indices = map((x,y) -> x[y], baxes, block_index)
        similar(V, map(length, indices))
    end
    return _BlockArray(convert(R, blocks), baxes)
end


initialized_blocks_BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, map(blockedrange,block_sizes))

@inline BlockArray{T}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, baxes)

@inline BlockArray{T, N}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, baxes)

@inline BlockArray{T, N, R}(::UndefInitializer, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, baxes)

@inline BlockArray{T,N,R,BS}(::UndefInitializer, baxes::BS) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} =
    initialized_blocks_BlockArray(R, baxes)

"""
    BlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N}

Construct a `N`-dim `BlockArray` with blocks of type `Array{T,N}`, with sizes defined by `block_sizes`.
The blocks are allocated using `similar`, and the elements in each block are therefore unitialized.

# Examples
```jldoctest
julia> B = BlockArray{Int8}(undef, [1,2]);

julia> B[Block(1)] .= 2;

julia> B[Block(2)] .= 3;

julia> B
2-blocked 3-element BlockVector{Int8}:
 2
 ─
 3
 3
```
"""
@inline BlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes...)

@inline BlockArray{T, N}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    initialized_blocks_BlockArray(Array{Array{T,N},N}, block_sizes...)

@inline BlockArray{T, N, R}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    initialized_blocks_BlockArray(R, block_sizes...)


@inline BlockArray{T,N,R,BS}(::UndefInitializer, sizes::NTuple{N,Int}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} =
    BlockArray{T,N,R,BS}(undef, convert(BS, map(Base.OneTo, sizes)))

function BlockArray{T}(arr::AbstractArray{V, N}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T,V,N}
    for i in 1:N
        if sum(block_sizes[i]) != size(arr, i)
            throw(DimensionMismatch("block size for dimension $i: $(block_sizes[i]) does not sum to the array size: $(size(arr, i))"))
        end
    end
    BlockArray{T}(arr, map(blockedrange,block_sizes))
end

BlockArray(arr::AbstractArray{T, N}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T,N} =
    BlockArray{T}(arr, block_sizes...)

function BlockArray{T}(arr::AbstractArray{T, N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N}
    blocks = map(Iterators.product(map(x -> blockaxes(x,1), baxes)...)) do block_index
        indices = map((x,y) -> x[y], baxes, block_index)
        arr[indices...]
    end
    return _BlockArray(blocks, baxes)
end

BlockArray{T}(arr::AbstractArray{<:Any, N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N} =
    BlockArray{T}(convert(AbstractArray{T, N}, arr), baxes)

BlockArray(arr::AbstractArray{T, N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N} =
    BlockArray{T}(arr, baxes)

BlockVector(blocks::AbstractVector, baxes::Tuple{AbstractUnitRange{Int}}) = BlockArray(blocks, baxes)
BlockVector(blocks::AbstractVector, block_sizes::AbstractVector{<:Integer}) = BlockArray(blocks, block_sizes)
BlockMatrix(blocks::AbstractMatrix, baxes::NTuple{2,AbstractUnitRange{Int}}) = BlockArray(blocks, baxes)
BlockMatrix(blocks::AbstractMatrix, block_sizes::Vararg{AbstractVector{<:Integer},2}) = BlockArray(blocks, block_sizes...)

BlockArray{T}(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = BlockArray{T}(Matrix(λ, map(length,baxes)...), baxes)
BlockArray{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) where T = BlockArray{T}(λ, map(blockedrange,block_sizes))
BlockArray(λ::UniformScaling{T}, block_sizes::Vararg{AbstractVector{<:Integer}, 2}) where T = BlockArray{T}(λ, block_sizes...)
BlockArray(λ::UniformScaling{T}, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = BlockArray{T}(λ, baxes)
BlockMatrix(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) = BlockArray(λ, baxes)
BlockMatrix(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer},2}) = BlockArray(λ, block_sizes...)
BlockMatrix{T}(λ::UniformScaling, baxes::NTuple{2,AbstractUnitRange{Int}}) where T = BlockArray{T}(λ, baxes)
BlockMatrix{T}(λ::UniformScaling, block_sizes::Vararg{AbstractVector{<:Integer},2}) where T = BlockArray{T}(λ, block_sizes...)

"""
    mortar(blocks::AbstractArray)
    mortar(blocks::AbstractArray{R, N}, sizes_1, sizes_2, ..., sizes_N)
    mortar(blocks::AbstractArray{R, N}, block_sizes::NTuple{N,AbstractUnitRange{Int}})

Construct a `BlockArray` from `blocks`.  `block_sizes` is computed from
`blocks` if it is not given.

This is an "inverse" of [`blocks`](@ref).

# Examples
```jldoctest
julia> arrays = permutedims(reshape([
                  fill(1.0, 1, 3), fill(2.0, 1, 2),
                  fill(3.0, 2, 3), fill(4.0, 2, 2),
              ], (2, 2)))
2×2 Matrix{Matrix{Float64}}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> M = mortar(arrays)
2×2-blocked 3×5 BlockMatrix{Float64}:
 1.0  1.0  1.0  │  2.0  2.0
 ───────────────┼──────────
 3.0  3.0  3.0  │  4.0  4.0
 3.0  3.0  3.0  │  4.0  4.0

julia> M == mortar(
                  (fill(1.0, 1, 3), fill(2.0, 1, 2)),
                  (fill(3.0, 2, 3), fill(4.0, 2, 2)),
              )
true
```
"""
mortar(blocks::AbstractArray{R, N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {R, N} =
    _BlockArray(blocks, baxes)

mortar(blocks::AbstractArray{R, N}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {R, N} =
    _BlockArray(blocks, block_sizes...)

mortar(blocks::AbstractArray) = mortar(blocks, sizes_from_blocks(blocks)...)

sizes_from_blocks(blocks) = sizes_from_blocks(blocks, axes(blocks)) # allow overriding on axes

function sizes_from_blocks(blocks::AbstractVector, _)
    if !all(b -> ndims(b) == 1, blocks)
        error("All blocks must have ndims consistent with ndims = 1 of `blocks` array.")
    end
    (map(length, blocks),)
end

function sizes_from_blocks(blocks::AbstractArray{<:Any, N}, _) where N
    if length(blocks) == 0
        return zeros.(Int, size(blocks))
    end
    if !all(b -> ndims(b) == N, blocks)
        error("All blocks must have ndims consistent with ndims = $N of `blocks` array.")
    end
    fullsizes = map!(size, Array{NTuple{N,Int}, N}(undef, size(blocks)), blocks)
    fR = reinterpret(reshape, Int, fullsizes)
    stfR = strides(fR)
    block_sizes = ntuple(N) do i
        fR[range(i, step = stfR[i+1], length=size(fullsizes, i))]
    end
    checksizes(fullsizes, block_sizes)
    return block_sizes
end

getsizes(block_sizes, block_index) = getindex.(block_sizes, block_index)

function checksizes(fullsizes::Array{NTuple{N,Int}, N}, block_sizes::NTuple{N,Vector{Int}}) where N
    for I in CartesianIndices(fullsizes)
        block_index = Tuple(I)
        if fullsizes[block_index...] != getsizes(block_sizes, block_index)
            error("size(blocks[", strip(repr(block_index), ['(', ')']),
                  "]) (= ", fullsizes[block_index...],
                  ") is incompatible with expected size: ",
                  getsizes(block_sizes, block_index))
        end
    end
    return fullsizes
end

"""
    mortar((block_11, ..., block_1m), ... (block_n1, ..., block_nm))

Construct a `BlockMatrix` with `n * m`  blocks.  Each `block_ij` must be an
`AbstractMatrix`.
"""
function mortar(row1::NTuple{M, AbstractMatrix}, rows::Vararg{NTuple{M, AbstractMatrix}}) where M
    allrows = (row1, rows...)
    allblocks = reduce((x,y)->(x...,y...), allrows)
    allblocks_vector = [allblocks...]
    mortar(permutedims(reshape(allblocks_vector, M, length(allrows))))
end

# Convert AbstractArrays that conform to block array interface
convert(::Type{BlockArray{T,N,R}}, A::BlockArray{T,N,R}) where {T,N,R} = A
convert(::Type{BlockArray{T,N}}, A::BlockArray{T,N}) where {T,N} = A
convert(::Type{BlockArray{T}}, A::BlockArray{T}) where {T} = A
convert(::Type{BlockArray}, A::BlockArray) = A

BlockArray{T, N}(A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockArray(Array{T, N}(A), axes(A))
BlockArray{T1}(A::AbstractArray{T2, N}) where {T1,T2,N} = BlockArray{T1, N}(A)
BlockArray(A::AbstractArray{T, N}) where {T,N} = BlockArray{T, N}(A)

convert(::Type{BlockArray{T, N}}, A::AbstractArray{T2, N}) where {T,T2,N} =
    BlockArray(convert(Array{T, N}, A), axes(A))
convert(::Type{BlockArray{T1}}, A::AbstractArray{T2, N}) where {T1,T2,N} =
    convert(BlockArray{T1, N}, A)
convert(::Type{BlockArray}, A::AbstractArray{T, N}) where {T,N} =
    convert(BlockArray{T, N}, A)

copy(A::BlockArray) = _BlockArray(map(copy,A.blocks), A.axes)

################################
# AbstractBlockArray Interface #
################################
@inline axes(block_array::BlockArray) = block_array.axes

@propagate_inbounds function viewblock(block_arr::BlockArray, block)
    blks = block.n
    @boundscheck blockcheckbounds(block_arr, blks...)
    block_arr.blocks[blks...]
end

@inline function _blockindex_getindex(block_arr, bi)
    @boundscheck blockcheckbounds(block_arr, Block(bi.I))
    @inbounds bl = view(block_arr, block(bi))
    inds = bi.α
    @boundscheck checkbounds(bl, inds...)
    @inbounds v = bl[inds...]
    return v
end

@propagate_inbounds getindex(block_arr::BlockArray{T,N}, blockindex::BlockIndex{N}) where {T,N} =
    _blockindex_getindex(block_arr, blockindex)
@propagate_inbounds getindex(block_arr::BlockVector{T}, blockindex::BlockIndex{1}) where {T} =
    _blockindex_getindex(block_arr, blockindex)

###########################
# AbstractArray Interface #
###########################


@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{Union{AbstractUnitRange{Int},Integer},AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{Union{AbstractUnitRange{Int},Integer},AbstractBlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

@inline Base.similar(B::BlockArray, ::Type{T}) where {T} = mortar(similar.(blocks(B), T))

const OffsetAxis = Union{Integer, UnitRange, Base.OneTo, Base.IdentityUnitRange}

# avoid ambiguities
@inline Base.similar(block_array::BlockArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N} =
    Array{T}(undef, dims)
@inline Base.similar(block_array::BlockArray, ::Type{T}, axes::Tuple{OffsetAxis,Vararg{OffsetAxis}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::BlockArray, ::Type{T}, axes::Tuple{Base.OneTo{Int},Vararg{Base.OneTo{Int}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

@inline function getindex(block_arr::BlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[findblockindex.(axes(block_arr), i)...]
    return v
end

@inline function setindex!(block_arr::BlockArray{T, N}, v, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr[findblockindex.(axes(block_arr), i)...] = v
    return block_arr
end

############
# Indexing #
############

function _check_setblock!(block_arr::BlockArray{T, N}, v, block::NTuple{N, Integer}) where {T,N}
    for i in 1:N
        bsz = length(axes(block_arr, i)[Block(block[i])])
        if size(v, i) != bsz
            throw(DimensionMismatch(string("tried to assign $(size(v)) array to ", length.(getindex.(axes(block_arr), block)), " block")))
        end
    end
end

@inline function setindex!(block_arr::BlockArray{T, N}, v, block::Vararg{Block{1}, N}) where {T,N}
    blks = Int.(block)
    @boundscheck blockcheckbounds(block_arr, blks...)
    @boundscheck _check_setblock!(block_arr, v, blks)
    @inbounds block_arr.blocks[blks...] = v
    return block_arr
end

Base.dataids(arr::BlockArray) = (dataids(arr.blocks)..., dataids(arr.axes)...)
# This is not entirely valid.  In principle, we have to concatenate
# all dataids of all blocks.  However, it makes `dataids` non-inferable.

# Pretty-printing for sparse arrays
function _replace_in_print_matrix_inds(block_arr, i...)
    J = findblockindex.(axes(block_arr), i)
    blind = map(block, J)
    bl = @view block_arr[blind...]
    inds = map(blockindex, J)
    bl, inds
end
function Base.replace_in_print_matrix(block_arr::BlockArray{<:Any,2}, i::Integer, j::Integer, s::AbstractString)
    try
        I,J = findblock(axes(block_arr,1),i),findblock(axes(block_arr,2),j)
        if Int(I) in colsupport(block_arr.blocks, Int(J))
            bl, inds = _replace_in_print_matrix_inds(block_arr, i, j)
            Base.replace_in_print_matrix(bl, inds..., s)
        else
            Base.replace_with_centered_mark(s)
        end
    catch UndefRefError # thrown with undef_blocks
        s
    end
end
function Base.replace_in_print_matrix(block_arr::BlockArray{<:Any,1}, i::Integer, j::Integer, s::AbstractString)
    try
        bl, inds = _replace_in_print_matrix_inds(block_arr, i)
        Base.replace_in_print_matrix(bl, inds..., j, s)
    catch UndefRefError
        s
    end
end

########
# Misc #
########

function Base.Array(block_array::BlockArray{T, N, R}) where {T,N,R}
    arr = Array{eltype(T)}(undef, size(block_array))
    for block_index in Iterators.product(blockaxes(block_array)...)
        indices = getindex.(axes(block_array), block_index)
        arr[indices...] = @view block_array[block_index...]
    end
    return arr
end

function Base.fill!(block_array::BlockArray, v)
    for block in block_array.blocks
        fill!(block, v)
    end
    block_array
end

# Temporary work around
Base.reshape(block_array::BlockArray, axes::NTuple{N,AbstractUnitRange{Int}}) where N =
    reshape(PseudoBlockArray(block_array), axes)
Base.reshape(block_array::BlockArray, dims::Tuple{Int,Vararg{Int}}) =
    reshape(PseudoBlockArray(block_array), dims)
Base.reshape(block_array::BlockArray, axes::Tuple{Union{Integer,Base.OneTo}, Vararg{Union{Integer,Base.OneTo}}}) =
    reshape(PseudoBlockArray(block_array), axes)
Base.reshape(block_array::BlockArray, dims::Tuple{Vararg{Union{Int,Colon}}}) =
    reshape(PseudoBlockArray(block_array), dims)

"""
    resize!(a::BlockVector, N::Block) -> PseudoBlockVector

Resize `a` to contain the first `N` blocks, returning a new `BlockVector` sharing
memory with `a`. If `N` is smaller than the current
collection block length, the first `N` blocks will be retained. `N` is not allowed to be larger.
"""
function resize!(a::BlockVector, N::Block{1})
    ax = axes(a,1)
    Ni = Int(N)
    _BlockArray(resize!(a.blocks, Ni), (ax[Block.(Base.OneTo(Ni))],))
end

