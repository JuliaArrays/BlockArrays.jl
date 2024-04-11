module BlockArrays
using Base.Cartesian
using LinearAlgebra, ArrayLayouts, FillArrays

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, eachblock, blocks
export blockaxes, blocksize, blocklength, blockcheckbounds, BlockBoundsError, BlockIndex
export blocksizes, blocklengths, blocklasts, blockfirsts, blockisequal
export BlockRange, blockedrange, BlockedUnitRange, BlockedOneTo

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat, mortar
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef, findblock, findblockindex

export khatri_rao, blockkron, BlockKron

export blockappend!, blockpush!, blockpushfirst!, blockpop!, blockpopfirst!

import Base: @propagate_inbounds, Array, to_indices, to_index,
            unsafe_indices, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, setindex!, ndims, show, view,
            step,
            broadcast, eltype, convert, similar,
            tail, reindex,
            RangeIndex, Int, Integer, Number, Tuple,
            +, -, *, /, \, min, max, isless, in, copy, copyto!, axes, @deprecate,
            BroadcastStyle, checkbounds, throw_boundserror,
            oneunit, ones, zeros, intersect, Slice, resize!
using Base: ReshapedArray, dataids, oneto
import Base: AbstractArray

_maybetail(::Tuple{}) = ()
_maybetail(t::Tuple) = tail(t)

import Base: (:), IteratorSize, iterate, axes1, strides, isempty
import Base.Broadcast: broadcasted, DefaultArrayStyle, AbstractArrayStyle, Broadcasted, broadcastable
import LinearAlgebra: lmul!, rmul!, AbstractTriangular, HermOrSym, AdjOrTrans,
                        StructuredMatrixStyle, cholesky, cholesky!, cholcopy, RealHermSymComplexHerm
import ArrayLayouts: zero!, MatMulVecAdd, MatMulMatAdd, MatLmulVec, MatLdivVec,
                        materialize!, MemoryLayout, sublayout, transposelayout, conjlayout,
                        triangularlayout, triangulardata, _inv, _copyto!, axes_print_matrix_row,
                        colsupport, rowsupport, sub_materialize, sub_materialize_axes, zero!

if VERSION ≥ v"1.11.0-DEV.21"
    using LinearAlgebra: UpperOrLowerTriangular
else
    const UpperOrLowerTriangular{T,S} = Union{LinearAlgebra.UpperTriangular{T,S},
                                              LinearAlgebra.UnitUpperTriangular{T,S},
                                              LinearAlgebra.LowerTriangular{T,S},
                                              LinearAlgebra.UnitLowerTriangular{T,S}}
end

include("blockindices.jl")
include("blockaxis.jl")
include("abstractblockarray.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("views.jl")
include("blocks.jl")

include("blockbroadcast.jl")
include("blockcholesky.jl")
include("blocklinalg.jl")
include("blockproduct.jl")
include("show.jl")
include("blockreduce.jl")
include("blockdeque.jl")
include("blockarrayinterface.jl")

@deprecate getblock(A::AbstractBlockArray{T,N}, I::Vararg{Integer, N}) where {T,N} view(A, Block(I))
@deprecate getblock!(X, A::AbstractBlockArray{T,N}, I::Vararg{Integer, N}) where {T,N} copyto!(X, view(A, Block(I)))
@deprecate setblock!(A::AbstractBlockArray{T,N}, v, I::Vararg{Integer, N}) where {T,N} (A[Block(I...)] = v)

if !isdefined(Base, :get_extension)
    include("../ext/BlockArraysLazyArraysExt.jl")
end

end # module
