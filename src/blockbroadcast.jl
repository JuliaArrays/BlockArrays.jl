
# Here we override broadcasting for banded matrices.
# The design is to to exploit the broadcast machinery so that
# banded matrices that conform to the banded matrix interface but are not
# <: AbstractBandedMatrix can get access to fast copyto!, lmul!, rmul!, axpy!, etc.
# using broadcast variants (B .= A, B .= 2.0 .* A, etc.)


abstract type AbstractBlockStyle{N} <: AbstractArrayStyle{N} end
struct BlockStyle{N} <: AbstractBlockStyle{N} end
struct BlockedStyle{N} <: AbstractBlockStyle{N} end


BlockStyle(::Val{N}) where {N} = BlockStyle{N}()
BlockedStyle(::Val{N}) where {N} = BlockedStyle{N}()
BlockStyle{M}(::Val{N}) where {N,M} = BlockStyle{N}()
BlockedStyle{M}(::Val{N}) where {N,M} = BlockedStyle{N}()
blockbroadcaststyle(::AbstractArrayStyle{N}) where {N} = BlockStyle{N}()
blockedbroadcaststyle(::AbstractArrayStyle{N}) where {N} = BlockedStyle{N}()

BroadcastStyle(::Type{<:BlockArray{<:Any,N,Blocks}}) where {N,Blocks} = blockbroadcaststyle(BroadcastStyle(Blocks))
BroadcastStyle(::Type{<:BlockedArray{<:Any,N,Blocks}}) where {N,Blocks} = blockedbroadcaststyle(BroadcastStyle(Blocks))
BroadcastStyle(::Type{<:Adjoint{T,<:BlockArray{<:Any,N,Blocks}}}) where {T,N,Blocks} = blockbroadcaststyle(BroadcastStyle(Adjoint{T,Blocks}))
BroadcastStyle(::Type{<:Transpose{T,<:BlockArray{<:Any,N,Blocks}}}) where {T,N,Blocks} = blockbroadcaststyle(BroadcastStyle(Transpose{T,Blocks}))
BroadcastStyle(::Type{<:Adjoint{T,<:BlockedArray{<:Any,N,Blocks}}}) where {T,N,Blocks} = blockedbroadcaststyle(BroadcastStyle(Adjoint{T,Blocks}))
BroadcastStyle(::Type{<:Transpose{T,<:BlockedArray{<:Any,N,Blocks}}}) where {T,N,Blocks} = blockedbroadcaststyle(BroadcastStyle(Transpose{T,Blocks}))

BroadcastStyle(::DefaultArrayStyle{N}, b::AbstractBlockStyle{M}) where {M,N} = typeof(b)(Val(max(M,N)))
BroadcastStyle(a::AbstractBlockStyle{N}, ::DefaultArrayStyle{M}) where {M,N} = typeof(a)(Val(max(M,N)))
BroadcastStyle(::StructuredMatrixStyle, b::AbstractBlockStyle{M}) where {M} = typeof(b)(Val(max(M,2)))
BroadcastStyle(a::AbstractBlockStyle{M}, ::StructuredMatrixStyle) where {M} = typeof(a)(Val(max(M,2)))
BroadcastStyle(::BlockStyle{M}, ::BlockedStyle{N}) where {M,N} = BlockStyle(Val(max(M,N)))
BroadcastStyle(::BlockedStyle{M}, ::BlockStyle{N}) where {M,N} = BlockStyle(Val(max(M,N)))


# sortedunion can assume inputs are already sorted so this could be improved
maybeinplacesort!(v::StridedVector) = sort!(v)
maybeinplacesort!(v) = sort(v)
sortedunion(a,b) = maybeinplacesort!(union(a,b))
sortedunion(a::Base.OneTo, b::Base.OneTo) = Base.OneTo(max(last(a),last(b)))
sortedunion(a::AbstractUnitRange, b::AbstractUnitRange) = min(first(a),first(b)):max(last(a),last(b))
combine_blockaxes(a, b) = _BlockedUnitRange(sortedunion(blocklasts(a), blocklasts(b)))
combine_blockaxes(a::BlockedOneTo, b::BlockedOneTo) = BlockedOneTo(sortedunion(blocklasts(a), blocklasts(b)))

