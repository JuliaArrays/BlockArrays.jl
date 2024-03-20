
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

abstract type AbstractBlockedUnitRange{T,CS} <: AbstractUnitRange{T} end

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
3-blocked 7-element BlockedOneTo{Vector{Int64}}:
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
struct BlockedUnitRange{CS} <: AbstractBlockedUnitRange{Int,CS}
    first::Int
    lasts::CS
    global _BlockedUnitRange(f, cs::CS) where CS = new{CS}(f, cs)
end

@inline _BlockedUnitRange(cs) = _BlockedUnitRange(1,cs)

first(b::BlockedUnitRange) = b.first
@inline blocklasts(a::BlockedUnitRange) = a.lasts

BlockedUnitRange(::BlockedUnitRange) = throw(ArgumentError("Forbidden due to ambiguity"))

@inline blockfirsts(a::AbstractBlockedUnitRange) = [first(a); @views(blocklasts(a)[1:end-1]) .+ 1]
# optimize common cases
@inline function blockfirsts(a::AbstractBlockedUnitRange{<:Any,<:Union{Vector, RangeCumsum{<:Any, <:UnitRange}}})
    v = Vector{eltype(a)}(undef, length(blocklasts(a)))
    v[1] = first(a)
    v[2:end] .= @views(blocklasts(a)[oneto(end-1)]) .+ 1
    return v
end

length(a::AbstractBlockedUnitRange) = isempty(blocklasts(a)) ? 0 : Integer(last(blocklasts(a))-first(a)+1)

struct BlockedOneTo{CS} <: AbstractBlockedUnitRange{Int,CS}
    lasts::CS
end

const DefaultBlockAxis = BlockedOneTo{Vector{Int}}

first(b::BlockedOneTo) = oneunit(eltype(b))
@inline blocklasts(a::BlockedOneTo) = a.lasts

BlockedOneTo(::BlockedOneTo) = throw(ArgumentError("Forbidden due to ambiguity"))

axes(b::BlockedOneTo) = (b,)
function axes(b::BlockedOneTo{<:RangeCumsum}, d::Int)
    d <= 1 && return axes(b)[d]
    return BlockedOneTo(oftype(b.lasts, RangeCumsum(Base.OneTo(1))))
end

_blocklengths2blocklasts(blocks) = cumsum(blocks) # extra level to allow changing default cumsum behaviour
@inline blockedrange(blocks::Union{Tuple,AbstractVector}) = BlockedOneTo(_blocklengths2blocklasts(blocks))
@inline blockedrange(f, blocks::Union{Tuple,AbstractVector}) = _BlockedUnitRange(f, f-1 .+ _blocklengths2blocklasts(blocks))

_diff(a::AbstractVector) = diff(a)
_diff(a::Tuple) = diff(collect(a))
_blocklengths(a, bl, dbl) = isempty(bl) ? [dbl;] : [first(bl)-first(a)+1; dbl]
function _blocklengths(a::BlockedOneTo, bl::RangeCumsum, ::AbstractUnitRange)
    # the 1:0 is hardcoded here to enable conversions to a Base.OneTo
    isempty(bl) ? oftype(bl.range, 1:0) : bl.range
end
_blocklengths(a, bl) = _blocklengths(a, bl, _diff(bl))
blocklengths(a::AbstractBlockedUnitRange) = _blocklengths(a, blocklasts(a))

"""
    blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int})

Check if `a` and `b` have the same block structure.

# Examples
```jldoctest
julia> b1 = blockedrange([1,2])
2-blocked 3-element BlockedOneTo{Vector{Int64}}:
 1
 ─
 2
 3

julia> b2 = blockedrange([1,1,1])
3-blocked 3-element BlockedOneTo{Vector{Int64}}:
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

Return if the tuples satisfy `blockisequal` elementwise.
"""
blockisequal(a::Tuple, b::Tuple) = blockisequal(first(a), first(b)) && blockisequal(Base.tail(a), Base.tail(b))
blockisequal(::Tuple{}, ::Tuple{}) = true
blockisequal(::Tuple, ::Tuple{}) = false
blockisequal(::Tuple{}, ::Tuple) = false


