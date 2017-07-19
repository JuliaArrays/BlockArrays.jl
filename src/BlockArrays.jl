__precompile__()

module BlockArrays

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blockcheckbounds, BlockBoundsError, BlockIndex

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

import Base: @propagate_inbounds, Array, to_indices, indices, unsafe_indices,
            indices1, first, last, size, length, unsafe_length,
            getindex, show, start, next, done, @_inline_meta, _maybetail, tail
            
using Base.Cartesian


include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("views.jl")
include("show.jl")


end # module
