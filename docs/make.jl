using Documenter, BlockArrays

# Build documentation.
# ====================

DocMeta.setdocmeta!(BlockArrays, :DocTestSetup, :(using BlockArrays); recursive=true)

makedocs(
    modules = [BlockArrays],
    sitename = "BlockArrays.jl",
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
)
