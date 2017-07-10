# Note: Functions surrounded by a comment blocks are there because `Vararg` is still allocating.
# When Vararg is fast enough, they can simply be removed.

#=======================
 BlockTridiagMatrix
=======================#

"""
    BlockTridiagMatrix{T, R <: AbstractMatrix{T}} <: AbstractBlockArray{T, N}

A `BlockTridiagMatrix` is a block tridiagonal matrix where each block is stored contiguously. 
This means that insertions and retrieval of blocks
can be very fast and non allocating since no copying of data is needed.

In the type definition, `R` defines the array type that each block has, 
for example `Matrix{Float64}.
"""
struct BlockTridiagMatrix{T, R <: AbstractMatrix{T}} <: AbstractBlockMatrix{T}
    diagl::Vector{R}
    lower::Vector{R}
    upper::Vector{R}
    block_sizes::BlockSizes{2}
end

# Auxilary outer constructors
function BlockTridiagMatrix{T, R <: AbstractArray{T}
                           }(diagl::Vector{R}, 
                             lower::Vector{R}, 
                             upper::Vector{R},
                             block_sizes::BlockSizes{2})
   return BlockTridiagMatrix{T, R}(diagl, lower, upper, block_sizes)
end

function BlockTridiagMatrix{T, R <: AbstractArray{T}}(diagl::Vector{R}, lower::Vector{R}, upper::Vector{R}, 
                            block_sizes::Vararg{Vector{Int}, 2})
    return BlockTridiagMatrix{T, R}(diagl, lower, upper, 
                                    BlockSizes(block_sizes...))
end


################
# Constructors #
################

"""
Constructs a `BlockTridiagMatrix` with uninitialized blocks from a block type `R` 
with sizes defind by `block_sizes`.

```jldoctest
julia> BlockTridiagMatrix(Matrix{Float64}, [1,3], [2,2])
2×2-blocked 4×4 BlockArrays.BlockTridiagMatrix{Float64,2,Array{Float64,2}}:
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
 #undef  │  #undef  #undef  #undef  │
 --------┼--------------------------┼
 #undef  │  #undef  #undef  #undef  │
```
"""
@inline function BlockTridiagMatrix{T, R <: AbstractMatrix{T}
                                   }(::Type{R}, 
                                     block_sizes::Vararg{Vector{Int}, 2})
    BlockTridiagMatrix(R, BlockSizes(block_sizes...))
end

function BlockTridiagMatrix{T, R <: AbstractMatrix{T}}(::Type{R}, block_sizes::BlockSizes{2})
    n_blocks = nblocks(block_sizes)
    n_blocks[1] == n_blocks[2] || throw("expect same number of blocks in both dimensions")
    diagl = Vector{R}(n_blocks[1])
    lower = Vector{R}(n_blocks[1]-1)
    upper = Vector{R}(n_blocks[1]-1)
    BlockTridiagMatrix{T,R}(diagl, lower, upper, block_sizes)
end

function BlockTridiagMatrix(arr::AbstractMatrix, 
                            block_sizes::Vararg{Vector{Int}, 2})
    for i in 1:2
        if sum(block_sizes[i]) != size(arr, i)
            throw(DimensionMismatch(
                    "block size for dimension $i: $(block_sizes[i])" *
                    "does not sum to the array size: $(size(arr, i))"))
        end
    end

    _block_sizes = BlockSizes(block_sizes...)
    bltrid_mat = BlockTridiagMatrix(typeof(arr), _block_sizes)
    row_blocks, col_blocks = nblocks(bltrid_mat)
    for brow in 1:row_blocks
        for bcol in max(1,brow-1):min(brow+1,col_blocks)
            indices = globalrange(_block_sizes, (brow,bcol))
            setblock!(bltrid_mat, arr[indices...], brow, bcol)
        end
    end

    return bltrid_mat
end

################################
# AbstractBlockArray Interface #
################################
@inline nblocks(bltrid_mat::BlockTridiagMatrix) = nblocks(bltrid_mat.block_sizes)
@inline blocksize(bltrid_mat::BlockTridiagMatrix, i::Int, j::Int) = blocksize(bltrid_mat.block_sizes, (i, j))

@inline function getblock(bltrid_mat::BlockTridiagMatrix, i::Int, j::Int)
    @boundscheck blockcheckbounds(bltrid_mat, i, j)
    if i==j
        # for blocks on the diagonal,
        # get the block from `diagl`
        return bltrid_mat.diagl[i]
    elseif i==j+1
        # for blocks below the diagonal,
        # get the block from `lower`
        return bltrid_mat.lower[j]
    elseif i+1==j
        # for blocks above the diagonal,
        # get the block from `upper`
        return bltrid_mat.upper[i]
    else
        # otherwise return a freshly-baked
        # matrix of zeros (with a warning
        # because that's dumb)
        warn(@sprintf("""The (%d,%d) block of a block tridiagonal matrix
                         is just zeros. It's wasteful to obtain this block.
                         """, i, j),
             once=true,
             key="blocktridiagonal_inefficient_getblock")
        return zeros(eltype(bltrid_mat), blocksize(bltrid_mat, i,  j))
    end
