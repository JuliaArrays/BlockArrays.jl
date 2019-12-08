
# interface
getindex(b::AbstractVector, K::BlockIndex{1}) = b[Block(K.I[1])][K.α[1]]
getindex(b::AbstractVector, K::BlockIndexRange{1}) = b[K.block][K.indices[1]]

function findblockindex(b::AbstractVector, k::Integer)
    K = findblock(b, k)
    K[searchsortedfirst(b[K], k)] # guaranteed to be in range
end

struct CumsumBlockRange{CS} <: AbstractUnitRange{Int}
    first::Int
    cumsum::CS
end

const DefaultBlockAxis = CumsumBlockRange{Vector{Int}}

@inline _CumsumBlockRange(cs) = CumsumBlockRange(1,cs)

CumsumBlockRange(::CumsumBlockRange) = throw(ArgumentError("Forbidden due to ambiguity"))
@inline CumsumBlockRange(blocks::AbstractVector{Int}) = _CumsumBlockRange(cumsum(blocks))

@inline _block_cumsum(a::CumsumBlockRange) = a.cumsum
blockisequal(a::AbstractVector, b::AbstractVector) = first(a) == first(b) && _block_cumsum(a) == _block_cumsum(b)
blockisequal(a::Tuple, b::Tuple) = all(blockisequal.(a, b))

Base.similar(::Type{T}, shape::Tuple{CumsumBlockRange,Vararg{CumsumBlockRange}}) where {T<:AbstractArray} = 
    similar(T, map(length,shape))


Base.convert(::Type{CumsumBlockRange}, axis::CumsumBlockRange) = axis
Base.convert(::Type{CumsumBlockRange}, axis::AbstractUnitRange{Int}) = CumsumBlockRange([length(axis)], axis)
Base.convert(::Type{CumsumBlockRange}, axis::Base.Slice) = convert(CumsumBlockRange, axis.indices)
Base.convert(::Type{CumsumBlockRange}, axis::Base.IdentityUnitRange) = convert(CumsumBlockRange, axis.indices)
Base.convert(::Type{CumsumBlockRange{CS}}, axis::CumsumBlockRange{CS}) where CS = axis
Base.convert(::Type{CumsumBlockRange{CS}}, axis::CumsumBlockRange) where CS = CumsumBlockRange(first(axis), convert(CS, _block_cumsum(axis)))

"""
    blockaxes(A)

Return the tuple of valid block indices for array `A`.
"""
blockaxes(b::CumsumBlockRange) = (Block.(axes(b.cumsum,1)),)
blockaxes(b::AbstractArray{<:Any,N}) where N = blockaxes.(axes(b), 1)

"""
    blockaxes(A, d)

Return the valid range of block indices for array `A` along dimension `d`.
```
"""
function blockaxes(A::AbstractArray{T,N}, d) where {T,N}
    @_inline_meta
    d::Integer <= N ? blockaxes(A)[d] : OneTo(1)
end

blocksize(A) = map(length, blockaxes(A))
blocksize(A,i) = length(blockaxes(A,i))
blocklength(t) = (@_inline_meta; prod(blocksize(t)))

axes(b::CumsumBlockRange) = (_CumsumBlockRange(_block_cumsum(b) .- (first(b)-1)),)
unsafe_indices(b::CumsumBlockRange) = axes(b)
first(b::CumsumBlockRange) = b.first
_last(b::CumsumBlockRange, _) = isempty(_block_cumsum(b)) ? first(b)-1 : last(_block_cumsum(b))
last(b::CumsumBlockRange) = _last(b, axes(_block_cumsum(b),1))
_length(b::CumsumBlockRange, _) = Base.invoke(length, Tuple{AbstractUnitRange{Int}}, b)
length(b::CumsumBlockRange) = _length(b, axes(_block_cumsum(b),1))

function getindex(b::CumsumBlockRange, K::Block{1})
    k = Int(K)
    bax = blockaxes(b,1)
    cs = _block_cumsum(b)
    @boundscheck K in bax || throw(BlockBoundsError(b, k))
    S = first(bax)
    K == S && return first(b):first(cs)
    return cs[k-1]+1:cs[k]
end

function getindex(b::CumsumBlockRange, KR::BlockRange{1})
    cs = _block_cumsum(b)
    isempty(KR) && return CumsumBlockRange(1,cs[1:0])
    K,J = first(KR),last(KR)
    k,j = Int(K),Int(J)
    bax = blockaxes(b,1)
    @boundscheck K in bax || throw(BlockBoundsError(b,K))
    @boundscheck J in bax || throw(BlockBoundsError(b,J))
    K == first(bax) && return CumsumBlockRange(first(b),cs[k:j])
    CumsumBlockRange(cs[k-1]+1,cs[k:j])
end

function findblock(b::CumsumBlockRange, k::Integer)
    @boundscheck k in b || throw(BoundsError(b,k))
    Block(searchsortedfirst(_block_cumsum(b), k))
end

Base.dataids(b::CumsumBlockRange) = Base.dataids(_block_cumsum(b))


###
# CumsumBlockRange interface
###
function getindex(b::AbstractUnitRange{Int}, K::Block{1})
    @boundscheck K == Block(1) || throw(BlockBoundsError(b, K))
    b
end

blockaxes(b::AbstractUnitRange{Int}) = (Block.(Base.OneTo(1)),)

function findblock(b::AbstractUnitRange{Int}, k::Integer)
    @boundscheck k in axes(b,1) || throw(BoundsError(b,k))
    Block(1)
end

_block_cumsum(a::AbstractUnitRange{Int}) = [length(a)]

Base.summary(a::CumsumBlockRange) = _block_summary(a)
Base.summary(io::IO, a::CumsumBlockRange) =  _block_summary(io, a)
