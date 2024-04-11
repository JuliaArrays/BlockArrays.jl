# BlockArrays

```@meta
DocTestSetup = quote
    using BlockArrays, SparseArrays
end
```

## Creating `BlockArray`s from an array

An `AbstractArray` can be repacked into a `BlockArray` with `BlockArray(array, block_sizes...)`.  The block sizes are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension (so the sum of `block_sizes` in every dimension must match the size of `array` in that dimension).

```jldoctest
julia> BlockArray(Array(reshape(1:16, 4, 4)), [2,2], [1,1,2])
2×3-blocked 4×4 BlockMatrix{Int64}:
 1  │  5  │   9  13
 2  │  6  │  10  14
 ───┼─────┼────────
 3  │  7  │  11  15
 4  │  8  │  12  16

julia> S = spzeros(4,5); S[1,2] = S[4,3] = 1;

julia> block_array_sparse = BlockArray(S, [1,3], [2,3])
2×2-blocked 4×5 BlockMatrix{Float64, Matrix{SparseMatrixCSC{Float64, Int64}}, Tuple{BlockedUnitRange{Vector{Int64}}, BlockedUnitRange{Vector{Int64}}}}:
  ⋅   1.0  │   ⋅    ⋅    ⋅ 
 ──────────┼───────────────
  ⋅    ⋅   │   ⋅    ⋅    ⋅ 
  ⋅    ⋅   │   ⋅    ⋅    ⋅ 
  ⋅    ⋅   │  1.0   ⋅    ⋅ 
```


## Creating uninitialized `BlockArray`s

A block array can be created with uninitialized values (but initialized blocks) using the
`BlockArray{T}(undef, block_sizes)` function. The `block_sizes` are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension. We here create a block matrix of `Float32`s:

```julia
julia> BlockArray{Float32}(undef, [1,2,1], [1,1,1])
3×3-blocked 4×3 BlockMatrix{Float32}:
 -2.15145e-35  │   1.4013e-45   │  -1.77199e-35
 ──────────────┼────────────────┼──────────────
  1.4013e-45   │  -1.77199e-35  │  -1.72473e-34
  1.4013e-45   │   4.57202e-41  │   4.57202e-41
 ──────────────┼────────────────┼──────────────
  0.0          │  -1.36568e-33  │  -1.72473e-34
```

We can also any other user defined array type that supports `similar`.


## Creating `BlockArrays` with uninitialized blocks.

A `BlockArray` can be created with the blocks left uninitialized using the `BlockArray(undef_blocks[, block_type], block_sizes...)` function.  We here create a `[1,2]×[3,2]` block matrix of `Float32`s:

```jldoctest
julia> BlockArray{Float32}(undef_blocks, [1,2], [3,2])
2×2-blocked 3×5 BlockMatrix{Float32}:
 #undef  #undef  #undef  │  #undef  #undef
 ────────────────────────┼────────────────
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```

The `block_type` should be an array type.  It specifies the internal block type, which defaults to an `Array` of the according dimension.  We can also use a `SparseVector` or any other user defined array type:

```jldoctest
julia> BlockArray(undef_blocks, SparseVector{Float64, Int}, [1,2])
2-blocked 3-element BlockVector{Float64, Vector{SparseVector{Float64, Int64}}, Tuple{BlockedUnitRange{Vector{Int64}}}}:
 #undef
 ──────
 #undef
 #undef
```

!!! warning

    Note that accessing an undefined block will throw an "access to undefined reference"-error!  If you create an array with undefined blocks, you _have_ to [initialize it block-wise](@ref setting_and_getting)); whole-array functions like `fill!` will not work:

    ```jldoctest
    julia> fill!(BlockArray{Float32}(undef_blocks, [1,2], [3,2]), 0)
    ERROR: UndefRefError: access to undefined reference
    ```

## [Setting and getting blocks and values](@id setting_and_getting)

A block can be set by  `block_array[Block(i...)] = v`. The indexing may equivalently be carried out as
`block_array[Block.(i)...]`.

```jldoctest block_array
julia> block_array = BlockArray{Float64}(undef_blocks, [1,2], [2,2])
2×2-blocked 3×4 BlockMatrix{Float64}:
 #undef  #undef  │  #undef  #undef
 ────────────────┼────────────────
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef

julia> block_array[Block(2,1)] = reshape([1:4;], 2, 2);

julia> block_array[Block(1),Block(1)] = [1 2];

julia> block_array
2×2-blocked 3×4 BlockMatrix{Float64}:
 1.0  2.0  │  #undef  #undef
 ──────────┼────────────────
 1.0  3.0  │  #undef  #undef
 2.0  4.0  │  #undef  #undef
```

Note that this will "take ownership" of the passed in array, that is, no copy is made.

A block can be retrieved with `view(block_array, Block(i...))`,
or if a copy is desired, `block_array[Block(i...)]`:

```jldoctest block_array
julia> view(block_array, Block(1, 1))
1×2 Matrix{Float64}:
 1.0  2.0

julia> block_array[Block(1, 1)] # makes a copy
1×2 Matrix{Float64}:
 1.0  2.0

julia> block_array[Block(1), Block(1)]  # equivalent to above
1×2 Matrix{Float64}:
 1.0  2.0
```

For setting and getting a single scalar element, the usual `setindex!` and `getindex` are available.

```jl
julia> block_array[1, 2]
2.0
```

## Views of blocks

To view and modify blocks of `BlockArray` use the `view` syntax.
```jldoctest
julia> A = BlockArray(ones(6), 1:3);

julia> view(A, Block(2))
2-element Vector{Float64}:
 1.0
 1.0

julia> view(A, Block(2)) .= [3,4]; A[Block(2)]
2-element Vector{Float64}:
 3.0
 4.0

julia> view(A, Block.(1:2))
3-element view(::BlockVector{Float64, Vector{Vector{Float64}}, Tuple{BlockedUnitRange{ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}}}}, BlockSlice(BlockRange(1:2),1:1:3)) with eltype Float64 with indices 1:1:3:
 1.0
 3.0
 4.0
```



## Converting between `BlockArray` and normal arrays

An array can be repacked into a `BlockArray` with `BlockArray(array, block_sizes...)`:

```jldoctest repack
julia> S = spzeros(4,5); S[1,2] = S[4,3] = 1;

julia> block_array_sparse = BlockArray(S, [1,3], [2,3])
2×2-blocked 4×5 BlockMatrix{Float64, Matrix{SparseMatrixCSC{Float64, Int64}}, Tuple{BlockedUnitRange{Vector{Int64}}, BlockedUnitRange{Vector{Int64}}}}:
  ⋅   1.0  │   ⋅    ⋅    ⋅ 
 ──────────┼───────────────
  ⋅    ⋅   │   ⋅    ⋅    ⋅ 
  ⋅    ⋅   │   ⋅    ⋅    ⋅ 
  ⋅    ⋅   │  1.0   ⋅    ⋅ 
```

To get back the underlying sparse array, use `sparse`:

```jldoctest repack
julia> sparse(block_array_sparse)
4×5 SparseMatrixCSC{Float64, Int64} with 2 stored entries:
  ⋅   1.0   ⋅    ⋅    ⋅ 
  ⋅    ⋅    ⋅    ⋅    ⋅ 
  ⋅    ⋅    ⋅    ⋅    ⋅ 
  ⋅    ⋅   1.0   ⋅    ⋅ 
```

To get a dense array, use `Array`:
```jldoctest repack
julia> Array(block_array_sparse)
4×5 Matrix{Float64}:
 0.0  1.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  1.0  0.0  0.0
```
