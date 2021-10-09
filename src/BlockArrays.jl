module BlockArrays
using Base.Cartesian
using LinearAlgebra, ArrayLayouts, FillArrays

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, eachblock, blocks
export blockaxes, blocksize, blocklength, blockcheckbounds, BlockBoundsError, BlockIndex
export blocksizes, blocklengths, blocklasts, blockfirsts, blockisequal
export BlockRange, blockedrange, BlockedUnitRange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat, mortar
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef, findblock, findblockindex

export khatri_rao, blockkron, BlockKron

export blockappend!, blockpush!, blockpushfirst!, blockpop!, blockpopfirst!

import Base: @propagate_inbounds, Array, to_indices, to_index,
            unsafe_indices, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, ndims, show,
            step, 
            broadcast, eltype, convert, similar,
            @_inline_meta, _maybetail, tail, @_propagate_inbounds_meta, reindex,
            RangeIndex, Int, Integer, Number,
            +, -, *, /, \, min, max, isless, in, copy, copyto!, axes, @deprecate,
            BroadcastStyle, checkbounds, throw_boundserror, 
            ones, zeros, intersect, Slice, resize!
using Base: ReshapedArray, dataids


import Base: (:), IteratorSize, iterate, axes1, strides, isempty
import Base.Broadcast: broadcasted, DefaultArrayStyle, AbstractArrayStyle, Broadcasted, broadcastable
import LinearAlgebra: lmul!, rmul!, AbstractTriangular, HermOrSym, AdjOrTrans,
                        StructuredMatrixStyle
import ArrayLayouts: _fill_lmul!, MatMulVecAdd, MatMulMatAdd, MatLmulVec, MatLdivVec,
                        materialize!, MemoryLayout, sublayout, transposelayout, conjlayout, 
                        triangularlayout, triangulardata, _inv, _copyto!, axes_print_matrix_row,
                        colsupport, rowsupport, sub_materialize

include("blockindices.jl")                        
include("blockaxis.jl")
include("abstractblockarray.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("views.jl")
include("blocks.jl")

include("blockbroadcast.jl")
include("blocklinalg.jl")
include("blockproduct.jl")
include("show.jl")
include("blockreduce.jl")
include("blockdeque.jl")
include("blockarrayinterface.jl")

@deprecate getblock(A::AbstractBlockArray{T,N}, I::Vararg{Integer, N}) where {T,N} view(A, Block(I))
@deprecate getblock!(X, A::AbstractBlockArray{T,N}, I::Vararg{Integer, N}) where {T,N} copyto!(X, view(A, Block(I)))
@deprecate setblock!(A::AbstractBlockArray{T,N}, v, I::Vararg{Integer, N}) where {T,N} (A[Block(I...)] = v)


end # module
