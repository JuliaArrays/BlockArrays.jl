var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#BlockArrays.jl-1",
    "page": "Home",
    "title": "BlockArrays.jl",
    "category": "section",
    "text": "Block arrays in Julia(Image: Build Status) (Image: codecov)A block array is a partition of an array into blocks or subarrays, see wikipedia for a more extensive description. This package has two purposes. Firstly, it defines an interface for an AbstractBlockArray block arrays that can be shared among types representing different types of block arrays. The advantage to this is that it provides a consistent API for block arrays.Secondly, it also implements two different type of block arrays that follow the AbstractBlockArray interface. The type BlockArray stores each block contiguously while the type PseudoBlockArray stores the full matrix contiguously. This means that BlockArray supports fast non copying extraction and insertion of blocks while PseudoBlockArray supports fast access to the full matrix to use in in for example a linear solver."
},

{
    "location": "index.html#Manual-Outline-1",
    "page": "Home",
    "title": "Manual Outline",
    "category": "section",
    "text": "Pages = [\"man/abstractblockarrayinterface.md\", \"man/blockarrays.md\", \"man/pseudoblockarrays.md\"]\nDepth = 2"
},

{
    "location": "index.html#Library-Outline-1",
    "page": "Home",
    "title": "Library Outline",
    "category": "section",
    "text": "Pages = [\"lib/public.md\", \"lib/internals.md\"]\nDepth = 2"
},

{
    "location": "index.html#main-index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"lib/public.md\", \"lib/internals.md\"]"
},

{
    "location": "man/abstractblockarrayinterface.html#",
    "page": "The AbstractBlockArray interface",
    "title": "The AbstractBlockArray interface",
    "category": "page",
    "text": ""
},

{
    "location": "man/abstractblockarrayinterface.html#The-AbstractBlockArray-interface-1",
    "page": "The AbstractBlockArray interface",
    "title": "The AbstractBlockArray interface",
    "category": "section",
    "text": "In order to follow the AbstractBlockArray the following methods should be implemented:Methods to implement Brief description\nnblocks(A) Tuple of number of blocks in each dimension\nnblocks(A, i) Number of blocks in dimension i\nblocksize(A, i...) Size of the block at block index i...\ngetblock(A, i...) X[Block(i...)], blocked indexing\nsetblock!(A, v, i...) X[Block(i...)] = v, blocked index assignment\nOptional methods \ngetblock!(x, A, i) X[i], blocked index assignment with in place storage in xFor a more thorough description of the methods see the public interface documentation.With the methods above implemented the following are automatically provided:A pretty printing show function that uses unicode lines to split up the blocks:julia> A = BlockArray(rand(4, 5), [1,3], [2,3])\n2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n0.61179   0.965631  │  0.696476   0.392796  0.712462\n--------------------┼-------------------------------\n0.620099  0.364706  │  0.0311643  0.27895   0.73477\n0.215712  0.923602  │  0.279944   0.994497  0.383706\n0.569955  0.754047  │  0.0190392  0.548297  0.687052A bounds index checking function for indexing with blocks:julia> blockcheckbounds(A, 5, 3)\nERROR: BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [5,3]Happy users who know how to use your new block array :)"
},

{
    "location": "man/blockarrays.html#",
    "page": "BlockArrays",
    "title": "BlockArrays",
    "category": "page",
    "text": ""
},

{
    "location": "man/blockarrays.html#BlockArrays-1",
    "page": "BlockArrays",
    "title": "BlockArrays",
    "category": "section",
    "text": "DocTestSetup = quote\n    srand(1234)\nend"
},

{
    "location": "man/blockarrays.html#Creating-uninitialized-BlockArrays-1",
    "page": "BlockArrays",
    "title": "Creating uninitialized BlockArrays",
    "category": "section",
    "text": "A block array can be created with initialized blocks using the BlockArray{T}(block_sizes) function. The block_sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension. We here create a [1,2]×[3,2] block matrix of Float32s:julia> BlockArray{Float32}(uninitialized, [1,2], [3,2])\n2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:\n 9.39116f-26  1.4013f-45   3.34245f-21  │  9.39064f-26  1.4013f-45\n ───────────────────────────────────────┼──────────────────────────\n 3.28434f-21  9.37645f-26  3.28436f-21  │  8.05301f-24  9.39077f-26\n 1.4013f-45   1.4013f-45   1.4013f-45   │  1.4013f-45   1.4013f-45We can also any other user defined array type that supports similar."
},

