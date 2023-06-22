blockrowsupport(_, A, k) = blockaxes(A,2)
"""
    blockrowsupport(A, k)

Return an iterator containing the possible non-zero blocks in the k-th block-row of A.

# Examples
```jldoctest
julia> B = BlockArray(collect(reshape(1:9, 3, 3)), [1,2], [1,2])
2×2-blocked 3×3 BlockMatrix{Int64}:
 1  │  4  7
 ───┼──────
 2  │  5  8
 3  │  6  9

julia> BlockArrays.blockrowsupport(B, 2)
2-element BlockRange{1, Tuple{Base.OneTo{Int64}}}:
 Block(1)
 Block(2)
```
"""
blockrowsupport(A, k) = blockrowsupport(MemoryLayout(A), A, k)
blockrowsupport(A) = blockrowsupport(A, blockaxes(A,1))

blockcolsupport(_, A, j) = Block.(colsupport(blocks(A), Int.(j)))

"""
    blockcolsupport(A, j)

Return an iterator containing the possible non-zero blocks in the j-th block-column of A.

# Examples
```jldoctest
julia> B = BlockArray(collect(reshape(1:9, 3, 3)), [1,2], [1,2])
2×2-blocked 3×3 BlockMatrix{Int64}:
 1  │  4  7
 ───┼──────
 2  │  5  8
 3  │  6  9

julia> BlockArrays.blockcolsupport(B, 2)
2-element BlockRange{1, Tuple{Base.OneTo{Int64}}}:
 Block(1)
 Block(2)
```
"""
blockcolsupport(A, j) = blockcolsupport(MemoryLayout(A), A, j)
blockcolsupport(A) = blockcolsupport(A, blockaxes(A,2))

blockcolstart(A...) = first(blockcolsupport(A...))
blockcolstop(A...) = last(blockcolsupport(A...))
blockrowstart(A...) = first(blockrowsupport(A...))
blockrowstop(A...) = last(blockrowsupport(A...))


for Func in (:blockcolstart, :blockcolstop, :blockrowstart, :blockrowstop)
    @eval @deprecate $Func(A, i::Integer) $Func(A, Block(i))
end

abstract type AbstractBlockLayout <: MemoryLayout end
struct BlockLayout{ArrLay,BlockLay} <: AbstractBlockLayout end

function colsupport(::BlockLayout, A, j)
    JR = Int(findblock(axes(A,2), minimum(j))):Int(findblock(axes(A,2), maximum(j)))
    KR = colsupport(blocks(A), JR)
    axes(A,1)[Block.(KR)]
end

function rowsupport(::BlockLayout, A, k)
    KR = Int(findblock(axes(A,1), minimum(k))):Int(findblock(axes(A,1), maximum(k)))
    JR = rowsupport(blocks(A), KR)
    axes(A,2)[Block.(JR)]
end



similar(M::MulAdd{<:AbstractBlockLayout,<:AbstractBlockLayout}, ::Type{T}, axes) where {T} =
    similar(BlockArray{T}, axes)

@inline MemoryLayout(::Type{<:PseudoBlockArray{T,N,R}}) where {T,N,R} = MemoryLayout(R)
@inline MemoryLayout(::Type{<:BlockArray{T,N,R}}) where {T,N,D,R<:AbstractArray{D,N}} =
    BlockLayout{typeof(MemoryLayout(R)),typeof(MemoryLayout(D))}()

sublayout(::BlockLayout{MLAY,BLAY}, ::Type{<:NTuple{N,BlockSlice1}}) where {MLAY,BLAY,N} = BLAY()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:NTuple{N,<:BlockSlice{BlockRange{1,Tuple{II}}}}}) where {N,MLAY,BLAY,II} =
    BlockLayout{typeof(sublayout(MLAY(),NTuple{N,II})), BLAY}()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:Tuple{BlockSlice1,<:BlockSlice{BlockRange{1,Tuple{II}}}}}) where {MLAY,BLAY,II} =
    BlockLayout{typeof(sublayout(MLAY(),Tuple{Int,II})), BLAY}()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:Tuple{BlockSlice{BlockRange{1,Tuple{II}}},BlockSlice1}}) where {MLAY,BLAY,II} =
    BlockLayout{typeof(sublayout(MLAY(),Tuple{II,Int})), BLAY}()
# This might need modification: no guarantee axes(BL,1) == axes(MLAY,1) so Slice might not be right here
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:Tuple{Sl,<:BlockSlice{BlockRange{1,Tuple{II}}}}}) where {MLAY,BLAY,Sl<:Slice,II} =
    BlockLayout{typeof(sublayout(MLAY(),Tuple{Sl,II})), BLAY}()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:Tuple{<:BlockSlice{BlockRange{1,Tuple{II}}},Sl}}) where {MLAY,BLAY,Sl<:Slice,II} =
    BlockLayout{typeof(sublayout(MLAY(),Tuple{II,Sl})), BLAY}()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:Tuple{Sl1,Sl2}}) where {MLAY,BLAY,Sl1<:Slice,Sl2<:Slice} =
    BlockLayout{typeof(sublayout(MLAY(),Tuple{Sl1,Sl2})), BLAY}()
