__precompile__()

module BlockArrays

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blockcheckbounds, BlockBoundsError, BlockIndex

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

import Base: @propagate_inbounds, Array, to_indices, to_index, indices,
            unsafe_indices, indices1, first, last, size, length, unsafe_length,
            getindex, show, start, next, done, @_inline_meta, _maybetail, tail,
            colon, broadcast, eltype

using Base.Cartesian
using Compat


include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("blockrange.jl")
include("views.jl")
include("convert.jl")
include("show.jl")


end # module
