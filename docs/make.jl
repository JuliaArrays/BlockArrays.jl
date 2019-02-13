include("build.jl")

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    repo = "github.com/JuliaArrays/BlockArrays.jl.git",
    target = "build",
    julia = "nightly", # deploy from release bot
    deps = nothing,
    make = nothing
)
