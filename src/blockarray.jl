# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed.

##############
# BlockArray #
##############

"""
    BlockArray{T, N, R <: AbstractArray{T, N}} <: AbstractBlockArray{T, N}

A `BlockArray` is an array where each block is stored contiguously. This means that insertions and retrieval of blocks
can be very fast and non allocating since no copying of data is needed.

In the type definition, `R` defines the array type that each block has, for example `Matrix{Float64}.
"""
struct BlockArray{T, N, R <: AbstractArray{T, N}} <: AbstractBlockArray{T, N}
    blocks::Array{R, N}
    block_sizes::BlockSizes{N}
end

# Auxilary outer constructors
function BlockArray(blocks::Array{R, N}, block_sizes::BlockSizes{N}) where {T, N, R <: AbstractArray{T, N}}
    return BlockArray{T, N, R}(blocks, block_sizes)
end

function BlockArray(blocks::Array{R, N}, block_sizes::Vararg{Vector{Int}, N}) where {T, N, R <: AbstractArray{T, N}}
    return BlockArray{T, N, R}(blocks, BlockSizes(block_sizes...))
end


const BlockMatrix{T, R <: AbstractMatrix{T}} = BlockArray{T, 2, R}
const BlockVector{T, R <: AbstractVector{T}} = BlockArray{T, 1, R}
const BlockVecOrMat{T, R} = Union{BlockMatrix{T, R}, BlockVector{T, R}}

################
# Constructors #
################

"""
Constructs a `BlockArray` with uninitialized blocks from a block type `R` with sizes defind by `block_sizes`.

```jldoctest
julia> BlockArray(Matrix{Float64}, [1,3], [2,2])
2×2-blocked 4×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
```
"""
@inline function BlockArray{T, N, R <: AbstractArray{T,N}}(::Type{R}, block_sizes::Vararg{Vector{Int}, N})
    BlockArray(R, BlockSizes(block_sizes...))
end

function BlockArray{T, N, R <: AbstractArray{T,N}}(::Type{R}, block_sizes::BlockSizes{N})
    n_blocks = nblocks(block_sizes)
    blocks = Array{R, N}(n_blocks)
    BlockArray{T,N,R}(blocks, block_sizes)
end

@generated function BlockArray{T, N}(arr::AbstractArray{T, N}, block_sizes::Vararg{Vector{Int}, N})
    return quote
        for i in 1:N
            if sum(block_sizes[i]) != size(arr, i)
                throw(DimensionMismatch("block size for dimension $i: $(block_sizes[i]) does not sum to the array size: $(size(arr, i))"))
            end
        end

        _block_sizes = BlockSizes(block_sizes...)
        block_arr = BlockArray(typeof(arr), _block_sizes)
        @nloops $N i i->(1:nblocks(_block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(_block_sizes, block_index)
            setblock!(block_arr, arr[indices...], block_index...)
        end

        return block_arr
    end
end

################################
# AbstractBlockArray Interface #
################################

@inline nblocks(block_array::BlockArray) = nblocks(block_array.block_sizes)
@inline blocksize{T, N}(block_array::BlockArray{T,N}, i::Vararg{Int, N}) = blocksize(block_array.block_sizes, i)

@inline function getblock{T, N}(block_arr::BlockArray{T,N}, block::Vararg{Int, N})
    @boundscheck blockcheckbounds(block_arr, block...)
    block_arr.blocks[block...]
end

@inline function Base.getindex{T, N}(block_arr::BlockArray{T,N}, blockindex::BlockIndex{N})
    @boundscheck checkbounds(block_arr.blocks, blockindex.I...)
    @inbounds block = block_arr.blocks[blockindex.I...]
    @boundscheck checkbounds(block, blockindex.α...)
    @inbounds v = block[blockindex.α...]
    return v
end


###########################
# AbstractArray Interface #
###########################

@inline function Base.similar{T,N,T2}(block_array::BlockArray{T,N}, ::Type{T2})
    BlockArray(similar(block_array.blocks, Array{T2, N}), copy(block_array.block_sizes))
end

@generated function Base.size{T,N}(arr::BlockArray{T,N})
    exp = Expr(:tuple, [:(arr.block_sizes[$i][end] - 1) for i in 1:N]...)
    return quote
        @inbounds return $exp
    end
end

@inline function Base.getindex{T, N}(block_arr::BlockArray{T, N}, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[global2blockindex(block_arr.block_sizes, i)]
    return v
end

@inline function Base.setindex!{T, N}(block_arr::BlockArray{T, N}, v, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr[global2blockindex(block_arr.block_sizes, i)] = v
    return block_arr
end

############
# Indexing #
############

function _check_setblock!{T,N}(block_arr::BlockArray{T, N}, v, block::NTuple{N, Int})
    for i in 1:N
        if size(v, i) != blocksize(block_arr.block_sizes, i, block[i])
            throw(DimensionMismatch(string("tried to assign $(size(v)) array to ", blocksize(block_arr, block...), " block")))
        end
    end
end


@inline function setblock!{T, N}(block_arr::BlockArray{T, N}, v, block::Vararg{Int, N})
    @boundscheck blockcheckbounds(block_arr, block...)
    @boundscheck _check_setblock!(block_arr, v, block)
    @inbounds block_arr.blocks[block...] = v
    return block_arr
end

@inline function Base.setindex!{T,N}(block_array::BlockArray{T, N}, v, block_index::BlockIndex{N})
    getblock(block_array, block_index.I...)[block_index.α...] = v
end

########
# Misc #
########

@generated function Base.Array{T,N,R}(block_array::BlockArray{T, N, R})
    # TODO: This will fail for empty block array
    return quote
        block_sizes = block_array.block_sizes
        arr = similar(block_array.blocks[1], size(block_array)...)
        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            arr[indices...] = getblock(block_array, block_index...)
        end

        return arr
    end
end

@generated function Base.copy!{T, N, R <: AbstractArray}(block_array::BlockArray{T, N, R}, arr::R)
    return quote
        block_sizes = block_array.block_sizes

        @nloops $N i i->(1:nblocks(block_sizes, i)) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            copy!(getblock(block_array, block_index...), arr[indices...])
        end

        return block_array
    end
end

function Base.fill!(block_array::BlockArray, v)
    for block in block_array.blocks
        fill!(block, v)
    end
end
