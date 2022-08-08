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

# Examples
```julia
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

Alias for UndefBlocksInitializer(), which constructs an instance of the singleton
type UndefBlocksInitializer (@ref), used in block array initialization to indicate the
array-constructor-caller would like an uninitialized block array.

# Examples
```julia
julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockMatrix{Float32}:
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

# Auxilary outer constructors
@inline _BlockArray(blocks::R, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    _BlockArray(blocks, map(blockedrange, block_sizes))

# support non-concrete eltypes in blocks
_BlockArray(blocks::R, block_axes::BS) where {T, N, R<:AbstractArray{<:AbstractArray{V,N} where V,N}, BS<:NTuple{N,AbstractUnitRange{Int}}} =
    _BlockArray(convert(AbstractArray{AbstractArray{mapreduce(eltype,promote_type,blocks),N},N}, blocks), block_axes)
_BlockArray(blocks::R, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{V,N} where V,N}} =
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
Constructs a `BlockArray` with uninitialized blocks from a block type `R` with sizes defind by `block_sizes`.

```jldoctest; setup = quote using BlockArrays end
julia> BlockArray(undef_blocks, Matrix{Float64}, [1,3], [2,2])
2×2-blocked 4×4 BlockMatrix{Float64}:
 #undef  #undef  │  #undef  #undef
 ────────────────┼────────────────
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef
```
"""
@inline BlockArray(::UndefBlocksInitializer, ::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{T,N}} =
    undef_blocks_BlockArray(Array{R,N}, block_sizes...)

@inline BlockArray{T}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N} =
    BlockArray(undef_blocks, Array{T,N}, block_sizes...)

@inline BlockArray{T,N,R}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{<:AbstractArray{T,N},N}} =
    undef_blocks_BlockArray(R, block_sizes...)

@generated function initialized_blocks_BlockArray(::Type{R}, baxes::NTuple{N,AbstractUnitRange{Int}}) where R<:AbstractArray{V,N} where {T,N,V<:AbstractArray{T,N}}
    return quote
        block_arr = _BlockArray(R, baxes)
        @nloops $N i i->blockaxes(baxes[i],1) begin
            block_index = @ntuple $N i
            block_arr[block_index...] = similar(V, length.(getindex.(baxes, block_index)))
        end

        return block_arr
    end
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

@generated function BlockArray{T}(arr::AbstractArray{T, N}, baxes::NTuple{N,AbstractUnitRange{Int}}) where {T,N}
    return quote
        block_arr = _BlockArray(Array{typeof(arr),N}, baxes)
        @nloops $N i i->blockaxes(baxes[i],1) begin
            block_index = @ntuple $N i
            indices = getindex.(baxes,block_index)
            block_arr[block_index...] = arr[indices...]
        end

        return block_arr
    end
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
```jldoctest; setup = quote using BlockArrays end
julia> arrays = permutedims(reshape([
                  1ones(1, 3), 2ones(1, 2),
                  3ones(2, 3), 4ones(2, 2),
              ], (2, 2)))
2×2 Matrix{Matrix{Float64}}:
 [1.0 1.0 1.0]               [2.0 2.0]
 [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]

julia> mortar(arrays)
2×2-blocked 3×5 BlockMatrix{Float64}:
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

function viewblock(block_arr::BlockArray, block)
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

@inline Base.getindex(block_arr::BlockArray{T,N}, blockindex::BlockIndex{N}) where {T,N} =
    _blockindex_getindex(block_arr, blockindex)
@inline Base.getindex(block_arr::BlockVector{T}, blockindex::BlockIndex{1}) where {T} =
    _blockindex_getindex(block_arr, blockindex)

###########################
# AbstractArray Interface #
###########################


@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{BlockedUnitRange,BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::AbstractArray, ::Type{T}, axes::Tuple{Union{AbstractUnitRange{Int},Integer},BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{BlockedUnitRange,BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::Type{<:AbstractArray{T}}, axes::Tuple{Union{AbstractUnitRange{Int},Integer},BlockedUnitRange,Vararg{Union{AbstractUnitRange{Int},Integer}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

const OffsetAxis = Union{Integer, UnitRange, Base.OneTo, Base.IdentityUnitRange}

# avoid ambiguities
@inline Base.similar(block_array::BlockArray, ::Type{T}, dims::NTuple{N,Int}) where {T,N} =
    Array{T}(undef, dims)
@inline Base.similar(block_array::BlockArray, ::Type{T}, axes::Tuple{OffsetAxis,Vararg{OffsetAxis}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))
@inline Base.similar(block_array::BlockArray, ::Type{T}, axes::Tuple{Base.OneTo{Int},Vararg{Base.OneTo{Int}}}) where T =
    BlockArray{T}(undef, map(to_axes,axes))

@inline function Base.getindex(block_arr::BlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[findblockindex.(axes(block_arr), i)...]
    return v
end

@inline function Base.setindex!(block_arr::BlockArray{T, N}, v, i::Vararg{Integer, N}) where {T,N}
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

@inline function Base.setindex!(block_arr::BlockArray{T, N}, v, block::Vararg{Block{1}, N}) where {T,N}
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
    bl = block_arr[blind...]
    inds = map(blockindex, J)
    bl, inds
end
function Base.replace_in_print_matrix(block_arr::BlockArray{<:Any,2}, i::Integer, j::Integer, s::AbstractString)
    try
        bl, inds = _replace_in_print_matrix_inds(block_arr, i, j)
        Base.replace_in_print_matrix(bl, inds..., s)
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

@generated function Base.Array(block_array::BlockArray{T, N, R}) where {T,N,R}
    # TODO: This will fail for empty block array
    return quote
        arr = similar(block_array.blocks[1], size(block_array)...)
        @nloops $N i i->blockaxes(block_array,i) begin
            block_index = @ntuple $N i
            indices = getindex.(axes(block_array), block_index)
            arr[indices...] = block_array[block_index...]
        end

        return arr
    end
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

