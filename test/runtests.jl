using BlockArrays

if VERSION > v"0.7.0-DEV.2004"
    using Test
else
    using Base.Test
end


include("test_blockindices.jl")
include("test_blockarrays.jl")
include("test_blockviews.jl")
include("test_blockrange.jl")

include("../docs/make.jl")
