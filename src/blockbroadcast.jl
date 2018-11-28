
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
BroadcastStyle(::DefaultArrayStyle{N}, b::AbstractBlockStyle{M}) where {M,N} = typeof(b)(_max(Val(M),Val(N)))
BroadcastStyle(a::AbstractBlockStyle{N}, ::DefaultArrayStyle{M}) where {M,N} = typeof(a)(_max(Val(M),Val(N)))
BroadcastStyle(::BlockStyle{M}, ::PseudoBlockStyle{N}) where {M,N} = BlockStyle(_max(Val(M),Val(N)))
BroadcastStyle(::PseudoBlockStyle{M}, ::BlockStyle{N}) where {M,N} = BlockStyle(_max(Val(M),Val(N)))


####
# Default to standard Array broadcast
####


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


_broadcast_block(::Tuple{}, ::Tuple{}) = ()
_broadcast_block(::Tuple{}, ::Tuple) = ()
_broadcast_block(shape::Tuple, ::Tuple{}) = throw(BoundsError("Not enough blocks"))
_broadcast_block(shape::Tuple, blocks::Tuple) = (blocks[1], _broadcast_block(tail(shape), tail(blocks))...)

broadcast_block(A, K::Block) = view(A, Block(_broadcast_block(axes(A), K.n)))
broadcast_block(A::Number, K::Block) = A
broadcast_block(A::BlockArray, K::Block) = A.blocks[_broadcast_block(size(A), K.n)...]
broadcast_block(A::Broadcasted, K::Block) = broadcasted(A.f, broadcast_block.(A.args, Ref(K))...)






blocksizes(A::Broadcasted{<:AbstractArrayStyle{N}}) where N =
    BlockSizes(combine_cumulsizes(broadcast_cumulsizes.(A.args)...))


function copyto!(dest::AbstractVector, bc::Broadcasted{<:AbstractBlockStyle})
    bs = blocksizes(bc)
    if blocksizes(dest) ≠ bs
        copyto!(PseudoBlockArray(dest, bs), bc)
        return dest
    end

    for K = Block.(1:nblocks(bs,1))
        argblocks = broadcast_block.(bc.args, Ref(K))
        broadcast!(bc.f, view(dest, K), argblocks...)
    end
    dest
end

function copyto!(dest::AbstractMatrix, bc::Broadcasted{<:AbstractBlockStyle})
    bs = blocksizes(bc)
    if blocksizes(dest) ≠ bs
        copyto!(PseudoBlockArray(dest, bs), bc)
        return dest
    end

    for K = 1:nblocks(bs,1), J = 1:nblocks(bs,2)
        KJ = Block(K,J)
        argblocks = broadcast_block.(bc.args, Ref(KJ))
        broadcast!(bc.f, view(dest, KJ), argblocks...)
    end
    dest
end

copyto!(dest::AbstractArray{N}, bc::Broadcasted{<:AbstractBlockStyle}) where N =
   copyto!(dest, Broadcasted{DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes))

similar(bc::Broadcasted{<:AbstractBlockStyle{N}}, ::Type{T}) where {T,N} =
    BlockArray{T,N}(undef, blocksizes(bc))

similar(bc::Broadcasted{PseudoBlockStyle{N}}, ::Type{T}) where {T,N} =
    PseudoBlockArray{T,N}(undef, blocksizes(bc))