{
    "location": "man/blockarrays.html#Creating-BlockArrays-with-uninitialized-blocks.-1",
    "page": "BlockArrays",
    "title": "Creating BlockArrays with uninitialized blocks.",
    "category": "section",
    "text": "A BlockArray can be created with the blocks left uninitialized using the BlockArray(uninitialized, block_type, block_sizes...) function. The block_type should be an array type, it could for example be Matrix{Float64}. The block sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension. We here create a [1,2]×[3,2] block matrix of Float32s:julia> BlockArray{Float32}(uninitialized_blocks, [1,2], [3,2])\n2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:\n #undef  #undef  #undef  │  #undef  #undef\n ------------------------┼----------------\n #undef  #undef  #undef  │  #undef  #undef\n #undef  #undef  #undef  │  #undef  #undefWe can also use a SparseVector or any other user defined array type by specifying it as the second argument:julia> BlockArray(uninitialized_blocks, SparseVector{Float64, Int}, [1,2])\n2-blocked 3-element BlockArrays.BlockArray{Float64,1,SparseVector{Float64,Int64}}:\n #undef\n ------\n #undef\n #undefNote that accessing an undefined block will throw an \"access to undefined reference\"-error."
},

{
    "location": "man/blockarrays.html#Setting-and-getting-blocks-and-values-1",
    "page": "BlockArrays",
    "title": "Setting and getting blocks and values",
    "category": "section",
    "text": "A block can be set by setblock!(block_array, v, i...) where v is the array to set and i is the block index. An alternative syntax for this is block_array[Block(i...)] = v or block_array[Block.(i)...].julia> block_array = BlockArray{Float64}(unitialized_blocks, [1,2], [2,2])\n2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n #undef  #undef  │  #undef  #undef\n ----------------┼----------------\n #undef  #undef  │  #undef  #undef\n #undef  #undef  │  #undef  #undef\n\njulia> setblock!(block_array, rand(2,2), 2, 1)\n2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n #undef      #undef      │  #undef  #undef\n ------------------------┼----------------\n   0.590845    0.566237  │  #undef  #undef\n   0.766797    0.460085  │  #undef  #undef\n\njulia> block_array[Block(1, 1)] = [1 2];\n\njulia> block_array\n2×2-blocked 3×4 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n 1.0       2.0       │  #undef  #undef\n --------------------┼----------------\n 0.590845  0.566237  │  #undef  #undef\n 0.766797  0.460085  │  #undef  #undefNote that this will \"take ownership\" of the passed in array, that is, no copy is made.A block can be retrieved with getblock(block_array, i...) or block_array[Block(i...)]:julia> block_array[Block(1, 1)]\n1×2 Array{Float64,2}:\n 1.0  2.0\n\njulia> block_array[Block(1), Block(1)]  # equivalent to above\n 1×2 Array{Float64,2}:\n  1.0  2.0Similarly to setblock! this does not copy the returned array.For setting and getting a single scalar element, the usual setindex! and getindex are available.julia> block_array[1, 2]\n2.0"
},

{
    "location": "man/blockarrays.html#Views-of-blocks-1",
    "page": "BlockArrays",
    "title": "Views of blocks",
    "category": "section",
    "text": "We can also view and modify views of blocks of BlockArray using the view syntax:julia> A = BlockArray(ones(6), 1:3);\n\njulia> view(A, Block(2))\n2-element SubArray{Float64,1,BlockArrays.BlockArray{Float64,1,Array{Float64,1}},Tuple{BlockArrays.BlockSlice},false}:\n 1.0\n 1.0\n\njulia> view(A, Block(2)) .= [3,4]; A[Block(2)]\n2-element Array{Float64,1}:\n 3.0\n 4.0"
},

