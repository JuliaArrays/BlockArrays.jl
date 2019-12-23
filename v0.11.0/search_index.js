var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#BlockArrays.jl-1",
    "page": "Home",
    "title": "BlockArrays.jl",
    "category": "section",
    "text": "Block arrays in Julia(Image: Build Status) (Image: codecov)A block array is a partition of an array into multiple blocks or subarrays, see wikipedia for a more extensive description. This package has two purposes. Firstly, it defines an interface for an AbstractBlockArray block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.Secondly, it also implements two concrete types of block arrays that follow the AbstractBlockArray interface.  The type BlockArray stores each single block contiguously, by wrapping an AbstractArray{<:AbstractArray{T,N},N} to concatenate all blocks – the complete array is thus not stored contiguously.  Conversely, a PseudoBlockArray stores the full matrix contiguously (by wrapping only one AbstractArray{T, N}) and only superimposes a block structure.  This means that BlockArray supports fast non copying extraction and insertion of blocks, while PseudoBlockArray supports fast access to the full matrix to use in, for example, a linear solver."
},

{
    "location": "#Terminology-1",
    "page": "Home",
    "title": "Terminology",
    "category": "section",
    "text": "We talk about an “a×b-blocked m×n block array”, if we have m times n values arranged in a times b blocks, like in the following example:2×3-blocked 4×4 BlockArray{Float64,2}:\n 0.56609   │  0.95429   │  0.0688403  0.980771 \n 0.203829  │  0.138667  │  0.0200418  0.0515364\n ──────────┼────────────┼──────────────────────\n 0.963832  │  0.391176  │  0.925799   0.148993 \n 0.18693   │  0.838529  │  0.801236   0.793251The dimension of arrays works the same as with standard Julia arrays; for example the following is a 2 times 2 block vector:2-blocked 4-element BlockArray{Float64,1}:\n 0.35609231970760424\n 0.7732179994849591 \n ───────────────────\n 0.8455294223894625 \n 0.04250653797187476A block array layout is specified its block sizes – a tuple of AbstractArray{Int}.  The length of the tuple is equal to the dimension, the length of each block size array is the number of blocks in the corresponding dimension, and the sum of each block size is the scalar size in that dimension.  For example, BlockArray{Int}(undef, [2,2,2], [2,2,2], [2,2,2]) will produce a blocked cube (an AbstractArray{Int, 3}, i.e., 3 dimensions), consisting of 27 2×2×2 blocks (3 in each dimension) and 216 values (6 in each dimension)."
},

{
    "location": "#Manual-Outline-1",
    "page": "Home",
    "title": "Manual Outline",
    "category": "section",
    "text": "Pages = [\"man/abstractblockarrayinterface.md\", \"man/blockarrays.md\", \"man/pseudoblockarrays.md\"]\nDepth = 2"
},

{
    "location": "#Library-Outline-1",
    "page": "Home",
    "title": "Library Outline",
    "category": "section",
    "text": "Pages = [\"lib/public.md\", \"lib/internals.md\"]\nDepth = 2"
},

{
    "location": "#main-index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"lib/public.md\", \"lib/internals.md\"]"
},

{
    "location": "man/abstractblockarrayinterface/#",
    "page": "The block axis interface",
    "title": "The block axis interface",
    "category": "page",
    "text": ""
},

{
    "location": "man/abstractblockarrayinterface/#The-block-axis-interface-1",
    "page": "The block axis interface",
    "title": "The block axis interface",
    "category": "section",
    "text": "A block array\'s block structure is dictated by its axes, which are typically a BlockedUnitRange but may also be a UnitRange,  which is assumed to be a single block, or other type that implements the block axis interface.Methods to implement Brief description\nblockaxes(A) A one-tuple returning a range of blocks specifying the block structure\ngetindex(A, K::Block{1}) return a unit range of indices in the specified block\nblocklasts(A) Returns the last index of each block\nfindblock(A, k) return the block that contains the kth entry of A"
},

