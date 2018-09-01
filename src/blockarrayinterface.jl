
blocksizes(A::AbstractTriangular) = blocksizes(parent(A))


blocksizes(A::Symmetric) = blocksizes(parent(A))
blocksizes(A::Hermitian) = blocksizes(parent(A))

Base.print_matrix_row(io::IO,
        X::Union{AbstractTriangular{<:Any,<:AbstractBlockMatrix},
                 Symmetric{<:Any,<:AbstractBlockMatrix},
                 Hermitian{<:Any,<:AbstractBlockMatrix}}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
