
# Here we override broadcasting for banded matrices.
# The design is to to exploit the broadcast machinery so that
# banded matrices that conform to the banded matrix interface but are not
# <: AbstractBandedMatrix can get access to fast copyto!, lmul!, rmul!, axpy!, etc.
# using broadcast variants (B .= A, B .= 2.0 .* A, etc.)


abstract type AbstractBlockStyle{N} <: AbstractArrayStyle{N} end
struct BlockStyle{N} <: AbstractBlockStyle{N} end
struct PseudoBlockStyle{N} <: AbstractBlockStyle{N} end


BlockStyle(::Val{N}) where {N} = BlockStyle{N}()
PseudoBlockStyle(::Val{N}) where {N} = PseudoBlockStyle{N}()
BlockStyle{M}(::Val{N}) where {N,M} = BlockStyle{N}()
PseudoBlockStyle{M}(::Val{N}) where {N,M} = PseudoBlockStyle{N}()
BroadcastStyle(::Type{<:BlockArray{<:Any,N}}) where N = BlockStyle{N}()
BroadcastStyle(::Type{<:PseudoBlockArray{<:Any,N}}) where N = PseudoBlockStyle{N}()
BroadcastStyle(::DefaultArrayStyle{N}, b::AbstractBlockStyle{M}) where {M,N} = typeof(b)(Val(max(M,N)))
BroadcastStyle(a::AbstractBlockStyle{N}, ::DefaultArrayStyle{M}) where {M,N} = typeof(a)(Val(max(M,N)))
BroadcastStyle(::StructuredMatrixStyle, b::AbstractBlockStyle{M}) where {M} = typeof(b)(Val(max(M,2)))
BroadcastStyle(a::AbstractBlockStyle{M}, ::StructuredMatrixStyle) where {M} = typeof(a)(Val(max(M,2)))
BroadcastStyle(::BlockStyle{M}, ::PseudoBlockStyle{N}) where {M,N} = BlockStyle(Val(max(M,N)))
BroadcastStyle(::PseudoBlockStyle{M}, ::BlockStyle{N}) where {M,N} = BlockStyle(Val(max(M,N)))


# following code modified from julia/base/broadcast.jl
broadcast_cumulsizes(::Number) = ()
broadcast_cumulsizes(A::AbstractArray) = cumulsizes(blocksizes(A))
broadcast_cumulsizes(A::Broadcasted) = cumulsizes(blocksizes(A))

combine_cumulsizes(A) = A
combine_cumulsizes(A, B, C...) = combine_cumulsizes(_cms(A,B), C...)

_cms(::Tuple{}, ::Tuple{}) = ()
_cms(::Tuple{}, newshape::Tuple) = (newshape[1], _cms((), tail(newshape))...)
_cms(shape::Tuple, ::Tuple{}) = (shape[1], _cms(tail(shape), ())...)
_cms(shape::Tuple, newshape::Tuple) = (sort!(union(shape[1], newshape[1])), _cms(tail(shape), tail(newshape))...)


blocksizes(A::Broadcasted{<:AbstractArrayStyle{N}}) where N =
    BlockSizes(combine_cumulsizes(broadcast_cumulsizes.(A.args)...))


similar(bc::Broadcasted{<:AbstractBlockStyle{N}}, ::Type{T}) where {T,N} =
    BlockArray{T,N}(undef, blocksizes(bc))

similar(bc::Broadcasted{PseudoBlockStyle{N}}, ::Type{T}) where {T,N} =
    PseudoBlockArray{T,N}(undef, blocksizes(bc))

"""
    SubBlockIterator(subcumulsize::Vector{Int}, cumulsize::Vector{Int})
    SubBlockIterator(A::AbstractArray, bs::BlockSizes, dim::Integer)

An iterator for iterating `BlockIndexRange` of the blocks specified by
`cumulsize`.  The `Block` index part of `BlockIndexRange` is
determined by `subcumulsize`.  That is to say, the `Block` index first
specifies one of the block represented by `subcumulsize` and then the
inner-block index range specifies the region within the block.  Each
such block corresponds to a block specified by `cumulsize`.

Note that the invariance `subcumulsize ⊂ cumulsize` must hold and must
be ensured by the caller.

# Examples
```jldoctest
julia> using BlockArrays 

julia> import BlockArrays: SubBlockIterator, BlockIndexRange, cumulsizes

julia> A = BlockArray(1:6, 1:3);

julia> subcumulsize = cumulsizes(A, 1);

julia> @assert subcumulsize == [1, 2, 4, 7]

julia> cumulsize = [1, 2, 4, 5, 7];

julia> for idx in SubBlockIterator(subcumulsize, cumulsize)
           B = @show view(A, idx)
           @assert !(parent(B) isa BlockArray)
           idx :: BlockIndexRange
           idx.block :: Block{1}
           idx.indices :: Tuple{UnitRange}
       end
view(A, idx) = [1]
view(A, idx) = [2, 3]
view(A, idx) = [4]
view(A, idx) = [5, 6]

julia> [idx.block.n[1] for idx in SubBlockIterator(subcumulsize, cumulsize)]
4-element Array{Int64,1}:
 1
 2
 3
 3

julia> [idx.indices[1] for idx in SubBlockIterator(subcumulsize, cumulsize)]
4-element Array{UnitRange{Int64},1}:
 1:1
 1:2
 1:1
 2:3
```
"""
struct SubBlockIterator
    subcumulsize::Vector{Int}
    cumulsize::Vector{Int}
