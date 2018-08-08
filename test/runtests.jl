using BlockArrays, Compat.LinearAlgebra, Compat, Compat.Test

if VERSION < v"0.7-"
    const parentindices = parentindexes
    const axes1 = Base.indices1
else
    import Base: axes1
end

include("test_blockindices.jl")
include("test_blockarrays.jl")
include("test_blockviews.jl")
include("test_blockrange.jl")
include("test_blockarrayinterface.jl")

include("../docs/make.jl")
