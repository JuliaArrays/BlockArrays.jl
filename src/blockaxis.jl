
# interface

@inline getindex(b::AbstractVector, K::BlockIndex{1}) = b[Block(K.I[1])][K.α[1]]
@inline getindex(b::AbstractArray{T,N}, K::BlockIndex{N}) where {T,N} =
    b[block(K)][K.α...]
@inline getindex(b::AbstractArray, K::BlockIndex{1}, J::BlockIndex{1}...) =
    b[BlockIndex(tuple(K, J...))]

@inline getindex(b::AbstractArray{T,N}, K::BlockIndexRange{N}) where {T,N} = b[block(K)][K.indices...]
@inline getindex(b::LayoutArray{T,N}, K::BlockIndexRange{N}) where {T,N} = b[block(K)][K.indices...]
@inline getindex(b::LayoutArray{T,1}, K::BlockIndexRange{1}) where {T} = b[block(K)][K.indices...]

function findblockindex(b::AbstractVector, k::Integer)
    K = findblock(b, k)
    K[searchsortedfirst(b[K], k)] # guaranteed to be in range
end

function _BlockedUnitRange end


"""
    BlockedUnitRange

is an `AbstractUnitRange{Int}` that has been divided
into blocks, and is used to represent axes of block arrays.
Construction is typically via `blockrange` which converts
a vector of block lengths to a `BlockedUnitRange`.
```jldoctest; setup = quote using BlockArrays end
julia> blockedrange([2,2,3])
3-blocked 7-element BlockedUnitRange{Array{Int64,1}}:
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
@inline blockedrange(blocks::AbstractVector{Int}) = _BlockedUnitRange(_blocklengths2blocklasts(blocks))

@inline blockfirsts(a::BlockedUnitRange) = [a.first; @view(a.lasts[1:end-1]) .+ 1]
@inline blocklasts(a::BlockedUnitRange) = a.lasts
@inline blocklengths(a::BlockedUnitRange) = [first(a.lasts)-a.first+1; diff(a.lasts)]

"""
   blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int})

returns true if a and b have the same block structure.
"""
blockisequal(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int}) = first(a) == first(b) && blocklasts(a) == blocklasts(b)
blockisequal(a, b, c, d...) = blockisequal(a,b) && blockisequal(b,c,d...)
"""
   blockisequal(a::Tuple, b::Tuple)

returns true if `all(blockisequal.(a,b))`` is true.
"""
blockisequal(a::Tuple, b::Tuple) = all(blockisequal.(a, b))


Base.convert(::Type{BlockedUnitRange}, axis::BlockedUnitRange) = axis
Base.convert(::Type{BlockedUnitRange}, axis::AbstractUnitRange{Int}) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange}, axis::Base.Slice) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange}, axis::Base.IdentityUnitRange) = _BlockedUnitRange(first(axis),[last(axis)])
Base.convert(::Type{BlockedUnitRange{CS}}, axis::BlockedUnitRange{CS}) where CS = axis
Base.convert(::Type{BlockedUnitRange{CS}}, axis::BlockedUnitRange) where CS = _BlockedUnitRange(first(axis), convert(CS, blocklasts(axis)))
Base.convert(::Type{BlockedUnitRange{CS}}, axis::AbstractUnitRange{Int}) where CS = convert(BlockedUnitRange{CS}, convert(BlockedUnitRange, axis))

Base.vcat(

if VERSION ≥ v"1.6-"
    Base.unitrange(b::BlockedUnitRange) = first(b):last(b)
end


"""
    blockaxes(A)

Return the tuple of valid block indices for array `A`.
```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray([1,2,3],[2,1])
2-blocked 3-element BlockArray{Int64,1}:
 1
 2
 ─
 3

julia> blockaxes(A)[1]
2-element BlockRange{1,Tuple{Base.OneTo{Int64}}}:
 Block(1)
 Block(2)
```
"""
blockaxes(b::BlockedUnitRange) = (Block.(axes(b.lasts,1)),)
blockaxes(b) = blockaxes.(axes(b), 1)

"""
    blockaxes(A, d)

Return the valid range of block indices for array `A` along dimension `d`.
```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray([1,2,3],[2,1])
2-blocked 3-element BlockArray{Int64,1}:
 1
 2
 ─
 3