{
    "location": "man/abstractblockarrayinterface/#The-AbstractBlockArray-interface-1",
    "page": "The block axis interface",
    "title": "The AbstractBlockArray interface",
    "category": "section",
    "text": "An arrays block structure is inferred from an axes, and therefore every array is in some sense already a block array:julia> A = randn(5,5)\n5×5 Array{Float64,2}:\n  0.452801   -0.416508   1.17406    1.52575     3.1574  \n  0.413142   -1.34722   -1.28597    0.637721    0.30655 \n  0.34907    -0.887615   0.284972  -0.0212884  -0.225832\n  0.466102   -1.10425    1.49226    0.968436   -2.13637 \n -0.0971956  -1.7664    -0.592629  -1.48947     1.53418 \n\njulia> A[Block(1,1)]\n5×5 Array{Float64,2}:\n  0.452801   -0.416508   1.17406    1.52575     3.1574  \n  0.413142   -1.34722   -1.28597    0.637721    0.30655 \n  0.34907    -0.887615   0.284972  -0.0212884  -0.225832\n  0.466102   -1.10425    1.49226    0.968436   -2.13637 \n -0.0971956  -1.7664    -0.592629  -1.48947     1.53418 It is possible to override additional functions to improve speed, however.Methods to implement Brief description\nOptional methods \ngetblock(A, i...) X[Block(i...)], blocked indexing\nsetblock!(A, v, i...) X[Block(i...)] = v, blocked index assignment\ngetblock!(x, A, i) X[i], blocked index assignment with in place storage in xFor a more thorough description of the methods see the public interface documentation.With the methods above implemented the following are automatically provided for arrays that are subtypes of AbstractBlockArray:A pretty printing show function that uses unicode lines to split up the blocks:julia> A = BlockArray(rand(4, 5), [1,3], [2,3])\n2×2-blocked 4×5 BlockArray{Float64,2}:\n0.61179   0.965631  │  0.696476   0.392796  0.712462\n--------------------┼-------------------------------\n0.620099  0.364706  │  0.0311643  0.27895   0.73477\n0.215712  0.923602  │  0.279944   0.994497  0.383706\n0.569955  0.754047  │  0.0190392  0.548297  0.687052A bounds index checking function for indexing with blocks:julia> blockcheckbounds(A, 5, 3)\nERROR: BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [5,3]Happy users who know how to use your new block array :)"
},

{
    "location": "man/blockarrays/#",
    "page": "BlockArrays",
    "title": "BlockArrays",
    "category": "page",
    "text": ""
},

{
    "location": "man/blockarrays/#BlockArrays-1",
    "page": "BlockArrays",
    "title": "BlockArrays",
    "category": "section",
    "text": "DocTestSetup = quote\n    using BlockArrays\n    using Random\n    Random.seed!(1234)\nend"
},

{
    "location": "man/blockarrays/#Creating-BlockArrays-from-an-array-1",
    "page": "BlockArrays",
    "title": "Creating BlockArrays from an array",
    "category": "section",
    "text": "An AbstractArray can be repacked into a BlockArray with BlockArray(array, block_sizes...).  The block sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension (so the sum of block_sizes in every dimension must match the size of array in that dimension).julia> BlockArray(rand(4, 4), [2,2], [1,1,2])\n2×3-blocked 4×4 BlockArray{Float64,2}:\n 0.70393   │  0.568703  │  0.0137366  0.953038\n 0.24957   │  0.145924  │  0.884324   0.134155\n ──────────┼────────────┼─────────────────────\n 0.408133  │  0.707723  │  0.467458   0.326718\n 0.844314  │  0.794279  │  0.0421491  0.683791\n\njulia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])\n2×2-blocked 4×5 BlockArray{Float64,2,Array{SparseMatrixCSC{Float64,Int64},2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}}:\n 0.0341601  0.374187  │  0.0118196  0.299058  0.0     \n ---------------------┼-------------------------------\n 0.0945445  0.931115  │  0.0460428  0.0       0.0     \n 0.314926   0.438939  │  0.496169   0.0       0.0     \n 0.12781    0.246862  │  0.732      0.449182  0.875096"
},

{
    "location": "man/blockarrays/#Creating-uninitialized-BlockArrays-1",
    "page": "BlockArrays",
    "title": "Creating uninitialized BlockArrays",
    "category": "section",
    "text": "A block array can be created with uninitialized values (but initialized blocks) using the BlockArray{T}(undef, block_sizes) function. The block_sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension. We here create a block matrix of Float32s:julia> BlockArray{Float32}(undef, [1,2,1], [1,1,1])\n3×3-blocked 4×3 BlockArray{Float32,2}:\n -2.15145e-35  │   1.4013e-45   │  -1.77199e-35\n ──────────────┼────────────────┼──────────────\n  1.4013e-45   │  -1.77199e-35  │  -1.72473e-34\n  1.4013e-45   │   4.57202e-41  │   4.57202e-41\n ──────────────┼────────────────┼──────────────\n  0.0          │  -1.36568e-33  │  -1.72473e-34We can also any other user defined array type that supports similar."
},

