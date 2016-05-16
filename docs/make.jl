using Documenter, BlockArrays

# Build documentation.
# ====================

makedocs(
    # options
    modules = [BlockArrays],
    clean   = true,
    doctest = false,
    )

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    # options
    deps = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/KristofferC/BlockArrays.jl.git"
)