Base.Broadcast.axistype(a::AbstractBlockedUnitRange, b::AbstractBlockedUnitRange) = length(b) == 1 ? a : combine_blockaxes(a, b)
Base.Broadcast.axistype(a::AbstractBlockedUnitRange, b) = length(b) == 1 ? a : combine_blockaxes(a, b)
Base.Broadcast.axistype(a, b::AbstractBlockedUnitRange) = length(b) == 1 ? a : combine_blockaxes(a, b)


similar(bc::Broadcasted{<:AbstractBlockStyle{N}}, ::Type{T}) where {T,N} =
    BlockArray{T,N}(undef, axes(bc))

similar(bc::Broadcasted{BlockedStyle{N}}, ::Type{T}) where {T,N} =
    BlockedArray{T,N}(undef, axes(bc))

"""
    SubBlockIterator(subblock_lasts::Vector{Int}, block_lasts::Vector{Int})
    SubBlockIterator(A::AbstractArray, bs::NTuple{N,AbstractUnitRange{Int}} where N, dim::Integer)

Return an iterator over the `BlockIndexRange`s of the blocks specified by
`subblock_lasts`.  The `Block` index part of `BlockIndexRange` is
determined by `subblock_lasts`.  That is to say, the `Block` index first
specifies one of the block represented by `subblock_lasts` and then the
inner-block index range specifies the region within the block.  Each
such block corresponds to a block specified by `blocklasts`.

Note that the invariance `subblock_lasts ⊂ block_lasts` must hold and must
be ensured by the caller.

# Examples
```jldoctest
julia> using BlockArrays

julia> import BlockArrays: SubBlockIterator

julia> A = BlockArray(1:6, 1:3);

julia> subblock_lasts = blocklasts(axes(A, 1))
3-element ArrayLayouts.RangeCumsum{Int64, UnitRange{Int64}}:
 1
 3
 6

julia> block_lasts = [1, 3, 4, 6];

julia> itr = SubBlockIterator(subblock_lasts, block_lasts)
SubBlockIterator([1, 3, 6], [1, 3, 4, 6])

julia> collect(itr)
4-element Vector{BlockIndexRange{1, Tuple{UnitRange{Int64}}, Tuple{Int64}, Int64}}:
 Block(1)[1:1]
 Block(2)[1:2]
 Block(3)[1:1]
 Block(3)[2:3]
```
"""
struct SubBlockIterator
    subblock_lasts::Vector{Int}
    block_lasts::Vector{Int}
end

Base.IteratorEltype(::Type{<:SubBlockIterator}) = Base.HasEltype()
Base.eltype(::Type{<:SubBlockIterator}) = BlockIndexRange{1,Tuple{UnitRange{Int}},Tuple{Int},Int}

Base.IteratorSize(::Type{<:SubBlockIterator}) = Base.HasLength()
Base.length(it::SubBlockIterator) = length(it.block_lasts)

SubBlockIterator(arr::AbstractArray, bs::Tuple{Vararg{AbstractUnitRange{<:Integer}}}, dim::Integer) =
    SubBlockIterator(blocklasts(axes(arr, dim)), blocklasts(bs[dim]))

function Base.iterate(it::SubBlockIterator, (i, j) = (1,1))
    i > length(it.block_lasts) && return nothing
    idx = i == 1 ? (1:it.block_lasts[i]) : (it.block_lasts[i-1]+1:it.block_lasts[i])
    bir = Block(j)[j == 1 ? idx : idx .- it.subblock_lasts[j-1]]
    if it.subblock_lasts[j] == it.block_lasts[i]
        j += 1
    end
    return (bir, (i + 1, j))
end

subblocks(::Any, bs::Tuple{Vararg{AbstractUnitRange{<:Integer}}}, dim::Integer) =
    (nothing for _ in blockaxes(bs[dim], 1))

function subblocks(arr::AbstractArray, bs::Tuple{Vararg{AbstractUnitRange{<:Integer}}}, dim::Integer)
    return SubBlockIterator(arr, bs, dim)
end

@inline _bview(arg, ::Vararg) = arg
@inline _bview(A::AbstractArray, I...) = view(A, I...)

