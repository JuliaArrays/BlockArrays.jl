using BlockArrays, Test, LinearAlgebra



@testset "Block cholesky" begin

    # Generating random positive definite and symmetric matrices
    A = BlockArray{Float64}(randn(9,9)+100I, fill(3,3), fill(3,3)); A = Symmetric(A)
    B = BlockArray{Float64}(randn(55,55)+100I, 1:10, 1:10); B = Symmetric(B)
    C = BlockArray{Float64}(randn(9,9)+100I, fill(3,3), fill(3,3)); C = Symmetric(C, :L)
    D = BlockArray{Float64}(randn(55,55)+100I, 1:10, 1:10); D = Symmetric(D, :L)

    A_T = Matrix(A)
    B_T = Matrix(B)
    C_T = Matrix(C)
    D_T = Matrix(D)

    #Tests on A
    @test cholesky(A).U ≈ cholesky(A_T).U
    @test cholesky(A).U'cholesky(A).U ≈ A
    
    #Tests on B
    @test cholesky(B).U ≈ cholesky(B_T).U
    @test cholesky(B).U'cholesky(B).U ≈ B

    #Tests on C
    @test cholesky(C).L ≈ cholesky(C_T).L
    @test cholesky(C).L*cholesky(C).L' ≈ C

    #tests on D
    @test cholesky(D).L ≈ cholesky(D_T).L
    @test cholesky(D).L*cholesky(D).L' ≈ D

end

