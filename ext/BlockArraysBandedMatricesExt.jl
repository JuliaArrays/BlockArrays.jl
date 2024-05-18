module BlockArraysBandedMatricesExt

using BandedMatrices, BlockArrays
using BlockArrays.ArrayLayouts
import BandedMatrices: isbanded, AbstractBandedLayout, bandeddata, bandwidths
import BlockArrays: blockcolsupport, blockrowsupport, AbstractBlockedUnitRange
import ArrayLayouts: sub_materialize


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


end