_shift_blocklengths(::AbstractBlockedUnitRange, bl, f) = bl
_shift_blocklengths(::Any, bl, f) = bl .+ (f - 1)
const OneBasedRanges = Union{Base.OneTo, Base.Slice{<:Base.OneTo}, Base.IdentityUnitRange{<:Base.OneTo}}
_shift_blocklengths(::OneBasedRanges, bl, f) = bl
function Base.convert(::Type{BlockedUnitRange}, axis::AbstractUnitRange{Int})
    bl = blocklasts(axis)
    f = first(axis)
    _BlockedUnitRange(f, _shift_blocklengths(axis, bl, f))
end
function Base.convert(::Type{BlockedUnitRange{CS}}, axis::AbstractUnitRange{Int}) where CS
    bl = blocklasts(axis)
    f = first(axis)
    _BlockedUnitRange(f, convert(CS, _shift_blocklengths(axis, bl, f)))
end

Base.unitrange(b::AbstractBlockedUnitRange) = first(b):last(b)

Base.promote_rule(::Type{<:AbstractBlockedUnitRange}, ::Type{Base.OneTo{Int}}) = UnitRange{Int}

Base.convert(::Type{BlockedOneTo}, axis::BlockedOneTo) = axis
_convert(::Type{BlockedOneTo}, axis::AbstractBlockedUnitRange) = BlockedOneTo(blocklasts(axis))
_convert(::Type{BlockedOneTo}, axis::AbstractUnitRange{Int}) = BlockedOneTo(last(axis):last(axis))
function Base.convert(::Type{BlockedOneTo}, axis::AbstractUnitRange{Int})
    first(axis) == 1 || throw(ArgumentError("first element of range is not 1"))
    _convert(BlockedOneTo, axis)
end
Base.convert(::Type{BlockedOneTo{CS}}, axis::BlockedOneTo{CS}) where CS = axis
Base.convert(::Type{BlockedOneTo{CS}}, axis::BlockedOneTo) where CS = BlockedOneTo(convert(CS, blocklasts(axis)))
Base.convert(::Type{BlockedOneTo{CS}}, axis::AbstractUnitRange{Int}) where CS = convert(BlockedOneTo{CS}, convert(BlockedOneTo, axis))

"""
    blockaxes(A::AbstractArray)

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
blockaxes(b::AbstractBlockedUnitRange) = _blockaxes(blocklasts(b))
_blockaxes(b::AbstractVector) = (Block.(axes(b,1)),)
_blockaxes(b::Tuple) = (Block.(Base.OneTo(length(b))),)
blockaxes(b) = blockaxes.(axes(b), 1)

"""
    blockaxes(A::AbstractArray, d::Int)

Return the valid range of block indices for array `A` along dimension `d`.

