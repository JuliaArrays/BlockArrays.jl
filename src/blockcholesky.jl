

##########################################
# Cholesky Factorization on BlockMatrices#
##########################################


cholesky(A::Symmetric{<:Real,<:AbstractArray},
    ::Val{false}=Val(false); check::Bool = true) = cholesky!(cholcopy(A); check = check)


function _diag_chol!(A::AbstractArray{T}, i::Int, ::Type{UpperTriangular}) where T<:Real
    Pii = getblock(A,i,i)
    for k = 1:i-1
        muladd!(-one(T), getblock(A,k,i)', getblock(A,k,i), one(T), Pii)
    end
    return LinearAlgebra._chol!(Pii, UpperTriangular)
end

function _diag_chol!(A::AbstractArray{T}, i::Int, ::Type{LowerTriangular}) where T<:Real
    Pii = getblock(A,i,i)
    for k = 1:i-1
        muladd!(-one(T), getblock(A,i,k), getblock(A,i,k)', one(T), Pii)
    end
    return LinearAlgebra._chol!(Pii, LowerTriangular)
end

function _nondiag_chol!(A::AbstractArray{T}, i::Int, n::Int, ::Type{UpperTriangular}) where T<:Real
    for j = intersect(convert(Array{Int,1},blockrowsupport(A,i)),i+1:n)
        Pij = getblock(A,i,j)
        for k = 1:i-1
            muladd!(-one(T), getblock(A,k,i)', getblock(A,k,j), one(T), Pij)
        end
        ldiv!(UpperTriangular(getblock(A,i,i))', Pij)
    end
end

function _nondiag_chol!(A::AbstractArray{T}, i::Int, n::Int, ::Type{LowerTriangular}) where T<:Real
    for j = intersect(convert(Array{Int,1},blockcolsupport(A,i)),i+1:n)
        Pij = getblock(A,j,i)
        for k = 1:i-1
            muladd!(-one(T), getblock(A,j,k), getblock(A,i,k)', one(T), Pij)
        end
        rdiv!(Pij, LowerTriangular(getblock(A,i,i))')
    end
end


function _block_chol!(A::AbstractArray{T}, ::Type{UpperTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        for i = 1:n
            Aii, info = _diag_chol!(A, i, UpperTriangular)

            if !iszero(info)
                @assert info > 0
                if i == 1
                    return UpperTriangular(A), info
                end
                info += sum(size(A[Block(l,l)])[1] for l=1:i-1) 
                return UpperTriangular(A), info
            end

            _nondiag_chol!(A, i, n, UpperTriangular)
        end
    end
 
    return UpperTriangular(A), 0
end


function _block_chol!(A::AbstractArray{T}, ::Type{LowerTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        for i = 1:n
            Aii, info = _diag_chol!(A, i, LowerTriangular)

            if !iszero(info)
                @assert info > 0
                if i == 1
                    return UpperTriangular(A), info
                end
                info += sum(size(A[Block(l,l)])[1] for l=1:i-1) 
                return LowerTriangular(A), info
            end
    
            _nondiag_chol!(A, i, n, LowerTriangular)
        end
    end

    return LowerTriangular(A), 0
end

function cholesky!(A::Symmetric{<:Real,<:AbstractArray}, ::Val{false}=Val(false); check::Bool = true)
    C, info = _block_chol!(A.data, A.uplo == 'U' ? UpperTriangular : LowerTriangular)
    #check && LinearAlgebra.checkpositivedefinite(info)
    return Cholesky(C.data, A.uplo, info)
end

