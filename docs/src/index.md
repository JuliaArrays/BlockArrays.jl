# BlockArrays.jl

*Block arrays in Julia*

[![Build Status](https://travis-ci.org/KristofferC/BlockArrays.jl.svg?branch=master)](https://travis-ci.org/KristofferC/BlockArrays.jl) [![codecov](https://codecov.io/gh/KristofferC/BlockArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/KristofferC/BlockArrays.jl)

A block array is a partition of an array into blocks or subarrays, see [wikipedia](https://en.wikipedia.org/wiki/Block_matrix) for a more extensive description. This package has two purposes. Firstly, it defines an interface for an `AbstractBlockArray` block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.

Secondly, it also implements two different type of block arrays that follow the `AbstractBlockArray` interface. The type `BlockArray` stores each block contiguously while the type `PseudoBlockArray` stores the full matrix contiguously. This means that `BlockArray` supports fast non copying extraction and insertion of blocks while `PseudoBlockArray` supports fast access to the full matrix to use in in for example a linear solver.

**Note:** Currently, a quite new build of julia master is needed to use this package.


## Manual Outline

    {contents}
    Pages = ["man/abstractblockarrayinterface.md", "man/blockarrayss.md", "man/pseudoblockarrays.md"]
    Depth = 2

## Library Outline

    {contents}
    Pages = ["lib/public.md", "lib/internals.md"]
    Depth = 2

## [Index]({ref#main-index})

    {index}
    Pages = ["lib/public.md", "lib/internals.md"]
