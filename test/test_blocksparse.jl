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
end

end # module
