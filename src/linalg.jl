
@lazymul AbstractBlockMatrix

MemoryLayout(A::PseudoBlockArray) = MemoryLayout(A.blocks)


function materialize!(M::MatMulVecAdd{<:AbstractBlockLayout,<:AbstractStridedLayout,<:AbstractStridedLayout})
    α, A, x_in, β, y_in = M.α, M.A, M.B, M.β, M.C
    if length(x_in) != size(A,2) || length(y_in) != size(A,1)
        throw(DimensionMismatch())
    end

    # impose block structure
    y = PseudoBlockArray(y_in, BlockSizes((cumulsizes(blocksizes(A),1),)))
    x = PseudoBlockArray(x_in, BlockSizes((cumulsizes(blocksizes(A),2),)))

    _fill_lmul!(β, y)

    for J = Block.(1:nblocks(A,2))
        for K = blockcolrange(A,J)
            view(y,K) .= α .* Mul(view(A,K,J), view(x,J)) .+ view(y,K)
        end
    end
    y_in
end

function materialize!(M::MatMulMatAdd{<:AbstractBlockBandedLayout,<:AbstractBlockBandedLayout,<:AbstractBlockBandedLayout})
    α, A, X, β, Y = M.α, M.A, M.B, M.β, M.C
    _fill_lmul!(β, Y)
    for J=Block(1):Block(nblocks(X,2)),
            N=blockcolrange(X,J), K=blockcolrange(A,N)
        view(Y,K,J) .= α .* Mul( view(A,K,N), view(X,N,J)) .+ view(Y,K,J)
    end
    Y
end

function materialize!(M::MatMulMatAdd{<:AbstractBlockBandedLayout,<:AbstractColumnMajor,<:AbstractColumnMajor})
    α, A, X_in, β, Y_in = M.α, M.A, M.B, M.β, M.C
    _fill_lmul!(β, Y_in)
    X = PseudoBlockArray(X_in, BlockSizes((cumulsizes(blocksizes(A),2),[1,size(X_in,2)+1])))
    Y = PseudoBlockArray(Y_in, BlockSizes((cumulsizes(blocksizes(A),1), [1,size(Y_in,2)+1])))
    for N=Block.(1:nblocks(X,1)), K=blockcolrange(A,N)
        view(Y,K,Block(1)) .= α .* Mul( view(A,K,N), view(X,N,Block(1))) .+ view(Y,K,Block(1))
    end
    Y_in
end

function materialize!(M::MatMulMatAdd{<:AbstractColumnMajor,<:AbstractBlockBandedLayout,<:AbstractColumnMajor})
    α, A_in, X, β, Y_in = M.α, M.A, M.B, M.β, M.C
    _fill_lmul!(β, Y_in)
    A = PseudoBlockArray(A_in, BlockSizes(([1,size(A_in,1)+1],cumulsizes(blocksizes(X),1))))
    Y = PseudoBlockArray(Y_in, BlockSizes(([1,size(Y_in,1)+1],cumulsizes(blocksizes(X),2))))
    for J=Block(1):Block(nblocks(X,2)), N=blockcolrange(X,J)
        view(Y,Block(1),J) .= α .* Mul( view(A,Block(1),N), view(X,N,J)) .+ view(Y,Block(1),J)
    end
    Y_in
end
