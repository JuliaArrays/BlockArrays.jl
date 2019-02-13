include("build.jl")

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    repo = "github.com/JuliaArrays/BlockArrays.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