{
    "location": "man/blockarrays/#Creating-BlockArrays-with-uninitialized-blocks.-1",
    "page": "BlockArrays",
    "title": "Creating BlockArrays with uninitialized blocks.",
    "category": "section",
    "text": "A BlockArray can be created with the blocks left uninitialized using the BlockArray(undef_blocks[, block_type], block_sizes...) function.  We here create a [1,2]×[3,2] block matrix of Float32s:julia> BlockArray{Float32}(undef_blocks, [1,2], [3,2])\n2×2-blocked 3×5 BlockArray{Float32,2}:\n #undef  #undef  #undef  │  #undef  #undef\n ────────────────────────┼────────────────\n #undef  #undef  #undef  │  #undef  #undef\n #undef  #undef  #undef  │  #undef  #undefThe block_type should be an array type.  It specifies the internal block type, which defaults to an Array of the according dimension.  We can also use a SparseVector or any other user defined array type:julia> BlockArray(undef_blocks, SparseVector{Float64, Int}, [1,2])\n2-blocked 3-element BlockArray{Float64,1,Array{SparseVector{Float64,Int64},1},Tuple{BlockedUnitRange{Array{Int64,1}}}}:\n #undef\n ------\n #undef\n #undefwarning: Warning\nNote that accessing an undefined block will throw an \"access to undefined reference\"-error!  If you create an array with undefined blocks, you have to initialize it block-wise); whole-array functions like fill! will not work:julia> fill!(BlockArray{Float32}(undef_blocks, [1,2], [3,2]), 0)\nERROR: UndefRefError: access to undefined reference\n…"
},

{
    "location": "man/blockarrays/#setting_and_getting-1",
    "page": "BlockArrays",
    "title": "Setting and getting blocks and values",
    "category": "section",
    "text": "A block can be set by setblock!(block_array, v, i...) where v is the array to set and i is the block index. An alternative syntax for this is block_array[Block(i...)] = v or block_array[Block.(i)...].julia> block_array = BlockArray{Float64}(undef_blocks, [1,2], [2,2])\n2×2-blocked 3×4 BlockArray{Float64,2}:\n #undef  #undef  │  #undef  #undef\n ────────────────┼────────────────\n #undef  #undef  │  #undef  #undef\n #undef  #undef  │  #undef  #undef\n\njulia> setblock!(block_array, rand(2,2), 2, 1)\n2×2-blocked 3×4 BlockArray{Float64,2}:\n #undef      #undef      │  #undef  #undef\n ────────────────────────┼────────────────\n   0.590845    0.566237  │  #undef  #undef\n   0.766797    0.460085  │  #undef  #undef\n\njulia> block_array[Block(1, 1)] = [1 2];\n\njulia> block_array\n2×2-blocked 3×4 BlockArray{Float64,2}:\n 1.0       2.0       │  #undef  #undef\n ────────────────────┼────────────────\n 0.590845  0.566237  │  #undef  #undef\n 0.766797  0.460085  │  #undef  #undefNote that this will \"take ownership\" of the passed in array, that is, no copy is made.A block can be retrieved with getblock(block_array, i...) or block_array[Block(i...)]:julia> block_array[Block(1, 1)]\n1×2 Array{Float64,2}:\n 1.0  2.0\n\njulia> block_array[Block(1), Block(1)]  # equivalent to above\n1×2 Array{Float64,2}:\n 1.0  2.0Similarly to setblock! this does not copy the returned array.For setting and getting a single scalar element, the usual setindex! and getindex are available.julia> block_array[1, 2]\n2.0"
},

{
    "location": "man/blockarrays/#Views-of-blocks-1",
    "page": "BlockArrays",
    "title": "Views of blocks",
    "category": "section",
    "text": "We can also view and modify views of blocks of BlockArray using the view syntax:julia> A = BlockArray(ones(6), 1:3);\n\njulia> view(A, Block(2))\n2-element view(::BlockArray{Float64,1,Array{Array{Float64,1},1},Tuple{BlockedUnitRange{Array{Int64,1}}}}, BlockSlice(Block(2),2:3)) with eltype Float64:\n 1.0\n 1.0\n\njulia> view(A, Block(2)) .= [3,4]; A[Block(2)]\n2-element Array{Float64,1}:\n 3.0\n 4.0"
},

{
    "location": "man/blockarrays/#Converting-between-BlockArray-and-normal-arrays-1",
    "page": "BlockArrays",
    "title": "Converting between BlockArray and normal arrays",
    "category": "section",
    "text": "An array can be repacked into a BlockArray with BlockArray(array, block_sizes...):julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])\n2×2-blocked 4×5 BlockArray{Float64,2,Array{SparseMatrixCSC{Float64,Int64},2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}}:\n 0.0341601  0.374187  │  0.0118196  0.299058  0.0     \n ---------------------┼-------------------------------\n 0.0945445  0.931115  │  0.0460428  0.0       0.0     \n 0.314926   0.438939  │  0.496169   0.0       0.0     \n 0.12781    0.246862  │  0.732      0.449182  0.875096To get back the underlying array use Array:julia> Array(block_array_sparse)\n4×5 SparseMatrixCSC{Float64,Int64} with 13 stored entries:\n  [1, 1]  =  0.30006\n  [2, 1]  =  0.451742\n  [3, 1]  =  0.243174\n  [4, 1]  =  0.156468\n  [1, 2]  =  0.94057\n  [3, 2]  =  0.544175\n  [4, 2]  =  0.598345\n  [3, 3]  =  0.737486\n  [4, 3]  =  0.929512\n  [1, 4]  =  0.539601\n  [3, 4]  =  0.757658\n  [4, 4]  =  0.44709\n  [2, 5]  =  0.514679"
},

