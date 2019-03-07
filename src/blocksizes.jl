##############
# BlockSizes #
##############

abstract type AbstractBlockSizes{N} end

# Keeps track of the (cumulative) sizes of all the blocks in the `BlockArray`.
struct BlockSizes{N,VT<:AbstractVector{Int}} <: AbstractBlockSizes{N}
    cumul_sizes::NTuple{N,VT}
    # Takes a tuple of sizes, accumulates them and create a `BlockSizes`
    BlockSizes{N,VT}() where {N,VT<:AbstractVector{Int}} = new{N,VT}()
    BlockSizes{N,VT}(cs::NTuple{N,VT}) where {N,VT<:AbstractVector{Int}} = new{N,VT}(cs)
end

BlockSizes{N}(cs::NTuple{N,VT}) where {N,VT<:AbstractVector{Int}} = BlockSizes{N,VT}(cs)
BlockSizes{N}() where N = BlockSizes{N,Vector{Int}}()
BlockSizes() = BlockSizes{0}()

BlockSizes(cs::NTuple{N,VT}) where {N,VT<:AbstractVector{Int}} = BlockSizes{N}(cs)

function BlockSizes(sizes::Vararg{AbstractVector{Int}, N}) where {N}
    cumul_sizes = ntuple(k -> _cumul_vec(sizes[k]), Val(N))
    return BlockSizes(cumul_sizes)
end

Base.:(==)(a::BlockSizes, b::BlockSizes) = cumulsizes(a) == cumulsizes(b)

Base.dataids(b::BlockSizes) = _splatmap(dataids, b.cumul_sizes)
# _splatmap taken from Base:
_splatmap(f, ::Tuple{}) = ()
_splatmap(f, t::Tuple) = (f(t[1])..., _splatmap(f, tail(t))...)

function _cumul_vec(v::AbstractVector{T}) where {T}
    v_cumul = similar(v, length(v) + 1)
    z = one(T)
    v_cumul[1] = z
    for i in eachindex(v)
        z += v[i]
        v_cumul[i+1] = z
    end
    return v_cumul
end

@propagate_inbounds cumulsizes(block_sizes::BlockSizes) = block_sizes.cumul_sizes
@propagate_inbounds cumulsizes(block_sizes::AbstractBlockSizes, i) = cumulsizes(block_sizes)[i]
@propagate_inbounds cumulsizes(block_sizes::AbstractBlockSizes, i, j) = cumulsizes(block_sizes,i)[j]

@propagate_inbounds blocksize(block_sizes::AbstractBlockSizes, i, j) =
    cumulsizes(block_sizes, i, j+1) - cumulsizes(block_sizes, i, j)

# ntuple with Val was slow here. @generated it is!
@generated function blocksize(block_sizes::AbstractBlockSizes{N}, i::NTuple{N, Int}) where {N}
    exp = Expr(:tuple, [:(blocksize(block_sizes, $k, i[$k])) for k in 1:N]...)
    return exp
end

# Gives the total sizes
@generated function Base.size(block_sizes::AbstractBlockSizes{N}) where {N}
    exp = Expr(:tuple, [:(cumulsizes(block_sizes, $i)[end] - 1) for i in 1:N]...)
    return quote
        @inbounds return $exp
    end
end

@inline function Base.size(block_sizes::AbstractBlockSizes{1})
    (cumulsizes(block_sizes,1)[end] - 1,)
end

@inline function Base.size(block_sizes::AbstractBlockSizes{2})
    (cumulsizes(block_sizes,1)[end] - 1,cumulsizes(block_sizes,2)[end] - 1)
end

function Base.show(io::IO, block_sizes::AbstractBlockSizes{N}) where {N}
    if N == 0
        print(io, "[]")
    else
        print(io, diff(cumulsizes(block_sizes,1)))
        for i in 2:N
            print(io, " × ", diff(cumulsizes(block_sizes,i)))
        end
    end
end

@inline function searchlinear(vec::AbstractVector, a)
    l = length(vec)
    @inbounds for i in 1:l
        vec[i] > a && return i - 1
    end
    return l
end

_find_block(bs::AbstractVector, i::Integer) = length(bs) > 10 ? last(searchsorted(bs, i)) : searchlinear(bs, i)

