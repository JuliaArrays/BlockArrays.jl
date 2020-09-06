
##########################################
# Cholesky Factorization on BlockMatrices#
##########################################


cholesky(A::Symmetric{<:Real,<:AbstractArray},
    ::Val{false}=Val(false); check::Bool = true) = cholesky!(cholcopy(A); check = check)

function _diag_chol!(A::AbstractArray{T}, i::Int, ::Type{UpperTriangular}) where T<:Real
    Pii = view(A,Block(i,i))
    for k = 1:i-1
        muladd!(-one(T), getblock(A,k,i)', getblock(A,k,i), one(T), Pii)
    end
    return LAPACK.potrf!('U', Pii)
end

function _diag_chol!(A::AbstractArray{T}, i::Int, ::Type{LowerTriangular}) where T<:Real
    Pii = view(A,Block(i,i))
    for k = 1:i-1
        muladd!(-one(T), getblock(A,k,i)', getblock(A,k,i), one(T), Pii)
    end
    return LAPACK.potrf!('U', Pii)
end

function _nondiag_chol!(A::AbstractArray{T}, i::Int, n::Int, ::Type{UpperTriangular}) where T<:Real
    for j = intersect(convert(Array{Int,1},blockrowsupport(A,i)),i+1:n)
        Pij = view(A,Block(i,j))
        for k = 1:i-1
            muladd!(-one(T), getblock(A,k,i)', getblock(A,k,j), one(T), Pij)
        end
        ldiv!(transpose(UpperTriangular(getblock(A,i,i))), Pij)
    end
end

function _nondiag_chol!(A::AbstractArray{T}, i::Int, n::Int, ::Type{LowerTriangular}) where T<:Real
    for j = intersect(convert(Array{Int,1},blockrowsupport(A,i)),i+1:n)
        Pij = view(A,Block(i,j))
        for k = 1:i-1
            muladd!(-one(T), getblock(A,k,i)', getblock(A,k,j), one(T), Pij)
        end
        ldiv!(UpperTriangular(getblock(A,i,i))', Pij)
    end
end

function _block_chol!(A::AbstractArray{T}, ::Type{UpperTriangular}) where T<:Real
    n = blocksize(A)[1]

    @inbounds begin
        for i = 1:n
            _, info = _diag_chol!(A, i, UpperTriangular)

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
    A = copy(transpose(A))

    @inbounds begin
        for i = 1:n
            _, info = _diag_chol!(A, i, LowerTriangular)

            if !iszero(info)
                @assert info > 0
                if i == 1
                    return LowerTriangular(copy(transpose(A))), info
                end
                info += sum(size(A[Block(l,l)])[1] for l=1:i-1) 
                return LowerTriangular(A), info
            end
    
            _nondiag_chol!(A, i, n, LowerTriangular)
        end
    end

    return LowerTriangular(transpose(A)), 0
end

function cholesky!(A::Symmetric{<:Real,<:AbstractArray}, ::Val{false}=Val(false); check::Bool = true)
    C, info = _block_chol!(A.data, A.uplo == 'U' ? UpperTriangular : LowerTriangular)
    return Cholesky(C.data, A.uplo, info)
end
