# BlockArrays.jl

[![Build Status](https://travis-ci.org/KristofferC/BlockArrays.jl.svg?branch=master)](https://travis-ci.org/KristofferC/BlockArrays.jl) [![codecov](https://codecov.io/gh/KristofferC/BlockArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/KristofferC/BlockArrays.jl)

**Note:** Currently, a quite new build of julia master is needed to use this package.

A block array is a partition of an array into blocks or subarrays, see [wikipedia](https://en.wikipedia.org/wiki/Block_matrix) for a good description. This package introduces the abstract type `AbstractBlockArray` for arrays that exhibit this block structure. Currently, two concrete types are implemented that have very similar API but differs in how the blocks are stored in memory. The type `BlockArray` stores each block contiguously while the type `PseudoBlockArray` stores the full matrix contiguously. Which one to use depends on the use case, `BlockArray` supports fast non copying extraction and insertion of blocks while `PseudoBlockArray` supports directly using the underlying full matrix in a linear solver for example. Both these type follow the `AbstractArray` interface and should work in arbitrary dimensions for arbitrary block types, as long as the block type itself satisfies the `AbstractArray` interface.

This README will first provide an overview over the `BlockArray` type and then later discuss the few differences between `BlockArrays` and `PseudoBlockArrays`.


### Creating uninitialized `BlockArray`s.

A `BlockArray` can be created with the blocks left uninitialized using the `BlockArray(block_type, block_sizes...)` function.
The `block_type` should be an array type, for example could for example a `Vector{Int}`. The block sizes are each a `Vector{Int}` which determines the size of the blocks in that dimension. We here create a `[1,2]×[3,2]` block matrix of `Float32`s:

```jl
julia> BlockArray(Matrix{Float32}, [1,2], [3,2])
3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:
 #undef  #undef  #undef  │  #undef  #undef
 ------------------------┿----------------
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```

We can also use a `SparseVector` or any other user defined array type:

```jl
julia> BlockArray(SparseVector{Float64, Int}, [1,2])
3-element BlockArrays.BlockArray{Float64,1,SparseVector{Float64,Int64}}:
 #undef
 ------
 #undef
 #undef
```

Note that accessing an undefined block will throw an "access to undefined reference"-error.

### Setting and getting blocks and values

A block can be set by `setblock!(block_array, v, i...)` where `v` is the array to set and `i` is the block index.
An alternative syntax for this is `block_array[Block(i...)] = v`.

```jl
julia> block_array = BlockArray(Matrix{Float64}, [1,2], [2,2])
3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef  #undef  │  #undef  #undef
 ━━━━━━━━━━━━━━━━┿━━━━━━━━━━━━━━━━
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef

julia> setblock!(block_array, rand(2,2), 2, 1)
3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef      #undef      │  #undef  #undef
 ------------------------┿----------------
   0.314407    0.298761  │  #undef  #undef
   0.91585     0.644499  │  #undef  #undef

julia> block_array[Block(1, 1)] = [1 2];

julia> block_array
3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 1.0       2.0       │  #undef  #undef
 --------------------┿----------------
 0.314407  0.298761  │  #undef  #undef
 0.91585   0.644499  │  #undef  #undef
```

Note that this will "take ownership" of the passed in array, that is, no copy is made.

A block can be retrieved with `getblock(block_array, i...)` or `block_array[Block(i...)]`:

```jl
julia> block_array[Block(1, 1)]
1×2 Array{Float64,2}:
 1.0  2.0
```

Similarly to `setblock!` this does not copy the returned array.

For setting and getting a single scalar element, the usual `setindex!` and `getindex` are available.

```jl
julia> block_array[1, 2]
2.0
```

### Converting between `BlockArray` and normal arrays

An array can be repacked into a `BlockArray` with`BlockArray(array, block_sizes...)`:

```jl
julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])
4×5 BlockArrays.BlockArray{Float64,2,SparseMatrixCSC{Float64,Int64}}:
 0.0       0.284338  │  0.0         0.52346   0.403969
 --------------------┿--------------------------------
 0.909193  0.0       │  0.0         0.3401    0.922003
 0.0       0.736793  │  0.00840872  0.804832  0.441806
 0.0       0.0       │  0.553519    0.757454  0.575238
```

To get back the full array use `full`:

```jl
julia> full(block_array_sparse)
4×5 sparse matrix with 13 Float64 nonzero entries:
    [2, 1]  =  0.909193
    [1, 2]  =  0.284338
      ⋮
    [3, 5]  =  0.441806
    [4, 5]  =  0.575238
```

### Operations on `BlockArrays`.

Simple unary/binary functions and reductions are available, for an overview, see the `operations.jl` file.

## `PseudoBlockArrays`

`PseudoBlockArrays` are similar to `BlockArrays` except the full matrix is stored contiguously. This means that it is no longer possible to set and get blocks by simply changing a reference. However, the wrapped array can be directly used in for example linear solvers for.

Creating a `PseudoBlockArray works in the same way as a `BlockArray`.

```julia
julia> psuedo = PseudoBlockArray(rand(3,3), [1,2], [2,1])
3×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 0.282059  0.560107  │  0.540811
 --------------------┿----------
 0.46358   0.11423   │  0.520826
 0.250737  0.809022  │  0.905993
```

Setting and getting blocks uses the same API as `BlockArray`s. The difference here is that setting a block will update the block in place and getting a block
will extract a copy of the block and return it. For `PseudoBlockArray`s there is a mutating block getter called `getblock!` which updates a passed in array to avoid a copy:

```julia
julia> A = zeros(2,2)

julia> getblock!(A, pseudo, 2, 1);

julia> A
2×2 Array{Float64,2}:
 0.46358   0.11423
 0.250737  0.809022
```

The underlaying arary is accessed with `full` just like for `BlockArray`.

## TODO

- Linear algebra stuff
- Investigate performance

## Author

This Julia package was written by [Kristoffer Carlsson](kristoffer.carlsson@chalmers.se)