@inline function Broadcast.materialize!(dest, bc::Broadcasted{BS}) where {NDims, BS<:AbstractBlockStyle{NDims}}
    dest_reshaped = ndims(dest) == NDims ? dest : reshape(dest, size(bc))
    bc2 = Broadcast.instantiate(
            Broadcast.flatten(Broadcast.Broadcasted{BS}(bc.f, bc.args,
                map(combine_blockaxes, axes(dest_reshaped), axes(bc)))))
    copyto!(dest_reshaped, bc2)
    return dest
end

function _generic_blockbroadcast_copyto!(dest::AbstractArray,
                            bc::Broadcasted{<:AbstractBlockStyle{NDims}, <:Any, <:Any, Args}) where {NDims, Args <: Tuple}

    NArgs = fieldcount(Args)

    bs = axes(bc)
    if !blockisequal(axes(dest), bs)
        copyto!(BlockedArray(dest, bs), bc)
        return dest
    end

    t = ntuple(NDims) do dim
            zip(
                subblocks(dest, bs, dim),
                map(x -> subblocks(x, bs, dim), bc.args)...
            )
        end

    for inds in Iterators.product(t...)
        destinds, bcinds = map(first, inds), ntuple(i -> map(x->x[i+1], inds), NArgs)
        destview = _bview(dest, destinds...)
        argblocks = ntuple(i -> _bview(bc.args[i], bcinds[i]...), NArgs)
        broadcast!(bc.f, destview, argblocks...)
    end

    return dest
end

copyto!(dest::AbstractArray,
        bc::Broadcasted{<:AbstractBlockStyle{NDims}, <:Any, <:Any, Args}) where {NDims, Args <: Tuple} =
    _generic_blockbroadcast_copyto!(dest, bc)

# type-stable version of _bview.(args, K)
__bview(args::Tuple{}, K) = ()
__bview(args::Tuple, K) = tuple(_bview(args[1],K), __bview(tail(args), K)...)

function _fast_blockbradcast_copyto!(dest, bc)
    @inbounds for K in blockaxes(bc)[1]
        broadcast!(bc.f, view(dest,K), __bview(bc.args, K)...)
    end
    dest
end

_hasscalarlikevec() = false
_hasscalarlikevec(a, b...) = _hasscalarlikevec(b...)
_hasscalarlikevec(a::AbstractVector, b...) = size(a,1) == 1 || _hasscalarlikevec(b...)

blockisequalorscalar(ax, ::Number) = true
blockisequalorscalar(ax, a) = blockisequal(ax, Base.axes1(a))

function copyto!(dest::AbstractVector,
        bc::Broadcasted{<:AbstractBlockStyle{1}, <:Any, <:Any, Args}) where {Args <: Tuple}
    _hasscalarlikevec(bc.args...) && return _generic_blockbroadcast_copyto!(dest, bc)
    ax = axes(dest,1)
    for a in bc.args
        blockisequalorscalar(ax, a) || return _generic_blockbroadcast_copyto!(dest, bc)
    end
    return _fast_blockbradcast_copyto!(dest, bc)
end
@inline function Broadcast.instantiate(bc::Broadcasted{Style}) where {Style <:BlockStyle}
    bcf = Broadcast.instantiate(Broadcast.flatten(Broadcasted{Nothing}(bc.f, bc.args, bc.axes)))
    return Broadcasted{Style}(bcf.f, bcf.args, bcf.axes)
end

_removeblocks(a::Broadcasted) = broadcasted(a.f, map(_removeblocks,a.args)...)
_removeblocks(a::BlockedArray) = a.blocks
_removeblocks(a::BlockSlice) = a.indices
_removeblocks(a::Adjoint) = _removeblocks(parent(a))'
_removeblocks(a::Transpose) = transpose(_removeblocks(parent(a)))
_removeblocks(a::SubArray{<:Any,N,<:BlockedArray}) where N = view(_removeblocks(parent(a)), map(_removeblocks, parentindices(a))...)
_removeblocks(a) = a
copy(bc::Broadcasted{BlockedStyle{N}}) where N = BlockedArray(Broadcast.materialize(_removeblocks(bc)), axes(bc))

