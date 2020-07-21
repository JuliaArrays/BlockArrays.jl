

##########################
# Cholesky Factorization #
##########################

"""
Funtions to do
2.check square
3.check positive definite
"""

cholesky(A::Symmetric{<:Real,<:BlockArray},
    ::Val{false}=Val(false); check::Bool = true) = cholesky!(cholcopy(A); check = check)


function b_chol!(A::BlockArray{T}, ::Type{UpperTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        # Initializing the first role of blocks
        cholesky!(Symmetric(getblock(A,1,1)))
        for j = 2:n
            ldiv!(UpperTriangular(getblock(A,1,1))', getblock(A,1,j))
        end

        # For the left blocks
        for i = 2:n
            Pii = getblock(A,i,i) 
            for k = 1:i-1
                muladd!(-1.0, getblock(A,k,i)', getblock(A,k,i), 1.0, Pii)
            end
            cholesky!(Symmetric(Pii))
    
            for j = i+1:n
                Pij = getblock(A,i,j)
                for k = 1:i-1
                    muladd!(-1.0, getblock(A,k,i)', getblock(A,k,j), 1.0, Pij)
                end
                ldiv!(UpperTriangular(getblock(A,i,i))', Pij)
            end
        end
    end

    return UpperTriangular(A)
end
function b_chol!(A::BlockArray{T}, ::Type{LowerTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        # Initializing the first role of blocks
        cholesky!(Symmetric(getblock(A,1,1), :L))
        for j = 2:n
            rdiv!(getblock(A,j,1), LowerTriangular(getblock(A,1,1))')
        end

        # For the left blocks
        for i = 2:n
            Pii = getblock(A,i,i) 
            for k = 1:i-1
                muladd!(-1.0, getblock(A,i,k), getblock(A,i,k)', 1.0, Pii)
            end
            cholesky!(Symmetric(Pii, :L))
    
            for j = i+1:n
                Pij = getblock(A,j,i)
                for k = 1:i-1
                    muladd!(-1.0, getblock(A,j,k), getblock(A,i,k)', 1.0, Pij)
                end
                rdiv!(Pij, LowerTriangular(getblock(A,i,i))')
            end
        end
    end

    return LowerTriangular(A)
end

function cholesky!(A::Symmetric{<:Real,<:BlockArray}, ::Val{false}=Val(false); check::Bool = true)
    C = b_chol!(A.data, A.uplo == 'U' ? UpperTriangular : LowerTriangular)
    #check && checkpositivedefinite(info)
    return Cholesky(C.data, A.uplo, 0)
end

