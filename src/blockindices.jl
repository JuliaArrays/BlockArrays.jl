"""
    Block(inds...)

A `Block` is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the a block at that block index will be returned instead of
a single element.

It can be constructed and used to index into `BlockArrays` in the following manner:

```jldoctest
julia> Block(1)
Block(1)

julia> Block(1, 2)
Block(1, 2)

julia> Block((Block(1), Block(2)))
Block(1, 2)

julia> A = BlockArray(ones(2,3), [1, 1], [2, 1])
2×2-blocked 2×3 BlockMatrix{Float64}:
 1.0  1.0  │  1.0
 ──────────┼─────
 1.0  1.0  │  1.0

julia> A[Block(1, 1)]
1×2 Matrix{Float64}:
 1.0  1.0
```
"""
struct Block{N, T}
    n::NTuple{N, T}
    Block{N, T}(n::NTuple{N, T}) where {N, T} = new{N, T}(n)
    Block{1, T}(n::Tuple{T}) where T = new{1, T}(n)
end

Block{N, T}(n::Tuple{Vararg{Any, N}}) where {N,T} = Block{N, T}(convert(NTuple{N,T}, n))
Block{N, T}(n::Vararg{Any, N}) where {N,T} = Block{N, T}(n)
Block{1, T}(n::Tuple{Any}) where {T} = Block{1, T}(convert(Tuple{T}, n))
Block{0}() = Block{0,Int}()
Block() = Block{0}()
Block(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block{0}(n::Tuple{}) = Block{0, Int}()

# These method have been defined for Tuple{A, Vararg{A}} instead of NTuple{N,A}
# to get Aqua to recognize that these will never be called with an empty tuple
# (or without any argument in the Vararg case).
# See https://github.com/JuliaTesting/Aqua.jl/issues/86
# Arguably, being clear about this is good style
Block{N}(x::T, n::Vararg{T}) where {N,T} = Block{N, T}(x, n...)
Block{N}(n::Tuple{T, Vararg{T}}) where {N,T} = Block{N, T}(n)
Block(n::Tuple{T, Vararg{T}}) where {T} = Block{length(n), T}(n)
@inline function Block(blocks::Tuple{Block{1, T}, Vararg{Block{1, T}}}) where {T}
    N = length(blocks)
    Block{N, T}(ntuple(i -> blocks[i].n[1], Val(N)))
end
@inline Block(::Tuple{}) = Block{0,Int}(())

# iterate and broadcast like Number
length(b::Block) = 1
size(b::Block) = ()
last(b::Block) = b
iterate(x::Block) = (x, nothing)
iterate(x::Block, ::Any) = nothing
isempty(x::Block) = false
broadcastable(x::Block) = Ref(x)
ndims(::Type{<:Block}) = 0
ndims(::Block) = 0
eltype(::Type{B}) where B<:Block = B

# The following code is taken from CartesianIndex
@inline (+)(index::Block{N}) where {N} = Block{N}(map(+, index.n))
@inline (-)(index::Block{N}) where {N} = Block{N}(map(-, index.n))

@inline (+)(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(+, index1.n, index2.n))
@inline (-)(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(-, index1.n, index2.n))
@inline min(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(min, index1.n, index2.n))
@inline max(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(max, index1.n, index2.n))

@inline (+)(i::Integer, index::Block) = index+i
@inline (+)(index::Block{N}, i::Integer) where {N} = Block{N}(map(x->x+i, index.n))
@inline (-)(index::Block{N}, i::Integer) where {N} = Block{N}(map(x->x-i, index.n))
@inline (-)(i::Integer, index::Block{N}) where {N} = Block{N}(map(x->i-x, index.n))
@inline (*)(a::Integer, index::Block{N}) where {N} = Block{N}(map(x->a*x, index.n))
@inline (*)(index::Block, a::Integer) = *(a,index)

Base.oneunit(B::Block{N,T}) where {N,T} = Block(ntuple(_->oneunit(T), Val(N)))
Base.one(B::Block) = true

# comparison
# _isless copied from Base in Julia 1.7 since it was removed in 1.8.
@inline function _isless(ret, I1::Tuple{Int,Vararg{Int,N}}, I2::Tuple{Int,Vararg{Int,N}}) where {N}
    newret = ifelse(ret==0, icmp(last(I1), last(I2)), ret)
    t1, t2 = Base.front(I1), Base.front(I2)
    # avoid dynamic dispatch by telling the compiler relational invariants
    return isa(t1, Tuple{}) ? _isless(newret, (), ()) : _isless(newret, t1, t2::Tuple{Int,Vararg{Int}})
end
_isless(ret, ::Tuple{}, ::Tuple{}) = ifelse(ret==1, true, false)
icmp(a, b) = ifelse(isless(a,b), 1, ifelse(a==b, 0, -1))
@inline isless(I1::Block{N}, I2::Block{N}) where {N} = _isless(0, I1.n, I2.n)
@inline isless(I1::Block{1}, I2::Block{1}) = isless(Integer(I1), Integer(I2))

# conversions
convert(::Type{T}, index::Block{1}) where {T<:Number} = convert(T, index.n[1])
convert(::Type{T}, index::Block) where {T<:Tuple} = convert(T, Block.(index.n))

Int(index::Block{1}) = Int(index.n[1])
Integer(index::Block{1}) = index.n[1]
Number(index::Block{1}) = index.n[1]
Tuple(index::Block) = Block.(index.n)


# Some views may be computed eagerly without the SubArray wrapper
@propagate_inbounds view(r::AbstractRange, B::Block{1}) = r[to_indices(r, (B,))...]
@propagate_inbounds function view(C::CartesianIndices{N}, b1::Block{1}, B::Block{1}...) where {N}
    blk = Block((b1, B...))
    view(C, to_indices(C, (blk,))...)
end
@propagate_inbounds function view(C::CartesianIndices{N}, B::Block{N}) where {N}
    view(C, to_indices(C, (B,))...)
end

"""
    BlockIndex{N}

A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.

It can be constructed and used to index into `BlockArrays` in the following manner:

```jldoctest
julia> BlockIndex((1,2), (3,4))
Block(1, 2)[3, 4]

julia> Block(1)[3] === BlockIndex((1), (3))
true

julia> Block(1,2)[3,4] === BlockIndex((1,2), (3,4))
true

julia> BlockIndex((Block(1)[3], Block(2)[4]))
Block(1, 2)[3, 4]

julia> arr = Array(reshape(1:25, (5,5)));

julia> a = BlockedArray(arr, [3,2], [1,4])
2×2-blocked 5×5 BlockedMatrix{Int64}:
 1  │   6  11  16  21
 2  │   7  12  17  22
 3  │   8  13  18  23
 ───┼────────────────
 4  │   9  14  19  24
 5  │  10  15  20  25

julia> a[Block(1,2)[1,2]]
11

julia> a[Block(2,2)[2,3]]
20
```
"""
struct BlockIndex{N,TI<:Tuple{Vararg{Integer,N}},Tα<:Tuple{Vararg{Integer,N}}}
    I::TI
    α::Tα
end

@inline BlockIndex(a::NTuple{N,Block{1}}, b::Tuple) where N = BlockIndex(Int.(a), b)
@inline BlockIndex(::Tuple{}, b::Tuple{}) = BlockIndex{0,Tuple{},Tuple{}}((), ())

@inline BlockIndex(a::Integer, b::Integer) = BlockIndex((a,), (b,))
@inline BlockIndex(a::Tuple, b::Integer) = BlockIndex(a, (b,))
@inline BlockIndex(a::Integer, b::Tuple) = BlockIndex((a,), b)
@inline BlockIndex() = BlockIndex((), ())

@inline BlockIndex(a::Block, b::Tuple) = BlockIndex(a.n, b)
@inline BlockIndex(a::Block, b::Integer) = BlockIndex(a, (b,))

@inline function BlockIndex(I::Tuple{Vararg{Integer,N}}, α::Tuple{Vararg{Integer,M}}) where {M,N}
    M <= N || throw(ArgumentError("number of indices must not exceed the number of blocks"))
    α2 = ntuple(k -> k <= M ? α[k] : 1, N)
    BlockIndex(I, α2)
end

block(b::BlockIndex) = Block(b.I...)
blockindex(b::BlockIndex{1}) = b.α[1]
blockindex(b::BlockIndex) = CartesianIndex(b.α)

BlockIndex(indcs::Tuple{Vararg{BlockIndex{1},N}}) where N = BlockIndex(block.(indcs), blockindex.(indcs))

##
# checkindex
##

@inline checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::Block{N}) where N = blockcheckbounds(Bool, A, I.n...)

