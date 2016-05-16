# PseudoBlockArrays

A `PseudoBlockArray` is similar to a [`BlockArray`]({ref}) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand `full` on a `PseudoBlockArray` is instead instant since
it just returns the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `PseudoBlockArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `full`.

## Creating PseudoBlockArrays

Creating a `PseudoBlockArray` works in the same way as a `BlockArray`.

```julia
julia> pseudo = PseudoBlockArray(rand(3,3), [1,2], [2,1])
2×2-blocked 3×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 0.282059  0.560107  │  0.540811
 --------------------┼----------
 0.46358   0.11423   │  0.520826
 0.250737  0.809022  │  0.905993
```

This "takes ownership" of the passed in array so no copy of the array is made.

## Setting and getting blocks and values

Setting and getting blocks uses the same API as `BlockArrays`. The difference here is that setting a block will update the block in place and getting a block
will extract a copy of the block and return it. For `PseudoBlockArrays` there is a mutating block getter called `getblock!` which updates a passed in array to avoid a copy:

```julia
julia> A = zeros(2,2)

julia> getblock!(A, pseudo, 2, 1);

julia> A
2×2 Array{Float64,2}:
 0.46358   0.11423
 0.250737  0.809022
```

The underlying array is accessed with `full` just like for `BlockArray`.
