
blocksizes(A) = BlockSizes(vcat.(size(A))...)
getindex(a::Number, ::Block{0}) = a


blocksizes(A::AbstractTriangular) = blocksizes(parent(A))


blocksizes(A::HermOrSym) = blocksizes(parent(A))
blocksizes(A::AdjOrTrans{<:Any,<:AbstractMatrix}) = BlockSizes(reverse(cumulsizes(blocksizes(parent(A)))))
blocksizes(A::AdjOrTrans{<:Any,<:AbstractVector}) = BlockSizes(([1,2],cumulsizes(blocksizes(parent(A)))[1]))


Base.print_matrix_row(io::IO,
        X::Union{AbstractTriangular{<:Any,<:AbstractBlockMatrix},
                 Symmetric{<:Any,<:AbstractBlockMatrix},
                 Hermitian{<:Any,<:AbstractBlockMatrix}}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