end

@inline function Base.getindex(bltrid_mat::BlockTridiagMatrix, blockindex::BlockIndex{2})
    block_i, block_j = blockindex.I
    @boundscheck blockcheckbounds(bltrid_mat, block_i, block_j)
    if abs(block_i-block_j) > 1
        return zero(eltype(bltrid_mat))
    end
    @inbounds block = getblock(bltrid_mat, blockindex.I...)
    @boundscheck checkbounds(block, blockindex.α...)
    @inbounds v = block[blockindex.α...]
    return v
end


###########################
# AbstractArray Interface #
###########################

@inline function Base.similar{T2}(bltrid_mat::BlockTridiagMatrix, 
                                    ::Type{T2})
    diagl = bltrid_mat.diagl
    lower = bltrid_mat.lower
    upper = bltrid_mat.upper
    BlockTridiagMatrix(similar(diagl, Matrix{T2}),
                       similar(lower, Matrix{T2}),
                       similar(upper, Matrix{T2}),
                       copy(bltrid_mat.block_sizes))
end

function Base.size(arr::BlockTridiagMatrix)
    return (arr.block_sizes[1][end]-1, 
            arr.block_sizes[2][end]-1)
end

@inline function Base.getindex(bltrid_mat::BlockTridiagMatrix, i::Vararg{Int, 2})
    @boundscheck checkbounds(bltrid_mat, i...)
    @inbounds v = bltrid_mat[global2blockindex(bltrid_mat.block_sizes, i)]
    return v
end

@inline function Base.setindex!(bltrid_mat::BlockTridiagMatrix, v, i::Vararg{Int, 2})
    @boundscheck checkbounds(bltrid_mat, i...)
    @inbounds bltrid_mat[global2blockindex(bltrid_mat.block_sizes, i)] = v
    return bltrid_mat
end

############
# Indexing #
############

function _check_setblock!(bltrid_mat::BlockTridiagMatrix, v, i::Int, j::Int)
    if size(v) != blocksize(bltrid_mat, i, j)
        throw(DimensionMismatch(string("tried to assign $(size(v)) array to ", blocksize(bltrid_mat, i, j), " block")))
    end
end


@inline function setblock!(bltrid_mat::BlockTridiagMatrix, v, i::Int, j::Int)
    @boundscheck blockcheckbounds(bltrid_mat, i, j)
    @boundscheck _check_setblock!(bltrid_mat, v, i, j)
    @inbounds begin
        if i==j
            # for blocks on the diagonal,
            # get the block from `diagl`
            bltrid_mat.diagl[i] = v
        elseif i==j+1
            # for blocks below the diagonal,
            # get the block from `lower`
            bltrid_mat.lower[j] = v
        elseif i+1==j
            # for blocks above the diagonal,
            # get the block from `upper`
            bltrid_mat.upper[i] = v
        else
            throw("tried to set zero block of BlockTridiagMatrix")
        end
    end
    return bltrid_mat
end

@propagate_inbounds function Base.setindex!{T,N}(bltrid_mat::BlockTridiagMatrix{T, N}, v, block_index::BlockIndex{N})
    getblock(bltrid_mat, block_index.I...)[block_index.α...] = v
end

########
# Misc #
########

function Base.Array{T,R}(bltrid_mat::BlockTridiagMatrix{T, R})
    # TODO: This will fail for empty block array
    block_sizes = bltrid_mat.block_sizes
    row_blocks, col_blocks = nblocks(bltrid_mat)
    arr = zeros(T, size(bltrid_mat))
    for brow in 1:row_blocks
        for bcol in max(1,brow-1):min(brow+1,col_blocks)
            indices = globalrange(block_sizes, (brow,bcol))
            arr[indices...] = getblock(bltrid_mat, brow, bcol)
        end
    end
    return arr
end

function Base.copy!{T, R<:AbstractArray{T}, M<:AbstractArray{T}
                   }(bltrid_mat::BlockTridiagMatrix{T, R}, arr::M)
    block_sizes = bltrid_mat.block_sizes
    row_blocks, col_blocks = nblocks(bltrid_mat)
    for brow in 1:row_blocks
        for bcol in max(1,brow-1):min(brow+1,col_blocks)
            indices = globalrange(block_sizes, (brow,bcol))
            copy!(getblock(bltrid_mat, brow, bcol), view(arr, indices...))
        end
    end
    return bltrid_mat
end
