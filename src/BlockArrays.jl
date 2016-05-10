module BlockArrays

export AbstractBlockArray, BlockArray, PseudoBlockArray, Block, getblock, getblock!, setblock!

import Base: @propagate_inbounds
using Base.Cartesian

abstract AbstractBlockArray{T, N, R} <: AbstractArray{T, N}

typealias AbstractBlockMatrix{T, R} AbstractBlockArray{T, 2, R}
typealias AbstractBlockVector{T, R} AbstractBlockArray{T, 1, R}
typealias AbstractBlockVecOrMat{T, R} Union{AbstractBlockMatrix{T, R}, AbstractBlockVector{T, R}}

nblocks(block_array::AbstractBlockArray) = nblocks(block_array.block_sizes)
nblocks(block_array::AbstractBlockArray, i::Int) = nblocks(block_array.block_sizes, i)

Base.similar{T,N}(block_array::AbstractBlockArray{T,N}) = similar(block_array, T)
Base.size(arr::AbstractBlockArray) = map(sum, arr.block_sizes.sizes)

Base.linearindexing{BA <: AbstractBlockArray}(::Type{BA}) = Base.LinearSlow()

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("block.jl")
include("operations.jl")
include("utilities.jl")
include("show.jl")

end # module
