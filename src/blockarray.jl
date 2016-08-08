# Note: Functions surrounded by a comment blocks are there because `Vararg` is sitll allocating.
# When Vararg is fast enough, they can simply be removed

##############
# BlockArray #
##############

"""
    BlockArray{T, N, R} <: AbstractBlockArray{T, N}

A `BlockArray` is an array where each block is stored contiguously. This means that insertions and retrival of blocks
can be very fast since no copying of data is needed.

In the type definition, `R` defines the array type that each block has, for example `Matrix{Float64}.
"""
immutable BlockArray{T, N, R <: AbstractArray} <: AbstractBlockArray{T, N}
    blocks::Array{R, N}
    block_sizes::BlockSizes{N}
    function BlockArray(blocks::Array{R, N}, block_sizes::BlockSizes{N})
        @assert ndims(R) == N
        @assert eltype(T) == T
        new(blocks, block_sizes)
    end
end

# Auxilary outer constructor
BlockArray{N, R <: AbstractArray}(blocks::Array{R, N}, block_sizes::BlockSizes{N}) = BlockArray{eltype(R), N, R}(blocks, block_sizes)
BlockArray{N, R <: AbstractArray}(blocks::Array{R, N}, block_sizes::Vararg{Vector{Int}, N}) = BlockArray{eltype(R), N, R}(blocks, BlockSizes(block_sizes))

typealias BlockMatrix{T, R} BlockArray{T, 2, R}
typealias BlockVector{T, R} BlockArray{T, 1, R}
typealias BlockVecOrMat{T, R} Union{BlockMatrix{T, R}, BlockVector{T, R}}


###########################
# AbstractArray Interface #
###########################

function Base.similar{T,N,T2}(block_array::BlockArray{T,N}, ::Type{T2})
    BlockArray(similar(block_array.blocks, Array{T2, N}), copy(block_array.block_sizes))
end

Base.size(arr::BlockArray) = map(sum, arr.block_sizes.sizes)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function Base.getindex(block_arr::BlockArray, i::Int)
    @boundscheck checkbounds(block_arr, i)
    @inbounds v = block_arr[global2blockindex(block_arr.block_sizes, (i,))]
    return v
end

function Base.getindex(block_arr::BlockArray, i::Int, j::Int)
    @boundscheck checkbounds(block_arr, i, j)
    @inbounds v = block_arr[global2blockindex(block_arr.block_sizes, (i,j))]
    return v
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

function Base.getindex{N}(block_arr::BlockArray, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[global2blockindex(block_arr.block_sizes, i)]
    return v
end


# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function Base.setindex!(block_arr::BlockArray, v, i::Int)
    @boundscheck checkbounds(block_arr, i)
    @inbounds block_arr[global2blockindex(block_arr.block_sizes, (i,))] = v
    return block_arr
end


function Base.setindex!(block_arr::BlockArray, v, i::Int, j::Int)
    @boundscheck checkbounds(block_arr, i, j)
    @inbounds block_arr[global2blockindex(block_arr.block_sizes, (i,j))] = v
    return block_arr
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #


function Base.setindex!{N}(block_arr::BlockArray, v, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr[global2blockindex(block_arr.block_sizes, i)] = v
    return block_arr
end


################################
# AbstractBlockArray Interface #
################################

nblocks(block_array::BlockArray) = nblocks(block_array.block_sizes)
blocksize{T, N}(block_array::BlockArray{T,N}, i::Vararg{Int, N}) = blocksize(block_array.block_sizes, i)


############
# Indexing #
############

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds function getblock{T}(block_arr::BlockArray{T,1}, block_i::Int)
    @boundscheck blockcheckbounds(block_arr, block_i)
    @inbounds v = block_arr.blocks[block_i]
    return v
end

@propagate_inbounds function getblock{T}(block_arr::BlockArray{T,2}, block_i::Int, block_j::Int)
    @boundscheck blockcheckbounds(block_arr, block_i, block_j)
    @inbounds v = block_arr.blocks[block_i, block_j]
    return v
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
@propagate_inbounds function getblock{T,N}(block_arr::BlockArray{T,N}, block::Vararg{Int, N})
    @boundscheck blockcheckbounds(block_arr, block...)
    block_arr.blocks[block...]
end

function _check_setblock!{T,N}(block_arr::BlockArray{T, N}, v, block::NTuple{N, Int})
    for i in 1:N
        if size(v, i) != block_arr.block_sizes[i, block[i]]
            throw(DimensionMismatch(string("tried to assign $(size(v)) array to ", blocksize(block_arr, block...), " block")))
        end
    end
end

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function setblock!{T}(block_arr::BlockArray{T, 1}, v, block_i::Int)
    @boundscheck blockcheckbounds(block_arr, block_i)
    @boundscheck _check_setblock!(block_arr, v, (block_i,))
    @inbounds block_arr.blocks[block_i] = v
    return block_arr
end

function setblock!{T}(block_arr::BlockArray{T, 2}, v, block_i::Int, block_j::Int)
      @boundscheck blockcheckbounds(block_arr, block_i, block_j)
    @boundscheck _check_setblock!(block_arr, v, (block_i, block_j))
    @inbounds block_arr.blocks[block_i, block_j] = v
    return block_arr
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

function setblock!{T, N}(block_arr::BlockArray{T, N}, v, block::Vararg{Int, N})
    @boundscheck blockcheckbounds(block_arr, block...)
    @boundscheck _check_setblock!(block_arr, v, block)
    @inbounds block_arr.blocks[block...] = v
    return block_arr
end

function Base.getindex{T,N}(block_array::BlockArray{T, N}, block_index::BlockIndex{N})
    return getblock(block_array, block_index.I...)[block_index.α...]
end

function Base.setindex!{T,N}(block_array::BlockArray{T, N}, v, block_index::BlockIndex{N})
    getblock(block_array, block_index.I...)[block_index.α...] = v
end

################
# Constructors #
################

"""
Constructs a `BlockArray` with uninitialized blocks from a block type.
"""
function BlockArray{N, R <: DataType}(block_type::R, block_sizes::Vararg{Vector{Int}, N})
    n_blocks = ntuple(i -> length(block_sizes[i]), Val{N})
    blocks = Array{block_type, N}(n_blocks...)
    BlockArray(blocks, block_sizes...)
end

@generated function BlockArray{T, N}(arr::AbstractArray{T, N}, block_sizes::Vararg{Vector{Int}, N})
    return quote
        for i in 1:N
            @assert sum(block_sizes[i]) == size(arr, i)
        end

        block_arr = BlockArray(typeof(arr), block_sizes...)
        _block_sizes = BlockSizes(block_sizes)

        @nloops $N i i->(1:length(block_sizes[i])) begin
            block_index = @ntuple $N i
            indices = globalrange(_block_sizes, block_index)
            setblock!(block_arr, arr[indices...], block_index...)
        end

        return block_arr
    end
end


########
# Misc #
########

@generated function Base.full{T,N,R}(block_array::BlockArray{T, N, R})
    # TODO: This will fail for empty block array
    return quote
        block_sizes = block_array.block_sizes
        arr = similar(block_array.blocks[1], size(block_array)...)

        @nloops $N i i->(1:length(block_sizes[i])) begin
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
        if size(block_array) != size(arr)
            throw(DimensionMismatch())
        end

        @nloops $N i i->(1:length(block_sizes[i])) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index)
            @inbounds block = getblock(block_array, block_index...)
            copy!(block, arr[indices...])
        end

        return block_array
    end
end

function Base.fill!(block_array::BlockArray, v)
    for block in block_array.blocks
        fill!(block, v)
    end
end