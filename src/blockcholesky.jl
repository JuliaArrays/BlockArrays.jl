

##########################################
# Cholesky Factorization on BlockMatrices#
##########################################


cholesky(A::Symmetric{<:Real,<:BlockArray},
    ::Val{false}=Val(false); check::Bool = false) = cholesky!(cholcopy(A); check = check)


function b_chol!(A::BlockArray{T}, ::Type{UpperTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        for i = 1:n
            Pii = getblock(A,i,i) 
            for k = 1:i-1
                muladd!(-1.0, getblock(A,k,i)', getblock(A,k,i), 1.0, Pii)
            end
            Aii, info = LinearAlgebra._chol!(Pii, UpperTriangular)
            if !iszero(info)
                @assert info > 0
                if i == 1
                    return UpperTriangular(A), info
                end
                info += sum(size(A[Block(l,l)])[1] for l=1:i-1) 
                return UpperTriangular(A), info
            end

            for j = i+1:n
                Pij = getblock(A,i,j)
                for k = 1:i-1
                    muladd!(-1.0, getblock(A,k,i)', getblock(A,k,j), 1.0, Pij)
                end
                ldiv!(UpperTriangular(getblock(A,i,i))', Pij)
            end
        end
    end
 
    return UpperTriangular(A), 0
end


function b_chol!(A::BlockArray{T}, ::Type{LowerTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        for i = 1:n
            Pii = getblock(A,i,i) 
            for k = 1:i-1
                muladd!(-1.0, getblock(A,i,k), getblock(A,i,k)', 1.0, Pii)
            end
            Aii, info = LinearAlgebra._chol!(Pii, LowerTriangular)
            if !iszero(info)
                @assert info > 0
                if i == 1
                    return UpperTriangular(A), info
                end
                info += sum(size(A[Block(l,l)])[1] for l=1:i-1) 
                return LowerTriangular(A), info
            end
    
            for j = i+1:n
                Pij = getblock(A,j,i)
                for k = 1:i-1
                    muladd!(-1.0, getblock(A,j,k), getblock(A,i,k)', 1.0, Pij)
                end
                rdiv!(Pij, LowerTriangular(getblock(A,i,i))')
            end
        end
    end

    return LowerTriangular(A), 0
end

function cholesky!(A::Symmetric{<:Real,<:BlockArray}, ::Val{false}=Val(false); check::Bool = false)
    C, info = b_chol!(A.data, A.uplo == 'U' ? UpperTriangular : LowerTriangular)
    #check && LinearAlgebra.checkpositivedefinite(info)
    return Cholesky(C.data, A.uplo, info)
end