{
    "location": "man/blockarrays.html#Converting-between-BlockArray-and-normal-arrays-1",
    "page": "BlockArrays",
    "title": "Converting between BlockArray and normal arrays",
    "category": "section",
    "text": "An array can be repacked into a BlockArray with BlockArray(array, block_sizes...):julia> block_array_sparse = BlockArray(sprand(4, 5, 0.7), [1,3], [2,3])\n2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,SparseMatrixCSC{Float64,Int64}}:\n 0.0341601  0.374187  │  0.0118196  0.299058  0.0     \n ---------------------┼-------------------------------\n 0.0945445  0.931115  │  0.0460428  0.0       0.0     \n 0.314926   0.438939  │  0.496169   0.0       0.0     \n 0.12781    0.246862  │  0.732      0.449182  0.875096To get back the underlying array use Array:julia> Array(block_array_sparse))\n4×5 SparseMatrixCSC{Float64,Int64} with 15 stored entries:\n  [1, 1]  =  0.0341601\n  [2, 1]  =  0.0945445\n  [3, 1]  =  0.314926\n  [4, 1]  =  0.12781\n  ⋮\n  [3, 3]  =  0.496169\n  [4, 3]  =  0.732\n  [1, 4]  =  0.299058\n  [4, 4]  =  0.449182\n  [4, 5]  =  0.875096"
},

{
    "location": "man/pseudoblockarrays.html#",
    "page": "PseudoBlockArrays",
    "title": "PseudoBlockArrays",
    "category": "page",
    "text": ""
},

{
    "location": "man/pseudoblockarrays.html#PseudoBlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "PseudoBlockArrays",
    "category": "section",
    "text": "DocTestSetup = quote\n    srand(1234)\nendA PseudoBlockArray is similar to a BlockArray except the full array is stored contiguously instead of block by block. This means that is not possible to insert and retrieve blocks without copying data. On the other hand, converting a `PseudoBlockArray to the \"full\" underlying array is instead instant since it can just return the wrapped array.When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient to use a PseudoBlockArray to build up the Jacobian block by block and then pass the resulting matrix to a direct solver using full."
},

{
    "location": "man/pseudoblockarrays.html#Creating-PseudoBlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "Creating PseudoBlockArrays",
    "category": "section",
    "text": "Creating a PseudoBlockArray works in the same way as a BlockArray.julia> pseudo = PseudoBlockArray(rand(3,3), [1,2], [2,1])\n2×2-blocked 3×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:\n 0.590845  0.460085  │  0.200586\n ────────────────────┼──────────\n 0.766797  0.794026  │  0.298614\n 0.566237  0.854147  │  0.246837This \"takes ownership\" of the passed in array so no copy of the array is made."
},

{
    "location": "man/pseudoblockarrays.html#Creating-initialized-BlockArrays-1",
    "page": "PseudoBlockArrays",
    "title": "Creating initialized BlockArrays",
    "category": "section",
    "text": "A block array can be created with uninitialized entries using the BlockArray{T}(uninitialized, block_sizes...) function. The block_sizes are each an AbstractVector{Int} which determines the size of the blocks in that dimension. We here create a [1,2]×[3,2] block matrix of Float32s:julia> PseudoBlockArray{Float32}(uninitialized, [1,2], [3,2])\n2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:\n 9.39116f-26  1.4013f-45   3.34245f-21  │  9.39064f-26  1.4013f-45\n ───────────────────────────────────────┼──────────────────────────\n 3.28434f-21  9.37645f-26  3.28436f-21  │  8.05301f-24  9.39077f-26\n 1.4013f-45   1.4013f-45   1.4013f-45   │  1.4013f-45   1.4013f-45We can also any other user defined array type that supports similar."
},

