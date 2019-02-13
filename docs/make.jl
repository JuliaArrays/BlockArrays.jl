include("build.jl")

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    repo = "github.com/JuliaArrays/BlockArrays.jl.git",
)
