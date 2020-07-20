
##########################
# Cholesky Factorization #
##########################

"""
Funtions to do
1.cholesky structure
2.check square
3.check positive definite
4.swap 'cholesky!'
"""

cholesky(A::Symmetric{<:Real,<:BlockArray},
    ::Val{false}=Val(false); check::Bool = true) = cholesky!(cholcopy(A); check = check)

function cholesky!(A::Symmetric{<:Real,<:BlockArray}; check::Bool = true)
    
    chol_P = parent(A)

    # Initializing the first role of blocks
    cholesky!(Symmetric(getblock(chol_P,1,1)))
    for j = 2:blocksize(A)[1]
        ldiv!(UpperTriangular(getblock(chol_P,1,1))', getblock(chol_P,1,j))
    end

    # For the left blocks
    for i = 2:blocksize(A)[1]
        Pii = getblock(chol_P,i,i) 
        for k = 1:i-1
            mul!(Pii,getblock(chol_P,k,i)',getblock(chol_P,k,i),-1.0,1.0)
        end
        cholesky!(Symmetric(Pii))

        for j = i+1:blocksize(A)[1]
            Pij = getblock(chol_P,i,j)
            for k = 1:i-1
                mul!(Pij,getblock(chol_P,k,i)',getblock(chol_P,k,j),-1.0,1.0)
            end
            ldiv!(UpperTriangular(getblock(chol_P,i,i))', Pij)
        end
    end
    
    return UpperTriangular(chol_P)
end