{
    "location": "man/pseudoblockarrays.html#Setting-and-getting-blocks-and-values-1",
    "page": "PseudoBlockArrays",
    "title": "Setting and getting blocks and values",
    "category": "section",
    "text": "Setting and getting blocks uses the same API as BlockArrays. The difference here is that setting a block will update the block in place and getting a block will extract a copy of the block and return it. For PseudoBlockArrays there is a mutating block getter called getblock! which updates a passed in array to avoid a copy:julia> A = zeros(2,2)\n2×2 Array{Float64,2}:\n 0.0  0.0\n 0.0  0.0\n\njulia> getblock!(A, pseudo, 2, 1);\n\njulia> A\n2×2 Array{Float64,2}:\n 0.766797  0.794026\n 0.566237  0.854147It is sometimes convenient to access an index in a certain block. We could of course write this as A[Block(I,J)][i,j] but the problem is that A[Block(I,J)] allocates its output so this type of indexing will be inefficient. Instead, it is possible to use the A[BlockIndex((I,J), (i,j))] indexing. Using the same block matrix A as above:julia> pseudo[BlockIndex((2,1), (2,2))]\n0.8541465903790502The underlying array is accessed with Array just like for BlockArray."
},

{
    "location": "man/pseudoblockarrays.html#Views-of-blocks-1",
    "page": "PseudoBlockArrays",
    "title": "Views of blocks",
    "category": "section",
    "text": "We can also view and modify views of blocks of PseudoBlockArray using the view syntax:julia> A = PseudoBlockArray(ones(6), 1:3);\n\njulia> view(A, Block(2))\n2-element SubArray{Float64,1,BlockArrays.PseudoBlockArray{Float64,1,Array{Float64,1}},Tuple{BlockArrays.BlockSlice},false}:\n 1.0\n 1.0\n\njulia> view(A, Block(2)) .= [3,4]; A[Block(2)]\n2-element Array{Float64,1}:\n 3.0\n 4.0Note that, in memory, each block is in a BLAS-Level 3 compatible format, so that, in the future, algebra with blocks will be highly efficient."
},

{
    "location": "lib/public.html#",
    "page": "Public Documentation",
    "title": "Public Documentation",
    "category": "page",
    "text": "CurrentModule = BlockArrays"
},

{
    "location": "lib/public.html#Public-Documentation-1",
    "page": "Public Documentation",
    "title": "Public Documentation",
    "category": "section",
    "text": "Documentation for BlockArrays.jl\'s public interface.See Internal Documentation for internal package docs covering all submodules."
},

{
    "location": "lib/public.html#Contents-1",
    "page": "Public Documentation",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\"public.md\"]"
},

{
    "location": "lib/public.html#Index-1",
    "page": "Public Documentation",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"public.md\"]"
},