{
    "location": "man/pseudoblockarrays/#",
    "page": "PseudoBlockArrays",
    "title": "PseudoBlockArrays",
    "category": "page",
    "text": ""
},

{
    "location": "man/pseudoblockarrays/#PseudoBlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "PseudoBlockArrays",
    "category": "section",
    "text": "DocTestSetup = quote\n    using BlockArrays\n    using Random\n    Random.seed!(1234)\nendA PseudoBlockArray is similar to a BlockArray except the full array is stored contiguously instead of block by block. This means that is not possible to insert and retrieve blocks without copying data. On the other hand, converting a `PseudoBlockArray to the \"full\" underlying array is instead instant since it can just return the wrapped array.When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient to use a PseudoBlockArray to build up the Jacobian block by block and then pass the resulting matrix to a direct solver using full."
},

{
    "location": "man/pseudoblockarrays/#Creating-PseudoBlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "Creating PseudoBlockArrays",
    "category": "section",
    "text": "Creating a PseudoBlockArray works in the same way as a BlockArray.julia> pseudo = PseudoBlockArray(rand(3,3), [1,2], [2,1])\n2×2-blocked 3×3 PseudoBlockArray{Float64,2}:\n 0.590845  0.460085  │  0.200586\n ────────────────────┼──────────\n 0.766797  0.794026  │  0.298614\n 0.566237  0.854147  │  0.246837This \"takes ownership\" of the passed in array so no copy of the array is made."
},

{
    "location": "man/pseudoblockarrays/#Creating-initialized-BlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "Creating initialized BlockArrays",
    "category": "section",
    "text": "A block array can be created with uninitialized entries using the BlockArray{T}(undef, block_sizes...) function. The block_sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension. We here create a [1,2]×[3,2] block matrix of Float32s:julia> PseudoBlockArray{Float32}(undef, [1,2], [3,2])\n2×2-blocked 3×5 PseudoBlockArray{Float32,2}:\n 1.02295e-43  0.0          1.09301e-43  │  0.0          1.17709e-43\n ───────────────────────────────────────┼──────────────────────────\n 0.0          1.06499e-43  0.0          │  1.14906e-43  0.0        \n 1.05097e-43  0.0          1.13505e-43  │  0.0          1.1911e-43 We can also any other user defined array type that supports similar."
},

{
    "location": "man/pseudoblockarrays/#Setting-and-getting-blocks-and-values-1",
    "page": "PseudoBlockArrays",
    "title": "Setting and getting blocks and values",
    "category": "section",
    "text": "Setting and getting blocks uses the same API as BlockArrays. The difference here is that setting a block will update the block in place and getting a block will extract a copy of the block and return it. For PseudoBlockArrays there is a mutating block getter called getblock! which updates a passed in array to avoid a copy:julia> A = zeros(2,2)\n2×2 Array{Float64,2}:\n 0.0  0.0\n 0.0  0.0\n\njulia> getblock!(A, pseudo, 2, 1);\n\njulia> A\n2×2 Array{Float64,2}:\n 0.766797  0.794026\n 0.566237  0.854147It is sometimes convenient to access an index in a certain block. We could of course write this as A[Block(I,J)][i,j] but the problem is that A[Block(I,J)] allocates its output so this type of indexing will be inefficient. Instead, it is possible to use the A[BlockIndex((I,J), (i,j))] indexing. Using the same block matrix A as above:julia> pseudo[BlockIndex((2,1), (2,2))]\n0.8541465903790502The underlying array is accessed with Array just like for BlockArray."
},

{
    "location": "man/pseudoblockarrays/#Views-of-blocks-1",
    "page": "PseudoBlockArrays",
    "title": "Views of blocks",
    "category": "section",
    "text": "We can also view and modify views of blocks of PseudoBlockArray using the view syntax:julia> A = PseudoBlockArray(ones(6), 1:3);\n\njulia> view(A, Block(2))\n2-element view(::PseudoBlockArray{Float64,1,Array{Float64,1},Tuple{BlockedUnitRange{Array{Int64,1}}}}, BlockSlice(Block(2),2:3)) with eltype Float64:\n 1.0\n 1.0\n\njulia> view(A, Block(2)) .= [3,4]; A[Block(2)]\n2-element Array{Float64,1}:\n 3.0\n 4.0Note that, in memory, each block is in a BLAS-Level 3 compatible format, so that, in the future, algebra with blocks will be highly efficient."
},

{
    "location": "lib/public/#",
    "page": "Public Documentation",
    "title": "Public Documentation",
    "category": "page",
    "text": "CurrentModule = BlockArrays"
},

