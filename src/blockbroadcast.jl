
# Here we override broadcasting for banded matrices.
# The design is to to exploit the broadcast machinery so that
# banded matrices that conform to the banded matrix interface but are not
# <: AbstractBandedMatrix can get access to fast copyto!, lmul!, rmul!, axpy!, etc.
# using broadcast variants (B .= A, B .= 2.0 .* A, etc.)


abstract type AbstractBlockStyle{N} <: AbstractArrayStyle{N} end
struct BlockStyle{N} <: AbstractBlockStyle{N} end
struct PseudoBlockStyle{N} <: AbstractBlockStyle{N} end

BlockStyle{M}(::Val{N}) where {N,M} = BlockStyle{N}()
PseudoBlockStyle{M}(::Val{N}) where {N,M} = PseudoBlockStyle{N}()
BroadcastStyle(::Type{<:BlockArray{<:Any,N}}) where N = BlockStyle{N}()
BroadcastStyle(::Type{<:PseudoBlockArray{<:Any,N}}) where N = PseudoBlockStyle{N}()
BroadcastStyle(::DefaultArrayStyle{N}, ::AbstractBlockStyle{M}) where {M,N} = DefaultArrayStyle{_max(Val(M),Val(N))}()
BroadcastStyle(::AbstractBlockStyle{N}, ::DefaultArrayStyle{M}) where {M,N} = DefaultArrayStyle{_max(Val(M),Val(N))}()
BroadcastStyle(::DefaultArrayStyle{0}, a::AbstractBlockStyle{M}) where {M} = a
BroadcastStyle(a::AbstractBlockStyle{N}, ::DefaultArrayStyle{0}) where {N} = a
BroadcastStyle(::BlockStyle{M}, ::PseudoBlockStyle{N}) where {M,N} = BlockStyle{_max(Val(M),Val(N))}()
BroadcastStyle(::PseudoBlockStyle{M}, ::BlockStyle{N}) where {M,N} = BlockStyle{_max(Val(M),Val(N))}()


####
# Default to standard Array broadcast
####


# following code modified from julia/base/broadcast.jl
broadcast_cumulsizes(::Number) = ()
broadcast_cumulsizes(A::AbstractArray) = cumulsizes(blocksizes(A))
broadcast_cumulsizes(A::Broadcasted) = cumulsizes(blocksizes(A))

combine_cumulsizes(A) = A
combine_cumulsizes(A, B, C...) = combine_cumulsizes(_bcs(A,B), C...)

_bcs(::Tuple{}, ::Tuple{}) = ()
_bcs(::Tuple{}, newshape::Tuple) = (newshape[1], _bcs((), tail(newshape))...)
_bcs(shape::Tuple, ::Tuple{}) = (shape[1], _bcs(tail(shape), ())...)
_bcs(shape::Tuple, newshape::Tuple) = (sort!(union(shape[1], newshape[1])), _bcs(tail(shape), tail(newshape))...)


blocksizes(A::Broadcasted{<:AbstractArrayStyle{N}}) where N =
    BlockSizes(combine_cumulsizes(broadcast_cumulsizes.(A.args)...))

copyto!(dest::AbstractArray, bc::Broadcasted{<:AbstractBlockStyle}) =
   copyto!(dest, Broadcasted{DefaultArrayStyle{2}}(bc.f, bc.args, bc.axes))

similar(bc::Broadcasted{<:AbstractBlockStyle{N}}, ::Type{T}) where {T,N} =
    BlockArray{T,N}(undef, blocksizes(bc))

similar(bc::Broadcasted{PseudoBlockStyle{N}}, ::Type{T}) where {T,N} =
    PseudoBlockArray{T,N}(undef, blocksizes(bc))