{
    "location": "lib/public.html#BlockArrays.AbstractBlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.AbstractBlockArray",
    "category": "type",
    "text": "abstract AbstractBlockArray{T, N} <: AbstractArray{T, N}\n\nThe abstract type that represents a blocked array. Types that implement the AbstractBlockArray interface should subtype from this type.\n\n** Typealiases **\n\nAbstractBlockMatrix{T} -> AbstractBlockArray{T, 2}\nAbstractBlockVector{T} -> AbstractBlockArray{T, 1}\nAbstractBlockVecOrMat{T} -> Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.BlockBoundsError",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockBoundsError",
    "category": "type",
    "text": "BlockBoundsError([A], [inds...])\n\nThrown when a block indexing operation into a block array, A, tried to access an out-of-bounds block, inds.\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.Block",
    "page": "Public Documentation",
    "title": "BlockArrays.Block",
    "category": "type",
    "text": "Block(inds...)\n\nA Block is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By indexing a AbstractBlockArray with a Block the a block at that block index will be returned instead of a single element.\n\njulia> A = BlockArray(ones(2,3), [1, 1], [2, 1])\n2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n 1.0  1.0  │  1.0\n ----------┼-----\n 1.0  1.0  │  1.0\n\njulia> A[Block(1, 1)]\n1×2 Array{Float64,2}:\n 1.0  1.0\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.BlockIndex",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockIndex",
    "category": "type",
    "text": "BlockIndex{N}\n\nA BlockIndex is an index which stores a global index in two parts: the block and the offset index into the block.\n\nIt can be used to index into BlockArrays in the following manner:\n\njulia> arr = Array(reshape(1:25, (5,5)));\n\njulia> a = PseudoBlockArray(arr, [3,2], [1,4])\n2×2-blocked 5×5 BlockArrays.PseudoBlockArray{Int64,2,Array{Int64,2}}:\n 1  │   6  11  16  21\n 2  │   7  12  17  22\n 3  │   8  13  18  23\n ───┼────────────────\n 4  │   9  14  19  24\n 5  │  10  15  20  25\n\njulia> a[BlockIndex((1,2), (1,2))]\n11\n\njulia> a[BlockIndex((2,2), (2,3))]\n20\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.nblocks",
    "page": "Public Documentation",
    "title": "BlockArrays.nblocks",
    "category": "function",
    "text": "nblocks(A, [dim...])\n\nReturns a tuple containing the number of blocks in a block array.  Optionally you can specify the dimension(s) you want the number of blocks for.\n\njulia> A =  BlockArray(rand(5,4,6), [1,4], [1,2,1], [1,2,2,1]);\n\njulia> nblocks(A)\n(2, 3, 4)\n\njulia> nblocks(A, 2)\n3\n\njulia> nblocks(A, 3, 2)\n(4, 3)\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.blocksize",
    "page": "Public Documentation",
    "title": "BlockArrays.blocksize",
    "category": "function",
    "text": "blocksize(A, inds...)\n\nReturns a tuple containing the size of the block at block index inds....\n\njulia> A = BlockArray(rand(5, 4, 6), [1, 4], [1, 2, 1], [1, 2, 2, 1]);\n\njulia> blocksize(A, 1, 3, 2)\n(1, 1, 2)\n\njulia> blocksize(A, 2, 1, 3)\n(4, 1, 2)\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.getblock",
    "page": "Public Documentation",
    "title": "BlockArrays.getblock",
    "category": "function",
    "text": "getblock(A, inds...)\n\nReturns the block at blockindex inds.... An alternative syntax is A[Block(inds...)]. Throws aBlockBoundsError` if this block is out of bounds.\n\njulia> v = Array(reshape(1:6, (2, 3)))\n2×3 Array{Int64,2}:\n 1  3  5\n 2  4  6\n\njulia> A = BlockArray(v, [1,1], [2,1])\n2×2-blocked 2×3 BlockArrays.BlockArray{Int64,2,Array{Int64,2}}:\n 1  3  │  5\n ------┼---\n 2  4  │  6\n\njulia> getblock(A, 2, 1)\n1×2 Array{Int64,2}:\n 2  4\n\njulia> A[Block(1, 2)]\n1×1 Array{Int64,2}:\n 5\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.getblock!",
    "page": "Public Documentation",
    "title": "BlockArrays.getblock!",
    "category": "function",
    "text": "getblock!(X, A, inds...)\n\nStores the block at blockindex inds in X and returns it. Throws a BlockBoundsError if the attempted assigned block is out of bounds.\n\njulia> A = PseudoBlockArray(ones(2, 3), [1, 1], [2, 1])\n2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:\n 1.0  1.0  │  1.0\n ----------┼-----\n 1.0  1.0  │  1.0\n\njulia> x = zeros(1, 2);\n\njulia> getblock!(x, A, 2, 1);\n\njulia> x\n1×2 Array{Float64,2}:\n 1.0  1.0\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.setblock!",
    "page": "Public Documentation",
    "title": "BlockArrays.setblock!",
    "category": "function",
    "text": "setblock!(A, v, inds...)\n\nStores the block v in the block at block index inds in A. An alternative syntax is A[Block(inds...)] = v. Throws a BlockBoundsError if this block is out of bounds.\n\njulia> A = PseudoBlockArray(zeros(2, 3), [1, 1], [2, 1]);\n\njulia> setblock!(A, [1 2], 1, 1);\n\njulia> A[Block(2, 1)] = [3 4];\n\njulia> A\n2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:\n 1.0  2.0  │  0.0\n ----------┼-----\n 3.0  4.0  │  0.0\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#Core.Array",
    "page": "Public Documentation",
    "title": "Core.Array",
    "category": "type",
    "text": "Array(A::AbstractBlockArray)\n\nReturns the array stored in A as a Array.\n\njulia> A = BlockArray(ones(2,3), [1,1], [2,1])\n2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:\n 1.0  1.0  │  1.0\n ----------┼-----\n 1.0  1.0  │  1.0\n\njulia> Array(A)\n2×3 Array{Float64,2}:\n 1.0  1.0  1.0\n 1.0  1.0  1.0\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.blockcheckbounds",
    "page": "Public Documentation",
    "title": "BlockArrays.blockcheckbounds",
    "category": "function",
    "text": "blockcheckbounds(A, inds...)\n\nThrow a BlockBoundsError if the specified block indexes are not in bounds for the given block array. Subtypes of AbstractBlockArray should specialize this method if they need to provide custom block bounds checking behaviors.\n\njulia> A = BlockArray(rand(2,3), [1,1], [2,1]);\n\njulia> blockcheckbounds(A, 3, 2)\nERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [3,2]\n[...]\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#AbstractBlockArray-interface-1",
    "page": "Public Documentation",
    "title": "AbstractBlockArray interface",
    "category": "section",
    "text": "This sections defines the functions a subtype of AbstractBlockArray should define to be a part of the AbstractBlockArray interface. An AbstractBlockArray{T, N} is a subtype of AbstractArray{T,N} and should therefore also fulfill the AbstractArray interface.AbstractBlockArray\nBlockBoundsError\nBlock\nBlockIndex\nnblocks\nblocksize\ngetblock\ngetblock!\nsetblock!\nArray\nblockcheckbounds"
},

