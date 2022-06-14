
getindex(a::Number, ::Block{0}) = a

function _sym_axes(A)
    ax = axes(parent(A),2)
    (ax, ax)
end

# Symmetric and Triangular should inherit blocks from parent
axes(A::HermOrSym{<:Any,<:AbstractBlockMatrix}) = _sym_axes(A)
axes(A::HermOrSym{<:Any,<:SubArray{<:Any,2,<:AbstractBlockMatrix}}) = _sym_axes(A)
axes(A::AbstractTriangular{<:Any,<:AbstractBlockMatrix}) = axes(parent(A))
axes(A::AbstractTriangular{<:Any,<:SubArray{<:Any,2,<:AbstractBlockMatrix}}) = axes(parent(A))
function axes(D::Diagonal{<:Any,<:AbstractBlockVector})
    a = axes(parent(D),1)
    (a,a)
end
ArrayLayouts.diagonallayout(lay::AbstractBlockLayout) = DiagonalLayout{typeof(lay)}()

blocksize(A::AbstractTriangular) = blocksize(parent(A))
blocksize(A::AbstractTriangular, i::Int) = blocksize(parent(A), i)
blockaxes(A::AbstractTriangular) = blockaxes(parent(A))

hasmatchingblocks(A::AbstractTriangular) = hasmatchingblocks(parent(A))
hasmatchingblocks(A::HermOrSym) = true