@inline function checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::BlockIndex{N}) where N
    bl = block(I)
    checkbounds(Bool, A, bl) || return false
    # TODO: Replace with `eachblockaxes(A)[bl]` once that is defined.
    binds = map(Base.axes1 ∘ getindex, axes(A), Tuple(bl))
    Base.checkbounds_indices(Bool, binds, (blockindex(I),))
end
checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::AbstractArray{<:BlockIndex{N}}) where N =
    all(i -> checkbounds(Bool, A, i), I)

struct BlockIndexRange{N,R<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}},I<:Tuple{Vararg{Integer,N}},BI<:Integer} <: AbstractArray{BlockIndex{N,NTuple{N,BI},I},N}
    block::Block{N,BI}
    indices::R
    function BlockIndexRange(block::Block{N,BI}, inds::R) where {N,BI<:Integer,R<:Tuple{Vararg{AbstractUnitRange{<:Integer},N}}}
        I = Tuple{eltype.(inds)...}
        return new{N,R,I,BI}(block,inds)
    end
end

"""
    BlockIndexRange(block, startind:stopind)

Represents a cartesian range inside a block.

It can be constructed and used to index into `BlockArrays` in the following manner:

```jldoctest
julia> BlockIndexRange(Block(1,2), (2:3,3:4))
Block(1, 2)[2:3, 3:4]

julia> Block(1)[2:3] === BlockIndexRange(Block(1), 2:3)
true

julia> Block(1,2)[2:3,3:4] === BlockIndexRange(Block(1,2), (2:3,3:4))
true

julia> BlockIndexRange((Block(1)[2:3], Block(2)[3:4]))
Block(1, 2)[2:3, 3:4]

julia> arr = Array(reshape(1:25, (5,5)));

julia> a = BlockedArray(arr, [3,2], [1,4])
2×2-blocked 5×5 BlockedMatrix{Int64}:
 1  │   6  11  16  21
 2  │   7  12  17  22
 3  │   8  13  18  23
 ───┼────────────────
 4  │   9  14  19  24
 5  │  10  15  20  25

julia> a[Block(1,2)[1:2,2:3]]
2×2 Matrix{Int64}:
 11  16
 12  17

julia> a[Block(2,2)[1:2,3:4]]
2×2 Matrix{Int64}:
 19  24
 20  25
```
"""
BlockIndexRange