{
    "location": "lib/public.html#BlockArrays.BlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.BlockArray",
    "category": "type",
    "text": "BlockArray{T, N, R <: AbstractArray{T, N}} <: AbstractBlockArray{T, N}\n\nA BlockArray is an array where each block is stored contiguously. This means that insertions and retrieval of blocks can be very fast and non allocating since no copying of data is needed.\n\nIn the type definition, R defines the array type that each block has, for example Matrix{Float64}.\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.uninitialized_blocks",
    "page": "Public Documentation",
    "title": "BlockArrays.uninitialized_blocks",
    "category": "constant",
    "text": "uninitialized_blocks\n\nAlias for UninitializedBlocks(), which constructs an instance of the singleton type UninitializedBlocks (@ref), used in block array initialization to indicate the array-constructor-caller would like an uninitialized block array.\n\nExamples ≡≡≡≡≡≡≡≡≡≡\n\njulia> BlockArray(uninitialized_blocks, Matrix{Float32}, [1,2], [3,2]) 2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:  #undef  #undef  #undef  │  #undef  #undef  ––––––––––––┼––––––––  #undef  #undef  #undef  │  #undef  #undef  #undef  #undef  #undef  │  #undef  #undef\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArrays.UninitializedBlocks",
    "page": "Public Documentation",
    "title": "BlockArrays.UninitializedBlocks",
    "category": "type",
    "text": "UninitializedBlocks\n\nSingleton type used in block array initialization, indicating the array-constructor-caller would like an uninitialized block array. See also uninitialized_blocks (@ref), an alias for UninitializedBlocks().\n\nExamples ≡≡≡≡≡≡≡≡≡≡\n\njulia> BlockArray(uninitialized_blocks, Matrix{Float32}, [1,2], [3,2]) 2×2-blocked 3×5 BlockArrays.BlockArray{Float32,2,Array{Float32,2}}:  #undef  #undef  #undef  │  #undef  #undef  ––––––––––––┼––––––––  #undef  #undef  #undef  │  #undef  #undef  #undef  #undef  #undef  │  #undef  #undef\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#BlockArray-1",
    "page": "Public Documentation",
    "title": "BlockArray",
    "category": "section",
    "text": "BlockArray\nuninitialized_blocks\nUninitializedBlocks"
},

