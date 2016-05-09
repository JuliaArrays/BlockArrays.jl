module BlockArrays

export BlockArray, Block, getblock, setblock!, nblocks

import Base: @propagate_inbounds
using Base.Cartesian

##############
# BlockSizes #
##############
"""
Keeps track of the sizes of all the blocks in the `BlockArray`
"""
immutable BlockSizes{N}
    sizes::NTuple{N, Vector{Int}}
end

Base.(:(==))(a::BlockSizes, b::BlockSizes) = a.sizes == b.sizes

BlockSizes{N}(sizes::Vararg{Vector{Int}, N}) = BlockSizes(sizes)
Base.getindex(block_sizes::BlockSizes, i) = block_sizes.sizes[i]
Base.getindex(block_sizes::BlockSizes, i, j) = block_sizes.sizes[i][j]

function Base.show{N}(io::IO, block_sizes::BlockSizes{N})
    if N == 0
        print(io, "[]")
    else
        print(io, block_sizes.sizes[1])
        for i in 2:N
            print(io, "×", block_sizes.sizes[i])
        end
    end
end

nblocks{N}(block_sizes::BlockSizes{N}) = ntuple(i -> length(block_sizes[i]), Val{N})
nblocks(block_sizes::BlockSizes, i::Int) = length(block_sizes[i])


"""
Computes the global range of an Array that corresponds to a given block_index
"""
function globalrange{N}(block_sizes::BlockSizes, block_index::Vararg{Int, N})
    start_indices = ntuple(i -> 1 + _cumsum(block_sizes[i], 1:block_index[i]-1), Val{N})
    indices = ntuple(i -> start_indices[i]:start_indices[i] + block_sizes[i, block_index[i]] - 1, Val{N})
end


##############
# BlockArray #
##############

immutable BlockArray{T, N, R} <: AbstractArray{T, N}
    blocks::Array{R, N}
    block_sizes::BlockSizes{N}
    size::NTuple{N, Int}
    function BlockArray(blocks::Array{R, N}, block_sizes::BlockSizes{N},size::NTuple{N, Int})
        @assert ndims(R) == N
        @assert eltype(T) == T
        new(blocks, block_sizes, size)
    end
end

typealias BlockMatrix{T, R} BlockArray{T, 2, R}
typealias BlockVector{T, R} BlockArray{T, 1, R}
typealias BlockVecOrMat{T, R} Union{BlockMatrix{T, R}, BlockVector{T, R}}

include("blockindices.jl")
include("operations.jl")
include("utilities.jl")
include("show.jl")

nblocks(block_array::BlockArray) = nblocks(block_array.block_sizes)
nblocks(block_array::BlockArray, i::Int) = nblocks(block_array.block_sizes, i)


"""
Constructs a `BlockArray` with uninitialized blocks from a block type.
"""
function BlockArray{N, R <: DataType}(block_type::R, block_sizes::Vararg{Vector{Int}, N})
    n_blocks = ntuple(i -> length(block_sizes[i]), Val{N})
    blocks = Array{block_type, N}(n_blocks...)
    BlockArray(blocks, block_sizes...)
end

"""
Constructs a `BlockArray` with given blocks.
"""
function BlockArray{N, R <: AbstractArray}(blocks::Array{R, N}, block_sizes::Vararg{Vector{Int}, N})
    _size = map(sum, block_sizes)
    BlockArray{eltype(R), N, R}(blocks, BlockSizes(block_sizes), _size)
end

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

Base.size(arr::BlockArray) = arr.size
Base.linearindexing(::Type{BlockArray}) = Base.LinearSlow()
function Base.similar{T,N,T2}(block_array::BlockArray{T,N}, ::Type{T2})
    BlockArray(similar(block_array.blocks, Array{T2, N}), ntuple(i->copy(block_array.block_sizes[i]), Val{N})...)
end

Base.similar{T,N}(block_array::BlockArray{T,N}) = similar(block_array, T)

@propagate_inbounds getblock{T,N}(block_arr::BlockArray{T,N}, block::Vararg{Int, N}) = block_arr.blocks[block...]

function setblock!{T, N, R}(block_arr::BlockArray{T, N, R}, v::R, idx::Vararg{Int, N})
    @boundscheck begin # TODO: Check if this eliminates the boundscheck with @inbounds
        block_size = ntuple(i -> block_arr.block_sizes[i][idx[i]], Val{N})
        if size(v) != block_size
            throw(ArgumentError("attempt to assign a $(size(v)) array to a $block_size block"))
        end
    end
    @inbounds block_arr.blocks[idx...] = v
    return block_arr
end

##############################
# Indexing with a Block type #
##############################
immutable Block{N}
    n::NTuple{N, Int}
end

Block{N}(n::Vararg{Int, N}) = Block{N}(n)

@propagate_inbounds Base.setindex!{T,N,R}(block_arr::BlockArray{T,N,R}, v::R, block::Block{N}) =  setblock!(block_arr, v, block.n...)
@propagate_inbounds Base.getindex{T,N}(block_arr::BlockArray{T,N}, block::Block{N}) = getblock(block_arr, block.n...)


################
# Constructors #
################

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

end # module