{
    "location": "lib/public/#Public-Documentation-1",
    "page": "Public Documentation",
    "title": "Public Documentation",
    "category": "section",
    "text": "Documentation for BlockArrays.jl\'s public interface.See Internal Documentation for internal package docs covering all submodules."
},

{
    "location": "lib/public/#Contents-1",
    "page": "Public Documentation",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\"public.md\"]"
},

{
    "location": "lib/public/#Index-1",
    "page": "Public Documentation",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"public.md\"]"
},

{
    "location": "lib/public/#BlockArrays.AbstractBlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.AbstractBlockArray",
    "category": "type",
    "text": "abstract AbstractBlockArray{T, N} <: AbstractArray{T, N}\n\nThe abstract type that represents a blocked array. Types that implement the AbstractBlockArray interface should subtype from this type.\n\n** Typealiases **\n\nAbstractBlockMatrix{T} -> AbstractBlockArray{T, 2}\nAbstractBlockVector{T} -> AbstractBlockArray{T, 1}\nAbstractBlockVecOrMat{T} -> Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.BlockBoundsError",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockBoundsError",
    "category": "type",
    "text": "BlockBoundsError([A], [inds...])\n\nThrown when a block indexing operation into a block array, A, tried to access an out-of-bounds block, inds.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.Block",
    "page": "Public Documentation",
    "title": "BlockArrays.Block",
    "category": "type",
    "text": "Block(inds...)\n\nA Block is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By indexing a AbstractBlockArray with a Block the a block at that block index will be returned instead of a single element.\n\njulia> A = BlockArray(ones(2,3), [1, 1], [2, 1])\n2×2-blocked 2×3 BlockArray{Float64,2}:\n 1.0  1.0  │  1.0\n ──────────┼─────\n 1.0  1.0  │  1.0\n\njulia> A[Block(1, 1)]\n1×2 Array{Float64,2}:\n 1.0  1.0\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.BlockIndex",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockIndex",
    "category": "type",
    "text": "BlockIndex{N}\n\nA BlockIndex is an index which stores a global index in two parts: the block and the offset index into the block.\n\nIt can be used to index into BlockArrays in the following manner:\n\njulia> arr = Array(reshape(1:25, (5,5)));\n\njulia> a = PseudoBlockArray(arr, [3,2], [1,4])\n2×2-blocked 5×5 PseudoBlockArray{Int64,2}:\n 1  │   6  11  16  21\n 2  │   7  12  17  22\n 3  │   8  13  18  23\n ───┼────────────────\n 4  │   9  14  19  24\n 5  │  10  15  20  25\n\njulia> a[BlockIndex((1,2), (1,2))]\n11\n\njulia> a[BlockIndex((2,2), (2,3))]\n20\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blockaxes",
    "page": "Public Documentation",
    "title": "BlockArrays.blockaxes",
    "category": "function",
    "text": "blockaxes(A)\n\nReturn the tuple of valid block indices for array A. \n\njulia> A = BlockArray([1,2,3],[2,1])\n2-blocked 3-element BlockArray{Int64,1}:\n 1\n 2\n ─\n 3\n\njulia> blockaxes(A)[1]\n2-element BlockRange{1,Tuple{UnitRange{Int64}}}:\n Block(1)\n Block(2)\n\n\n\n\n\nblockaxes(A, d)\n\nReturn the valid range of block indices for array A along dimension d.\n\njulia> A = BlockArray([1,2,3],[2,1])\n2-blocked 3-element BlockArray{Int64,1}:\n 1\n 2\n ─\n 3\n\njulia> blockaxes(A,1)\n2-element BlockRange{1,Tuple{UnitRange{Int64}}}:\n Block(1)\n Block(2)\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blockisequal",
    "page": "Public Documentation",
    "title": "BlockArrays.blockisequal",
    "category": "function",
    "text": "blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int})\n\nreturns true if a and b have the same block structure.\n\n\n\n\n\nblockisequal(a::Tuple, b::Tuple)\n\nreturns true if all(blockisequal.(a,b))` is true.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blocksize",
    "page": "Public Documentation",
    "title": "BlockArrays.blocksize",
    "category": "function",
    "text": "blocksize(A)\n\nReturn the tuple of the number of blocks along each dimension.\n\njulia> A = BlockArray(ones(3,3),[2,1],[1,1,1])\n2×3-blocked 3×3 BlockArray{Float64,2}:\n 1.0  │  1.0  │  1.0\n 1.0  │  1.0  │  1.0\n ─────┼───────┼─────\n 1.0  │  1.0  │  1.0\n\njulia> blocksize(A)\n(2, 3)\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blockfirsts",
    "page": "Public Documentation",
    "title": "BlockArrays.blockfirsts",
    "category": "function",
    "text": "blockfirsts(a::AbstractUnitRange{Int})\n\nreturns the first index of each block of a.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blocklasts",
    "page": "Public Documentation",
    "title": "BlockArrays.blocklasts",
    "category": "function",
    "text": "blocklasts(a::AbstractUnitRange{Int})\n\nreturns the last index of each block of a.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blocklengths",
    "page": "Public Documentation",
    "title": "BlockArrays.blocklengths",
    "category": "function",
    "text": "blocklengths(a::AbstractUnitRange{Int})\n\nreturns the length of each block of a.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.getblock",
    "page": "Public Documentation",
    "title": "BlockArrays.getblock",
    "category": "function",
    "text": "getblock(A, inds...)\n\nReturns the block at blockindex inds.... An alternative syntax is A[Block(inds...)]. Throws aBlockBoundsError` if this block is out of bounds.\n\njulia> v = Array(reshape(1:6, (2, 3)))\n2×3 Array{Int64,2}:\n 1  3  5\n 2  4  6\n\njulia> A = BlockArray(v, [1,1], [2,1])\n2×2-blocked 2×3 BlockArray{Int64,2}:\n 1  3  │  5\n ──────┼───\n 2  4  │  6\n\njulia> getblock(A, 2, 1)\n1×2 Array{Int64,2}:\n 2  4\n\njulia> A[Block(1, 2)]\n1×1 Array{Int64,2}:\n 5\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.getblock!",
    "page": "Public Documentation",
    "title": "BlockArrays.getblock!",
    "category": "function",
    "text": "getblock!(X, A, inds...)\n\nStores the block at blockindex inds in X and returns it. Throws a BlockBoundsError if the attempted assigned block is out of bounds.\n\njulia> A = PseudoBlockArray(ones(2, 3), [1, 1], [2, 1])\n2×2-blocked 2×3 PseudoBlockArray{Float64,2}:\n 1.0  1.0  │  1.0\n ──────────┼─────\n 1.0  1.0  │  1.0\n\njulia> x = zeros(1, 2);\n\njulia> getblock!(x, A, 2, 1);\n\njulia> x\n1×2 Array{Float64,2}:\n 1.0  1.0\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.setblock!",
    "page": "Public Documentation",
    "title": "BlockArrays.setblock!",
    "category": "function",
    "text": "setblock!(A, v, inds...)\n\nStores the block v in the block at block index inds in A. An alternative syntax is A[Block(inds...)] = v. Throws a BlockBoundsError if this block is out of bounds.\n\njulia> A = PseudoBlockArray(zeros(2, 3), [1, 1], [2, 1]);\n\njulia> setblock!(A, [1 2], 1, 1);\n\njulia> A[Block(2, 1)] = [3 4];\n\njulia> A\n2×2-blocked 2×3 PseudoBlockArray{Float64,2}:\n 1.0  2.0  │  0.0\n ──────────┼─────\n 3.0  4.0  │  0.0\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.blockcheckbounds",
    "page": "Public Documentation",
    "title": "BlockArrays.blockcheckbounds",
    "category": "function",
    "text": "blockcheckbounds(A, inds...)\n\nThrow a BlockBoundsError if the specified block indexes are not in bounds for the given block array. Subtypes of AbstractBlockArray should specialize this method if they need to provide custom block bounds checking behaviors.\n\njulia> A = BlockArray(rand(2,3), [1,1], [2,1]);\n\njulia> blockcheckbounds(A, 3, 2)\nERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockArray{Float64,2,Array{Array{Float64,2},2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}} at block index [3,2]\n[...]\n\n\n\n\n\n"
},

