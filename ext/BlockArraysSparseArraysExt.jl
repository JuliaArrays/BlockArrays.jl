module BlockArraysSparseArraysExt

using BlockArrays, SparseArrays
using BlockArrays.ArrayLayouts
using BlockArrays.LinearAlgebra
using BlockArrays: AbstractBlockVecOrMat, AbstractBlockLayout, AbstractBlockedUnitRange, BlockSlice, NoncontiguousBlockSlice
using BlockArrays.ArrayLayouts: Mul, Ldiv, UnknownLayout, AbstractStridedLayout
using BlockArrays.LinearAlgebra: HermOrSym, AdjOrTrans
import Base: copy, \

# sparse preserves the block structure by wrapping the sparse storage in a BlockedArray
_sparse(A::BlockedArray) = sparse(A.blocks)
_sparse(A::AbstractVector) = sparsevec(A)
_sparse(A::AbstractMatrix{T}) where T = convert(SparseMatrixCSC{T}, A)
SparseArrays.sparse(A::AbstractBlockVecOrMat) = BlockedArray(_sparse(A), axes(A))

# forward linear algebra to the sparse storage, otherwise the generic dense fallbacks are used
const BlockedSparseMatrix{T} = BlockedMatrix{T,<:AbstractSparseMatrix{T}}
const BlockedSparseSymOrHerm{T} = Union{Symmetric{T,<:BlockedSparseMatrix}, Hermitian{T,<:BlockedSparseMatrix}}
const BlockedSparseAdjOrTrans{T} = Union{Adjoint{T,<:BlockedSparseMatrix}, Transpose{T,<:BlockedSparseMatrix}}
const BlockedSparseMatrixLike{T} = Union{BlockedSparseMatrix{T}, BlockedSparseSymOrHerm{T}, BlockedSparseAdjOrTrans{T}}

_unblocked(A::BlockedArray) = A.blocks
_unblocked(A::Adjoint{<:Any,<:BlockedArray}) = parent(A).blocks'
_unblocked(A::Transpose{<:Any,<:BlockedArray}) = transpose(parent(A).blocks)
_unblocked(A::Symmetric{<:Any,<:BlockedArray}) = Symmetric(parent(A).blocks, Symbol(A.uplo))
_unblocked(A::Hermitian{<:Any,<:BlockedArray}) = Hermitian(parent(A).blocks, Symbol(A.uplo))
_unblocked(A) = A

# matches the signature of ArrayLayouts' overloads for RealHermSymComplexHerm{<:Real,<:LayoutMatrix}
const BlockedSparseRealHermSymComplexHerm{T<:Real} =
    Union{Hermitian{T,<:BlockedSparseMatrix}, Hermitian{Complex{T},<:BlockedSparseMatrix}, Symmetric{T,<:BlockedSparseMatrix}}

for f in (:factorize, :lu, :qr, :cholesky, :ldlt)
    @eval LinearAlgebra.$f(A::BlockedSparseMatrix; kwds...) = $f(A.blocks; kwds...)
end
for f in (:factorize, :lu, :cholesky, :ldlt)
    @eval LinearAlgebra.$f(A::BlockedSparseAdjOrTrans; kwds...) = $f(_unblocked(A); kwds...)
end
for f in (:factorize, :cholesky, :ldlt)
    @eval LinearAlgebra.$f(A::BlockedSparseRealHermSymComplexHerm; kwds...) = $f(_unblocked(A); kwds...)
end
# lu/qr of wrapped sparse matrices may not use UMFPACK/SPQR, so convert first
LinearAlgebra.lu(A::BlockedSparseSymOrHerm; kwds...) = lu(sparse(_unblocked(A)); kwds...)
LinearAlgebra.qr(A::BlockedSparseAdjOrTrans; kwds...) = qr(sparse(_unblocked(A)); kwds...)
LinearAlgebra.qr(A::BlockedSparseRealHermSymComplexHerm; kwds...) = qr(sparse(_unblocked(A)); kwds...)

