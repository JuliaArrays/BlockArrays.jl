"""
    BlockIndex{N}

A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.

It can be used to index into `BlockArrays` in the following manner:

```jldoctest; setup = quote using BlockArrays end
julia> arr = Array(reshape(1:25, (5,5)));

julia> a = PseudoBlockArray(arr, [3,2], [1,4])
2×2-blocked 5×5 PseudoBlockArray{Int64,2}:
 1  │   6  11  16  21
 2  │   7  12  17  22
 3  │   8  13  18  23
 ───┼────────────────
 4  │   9  14  19  24
 5  │  10  15  20  25

julia> a[BlockIndex((1,2), (1,2))]
11

julia> a[BlockIndex((2,2), (2,3))]
20
```
"""
struct BlockIndex{N}
    I::NTuple{N, Int}
    α::NTuple{N, Int}
end

@inline BlockIndex(a::Int, b::Int) = BlockIndex((a,), (b,))
@inline BlockIndex(a::Tuple, b::Int) = BlockIndex(a, (b,))
@inline BlockIndex(a::Int, b::Tuple) = BlockIndex((a,), b)

@inline BlockIndex(a::Block, b::Tuple) = BlockIndex(a.n, b)
@inline BlockIndex(a::Block, b::Int) = BlockIndex(a, (b,))

@generated function BlockIndex(I::NTuple{N, Int}, α::NTuple{M, Int}) where {M,N}
    @assert M < N
    α_ex = Expr(:tuple, [k <= M ? :(α[$k]) : :(1) for k = 1:N]...)
    return quote
        $(Expr(:meta, :inline))
        @inbounds α2 = $α_ex
        BlockIndex(I, α2)
    end
end

"""
    global2blockindex{N}(block_sizes::BlockSizes{N}, inds...) -> BlockIndex{N}

Converts from global indices `inds` to a `BlockIndex`.
"""
@generated function global2blockindex(block_sizes::AbstractBlockSizes{N}, i::NTuple{N, Int}) where {N}
    block_index_ex = Expr(:tuple, [:(_find_block(block_sizes, $k, i[$k])) for k = 1:N]...)
    I_ex = Expr(:tuple, [:(block_index[$k][1]) for k = 1:N]...)
    α_ex = Expr(:tuple, [:(block_index[$k][2]) for k = 1:N]...)
    return quote
        $(Expr(:meta, :inline))
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
@generated function blockindex2global(block_sizes::AbstractBlockSizes{N}, block_index::BlockIndex{N}) where {N}
    ex = Expr(:tuple, [:(cumulsizes(block_sizes, $k, block_index.I[$k]) + block_index.α[$k] - 1) for k = 1:N]...)
    return quote
        $(Expr(:meta, :inline))
        @inbounds v = $ex
        return $ex
    end
end

# I hate having these function definitions but the generated function above sometimes(!) generates bad code and starts to allocate
@inline function blockindex2global(block_sizes::AbstractBlockSizes{1}, block_index::BlockIndex{1})
    @inbounds v =(cumulsizes(block_sizes, 1, block_index.I[1]) + block_index.α[1] - 1,)
    return v
end

@inline function blockindex2global(block_sizes::AbstractBlockSizes{2}, block_index::BlockIndex{2})
    @inbounds v =(cumulsizes(block_sizes, 1, block_index.I[1]) + block_index.α[1] - 1,
                  cumulsizes(block_sizes, 2, block_index.I[2]) + block_index.α[2] - 1)
    return v
end

@inline function blockindex2global(block_sizes::AbstractBlockSizes{3}, block_index::BlockIndex{3})
    @inbounds v =(cumulsizes(block_sizes, 1, block_index.I[1]) + block_index.α[1] - 1,
                  cumulsizes(block_sizes, 2, block_index.I[2]) + block_index.α[2] - 1,
                  cumulsizes(block_sizes, 3, block_index.I[3]) + block_index.α[3] - 1)
    return v
end


##
# checkindex
##

@inline checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::Block{N}) where N = blockcheckbounds(Bool, A, I.n...)
@inline function checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::BlockIndex{N}) where N
    checkbounds(Bool, A, Block(I.I)) || return false
    @inbounds block = getblock(A, I.I...)
    checkbounds(Bool, block, I.α...)
end

checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::AbstractVector{BlockIndex{N}}) where N = 
    all(checkbounds.(Bool, Ref(A), I))
