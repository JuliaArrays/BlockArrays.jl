module BlockArrays

export BlockArray, Block, getblock, setblock!

import Base: @propagate_inbounds
using Base.Cartesian

immutable BlockArray{T, N} <: AbstractArray{T, N}
    blocks::Array{Array{T, N}, N}
    block_sizes::NTuple{N, Vector{Int}}
    size::NTuple{N, Int}

end

typealias BlockMatrix{T} BlockArray{T, 2}
typealias BlockVector{T} BlockArray{T, 1}
typealias BlockMatOrVec{T} = Union{BlockMatrix{T}, BlockVector{T}}

include("blockindices.jl")
include("operations.jl")
include("utilities.jl")

function Base.getindex{T, N}(block_arr::BlockArray{T, N}, i::Vararg{Int, N})
    block_arr[global2blockindex(block_arr.block_sizes, i)]
end

function Base.setindex!{T, N}(block_arr::BlockArray{T, N}, v, i::Vararg{Int, N})
    block_arr[global2blockindex(block_arr.block_sizes, i)] = v
end


function BlockArray{T,N}(::Type{T}, block_sizes::Vararg{Vector{Int}, N})
    n_blocks = ntuple(i -> length(block_sizes[i]), Val{N})
    blocks = Array{Array{T, N}, N}(n_blocks...)
    _size = map(sum, block_sizes)
    return BlockArray(blocks, block_sizes, _size)
end

Base.size(arr::BlockArray) = arr.size
Base.linearindexing(::Type{BlockArray}) = Base.LinearSlow()
function Base.similar{T,N,T2}(block_array::BlockArray{T,N}, ::Type{T2})
    BlockArray(similar(block_array.blocks, Array{T2, N}), ntuple(i->copy(block_array.block_sizes[i]), Val{N}), block_array.size)
end

Base.similar{T,N}(block_array::BlockArray{T,N}) = similar(block_array, T)

@propagate_inbounds getblock{T,N}(block_arr::BlockArray{T,N}, block::Vararg{Int, N}) = block_arr.blocks[block...]

function setblock!{T, N}(block_arr::BlockArray{T, N}, v::Array{T,N}, idx::Vararg{Int, N})
    @boundscheck begin # TODO: Check if this eliminates the boundscheck with @inbounds
        block_size = ntuple(i -> block_arr.block_sizes[i][idx[i]], Val{N})
        if size(v) != block_size
            throw(ArgumentError("attempt to assign a $(size(v)) array to a $block_size block"))
        end
    end
    block_arr.blocks[idx...] = v
end

##############################
# Indexing with a Block type #
##############################
immutable Block{N}
    n::NTuple{N, Int}
end

Block{N}(n::Vararg{Int, N}) = Block{N}(n)

@propagate_inbounds Base.setindex!{T,N}(block_arr::BlockArray{T,N}, v::Array{T,N}, block::Block{N}) =  setblock!(block_arr, v, block.n...)
@propagate_inbounds Base.getindex{T,N}(block_arr::BlockArray{T,N}, block::Block{N}) = getblock(block_arr, block.n...)


################
# Constructors #
################

@inline function set_block!{N}(blocks, arr, block_sizes, block_index::Vararg{Int, N})
    indices = compute_indices(block_sizes, block_index...)
    blocks[block_index...] = arr[indices...]
    return
end

@inline function compute_indices{N}(block_sizes, block_index::Vararg{Int, N})
    start_indices = ntuple(i -> 1 + _cumsum(block_sizes[i], 1:block_index[i]-1), Val{N})
    indices = ntuple(i -> start_indices[i]:start_indices[i] + block_sizes[i][block_index[i]] - 1, Val{N})
end

@generated function BlockArray{T,N}(arr::Array{T,N}, block_sizes::Vararg{Vector{Int}, N})
    return quote
        for i in 1:N
            @assert sum(block_sizes[i]) == size(arr, i)
        end

        n_blocks = ntuple(i -> length(block_sizes[i]), Val{N})
        blocks = Array{Array{T, N}, N}(n_blocks...)
        _size = map(sum, block_sizes)

        @nloops $N i i->(1:length(block_sizes[i])) begin
            set_block!(blocks, arr, block_sizes, (@ntuple $N i)...)
        end

        return BlockArray(blocks, block_sizes, _size)
    end
end

end # module