# products of symmetric sparse wrappers with sparse matrices are slow, so convert first
const SparseOrAdjOrTrans = Union{AbstractSparseMatrix, AdjOrTrans{<:Any,<:AbstractSparseMatrix}}
const SparseSymOrHerm = HermOrSym{<:Any,<:AbstractSparseMatrix}
_spmul(A, B) = A * B
_spmul(A::SparseSymOrHerm, B::SparseOrAdjOrTrans) = sparse(A) * B
_spmul(A::SparseOrAdjOrTrans, B::SparseSymOrHerm) = A * sparse(B)
_spmul(A::SparseSymOrHerm, B::SparseSymOrHerm) = sparse(A) * sparse(B)

const SparseOrStridedLayout = Union{UnknownLayout,AbstractStridedLayout}

copy(M::Mul{UnknownLayout,<:SparseOrStridedLayout,<:BlockedSparseMatrixLike,<:AbstractVecOrMat}) =
    BlockedArray(_spmul(_unblocked(M.A), _unblocked(M.B)), axes(M))
copy(M::Mul{<:SparseOrStridedLayout,UnknownLayout,<:AbstractMatrix,<:BlockedSparseMatrixLike}) =
    BlockedArray(_spmul(_unblocked(M.A), _unblocked(M.B)), axes(M))
copy(M::Mul{UnknownLayout,UnknownLayout,<:BlockedSparseMatrixLike,<:BlockedSparseMatrixLike}) =
    BlockedArray(_spmul(_unblocked(M.A), _unblocked(M.B)), axes(M))

copy(L::Ldiv{UnknownLayout,<:SparseOrStridedLayout,<:BlockedSparseMatrixLike,<:AbstractVecOrMat}) =
    BlockedArray(_unblocked(L.A) \ _unblocked(L.B), axes(L))

# indexing preserves sparsity: views of a sparse BlockedArray index the sparse storage,
# and views of whole blocks of a BlockArray with sparse blocks copy the selected blocks
_parentindex(I::AbstractUnitRange{<:Integer}) = first(I):last(I)
_parentindex(I::AbstractVector{<:Integer}) = collect(I)
_parentindex(I) = I
ArrayLayouts.sub_materialize(::UnknownLayout, V::SubArray{<:Any,N,<:BlockedArray{<:Any,N,<:AbstractSparseArray}}, ax) where N =
    BlockedArray(parent(V).blocks[map(_parentindex, parentindices(V))...], ax)

const WholeBlockSlice = Union{BlockSlice{<:Block{1}}, BlockSlice{<:BlockRange{1}},
                              NoncontiguousBlockSlice{<:AbstractVector{<:Block{1}}}, Base.Slice{<:AbstractBlockedUnitRange}}
_blockindices(I::BlockSlice{<:Block{1}}) = Int(I.block):Int(I.block)
_blockindices(I::Union{BlockSlice{<:BlockRange{1}},NoncontiguousBlockSlice}) = Int.(I.block)
_blockindices(I::Base.Slice) = axes(blocks(I.indices), 1)
const BlockArrayWholeBlockView{N} = SubArray{<:Any,N,<:BlockArray{<:Any,N,<:AbstractArray{<:AbstractSparseArray,N}},<:NTuple{N,WholeBlockSlice}}
_blocksparse_materialize(V, ax) = mortar(map(copy, blocks(parent(V))[map(_blockindices, parentindices(V))...]), ax)
ArrayLayouts.sub_materialize(::AbstractBlockLayout, V::BlockArrayWholeBlockView, ax) = _blocksparse_materialize(V, ax)
ArrayLayouts.sub_materialize(::UnknownLayout, V::BlockArrayWholeBlockView, ax) = _blocksparse_materialize(V, ax)

# \ on these wrappers is not routed through ArrayLayouts. Other right-hand sides
# use LinearAlgebra's \, which calls the factorize overloads above.
\(A::Union{BlockedSparseSymOrHerm,BlockedSparseAdjOrTrans}, B::StridedVecOrMat) = ArrayLayouts.ldiv(A, B)

end
