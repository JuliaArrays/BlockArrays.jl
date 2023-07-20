
# interface

@propagate_inbounds getindex(b::AbstractVector, K::BlockIndex{1}) = b[Block(K.I[1])][K.α[1]]
@propagate_inbounds getindex(b::AbstractArray{T,N}, K::BlockIndex{N}) where {T,N} =
    b[block(K)][K.α...]
@propagate_inbounds getindex(b::AbstractArray, K::BlockIndex{1}, J::BlockIndex{1}...) =
    b[BlockIndex(tuple(K, J...))]

@propagate_inbounds getindex(b::AbstractArray{T,N}, K::BlockIndexRange{N}) where {T,N} = b[block(K)][K.indices...]
@propagate_inbounds getindex(b::LayoutArray{T,N}, K::BlockIndexRange{N}) where {T,N} = b[block(K)][K.indices...]
@propagate_inbounds getindex(b::LayoutArray{T,1}, K::BlockIndexRange{1}) where {T} = b[block(K)][K.indices...]

function findblockindex(b::AbstractVector, k::Integer)
    @boundscheck k in b || throw(BoundsError())
    bl = blocklasts(b)
    blockidx = _searchsortedfirst(bl, k)
    @assert blockindex != lastindex(bl) + 1 # guaranteed by the @boundscheck above
    prevblocklast = blockidx == firstindex(bl) ? first(b)-1 : bl[blockidx-1]
    local_index = k - prevblocklast
    return BlockIndex(blockidx, local_index)
end

function _BlockedUnitRange end


"""
    BlockedUnitRange

is an `AbstractUnitRange{Int}` that has been divided
into blocks, and is used to represent axes of block arrays.
Construction is typically via `blockedrange` which converts
a vector of block lengths to a `BlockedUnitRange`.

# Examples
```jldoctest
julia> blockedrange([2,2,3])
3-blocked 7-element BlockedUnitRange{Vector{Int64}}:
 1
 2
 ─
 3
 4
 ─
 5
 6
 7
```
"""
struct BlockedUnitRange{CS} <: AbstractUnitRange{Int}
    first::Int
    lasts::CS
    global _BlockedUnitRange(f, cs::CS) where CS = new{CS}(f, cs)
end

const DefaultBlockAxis = BlockedUnitRange{Vector{Int}}

@inline _BlockedUnitRange(cs) = _BlockedUnitRange(1,cs)


BlockedUnitRange(::BlockedUnitRange) = throw(ArgumentError("Forbidden due to ambiguity"))
_blocklengths2blocklasts(blocks) = cumsum(blocks) # extra level to allow changing default cumsum behaviour
@inline blockedrange(blocks::Union{Tuple,AbstractVector}) = _BlockedUnitRange(_blocklengths2blocklasts(blocks))

@inline blockfirsts(a::BlockedUnitRange) = [a.first; @views(a.lasts[1:end-1]) .+ 1]
# optimize common cases
@inline function blockfirsts(a::BlockedUnitRange{<:Union{Vector, RangeCumsum{<:Any, <:UnitRange}}})
    v = Vector{eltype(a)}(undef, length(a.lasts))
    v[1] = a.first
    v[2:end] .= @views(a.lasts[oneto(end-1)]) .+ 1
    return v
end
@inline blocklasts(a::BlockedUnitRange) = a.lasts

_diff(a::AbstractVector) = diff(a)
_diff(a::Tuple) = diff(collect(a))
@inline blocklengths(a::BlockedUnitRange) = isempty(a.lasts) ? [_diff(a.lasts);] : [first(a.lasts)-a.first+1; _diff(a.lasts)]

length(a::BlockedUnitRange) = isempty(a.lasts) ? 0 : Integer(last(a.lasts)-a.first+1)

