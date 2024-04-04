using BlockArrays, LinearAlgebra, FillArrays, Test, ArrayLayouts

# avoid fast-paths for view
bview(a, b) = Base.invoke(view, Tuple{AbstractArray,Any}, a, b)

@testset "missing fallback block axes" begin
    @test_throws ArgumentError invoke(axes, Tuple{AbstractBlockArray}, PseudoBlockArray{ComplexF64}(undef, (1:4), (2:5)))
end

@testset "Array block interface" begin
    @test 1[Block()] == 1

    A = randn(5)
    @test blocksize(A) == (1,)
    @test blocksize(A, 1) == 1
    @test blocksizes(A) == ([5],)
    @test blocksizes(A, 1) == [5]
    @test A[Block(1)] == A
    view(A, Block(1))[1] = 2
    @test A[1] == 2
    @test_throws BlockBoundsError A[Block(2)]

    A = randn(5, 5)
    @test A[Block(1, 1)] == A
    @test A[BlockIndex((1,1), (1,2))] == A[1,2]
    @test_throws BoundsError A[BlockIndex((1,1), (1,6))]

    @test similar(BlockVector{Float64}, Base.OneTo(5)) isa Vector{Float64}
    @test similar(BlockVector{Float64}, 5) isa Vector{Float64}
    @test similar(BlockVector{Float64}, (5,)) isa Vector{Float64}
end

@testset "Triangular/Symmetric/Hermitian block arrays" begin
    @testset "square blocks" begin
        A = PseudoBlockArray{ComplexF64}(undef, 1:4, 1:4)
        A .= reshape(1:length(A), size(A))
        U = UpperTriangular(A)
        S = Symmetric(A)
        H = Hermitian(A)

        @test blocksize(U) == blocksize(S) == blocksize(A)
        @test blockaxes(U) == blockaxes(S) == blockaxes(A)

        @test U[Block(2, 2)] == UpperTriangular(A[2:3, 2:3])
        @test U[Block(2, 3)] == A[2:3, 4:6]
        @test U[Block(3, 2)] == zeros(3, 2)
        @test S[Block(2, 2)] == Symmetric(A[2:3, 2:3])
        @test S[Block(2, 3)] == A[2:3, 4:6]
        @test S[Block(3, 2)] == transpose(A[2:3, 4:6])
        @test H[Block(2, 2)] == Hermitian(A[2:3, 2:3])
        @test H[Block(2, 3)] == A[2:3, 4:6]
        @test H[Block(3, 2)] == A[2:3, 4:6]'

        V = view(A, Block.(1:2), Block.(1:2))
        @test blockisequal(axes(Symmetric(V)), axes(view(A, Block.(1:2), Block.(1:2))))

        A = PseudoBlockArray{Int}(reshape([1:9;],3,3), 1:2, 1:2)
        B = UpperTriangular(A)
        str = sprint(show, "text/plain", B)
        @test str == "$(summary(B)):\n 1  │  4  7\n ───┼──────\n ⋅  │  5  8\n ⋅  │  ⋅  9"
    end

    @testset "rect blocks" begin
        A = PseudoBlockArray{ComplexF64}(undef, 1:3, fill(3, 2))
        A .= randn(6, 6) .+ im * randn(6, 6)
        U = UpperTriangular(A)
        S = Symmetric(A)
        H = Hermitian(A)

        @test blockisequal(axes(S), (axes(A, 2), axes(A, 2)))
        @test blockisequal(axes(U), axes(A))
        @test blocksize(S) == (blocksize(S, 1), blocksize(S, 2)) == (2, 2)
        @test blocksize(U) == (blocksize(U, 1), blocksize(U, 2)) == blocksize(A)
        @test blockaxes(S) == (blockaxes(S, 1), blockaxes(S, 2)) == (Block.(1:2), Block.(1:2))
        @test blockaxes(U) == (blockaxes(U, 1), blockaxes(U, 2)) == blockaxes(A)

        @test U[Block(2, 2)] == A[Block(2, 2)]
        @test U[Block(3, 2)] == triu(A[Block(3, 2)])
        @test U[Block(3, 1)] == zeros(3, 3)
        @test S[Block(2, 2)] == Symmetric(A[4:6, 4:6])
        @test S[Block(1, 2)] == A[1:3, 4:6]
        @test S[Block(2, 1)] == transpose(A[1:3, 4:6])
        @test H[Block(2, 2)] == Hermitian(A[4:6, 4:6])
        @test H[Block(1, 2)] == A[1:3, 4:6]
        @test H[Block(2, 1)] == A[1:3, 4:6]'

        @test !BlockArrays.hasmatchingblocks(U)
        @test BlockArrays.hasmatchingblocks(S)
        @test BlockArrays.hasmatchingblocks(H)
    end

    @testset "getindex ambiguity" begin
        A = PseudoBlockArray{ComplexF64}(undef, 1:4, 1:4)
        A .= reshape(1:length(A), size(A)) .+ im
        S = Symmetric(A)
        H = Hermitian(A)

        @test S[Block.(1:3), Block.(1:3)] == Symmetric(A[Block.(1:3), Block.(1:3)])
        @test H[Block.(1:3), Block.(1:3)] == Hermitian(A[Block.(1:3), Block.(1:3)])
        @test S[Block.(1:3), Block(3)] == S[1:6, 4:6]
        @test H[Block.(1:3), Block(3)] == H[1:6, 4:6]
        @test S[Block(3), Block.(1:3)] == S[4:6, 1:6]
        @test H[Block(3), Block.(1:3)] == H[4:6, 1:6]
    end