@inline function _find_block(block_sizes::AbstractBlockSizes, dim::Int, i::Int)
    bs = cumulsizes(block_sizes, dim)
    block = _find_block(bs, i)
    @inbounds cum_size = cumulsizes(block_sizes, dim, block) - 1
    return block, i - cum_size
end

@generated function nblocks(block_sizes::AbstractBlockSizes{N}) where {N}
    ex = Expr(:tuple, [:(nblocks(block_sizes, $i)) for i in 1:N]...)
    return quote
        @inbounds return $ex
    end
end

@inline @propagate_inbounds nblocks(block_sizes::AbstractBlockSizes, i::Int) =
    length(cumulsizes(block_sizes,i)) - 1

function nblocks(block_sizes::AbstractBlockSizes, i::Vararg{Int, N}) where {N}
    b = nblocks(block_sizes)
    return ntuple(k-> b[i[k]], Val(N))
end


# ntuple is yet again slower
@generated function Base.copy(block_sizes::BlockSizes{N}) where {N}
    exp = Expr(:tuple, [:(copy(cumulsizes(block_sizes, $k))) for k in 1:N]...)
    return quote
        BlockSizes($exp)
    end
end

# Computes the global range of an Array that corresponds to a given block_index
@generated function globalrange(block_sizes::AbstractBlockSizes{N}, block_index::NTuple{N, Int}) where {N}
    indices_ex = Expr(:tuple, [:(cumulsizes(block_sizes, $i, block_index[$i]):cumulsizes(block_sizes, $i, block_index[$i] + 1) - 1) for i = 1:N]...)
    return quote
        $(Expr(:meta, :inline))
        @inbounds inds = $indices_ex
        return inds
    end
end

# I hate having these function definitions but the generated function above sometimes(!) generates bad code and starts to allocate
@inline function globalrange(block_sizes::AbstractBlockSizes{1}, block_index::NTuple{1, Int})
    @inbounds v = (cumulsizes(block_sizes, 1, block_index[1]):cumulsizes(block_sizes, 1, block_index[1] + 1) - 1,)
    return v
end

@inline function globalrange(block_sizes::AbstractBlockSizes{2}, block_index::NTuple{2, Int})
    @inbounds v = (cumulsizes(block_sizes, 1, block_index[1]):cumulsizes(block_sizes, 1, block_index[1] + 1) - 1,
                   cumulsizes(block_sizes, 2, block_index[2]):cumulsizes(block_sizes, 2, block_index[2] + 1) - 1)
    return v
end

@inline function globalrange(block_sizes::AbstractBlockSizes{3}, block_index::NTuple{3, Int})
    @inbounds v = (cumulsizes(block_sizes, 1, block_index[1]):cumulsizes(block_sizes, 1, block_index[1] + 1) - 1,
                   cumulsizes(block_sizes, 2, block_index[2]):cumulsizes(block_sizes, 2, block_index[2] + 1) - 1,
                   cumulsizes(block_sizes, 3, block_index[3]):cumulsizes(block_sizes, 3, block_index[3] + 1) - 1)
    return v
end



"""
    blocksizes(A)

returns a subtype of `AbstractBlockSizes` that contains information about the
block sizes of `A`. Any subtype of AbstractBlockArrays must override this.
"""
blocksizes(A::AbstractBlockArray) = error("blocksizes for $(typeof(A)) is not implemented")

@inline nblocks(block_array::AbstractArray) = nblocks(blocksizes(block_array))

"""
    blocksize(A, inds)

Returns a tuple containing the size of the block at block index `inds`.

```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray(rand(5, 4, 6), [1, 4], [1, 2, 1], [1, 2, 2, 1]);

julia> blocksize(A, (1, 3, 2))
(1, 1, 2)

julia> blocksize(A, (2, 1, 3))
(4, 1, 2)
```
"""
@inline blocksize(block_array::AbstractArray, i::Int...) =
    blocksize(blocksizes(block_array), i...)

@inline blocksize(block_array::AbstractArray{T,N}, i::NTuple{N, Int}) where {T, N} =
    blocksize(blocksizes(block_array), i)

@inline Base.size(arr::AbstractBlockArray) = size(blocksizes(arr))

cumulsizes(A::AbstractArray) = cumulsizes(blocksizes(A))
@inline cumulsizes(A::AbstractArray, i) = cumulsizes(blocksizes(A), i)
@inline cumulsizes(A::AbstractArray, i, j) = cumulsizes(blocksizes(A), i, j)