"""
   blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int})

Check if `a` and `b` have the same block structure.

# Examples
```jldoctest
julia> b1 = blockedrange(1:2)
2-blocked 3-element BlockedUnitRange{ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}}:
 1
 ─
 2
 3

julia> b2 = blockedrange([1,1,1])
3-blocked 3-element BlockedUnitRange{Vector{Int64}}:
 1
 ─
 2
 ─
 3

julia> blockisequal(b1, b1)
true

julia> blockisequal(b1, b2)
false
```
"""
blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int}) = first(a) == first(b) && blocklasts(a) == blocklasts(b)
blockisequal(a, b, c, d...) = blockisequal(a,b) && blockisequal(b,c,d...)
"""
   blockisequal(a::Tuple, b::Tuple)

Return `all(blockisequal.(a,b))``
"""
blockisequal(a::Tuple, b::Tuple) = all(blockisequal.(a, b))


Base.convert(::Type{BlockedUnitRange}, axis::BlockedUnitRange) = axis
Base.convert(::Type{BlockedUnitRange}, axis::AbstractUnitRange{Int}) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange}, axis::Base.Slice) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange}, axis::Base.IdentityUnitRange) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange{CS}}, axis::BlockedUnitRange{CS}) where CS = axis
Base.convert(::Type{BlockedUnitRange{CS}}, axis::BlockedUnitRange) where CS = _BlockedUnitRange(first(axis), convert(CS, blocklasts(axis)))
Base.convert(::Type{BlockedUnitRange{CS}}, axis::AbstractUnitRange{Int}) where CS = convert(BlockedUnitRange{CS}, convert(BlockedUnitRange, axis))

Base.unitrange(b::BlockedUnitRange) = first(b):last(b)

Base.promote_rule(::Type{BlockedUnitRange{CS}}, ::Type{Base.OneTo{Int}}) where CS = UnitRange{Int}

"""
    blockaxes(A)

Return the tuple of valid block indices for array `A`.

# Examples
```jldoctest
julia> A = BlockArray([1,2,3],[2,1])
2-blocked 3-element BlockVector{Int64}:
 1
 2
 ─
 3

julia> blockaxes(A)
(BlockRange(Base.OneTo(2)),)

julia> B = BlockArray(zeros(3,4), [1,2], [1,2,1])
2×3-blocked 3×4 BlockMatrix{Float64}:
 0.0  │  0.0  0.0  │  0.0
 ─────┼────────────┼─────
 0.0  │  0.0  0.0  │  0.0
 0.0  │  0.0  0.0  │  0.0

julia> blockaxes(B)
(BlockRange(Base.OneTo(2)), BlockRange(Base.OneTo(3)))
```
"""
blockaxes(b::BlockedUnitRange) = _blockaxes(b.lasts)
_blockaxes(b::AbstractVector) = (Block.(axes(b,1)),)
_blockaxes(b::Tuple) = (Block.(Base.OneTo(length(b))),)
blockaxes(b) = blockaxes.(axes(b), 1)

"""
    blockaxes(A, d)

Return the valid range of block indices for array `A` along dimension `d`.

# Examples
```jldoctest
julia> A = BlockArray([1,2,3],[2,1])
2-blocked 3-element BlockVector{Int64}:
 1
 2
 ─
 3

julia> blockaxes(A,1)
BlockRange(Base.OneTo(2))

julia> blockaxes(A,1) |> collect
2-element Vector{Block{1, Int64}}:
 Block(1)
 Block(2)
```
"""
@inline function blockaxes(A::AbstractArray{T,N}, d) where {T,N}
    d::Integer <= N ? blockaxes(A)[d] : Base.OneTo(1)
end

"""
    blocksize(A)
    blocksize(A,i)

Return the tuple of the number of blocks along each
dimension. See also size and blocksizes.

# Examples
```jldoctest
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockMatrix{Float64}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> blocksize(A)
(2, 3)

julia> blocksize(A,2)
3
```
"""
blocksize(A) = map(length, blockaxes(A))
blocksize(A,i) = length(blockaxes(A,i))
@inline blocklength(t) = prod(blocksize(t))

