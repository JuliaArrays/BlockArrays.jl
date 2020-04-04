blockrowsupport(_, A, k) = blockaxes(A,2)
""""
    blockrowsupport(A, k)

gives an iterator containing the possible non-zero entries in the k-th row of A.
"""
blockrowsupport(A, k) = blockrowsupport(MemoryLayout(typeof(A)), A, k)
blockrowsupport(A) = blockrowsupport(A, blockaxes(A,1))

blockcolsupport(_, A, j) = blockaxes(A,1)

""""
    blockcolsupport(A, j)

gives an iterator containing the possible non-zero entries in the j-th column of A.
"""
blockcolsupport(A, j) = blockcolsupport(MemoryLayout(typeof(A)), A, j)
blockcolsupport(A) = blockcolsupport(A, blockaxes(A,2))

abstract type AbstractBlockLayout <: MemoryLayout end
struct BlockLayout{LAY} <: AbstractBlockLayout end

## BlockSlice1 is a convenience for views
const BlockSlice1 = BlockSlice{Block{1,Int},UnitRange{Int}}

similar(M::MulAdd{<:AbstractBlockLayout,<:AbstractBlockLayout}, ::Type{T}, axes) where {T,N} = 
    similar(BlockArray{T}, axes)

MemoryLayout(::Type{<:PseudoBlockArray{T,N,R}}) where {T,N,R} = MemoryLayout(R)
MemoryLayout(::Type{<:BlockArray{T,N,R}}) where {T,N,R} = BlockLayout{typeof(MemoryLayout(R))}()

sublayout(::BlockLayout{LAY}, ::Type{NTuple{N,BlockSlice1}}) where {LAY,N} = LAY()
sublayout(BL::BlockLayout, ::Type{<:NTuple{N,BlockSlice}}) where N = BL

conjlayout(::Type{T}, ::BlockLayout{LAY}) where {T<:Complex,LAY} = BlockLayout{typeof(conjlayout(T,LAY))}()
conjlayout(::Type{T}, ::BlockLayout{LAY}) where {T<:Real,LAY} = BlockLayout{LAY}()

transposelayout(::BlockLayout{LAY}) where LAY = BlockLayout{typeof(transposelayout(LAY()))}()


block(A::BlockSlice) = block(A.block)
block(A::Block) = A

getblock(A::SubArray{<:Any,N,<:BlockArray,NTuple{N,BlockSlice1}}) where N = 
    getblock(parent(A), Int.(block.(parentindices(A)))...)

strides(A::SubArray{<:Any,N,<:BlockArray,NTuple{N,BlockSlice1}}) where N = 
    strides(getblock(A))


#############
# BLAS overrides
#############


function materialize!(M::MatMulVecAdd{<:AbstractBlockLayout,<:AbstractStridedLayout,<:AbstractStridedLayout})
    α, A, x_in, β, y_in = M.α, M.A, M.B, M.β, M.C
    if length(x_in) != size(A,2) || length(y_in) != size(A,1)
        throw(DimensionMismatch())
    end

    # impose block structure
    y = PseudoBlockArray(y_in, (axes(A,1),))
    x = PseudoBlockArray(x_in, (axes(A,2),))

    _fill_lmul!(β, y)

    for J = blockaxes(A,2)
        for K = blockcolsupport(A,J)
            muladd!(α, view(A,K,J), view(x,J), one(α), view(y,K))
        end
    end
    y_in
end

function _block_muladd!(α, A, X, β, Y)
    _fill_lmul!(β, Y)
    for J = blockaxes(X,2), N = blockcolsupport(X,J), K = blockcolsupport(A,N)
        muladd!(α, view(A,K,N), view(X,N,J), one(α), view(Y,K,J))
    end
    Y
end 

materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractBlockLayout,<:AbstractBlockLayout}) =
    _block_muladd!(M.α, M.A, M.B, M.β, M.C)

function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractBlockLayout,<:AbstractColumnMajor})
    α, A, X, β, Y_in = M.α, M.A, M.B, M.β, M.C
    Y = PseudoBlockArray(Y_in, (axes(A,1), axes(Y_in,2)))
    _block_muladd!(α, A, X, β, Y)
    Y_in
end


function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractColumnMajor,<:AbstractColumnMajor})
    α, A, X_in, β, Y_in = M.α, M.A, M.B, M.β, M.C
    _fill_lmul!(β, Y_in)
    X = PseudoBlockArray(X_in, (axes(A,2), axes(X_in,2)))
    Y = PseudoBlockArray(Y_in, (axes(A,1), axes(Y_in,2)))
    _block_muladd!(α, A, X, β, Y)
    Y_in
end

function materialize!(M::MatMulMatAdd{<:AbstractColumnMajor,<:AbstractBlockLayout,<:AbstractColumnMajor})
    α, A_in, X, β, Y_in = M.α, M.A, M.B, M.β, M.C
    _fill_lmul!(β, Y_in)
    A = PseudoBlockArray(A_in, (axes(A_in,1),axes(X,1)))
    Y = PseudoBlockArray(Y_in, (axes(Y_in,1),axes(X,2)))
    _block_muladd!(α, A, X, β, Y)
    Y_in
end


