
getindex(a::Number, ::Block{0}) = a

axes(A::AbstractTriangular{<:Any,<:AbstractBlockMatrix}) = axes(parent(A))
axes(A::HermOrSym{<:Any,<:AbstractBlockMatrix}) = axes(parent(A))
