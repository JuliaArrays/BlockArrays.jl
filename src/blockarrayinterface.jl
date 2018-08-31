
blocksizes(A::AbstractTriangular) = blocksizes(parent(A))


blocksizes(A::Symmetric) = blocksizes(parent(A))
blocksizes(A::Hermitian) = blocksizes(parent(A))
