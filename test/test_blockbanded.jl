module TestBlockArraysBandedMatrices

using BlockArrays, LinearAlgebra, BandedMatrices, FillArrays, Test
using BlockArrays: BlockDiagonal, BlockBidiagonal, BlockTridiagonal, blockcolsupport, blockrowsupport, BlockLayout
using BandedMatrices: _BandedMatrix


@testset "Block-Banded" begin
    @testset "Block Diagonal" begin
        A = BlockDiagonal(fill([1 2],3))
        @test A[Block(1,1)] == [1 2]
        @test @inferred(A[Block(1,2)]) == [0 0]
        @test_throws DimensionMismatch A+I
        A = BlockDiagonal(fill([1 2; 1 2],3))
        @test A+I == I+A == mortar(Diagonal(fill([2 2; 1 3],3))) == Matrix(A) + I
    end

    @testset "Block Bidiagonal" begin
        Bu = BlockBidiagonal(fill([1 2],4), fill([3 4],3), :U)
        Bl = BlockBidiagonal(fill([1 2],4), fill([3 4],3), :L)
        @test Bu[Block(1,1)] == Bl[Block(1,1)] == [1 2]
        @test @inferred(Bu[Block(1,2)]) == @inferred(Bl[Block(2,1)]) == [3 4]
        @test @inferred(view(Bu,Block(1,3))) == @inferred(Bu[Block(1,3)]) == [0 0]
        @test_throws DimensionMismatch Bu+I
        Bu = BlockBidiagonal(fill([1 2; 1 2],4), fill([3 4; 3 4],3), :U)
        Bl = BlockBidiagonal(fill([1 2; 1 2],4), fill([3 4; 3 4],3), :L)
        @test Bu+I == I+Bu == mortar(Bidiagonal(fill([2 2; 1 3],4), fill([3 4; 3 4],3), :U)) == Matrix(Bu) + I
        @test Bl+I == I+Bl == mortar(Bidiagonal(fill([2 2; 1 3],4), fill([3 4; 3 4],3), :L)) == Matrix(Bl) + I
        @test Bu-I == mortar(Bidiagonal(fill([0 2; 1 1],4), fill([3 4; 3 4],3), :U)) == Matrix(Bu) - I
        @test I-Bu == mortar(Bidiagonal(fill([0 -2; -1 -1],4), fill(-[3 4; 3 4],3), :U)) == I - Matrix(Bu)
    end

    @testset "Block Tridiagonal" begin
        A = BlockTridiagonal(fill([1 2],3), fill([3 4],4), fill([4 5],3))
        @test A[Block(1,1)] == [3 4]
        @test @inferred(A[Block(1,2)]) == [4 5]
        @test @inferred(view(A,Block(1,3))) == @inferred(A[Block(1,3)]) == [0 0]
        @test_throws DimensionMismatch A+I
        A = BlockTridiagonal(fill([1 2; 1 2],3), fill([3 4; 3 4],4), fill([4 5; 4 5],3))
        @test A+I == I+A == mortar(Tridiagonal(fill([1 2; 1 2],3), fill([4 4; 3 5],4), fill([4 5; 4 5],3))) == Matrix(A) + I
        @test A-I == mortar(Tridiagonal(fill([1 2; 1 2],3), fill([2 4; 3 3],4), fill([4 5; 4 5],3))) == Matrix(A) - I
        @test I-A == mortar(Tridiagonal(fill(-[1 2; 1 2],3), fill([-2 -4; -3 -3],4), fill(-[4 5; 4 5],3))) == I - Matrix(A)
    end


    @testset "Block-BandedMatrix" begin
        a = blockedrange(1:5)
        B = _BandedMatrix(BlockedArray(randn(5,length(a)),(Base.OneTo(5),a)), a, 3, 1)
        @test blockcolsupport(B,Block(1)) == Block.(1:3)
        @test blockcolsupport(B,Block(3)) == Block.(2:4)
        @test blockrowsupport(B,Block(1)) == Block.(1:2)
        @test blockrowsupport(B,Block(4)) == Block.(3:5)

        Q = Eye((a,))[:,Block(2)]
        @test Q isa BandedMatrix
        @test blockcolsupport(Q,Block(1)) == Block.(2:2)

        Q = Eye((a,))[Block(2),:]
        @test Q isa BandedMatrix
        @test blockrowsupport(Q,Block(1)) == Block.(2:2)

        @testset "constant blocks" begin
            a = blockedrange(Fill(2,5))
            Q = Eye((a,))[:,Block(2)]
            @test Q isa BandedMatrix
        end

        @testset "empty support" begin
            # blocks outside blockcolsupport/blockrowsupport must be zero
            function test_blocksupport(A)
                for J in blockaxes(A,2)[1], K in blockaxes(A,1)[1]
                    K in blockcolsupport(A,J) || @test iszero(A[K,J])
                    J in blockrowsupport(A,K) || @test iszero(A[K,J])
                end
            end

            # strictly upper triangular: first column and last row are zero
            b = blockedrange(1:3)
            B = _BandedMatrix(BlockedArray(randn(1,length(b)),(Base.OneTo(1),b)), b, -1, 1)
            @test @inferred(blockcolsupport(B,Block(1))) == Block.(1:0)
            @test blockcolsupport(B,Block(2)) == Block.(1:2)

            B = BlockedMatrix(BandedMatrix(1 => 1:5), [3,2,1], [1,2,3])
            @test @inferred(blockcolsupport(B,Block(1))) == Block.(1:0)
            @test @inferred(blockrowsupport(B,Block(3))) == Block.(1:0)
            @test [blockcolsupport(B,J) for J in Block.(1:3)] == [Block.(1:0), Block.(1:1), Block.(1:2)]
            @test [blockrowsupport(B,K) for K in Block.(1:3)] == [Block.(2:3), Block.(3:3), Block.(1:0)]
            test_blocksupport(B)

            # columns/rows beyond the band of a rectangular matrix are zero
            W = BlockedMatrix(BandedMatrix((0 => 1:2,), (2,5)), [1,1], [2,3])
            @test blockcolsupport(W,Block(1)) == Block.(1:2)
            @test blockcolsupport(W,Block(2)) == Block.(1:0)
            test_blocksupport(W)

            T = BlockedMatrix(BandedMatrix((0 => 1:2,), (5,2)), [2,3], [1,1])
            @test blockrowsupport(T,Block(1)) == Block.(1:2)
            @test blockrowsupport(T,Block(2)) == Block.(1:0)
            test_blocksupport(T)
        end
    end

    @testset "Banded BlockedMatrix" begin
        A = BlockedArray(brand(5,4,1,2), [3,2], [2,2])
        @test bandwidths(A) == (1,2)
        @test BandedMatrix(A) == A
        @test copyto!(similar(A), A) == A
    end

    @testset "block banded" begin
        B = BandedMatrix{Matrix{Float64}}(undef, (3, 4), (1,2))
        for k = axes(B,1), j = max(1,k-1):min(4,k+2)
            B[k,j] = randn(2,2)
        end
        A = BlockArrays._BlockArray(B, (blockedrange(fill(2,3)), blockedrange(fill(2,4))))
        @test copyto!(zeros(size(A)), A) == Matrix(A)
    end

    @testset "Blocked Diagonal" begin
        A = BlockedMatrix(Diagonal(1:5), [2,3], [2,2,1])
        if isdefined(FillArrays, :OffDiagonal)
            @test A[Block(2,2)] isa FillArrays.OffDiagonal
        else
            @test A[Block(2,2)] isa BandedMatrix
        end
        @test bandwidths(A[Block(2,2)]) == (0,0)
        @test A[Block.(1:2), Block.(2:3)] isa BandedMatrix
    end
end

end # module