end

Base.IteratorEltype(::Type{<:SubBlockIterator}) = Base.HasEltype()
Base.eltype(::Type{<:SubBlockIterator}) = BlockIndexRange{1,Tuple{UnitRange{Int64}}}

Base.IteratorSize(::Type{<:SubBlockIterator}) = Base.HasLength()
Base.length(it::SubBlockIterator) = length(it.cumulsize) - 1

SubBlockIterator(arr::AbstractArray, bs::BlockSizes, dim::Integer) =
    SubBlockIterator(cumulsizes(arr, dim), cumulsizes(bs, dim))

function Base.iterate(it::SubBlockIterator, state=nothing)
    if state === nothing
        i = 1
        j = 1
    else
        i, j = state
    end
    length(it.cumulsize) == i && return nothing
    idx = it.cumulsize[i]:it.cumulsize[i + 1] - 1
    bir = BlockIndexRange(Block(j), idx .- (it.subcumulsize[j] - 1))
    if it.subcumulsize[j + 1] == it.cumulsize[i + 1]
        j += 1
    end
    return (bir, (i + 1, j))
end

subblocks(::Any, bs::BlockSizes, dim::Integer) =
    (nothing for _ in 1:nblocks(bs, dim))

function subblocks(arr::AbstractArray, bs::BlockSizes, dim::Integer)
    if size(arr, dim) == 1
        return (BlockIndexRange(Block(1), 1:1) for _ in 1:nblocks(bs, dim))
    end
    return SubBlockIterator(arr, bs, dim)
end

@inline _bview(arg, ::Vararg) = arg
@inline _bview(A::AbstractArray, I...) = view(A, I...)

@generated function copyto!(
        dest::AbstractArray,
        bc::Broadcasted{<:AbstractBlockStyle{NDims}, <:Any, <:Any, Args},
        ) where {NDims, Args <: Tuple}

    NArgs = length(Args.parameters)

    # `bvar(0, dim)` is a variable for BlockIndexRange of `dim`-th dimension
    # of `dest` array.  `bvar(i, dim)` is a similar variable of `i`-th
    # argument in `bc.args`.
    bvar(i, dim) = Symbol("blockindexrange_", i, "_", dim)

    function forloop(dim)
        if dim > 0
            quote
                for ($(bvar(0, dim)), $(bvar.(1:NArgs, dim)...),) in zip(
                        subblocks(dest, bs, $dim),
                        subblocks.(bc.args, Ref(bs), Ref($dim))...)
                    $(forloop(dim - 1))
                end
            end
        else
            bview(a, i) = :(_bview($a, $([bvar(i, d) for d in 1:NDims]...)))
            destview = bview(:dest, 0)
            argblocks = [bview(:(bc.args[$i]), i) for i in 1:NArgs]
            quote
                broadcast!(bc.f, $destview, $(argblocks...))
            end
        end
    end

    quote
        bs = blocksizes(bc)
        if blocksizes(dest) ≠ bs
            copyto!(PseudoBlockArray(dest, bs), bc)
            return dest
        end

        $(forloop(NDims))
        return dest
    end
end

@inline function Broadcast.instantiate(
        bc::Broadcasted{Style}) where {Style <:AbstractBlockStyle}
    bcf = Broadcast.flatten(Broadcasted{Nothing}(bc.f, bc.args, bc.axes))
    return Broadcasted{Style}(bcf.f, bcf.args, bcf.axes)
end


for op in (:+, :-, :*)
    @eval function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:BlockArray{<:Number,N}}}) where N 
        (A,) = bc.args
        _BlockArray(broadcast(a -> broadcast($op, a), A.blocks), blocksizes(A))        
    end
end

for op in (:+, :-, :*, :/, :\)
    @eval begin
        function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:Number,<:BlockArray{<:Number,N}}}) where N
            x,A = bc.args
            _BlockArray(broadcast((x,a) -> broadcast($op, x, a), x, A.blocks), blocksizes(A))
        end
        function copy(bc::Broadcasted{BlockStyle{N},<:Any,typeof($op),<:Tuple{<:BlockArray{<:Number,N},<:Number}}) where N 
            A,x = bc.args
            _BlockArray(broadcast((a,x) -> broadcast($op, a, x), A.blocks,x), blocksizes(A))            
        end
    end
end
