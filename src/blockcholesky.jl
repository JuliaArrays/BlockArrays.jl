
# Function for cholesky decomposition on block matries
# 'cholesky' is the build-in one in LAPACK

function Bcholesky(A::Symmetric{<:Any,<:BlockArray})
    chol_U = BlockArray{Float64}(zeros(size(A)), fill(size(A)[1]÷blocksize(A)[1], blocksize(A)[1]), fill(size(A)[1]÷blocksize(A)[1], blocksize(A)[1]))

    # Initializing the first role of blocks
    chol_U[Block(1,1)] = cholesky!(A[Block(1,1)]).U
    for j = 2:blocksize(A)[1]
        chol_U[Block(1,j)] = chol_U[Block(1,1)]' \ A[Block(1,j)]
    end

    # For the left blocks
    for i = 2:blocksize(A)[1]
        for j = i:blocksize(A)[1]
            if j == i
                chol_U[Block(i,j)] = cholesky!(A[Block(i,j)] - sum(chol_U[Block(k,j)]'chol_U[Block(k,j)] for k in 1:j-1)).U
            else
                chol_U[Block(i,j)] = chol_U[Block(i,i)]' \ (A[Block(i,j)] - sum(chol_U[Block(k,i)]'chol_U[Block(k,j)] for k in 1:j-1))
            end
        end
    end

    return chol_U

end
