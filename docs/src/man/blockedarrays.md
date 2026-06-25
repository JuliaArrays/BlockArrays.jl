# BlockedArrays

```@meta
DocTestSetup = quote
    using BlockArrays
    using Random
    Random.seed!(1234)
end
```

A `BlockedArray` is similar to a [`BlockArray`](@ref) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand, converting a `BlockedArray` to the "full" underlying array is instead instant since
it can just return the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `BlockedArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `Matrix`.

## Creating BlockedArrays

Creating a `BlockedArray` works in the same way as a `BlockArray`.

```jldoctest A
julia> pseudo = BlockedArray(reshape([1:9;], 3, 3), [1,2], [2,1])
2×2-blocked 3×3 BlockedMatrix{Int64}:
 1  4  │  7
 ──────┼───
 2  5  │  8
 3  6  │  9
```

This "takes ownership" of the passed in array so no copy of the array is made.


## Creating initialized `BlockArrays`

A block array can be created with uninitialized entries using the `BlockArray{T}(undef, block_sizes...)`
function. The block_sizes are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension. We here create a `[1,2]×[3,2]` block matrix of `Float32`s:
```julia
julia> BlockedArray{Float32}(undef, [1,2], [3,2])
2×2-blocked 3×5 BlockedMatrix{Float32}:
 1.02295e-43  0.0          1.09301e-43  │  0.0          1.17709e-43
 ───────────────────────────────────────┼──────────────────────────
 0.0          1.06499e-43  0.0          │  1.14906e-43  0.0
 1.05097e-43  0.0          1.13505e-43  │  0.0          1.1911e-43
```
We can also any other user defined array type that supports `similar`.

## Setting and getting blocks and values

Setting and getting blocks uses the same API as `BlockArrays`. The difference here is that setting a block will update the block in place and getting a block
will extract a copy of the block and return it. Note to update a passed in array without allocating
one can use views:

```jldoctest A
julia> A = zeros(2,2)
2×2 Matrix{Float64}:
 0.0  0.0
 0.0  0.0

julia> copyto!(A, view(pseudo, Block(2, 1)));

julia> A
2×2 Matrix{Float64}:
 2.0  5.0
 3.0  6.0
```

It is sometimes convenient to access an index in a certain block. We could of course write this as `A[Block(I,J)][i,j]` but the problem is that `A[Block(I,J)]` allocates its output so this type of indexing will be inefficient. Instead, it is possible to use the `A[BlockIndex((I,J), (i,j))]` indexing. Using the same block matrix `A` as above:

```jldoctest A
julia> pseudo[BlockIndex((2,1), (2,2))]
6
```

The underlying array is accessed with `Array` just like for `BlockArray`.


## Views of blocks

We can also view and modify views of blocks of `BlockedArray` using the `view` syntax:
```jldoctest
julia> A = BlockedArray(ones(6), 1:3);

julia> view(A, Block(2))
2-element view(::Vector{Float64}, 2:3) with eltype Float64:
 1.0
 1.0

julia> view(A, Block(2)) .= [3,4]; A[Block(2)]
2-element Vector{Float64}:
 3.0
 4.0
```
Note that, in memory, each block is in a BLAS-Level 3 compatible format, so
that algebra with blocks is highly efficient.
