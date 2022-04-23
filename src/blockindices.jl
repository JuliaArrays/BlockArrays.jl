"""
    Block(inds...)

A `Block` is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the a block at that block index will be returned instead of
a single element.

```jldoctest; setup = quote using BlockArrays end
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
Block{N}(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block{1, T}(n::Tuple{Any}) where {N,T} = Block{1, T}(convert(Tuple{T}, n))
Block{0}() = Block{0,Int}()
Block() = Block{0}()
Block(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block{1}(n::Tuple{T}) where {T} = Block{1, T}(n)
Block{N}(n::NTuple{N, T}) where {N,T} = Block{N, T}(n)
Block(n::NTuple{N, T}) where {N,T} = Block{N, T}(n)

@inline Block(blocks::NTuple{N, Block{1, T}}) where {N,T} = Block{N, T}(ntuple(i -> blocks[i].n[1], Val(N)))
@inline Block(::Tuple{}) = Block{0,Int}(())

# iterate and broadcast like Number
length(b::Block) = 1
size(b::Block) = ()
iterate(x::Block) = (x, nothing)
iterate(x::Block, ::Any) = nothing
isempty(x::Block) = false
broadcastable(x::Block) = x
ndims(::Type{<:Block}) = 0
ndims(::Block) = 0
eltype(::Type{B}) where B<:Block = B
getindex(B::Block, ::CartesianIndex{0}) = B

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
convert(::Type{T}, index::Block) where {T<:Tuple} = convert(T, index.n)

Int(index::Block{1}) = Int(index.n[1])
Integer(index::Block{1}) = index.n[1]
Number(index::Block{1}) = index.n[1]

# print
Base.show(io::IO, B::Block{0,Int}) = print(io, "Block()")
function Base.show(io::IO, B::Block{N,Int}) where N 
    print(io, "Block($(B.n[1])")
    for n in Base.tail(B.n)
        print(io, ", $n")
    end
    print(io, ")")
end

"""
    BlockIndex{N}

A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.

It can be used to index into `BlockArrays` in the following manner:

