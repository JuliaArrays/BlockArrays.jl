__precompile__()

module BlockArrays

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blockcheckbounds, BlockBoundsError, BlockIndex

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

import Base: @propagate_inbounds, Array
using Base.Cartesian

include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("convert.jl")
include("show.jl")


end # module
