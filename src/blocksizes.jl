##############
# BlockSizes #
##############

# Keeps track of the sizes of all the blocks in the `BlockArray`
immutable BlockSizes{N}
    sizes::NTuple{N, Vector{Int}}
end

Base.:(==)(a::BlockSizes, b::BlockSizes) = a.sizes == b.sizes

BlockSizes{N}(sizes::Vararg{Vector{Int}, N}) = BlockSizes(sizes)
Base.getindex(block_sizes::BlockSizes, i) = block_sizes.sizes[i]
Base.getindex(block_sizes::BlockSizes, i, j) = block_sizes.sizes[i][j]

function blocksize{N}(block_sizes::BlockSizes{N}, i::NTuple{N, Int})
    return ntuple(k->block_sizes[k, i[k]], Val{N})
end

function Base.show{N}(io::IO, block_sizes::BlockSizes{N})
    if N == 0
        print(io, "[]")
    else
        print(io, block_sizes.sizes[1])
        for i in 2:N
            print(io, "×", block_sizes.sizes[i])
        end
    end
end

nblocks{N}(block_sizes::BlockSizes{N}) = ntuple(i -> length(block_sizes[i]), Val{N})
nblocks(block_sizes::BlockSizes, i::Int) = length(block_sizes[i])

Base.copy{N}(block_sizes::BlockSizes{N}) = BlockSizes(ntuple(i -> copy(block_sizes[i]), Val{N}))


# Computes the global range of an Array that corresponds to a given block_index
@generated function globalrange{N}(block_sizes::BlockSizes, block_index::NTuple{N, Int})
    start_indices_ex = Expr(:tuple, [:(1 + _cumsum(block_sizes[$i], block_index[$i]-1)) for i=1:N]...)
    indices_ex = Expr(:tuple, [:(start_indices[$i]:start_indices[$i] + block_sizes[$i, block_index[$i]] - 1) for i = 1:N]...)
    return quote
        @inbounds start_indices = $start_indices_ex
        @inbounds indices = $indices_ex
        return indices
    end
end