"""
    blocksizes(A)
    blocksizes(A,i)

Return the tuple of the sizes of blocks along each
dimension. See also size and blocksize.

# Examples
```jldoctest
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockMatrix{Float64}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> blocksizes(A)
([2, 1], [1, 1, 1])

julia> blocksizes(A,2)
3-element Vector{Int64}:
 1
 1
 1
```
"""
blocksizes(A) = map(blocklengths, axes(A))
blocksizes(A,i) = blocklengths(axes(A,i))

axes(b::BlockedUnitRange) = (_BlockedUnitRange(blocklasts(b) .- (first(b)-1)),)
unsafe_indices(b::BlockedUnitRange) = axes(b)
first(b::BlockedUnitRange) = b.first
# ::Integer works around case where blocklasts might return different type
last(b::BlockedUnitRange)::Integer = isempty(blocklasts(b)) ? first(b)-1 : last(blocklasts(b))

# view and indexing are identical for a unitrange
Base.view(b::BlockedUnitRange, K::Block{1}) = b[K]

@propagate_inbounds function getindex(b::BlockedUnitRange, K::Block{1})
    k = Integer(K)
    bax = blockaxes(b,1)
    cs = blocklasts(b)
    @boundscheck K in bax || throw(BlockBoundsError(b, k))
    S = first(bax)
    K == S && return first(b):first(cs)
    return cs[k-1]+1:cs[k]
end

@propagate_inbounds function getindex(b::BlockedUnitRange, KR::BlockRange{1})
    cs = blocklasts(b)
    isempty(KR) && return _BlockedUnitRange(1,cs[1:0])
    K,J = first(KR),last(KR)
    k,j = Integer(K),Integer(J)
    bax = blockaxes(b,1)
    @boundscheck K in bax || throw(BlockBoundsError(b,K))
    @boundscheck J in bax || throw(BlockBoundsError(b,J))
    K == first(bax) && return _BlockedUnitRange(first(b),cs[k:j])
    _BlockedUnitRange(cs[k-1]+1,cs[k:j])
end

@propagate_inbounds function getindex(b::BlockedUnitRange, KR::BlockRange{1,Tuple{Base.OneTo{Int}}})
    cs = blocklasts(b)
    isempty(KR) && return _BlockedUnitRange(1,cs[Base.OneTo(0)])
    J = last(KR)
    j = Integer(J)
    bax = blockaxes(b,1)
    @boundscheck J in bax || throw(BlockBoundsError(b,J))
    _BlockedUnitRange(first(b),cs[Base.OneTo(j)])
end

@propagate_inbounds getindex(b::BlockedUnitRange, KR::BlockSlice) = b[KR.block]

_searchsortedfirst(a::AbstractVector, k) = searchsortedfirst(a, k)
function _searchsortedfirst(a::Tuple, k)
    k ≤ first(a) && return 1
    1+_searchsortedfirst(tail(a), k)
end
_searchsortedfirst(a::Tuple{}, k) = 1

function findblock(b::BlockedUnitRange, k::Integer)
    @boundscheck k in b || throw(BoundsError(b,k))
    Block(_searchsortedfirst(blocklasts(b), k))
end

Base.dataids(b::BlockedUnitRange) = Base.dataids(blocklasts(b))


###
# BlockedUnitRange interface
###
Base.checkindex(::Type{Bool}, b::BlockRange, K::Int) = checkindex(Bool, Int.(b), K)
Base.checkindex(::Type{Bool}, b::AbstractUnitRange{Int}, K::Block{1}) = checkindex(Bool, blockaxes(b,1), Int(K))

function Base.checkindex(::Type{Bool}, axis::BlockedUnitRange, ind::BlockIndexRange{1})
    checkindex(Bool, axis, first(ind)) && checkindex(Bool, axis, last(ind))
end
function Base.checkindex(::Type{Bool}, axis::BlockedUnitRange, ind::BlockIndex{1})
    checkindex(Bool, axis, block(ind)) && checkbounds(Bool, axis[block(ind)], blockindex(ind))
end

@propagate_inbounds function getindex(b::AbstractUnitRange{Int}, K::Block{1})
    @boundscheck K == Block(1) || throw(BlockBoundsError(b, K))
    b