for op in (:+, :-, :*)
    @eval function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:AbstractArray{<:Number,N}}}) where N
        (A,) = bc.args
        _BlockArray(broadcast(a -> broadcast($op, a), blocks(A)), axes(A))
    end
end

for op in (:+, :-, :*, :/, :\)
    @eval begin
        function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:Number,<:AbstractArray{<:Number,N}}}) where N
            x,A = bc.args
            _BlockArray(broadcast((x,a) -> broadcast($op, x, a), x, blocks(A)), axes(A))
        end
        function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:AbstractArray{<:Number,N},<:Number}}) where N
            A,x = bc.args
            _BlockArray(broadcast((a,x) -> broadcast($op, a, x), blocks(A),x), axes(A))
        end
    end
end

# exploit special cases for *, for example, *(::Number, ::Diagonal)
for op in (:*, :/)
    @eval @inline $op(A::BlockArray, x::Number) = _BlockArray($op(blocks(A),x), axes(A))
end
for op in (:*, :\)
    @eval @inline $op(x::Number, A::BlockArray) = _BlockArray($op(x,blocks(A)), axes(A))
end

###
# SubViews
###

_blocktype(::Type{<:BlockArray{<:Any,N,<:AbstractArray{R,N}}}) where {N,R} = R

BroadcastStyle(::Type{<:SubArray{T,N,Arr,<:NTuple{N,BlockSlice1},false}}) where {T,N,Arr<:BlockArray} =
    BroadcastStyle(_blocktype(Arr))


# special cases for SubArrays which we want to broadcast by Block
BroadcastStyle(::Type{<:SubArray{<:Any,N,<:Any,I}}) where {N,I<:Tuple{BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockStyle{N}()
BroadcastStyle(::Type{<:SubArray{<:Any,N,<:Any,I}}) where {N,I<:Tuple{BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockStyle{N}()
BroadcastStyle(::Type{<:SubArray{<:Any,N,<:Any,I}}) where {N,I<:Tuple{Any,BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockStyle{N}()

BroadcastStyle(::Type{<:SubArray{<:Any,N,<:BlockedArray,I}}) where {N,I<:Tuple{BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockedStyle{N}()
BroadcastStyle(::Type{<:SubArray{<:Any,N,<:BlockedArray,I}}) where {N,I<:Tuple{BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockedStyle{N}()
BroadcastStyle(::Type{<:SubArray{<:Any,N,<:BlockedArray,I}}) where {N,I<:Tuple{Any,BlockSlice{<:Any,<:Any,<:AbstractBlockedUnitRange},Vararg{Any}}} = BlockedStyle{N}()



###
# Fill
###

for op in (:*, :/)
    @eval begin
        broadcasted(::AbstractBlockStyle, ::typeof($op), a::Zeros, b::AbstractArray) = FillArrays._broadcasted_zeros($op, a, b)
        broadcasted(::AbstractBlockStyle, ::typeof($op), a::Ones{T}, b::AbstractArray{V}) where {T,V} = LinearAlgebra.copy_oftype(b, Base.promote_op(*, T, V))
    end
end

for op in (:*, :\)
    @eval begin
        broadcasted(::AbstractBlockStyle, ::typeof($op), a::AbstractArray, b::Zeros) = FillArrays._broadcasted_zeros($op, a, b)
        broadcasted(::AbstractBlockStyle, ::typeof($op), a::AbstractArray{T}, b::Ones{V}) where {T,V} = LinearAlgebra.copy_oftype(a, Base.promote_op(*, T, V))
    end
end



###
# Ranges
###

broadcasted(::DefaultArrayStyle{1}, ::typeof(+), r::AbstractBlockedUnitRange, x::Integer) = _BlockedUnitRange(first(r) + x, blocklasts(r) .+ x)
broadcasted(::DefaultArrayStyle{1}, ::typeof(+), x::Integer, r::AbstractBlockedUnitRange) = _BlockedUnitRange(x + first(r), x .+ blocklasts(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(-), r::AbstractBlockedUnitRange, x::Integer) = _BlockedUnitRange(first(r) - x, blocklasts(r) .- x)
