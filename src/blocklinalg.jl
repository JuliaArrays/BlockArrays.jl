blockrowsupport(_, A, k) = blockaxes(A,2)
""""
    blockrowsupport(A, k)

gives an iterator containing the possible non-zero blocks in the k-th block-row of A.
"""
blockrowsupport(A, k) = blockrowsupport(MemoryLayout(A), A, k)
blockrowsupport(A) = blockrowsupport(A, blockaxes(A,1))

blockcolsupport(_, A, j) = blockaxes(A,1)

""""
    blockcolsupport(A, j)

gives an iterator containing the possible non-zero blocks in the j-th block-column of A.
"""
blockcolsupport(A, j) = blockcolsupport(MemoryLayout(A), A, j)
blockcolsupport(A) = blockcolsupport(A, blockaxes(A,2))

blockcolstart(A...) = first(blockcolsupport(A...))
blockcolstop(A...) = last(blockcolsupport(A...))
blockrowstart(A...) = first(blockrowsupport(A...))
blockrowstop(A...) = last(blockrowsupport(A...))

for Func in (:blockcolstart, :blockcolstop, :blockrowstart, :blockrowstop)
    @eval $Func(A, i::Block{1}) = $Func(A, Int(i))
end


abstract type AbstractBlockLayout <: MemoryLayout end
struct BlockLayout{LAY} <: AbstractBlockLayout end


similar(M::MulAdd{<:AbstractBlockLayout,<:AbstractBlockLayout}, ::Type{T}, axes) where {T,N} = 
    similar(BlockArray{T}, axes)

MemoryLayout(::Type{<:PseudoBlockArray{T,N,R}}) where {T,N,R} = MemoryLayout(R)
MemoryLayout(::Type{<:BlockArray{T,N,R}}) where {T,N,R} = BlockLayout{typeof(MemoryLayout(R))}()

sublayout(::BlockLayout{LAY}, ::Type{NTuple{N,BlockSlice1}}) where {LAY,N} = LAY()
sublayout(BL::BlockLayout, ::Type{<:NTuple{N,BlockSlice}}) where N = BL

conjlayout(::Type{T}, ::BlockLayout{LAY}) where {T<:Complex,LAY} = BlockLayout{typeof(conjlayout(T,LAY()))}()
conjlayout(::Type{T}, ::BlockLayout{LAY}) where {T<:Real,LAY} = BlockLayout{LAY}()

transposelayout(::BlockLayout{LAY}) where LAY = BlockLayout{typeof(transposelayout(LAY()))}()



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

mul_blockscompatible(A, B, C) = blockisequal(axes(A,2), axes(B,1)) && 
    blockisequal(axes(A,1), axes(C,1)) && 
    blockisequal(axes(B,2), axes(C,2))

function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractBlockLayout,<:AbstractBlockLayout})
    α, A, B, β, C = M.α, M.A, M.B, M.β, M.C
    if mul_blockscompatible(A,B,C)
        _block_muladd!(α, A, B, β, C)
    else # use default
        materialize!(MulAdd{UnknownLayout,UnknownLayout,UnknownLayout}(α, A, B, β, C))
    end
end

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



####
# Triangular
####

@inline hasmatchingblocks(A) = blockisequal(axes(A)...)

triangularlayout(::Type{Tri}, ::ML) where {Tri,ML<:AbstractBlockLayout} = Tri{ML}()

_triangular_matrix(::Val{'U'}, ::Val{'N'}, A) = UpperTriangular(A)
_triangular_matrix(::Val{'L'}, ::Val{'N'}, A) = LowerTriangular(A)
_triangular_matrix(::Val{'U'}, ::Val{'U'}, A) = UnitUpperTriangular(A)
_triangular_matrix(::Val{'L'}, ::Val{'U'}, A) = UnitLowerTriangular(A)


function _matchingblocks_triangular_mul!(::Val{'U'}, UNIT, A::AbstractMatrix{T}, dest) where T
    # impose block structure
    b = PseudoBlockArray(dest, (axes(A,1),))

    for K = blockaxes(A,1)
        b_2 = view(b, K)
        Ũ = _triangular_matrix(Val('U'), UNIT, view(A, K,K))
        materialize!(Lmul(Ũ, b_2))
        JR = (K+1):last(blockrowsupport(A,K))
        if !isempty(JR)
            muladd!(one(T), view(A, K, JR), view(b,JR), one(T), b_2)
        end
    end
    dest
