
blocksizes(A) = BlockSizes(vcat.(size(A))...)
getindex(a::Number, ::Block{0}) = a

axes(A::AbstractTriangular{<:Any,<:AbstractBlockMatrix}) = axes(parent(A))
axes(A::HermOrSym{<:Any,<:AbstractBlockMatrix}) = axes(parent(A))

Base.print_matrix_row(io::IO,
        X::Union{AbstractTriangular{<:Any,<:AbstractBlockMatrix},
                 Symmetric{<:Any,<:AbstractBlockMatrix},
                 Hermitian{<:Any,<:AbstractBlockMatrix},
                 Adjoint{<:Any,<:AbstractBlockMatrix},
                 Transpose{<:Any,<:AbstractBlockMatrix}}, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
