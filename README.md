# BlockArrays

A `BlockArray` is a partition of an array into blocks or subarrays, see the [wikipedia link](https://en.wikipedia.org/wiki/Block_matrix). This package introduces the type `BlockArray` which stores these blocks contiguously such that getting and setting blocks can be done without any copying. `BlockArray`s follow the `AbstractArray` interface and should work in arbitrary dimensions for arbitrary block types, as long as the block type itself satisfies the `AbstractArray` interface.

### Creating uninitialized `BlockArray`s.

```jl
julia> BlockArray(Matrix{Float32}, [1,2], [3,2])
3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:
 #undef  #undef  #undef  │  #undef  #undef
 ------------------------┿----------------
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```

Note that the array type used is not limited to normal julia `Array`s. We can for example use a `SparseArray` or any other user defined array type:

```jl
julia> BlockArray(SparseVector{Float64, Int}, [1,2])
3-element BlockArrays.BlockArray{Float64,1,SparseVector{Float64,Int64}}:
 #undef
 ------
 #undef
 #undef
```

### Setting and getting blocks / values

A block can be set by `setblock!(block_array, v, i...)` where `v` is the array to set and `i` is the block.
An alternative syntax for this is `block_array[Block(i...)] = v`.

```jl
julia> block_array = BlockArray(Matrix{Float64}, [1,2], [2,2])

julia> setblock!(block_array, rand(2,2), 2, 1)
3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef      #undef      │  #undef  #undef
 ------------------------┿----------------
   0.314407    0.298761  │  #undef  #undef
   0.91585     0.644499  │  #undef  #undef

julia> block_array[Block(1,1)] = [1.0 2.0];

julia> block_array
3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 1.0       2.0       │  #undef  #undef
 --------------------┿----------------
 0.314407  0.298761  │  #undef  #undef
 0.91585   0.644499  │  #undef  #undef
```

Note that this will "take ownership" of the passed in array, that is, no copy is made.

A block can be retrieved with `getblock(block_array, i...)` or `block_array[Block(i...)]`:

```
julia> block_array[Block(1,1)]
1×2 Array{Float64,2}:
 1.0  2.0
```

For setting and getting a single item, the usual `setindex!` and `getindex` are available.

```
julia> block_array[1,2]
2.0
```

### Going between `BlockArray` and normal arrays

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

We can get back the array using `full`:

```jl
julia> full(block_array_sparse)
4×5 sparse matrix with 13 Float64 nonzero entries:
    [2, 1]  =  0.909193
    [1, 2]  =  0.284338
      ⋮
    [3, 5]  =  0.441806
    [4, 5]  =  0.575238
```

### Operations on `BlockArray`s.

Simple unary functions, binary functions and reductions are available. For a full list, see the `operations.jl` file.

TODO:

- Linear algebra stuff, like `BlockArray` times `BlockArray` and `BlockMatrix` times `Vector`.
- A new `BlockArray` type which does not store separate blocks contiguously. This can be convenient when using dense solvers.
