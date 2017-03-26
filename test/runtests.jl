using BlockArrays
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

include("test_blockindices.jl")
include("test_blockarrays.jl")

include("../docs/make.jl")
