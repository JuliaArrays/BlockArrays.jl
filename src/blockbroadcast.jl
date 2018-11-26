
# Here we override broadcasting for banded matrices.
# The design is to to exploit the broadcast machinery so that
# banded matrices that conform to the banded matrix interface but are not
# <: AbstractBandedMatrix can get access to fast copyto!, lmul!, rmul!, axpy!, etc.
# using broadcast variants (B .= A, B .= 2.0 .* A, etc.)


abstract type AbstractBlockStyle{N} <: AbstractArrayStyle{N} end
struct BlockStyle{N} <: AbstractBlockStyle{N} end
struct PseudoBlockStyle{N} <: AbstractBlockStyle{N} end

BlockStyle{N}(::Val{N}) where N = BlockStyle{N}()
PseudoBlockStyle{N}(::Val{N}) where N = PseudoBlockStyle{N}()
BroadcastStyle(::Type{<:BlockArray{<:Any,N}}) where N = BlockStyle{N}()
BroadcastStyle(::Type{<:PseudoBlockArray{<:Any,N}}) where N = PseudoBlockStyle{N}()
BroadcastStyle(::DefaultArrayStyle{N}, ::AbstractBlockStyle{N}) where N = DefaultArrayStyle{N}()
BroadcastStyle(::AbstractBlockStyle{N}, ::DefaultArrayStyle{N}) where N = DefaultArrayStyle{N}()
BroadcastStyle(::BlockStyle{N}, ::PseudoBlockStyle{N}) where N = BlockStyle{N}()
BroadcastStyle(::PseudoBlockStyle{N}, ::BlockStyle{N}) where N = BlockStyle{N}()



####
# Default to standard Array broadcast
####


union.(([1,2,3],[4,5,6]), ([1,2,3],[4,5,6]))

_broadcast_blocksizes(::Val{N}, ::AbstractArrayStyle{0}, _) where N =
    BlockSizes(ntuple(_ -> Int[], N))
_broadcast_blocksizes(::Val{N}, ::AbstractArrayStyle{N}, A) where N =
    blocksizes(A)
_broadcast_blocksizes(::Val{N}, A) where N =
    _broadcast_blocksizes(Val{N}(), BroadcastStyle(typeof(A)), A)

blocksizes(A::Broadcasted{<:AbstractArrayStyle{N}}) where N =
    BlockSizes(sort!.(union.(cumulsizes.(_broadcast_blocksizes.(Val{N}(), A.args))...)))

copyto!(dest::AbstractArray, bc::Broadcasted{<:AbstractBlockStyle}) =
   copyto!(dest, Broadcasted{DefaultArrayStyle{2}}(bc.f, bc.args, bc.axes))

similar(bc::Broadcasted{<:AbstractBlockStyle{N}}, ::Type{T}) where {T,N} =
    BlockArray{T,N}(undef, blocksizes(bc))

similar(bc::Broadcasted{PseudoBlockStyle{N}}, ::Type{T}) where {T,N} =
    PseudoBlockArray{T,N}(undef, blocksizes(bc))
