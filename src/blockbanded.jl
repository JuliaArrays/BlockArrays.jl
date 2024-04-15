const BlockDiagonal{T,VT<:Matrix{T}} = BlockMatrix{T,<:Diagonal{VT}}

BlockDiagonal(A) = mortar(Diagonal(A))


# Block Bi/Tridiagonal
const BlockTridiagonal{T,VT<:Matrix{T}} = BlockMatrix{T,<:Tridiagonal{VT}}
const BlockBidiagonal{T,VT<:Matrix{T}} = BlockMatrix{T,<:Bidiagonal{VT}}

BlockTridiagonal(A,B,C) = mortar(Tridiagonal(A,B,C))
BlockBidiagonal(A, B, uplo) = mortar(Bidiagonal(A,B,uplo))

sizes_from_blocks(A::Diagonal, _) = (size.(A.diag, 1), size.(A.diag,2))

function sizes_from_blocks(A::Tridiagonal, _)
    for k = 1:length(A.du)
        size(A.du[k],1) == size(A.d[k],1) || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
        size(A.du[k],2) == size(A.d[k+1],2) || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
        size(A.dl[k],1) == size(A.d[k+1],1) || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
        size(A.dl[k],2) == size(A.d[k],2) || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
    end
    (size.(A.d, 1), size.(A.d,2))
end

function sizes_from_blocks(A::Bidiagonal, _)
    if A.uplo == 'U'
        for k = 1:length(A.ev)
            size(A.ev[k],1) == size(A.dv[k],1) || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
            size(A.ev[k],2) == size(A.dv[k+1],2) || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
        end
    else
        for k = 1:length(A.ev)
            size(A.ev[k],1) == size(A.dv[k+1],1) || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
            size(A.ev[k],2) == size(A.dv[k],2) || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
        end
    end
    (size.(A.dv, 1), size.(A.dv,2))
end


# viewblock needs to handle zero blocks
@inline function viewblock(block_arr::BlockBidiagonal{T,VT}, KJ::Block{2}) where {T,VT<:AbstractMatrix}
    K,J = KJ.n
    @boundscheck blockcheckbounds(block_arr, K, J)
    l,u = block_arr.blocks.uplo == 'U' ? (0,1) : (1,0)
    -l ≤ (J-K) ≤ u || return convert(VT, Zeros{T}(length.(getindex.(axes(block_arr),(Block(K),Block(J))))...))
    block_arr.blocks[K,J]
end

@inline function viewblock(block_arr::BlockTridiagonal{T,VT}, KJ::Block{2}) where {T,VT<:AbstractMatrix}
    K,J = KJ.n
    @boundscheck blockcheckbounds(block_arr, K, J)
    abs(J-K) ≥ 2 && return convert(VT, Zeros{T}(length.(getindex.(axes(block_arr),(Block(K),Block(J))))...))
    block_arr.blocks[K,J]
end

checksquareblocks(A) = blockisequal(axes(A)...) || throw(DimensionMismatch("blocks are not square: block dimensions are $(axes(A))"))

# special case UniformScaling arithmetic
for op in (:-, :+)
    @eval begin
        function $op(A::BlockDiagonal, λ::UniformScaling)
            checksquareblocks(A)
            mortar(Diagonal(broadcast($op, A.blocks.diag, Ref(λ))))
        end
        function $op(λ::UniformScaling, A::BlockDiagonal)
            checksquareblocks(A)
            mortar(Diagonal(broadcast($op, Ref(λ), A.blocks.diag)))
        end

        function $op(A::BlockTridiagonal, λ::UniformScaling)
            checksquareblocks(A)
            mortar(Tridiagonal(broadcast($op, A.blocks.dl, Ref(0λ)),
                               broadcast($op, A.blocks.d, Ref(λ)),
                               broadcast($op, A.blocks.du, Ref(0λ))))
        end
        function $op(λ::UniformScaling, A::BlockTridiagonal)
            checksquareblocks(A)
            mortar(Tridiagonal(broadcast($op, Ref(0λ), A.blocks.dl),
                               broadcast($op, Ref(λ), A.blocks.d),
                               broadcast($op, Ref(0λ), A.blocks.du)))
        end
        function $op(A::BlockBidiagonal, λ::UniformScaling)
            checksquareblocks(A)
            mortar(Bidiagonal(broadcast($op, A.blocks.dv, Ref(λ)), A.blocks.ev, A.blocks.uplo))
        end
        function $op(λ::UniformScaling, A::BlockBidiagonal)
            checksquareblocks(A)
            mortar(Bidiagonal(broadcast($op, Ref(λ), A.blocks.dv), broadcast($op,A.blocks.ev), A.blocks.uplo))
        end
    end
end