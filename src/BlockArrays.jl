__precompile__()

module BlockArrays
using Base.Cartesian
using Compat
if VERSION ≥ v"0.7.0-DEV.3465"
    using LinearAlgebra
end

# AbstractBlockArray interface exports
export AbstractBlockArray, AbstractBlockMatrix, AbstractBlockVector, AbstractBlockVecOrMat
export Block, getblock, getblock!, setblock!, nblocks, blocksize, blockcheckbounds, BlockBoundsError, BlockIndex
export BlockRange

export BlockArray, BlockMatrix, BlockVector, BlockVecOrMat
export PseudoBlockArray, PseudoBlockMatrix, PseudoBlockVector, PseudoBlockVecOrMat

export undef_blocks, undef

import Base: @propagate_inbounds, Array, to_indices, to_index, indices,
            unsafe_indices, indices1, first, last, size, length, unsafe_length,
            unsafe_convert,
            getindex, show, start, next, done,
            broadcast, eltype, convert, broadcast,
            @_inline_meta, _maybetail, tail, @_propagate_inbounds_meta, reindex,
            RangeIndex, Int, Integer, Number,
            +, -, min, max, *, isless, in

import Compat: copyto!, axes

if VERSION < v"0.7-"
    import Base: colon, iteratorsize
    const parentindices = parentindexes
else
    import Base: (:), IteratorSize, iterate
    import Base.Broadcast: broadcasted, DefaultArrayStyle
end

include("abstractblockarray.jl")

include("blocksizes.jl")
include("blockindices.jl")
include("blockarray.jl")
include("pseudo_blockarray.jl")
include("blockrange.jl")
include("views.jl")
include("blockindexrange.jl")
include("convert.jl")
include("show.jl")
include("deprecate.jl")

end # module