{
    "location": "lib/public/#AbstractBlockArray-interface-1",
    "page": "Public Documentation",
    "title": "AbstractBlockArray interface",
    "category": "section",
    "text": "This sections defines the functions a subtype of AbstractBlockArray should define to be a part of the AbstractBlockArray interface. An AbstractBlockArray{T, N} is a subtype of AbstractArray{T,N} and should therefore also fulfill the AbstractArray interface.AbstractBlockArray\nBlockBoundsError\nBlock\nBlockIndex\nblockaxes\nblockisequal\nblocksize\nblockfirsts\nblocklasts\nblocklengths\ngetblock\ngetblock!\nsetblock!\nblockcheckbounds"
},

{
    "location": "lib/public/#BlockArrays.BlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockArray",
    "category": "type",
    "text": "BlockArray{T, N, R<:AbstractArray{<:AbstractArray{T,N},N}, BS<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractBlockArray{T, N}\n\nA BlockArray is an array where each block is stored contiguously. This means that insertions and retrieval of blocks can be very fast and non allocating since no copying of data is needed.\n\nIn the type definition, R defines the array type that holds the blocks, for example Matrix{Matrix{Float64}}.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.undef_blocks",
    "page": "Public Documentation",
    "title": "BlockArrays.undef_blocks",
    "category": "constant",
    "text": "undef_blocks\n\nAlias for UndefBlocksInitializer(), which constructs an instance of the singleton type UndefBlocksInitializer (@ref), used in block array initialization to indicate the array-constructor-caller would like an uninitialized block array.\n\nExamples\n\n≡≡≡≡≡≡≡≡≡≡ julia julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2]) 2×2-blocked 3×5 BlockArray{Float32,2}:  #undef  #undef  #undef  │  #undef  #undef  ------------------------┼----------------  #undef  #undef  #undef  │  #undef  #undef  #undef  #undef  #undef  │  #undef  #undef\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.UndefBlocksInitializer",
    "page": "Public Documentation",
    "title": "BlockArrays.UndefBlocksInitializer",
    "category": "type",
    "text": "UndefBlocksInitializer\n\nSingleton type used in block array initialization, indicating the array-constructor-caller would like an uninitialized block array. See also undef_blocks (@ref), an alias for UndefBlocksInitializer().\n\nExamples\n\n≡≡≡≡≡≡≡≡≡≡ julia julia> BlockArray(undef_blocks, Matrix{Float32}, [1,2], [3,2]) 2×2-blocked 3×5 BlockArray{Float32,2}:  #undef  #undef  #undef  │  #undef  #undef  ────────────────────────┼────────────────  #undef  #undef  #undef  │  #undef  #undef  #undef  #undef  #undef  │  #undef  #undef\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArrays.mortar",
    "page": "Public Documentation",
    "title": "BlockArrays.mortar",
    "category": "function",
    "text": "mortar(blocks::AbstractArray)\nmortar(blocks::AbstractArray{R, N}, sizes_1, sizes_2, ..., sizes_N)\nmortar(blocks::AbstractArray{R, N}, block_sizes::NTuple{N,AbstractUnitRange{Int}})\n\nConstruct a BlockArray from blocks.  block_sizes is computed from blocks if it is not given.\n\nExamples\n\njulia> blocks = permutedims(reshape([\n                  1ones(1, 3), 2ones(1, 2),\n                  3ones(2, 3), 4ones(2, 2),\n              ], (2, 2)))\n2×2 Array{Array{Float64,2},2}:\n [1.0 1.0 1.0]               [2.0 2.0]\n [3.0 3.0 3.0; 3.0 3.0 3.0]  [4.0 4.0; 4.0 4.0]\n\njulia> mortar(blocks)\n2×2-blocked 3×5 BlockArray{Float64,2}:\n 1.0  1.0  1.0  │  2.0  2.0\n ───────────────┼──────────\n 3.0  3.0  3.0  │  4.0  4.0\n 3.0  3.0  3.0  │  4.0  4.0\n\njulia> ans == mortar(\n                  (1ones(1, 3), 2ones(1, 2)),\n                  (3ones(2, 3), 4ones(2, 2)),\n              )\ntrue\n\n\n\n\n\nmortar((block_11, ..., block_1m), ... (block_n1, ..., block_nm))\n\nConstruct a BlockMatrix with n * m  blocks.  Each block_ij must be an AbstractMatrix.\n\n\n\n\n\n"
},

