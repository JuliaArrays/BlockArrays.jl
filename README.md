# BlockArrays.jl

[![Build Status](https://travis-ci.org/JuliaArrays/BlockArrays.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/BlockArrays.jl) [![codecov](https://codecov.io/gh/JuliaArrays/BlockArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaArrays/BlockArrays.jl) [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaArrays.github.io/BlockArrays.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaArrays.github.io/BlockArrays.jl/latest)


A block array is a partition of an array into blocks or subarrays, see [wikipedia](https://en.wikipedia.org/wiki/Block_matrix) for a more extensive description. This package has two purposes. Firstly, it defines an interface for an `AbstractBlockArray` block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.

Secondly, it also implements two different type of block arrays that follow the `AbstractBlockArray` interface. The type `BlockArray` stores each block contiguously while the type `PseudoBlockArray` stores the full matrix contiguously. This means that `BlockArray` supports fast non copying extraction and insertion of blocks while `PseudoBlockArray` supports fast access to the full matrix to use in in for example a linear solver.

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of the documentation.*

## Contributing

Possible ways of contributing to this package include:

* Implement the fusing broadcasting interface for blocked arrays.
* Make different Linear Algebra function (like matrix / vector multiplications) with blocked arrays work.
* Implement different reductions functionalities, (`sum` and co.).
* Audit the performance and make improvements as needed.

## Author

Kristoffer Carlsson - [@KristofferC](https://github.com/KristofferC)

[docs-latest-url]: https://JuliaArrays.github.io/BlockArrays.jl/latest/
[docs-stable-url]: https://JuliaArrays.github.io/BlockArrays.jl/stable
