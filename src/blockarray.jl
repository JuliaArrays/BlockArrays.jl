##############
# BlockArray #
##############

immutable BlockArray{T, N, R} <: AbstractBlockArray{T, N, R}
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

############
# Indexing #
############

function Base.getindex{T, N}(block_arr::BlockArray{T, N}, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr[global2blockindex(block_arr.block_sizes, i...)]
    return v
end

function Base.setindex!{T, N}(block_arr::BlockArray{T, N}, v, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr[global2blockindex(block_arr.block_sizes, i...)] = v
    return block_arr
end

@propagate_inbounds getblock{T,N}(block_arr::BlockArray{T,N}, block::Vararg{Int, N}) = block_arr.blocks[block...]

function setblock!{T, N, R}(block_arr::BlockArray{T, N, R}, v, block::Vararg{Int, N})
    @boundscheck begin # TODO: Check if this eliminates the boundscheck with @inbounds
        for i in 1:N
            if size(v, i) != block_arr.block_sizes[i, block[i]]
                throw(ArgumentError(string("attempt to assign a $(size(v)) array to a ",  ntuple(i -> block_arr.block_sizes[i][block[i]], Val{N}), " block")))
            end
        end
    end
    @inbounds block_arr.blocks[block...] = v
    return block_arr
end

@propagate_inbounds function Base.getindex{T,N}(block_array::BlockArray{T, N}, block_index::BlockIndex)
    return getblock(block_array, block_index.I...)[block_index.α...]
end

@propagate_inbounds function Base.setindex!{T,N}(block_array::BlockArray{T, N}, v, block_index::BlockIndex)
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
            indices = globalrange(_block_sizes, block_index...)
            setblock!(block_arr, arr[indices...], block_index...)
        end

        return block_arr
    end
end


########
# Misc #
########

"""
Converts from a `BlockArray` to a normal `Array`
"""
@generated function Base.full{T,N,R}(block_array::BlockArray{T, N, R})
    # TODO: This will fail for empty block array
    return quote
        block_sizes = block_array.block_sizes
        arr = similar(block_array.blocks[1], size(block_array)...)

        @nloops $N i i->(1:length(block_sizes[i])) begin
            block_index = @ntuple $N i
            indices = globalrange(block_sizes, block_index...)
            arr[indices...] = block_array[Block(block_index...)]
        end

        return arr
    end
end