julia> blockaxes(A,1)
2-element BlockRange{1,Tuple{Base.OneTo{Int64}}}:
 Block(1)
 Block(2)
```
"""
function blockaxes(A::AbstractArray{T,N}, d) where {T,N}
    @_inline_meta
    d::Integer <= N ? blockaxes(A)[d] : Base.OneTo(1)
end

"""
    blocksize(A)

Return the tuple of the number of blocks along each
dimension.
```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray(ones(3,3),[2,1],[1,1,1])
2×3-blocked 3×3 BlockArray{Float64,2}:
 1.0  │  1.0  │  1.0
 1.0  │  1.0  │  1.0
 ─────┼───────┼─────
 1.0  │  1.0  │  1.0

julia> blocksize(A)
(2, 3)
```
"""
blocksize(A) = map(length, blockaxes(A))
blocksize(A,i) = length(blockaxes(A,i))
blocklength(t) = (@_inline_meta; prod(blocksize(t)))

axes(b::BlockedUnitRange) = (_BlockedUnitRange(blocklasts(b) .- (first(b)-1)),)
unsafe_indices(b::BlockedUnitRange) = axes(b)
first(b::BlockedUnitRange) = b.first
_last(b::BlockedUnitRange, _) = isempty(blocklasts(b)) ? first(b)-1 : last(blocklasts(b))
last(b::BlockedUnitRange) = _last(b, axes(blocklasts(b),1))
_length(b::BlockedUnitRange, _) = Base.invoke(length, Tuple{AbstractUnitRange{Int}}, b)
length(b::BlockedUnitRange) = _length(b, axes(blocklasts(b),1))

function getindex(b::BlockedUnitRange, K::Block{1})
    k = Integer(K)
    bax = blockaxes(b,1)
    cs = blocklasts(b)
    @boundscheck K in bax || throw(BlockBoundsError(b, k))
    S = first(bax)
    K == S && return first(b):first(cs)
    return cs[k-1]+1:cs[k]
end

function getindex(b::BlockedUnitRange, KR::BlockRange{1})
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

function getindex(b::BlockedUnitRange, KR::BlockRange{1,Tuple{Base.OneTo{Int}}})
    cs = blocklasts(b)
    isempty(KR) && return _BlockedUnitRange(1,cs[Base.OneTo(0)])
    J = last(KR)
    j = Integer(J)
    bax = blockaxes(b,1)
    @boundscheck J in bax || throw(BlockBoundsError(b,J))
    _BlockedUnitRange(first(b),cs[Base.OneTo(j)])
end

function findblock(b::BlockedUnitRange, k::Integer)
    @boundscheck k in b || throw(BoundsError(b,k))
    Block(searchsortedfirst(blocklasts(b), k))
end

Base.dataids(b::BlockedUnitRange) = Base.dataids(blocklasts(b))


###
# BlockedUnitRange interface
###
Base.checkindex(::Type{Bool}, b::BlockRange, K::Int) = checkindex(Bool, Int.(b), K)
Base.checkindex(::Type{Bool}, b::AbstractUnitRange{Int}, K::Block{1}) = checkindex(Bool, blockaxes(b,1), Int(K))

function getindex(b::AbstractUnitRange{Int}, K::Block{1})
    @boundscheck K == Block(1) || throw(BlockBoundsError(b, K))
    b
end

function getindex(b::AbstractUnitRange{Int}, K::BlockRange)
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

returns the first index of each block of `a`.
"""
blockfirsts(a::AbstractUnitRange{Int}) = [1]
"""
   blocklasts(a::AbstractUnitRange{Int})

returns the last index of each block of `a`.
"""
blocklasts(a::AbstractUnitRange{Int}) = [length(a)]
"""
   blocklengths(a::AbstractUnitRange{Int})

returns the length of each block of `a`.
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
getindex(S::Base.Slice, b::Block{1}) = S.indices[b]
getindex(S::Base.Slice, b::BlockRange{1}) = S.indices[b]


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

    
###
# Concatenation
###
Base.vcat(a::BlockedUnitRange{T}...) where T = blockedrange(vcat(map(blocklengths,a)...)) # kind of lazy, not optimised
