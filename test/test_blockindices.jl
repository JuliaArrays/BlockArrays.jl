import BlockArrays.BlockIndices

#=
[1,1  1,2] | [1,3  1,4  1,5]
--------------------------
[2,1  2,2] | [2,3  2,4  2,5]
[3,1  3,2] | [3,3  3,4  3,5]
----------------------------
[4,1  4,2] | [4,3  4,4  4,5]
[5,1  5,2] | [5,3  5,4  5,5]
[6,1  6,2] | [6,3  6,4  6,5]
=#

bi = BlockIndices((1, 2, 3), (2, 3))

@test nblocks(bi) = 6
@test nblocks(bi, 3) = 2
@test nblocks(bi, 2) = 2

@test block_and_index(bi, (1,1)) == ([1,1], [1,1])
@test block_and_index(bi, (1,4)) == ([1,2], [1,2])
@test block_and_index(bi, (2,2)) == ([2,1], [1,2])
@test block_and_index(bi, (5,2)) == ([3,1], [2,2])
@test block_and_index(bi, (6,5)) == ([3,2], [3,3])

@test global_index(bi, (2,2), (2,2)) == [3,4]
@test global_index(bi, (1,1), (1,1)) == [1,1]
@test global_index(bi, (3,2), (3,3)) == [6,5]
@test global_index(bi, (3,1), (1,2)) == [4,2]
@test global_index(bi, (3,2), (2,2)) == [5,4]
