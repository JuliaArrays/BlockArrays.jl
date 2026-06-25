module BlockArraysBandedMatricesExt

using BandedMatrices, BlockArrays
using BlockArrays.ArrayLayouts
using BlockArrays.LinearAlgebra
import BandedMatrices: isbanded, AbstractBandedLayout, BandedColumns, bandeddata, bandwidths
import BlockArrays: blockcolsupport, blockrowsupport, AbstractBlockedUnitRange, BlockLayout, BlockSlice1
import ArrayLayouts: sub_materialize, _copyto!
import Base: BroadcastStyle


bandeddata(P::BlockedMatrix) = bandeddata(P.blocks)
bandwidths(P::BlockedMatrix) = bandwidths(P.blocks)

function blockcolsupport(::AbstractBandedLayout, B, j)
    m,n = axes(B)
    cs = colsupport(B,n[j])
    findblock(m,first(cs)):findblock(m,last(cs))
end

function blockrowsupport(::AbstractBandedLayout, B, k)
    m,n = axes(B)
    rs = rowsupport(B,m[k])
    findblock(n,first(rs)):findblock(n,last(rs))
end

# ambiguity
sub_materialize(::AbstractBandedLayout, V, ::Tuple{AbstractBlockedUnitRange,Base.OneTo{Int}}) = BandedMatrix(V)
sub_materialize(::AbstractBandedLayout, V, ::Tuple{Base.OneTo{Int},AbstractBlockedUnitRange}) = BandedMatrix(V)
sub_materialize(::AbstractBandedLayout, V, ::Tuple{AbstractBlockedUnitRange,AbstractBlockedUnitRange}) = BandedMatrix(V)


# _copyto!
# disabled as not clear its needed and used undefined colblockbandwidths

# function _copyto!(_, ::BlockLayout{<:BandedColumns}, dest::AbstractMatrix, src::AbstractMatrix)
#     if !blockisequal(axes(dest), axes(src))
#         copyto!(BlockedArray(dest, axes(src)), src)
#         return dest
#     end

#     srcB = blocks(src)
#     srcD = bandeddata(srcB)

#     dl, du = colblockbandwidths(dest)
#     sl, su = bandwidths(srcB)
#     M,N = size(srcB)
#     # Source matrix must fit within bands of destination matrix
#     all(dl .≥ min(sl,M-1)) && all(du .≥ min(su,N-1)) || throw(BandError(dest))

#     for J = 1:N
#         for K = max(1,J-du[J]):min(J-su-1,M)
#             zero!(view(dest,Block(K),Block(J)))
#         end
#         for K = max(1,J-su):min(J+sl,M)
#             copyto!(view(dest,Block(K),Block(J)), srcD[K-J+su+1,J])
#         end
#         for K = max(1,J+sl+1):min(J+dl[J],M)
#             zero!(view(dest,Block(K),Block(J)))
#         end
#     end
#     dest
# end

# function _copyto!(_, ::BlockLayout{<:AbstractBandedLayout}, dest::AbstractMatrix, src::AbstractMatrix)
#     if !blockisequal(axes(dest), axes(src))
#         copyto!(BlockedArray(dest, axes(src)), src)
#         return dest
#     end

#     srcB = blocks(src)

#     dl, du = colblockbandwidths(dest)
#     sl, su = bandwidths(srcB)
#     M,N = size(srcB)
#     # Source matrix must fit within bands of destination matrix
#     all(dl .≥ min(sl,M-1)) && all(du .≥ min(su,N-1)) || throw(BandError(dest))

#     for J = 1:N
#         for K = max(1,J-du[J]):min(J-su-1,M)
#             zero!(view(dest,Block(K),Block(J)))
#         end
#         for K = max(1,J-su):min(J+sl,M)
#             copyto!(view(dest,Block(K),Block(J)), inbands_getindex(srcB, K, J))
#         end
#         for K = max(1,J+sl+1):min(J+dl[J],M)
#             zero!(view(dest,Block(K),Block(J)))
#         end
#     end
#     dest
# end

## WARNING: type piracy
# BroadcastStyle(::Type{<:SubArray{<:Any,2,<:BlockedMatrix{<:Any,<:Diagonal}, <:Tuple{<:BlockSlice1,<:BlockSlice1}}}) = BandedStyle()


end
