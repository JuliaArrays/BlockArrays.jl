__precompile__()

module BlockArrays
using Base.Cartesian
using LinearAlgebra

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, blockaxes, blocksize, blocklength, blockcheckbounds, BlockBoundsError, BlockIndex
export BlockRange, blockedrange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat, mortar
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef, findblock, findblockindex

import Base: @propagate_inbounds, Array, to_indices, to_index,
            unsafe_indices, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, show,
            step, 
            broadcast, eltype, convert, similar,
            @_inline_meta, _maybetail, tail, @_propagate_inbounds_meta, reindex,
            RangeIndex, Int, Integer, Number,
            +, -, min, max, *, isless, in, copy, copyto!, axes, @deprecate,
            BroadcastStyle, checkbounds, throw_boundserror
using Base: ReshapedArray, dataids


import Base: (:), IteratorSize, iterate, axes1
import Base.Broadcast: broadcasted, DefaultArrayStyle, AbstractArrayStyle, Broadcasted
import LinearAlgebra: lmul!, rmul!, AbstractTriangular, HermOrSym, AdjOrTrans,
                        StructuredMatrixStyle


include("blockindices.jl")                        
include("blockaxis.jl")
include("abstractblockarray.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("views.jl")
include("show.jl")
include("blockarrayinterface.jl")
include("blockbroadcast.jl")
# include("linalg.jl")


end # module
