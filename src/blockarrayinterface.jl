
blocksizes(A) = BlockSizes(vcat.(size(A))...)
getindex(a::Number, ::Block{0}) = a


blocksizes(A::AbstractTriangular) = blocksizes(parent(A))


blocksizes(A::HermOrSym) = blocksizes(parent(A))
blocksizes(A::AdjOrTrans{<:Any,<:AbstractMatrix}) = BlockSizes(reverse(cumulsizes(blocksizes(parent(A)))))
blocksizes(A::AdjOrTrans{<:Any,<:AbstractVector}) = BlockSizes(([1,2],cumulsizes(blocksizes(parent(A)))[1]))

function sizes_from_blocks(A::Tridiagonal{<:AbstractMatrix})
    sz = (size.(A.d, 1), size.(A.d,2))
    for k = 1:length(A.du)
        size(A.du[k],1) == sz[1][k] || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
        size(A.du[k],2) == sz[2][k+1] || throw(ArgumentError("block sizes of upper diagonal inconsisent with diagonal"))
        size(A.dl[k],1) == sz[1][k+1] || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
        size(A.dl[k],2) == sz[2][k] || throw(ArgumentError("block sizes of lower diagonal inconsisent with diagonal"))
    end
    sz
end


Base.print_matrix_row(io::IO,
        X::Union{AbstractTriangular{<:Any,<:AbstractBlockMatrix},
                 Symmetric{<:Any,<:AbstractBlockMatrix},
                 Hermitian{<:Any,<:AbstractBlockMatrix}}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