{
    "location": "lib/public.html#BlockArrays.PseudoBlockArray",
    "page": "Public Documentation",
    "title": "BlockArrays.PseudoBlockArray",
    "category": "type",
    "text": "PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N}\n\nA PseudoBlockArray is similar to a BlockArray except the full array is stored contiguously instead of block by block. This means that is not possible to insert and retrieve blocks without copying data. On the other hand Array on a PseudoBlockArray is instead instant since it just returns the wrapped array.\n\nWhen iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient to use a PseudoBlockArray to build up the Jacobian block by block and then pass the resulting matrix to a direct solver using Array.\n\njulia> srand(12345);\n\njulia> A = PseudoBlockArray(rand(2,3), [1,1], [2,1])\n2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:\n 0.562714  0.371605  │  0.381128\n --------------------┼----------\n 0.849939  0.283365  │  0.365801\n\njulia> A = PseudoBlockArray(sprand(6, 0.5), [3,2,1])\n3-blocked 6-element BlockArrays.PseudoBlockArray{Float64,1,SparseVector{Float64,Int64}}:\n 0.0\n 0.586598\n 0.0\n ---------\n 0.0501668\n 0.0\n ---------\n 0.0\n\n\n\n\n\n"
},

{
    "location": "lib/public.html#PseudoBlockArray-1",
    "page": "Public Documentation",
    "title": "PseudoBlockArray",
    "category": "section",
    "text": "PseudoBlockArray"
},

{
    "location": "lib/internals.html#",
    "page": "Internal Documentation",
    "title": "Internal Documentation",
    "category": "page",
    "text": "CurrentModule = BlockArrays"
},

{
    "location": "lib/internals.html#Internal-Documentation-1",
    "page": "Internal Documentation",
    "title": "Internal Documentation",
    "category": "section",
    "text": ""
},

{
    "location": "lib/internals.html#Contents-1",
    "page": "Internal Documentation",
    "title": "Contents",
    "category": "section",
    "text": "Pages = [\"internals.md\"]"
},

{
    "location": "lib/internals.html#Index-1",
    "page": "Internal Documentation",
    "title": "Index",
    "category": "section",
    "text": "Pages = [\"internals.md\"]"
},

{
    "location": "lib/internals.html#BlockArrays.blockindex2global",
    "page": "Internal Documentation",
    "title": "BlockArrays.blockindex2global",
    "category": "function",
    "text": "blockindex2global{N}(block_sizes::BlockSizes{N}, block_index::BlockIndex{N}) -> inds\n\nConverts from a block index to a tuple containing the global indices\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#BlockArrays.global2blockindex",
    "page": "Internal Documentation",
    "title": "BlockArrays.global2blockindex",
    "category": "function",
    "text": "global2blockindex{N}(block_sizes::BlockSizes{N}, inds...) -> BlockIndex{N}\n\nConverts from global indices inds to a BlockIndex.\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#BlockArrays.BlockRange",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockRange",
    "category": "type",
    "text": "BlockRange(startblock, stopblock)\n\nrepresents a cartesian range of blocks.\n\nThe relationship between Block and BlockRange mimicks the relationship between CartesianIndex and CartesianRange.\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#BlockArrays.BlockIndexRange",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockIndexRange",
    "category": "type",
    "text": "BlockIndexRange(block, startind:stopind)\n\nrepresents a cartesian range inside a block.\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#BlockArrays.BlockSlice",
    "page": "Internal Documentation",
    "title": "BlockArrays.BlockSlice",
    "category": "type",
    "text": "BlockSlice(indices)\n\nRepresent an AbstractUnitRange of indices that attaches a block.\n\nUpon calling to_indices(), Blocks are converted to BlockSlice objects to represent the indices over which the Block spans.\n\nThis mimics the relationship between Colon and Base.Slice.\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#BlockArrays.unblock",
    "page": "Internal Documentation",
    "title": "BlockArrays.unblock",
    "category": "function",
    "text": "unblock(block_sizes, inds, I)\n\nReturns the indices associated with a block as a BlockSlice.\n\n\n\n\n\n"
},

{
    "location": "lib/internals.html#Internals-1",
    "page": "Internal Documentation",
    "title": "Internals",
    "category": "section",
    "text": "blockindex2global\nglobal2blockindex\nBlockRange\nBlockIndexRange\nBlockSlice\nunblock"
},

]}
