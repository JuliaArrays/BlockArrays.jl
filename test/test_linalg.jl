using BlockArrays, ArrayLayouts, LinearAlgebra, Test
import BlockArrays: BlockLayout
import ArrayLayouts: DenseRowMajor

@testset "Linear Algebra" begin
    @testset "BlockArray matrix * vector" begin
        A = BlockArray{Float64}(randn(6,6), fill(2,3), 1:3)
        b = randn(6)
        @test MemoryLayout(A) isa BlockLayout{DenseColumnMajor}
        V = view(A,Block(2,3))
        @test MemoryLayout(V) isa DenseColumnMajor
        @test strides(V) == (1,2)

        @test all(V*view(b,4:6) .=== V*b[4:6] .=== Matrix(V) * b[4:6])

        @test A*b isa PseudoBlockVector
        @test A*BlockVector(b,1:3) isa BlockVector
        @test blockisequal(axes(A*b,1), axes(A,1))
        @test A*b ≈ Matrix(A)*b ≈ A*BlockVector(b,1:3)
        @test all(A*b .=== A*PseudoBlockVector(b,1:3))

        V = view(A, Block.(1:2), Block(3))
        @test MemoryLayout(V) isa BlockLayout{DenseColumnMajor}
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block(3), Block.(1:2))
        @test MemoryLayout(V) isa BlockLayout{DenseColumnMajor}
        @test all(V*view(b,4:6) .=== V*b[4:6])
        @test V*b[4:6] ≈ Matrix(V)*b[4:6]

        V = view(A, Block.(2:3), Block.(1:2))
        @test MemoryLayout(V) isa BlockLayout{DenseColumnMajor}
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

        @test all(V*view(b,4:6) .=== V*b[4:6] .=== Matrix(V) * b[4:6])

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
        @test MemoryLayout(A') isa BlockLayout{DenseRowMajor}

        V = view(A', Block(2,3))
        @test MemoryLayout(V) isa DenseRowMajor
        @test V*b[5:6] == A[Block(3,2)]'b[5:6]
        @test V'*b[3:4] == A[Block(3,2)]*b[3:4]
        @test A'*b ≈ Matrix(A)'*b
        @test all(transpose(A)*b .=== A'b)
        
        @test A'*B ≈ A'*Matrix(B) ≈ Matrix(A)'*B
        @test B'*A' ≈ Matrix(B)'*A' ≈ B'*Matrix(A)' ≈ Matrix(B')*Matrix(A')
        @test A'*A ≈ Matrix(A)'*Matrix(A)
    end

    @testset "triangular" begin
        A = BlockArray(randn(6,6), 1:3, 1:3) 
        b = randn(6)
        @test MemoryLayout(UpperTriangular(A)) isa TriangularLayout{'U','N',BlockLayout{DenseColumnMajor}}
        @test UpperTriangular(A) == UpperTriangular(Matrix(A))
        V = view(A, Block(2,2))
        @test MemoryLayout(UpperTriangular(V)) isa TriangularLayout{'U','N',DenseColumnMajor}
        @test mul(UpperTriangular(V),b[2:3]) ≈ UpperTriangular(V)*b[2:3] ≈ UpperTriangular(Matrix(V))*b[2:3]

        b2 = PseudoBlockArray(b,(axes(A,1),))
        @test Base.unsafe_convert(Ptr{Float64}, b) == Base.unsafe_convert(Ptr{Float64}, b2) == Base.unsafe_convert(Ptr{Float64}, view(b2,Block(1)))
        @test UpperTriangular(A) * b ≈ UpperTriangular(Matrix(A)) * b
    end
end


