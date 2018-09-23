__precompile__()

module BlockArrays
using Base.Cartesian
using LinearAlgebra

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blocksizes, blockcheckbounds, BlockBoundsError, BlockIndex
export BlockRange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef

import Base: @propagate_inbounds, Array, to_indices, to_index,
            unsafe_indices, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, show,
            broadcast, eltype, convert, broadcast,
            @_inline_meta, _maybetail, tail, @_propagate_inbounds_meta, reindex,
            RangeIndex, Int, Integer, Number,
            +, -, min, max, *, isless, in, copyto!, axes, @deprecate



import Base: (:), IteratorSize, iterate, axes1
import Base.Broadcast: broadcasted, DefaultArrayStyle
import LinearAlgebra: lmul!, rmul!, AbstractTriangular, HermOrSym, AdjOrTrans


include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("blockrange.jl")
include("views.jl")
include("blockindexrange.jl")
include("show.jl")
include("blockarrayinterface.jl")

include("deprecate.jl")

end # module
