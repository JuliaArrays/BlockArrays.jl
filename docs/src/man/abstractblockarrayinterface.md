# The `AbstractBlockSizes` interface

In order to follow the `AbstractBlockSizes` the following methods should be implemented:


| Methods to implement    | Brief description |
| :---------------------- | :---------------- |
| `cumulsizes(A)`      | A Tuple of abstract vectors storing the cumulative block sizes |
| **Optional methods**    |       
| `nblocks(A)`            | Tuple of number of blocks in each dimension |
| `nblocks(A, i)`         | Number of blocks in dimension `i` |
| `blocksize(A, i)`    | Size of the block at block index `i` |

# The `AbstractBlockArray` interface

| Methods to implement    | Brief description |
| :---------------------- | :---------------- |
| `blocksizes(A)`         | Return a subtype of `AbstractBlockSizes` |
| **Optional methods**    |                       
| `getblock(A, i...)`     | `X[Block(i...)]`, blocked indexing  |
| `setblock!(A, v, i...)` | `X[Block(i...)] = v`, blocked index assignment |
| `getblock!(x, A, i)`    | `X[i]`, blocked index assignment with in place storage in `x` |

For a more thorough description of the methods see the public interface documentation.

With the methods above implemented the following are automatically provided:

* A pretty printing `show` function that uses unicode lines to split up the blocks:
```
julia> A = BlockArray(rand(4, 5), [1,3], [2,3])
2×2-blocked 4×5 BlockArray{Float64,2}:
0.61179   0.965631  │  0.696476   0.392796  0.712462
--------------------┼-------------------------------
0.620099  0.364706  │  0.0311643  0.27895   0.73477
0.215712  0.923602  │  0.279944   0.994497  0.383706
0.569955  0.754047  │  0.0190392  0.548297  0.687052
```

* A bounds index checking function for indexing with blocks:

```
julia> blockcheckbounds(A, 5, 3)
ERROR: BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [5,3]
```

* Happy users who know how to use your new block array :)
