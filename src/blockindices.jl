"""
    BlockIndex{N}

A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.
"""
immutable BlockIndex{N}
    I::NTuple{N, Int}
    α::NTuple{N, Int}
end


"""
    global2blockindex{N}(block_sizes::BlockSizes{N}, inds...) -> BlockIndex{N}

Converts from global indices `inds` to a `BlockIndex`.
"""
@generated function global2blockindex{N}(block_sizes::BlockSizes{N}, i::NTuple{N, Int})
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
    blockindex2global{N}(block_sizes::BlockSizes{N}, block_index::BlockIndex{N}) -> inds

Converts from a block index to a tuple containing the global indices
"""
@generated function blockindex2global{N}(block_sizes::BlockSizes{N}, block_index::BlockIndex{N})
    ex = Expr(:tuple, [:(block_sizes[$k, block_index.I[$k]] + block_index.α[$k] - 1) for k = 1:N]...)
    return quote
        @inbounds v = $ex
        return $ex
    end
end
