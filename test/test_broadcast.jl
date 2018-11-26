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

        A = PseudoBlockArray(randn(6,6), 1:3,1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.PseudoBlockStyle{2}()

        @test exp.(A) == exp.(Matrix(A))
        @test blocksizes(A) == blocksizes(exp.(A))


        @test blocksizes(A + A) == blocksizes(A .+ A) == blocksizes(A)
        @test blocksizes(A .+ 1) == blocksizes(A)
    end

    @testset "Mixed" begin
        A = BlockArray(randn(6), 1:3)
        B = PseudoBlockArray(randn(6), 1:3)

        @test A + B isa BlockArray
        @test B + A isa BlockArray

        @test blocksizes(A + B) == blocksizes(A)

        C = randn(6)

        @test A + C isa Vector{Float64}
        @test C + A isa Vector{Float64}
        @test B + C isa Vector{Float64}
        @test C + B isa Vector{Float64}
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
