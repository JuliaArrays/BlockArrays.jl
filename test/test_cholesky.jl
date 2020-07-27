using BlockArrays, Test, LinearAlgebra



@testset "Block cholesky" begin

    # Generating random positive definite and symmetric matrices
    A = BlockArray{Float32}(randn(9,9)+100I, fill(3,3), fill(3,3)); A = Symmetric(A)
    B = BlockArray{Float32}(randn(55,55)+100I, 1:10, 1:10); B = Symmetric(B)
    C = BlockArray{Float32}(randn(9,9)+100I, fill(3,3), fill(3,3)); C = Symmetric(C, :L)
    D = BlockArray{Float32}(randn(55,55)+100I, 1:10, 1:10); D = Symmetric(D, :L)
    E = BlockArray{Float32}(randn(9,9)+100I, fill(3,3), fill(3,3)); E = Symmetric(E)
    E2 = copy(E); E2[2,2] = 0
    E5 = copy(E); E5[5,5] = 0
    E8 = copy(E); E8[8,8] = 0
    nsym = BlockArray{Float32}(randn(6,8), fill(2,3), fill(2,4))

    A_T = Matrix(A)
    B_T = Matrix(B)
    C_T = Matrix(C)
    D_T = Matrix(D)

    #Test on nonsymmetric matrix
    @test_throws MethodError cholesky(nsym)

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
    @test cholesky(E2).info == 2
    @test cholesky(E5).info == 5
    @test cholesky(E8).info == 8

end