{
    "location": "lib/public/#BlockArray-1",
    "page": "Public Documentation",
    "title": "BlockArray",
    "category": "section",
    "text": "BlockArray\nundef_blocks\nUndefBlocksInitializer\nmortar"
},

{
    "location": "lib/public/#BlockArrays.PseudoBlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.PseudoBlockArray",
    "category": "type",
    "text": "PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N}\n\nA PseudoBlockArray is similar to a BlockArray except the full array is stored contiguously instead of block by block. This means that is not possible to insert and retrieve blocks without copying data. On the other hand Array on a PseudoBlockArray is instead instant since it just returns the wrapped array.\n\nWhen iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient to use a PseudoBlockArray to build up the Jacobian block by block and then pass the resulting matrix to a direct solver using Array.\n\njulia> using BlockArrays, Random, SparseArrays\n\njulia> Random.seed!(12345);\n\njulia> A = PseudoBlockArray(rand(2,3), [1,1], [2,1])\n2×2-blocked 2×3 PseudoBlockArray{Float64,2}:\n 0.562714  0.371605  │  0.381128\n ────────────────────┼──────────\n 0.849939  0.283365  │  0.365801\n\njulia> A = PseudoBlockArray(sprand(6, 0.5), [3,2,1])\n3-blocked 6-element PseudoBlockArray{Float64,1,SparseVector{Float64,Int64},Tuple{BlockedUnitRange{Array{Int64,1}}}}:\n 0.0                \n 0.5865981007905481\n 0.0                \n ───────────────────\n 0.05016684053503706\n 0.0\n ───────────────────\n 0.0\n\n\n\n\n\n"
},

