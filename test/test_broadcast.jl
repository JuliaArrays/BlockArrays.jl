using BlockArrays, Test

@testset "broadcast" begin
    @testset "BlockArray" begin
        A = BlockArray(randn(6), 1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.BlockStyle{1}()

        @test exp.(A) == exp.(Vector(A))
        @test blocksizes(A) == blocksizes(exp.(A))

        @test A+A isa BlockArray
        @test blocksizes(A + A) == blocksizes(A .+ A) == blocksizes(A)
        @test blocksizes(A .+ 1) == blocksizes(A)

        A = BlockArray(randn(6,6), 1:3,1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.BlockStyle{2}()

        @test exp.(A) == exp.(Matrix(A))
        @test blocksizes(A) == blocksizes(exp.(A))


        @test blocksizes(A + A) == blocksizes(A .+ A) == blocksizes(A)
        @test blocksizes(A .+ 1) == blocksizes(A)
    end

    @testset "PseudoBlockArray" begin
        A = PseudoBlockArray(randn(6), 1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.PseudoBlockStyle{1}()


        @test exp.(A) == exp.(Vector(A))
        @test blocksizes(A) == blocksizes(exp.(A))

        @test A+A isa PseudoBlockArray
        @test blocksizes(A + A) == blocksizes(A .+ A) == blocksizes(A)
        @test blocksizes(A .+ 1) == blocksizes(A)

        B = PseudoBlockArray(randn(6,6), 1:3,1:3)

        @test BlockArrays.BroadcastStyle(typeof(B)) == BlockArrays.PseudoBlockStyle{2}()

        @test exp.(B) == exp.(Matrix(B))
        @test blocksizes(B) == blocksizes(exp.(B))

        @test blocksizes(B + B) == blocksizes(B .+ B) == blocksizes(B)
        @test blocksizes(B .+ 1) == blocksizes(B)
        @test blocksizes(A .+ 1 .+ B) == blocksizes(B)
        @test A .+ 1 .+ B == Vector(A) .+ 1 .+ B == Vector(A) .+ 1 .+ Matrix(B)
    end

    @testset "Mixed" begin
        A = BlockArray(randn(6), 1:3)
        B = PseudoBlockArray(randn(6), 1:3)

        @test A + B isa BlockArray
        @test B + A isa BlockArray

        @test blocksizes(A + B) == blocksizes(A)

        C = randn(6)

        A .+ C


        @test A + C isa BlockVector{Float64}
        @test C + A isa BlockVector{Float64}
        @test B + C isa PseudoBlockVector{Float64}
        @test C + B isa PseudoBlockVector{Float64}

        blocksizes(A+C) == blocksizes(C+A) == blocksizes(A)
        blocksizes(B+C) == blocksizes(C+B) == blocksizes(B)
    end

    @testset "Mixed block sizes" begin
        A = BlockArray(randn(6), 1:3)
        B = BlockArray(randn(6), fill(2,3))
        @test blocksizes(A+B) == BlockArrays.BlockSizes([1,1,1,1,2])

        A = BlockArray(randn(6,6), 1:3, 1:3)
        B = BlockArray(randn(6,6), fill(2,3), fill(3,2))

        @test blocksizes(A+B) == BlockArrays.BlockSizes([1,1,1,1,2], 1:3)
    end
end
