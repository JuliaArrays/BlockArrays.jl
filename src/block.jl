# Note: Functions surrounded by a comment blocks are there because `Vararg` is sitll allocating.
# When Vararg is fast enough, they can simply be removed

"""
A `Block` is simply a wrapper around a set of indixes so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the the returned object value be that block.
"""
immutable Block{N}
    n::NTuple{N, Int}
end

Block{N}(n::Vararg{Int, N}) = Block{N}(n)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds Base.getindex{T}(block_arr::AbstractBlockArray{T,1}, block::Block{1}) = getblock(block_arr, block.n[1])
@propagate_inbounds Base.getindex{T}(block_arr::AbstractBlockArray{T,2}, block::Block{2}) = getblock(block_arr, block.n[1], block.n[2])
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
@propagate_inbounds Base.getindex{T,N}(block_arr::AbstractBlockArray{T,N}, block::Block{N}) = getblock(block_arr, block.n...)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds Base.setindex!{T}(block_arr::AbstractBlockArray{T,1}, v, block::Block{1}) =  setblock!(block_arr, v, block.n[1])
@propagate_inbounds Base.setindex!{T}(block_arr::AbstractBlockArray{T,2}, v, block::Block{2}) =  setblock!(block_arr, v, block.n[1], block.n[2])
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
@propagate_inbounds Base.setindex!{T,N}(block_arr::AbstractBlockArray{T,N}, v, block::Block{N}) =  setblock!(block_arr, v, block.n...)

