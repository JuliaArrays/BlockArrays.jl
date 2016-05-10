####################
# PseudoBlockArray #
####################

"""
A `PseudoBlockArray` is similar to a `BlockArray` except the full array is stored contigously instead of block by block.
"""
immutable PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N, R}
    blocks::R
    block_sizes::BlockSizes{N}
    function PseudoBlockArray(blocks::R, block_sizes::BlockSizes{N})
        for i in 1:N
            @assert sum(block_sizes[i]) == size(blocks, i)
        end
        @assert ndims(R) == N
        @assert eltype(T) == T
        new(blocks, block_sizes)
    end
end

typealias PseudoBlockMatrix{T, R} PseudoBlockArray{T, 2, R}
typealias PseudoBlockVector{T, R} PseudoBlockArray{T, 1, R}
typealias PseudoBlockVecOrMat{T, R} Union{PseudoBlockMatrix{T, R}, PseudoBlockVector{T, R}}

# Auxilary outer constructor
PseudoBlockArray{N, R}(blocks::R, block_sizes::BlockSizes{N}) = PseudoBlockArray{eltype(R), N, R}(blocks, block_sizes)
PseudoBlockArray{N, R}(blocks::R, block_sizes::Vararg{Vector{Int}, N}) = PseudoBlockArray(blocks, BlockSizes(block_sizes))


###########################
# AbstractArray Interface #
###########################

function Base.similar{T,N,T2}(block_array::PseudoBlockArray{T,N}, ::Type{T2})
    BlockArray(similar(block_array.blocks, T2), copy(block_array.block_sizes))
end

############
# Indexing #
############

function Base.getindex{T, N}(block_arr::PseudoBlockArray{T, N}, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr.blocks[i...]
    return v
end

function Base.setindex!{T, N}(block_arr::PseudoBlockArray{T, N}, v, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr.blocks[i...] = v
    return block_arr
end

function getblock{T,N}(block_arr::PseudoBlockArray{T,N}, block::Vararg{Int, N})
    range = globalrange(block_arr.block_sizes, block...)
    return block_arr.blocks[range...]
end

function setblock!{T, N, R}(block_arr::PseudoBlockArray{T, N, R}, v, block::Vararg{Int, N})
    @boundscheck begin # TODO: Check if this eliminates the boundscheck with @inbounds
        for i in 1:N
            if size(v, i) != block_arr.block_sizes[i, block[i]]
                throw(ArgumentError(string("attempt to assign a $(size(v)) array to a ",  ntuple(i -> block_arr.block_sizes[i][block[i]], Val{N}), " block")))
            end
        end
    end
    range = globalrange(block_arr.block_sizes, block...)
    @inbounds block_arr.blocks[range...] = v
    return block_arr
end

########
# Misc #
########

"""
Converts from a `PseudoBlockArray` to a normal `Array`
"""
function Base.full{T,N,R}(block_array::PseudoBlockArray{T, N, R})
    return block_array.blocks
end
