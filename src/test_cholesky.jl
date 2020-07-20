using Test, LinearAlgebra

# Generating random positive definite and symmetric matrices
A = BlockArray{Float64}(randn(9,9)+100I, fill(3,3), fill(3,3)); A = Symmetric(A)
B = BlockArray{Float64}(randn(55,55)+100I, 1:10, 1:10); B = Symmetric(B)


A_T = Matrix(A)
B_T = Matrix(B)

@testset begin
    #Tests on A
    @test UpperTriangular(cholesky(A)) ≈ cholesky(A_T).U
    @test UpperTriangular(cholesky(A))'UpperTriangular(cholesky(A)) ≈ A
    
    #Tests on B
    @test UpperTriangular(cholesky(B)) ≈ cholesky(B_T).U
    @test UpperTriangular(cholesky(B))'UpperTriangular(cholesky(B)) ≈ B

end

