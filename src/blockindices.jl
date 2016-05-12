"""
A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.
"""
immutable BlockIndex{N}
    I::NTuple{N, Int}
    α::NTuple{N, Int}
end

@inline function _find_block(block_sizes::BlockSizes, dim::Int, i::Int)
    accum = 0
    block = 0
    @inbounds while accum < i
        block += 1
        accum += block_sizes[dim, block]
    end
    @inbounds accum -= block_sizes[dim, block]
    return block, i - accum
end

"""
Converts from a global index to a `BlockIndex`.
"""
@generated function global2blockindex{N}(block_sizes::BlockSizes{N}, i::NTuple{N, Int})
    # TODO: Try get rid of @generated
    block_index_ex = Expr(:tuple, [:(_find_block(block_sizes, $k, i[$k])) for k = 1:N]...)
    I_ex = Expr(:tuple, [:(block_index[$k][1]) for k = 1:N]...)
    α_ex = Expr(:tuple, [:(block_index[$k][2]) for k = 1:N]...)
    return quote
        @inbounds block_index = $block_index_ex
        @inbounds I = $I_ex
        @inbounds α = $α_ex
        return BlockIndex(I, α)
    end
end

"""
Converts from a `BlockIndex` to a global index.
"""
@generated function blockindex2global{N}(block_sizes::BlockSizes{N}, block_index::BlockIndex{N})
    # TODO: Try get rid of @generated
    ex = Expr(:tuple, [:(_sumiter(block_sizes[$k], block_index.I[$k]-1) + block_index.α[$k]) for k = 1:N]...)
    return quote
        @inbounds v = $ex
        return v
    end
end