sublayout(BL::BlockLayout{MLAY,BLAY}, ::Type{<:NTuple{N,<:BlockedUnitRange}}) where {N,MLAY,BLAY} =
    BlockLayout{typeof(sublayout(MLAY(),NTuple{N,Base.OneTo{Int}})), BLAY}()

# materialize views, used for `getindex`
sub_materialize(::AbstractBlockLayout, V, _) = BlockArray(V)
sub_materialize(::AbstractBlockLayout, V, ::Tuple{<:BlockedUnitRange}) = BlockArray(V)
sub_materialize(::AbstractBlockLayout, V, ::Tuple{<:BlockedUnitRange,<:BlockedUnitRange}) = BlockArray(V)
sub_materialize(::AbstractBlockLayout, V, ::Tuple{<:AbstractUnitRange,<:BlockedUnitRange}) = BlockArray(V)
sub_materialize(::AbstractBlockLayout, V, ::Tuple{<:BlockedUnitRange,<:AbstractUnitRange}) = BlockArray(V)

# if it's not a block layout, best to use PseudoBlockArray to take advantage of strideness
sub_materialize(_, V, ::Tuple{<:BlockedUnitRange}) = PseudoBlockArray(V)
sub_materialize(_, V, ::Tuple{<:BlockedUnitRange,<:BlockedUnitRange}) = PseudoBlockArray(V)
sub_materialize(_, V, ::Tuple{<:AbstractUnitRange,<:BlockedUnitRange}) = PseudoBlockArray(V)
sub_materialize(_, V, ::Tuple{<:BlockedUnitRange,<:AbstractUnitRange}) = PseudoBlockArray(V)

# Special for FillArrays.jl

# special case for fill blocks
LinearAlgebra.fill!(V::SubArray{T,1,<:BlockArray,<:Tuple{BlockSlice1}}, x) where T =
    fill!(view(parent(V), parentindices(V)[1].block), x)

FillArrays.getindex_value(V::SubArray{T,1,<:BlockArray,<:Tuple{BlockSlice1}}) where T =
    FillArrays.getindex_value(view(parent(V), block(parentindices(V)[1])))

sub_materialize(::ArrayLayouts.AbstractFillLayout, V, ax::Tuple{<:BlockedUnitRange,<:AbstractUnitRange}) =
    Fill(FillArrays.getindex_value(V), ax)
sub_materialize(::ArrayLayouts.OnesLayout, V, ax::Tuple{<:BlockedUnitRange,<:AbstractUnitRange}) =
    Ones{eltype(V)}(ax)
sub_materialize(::ArrayLayouts.ZerosLayout, V, ax::Tuple{<:BlockedUnitRange,<:AbstractUnitRange}) =
    Zeros{eltype(V)}(ax)
sub_materialize(::ArrayLayouts.AbstractFillLayout, V, ax::Tuple{<:AbstractUnitRange,<:BlockedUnitRange}) =
    Fill(FillArrays.getindex_value(V), ax)
sub_materialize(::ArrayLayouts.OnesLayout, V, ax::Tuple{<:AbstractUnitRange,<:BlockedUnitRange}) =
    Ones{eltype(V)}(ax)
sub_materialize(::ArrayLayouts.ZerosLayout, V, ax::Tuple{<:AbstractUnitRange,<:BlockedUnitRange}) =
    Zeros{eltype(V)}(ax)

@propagate_inbounds Base.view(A::FillArrays.AbstractFill, I::Union{Real, AbstractArray, Block}...) =
    FillArrays._fill_getindex(A, Base.to_indices(A, I)...)

conjlayout(::Type{T}, ::BlockLayout{MLAY,BLAY}) where {T<:Complex,MLAY,BLAY} = BlockLayout{MLAY,typeof(conjlayout(T,BLAY()))}()
conjlayout(::Type{T}, ::BlockLayout{MLAY,BLAY}) where {T<:Real,MLAY,BLAY} = BlockLayout{MLAY,BLAY}()

transposelayout(::BlockLayout{MLAY,BLAY}) where {MLAY,BLAY} =
    BlockLayout{typeof(transposelayout(MLAY())),typeof(transposelayout(BLAY()))}()

#############
# copyto!
#############

function _copyto!(_, ::AbstractBlockLayout, dest::AbstractVector, src::AbstractVector)
    if !blockisequal(axes(dest), axes(src))
        # impose block structure
        copyto!(PseudoBlockArray(dest, axes(src)), src)
        return dest
    end

    @inbounds for K = blockaxes(src,1)
        copyto!(view(dest,K), view(src,K))
    end
    dest
