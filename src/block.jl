"""
A `Block` is simply a wrapper around a set of indixes so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the the returned object value be that block.
"""
immutable Block{N}
    n::NTuple{N, Int}
end

Block{N}(n::Vararg{Int, N}) = Block{N}(n)

@propagate_inbounds Base.setindex!{T,N,R}(block_arr::AbstractBlockArray{T,N,R}, v, block::Block{N}) =  setblock!(block_arr, v, block.n...)
@propagate_inbounds Base.getindex{T,N}(block_arr::AbstractBlockArray{T,N}, block::Block{N}) = getblock(block_arr, block.n...)
