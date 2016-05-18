# The AbstractBlockArray interface

In order to follow the `AbstractBlockArray` the following methods should be implemented:


| Methods to implement    | Brief description |
| :---------------------- | :---------------- |
| `nblocks(A)`            | Tuple of number of blocks in each dimension |
| `nblocks(A, i)`         | Number of blocks in dimension `i` |
| `blocksize(A, i...)`    | Size of the block at block index `i...` |
| `getblock(A, i...)`     | `X[Block(i...)]`, blocked indexing  |
| `setblock!(A, v, i...)` | `X[Block(i...)] = v`, blocked index assignment |
| `full(A)`               | The non blocked array |
| **Optional methods**    |                        |
| `getblock!(x, A, i)`    | `X[i]`, blocked index assignment with in place storage in `x` |

For a more thorough description of the methods see the public interface documentation.


With the methods above implemented the following are automatically provided:

* A pretty printing `show` function that uses unicode lines to split up the blocks:

    julia> A = BlockArray(rand(4, 5), [1,3], [2,3])
    2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
     0.28346   0.234328  │  0.10266   0.0670817  0.941958
     --------------------┼-------------------------------
     0.881618  0.152164  │  0.938311  0.819992   0.860623
     0.74367   0.16049   │  0.704886  0.950269   0.601036
     0.502035  0.259069  │  0.857453  0.197673   0.962873

* Indexing with `Enums` works as a way to access blocks and set blocks.

    julia> @enum vars u=1 v=2

    julia> A[u, v]
    1×3 Array{Float64,2}:
     0.10266  0.0670817  0.941958

    julia> A[u, v] = zeros(1,3);

    julia> A[u, v]
    1×3 Array{Float64,2}:
     0.0  0.0  0.0


* A bounds index checking function for indexing with blocks:

    julia> blockcheckbounds(A, 5, 3)
    ERROR: BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [5,3]
     in blockcheckbounds(::BlockArrays.BlockArray{Float64,2,Array{Float64,2}}, ::Int64, ::Int64) at .julia/v0.5/BlockArrays/src/abstractblockarray.jl:190
     in eval(::Module, ::Any) at ./boot.jl:226

* Happy users who know how to use your new block array :)

