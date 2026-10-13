module BlockArraysSparseArraysExt

using BlockArrays, SparseArrays
using BlockArrays.ArrayLayouts
using BlockArrays.LinearAlgebra
using BlockArrays: AbstractBlockVecOrMat
using BlockArrays.ArrayLayouts: Mul, Ldiv, UnknownLayout, AbstractStridedLayout
import Base: copy

# sparse preserves the block structure by wrapping the sparse storage in a BlockedArray
_sparse(A::BlockedArray) = sparse(A.blocks)
_sparse(A::AbstractVector) = sparsevec(A)
_sparse(A::AbstractMatrix{T}) where T = convert(SparseMatrixCSC{T}, A)
SparseArrays.sparse(A::AbstractBlockVecOrMat) = BlockedArray(_sparse(A), axes(A))

# forward linear algebra to the sparse storage, otherwise the generic dense fallbacks are used
const BlockedSparseMatrix{T} = BlockedMatrix{T,<:AbstractSparseMatrix{T}}

for f in (:factorize, :lu, :qr, :cholesky, :ldlt)
    @eval LinearAlgebra.$f(A::BlockedSparseMatrix; kwds...) = $f(A.blocks; kwds...)
end

_unblocked(A::BlockedArray) = A.blocks
_unblocked(A) = A

const SparseOrStridedLayout = Union{UnknownLayout,AbstractStridedLayout}

copy(M::Mul{UnknownLayout,<:SparseOrStridedLayout,<:BlockedSparseMatrix,<:AbstractVecOrMat}) =
    BlockedArray(M.A.blocks * _unblocked(M.B), axes(M))
copy(M::Mul{<:SparseOrStridedLayout,UnknownLayout,<:AbstractMatrix,<:BlockedSparseMatrix}) =
    BlockedArray(_unblocked(M.A) * M.B.blocks, axes(M))
copy(M::Mul{UnknownLayout,UnknownLayout,<:BlockedSparseMatrix,<:BlockedSparseMatrix}) =
    BlockedArray(M.A.blocks * M.B.blocks, axes(M))

copy(L::Ldiv{UnknownLayout,<:SparseOrStridedLayout,<:BlockedSparseMatrix,<:AbstractVecOrMat}) =
    BlockedArray(L.A.blocks \ _unblocked(L.B), axes(L))

end
