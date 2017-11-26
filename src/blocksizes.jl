##############
# BlockSizes #
##############

# Keeps track of the (cumulative) sizes of all the blocks in the `BlockArray`.
struct BlockSizes{N}
    cumul_sizes::NTuple{N, Vector{Int}}
    # Takes a tuple of sizes, accumulates them and create a `BlockSizes`
end

function BlockSizes(sizes::Vararg{Vector{Int}, N}) where {N}
    cumul_sizes = ntuple(k -> _cumul_vec(sizes[k]), Val(N))
    return BlockSizes(cumul_sizes)
end

BlockSizes(sizes::Vararg{AbstractVector{Int}, N}) where {N} =
    BlockSizes(Vector{Int}.(sizes)...)

Base.:(==)(a::BlockSizes, b::BlockSizes) = a.cumul_sizes == b.cumul_sizes

function _cumul_vec(v::Vector{T}) where {T}
    v_cumul = similar(v, length(v) + 1)
    z = one(T)
    v_cumul[1] = z
    for i in eachindex(v)
        z += v[i]
        v_cumul[i+1] = z
    end
    return v_cumul
end

@propagate_inbounds Base.getindex(block_sizes::BlockSizes, i) = block_sizes.cumul_sizes[i]
@propagate_inbounds Base.getindex(block_sizes::BlockSizes, i, j) = block_sizes.cumul_sizes[i][j]

@propagate_inbounds blocksize(block_sizes::BlockSizes, i, j) = block_sizes[i, j+1] - block_sizes[i, j]

# ntuple with Val was slow here. @generated it is!
@generated function blocksize(block_sizes::BlockSizes{N}, i::NTuple{N, Int}) where {N}
    exp = Expr(:tuple, [:(blocksize(block_sizes, $k, i[$k])) for k in 1:N]...)
    return exp
end

# Gives the total sizes
@generated function Base.size(block_sizes::BlockSizes{N}) where {N}
    exp = Expr(:tuple, [:(block_sizes[$i][end] - 1) for i in 1:N]...)
    return quote
        @inbounds return $exp
    end
end

function Base.show(io::IO, block_sizes::BlockSizes{N}) where {N}
    if N == 0
        print(io, "[]")
    else
        print(io, diff(block_sizes[1]))
        for i in 2:N
            print(io, " × ", diff(block_sizes[i]))
        end
    end
end

@inline function searchlinear(vec::Vector, a)
    l = length(vec)
    @inbounds for i in 1:l
        vec[i] > a && return i - 1
    end
    return l
end

@inline function _find_block(block_sizes::BlockSizes, dim::Int, i::Int)
    bs = block_sizes[dim]
    block = 0
    if length(bs) > 10
        block = last(searchsorted(bs, i))
    else
        block = searchlinear(bs, i)
    end
    @inbounds cum_size = block_sizes[dim, block] - 1
    return block, i - cum_size
end

@generated function nblocks(block_sizes::BlockSizes{N}) where {N}
    ex = Expr(:tuple, [:(nblocks(block_sizes, $i)) for i in 1:N]...)
    return quote
        @inbounds return $ex
    end
end

@inline @propagate_inbounds nblocks(block_sizes::BlockSizes, i::Int) = length(block_sizes[i]) - 1


# ntuple is yet again slower
@generated function Base.copy(block_sizes::BlockSizes{N}) where {N}
    exp = Expr(:tuple, [:(copy(block_sizes[$k])) for k in 1:N]...)
    return quote
        BlockSizes($exp)
    end
end

# Computes the global range of an Array that corresponds to a given block_index
@generated function globalrange(block_sizes::BlockSizes{N}, block_index::NTuple{N, Int}) where {N}
    indices_ex = Expr(:tuple, [:(block_sizes[$i, block_index[$i]]:block_sizes[$i, block_index[$i] + 1] - 1) for i = 1:N]...)
    return quote
        $Expr(:meta, :inline)
        @inbounds inds = $indices_ex
        return inds
    end
end

# I hate having these function definitions but the generated function above sometimes(!) generates bad code and starts to allocate
@inline function globalrange(block_sizes::BlockSizes{1}, block_index::NTuple{1, Int})
    @inbounds v = (block_sizes[1, block_index[1]]:block_sizes[1, block_index[1] + 1] - 1,)
    return v
end

@inline function globalrange(block_sizes::BlockSizes{2}, block_index::NTuple{2, Int})
    @inbounds v = (block_sizes[1, block_index[1]]:block_sizes[1, block_index[1] + 1] - 1,
                   block_sizes[2, block_index[2]]:block_sizes[2, block_index[2] + 1] - 1)
    return v
end

@inline function globalrange(block_sizes::BlockSizes{3}, block_index::NTuple{3, Int})
    @inbounds v = (block_sizes[1, block_index[1]]:block_sizes[1, block_index[1] + 1] - 1,
                   block_sizes[2, block_index[2]]:block_sizes[2, block_index[2] + 1] - 1,
                   block_sizes[3, block_index[3]]:block_sizes[3, block_index[3] + 1] - 1)
    return v
end
