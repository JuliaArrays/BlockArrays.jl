__precompile__()

module BlockArrays
using Base.Cartesian
using Compat

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blockcheckbounds, BlockBoundsError, BlockIndex
export BlockRange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export uninitialized_blocks, UninitializedBlocks, uninitialized, Uninitialized

import Base: @propagate_inbounds, Array, to_indices, to_index, indices,
            unsafe_indices, indices1, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, show, start, next, done,
            colon, broadcast, eltype, iteratorsize, convert, broadcast,
            @_inline_meta, _maybetail, tail, @_propagate_inbounds_meta, reindex

import Base: +, -, min, max, *, isless



include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("blockrange.jl")
include("views.jl")
include("convert.jl")
include("show.jl")
include("deprecate.jl")

end # module
