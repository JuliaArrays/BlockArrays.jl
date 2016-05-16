# BlockArrays



## Creating uninitialized `BlockArrays`.

A `BlockArray` can be created with the blocks left uninitialized using the `BlockArray(block_type, block_sizes...)` function.
The `block_type` should be an array type, it could for example be `Matrix{Float64}`. The block sizes are each a `Vector{Int}` which determines the size of the blocks in that dimension. We here create a `[1,2]×[3,2]` block matrix of `Float32`s:

```jl
julia> BlockArray(Matrix{Float32}, [1,2], [3,2])
2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:
 #undef  #undef  #undef  │  #undef  #undef
 ------------------------┼----------------
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```

We can also use a `SparseVector` or any other user defined array type:

```jl
julia> BlockArray(SparseVector{Float64, Int}, [1,2])
2-blocked 3-element BlockArrays.BlockArray{Float64,1,SparseVector{Float64,Int64}}:
 #undef
 ------
 #undef
 #undef
```

Note that accessing an undefined block will throw an "access to undefined reference"-error.

## Setting and getting blocks and values

A block can be set by `setblock!(block_array, v, i...)` where `v` is the array to set and `i` is the block index.
An alternative syntax for this is `block_array[Block(i...)] = v`.

```jl
julia> block_array = BlockArray(Matrix{Float64}, [1,2], [2,2])
2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef  #undef  │  #undef  #undef
 ----------------┼----------------
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef

julia> setblock!(block_array, rand(2,2), 2, 1)
2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 #undef      #undef      │  #undef  #undef
 ------------------------┼----------------
   0.314407    0.298761  │  #undef  #undef
   0.91585     0.644499  │  #undef  #undef

julia> block_array[Block(1, 1)] = [1 2];

julia> block_array
2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 1.0       2.0       │  #undef  #undef
 --------------------┼----------------
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

## Converting between `BlockArray` and normal arrays

An array can be repacked into a `BlockArray` with`BlockArray(array, block_sizes...)`:

```jl
julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])
2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,SparseMatrixCSC{Float64,Int64}
 0.0       0.284338  │  0.0         0.52346   0.403969
 --------------------┼--------------------------------
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

## Operations on `BlockArrays`.

Simple unary/binary functions and reductions are available, for an overview, see the `operations.jl` file.