BlockIndexRange(block::Block{N}, inds::Vararg{AbstractUnitRange{<:Integer},N}) where {N} =
    BlockIndexRange(block,inds)

function BlockIndexRange(inds::Tuple{BlockIndexRange{1},Vararg{BlockIndexRange{1}}})
    BlockIndexRange(Block(block.(inds)), map(ind -> ind.indices[1], inds))
end

block(R::BlockIndexRange) = R.block

copy(R::BlockIndexRange) = BlockIndexRange(R.block, map(copy, R.indices))

getindex(::Block{0}) = BlockIndex()
getindex(B::Block{N}, inds::Vararg{Integer,N}) where N = BlockIndex(B,inds)
getindex(B::Block{N}, inds::Vararg{AbstractUnitRange{<:Integer},N}) where N = BlockIndexRange(B,inds)
getindex(B::Block{1}, inds::Colon) = B
getindex(B::Block{1}, inds::Base.Slice) = B

getindex(B::BlockIndexRange{0}) = B.block[]
@propagate_inbounds getindex(B::BlockIndexRange{N}, kr::Vararg{AbstractUnitRange{<:Integer},N}) where {N} = BlockIndexRange(B.block, map(getindex, B.indices, kr))
@propagate_inbounds getindex(B::BlockIndexRange{N}, inds::Vararg{Int,N}) where N = B.block[Base.reindex(B.indices, inds)...]