# Examples
```jldoctest
julia> A = BlockArray([1,2,3], [2,1])
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
    blocksize(A::AbstractArray)
    blocksize(A::AbstractArray, i::Int)

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
    blocksizes(A::AbstractArray)
    blocksizes(A::AbstractArray, i::Int)

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

axes(b::AbstractBlockedUnitRange) = (_BlockedUnitRange(blocklasts(b) .- (first(b)-1)),)
unsafe_indices(b::AbstractBlockedUnitRange) = axes(b)
# ::Integer works around case where blocklasts might return different type
last(b::AbstractBlockedUnitRange)::Integer = isempty(blocklasts(b)) ? first(b)-1 : last(blocklasts(b))

# view and indexing are identical for a unitrange
view(b::AbstractBlockedUnitRange, K::Block{1}) = b[K]

@propagate_inbounds function getindex(b::AbstractBlockedUnitRange, K::Block{1})
    k = Integer(K)
    bax = blockaxes(b,1)
    cs = blocklasts(b)
    @boundscheck K in bax || throw(BlockBoundsError(b, k))
    S = first(bax)
    K == S && return first(b):first(cs)
    return cs[k-1]+1:cs[k]
end

@propagate_inbounds function getindex(b::AbstractBlockedUnitRange, KR::BlockRange{1})
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

@propagate_inbounds function getindex(b::AbstractBlockedUnitRange, KR::BlockRange{1,Tuple{Base.OneTo{Int}}})
    cs = blocklasts(b)
    isempty(KR) && return _BlockedUnitRange(1,cs[Base.OneTo(0)])
    J = last(KR)
    j = Integer(J)
    bax = blockaxes(b,1)
    @boundscheck J in bax || throw(BlockBoundsError(b,J))
    _BlockedUnitRange(first(b),cs[Base.OneTo(j)])
end

@propagate_inbounds getindex(b::AbstractBlockedUnitRange, KR::BlockSlice) = b[KR.block]

_searchsortedfirst(a::AbstractVector, k) = searchsortedfirst(a, k)
function _searchsortedfirst(a::Tuple, k)
    k ≤ first(a) && return 1
    1+_searchsortedfirst(tail(a), k)
end
_searchsortedfirst(a::Tuple{}, k) = 1

function findblock(b::AbstractBlockedUnitRange, k::Integer)
    @boundscheck k in b || throw(BoundsError(b,k))
    Block(_searchsortedfirst(blocklasts(b), k))
end

Base.dataids(b::AbstractBlockedUnitRange) = Base.dataids(blocklasts(b))


###
# BlockedUnitRange interface
###
Base.checkindex(::Type{Bool}, b::BlockRange, K::Int) = checkindex(Bool, Int.(b), K)
Base.checkindex(::Type{Bool}, b::AbstractUnitRange{Int}, K::Block{1}) = checkindex(Bool, blockaxes(b,1), Int(K))

function Base.checkindex(::Type{Bool}, axis::AbstractBlockedUnitRange, ind::BlockIndexRange{1})
    checkindex(Bool, axis, first(ind)) && checkindex(Bool, axis, last(ind))
end
function Base.checkindex(::Type{Bool}, axis::AbstractBlockedUnitRange, ind::BlockIndex{1})
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
julia> b = blockedrange([1,2,3])
3-blocked 6-element BlockedOneTo{Vector{Int64}}:
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
julia> b = blockedrange([1,2,3])
3-blocked 6-element BlockedOneTo{Vector{Int64}}:
 1
 ─
 2
 3
 ─
 4
 5
 6

julia> blocklasts(b)
3-element Vector{Int64}:
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
julia> b = blockedrange([1,2,3])
3-blocked 6-element BlockedOneTo{Vector{Int64}}:
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

Base.summary(io::IO, a::AbstractBlockedUnitRange) =  _block_summary(io, a)


###
# Slice{<:BlockedUnitRange}
###

Base.axes(S::Base.Slice{<:AbstractBlockedUnitRange}) = (S.indices,)
Base.unsafe_indices(S::Base.Slice{<:AbstractBlockedUnitRange}) = (S.indices,)
Base.axes1(S::Base.Slice{<:AbstractBlockedUnitRange}) = S.indices
blockaxes(S::Base.Slice) = blockaxes(S.indices)
@propagate_inbounds getindex(S::Base.Slice, b::Block{1}) = S.indices[b]
@propagate_inbounds getindex(S::Base.Slice, b::BlockRange{1}) = S.indices[b]


# This supports broadcasting with infinite block arrays
Base.BroadcastStyle(::Type{<:AbstractBlockedUnitRange{<:Any,R}}) where R = Base.BroadcastStyle(R)


###
# Special Fill/Range cases
#
# We want to use lazy types when possible
###

_blocklengths2blocklasts(blocks::AbstractRange) = RangeCumsum(blocks)
function blockfirsts(a::AbstractBlockedUnitRange{<:Any,Base.OneTo{Int}})
    first(a) == 1 || error("Offset axes not supported")
    Base.OneTo{Int}(length(blocklasts(a)))
end
function blocklengths(a::AbstractBlockedUnitRange{<:Any,Base.OneTo{Int}})
    first(a) == 1 || error("Offset axes not supported")
    Ones{Int}(length(blocklasts(a)))
end
function blockfirsts(a::AbstractBlockedUnitRange{<:Any,<:AbstractRange})
    st = step(blocklasts(a))
    first(a) == 1 || error("Offset axes not supported")
    @assert first(blocklasts(a))-first(a)+1 == st
    range(1; step=st, length=length(blocklasts(a)))
end
function blocklengths(a::AbstractBlockedUnitRange{<:Any,<:AbstractRange})
    st = step(blocklasts(a))
    first(a) == 1 || error("Offset axes not supported")
    @assert first(blocklasts(a))-first(a)+1 == st
    Fill(st,length(blocklasts(a)))
end


# TODO: Remove

function _last end
function _length end
