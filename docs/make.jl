using Documenter, BlockArrays

# Build documentation.
# ====================

makedocs(
    modules = [BlockArrays],
    format = :html,
    sitename = "BlockArrays.jl",
    doctest = false,
    strict = VERSION.major == 1 && sizeof(Int) == 8, # only strict mode on 1.0 and Int64
    pages = Any[
        "Home" => "index.md",
        "Manual" => [
            "man/abstractblockarrayinterface.md",
            "man/blockarrays.md",
            "man/pseudoblockarrays.md",
        ],
        "API" => [
            "lib/public.md",
            "lib/internals.md"
        ]
    ]
)

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    repo = "github.com/JuliaArrays/BlockArrays.jl.git",
    target = "build",
    julia = "nightly", # deploy from release bot
    deps = nothing,
    make = nothing
)