end

@propagate_inbounds function getindex(b::AbstractUnitRange{Int}, K::BlockRange)
    @boundscheck K == Block.(1:1) || throw(BlockBoundsError(b, K))
    b
end

blockaxes(b::AbstractUnitRange{Int}) = (Block.(Base.OneTo(1)),)

function findblock(b::AbstractUnitRange{Int}, k::Integer)
    @boundscheck k in axes(b,1) || throw(BoundsError(b,k))
    Block(1)
end

"""
   blockfirsts(a::AbstractUnitRange{Int})

Return the first index of each block of `a`.

# Examples
```jldoctest
julia> b = blockedrange(1:3)
3-blocked 6-element BlockedUnitRange{ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}}:
 1
 ─
 2
 3
 ─
 4
 5
 6

julia> blockfirsts(b)
3-element Vector{Int64}:
 1
 2
 4
```
"""
blockfirsts(a::AbstractUnitRange{Int}) = Ones{Int}(1)
"""
   blocklasts(a::AbstractUnitRange{Int})

Return the last index of each block of `a`.

# Examples
```jldoctest
julia> b = blockedrange(1:3)
3-blocked 6-element BlockedUnitRange{ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}}:
 1
 ─
 2
 3
 ─
 4
 5
 6

julia> blocklasts(b)
3-element ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}:
 1
 3
 6
```
"""
blocklasts(a::AbstractUnitRange{Int}) = Fill(length(a),1)
"""
   blocklengths(a::AbstractUnitRange{Int})

Return the length of each block of `a`.

# Examples
```jldoctest
julia> b = blockedrange(1:3)
3-blocked 6-element BlockedUnitRange{ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}}:
 1
 ─
 2
 3
 ─
 4
 5
 6

julia> blocklengths(b)
3-element Vector{Int64}:
 1
 2
 3
```
"""
blocklengths(a::AbstractUnitRange) = blocklasts(a) .- blockfirsts(a) .+ 1

Base.summary(a::BlockedUnitRange) = _block_summary(a)
Base.summary(io::IO, a::BlockedUnitRange) =  _block_summary(io, a)


###
# Slice{<:BlockedUnitRange}
###

Base.axes(S::Base.Slice{<:BlockedUnitRange}) = (S.indices,)
Base.unsafe_indices(S::Base.Slice{<:BlockedUnitRange}) = (S.indices,)
Base.axes1(S::Base.Slice{<:BlockedUnitRange}) = S.indices
blockaxes(S::Base.Slice) = blockaxes(S.indices)
@propagate_inbounds getindex(S::Base.Slice, b::Block{1}) = S.indices[b]
@propagate_inbounds getindex(S::Base.Slice, b::BlockRange{1}) = S.indices[b]


# This supports broadcasting with infinite block arrays
Base.BroadcastStyle(::Type{BlockedUnitRange{R}}) where R = Base.BroadcastStyle(R)


###
# Special Fill/Range cases
#
# We want to use lazy types when possible
###

_blocklengths2blocklasts(blocks::AbstractRange) = RangeCumsum(blocks)
function blockfirsts(a::BlockedUnitRange{Base.OneTo{Int}})
    a.first == 1 || error("Offset axes not supported")
    Base.OneTo{Int}(length(a.lasts))
end
function blocklengths(a::BlockedUnitRange{Base.OneTo{Int}})
    a.first == 1 || error("Offset axes not supported")
    Ones{Int}(length(a.lasts))
end
function blockfirsts(a::BlockedUnitRange{<:AbstractRange})
    st = step(a.lasts)
    a.first == 1 || error("Offset axes not supported")
    @assert first(a.lasts)-a.first+1 == st
    range(1; step=st, length=length(a.lasts))
end
function blocklengths(a::BlockedUnitRange{<:AbstractRange})
    st = step(a.lasts)
    a.first == 1 || error("Offset axes not supported")
    @assert first(a.lasts)-a.first+1 == st
    Fill(st,length(a.lasts))
end


# TODO: Remove

function _last end
function _length end
