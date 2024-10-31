module TestBlockSVD

using BlockArrays, Test, LinearAlgebra, Random
using BlockArrays: BlockDiagonal

Random.seed!(0)

eltypes = (Float32, Float64, ComplexF32, ComplexF64, Int)

@testset "Block SVD ($T)" for T in eltypes
    x = rand(T, 4, 4)
    USV = svd(x)
    U, S, Vt = USV.U, USV.S, USV.Vt

    y = BlockArray(x, [2, 2], [2, 2])
    # https://github.com/JuliaArrays/BlockArrays.jl/issues/425
    # USV_blocked = @inferred svd(y)
    USV_block = svd(y)
    U_block, S_block, Vt_block = USV_block.U, USV_block.S, USV_block.Vt

    # test types
    @test U_block isa BlockedMatrix
    @test eltype(U_block) == float(T)
    @test S_block isa BlockedVector
    @test eltype(S_block) == real(float(T))
    @test Vt_block isa BlockedMatrix
    @test eltype(Vt_block) == float(T)

    # test structure
    @test blocksizes(U_block, 1) == blocksizes(y, 1)
    @test length(blocksizes(U_block, 2)) == 1
    @test blocksizes(Vt_block, 2) == blocksizes(y, 2)
    @test length(blocksizes(Vt_block, 1)) == 1

    # test correctness
    @test U_block ≈ U
    @test S_block ≈ S
    @test Vt_block ≈ Vt
    @test U_block * Diagonal(S_block) * Vt_block ≈ y
end

@testset "Blocked SVD ($T)" for T in eltypes
    x = rand(T, 4, 4)
    USV = svd(x)
    U, S, Vt = USV.U, USV.S, USV.Vt

    y = BlockedArray(x, [2, 2], [2, 2])
    # https://github.com/JuliaArrays/BlockArrays.jl/issues/425
    # USV_blocked = @inferred svd(y)
    USV_blocked = svd(y)
    U_blocked, S_blocked, Vt_blocked = USV_blocked.U, USV_blocked.S, USV_blocked.Vt

    # test types
    @test U_blocked isa BlockedMatrix
    @test eltype(U_blocked) == float(T)
    @test S_blocked isa BlockedVector
    @test eltype(S_blocked) == real(float(T))
    @test Vt_blocked isa BlockedMatrix
    @test eltype(Vt_blocked) == float(T)

    # test structure
    @test blocksizes(U_blocked, 1) == blocksizes(y, 1)
    @test length(blocksizes(U_blocked, 2)) == 1
    @test blocksizes(Vt_blocked, 2) == blocksizes(y, 2)
    @test length(blocksizes(Vt_blocked, 1)) == 1

    # test correctness
    @test U_blocked ≈ U
    @test S_blocked ≈ S
    @test Vt_blocked ≈ Vt
    @test U_blocked * Diagonal(S_blocked) * Vt_blocked ≈ y
end

@testset "BlockDiagonal SVD ($T)" for T in eltypes
    blocksz = (2, 3, 1)
    y = BlockDiagonal([rand(T, d, d) for d in blocksz])
    x = Array(y)
    
    USV = svd(x)
    U, S, Vt = USV.U, USV.S, USV.Vt
    
    # https://github.com/JuliaArrays/BlockArrays.jl/issues/425
    # USV_blocked = @inferred svd(y)
    USV_block = svd(y)
    U_block, S_block, Vt_block = USV_block.U, USV_block.S, USV_block.Vt

    # test types
    @test U_block isa BlockDiagonal
    @test eltype(U_block) == float(T)
    @test S_block isa BlockVector
    @test eltype(S_block) == real(float(T))
    @test Vt_block isa BlockDiagonal
    @test eltype(Vt_block) == float(T)

    # test structure
    @test blocksizes(U_block, 1) == blocksizes(y, 1)
    @test length(blocksizes(U_block, 2)) == length(blocksz)
    @test blocksizes(Vt_block, 2) == blocksizes(y, 2)
    @test length(blocksizes(Vt_block, 1)) == length(blocksz)

    # test correctness: SVD is not unique, so cannot compare to dense
    @test U_block * BlockDiagonal(Diagonal.(S_block.blocks)) * Vt_block ≈ y
    @test U_block' * U_block ≈ LinearAlgebra.I
    @test Vt_block * Vt_block' ≈ LinearAlgebra.I
end

end # module