end

function _matchingblocks_triangular_mul!(::Val{'L'}, UNIT, A::AbstractMatrix{T}, dest) where T
    # impose block structure
    b = PseudoBlockArray(dest, (axes(A,1),))

    N = blocksize(A,1)

    for K = N:-1:1
        b_2 = view(b, Block(K))
        L̃ = _triangular_matrix(Val('L'), UNIT, view(A, Block(K,K)))
        materialize!(Lmul(L̃, b_2))
        JR = blockrowstart(A,K):Block(K-1)
        if !isempty(JR)
            muladd!(one(T), view(A, Block(K), JR), view(b,JR), one(T), b_2)
        end
    end

    dest
end

@inline function materialize!(M::MatLmulVec{<:TriangularLayout{UPLO,UNIT,<:AbstractBlockLayout},
                                   <:AbstractStridedLayout}) where {UPLO,UNIT}
    U,x = M.A,M.B
    T = eltype(M)
    @boundscheck size(U,1) == size(x,1) || throw(BoundsError())
    if hasmatchingblocks(U)
        _matchingblocks_triangular_mul!(Val(UPLO), Val(UNIT), triangulardata(U), x)
    else # use default
        x_1 = PseudoBlockArray(copy(x), (axes(U,2),))
        x_2 = PseudoBlockArray(x, (axes(U,1),))
        _block_muladd!(one(T), U, x_1, zero(T), x_2)
    end
end


for UNIT in ('U', 'N')
    @eval begin
        @inline function materialize!(M::MatLdivVec{<:TriangularLayout{'U',$UNIT,<:AbstractBlockLayout},
                                        <:AbstractStridedLayout})
            U,dest = M.A,M.B
            T = eltype(dest)

            A = triangulardata(U)
            if !hasmatchingblocks(A) # Use default for now
                return materialize!(Ldiv{TriangularLayout{'U',$UNIT,UnknownLayout}, 
                                         typeof(MemoryLayout(dest))}(U, dest))
            end

            @boundscheck size(A,1) == size(dest,1) || throw(BoundsError())

            # impose block structure
            b = PseudoBlockArray(dest, (axes(A,1),))

            N = blocksize(A,1)

            for K = N:-1:1
                b_2 = view(b, Block(K))
                Ũ = _triangular_matrix(Val('U'), Val($UNIT), view(A, Block(K,K)))
                materialize!(Ldiv(Ũ, b_2))

                if K ≥ 2
                    KR = blockcolstart(A, K):Block(K-1)
                    V_12 = view(A, KR, Block(K))
                    b̃_1 = view(b, KR)
                    muladd!(-one(T), V_12, b_2, one(T), b̃_1)
                end
            end

            dest
        end

        @inline function materialize!(M::MatLdivVec{<:TriangularLayout{'L',$UNIT,<:AbstractBlockLayout},
                                        <:AbstractStridedLayout})
            L,dest = M.A, M.B
            T = eltype(dest)
            A = triangulardata(L)
            if !hasmatchingblocks(A) # Use default for now
                return materialize!(Ldiv{TriangularLayout{'L',$UNIT,UnknownLayout}, 
                                         typeof(MemoryLayout(dest))}(L, dest))
            end


            @boundscheck size(A,1) == size(dest,1) || throw(BoundsError())

            # impose block structure
            b = PseudoBlockArray(dest, (axes(A,1),))

            N = blocksize(A,1)

            for K = 1:N
                b_2 = view(b, Block(K))
                L̃ = _triangular_matrix(Val('L'), Val($UNIT), view(A, Block(K,K)))
                materialize!(Ldiv(L̃, b_2))

                if K < N
                    KR = Block(K+1):blockcolstop(A, K)
                    V_12 = view(A, KR, Block(K))
                    b̃_1 = view(b, KR)
                    muladd!(-one(T), V_12, b_2, one(T), b̃_1)
                end
            end

            dest
        end
    end
end