end

@testset "Adjoint/Transpose block arrays" begin
    A = PseudoBlockArray{ComplexF64}(undef, (1:4), (2:5))
    A .= randn.() .+ randn.() .* im

    @test blocksize(A') == (4, 4)
    @test blocksize(Transpose(A)) == (4, 4)

    @test A'[Block(2, 2)] == A[Block(2, 2)]' == A[2:3, 3:5]'
    @test transpose(A)[Block(2, 2)] == transpose(A[2:3, 3:5])
    @test A'[Block(2, 3)] == A[Block(3, 2)]'
    @test transpose(A)[Block(2, 3)] == transpose(A[Block(3, 2)])

    @test BlockArray(A') == A'
    @test BlockArray(transpose(A)) == transpose(A)

    @test A'[Block.(1:2), Block.(1:3)] == A[Block.(1:3), Block.(1:2)]'
    @test transpose(A)[Block.(1:2), Block.(1:3)] == transpose(A[Block.(1:3), Block.(1:2)])

    @test A'[Block.(1:2), Block(1)] == A[Block(1), Block.(1:2)]'
    @test A'[Block.(1), Block.(1:3)] == A[Block.(1:3), Block.(1)]'
end

@testset "Diagonal BlockArray" begin
    A = mortar(Diagonal(fill([1 2], 2)))
    @test A isa BlockMatrix{Int,Diagonal{Matrix{Int},Vector{Matrix{Int}}}}
    @test A[Block(1, 2)] == [0 0]
    @test_throws BlockBoundsError A[Block(1, 3)]
    @test A == [1 2 0 0; 0 0 1 2]
    @test BlockArray(A) == A
    @test sprint(show, "text/plain", A) == "$(summary(A)):\n 1  2  │  ⋅  ⋅\n ──────┼──────\n ⋅  ⋅  │  1  2"

    N = 3
    D = Diagonal(mortar(Fill.(-(0:N) - (0:N) .^ 2, 1:2:2N+1)))
    @test axes(D) isa NTuple{2,BlockedOneTo}
    @test blockisequal(axes(D, 1), axes(parent(D), 1))
    @test D == Diagonal(Vector(parent(D)))
    @test MemoryLayout(D) isa BlockArrays.DiagonalLayout{<:BlockArrays.BlockLayout}
end

@testset "non-standard block axes" begin
    A = BlockArray([1 2; 3 4], Fill(1, 2), Fill(1, 2))
    @test A isa BlockMatrix{Int,Matrix{Matrix{Int}},<:NTuple{2,BlockedOneTo{<:AbstractRange}}}
    A = BlockArray([1 2; 3 4], Fill(1, 2), [1, 1])
    @test A isa BlockMatrix{Int,Matrix{Matrix{Int}},<:Tuple{BlockedOneTo{<:AbstractRange},BlockedOneTo{Vector{Int}}}}
end

@testset "block Fill" begin
    A = Fill(2, (blockedrange([1, 2, 2]),))
    @test A[Block(1)] ≡ view(A, Block(1)) ≡ Fill(2, 1)
    @test A[Block.(1:2)] == [2, 2, 2]
    @test A[Block.(1:2)] isa Fill
    @test view(A, Block.(1:2)) isa Fill
    @test 2A ≡ Fill(4, axes(A))

    F = Fill(2, (blockedrange([1, 2, 2]), blockedrange(1:3)))
    @test F[Block(2, 2)] ≡ view(F, Block(2, 2)) ≡ view(F, Block(2), Block(2)) ≡ F[Block(2), Block(2)] ≡ Fill(2, 2, 2)
    @test F[Block(2), 1:5] ≡ view(F, Block(2), 1:5) ≡ Fill(2, 2, 5)
    @test F[1:5, Block(2)] ≡ view(F, 1:5, Block(2)) ≡ Fill(2, 5, 2)
    @test F[:, Block(2)] ≡ Fill(2, (axes(F, 1), Base.OneTo(2)))
    @test F[Block(2), :] ≡ Fill(2, (Base.OneTo(2), axes(F, 2)))
    @test F[Block.(1:2), Block.(1:2)] == Fill(2, (blockedrange([1, 2]), blockedrange(1:2)))

    O = Ones{Int}((blockedrange([1, 2, 2]), blockedrange(1:3)))
    @test O[Block(2, 2)] ≡ O[Block(2), Block(2)] ≡ Ones{Int}(2, 2)
    @test O[Block(2), 1:5] ≡ Ones{Int}(2, 5)
    @test O[1:5, Block(2)] ≡ Ones{Int}(5, 2)
    @test O[:, Block(2)] ≡ Ones{Int}((axes(O, 1), Base.OneTo(2)))
    @test O[Block(2), :] ≡ Ones{Int}((Base.OneTo(2), axes(O, 2)))
    @test O[Block.(1:2), Block.(1:2)] == Ones{Int}((blockedrange([1, 2]), blockedrange(1:2)))

    Z = Zeros{Int}((blockedrange([1, 2, 2]), blockedrange(1:3)))
    @test Z[Block(2, 2)] ≡ Z[Block(2), Block(2)] ≡ Zeros{Int}(2, 2)
    @test Z[Block(2), 1:5] ≡ Zeros{Int}(2, 5)
    @test Z[1:5, Block(2)] ≡ Zeros{Int}(5, 2)
    @test Z[:, Block(2)] ≡ Zeros{Int}((axes(Z, 1), Base.OneTo(2)))
    @test Z[Block(2), :] ≡ Zeros{Int}((Base.OneTo(2), axes(Z, 2)))
    @test Z[Block.(1:2), Block.(1:2)] == Zeros{Int}((blockedrange([1, 2]), blockedrange(1:2)))

    B = Eye((blockedrange([1, 2]),))
    @test B[Block(2, 2)] == Matrix(I, 2, 2)

    C = Eye((blockedrange([1, 2, 2]), blockedrange([2, 2])))
    @test C[Block(2, 2)] == [0 0; 1.0 0]

    U = UpperTriangular(Ones((blockedrange([1, 2]), blockedrange([2, 1]))))

    @test sprint(show, "text/plain", A) == "$(summary(A)), with entries equal to 2"
    @test sprint(show, "text/plain", B) == summary(B)
    @test sprint(show, "text/plain", U) == "$(summary(U)):\n 1.0  1.0  │  1.0\n ──────────┼─────\n  ⋅   1.0  │  1.0\n  ⋅    ⋅   │  1.0"

    @testset "views" begin
        # This in theory can be dropped because `view` returns the block, but we keep in case needed
        a = BlockArray(randn(6), 1:3)
        fill!(bview(a, Block(2)), 2)
        @test view(a, Block(2)) == [2, 2]
        f = mortar([Fill(1, 2), Fill(2, 3)])
        @test FillArrays.getindex_value(bview(f, Block(2))) == 2
    end
end