```jldoctest; setup = quote using BlockArrays end
julia> arr = Array(reshape(1:25, (5,5)));

julia> a = PseudoBlockArray(arr, [3,2], [1,4])
2×2-blocked 5×5 PseudoBlockMatrix{Int64}:
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

@inline BlockIndex(a::NTuple{N,Block{1}}, b::Tuple) where N = BlockIndex(Int.(a), b)

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

block(b::BlockIndex) = Block(b.I...)
blockindex(b::BlockIndex{1}) = b.α[1]

BlockIndex(indcs::NTuple{N,BlockIndex{1}}) where N = BlockIndex(block.(indcs), blockindex.(indcs))

function Base.show(io::IO, B::BlockIndex)
    show(io, Block(B.I...))
    print(io, "[$(B.α[1])")
    for α in Base.tail(B.α)
        print(io, ", $α")
    end
    print(io, "]")
end

##
# checkindex
##

@inline checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::Block{N}) where N = blockcheckbounds(Bool, A, I.n...)
@inline function checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::BlockIndex{N}) where N
    bl = block(I)
    checkbounds(Bool, A, bl) || return false
    B = A[bl]
    checkbounds(Bool, B, blockindex(I)...)
end

checkbounds(::Type{Bool}, A::AbstractArray{<:Any,N}, I::AbstractVector{BlockIndex{N}}) where N = 
    all(checkbounds.(Bool, Ref(A), I))

struct BlockIndexRange{N,R<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractArray{BlockIndex{N},N}
    block::Block{N,Int}
    indices::R
end

"""
    BlockIndexRange(block, startind:stopind)

represents a cartesian range inside a block.
"""
BlockIndexRange

BlockIndexRange(block::Block{N}, inds::NTuple{N,AbstractUnitRange{Int}}) where {N} =
    BlockIndexRange{N,typeof(inds)}(inds)
BlockIndexRange(block::Block{N}, inds::Vararg{AbstractUnitRange{Int},N}) where {N} =
    BlockIndexRange(block,inds)

block(R::BlockIndexRange) = R.block

getindex(B::Block{N}, inds::Vararg{Int,N}) where N = BlockIndex(B,inds)
getindex(B::Block{N}, inds::Vararg{AbstractUnitRange{Int},N}) where N = BlockIndexRange(B,inds)
getindex(B::Block{1}, inds::Colon) = B
getindex(B::Block{1}, inds::Base.Slice) = B

getindex(B::BlockIndexRange{1}, kr::AbstractUnitRange{Int}) = BlockIndexRange(B.block, B.indices[1][kr])
getindex(B::BlockIndexRange{N}, inds::Vararg{Int,N}) where N = B.block[Base.reindex(B.indices, inds)...]

eltype(R::BlockIndexRange) = eltype(typeof(R))
eltype(::Type{BlockIndexRange{N}}) where {N} = BlockIndex{N}
eltype(::Type{BlockIndexRange{N,R}}) where {N,R} = BlockIndex{N}
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

function Base.show(io::IO, B::BlockIndexRange)
    show(io, Block(B))
    print(io, "[")
    show(io, B.indices[1])
    for α in Base.tail(B.indices)
        print(io, ", ")
        show(io, α)
    end
    print(io, "]")
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
    BlockSlice(indices)

Represent an AbstractUnitRange of indices that attaches a block.

Upon calling `to_indices()`, Blocks are converted to BlockSlice objects to represent
the indices over which the Block spans.

This mimics the relationship between `Colon` and `Base.Slice`.
"""
struct BlockSlice{BB,INDS<:AbstractUnitRange{Int}} <: AbstractUnitRange{Int}
    block::BB
    indices::INDS
end

Block(bs::BlockSlice{<:Block}) = bs.block


for f in (:axes, :unsafe_indices, :axes1, :first, :last, :size, :length,
          :unsafe_length, :start)
    @eval $f(S::BlockSlice) = $f(S.indices)
end

getindex(S::BlockSlice, i::Integer) = getindex(S.indices, i)
getindex(S::BlockSlice{<:Block}, k::AbstractUnitRange{Int}) = BlockSlice(S.block[k],S.indices[k])
getindex(S::BlockSlice{<:BlockIndexRange}, k::AbstractUnitRange{Int}) = BlockSlice(S.block[k],S.indices[k])
show(io::IO, r::BlockSlice) = print(io, "BlockSlice(", r.block, ",", r.indices, ")")

Block(bs::BlockSlice{<:BlockIndexRange}) = Block(bs.block)


struct BlockRange{N,R<:NTuple{N,AbstractUnitRange{Int}}} <: AbstractArray{Block{N,Int},N}
    indices::R
    BlockRange{N,R}(inds::R) where {N,R} = new{N,R}(inds)
end


# The following is adapted from Julia v0.7 base/multidimensional.jl
# definition of CartesianRange

# deleted code that isn't used, such as 0-dimensional case
"""
    BlockRange(startblock, stopblock)

represents a cartesian range of blocks.

The relationship between `Block` and `BlockRange` mimicks the relationship between
`CartesianIndex` and `CartesianRange`.
"""
BlockRange

BlockRange(inds::NTuple{N,AbstractUnitRange{Int}}) where {N} =
    BlockRange{N,typeof(inds)}(inds)
BlockRange(inds::Vararg{AbstractUnitRange{Int},N}) where {N} =
    BlockRange(inds)

(:)(start::Block{1}, stop::Block{1}) = BlockRange((first(start.n):first(stop.n),))
(:)(start::Block, stop::Block) = throw(ArgumentError("Use `BlockRange` to construct a cartesian range of blocks"))
Base.BroadcastStyle(::Type{<:BlockRange{1}}) = DefaultArrayStyle{1}()
broadcasted(::DefaultArrayStyle{1}, ::Type{Block}, r::AbstractUnitRange) = BlockRange((r,))
broadcasted(::DefaultArrayStyle{1}, ::Type{Int}, block_range::BlockRange{1}) = first(block_range.indices)
broadcasted(::DefaultArrayStyle{0}, ::Type{Int}, block::Block{1}) = Int(block)


# AbstractArray implementation
axes(iter::BlockRange{N,R}) where {N,R} = map(axes1, iter.indices)
Base.IndexStyle(::Type{BlockRange{N,R}}) where {N,R} = IndexCartesian()
@inline function Base.getindex(iter::BlockRange{N,<:NTuple{N,Base.OneTo}}, I::Vararg{Integer, N}) where {N}
    @boundscheck checkbounds(iter, I...)
    Block(I)
end
@inline function Base.getindex(iter::BlockRange{N,R}, I::Vararg{Integer, N}) where {N,R}
    @boundscheck checkbounds(iter, I...)
    Block(I .- first.(axes1.(iter.indices)) .+ first.(iter.indices))
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
intersect(a::BlockRange{1}, b::BlockRange{1}) = BlockRange(intersect(a.indices[1], b.indices[1]))


# needed for scalar-like broadcasting

BlockSlice{Block{1,BT},RT}(a::Base.OneTo) where {BT,RT<:AbstractUnitRange} = 
    BlockSlice(Block(convert(BT, 1)), convert(RT, a))::BlockSlice{Block{1,BT},RT}
BlockSlice{BlockRange{1,Tuple{BT}},RT}(a::Base.OneTo) where {BT<:AbstractUnitRange,RT<:AbstractUnitRange} = 
    BlockSlice(BlockRange(convert(BT, Base.OneTo(1))), convert(RT, a))::BlockSlice{BlockRange{1,Tuple{BT}},RT}
BlockSlice{BlockIndexRange{1,Tuple{BT}},RT}(a::Base.OneTo) where {BT<:AbstractUnitRange,RT<:AbstractUnitRange} = 
    BlockSlice(BlockIndexRange(Block(1), convert(BT, Base.OneTo(1))), convert(RT, a))::BlockSlice{BlockIndexRange{1,Tuple{BT}},RT}