{
    "location": "lib/public/#PseudoBlockArray-1",
    "page": "Public Documentation",
    "title": "PseudoBlockArray",
    "category": "section",
    "text": "PseudoBlockArray"
},

{
    "location": "lib/internals/#",
    "page": "Internal Documentation",
    "title": "Internal Documentation",
    "category": "page",
    "text": "CurrentModule = BlockArrays"
},

{
    "location": "lib/internals/#Internal-Documentation-1",
    "page": "Internal Documentation",
    "title": "Internal Documentation",
    "category": "section",
    "text": ""
},

{
    "location": "lib/internals/#Contents-1",
    "page": "Internal Documentation",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\"internals.md\"]"
},

{
    "location": "lib/internals/#Index-1",
    "page": "Internal Documentation",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"internals.md\"]"
},

{
    "location": "lib/internals/#BlockArrays.BlockedUnitRange",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockedUnitRange",
    "category": "type",
    "text": "BlockedUnitRange\n\nis an AbstractUnitRange{Int} that has been divided into blocks, and is used to represent axes of block arrays. Construction is typically via blockrange which converts a vector of block lengths to a BlockedUnitRange.\n\njulia> blockedrange([2,2,3])\n3-blocked 7-element BlockedUnitRange{Array{Int64,1}}:\n 1\n 2\n ─\n 3\n 4\n ─\n 5\n 6\n 7\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#BlockArrays.BlockRange",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockRange",
    "category": "type",
    "text": "BlockRange(startblock, stopblock)\n\nrepresents a cartesian range of blocks.\n\nThe relationship between Block and BlockRange mimicks the relationship between CartesianIndex and CartesianRange.\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#BlockArrays.BlockIndexRange",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockIndexRange",
    "category": "type",
    "text": "BlockIndexRange(block, startind:stopind)\n\nrepresents a cartesian range inside a block.\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#BlockArrays.BlockSlice",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockSlice",
    "category": "type",
    "text": "BlockSlice(indices)\n\nRepresent an AbstractUnitRange of indices that attaches a block.\n\nUpon calling to_indices(), Blocks are converted to BlockSlice objects to represent the indices over which the Block spans.\n\nThis mimics the relationship between Colon and Base.Slice.\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#BlockArrays.unblock",
    "page": "Internal Documentation",
    "title": "BlockArrays.unblock",
    "category": "function",
    "text": "unblock(block_sizes, inds, I)\n\nReturns the indices associated with a block as a BlockSlice.\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#BlockArrays.SubBlockIterator",
    "page": "Internal Documentation",
    "title": "BlockArrays.SubBlockIterator",
    "category": "type",
    "text": "SubBlockIterator(subblock_lasts::Vector{Int}, block_lasts::Vector{Int})\nSubBlockIterator(A::AbstractArray, bs::NTuple{N,AbstractUnitRange{Int}} where N, dim::Integer)\n\nAn iterator for iterating BlockIndexRange of the blocks specified by subblock_lasts.  The Block index part of BlockIndexRange is determined by subblock_lasts.  That is to say, the Block index first specifies one of the block represented by subblock_lasts and then the inner-block index range specifies the region within the block.  Each such block corresponds to a block specified by blocklasts.\n\nNote that the invariance subblock_lasts ⊂ block_lasts must hold and must be ensured by the caller.\n\nExamples\n\njulia> using BlockArrays\n\njulia> import BlockArrays: SubBlockIterator, BlockIndexRange\n\njulia> A = BlockArray(1:6, 1:3);\n\njulia> subblock_lasts = axes(A, 1).lasts;\n\njulia> @assert subblock_lasts == [1, 3, 6];\n\njulia> block_lasts = [1, 3, 4, 6];\n\njulia> for idx in SubBlockIterator(subblock_lasts, block_lasts)\n           B = @show view(A, idx)\n           @assert !(parent(B) isa BlockArray)\n           idx :: BlockIndexRange\n           idx.block :: Block{1}\n           idx.indices :: Tuple{UnitRange}\n       end\nview(A, idx) = [1]\nview(A, idx) = [2, 3]\nview(A, idx) = [4]\nview(A, idx) = [5, 6]\n\njulia> [idx.block.n[1] for idx in SubBlockIterator(subblock_lasts, block_lasts)]\n4-element Array{Int64,1}:\n 1\n 2\n 3\n 3\n\njulia> [idx.indices[1] for idx in SubBlockIterator(subblock_lasts, block_lasts)]\n4-element Array{UnitRange{Int64},1}:\n 1:1\n 1:2\n 1:1\n 2:3\n\n\n\n\n\n"
},

{
    "location": "lib/internals/#Internals-1",
    "page": "Internal Documentation",
    "title": "Internals",
    "category": "section",
    "text": "BlockedUnitRange\nBlockRange\nBlockIndexRange\nBlockSlice\nunblock\nSubBlockIterator"
},

]}
