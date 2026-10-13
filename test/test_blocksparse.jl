module TestBlockArraysSparseArrays

using BlockArrays, LinearAlgebra, SparseArrays, Test

@testset "sparse" begin
    M = sparse([4.0 1 0 0 0; 1 4 1 0 0; 0 1 4 1 0; 0 0 1 4 1; 2 0 0 1 4])

    @testset "block structure is preserved" begin
        for A in (BlockArray(M, [2,3], [1,4]), BlockedArray(Matrix(M), [2,3], [1,4]), BlockedArray(M, [2,3], [1,4]))
            S = sparse(A)
            @test S isa BlockedMatrix{Float64,<:SparseMatrixCSC}
            @test S == M
            @test blockisequal(axes(S), axes(A))
            @test nnz(S.blocks) == nnz(M)
        end

        B = BlockedArray(M, [2,3], [1,4])
        @test sparse(B).blocks !== B.blocks

        v = BlockArray([1.0, 0, 2, 0, 0], [2,3])
        s = sparse(v)
        @test s isa BlockedVector{Float64,<:SparseVector}
        @test s == v
        @test blockisequal(axes(s), axes(v))
        @test nnz(s.blocks) == 2

        @test SparseMatrixCSC(BlockArray(M, [2,3], [1,4])) isa SparseMatrixCSC
    end

    @testset "linear algebra uses sparse storage" begin
        S = sparse(BlockArray(M, [2,3], [2,3]))
        b = collect(1.0:5)
        X = [b reverse(b)]

        @test lu(S) isa SparseArrays.UMFPACK.UmfpackLU
        @test factorize(S) isa SparseArrays.UMFPACK.UmfpackLU
        @test qr(S) isa SparseArrays.SPQR.QRSparse

        for c in (b, BlockedArray(b, (axes(S,1),)), X)
            x = S \ c
            @test x ≈ Matrix(M) \ c
            @test blockisequal(axes(x,1), axes(S,2))
        end

        @test S * b ≈ M * b
        @test blockisequal(axes(S * b), (axes(S,1),))
        @test S * X ≈ M * X
        @test X' * S ≈ X' * M
        @test blockisequal(axes(X' * S, 2), axes(S,2))

        for (P, Q) in ((S, S), (S, M), (M, S))
            PQ = P * Q
            @test PQ isa BlockedMatrix{Float64,<:SparseMatrixCSC}
            @test PQ ≈ M * M
            @test blockisequal(axes(PQ), (axes(P,1), axes(Q,2)))
        end
    end

    @testset "Adjoint, Transpose, Symmetric and Hermitian" begin
        S = sparse(BlockArray(M, [2,3], [2,3]))
        b = collect(1.0:5)
        X = [b reverse(b)]
        for (W, Wm) in ((S', M'), (transpose(S), transpose(M)), (Symmetric(S), Symmetric(M)),
                        (Hermitian(S), Hermitian(M)), (Symmetric(S, :L), Symmetric(M, :L)))
            @test lu(W) isa SparseArrays.UMFPACK.UmfpackLU
            @test qr(W) isa SparseArrays.SPQR.QRSparse
            @test lu(W) \ b ≈ Wm \ b

            for c in (b, BlockedArray(b, (axes(S,1),)), X)
                x = W \ c
                @test x ≈ Wm \ Array(c)
                @test blockisequal(axes(x,1), axes(W,2))
            end

            Wb = W * b
            @test Wb ≈ Wm * b
            @test blockisequal(axes(Wb), (axes(W,1),))
            @test W * X ≈ Wm * X
            @test X' * W ≈ X' * Wm
            for (P, Q, Pm, Qm) in ((W, S, Wm, M), (S, W, M, Wm), (W, W, Wm, Wm), (W, M, Wm, M), (M, W, M, Wm))
                PQ = P * Q
                @test PQ isa BlockedMatrix{Float64,<:SparseMatrixCSC}
                @test PQ ≈ Pm * Qm
                @test blockisequal(axes(PQ), (axes(P,1), axes(Q,2)))
            end
        end
        for W in (Symmetric(S), Hermitian(S))
            @test cholesky(W) isa SparseArrays.CHOLMOD.Factor
            @test ldlt(W) isa SparseArrays.CHOLMOD.Factor
            @test factorize(W) isa SparseArrays.CHOLMOD.Factor
        end
    end

    @testset "block indexing preserves sparsity" begin
        A = BlockArray(M, [2,2,1], [1,3,1])
        D = BlockedArray(Matrix(M), axes(A))
        inds = ((Block.(1:2), Block.(1:2)), (Block.(2:3), Block(2)), (Block(2), Block.(1:2)),
                (Block.(1:2), :), (:, Block.(2:3)), ([Block(3), Block(1)], Block.(1:2)))
        for I in inds
            r = sparse(A)[I...]
            @test r isa BlockedMatrix{Float64,<:SparseMatrixCSC}
            @test r == D[I...]
            @test blockisequal(axes(r), axes(D[I...]))

            r = A[I...]
            @test r isa BlockMatrix{Float64,<:AbstractMatrix{<:SparseMatrixCSC}}
            @test r == D[I...]
            @test blockisequal(axes(r), axes(D[I...]))
        end
        for I in ((1:3, Block.(1:2)), (Block(1)[1:1], Block.(1:2)))
            r = sparse(A)[I...]
            @test r isa BlockedMatrix{Float64,<:SparseMatrixCSC}
            @test r == D[I...]
        end

        v = mortar([sparsevec([1.0, 0]), sparsevec([0.0, 2, 0])])
        for I in (Block.(1:2), [Block(2), Block(1)])
            @test v[I] isa BlockVector{Float64,<:AbstractVector{<:SparseVector}}
            @test v[I] == Vector(v)[I isa BlockRange ? (1:5) : [3,4,5,1,2]]
            @test sparse(v)[I] isa BlockedVector{Float64,<:SparseVector}
            @test sparse(v)[I] == v[I]
        end
    end
end

end # module