eltype(R::BlockIndexRange) = eltype(typeof(R))
eltype(::Type{BlockIndexRange{N}}) where {N} = BlockIndex{N}
eltype(::Type{BlockIndexRange{N,R,I,BI}}) where {N,R,I,BI} = BlockIndex{N,NTuple{N,BI},I}
IteratorSize(::Type{<:BlockIndexRange}) = Base.HasShape{1}()


first(iter::BlockIndexRange) = BlockIndex(iter.block.n, map(first, iter.indices))
last(iter::BlockIndexRange)  = BlockIndex(iter.block.n, map(last, iter.indices))

@inline function iterate(iter::BlockIndexRange)
    iterfirst, iterlast = first(iter), last(iter)
    if any(map(>, iterfirst.α, iterlast.α))
        return nothing
    end
    iterfirst, iterfirst
end
@inline function iterate(iter::BlockIndexRange, state)
    nextstate = BlockIndex(state.I, inc(state.α, first(iter).α, last(iter).α))
    nextstate.α[end] > last(iter.indices[end]) && return nothing
    nextstate, nextstate
end

size(iter::BlockIndexRange) = map(dimlength, first(iter).α, last(iter).α)
length(iter::BlockIndexRange) = prod(size(iter))


Block(bs::BlockIndexRange) = bs.block

##
# checkindex
##

function checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::BlockIndexRange{N}) where N
    bl = block(I)
    checkbounds(Bool, A, bl) || return false
    # TODO: Replace with `eachblockaxes(A)[bl]` once that is defined.
    binds = map(Base.axes1 ∘ getindex, axes(A), Tuple(bl))
    Base.checkbounds_indices(Bool, binds, I.indices)
end

# #################
# # support for pointers
# #################
#
# function unsafe_convert(::Type{Ptr{T}},
#                         V::SubArray{T, N, BlockArray{T, N, AT}, NTuple{N, BlockSlice{Block{1,Int}}}}) where AT <: AbstractArray{T, N} where {T,N}
#     unsafe_convert(Ptr{T}, parent(V).blocks[Int.(Block.(parentindices(V)))...])
# end


"""
    BlockSlice(block, indices)

Represent an AbstractUnitRange{<:Integer} of indices that attaches a block.

Upon calling `to_indices()`, Blocks are converted to BlockSlice objects to represent
the indices over which the Block spans.

This mimics the relationship between `Colon` and `Base.Slice`.
"""
struct BlockSlice{BB,T<:Integer,INDS<:AbstractUnitRange{T}} <: AbstractUnitRange{T}
    block::BB
    indices::INDS
end

Block(bs::BlockSlice{<:Block}) = bs.block


for f in (:axes, :unsafe_indices, :axes1, :first, :last, :size, :length,
          :unsafe_length, :start)
    @eval $f(S::BlockSlice) = $f(S.indices)
end

_indices(B::BlockSlice) = B.indices
_indices(B) = B

@propagate_inbounds getindex(S::BlockSlice, i::Integer) = getindex(S.indices, i)
@propagate_inbounds getindex(S::BlockSlice{<:Block{1}}, k::AbstractUnitRange{<:Integer}) =
    BlockSlice(S.block[_indices(k)], S.indices[_indices(k)])
@propagate_inbounds getindex(S::BlockSlice{<:BlockIndexRange{1}}, k::AbstractUnitRange{<:Integer}) =
    BlockSlice(S.block[_indices(k)], S.indices[_indices(k)])

# Avoid creating a SubArray wrapper in certain non-allocating cases
@propagate_inbounds view(C::CartesianIndices{N}, bs::Vararg{BlockSlice,N}) where {N} = view(C, map(x->x.indices, bs)...)

Block(bs::BlockSlice{<:BlockIndexRange}) = Block(bs.block)

