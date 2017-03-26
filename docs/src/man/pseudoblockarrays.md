# PseudoBlockArrays

```@meta
DocTestSetup = quote
    srand(1234)
end
```

A `PseudoBlockArray` is similar to a [`BlockArray`](@ref) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand, converting a ``PseudoBlockArray` to the "full" underlying array is instead instant since
it can just return the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `PseudoBlockArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `full`.

## Creating PseudoBlockArrays

Creating a `PseudoBlockArray` works in the same way as a `BlockArray`.

```jldoctest
julia> pseudo = PseudoBlockArray(rand(3,3), [1,2], [2,1])
2×2-blocked 3×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 0.590845  0.460085  │  0.200586
 ────────────────────┼──────────
 0.766797  0.794026  │  0.298614
 0.566237  0.854147  │  0.246837
```

This "takes ownership" of the passed in array so no copy of the array is made.

## Setting and getting blocks and values

Setting and getting blocks uses the same API as `BlockArrays`. The difference here is that setting a block will update the block in place and getting a block
will extract a copy of the block and return it. For `PseudoBlockArrays` there is a mutating block getter called `getblock!` which updates a passed in array to avoid a copy:

```jldoctest
julia> A = zeros(2,2)
2×2 Array{Float64,2}:
 0.0  0.0
 0.0  0.0

julia> getblock!(A, pseudo, 2, 1);

julia> A
2×2 Array{Float64,2}:
 0.766797  0.794026
 0.566237  0.854147
```

The underlying array is accessed with `Array` just like for `BlockArray`.
