# Note: Functions surrounded by a comment blocks are there because `Vararg` is sitll allocating.
# When Vararg is fast enough, they can simply be removed

####################
# PseudoBlockArray #
####################

"""
    PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N}

A `PseudoBlockArray` is similar to a [`BlockArray`](@ref) except the full array is stored
contiguously instead of block by block. This means that is not possible to insert and retrieve
blocks without copying data. On the other hand `full` on a `PseudoBlockArray` is instead instant since
it just returns the wrapped array.

When iteratively solving a set of equations with a gradient method the Jacobian typically has a block structure. It can be convenient
to use a `PseudoBlockArray` to build up the Jacobian block by block and then pass the resulting matrix to
a direct solver using `full`.

```jlcon
julia> A = PseudoBlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 0.599925  0.288788  │  0.55428
 --------------------┼----------
 0.82342   0.394812  │  0.263454

julia> A = PseudoBlockArray(sprand(6, 0.5), [3,2,1])
3-blocked 6-element BlockArrays.PseudoBlockArray{Float64,1,SparseVector{Float64,Int64}}:
 0.542401
 0.542299
 0.0
 ---------
 0.682638
 0.0
 ---------
 0.0553841
```
"""
immutable PseudoBlockArray{T, N, R} <: AbstractBlockArray{T, N}
    blocks::R
    block_sizes::BlockSizes{N}
    function PseudoBlockArray(blocks::R, block_sizes::BlockSizes{N})
        for i in 1:N
            @assert sum(block_sizes[i]) == size(blocks, i)
        end
        @assert ndims(R) == N
        @assert eltype(T) == T
        new(blocks, block_sizes)
    end
end

typealias PseudoBlockMatrix{T, R} PseudoBlockArray{T, 2, R}
typealias PseudoBlockVector{T, R} PseudoBlockArray{T, 1, R}
typealias PseudoBlockVecOrMat{T, R} Union{PseudoBlockMatrix{T, R}, PseudoBlockVector{T, R}}

# Auxiliary outer constructor
PseudoBlockArray{N, R}(blocks::R, block_sizes::BlockSizes{N}) = PseudoBlockArray{eltype(R), N, R}(blocks, block_sizes)
PseudoBlockArray{N, R}(blocks::R, block_sizes::Vararg{Vector{Int}, N}) = PseudoBlockArray(blocks, BlockSizes(block_sizes))


###########################
# AbstractArray Interface #
###########################

function Base.similar{T,N,T2}(block_array::PseudoBlockArray{T,N}, ::Type{T2})
    PseudoBlockArray(similar(block_array.blocks, T2), copy(block_array.block_sizes))
end

Base.size(arr::PseudoBlockArray) = map(sum, arr.block_sizes.sizes)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function Base.getindex{T, N}(block_arr::PseudoBlockArray{T, N}, i::Int)
    @boundscheck checkbounds(block_arr, )
    @inbounds v = block_arr.blocks[i]
    return v
end

function Base.getindex{T, N}(block_arr::PseudoBlockArray{T, N}, i::Int, j::Int)
    @boundscheck checkbounds(block_arr, i, j)
    @inbounds v = block_arr.blocks[i, j]
    return v
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