"""
    BlockedSlice(blocks, indices)

Represents blocked indices attached to a collection of corresponding blocks.

Upon calling `to_indices()`, a collection of blocks are converted to BlockedSlice objects to represent
the indices over which the blocks span.

This mimics the relationship between `Colon` and `Base.Slice`, `Block` and `BlockSlice`, etc.
"""
struct BlockedSlice{BB,T<:Integer,INDS<:AbstractVector{T}} <: AbstractVector{T}
    blocks::BB
    indices::INDS
end

for f in (:axes, :size)
    @eval $f(S::BlockedSlice) = $f(S.indices)
end

@propagate_inbounds getindex(S::BlockedSlice, i::Integer) = getindex(S.indices, i)
@propagate_inbounds getindex(S::BlockedSlice, k::Block{1}) = BlockSlice(S.blocks[Int(k)], getindex(S.indices, k))

struct BlockRange{N,R<:NTuple{N,AbstractUnitRange{<:Integer}}} <: AbstractArray{Block{N,Int},N}
    indices::R
    BlockRange{N,R}(inds::R) where {N,R} = new{N,R}(inds)
end


# The following is adapted from Julia v0.7 base/multidimensional.jl
# definition of CartesianRange

# deleted code that isn't used, such as 0-dimensional case
"""
    BlockRange(axes::Tuple{Vararg{AbstractUnitRange{<:Integer}}})
    BlockRange(sizes::Tuple{Vararg{Integer}})

Represent a Cartesian range of blocks.

The relationship between `Block` and `BlockRange` mimics the relationship between
`CartesianIndex` and `CartesianIndices`.

# Examples
```jldoctest
julia> BlockRange((2:3, 3:4)) |> collect
2×2 Matrix{Block{2, Int64}}:
 Block(2, 3)  Block(2, 4)
 Block(3, 3)  Block(3, 4)

julia> BlockRange((2, 2)) |> collect # number of elements, starting at 1
2×2 Matrix{Block{2, Int64}}:
 Block(1, 1)  Block(1, 2)
 Block(2, 1)  Block(2, 2)

julia> Block(1):Block(2)
BlockRange((1:2,))

julia> Block.(1:2)
BlockRange((1:2,))

julia> BlockRange((Block.(1:2), Block.(3:4)))
BlockRange((1:2, 3:4))
```
"""
BlockRange

combine_indices(inds::Tuple{BlockRange, Vararg{BlockRange}}) =
    (inds[1].indices..., combine_indices(inds[2:end])...)
combine_indices(::Tuple{}) = ()

function BlockRange(inds::Tuple{BlockRange,Vararg{BlockRange}})
    BlockRange(combine_indices(inds))
end

BlockRange(inds::Tuple{Vararg{AbstractUnitRange{<:Integer}}}) =
    BlockRange{length(inds),typeof(inds)}(inds)

BlockRange(sizes::Tuple{Integer, Vararg{Integer}}) = BlockRange(map(oneto, sizes))

BlockRange(B::AbstractArray) = BlockRange(blockaxes(B))

(:)(start::Block{1}, stop::Block{1}) = BlockRange((first(start.n):first(stop.n),))
(:)(start::Block, stop::Block) = throw(ArgumentError("Use `BlockRange` to construct a cartesian range of blocks"))
broadcasted(::DefaultArrayStyle{1}, ::Type{Block}, r::AbstractUnitRange) = BlockRange((r,))
broadcasted(::DefaultArrayStyle{1}, ::Type{<:Integer}, block_range::BlockRange{1}) = first(block_range.indices)
broadcasted(::DefaultArrayStyle{0}, type::Type{<:Integer}, block::Block{1}) = type(block)


