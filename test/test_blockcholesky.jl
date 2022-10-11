using BlockArrays, Test, LinearAlgebra, Random


Random.seed!(0)

@testset "Block cholesky" begin

    # Generating random positive definite and symmetric matrices
    A = BlockArray{Float32}(rand(9,9)+100I, fill(3,3), fill(3,3)); A = Symmetric(A)
    B = BlockArray{Float32}(rand(55,55)+100I, 1:10, 1:10); B = Symmetric(B)
    C = BlockArray{Float32}(rand(9,9)+100I, fill(3,3), fill(3,3)); C = Symmetric(C, :L)
    D = BlockArray{Float32}(rand(55,55)+100I, 1:10, 1:10); D = Symmetric(D, :L)
    E = BlockArray{Float32}(rand(9,9)+100I, fill(3,3), fill(3,3)); E = Symmetric(E)
    D1 = copy(D); D1[1,1] = 0
    D2 = copy(D); D2[2,2] = 0
    E2 = copy(E); E2[2,2] = 0
    E5 = copy(E); E5[5,5] = 0
    E8 = copy(E); E8[8,8] = 0
    nsym = BlockArray{Float32}(randn(6,8), fill(2,3), fill(2,4))

    A_T = Matrix(A)
    B_T = Matrix(B)
    C_T = Matrix(C)
    D_T = Matrix(D)

    #Test on nonsymmetric matrix
    if VERSION < v"1.8-"
        @test_throws MethodError cholesky(nsym)
    else
        @test_throws DimensionMismatch cholesky(nsym)
    end

    #Tests on A
    @test cholesky(A).U ≈ cholesky(A_T).U
    @test cholesky(A).U'cholesky(A).U ≈ A

    #Tests on B
    @test cholesky(B).U ≈ cholesky(B_T).U
    @test cholesky(B).U'cholesky(B).U ≈ B

    #Tests on C
    @test cholesky(C).L ≈ cholesky(C_T).L
    @test cholesky(C).L*cholesky(C).L' ≈ C

    #Tests on D
    @test cholesky(D).L ≈ cholesky(D_T).L
    @test cholesky(D).L*cholesky(D).L' ≈ D

    #Tests on non-PD matrices
    @test_throws PosDefException cholesky(D1)
    @test_throws PosDefException cholesky(D2)
    @test_throws PosDefException cholesky(E2)
    @test_throws PosDefException cholesky(E5)
    @test_throws PosDefException cholesky(E8)

    @test cholesky(D1; check=false).info == 1
    @test cholesky(D2; check=false).info == 2
    @test cholesky(E2; check=false).info == 2
    @test cholesky(E5; check=false).info == 5
    @test cholesky(E8; check=false).info == 8
end

