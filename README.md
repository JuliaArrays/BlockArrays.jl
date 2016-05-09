# BlockArrays

A `BlockArray` is a partition of an `Array` into blocks, where each block is¨considered its own array. These are useful where one wants to exploit 
For a more extensive description of a block array, see the [wikipedia link](https://en.wikipedia.org/wiki/Block_matrix)

A BlockArray of dimension `n` is created in the following way,


ba = BlockArray(Float64, block_partition_a, block_partition_b, ... block_partition_n)

[1 2 | 3
 4 5 | 6
 7 8 | 9
 ----|---
 10  11| 12]


Example:
```jl   
block_matrix = BlockArray(Float64, (2, 1), (3, 1))
```

This creates the structure of the blockarray, 




where `nblock_
```jl
block(block_arr)[2,3] # Returns the array at block 2,3
block!(block_arr) = rand(3,2)
block_arr[5,6] # Returns the item as 

```