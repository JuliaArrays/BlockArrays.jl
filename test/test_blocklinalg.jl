using BlockArrays, ArrayLayouts, LinearAlgebra, Test
import BlockArrays: BlockLayout
import ArrayLayouts: DenseRowMajor, ColumnMajor, StridedLayout

@testset "Linear Algebra" begin
    @testset "BlockArray scalar * matrix" begin
        A = BlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        @test 2A == A*2 == 2Matrix(A)
        @test blockisequal(axes(2A),axes(A))
    end

    @testset "BlockArray matrix * vector" begin
        A = BlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        b = randn(6)
        @test MemoryLayout(A) isa BlockLayout{DenseColumnMajor,DenseColumnMajor}
        V = view(A,Block(2,3))
        @test MemoryLayout(V) isa DenseColumnMajor
        @test strides(V) == (1,2)

        @test V*view(b,4:6) ≈ V*b[4:6] ≈ Matrix(V) * b[4:6]
        @test all(muladd!(1.0,V,view(b,4:6),0.0,similar(b,2)) .=== BLAS.gemv!('N', 1.0, Matrix(V), b[4:6], 0.0, similar(b,2)))

        @test A*b isa PseudoBlockVector
        @test A*BlockVector(b,1:3) isa BlockVector
        @test blockisequal(axes(A*b,1), axes(A,1))
        @test A*b ≈ Matrix(A)*b ≈ A*BlockVector(b,1:3)
        @test all(A*b .=== A*PseudoBlockVector(b,1:3))

        V = view(A, Block.(1:2), Block(3))
        @test MemoryLayout(V) isa BlockLayout{DenseColumnMajor,DenseColumnMajor}
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block(3), Block.(1:2))
        @test MemoryLayout(V) isa BlockLayout{StridedLayout,DenseColumnMajor}
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block.(2:3), Block.(1:2))
        @test MemoryLayout(V) isa BlockLayout{ColumnMajor,DenseColumnMajor}
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        # checks incompatible blocks
        @test A^2 ≈ A*A ≈ Matrix(A)^2
    end

    @testset "PseudoBlockArray matrix * vector" begin
        A = PseudoBlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        b = randn(6)
        @test MemoryLayout(A) isa DenseColumnMajor
        V = view(A,Block(2,3))
        @test MemoryLayout(V) isa ColumnMajor
        @test strides(V) == (1,6)

        @test V*view(b,4:6) ≈ V*b[4:6] ≈ Matrix(V) * b[4:6]
        @test all(muladd!(1.0,V,view(b,4:6),0.0,similar(b,2)) .=== BLAS.gemv!('N', 1.0, Matrix(V), b[4:6], 0.0, similar(b,2)))

        @test A*b isa PseudoBlockVector
        @test blockisequal(axes(A*b,1), axes(A,1))
        @test A*b ≈ Matrix(A)*b ≈ A*BlockVector(b,1:3)
        @test all(A*b .=== A*PseudoBlockVector(b,1:3))

        V = view(A, Block.(1:2), Block(3))
        @test MemoryLayout(V) isa ColumnMajor
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block(3), Block.(1:2))
        @test MemoryLayout(V) isa ColumnMajor
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block.(2:3), Block.(1:2))
        @test MemoryLayout(V) isa ColumnMajor
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        # checks incompatible blocks
        @test A^2 ≈ A*A ≈ Matrix(A)^2
    end

    @testset "matrix * matrix" begin
        A = BlockArray(randn(6,6), fill(2,3), 1:3)
        B = BlockArray(randn(6,3), 1:3, 1:2)

        @test A*B isa BlockMatrix
        @test A*B ≈ Matrix(A)*B ≈ A*Matrix(B) ≈ Matrix(A)*Matrix(B) ≈
                PseudoBlockArray(A)*B ≈ A*PseudoBlockArray(B)

        @test all(PseudoBlockArray(A)*PseudoBlockArray(B) .=== PseudoBlockArray(A)*Matrix(B) .===
                    Matrix(A)*PseudoBlockArray(B) .=== Matrix(A)*Matrix(B))
    end

    @testset "adjoint" begin
        A = BlockArray(randn(6,6), fill(2,3), 1:3)
        B = BlockArray(randn(6,6), 1:3, 1:3)
        C = BlockArray(randn(6,6) + im*randn(6,6), fill(2,3), 1:3)
        b = randn(6)
        c = randn(6) .+ im*randn(6)
        @test MemoryLayout(A') isa BlockLayout{DenseRowMajor,DenseRowMajor}
        @test MemoryLayout(C') isa BlockLayout{DenseRowMajor,ConjLayout{DenseRowMajor}}

        @test view(A', Block(2, 3)) == view(A, Block(3,2))'
        @test view(transpose(A), Block(2, 3)) == transpose(view(A, Block(3,2)))
        @test view(C', Block(2, 3)) == view(C, Block(3,2))'
        @test view(transpose(C), Block(2, 3)) == transpose(view(C, Block(3,2)))

        V = view(A', Block(2,3))
        @test MemoryLayout(V) isa DenseRowMajor
        @test strides(V) == (2,1)
        @test V*b[5:6] ≈ A[Block(3,2)]'b[5:6]
        @test V'*b[3:4] ≈ A[Block(3,2)]*b[3:4]
        @test V*c[5:6] ≈ A[Block(3,2)]'c[5:6]
        @test V'*c[3:4] ≈ A[Block(3,2)]*c[3:4]
        @test all(muladd!(1.0,V,b[5:6],0.0,similar(b,2)) .=== BLAS.gemv!('T', 1.0, Matrix(V'), b[5:6], 0.0, similar(b,2)))
        @test all(muladd!(1.0,V',b[3:4],0.0,similar(b,2)) .=== BLAS.gemv!('N', 1.0, Matrix(V'), b[3:4], 0.0, similar(b,2)))
        @test A'*b ≈ Matrix(A)'*b
        @test A'*c ≈ Matrix(A)'*c
        @test all(transpose(A)*b .=== A'b)
        @test all(transpose(A)*c .=== A'c)

        V = view(C', Block(2,3))
        @test MemoryLayout(V) isa ConjLayout{DenseRowMajor}
        @test strides(V) == (2,1)
        @test V*b[5:6] ≈ C[Block(3,2)]'b[5:6]
        @test V'*b[3:4] ≈ C[Block(3,2)]*b[3:4]
        @test V*c[5:6] ≈ C[Block(3,2)]'c[5:6]
        @test V'*c[3:4] ≈ C[Block(3,2)]*c[3:4]
        @test all(muladd!(1.0+0im,V,c[5:6],0.0+0im,similar(c,2)) .=== BLAS.gemv!('C', 1.0+0im, Matrix(V'), c[5:6], 0.0+0im, similar(c,2)))
        @test all(muladd!(1.0,V',c[3:4],0.0+0im,similar(c,2)) .=== BLAS.gemv!('N', 1.0+0im, Matrix(V'), c[3:4], 0.0+0im, similar(c,2)))
        @test A'*b ≈ Matrix(A)'*b
        @test A'*c ≈ Matrix(A)'*c
        @test all(transpose(A)*b .=== A'b)
        @test all(transpose(A)*c .=== A'c)

        @test A'*B ≈ A'*Matrix(B) ≈ Matrix(A)'*B
        @test B'*A' ≈ Matrix(B)'*A' ≈ B'*Matrix(A)' ≈ Matrix(B')*Matrix(A')
        @test A'*A ≈ Matrix(A)'*Matrix(A)
    end

    @testset "triangular" begin
        A = BlockArray(randn(6,6), 1:3, 1:3)
        B = BlockArray(randn(6,6), fill(2,3), 1:3)
        b = randn(6)
        @test MemoryLayout(UpperTriangular(A)) isa TriangularLayout{'U','N',BlockLayout{DenseColumnMajor,DenseColumnMajor}}
        @test UpperTriangular(A) == UpperTriangular(Matrix(A))
        V = view(A, Block(2,2))
        @test MemoryLayout(UpperTriangular(V)) isa TriangularLayout{'U','N',DenseColumnMajor}
        @test mul(UpperTriangular(V),b[2:3]) ≈ UpperTriangular(V)*b[2:3] ≈ UpperTriangular(Matrix(V))*b[2:3]

        @testset "bug in view pointer" begin
            b2 = PseudoBlockArray(b,(axes(A,1),))
            @test Base.unsafe_convert(Ptr{Float64}, b) == Base.unsafe_convert(Ptr{Float64}, b2) ==
                    Base.unsafe_convert(Ptr{Float64}, view(b2,Block(1)))
        end

        @testset "matching blocks" begin
            @test UpperTriangular(A) * b ≈ UpperTriangular(Matrix(A)) * b
            @test UnitUpperTriangular(A) * b ≈ UnitUpperTriangular(Matrix(A)) * b
            @test LowerTriangular(A) * b ≈ LowerTriangular(Matrix(A)) * b
            @test UnitLowerTriangular(A) * b ≈ UnitLowerTriangular(Matrix(A)) * b

            @test UpperTriangular(A) \ b ≈ UpperTriangular(Matrix(A)) \ b
            @test UnitUpperTriangular(A) \ b ≈ UnitUpperTriangular(Matrix(A)) \ b
            @test LowerTriangular(A) \ b ≈ LowerTriangular(Matrix(A)) \ b
            @test UnitLowerTriangular(A) \ b ≈ UnitLowerTriangular(Matrix(A)) \ b
        end
        @testset "non-matching blocks" begin
            @test UpperTriangular(B) * b ≈ UpperTriangular(Matrix(B)) * b
            @test UnitUpperTriangular(B) * b ≈ UnitUpperTriangular(Matrix(B)) * b
            @test LowerTriangular(B) * b ≈ LowerTriangular(Matrix(B)) * b
            @test UnitLowerTriangular(B) * b ≈ UnitLowerTriangular(Matrix(B)) * b

            @test UpperTriangular(B) \ b ≈ UpperTriangular(Matrix(B)) \ b
            @test UnitUpperTriangular(B) \ b ≈ UnitUpperTriangular(Matrix(B)) \ b
            @test LowerTriangular(B) \ b ≈ LowerTriangular(Matrix(B)) \ b
            @test UnitLowerTriangular(B) \ b ≈ UnitLowerTriangular(Matrix(B)) \ b
        end
    end

    @testset "inv" begin
        A = PseudoBlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        F = factorize(A)
        
        B = randn(6,6)
        @test ldiv!(F, copy(B)) ≈ Matrix(A) \ B
        B̃ = PseudoBlockArray(copy(B),1:3,fill(2,3))
        @test ldiv!(F, B̃) ≈ A\B ≈ Matrix(A) \ B

        @test inv(A) isa PseudoBlockArray
        @test inv(A) ≈ inv(Matrix(A))
        @test inv(A)*A ≈ Matrix(I,6,6)

        A = BlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        @test inv(A) isa BlockArray
        @test inv(A)*A ≈ Matrix(I,6,6)
    end

    @testset "Block Diagonal" begin
        D = mortar(Diagonal([randn(2,2),randn(2,2)]))
        @test MemoryLayout(D) isa BlockLayout{DiagonalLayout{DenseColumnMajor},DenseColumnMajor}
    end

    @testset "adjtrans block view strides" begin
        A = BlockArray(randn(6,6), fill(2,3), 1:3)
        @test strides(view(A', Block(1,2)))  == strides(bview(A', Block(1,2))) == (2,1)
    end

    @testset "mul! with adj" begin
        N = 10000
        M = 10
        A = mortar((randn(N, M), randn(N, M), randn(N, M)))

        X,Y = A',A
        Z = zeros(eltype(X), size(X, 1), size(Y, 2))
        mul!(Z, X, Y)
        @test Z ≈ X*Y

        Z = zeros(eltype(X), size(X, 1), size(Y, 2))
        mul!(Z, copy(X), Y)
        @test Z ≈ X*Y
    end

    @testset "5-arg mul! (#174)" begin
        A = BlockArray(rand(4, 5), [1,3], [2,3])
        Ã = PseudoBlockArray(A)
        B = BlockArray(rand(5, 3), [2,3], [1,1,1])
        B̃ = PseudoBlockArray(B)
        C = randn(4,3)
        @test mul!(view(copy(C),:,1:3), A, B, 1, 2) ≈ A*B + 2C
        @test mul!(view(copy(C),:,1:3), A, B̃, 1, 2) ≈ A*B + 2C
        @test mul!(view(copy(C),:,1:3), Ã, B, 1, 2) ≈ A*B + 2C
        @test mul!(view(copy(C),:,1:3), Ã, B̃, 1, 2) ≈ A*B + 2C
    end
end
