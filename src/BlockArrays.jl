module BlockArrays
using Base.Cartesian
using LinearAlgebra, ArrayLayouts

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, eachblock
export blockaxes, blocksize, blocklength, blockcheckbounds, BlockBoundsError, BlockIndex
export blocklengths, blocklasts, blockfirsts, blockisequal
export BlockRange, blockedrange, BlockedUnitRange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat, mortar
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef, findblock, findblockindex

export khatri_rao

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


import Base: (:), IteratorSize, iterate, axes1, strides
import Base.Broadcast: broadcasted, DefaultArrayStyle, AbstractArrayStyle, Broadcasted
import LinearAlgebra: lmul!, rmul!, AbstractTriangular, HermOrSym, AdjOrTrans,
                        StructuredMatrixStyle
import ArrayLayouts: _fill_lmul!, MatMulVecAdd, MatMulMatAdd, MatLmulVec, MatLdivVec,
                        materialize!, MemoryLayout, sublayout, transposelayout, conjlayout, 
                        triangularlayout, triangulardata, _inv

include("blockindices.jl")                        
include("blockaxis.jl")
include("abstractblockarray.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("views.jl")
include("show.jl")
include("blockarrayinterface.jl")
include("blockbroadcast.jl")
include("blocklinalg.jl")
include("blockproduct.jl")

end # module