end

function _copyto!(_, ::AbstractBlockLayout, dest::AbstractMatrix, src::AbstractMatrix)
    if !blockisequal(axes(dest), axes(src))
        # impose block structure
        copyto!(PseudoBlockArray(dest, axes(src)), src)
        return dest
    end

    @inbounds for J = blockaxes(src,2)
        CS_s = blockcolsupport(src,J)
        CS_d = blockcolsupport(dest,J)
        for K = first(CS_d):first(CS_s)-Block(1)
            zero!(view(dest,K,J))
        end
        for K = CS_s
            copyto!(view(dest,K,J), view(src,K,J))
        end
        for K = last(CS_s)+Block(1):last(CS_d)
            zero!(view(dest,K,J))
        end
    end
    dest
end


####
# l/rmul!
#####


function materialize!(L::Lmul{ScalarLayout,<:AbstractBlockLayout})
    α, block_array = L.A, L.B
    for block in blocks(block_array)
        lmul!(α, block)
    end
    block_array
end

function materialize!(L::Rmul{<:AbstractBlockLayout,ScalarLayout})
    block_array, α = L.A, L.B
    for block in block_array.blocks
        rmul!(block, α)
    end
    block_array
end

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

@inline function _block_muladd!(α, A, X::AbstractVector, β, Y::AbstractVector)
    _fill_lmul!(β, Y)
    for N = blockcolsupport(X), K = blockcolsupport(A,N)
        mul!(view(Y,K), view(A,K,N), view(X,N), α, one(β))
    end
    Y
end

@inline function _block_muladd!(α, A, X, β, Y)
    _fill_lmul!(β, Y)
    for J = blockaxes(X,2), N = blockcolsupport(X,J), K = blockcolsupport(A,N)
        mul!(view(Y,K,J), view(A,K,N), view(X,N,J), α, one(α))
    end
    Y
end

mul_blockscompatible(A, B, C) = blockisequal(axes(A,2), axes(B,1)) &&
    blockisequal(axes(A,1), axes(C,1)) &&
    blockisequal(axes(B,2), axes(C,2))

@inline function _matmul(M)
    α, A, B, β, C = M.α, M.A, M.B, M.β, M.C
    if mul_blockscompatible(A,B,C)
        _block_muladd!(α, A, B, β, C)
    else # use default
        materialize!(MulAdd{UnknownLayout,UnknownLayout,UnknownLayout}(α, A, B, β, C))
    end
end

function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractBlockLayout,<:AbstractBlockLayout})
    _matmul(M)
end

function materialize!(M::MatMulVecAdd{<:AbstractBlockLayout, <:AbstractBlockLayout, <:AbstractBlockLayout})
    _matmul(M)
end

function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractBlockLayout,<:AbstractColumnMajor})
    α, A, X, β, Y_in = M.α, M.A, M.B, M.β, M.C
    Y = PseudoBlockArray(Y_in, (axes(A,1), axes(X,2)))
    _block_muladd!(α, A, X, β, Y)
    Y_in
end

function materialize!(M::MatMulMatAdd{<:AbstractBlockLayout,<:AbstractColumnMajor,<:AbstractColumnMajor})
    α, A, X_in, β, Y_in = M.α, M.A, M.B, M.β, M.C
    X = PseudoBlockArray(X_in, (axes(A,2), axes(X_in,2)))
    Y = PseudoBlockArray(Y_in, (axes(A,1), axes(X_in,2)))
    _block_muladd!(α, A, X, β, Y)
    Y_in
end

function materialize!(M::MatMulMatAdd{<:AbstractColumnMajor,<:AbstractBlockLayout,<:AbstractColumnMajor})
    α, A_in, X, β, Y_in = M.α, M.A, M.B, M.β, M.C
    A = PseudoBlockArray(A_in, (axes(A_in,1),axes(X,1)))
    Y = PseudoBlockArray(Y_in, (axes(A,1),axes(X,2)))
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
        JR = blockrowstart(A,Block(K)):Block(K-1)
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

                if K ≥ 2
                    KR = blockcolstart(A, Block(K)):Block(K-1)
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
                    KR = Block(K+1):blockcolstop(A, Block(K))
                    V_12 = view(A, KR, Block(K))
                    b̃_1 = view(b, KR)
                    muladd!(-one(T), V_12, b_2, one(T), b̃_1)
                end
            end

            dest
        end
    end
end

# For now, use PseudoBlockArray
_inv(::AbstractBlockLayout, axes, A) = BlockArray(inv(PseudoBlockArray(A)))

for op in (:exp, :log, :sqrt)
    @eval begin
       $op(A::PseudoBlockMatrix) = PseudoBlockMatrix($op(A.blocks), axes(A))
    end
end
