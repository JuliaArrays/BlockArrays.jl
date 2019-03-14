# PseudoBlockArrays

```@meta
DocTestSetup = quote
    using BlockArrays
    using Random
    Random.seed!(1234)
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

```jldoctest A
julia> pseudo = PseudoBlockArray(rand(3,3), [1,2], [2,1])
2×2-blocked 3×3 PseudoBlockArray{Float64,2}:
 0.590845  0.460085  │  0.200586
 ────────────────────┼──────────
 0.766797  0.794026  │  0.298614
 0.566237  0.854147  │  0.246837
```

This "takes ownership" of the passed in array so no copy of the array is made.


## Creating initialized `BlockArrays`

A block array can be created with uninitialized entries using the `BlockArray{T}(undef, block_sizes...)`
function. The block_sizes are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension. We here create a `[1,2]×[3,2]` block matrix of `Float32`s:
```julia
julia> PseudoBlockArray{Float32}(undef, [1,2], [3,2])
2×2-blocked 3×5 PseudoBlockArray{Float32,2}:
 1.02295e-43  0.0          1.09301e-43  │  0.0          1.17709e-43
 ───────────────────────────────────────┼──────────────────────────
 0.0          1.06499e-43  0.0          │  1.14906e-43  0.0        
 1.05097e-43  0.0          1.13505e-43  │  0.0          1.1911e-43 
```
We can also any other user defined array type that supports `similar`.

## Setting and getting blocks and values

Setting and getting blocks uses the same API as `BlockArrays`. The difference here is that setting a block will update the block in place and getting a block
will extract a copy of the block and return it. For `PseudoBlockArrays` there is a mutating block getter called `getblock!` which updates a passed in array to avoid a copy:

```jldoctest A
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

It is sometimes convenient to access an index in a certain block. We could of course write this as `A[Block(I,J)][i,j]` but the problem is that `A[Block(I,J)]` allocates its output so this type of indexing will be inefficient. Instead, it is possible to use the `A[BlockIndex((I,J), (i,j))]` indexing. Using the same block matrix `A` as above:

```jldoctest A
julia> pseudo[BlockIndex((2,1), (2,2))]
0.8541465903790502
```

The underlying array is accessed with `Array` just like for `BlockArray`.


## Views of blocks

We can also view and modify views of blocks of `PseudoBlockArray` using the `view` syntax:
```jldoctest
julia> A = PseudoBlockArray(ones(6), 1:3);

julia> view(A, Block(2))
2-element view(::PseudoBlockArray{Float64,1,Array{Float64,1},BlockArrays.BlockSizes{1,Array{Int64,1}}}, BlockSlice(Block{1,Int64}((2,)),2:3)) with eltype Float64:
 1.0
 1.0

julia> view(A, Block(2)) .= [3,4]; A[Block(2)]
2-element Array{Float64,1}:
 3.0
 4.0
```
Note that, in memory, each block is in a BLAS-Level 3 compatible format, so
that, in the future, algebra with blocks will be highly efficient.
