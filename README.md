# BlockArrays.jl

[![Build Status](https://github.com/JuliaArrays/BlockArrays.jl/workflows/CI/badge.svg)](https://github.com/JuliaArrays/BlockArrays.jl/actions)
[![codecov](https://codecov.io/gh/JuliaArrays/BlockArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaArrays/BlockArrays.jl) [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaArrays.github.io/BlockArrays.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaArrays.github.io/BlockArrays.jl/dev)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![deps](https://juliahub.com/docs/General/BlockArrays/stable/deps.svg)](https://juliahub.com/ui/Packages/General/BlockArrays?t=2)
[![version](https://juliahub.com/docs/General/BlockArrays/stable/version.svg)](https://juliahub.com/ui/Packages/General/BlockArrays)
[![pkgeval](https://juliahub.com/docs/General/BlockArrays/stable/pkgeval.svg)](https://juliahub.com/ui/Packages/General/BlockArrays)

A block array is a partition of an array into blocks or subarrays, see [wikipedia](https://en.wikipedia.org/wiki/Block_matrix) for a more extensive description. This package has two purposes. Firstly, it defines an interface for an `AbstractBlockArray` block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.

Secondly, it also implements two different type of block arrays that follow the `AbstractBlockArray` interface. The type `BlockArray` stores each block contiguously while the type `PseudoBlockArray` stores the full matrix contiguously. This means that `BlockArray` supports fast non copying extraction and insertion of blocks while `PseudoBlockArray` supports fast access to the full matrix to use in in for example a linear solver.

A simple way to produce `BlockArray`s is via `mortar`, which combines an array of arrays into a `BlockArray`:
```julia
julia> mortar([randn(3), randn(4)])
2-blocked 7-element BlockVector{Float64}:
 -0.19808699390960527
  0.04711385377738941
 -0.6308529482215658
 ─────────────────────
 -0.021279626465135287
 -1.0991149020591062
  1.0817971931026398
 -0.012442892450142308

julia> mortar(reshape([randn(2,2), randn(1,2), randn(2,3), randn(1,3)],2,2))
2×2-blocked 3×5 BlockMatrix{Float64}:
 -1.17797    0.359738   │   0.87676    -2.06495    1.74256
  1.54787    1.64133    │  -0.0416484  -2.00241   -0.522441
 ───────────────────────┼──────────────────────────────────
  0.430093  -0.0263753  │  -1.31275     0.278447  -0.139579
```

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-dev-url] &mdash; *in-development version of the documentation.*

## Contributing

Possible ways of contributing to this package include:

* Implement the fusing broadcasting interface for blocked arrays.
* Make different Linear Algebra function (like matrix / vector multiplications) with blocked arrays work.
* Implement different reductions functionalities, (`sum` and co.).
* Audit the performance and make improvements as needed.

[docs-dev-url]: https://JuliaArrays.github.io/BlockArrays.jl/dev/
[docs-stable-url]: https://JuliaArrays.github.io/BlockArrays.jl/stable
