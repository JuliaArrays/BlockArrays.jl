# The block axis interface

A block array's block structure is dictated by its axes, which
are typically a `BlockedUnitRange` but may also be a `UnitRange`, 
which is assumed to be a single block, or other type that implements
the block axis interface.


| Methods to implement    | Brief description |
| :---------------------- | :---------------- |
| `blockaxes(A)`      | A one-tuple returning a range of blocks specifying the block structure |
| `getindex(A, K::Block{1})`      | return a unit range of indices in the specified block |
| `blocklasts(A)`      | Returns the last index of each block |
| `findblock(A, k)`      | return the block that contains the `k`th entry of `A` 


# The `AbstractBlockArray` interface

An arrays block structure is inferred from an axes, and therefore every array
is in some sense already a block array:
```julia
julia> A = randn(5,5)
5×5 Array{Float64,2}:
  0.452801   -0.416508   1.17406    1.52575     3.1574  
  0.413142   -1.34722   -1.28597    0.637721    0.30655 
  0.34907    -0.887615   0.284972  -0.0212884  -0.225832
  0.466102   -1.10425    1.49226    0.968436   -2.13637 
 -0.0971956  -1.7664    -0.592629  -1.48947     1.53418 

julia> A[Block(1,1)]
5×5 Array{Float64,2}:
  0.452801   -0.416508   1.17406    1.52575     3.1574  
  0.413142   -1.34722   -1.28597    0.637721    0.30655 
  0.34907    -0.887615   0.284972  -0.0212884  -0.225832
  0.466102   -1.10425    1.49226    0.968436   -2.13637 
 -0.0971956  -1.7664    -0.592629  -1.48947     1.53418 
```
It is possible to override additional functions to improve speed, however.

| Methods to implement    | Brief description |
| :---------------------- | :---------------- |
| **Optional methods**    |           
| `getblock(A, i...)`     | `X[Block(i...)]`, blocked indexing  |
| `setblock!(A, v, i...)` | `X[Block(i...)] = v`, blocked index assignment |
| `getblock!(x, A, i)`    | `X[i]`, blocked index assignment with in place storage in `x` |

For a more thorough description of the methods see the public interface documentation.

With the methods above implemented the following are automatically provided for arrays
that are subtypes of `AbstractBlockArray`:

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