function Base.getindex{T, N}(block_arr::PseudoBlockArray{T, N}, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds v = block_arr.blocks[i...]
    return v
end

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function Base.setindex!{T, N}(block_arr::PseudoBlockArray{T, N}, v, i::Int)
    @boundscheck checkbounds(block_arr, i)
    @inbounds block_arr.blocks[i] = v
    return block_arr
end

function Base.setindex!{T, N}(block_arr::PseudoBlockArray{T, N}, v, i::Int, j::Int)
    @boundscheck checkbounds(block_arr, i, j)
    @inbounds block_arr.blocks[i, j] = v
    return block_arr
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

function Base.setindex!{T, N}(block_arr::PseudoBlockArray{T, N}, v, i::Vararg{Int, N})
    @boundscheck checkbounds(block_arr, i...)
    @inbounds block_arr.blocks[i...] = v
    return block_arr
end

################################
# AbstractBlockArray Interface #
################################


nblocks(block_array::PseudoBlockArray) = nblocks(block_array.block_sizes)
blocksize{T, N}(block_array::PseudoBlockArray{T,N}, i::Vararg{Int, N}) = blocksize(block_array.block_sizes, i)


############
# Indexing #
############

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
function getblock{T,N}(block_arr::PseudoBlockArray{T,N}, block_i::Int)
    range = globalrange(block_arr.block_sizes, (block_i,))
    return block_arr.blocks[range[1]]
end

function getblock{T,N}(block_arr::PseudoBlockArray{T,N}, block_i::Int, block_j::Int)
    range = globalrange(block_arr.block_sizes, (block_i, block_j))
    return block_arr.blocks[range[1], range[2]]
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

function getblock{T,N}(block_arr::PseudoBlockArray{T,N}, block::Vararg{Int, N})
    range = globalrange(block_arr.block_sizes, block)
    return block_arr.blocks[range...]
end

function _check_getblock!{T, N}(blockrange, x, block_arr::PseudoBlockArray{T,N}, block::NTuple{N, Int})
    for i in 1:N
        if size(x, i) != length(blockrange[i])
            throw(DimensionMismatch(string("tried to assign ", blocksize(block_arr, block...), " block to $(size(x)) array")))
        end
    end
end

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds function getblock!{T}(x, block_arr::PseudoBlockArray{T,1}, block_i::Int)
    blockrange = globalrange(block_arr.block_sizes, (block_i,))
    @boundscheck _check_getblock!(blockrange, x, block_arr, (block_i,))

    arr = block_arr.blocks
    k_1 = 1
    @inbounds for i in blockrange[1]
        x[k_1] = arr[i]
        k_1 += 1
    end
    return x
end

@propagate_inbounds function getblock!{T}(x, block_arr::PseudoBlockArray{T,2}, block_i::Int, block_j::Int)
    blockrange = globalrange(block_arr.block_sizes, (block_i,block_j))
    @boundscheck _check_getblock!(blockrange, x, block_arr, (block_i, block_j))

    arr = block_arr.blocks
    k_2 = 1
    @inbounds for j in blockrange[2]
        k_1 = 1
        for i in blockrange[1]
            x[k_1, k_2] = arr[i, j]
            k_1 += 1
        end
        k_2 += 1
    end
    return x
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

@generated function getblock!{T,N}(x, block_arr::PseudoBlockArray{T,N}, block::Vararg{Int, N})
    return quote
        blockrange = globalrange(block_arr.block_sizes, block)
        @boundscheck _check_getblock!(blockrange, x, block_arr, block)

        arr = block_arr.blocks
        @nexprs $N d -> k_d = 1
        @inbounds begin
            @nloops $N i (d->(blockrange[d])) (d-> k_{d-1}=1) (d-> k_d+=1) begin
                (@nref $N x k) = (@nref $N arr i)
            end
        end
        return x
    end
end

function _check_setblock!{T, N}(blockrange, x, block_arr::PseudoBlockArray{T,N}, block::NTuple{N, Int})
    for i in 1:N
        if size(x, i) != block_arr.block_sizes[i, block[i]]
            throw(DimensionMismatch(string("tried to assign $(size(x)) array to ", blocksize(block_arr, block...), " block")))
        end
    end
end

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds function setblock!{T}(block_arr::PseudoBlockArray{T,1}, x, block_i::Int)
    blockrange = globalrange(block_arr.block_sizes, (block_i,))
    @boundscheck _check_setblock!(blockrange, x, block_arr, (block_i,))

    arr = block_arr.blocks
    k_1 = 1
    @inbounds for i in blockrange[1]
        arr[i] = x[k_1]
        k_1 += 1
    end
    return x
end

@propagate_inbounds function setblock!{T}(block_arr::PseudoBlockArray{T,2}, x, block_i::Int, block_j::Int)
    blockrange = globalrange(block_arr.block_sizes, (block_i,block_j))
    @boundscheck _check_setblock!(blockrange, x, block_arr, (block_i, block_j))

    arr = block_arr.blocks
    k_2 = 1
    @inbounds for j in blockrange[2]
        k_1 = 1
        for i in blockrange[1]
            arr[i, j] = x[k_1, k_2]
            k_1 += 1
        end
        k_2 += 1
    end
    return x
end
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #

@generated function setblock!{T, N}(block_arr::PseudoBlockArray{T, N}, x, block::Vararg{Int, N})
    return quote
        blockrange = globalrange(block_arr.block_sizes, block)
        @boundscheck _check_setblock!(blockrange, x, block_arr, block)
        arr = block_arr.blocks
        @nexprs $N d -> k_d = 1
        @inbounds begin
            @nloops $N i (d->(blockrange[d])) (d-> k_{d-1}=1) (d-> k_d+=1) begin
                (@nref $N arr i) = (@nref $N x k)
            end
        end
    end
end

########
# Misc #
########

function Base.full{T,N,R}(block_array::PseudoBlockArray{T, N, R})
    return block_array.blocks
end
