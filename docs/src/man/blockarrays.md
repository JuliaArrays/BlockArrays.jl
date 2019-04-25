# BlockArrays

```@meta
DocTestSetup = quote
    using BlockArrays
    using Random
    Random.seed!(1234)
end
```

## Creating `BlockArray`s from an array

An `AbstractArray` can be repacked into a `BlockArray` with `BlockArray(array, block_sizes...)`.  The block sizes are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension (so the sum of `block_sizes` in every dimension must match the size of `array` in that dimension).

```julia
julia> BlockArray(rand(4, 4), [2,2], [1,1,2])
2×3-blocked 4×4 BlockArray{Float64,2}:
 0.70393   │  0.568703  │  0.0137366  0.953038
 0.24957   │  0.145924  │  0.884324   0.134155
 ──────────┼────────────┼─────────────────────
 0.408133  │  0.707723  │  0.467458   0.326718
 0.844314  │  0.794279  │  0.0421491  0.683791

julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])
2×2-blocked 4×5 BlockArray{Float64,2,Array{SparseMatrixCSC{Float64,Int64},2},BlockArrays.BlockSizes{2,Array{Int64,1}}}:
 0.0341601  0.374187  │  0.0118196  0.299058  0.0     
 ---------------------┼-------------------------------
 0.0945445  0.931115  │  0.0460428  0.0       0.0     
 0.314926   0.438939  │  0.496169   0.0       0.0     
 0.12781    0.246862  │  0.732      0.449182  0.875096
```


## Creating uninitialized `BlockArray`s

A block array can be created with uninitialized values (but initialized blocks) using the
`BlockArray{T}(undef, block_sizes)` function. The `block_sizes` are each an `AbstractVector{Int}` which determines the size of the blocks in that dimension. We here create a block matrix of `Float32`s:

```julia
julia> BlockArray{Float32}(undef, [1,2,1], [1,1,1])
3×3-blocked 4×3 BlockArray{Float32,2}:
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
2×2-blocked 3×5 BlockArray{Float32,2}:
 #undef  #undef  #undef  │  #undef  #undef
 ────────────────────────┼────────────────
 #undef  #undef  #undef  │  #undef  #undef
 #undef  #undef  #undef  │  #undef  #undef
```

The `block_type` should be an array type.  It specifies the internal block type, which defaults to an `Array` of the according dimension.  We can also use a `SparseVector` or any other user defined array type:

```julia
julia> BlockArray(undef_blocks, SparseVector{Float64, Int}, [1,2])
2-blocked 3-element BlockArray{Float64,1,Array{SparseVector{Float64,Int64},1},BlockArrays.BlockSizes{1,Tuple{Array{Int64,1}}}}:
 #undef
 ------
 #undef
 #undef
```

!!! warning

    Note that accessing an undefined block will throw an "access to undefined reference"-error!  If you create an array with undefined blocks, you _have_ to [initialize it block-wise](@ref setting_and_getting)); whole-array functions like `fill!` will not work:
    
    ```julia
    julia> fill!(BlockArray{Float32}(undef_blocks, [1,2], [3,2]), 0)
    ERROR: UndefRefError: access to undefined reference
    …
    ```
    
    
## [Setting and getting blocks and values](@id setting_and_getting)

A block can be set by `setblock!(block_array, v, i...)` where `v` is the array to set and `i` is the block index.
An alternative syntax for this is `block_array[Block(i...)] = v` or
`block_array[Block.(i)...]`.

```jldoctest block_array
julia> block_array = BlockArray{Float64}(undef_blocks, [1,2], [2,2])
2×2-blocked 3×4 BlockArray{Float64,2}:
 #undef  #undef  │  #undef  #undef
 ────────────────┼────────────────
 #undef  #undef  │  #undef  #undef
 #undef  #undef  │  #undef  #undef

julia> setblock!(block_array, rand(2,2), 2, 1)
2×2-blocked 3×4 BlockArray{Float64,2}:
 #undef      #undef      │  #undef  #undef
 ────────────────────────┼────────────────
   0.590845    0.566237  │  #undef  #undef
   0.766797    0.460085  │  #undef  #undef

julia> block_array[Block(1, 1)] = [1 2];

julia> block_array
2×2-blocked 3×4 BlockArray{Float64,2}:
 1.0       2.0       │  #undef  #undef
 ────────────────────┼────────────────
 0.590845  0.566237  │  #undef  #undef
 0.766797  0.460085  │  #undef  #undef
```

Note that this will "take ownership" of the passed in array, that is, no copy is made.

A block can be retrieved with `getblock(block_array, i...)` or `block_array[Block(i...)]`:

```jldoctest block_array
julia> block_array[Block(1, 1)]
1×2 Array{Float64,2}:
 1.0  2.0

julia> block_array[Block(1), Block(1)]  # equivalent to above
1×2 Array{Float64,2}:
 1.0  2.0
```

Similarly to `setblock!` this does not copy the returned array.

For setting and getting a single scalar element, the usual `setindex!` and `getindex` are available.

```jl
julia> block_array[1, 2]
2.0
```

## Views of blocks

We can also view and modify views of blocks of `BlockArray` using the `view` syntax:
```jldoctest
julia> A = BlockArray(ones(6), 1:3);

julia> view(A, Block(2))
2-element view(::BlockArray{Float64,1,Array{Array{Float64,1},1},BlockArrays.BlockSizes{1,Tuple{Array{Int64,1}}}}, BlockSlice(Block{1,Int64}((2,)),2:3)) with eltype Float64:
 1.0
 1.0

julia> view(A, Block(2)) .= [3,4]; A[Block(2)]
2-element Array{Float64,1}:
 3.0
 4.0
```



## Converting between `BlockArray` and normal arrays

An array can be repacked into a `BlockArray` with `BlockArray(array, block_sizes...)`:

```jl
julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])
2×2-blocked 4×5 BlockArray{Float64,2,Array{SparseMatrixCSC{Float64,Int64},2},BlockArrays.BlockSizes{2,Tuple{Array{Int64,1}}}}:
 0.0341601  0.374187  │  0.0118196  0.299058  0.0     
 ---------------------┼-------------------------------
 0.0945445  0.931115  │  0.0460428  0.0       0.0     
 0.314926   0.438939  │  0.496169   0.0       0.0     
 0.12781    0.246862  │  0.732      0.449182  0.875096
```

To get back the underlying array use `Array`:

```jl
julia> Array(block_array_sparse)
4×5 SparseMatrixCSC{Float64,Int64} with 13 stored entries:
  [1, 1]  =  0.30006
  [2, 1]  =  0.451742
  [3, 1]  =  0.243174
  [4, 1]  =  0.156468
  [1, 2]  =  0.94057
  [3, 2]  =  0.544175
  [4, 2]  =  0.598345
  [3, 3]  =  0.737486
  [4, 3]  =  0.929512
  [1, 4]  =  0.539601
  [3, 4]  =  0.757658
  [4, 4]  =  0.44709
  [2, 5]  =  0.514679
```
