# BlockArrays.jl

*Block arrays in Julia*

[![Build Status](https://travis-ci.org/JuliaArrays/BlockArrays.jl.svg?branch=master)](https://travis-ci.org/JuliaArrays/BlockArrays.jl) [![codecov](https://codecov.io/gh/JuliaArrays/BlockArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaArrays/BlockArrays.jl)

A block array is a partition of an array into multiple blocks or subarrays, see [wikipedia](https://en.wikipedia.org/wiki/Block_matrix) for a more extensive description. This package has two purposes. Firstly, it defines an interface for an `AbstractBlockArray` block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.

Secondly, it also implements two concrete types of block arrays that follow the `AbstractBlockArray` interface.  The type `BlockArray` stores each single block contiguously, by wrapping an `AbstractArray{<:AbstractArray{T,N},N}` to concatenate all blocks – the complete array is thus not stored contiguously.  Conversely, a `PseudoBlockArray` stores the full matrix contiguously (by wrapping only one `AbstractArray{T, N}`) and only superimposes a block structure.  This means that `BlockArray` supports fast non copying extraction and insertion of blocks, while `PseudoBlockArray` supports fast access to the full matrix to use in, for example, a linear solver.


## Terminology

We talk about an “a×b-blocked m×n block array”, if we have ``m \times n`` values arranged in ``a \times b`` blocks, like in the following example:

```julia
2×3-blocked 4×4 BlockArray{Float64,2}:
 0.56609   │  0.95429   │  0.0688403  0.980771 
 0.203829  │  0.138667  │  0.0200418  0.0515364
 ──────────┼────────────┼──────────────────────
 0.963832  │  0.391176  │  0.925799   0.148993 
 0.18693   │  0.838529  │  0.801236   0.793251
```

The dimension of arrays works the same as with standard Julia arrays; for example the following is a ``2 \times 2`` block vector:

```julia
2-blocked 4-element BlockArray{Float64,1}:
 0.35609231970760424
 0.7732179994849591 
 ───────────────────
 0.8455294223894625 
 0.04250653797187476
```

A block array layout is specified its _block sizes_ – a tuple of `AbstractArray{Int}`.  The length of the tuple is equal to the dimension, the length of each block size array is the number of blocks in the corresponding dimension, and the sum of each block size is the scalar size in that dimension.  For example, `BlockArray{Int}(undef, [2,2,2], [2,2,2], [2,2,2])` will produce a blocked cube (an `AbstractArray{Int, 3}`, i.e., 3 dimensions), consisting of 27 2×2×2 blocks (3 in each dimension) and 216 values (6 in each dimension).


## Manual Outline

```@contents
Pages = ["man/abstractblockarrayinterface.md", "man/blockarrays.md", "man/pseudoblockarrays.md"]
Depth = 2
```

## Library Outline

```@contents
Pages = ["lib/public.md", "lib/internals.md"]
Depth = 2
```

## [Index](@id main-index)

```@index
Pages = ["lib/public.md", "lib/internals.md"]
```