# AbstractArray implementation
axes(iter::BlockRange{N,R}) where {N,R} = map(axes1, iter.indices)
@inline function getindex(iter::BlockRange{N,<:NTuple{N,Base.OneTo}}, I::Vararg{Int, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    Block(I)
end
@propagate_inbounds function getindex(iter::BlockRange{N}, I::Vararg{Int, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    Block(getindex.(iter.indices, I))
end

@propagate_inbounds function getindex(iter::BlockRange{N}, I::Vararg{AbstractUnitRange{<:Integer}, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    BlockRange(getindex.(iter.indices, I))
end

@inline function iterate(iter::BlockRange)
    iterfirst, iterlast = first(iter), last(iter)
    if any(map(>, iterfirst.n, iterlast.n))
        return nothing
    end
    iterfirst, iterfirst
end
@inline function iterate(iter::BlockRange, state)
    nextstate = Block(inc(state.n, first(iter).n, last(iter).n))
    nextstate.n[end] > last(iter.indices[end]) && return nothing
    nextstate, nextstate
end

# increment & carry
@inline inc(::Tuple{}, ::Tuple{}, ::Tuple{}) = ()
@inline inc(state::Tuple{Integer}, start::Tuple{Integer}, stop::Tuple{Integer}) = (state[1]+1,)
@inline function inc(state, start, stop)
    if state[1] < stop[1]
        return (state[1]+1,tail(state)...)
    end
    newtail = inc(tail(state), tail(start), tail(stop))
    (start[1], newtail...)
end

# 0-d cartesian ranges are special-cased to iterate once and only once
iterate(iter::BlockRange{0}, done=false) = done ? nothing : (Block(), true)

size(iter::BlockRange) = map(dimlength, first(iter).n, last(iter).n)
dimlength(start, stop) = stop-start+1

length(iter::BlockRange) = prod(size(iter))

first(iter::BlockRange) = Block(map(first, iter.indices))
last(iter::BlockRange)  = Block(map(last, iter.indices))

@inline function in(i::Block{N}, r::BlockRange{N}) where {N}
    _in(true, i.n, first(r).n, last(r).n)
end
_in(b, ::Tuple{}, ::Tuple{}, ::Tuple{}) = b
@inline _in(b, i, start, stop) = _in(b & (start[1] <= i[1] <= stop[1]), tail(i), tail(start), tail(stop))

# We sometimes need intersection of BlockRange to return a BlockRange
intersect(a::BlockRange{1}, b::BlockRange{1}) = BlockRange((intersect(a.indices[1], b.indices[1]),))

##
# checkindex
##

# Used to ensure a `BlockBoundsError` is thrown instead of a `BoundsError`,
# see https://github.com/JuliaArrays/BlockArrays.jl/issues/458
checkbounds(A::AbstractArray{<:Any,N}, I::BlockRange{N}) where N = blockcheckbounds(A, I)
checkbounds(A::AbstractArray, I1::BlockRange{1}, Irest::BlockRange{1}...) =
    blockcheckbounds(A, I1, Irest...)

# Convert Block inputs to integers.
checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::BlockRange{N}) where N =
    blockcheckbounds(Bool, A, I.indices...)
checkbounds(::Type{Bool}, A::AbstractArray, I1::AbstractVector{<:Block{1}}, Irest::AbstractVector{<:Block{1}}...) =
    blockcheckbounds(Bool, A, map(I -> Int.(I), (I1, Irest...))...)

# needed for scalar-like broadcasting

BlockSlice{Block{1,BT},T,RT}(a::Base.OneTo) where {BT,T,RT<:AbstractUnitRange} =
    BlockSlice(Block(convert(BT, 1)), convert(RT, a))::BlockSlice{Block{1,BT},T,RT}
BlockSlice{BlockRange{1,Tuple{BT}},T,RT}(a::Base.OneTo) where {BT<:AbstractUnitRange,T,RT<:AbstractUnitRange} =
    BlockSlice(BlockRange((convert(BT, Base.OneTo(1)),)), convert(RT, a))::BlockSlice{BlockRange{1,Tuple{BT}},T,RT}
BlockSlice{BlockIndexRange{1,Tuple{BT},I,BI},T,RT}(a::Base.OneTo) where {BT<:AbstractUnitRange,T,RT<:AbstractUnitRange,I,BI} =
    BlockSlice(BlockIndexRange(Block(BI(1)), convert(BT, Base.OneTo(1))), convert(RT, a))::BlockSlice{BlockIndexRange{1,Tuple{BT},I,BI},T,RT}
