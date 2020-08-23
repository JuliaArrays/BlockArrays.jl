

sparsecholesky(A::Symmetric{<:Real,<:BlockArray},
::Val{false}=Val(false); check::Bool = true) = sparsecholesky!(cholcopy(A); check = check)



function _blockbandedcholesky!(A::BlockArray{T}, ::Type{UpperTriangular}) where T<:Real
    n = blocksize(A)[1]
    k_end = 0

    @inbounds begin
        for i = 1:n
            Pii = getblock(A,i,i)
            for k = 1:i-1
                muladd!(-one(T), getblock(A,k,i)', getblock(A,k,i), one(T), Pii)
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
            
            k_start = n
            while getblock(A,i,k_start) ≈ zeros(Float32, size(getblock(A,i,k_start))) && k_start > k_end
                k_start -= 1
            end
            k_end = k_start

            for j = k_start:-1:i+1
                Pij = getblock(A,i,j)
                for k = 1:i-1
                    muladd!(-one(T), getblock(A,k,i)', getblock(A,k,j), one(T), Pij)
                end
                ldiv!(UpperTriangular(getblock(A,i,i))', Pij)
            end
        end
    end
 
    return UpperTriangular(A), 0
end

function _blockbandedcholesky!(A::BlockArray{T}, ::Type{LowerTriangular}) where T<:Real
    n = blocksize(A)[1]
    k_end = 0

    @inbounds begin
        for i = 1:n
            Pii = getblock(A,i,i) 
            for k = 1:i-1
                muladd!(-one(T), getblock(A,i,k), getblock(A,i,k)', one(T), Pii)
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

            k_start = n
            while getblock(A,k_start,i) ≈ zeros(Float32, size(getblock(A,k_start,i))) && k_start > k_end
                k_start -= 1
            end
            k_end = k_start

            for j = k_start:-1:i+1
                Pij = getblock(A,j,i)
                for k = 1:i-1
                    muladd!(-one(T), getblock(A,j,k), getblock(A,i,k)', one(T), Pij)
                end
                rdiv!(Pij, LowerTriangular(getblock(A,i,i))')
            end
        end
    end

    return LowerTriangular(A), 0
end


function sparsecholesky!(A::Symmetric{<:Real,<:BlockArray}, ::Val{false}=Val(false); check::Bool = true)
    C, info = _blockbandedcholesky!(A.data, A.uplo == 'U' ? UpperTriangular : LowerTriangular)
    #check && LinearAlgebra.checkpositivedefinite(info)
    return Cholesky(C.data, A.uplo, info)
end
