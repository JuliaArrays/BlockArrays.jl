module BlockArraysBandedMatricesExt

using BandedMatrices, BlockArrays
import BandedMatrices: isbanded, AbstractBandedLayout, bandeddata, bandwidths
import BlockArrays: blockcolsupport, blockrowsupport, sub_materialize


bandeddata(P::PseudoBlockMatrix) = bandeddata(P.blocks)
bandwidths(P::PseudoBlockMatrix) = bandwidths(P.blocks)

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
sub_materialize(::AbstractBandedLayout, V, ::Tuple{BlockedUnitRange,Base.OneTo{Int}}) = BandedMatrix(V)
sub_materialize(::AbstractBandedLayout, V, ::Tuple{Base.OneTo{Int},BlockedUnitRange}) = BandedMatrix(V)


end
