using SparseArrays, BlockArrays, Base64, FillArrays, LinearAlgebra, Test
import BlockArrays: _BlockArray

function test_error_message(f, needle, expected = Exception)
    err = nothing
    try
        f()
    catch err
    end
    @test err isa expected
    @test occursin(needle, sprint(showerror ,err))
    return err
end

@testset "block constructors" begin
    @testset "BlockArray Constructors" begin
        ret = BlockArray{Float64}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float64,1}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float64,1,Vector{Vector{Float64}}}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float64}(undef, (blockedrange(1:3),))
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float64,1}(undef, (blockedrange(1:3),))
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float64,1,Vector{Vector{Float64}}}(undef, (blockedrange(1:3),))
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = BlockArrays._BlockArray([[0.0],[0.0,0.0],[0.0,0.0,0.0]], 1:3)
        @test Array(ret)  == zeros(6)

        ret = BlockArrays._BlockArray([[0.0],[0.0,0.0],[0.0,0.0,0.0]], (blockedrange(1:3),))
        @test Array(ret)  == zeros(6)

        ret = BlockArray{Float32}(undef_blocks, 1:3)
        @test eltype(ret.blocks) == Vector{Float32}
        @test_throws UndefRefError ret.blocks[1]

        ret = BlockArray{Float32,1}(undef_blocks, 1:3)
        @test eltype(ret.blocks) == Vector{Float32}
        @test_throws UndefRefError ret.blocks[1]

        ret = BlockArray{Float32,1,Vector{Vector{Float32}}}(undef_blocks, 1:3)
        @test eltype(ret.blocks) == Vector{Float32}
        @test_throws UndefRefError ret.blocks[1]

        ret = BlockArray{Float32}(undef_blocks, 1:3, 1:3)
        @test eltype(ret.blocks) == Matrix{Float32}
        @test_throws UndefRefError ret.blocks[1]

        ret = BlockArray(undef_blocks, Vector{Float32}, 1:3)
        @test eltype(ret) == Float32
        @test eltype(ret.blocks) == Vector{Float32}
        @test_throws UndefRefError ret.blocks[1]

        ret = BlockArray{Float64}(undef, 1:3, 1:3)
        fill!(ret, 0)
        @test Matrix(ret) == zeros(6,6)

        A = [1,2,3,4,5,6]
        @test A == BlockArray(A, 1:3) == BlockArray{Int}(A, 1:3) == 
            BlockArray(A, (blockedrange(1:3),)) == BlockArray{Int}(A, (blockedrange(1:3),)) ==
            BlockArray{Float64}(A, 1:3)
    end
    @testset "PseudoBlockArray constructors" begin
        ret = PseudoBlockArray{Float64}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = PseudoBlockArray{Float64,1}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = PseudoBlockArray{Float64,1,Vector{Float64}}(undef, 1:3)
        fill!(ret, 0)
        @test Array(ret)  == zeros(6)

        ret = PseudoBlockArray{Float64}(undef, 1:3, 1:3)
        fill!(ret, 0)
        @test Matrix(ret) == zeros(6,6)

        A = [1,2,3,4,5,6]
        @test A == PseudoBlockArray(A, 1:3) == PseudoBlockArray{Int}(A, 1:3) == 
            PseudoBlockArray(A, (blockedrange(1:3),)) == PseudoBlockArray{Int}(A, (blockedrange(1:3),)) ==
            PseudoBlockArray{Float64}(A, 1:3)
    end

    @testset "similar" begin
        ret = BlockArray{Float64}(undef, 1:3)
        @test similar(typeof(ret), axes(ret)) isa BlockArray
        @test similar(typeof(ret), (Base.OneTo(6),)) isa BlockArray
        @test similar(Array{Float64}, axes(ret)) isa PseudoBlockArray
        @test similar(Vector{Float64}, axes(ret)) isa PseudoBlockArray
        @test similar(randn(5,5), Float64, axes(ret)) isa PseudoBlockArray

        ret = BlockArray{Float64}(undef, 1:3, 1:3)
        @test similar(typeof(ret), axes(ret)) isa BlockArray
        @test similar(typeof(ret), (Base.OneTo(6),axes(ret,2))) isa BlockArray
        @test similar(Array{Float64}, axes(ret)) isa PseudoBlockArray
        @test similar(Vector{Float64}, axes(ret)) isa PseudoBlockArray
        @test similar(Array{Float64}, (Base.OneTo(5), axes(ret,2))) isa PseudoBlockArray
        @test similar(randn(5,5), Float64, axes(ret)) isa PseudoBlockArray
        @test similar(randn(5,5), Float64, (Base.OneTo(5), axes(ret,2))) isa PseudoBlockArray
    end

    @test_throws DimensionMismatch BlockArray([1,2,3],[1,1])

    @testset "mortar" begin
        @testset for sizes in [(1:3,), (1:3, 1:3), (1:3, 1:3, 1:3)]
            dims = sum.(sizes)
            A = BlockArray(copy(reshape(1:prod(dims), dims)), sizes...)
            @test mortar(A.blocks) == A
        end

        ret = mortar([spzeros(2), spzeros(3)])
        @test eltype(ret.blocks) <: SparseVector
        @test axes(ret) == (blockedrange([2, 3]),)

        ret = mortar(
            (spzeros(1, 3), spzeros(1, 4)),
            (spzeros(2, 3), spzeros(2, 4)),
            (spzeros(5, 3), spzeros(5, 4)),
        )

        @test Array(ret) == zeros(8, 7)
        @test eltype(ret.blocks) <: SparseMatrixCSC
        @test axes(ret) == blockedrange.(([1, 2, 5], [3, 4]))

        test_error_message("must have ndims consistent with ndims = 1") do
            mortar([ones(2,2)])
        end
        test_error_message("must have ndims consistent with ndims = 2") do
            mortar(reshape([ones(2), ones(2, 2)], (1, 2)))
        end
        test_error_message("size(blocks[2, 2]) (= (111, 222)) is incompatible with expected size: (2, 4)") do
            mortar(
                (zeros(1, 3), zeros(1, 4)),
                (zeros(2, 3), zeros(111, 222)),
            )
        end
    end
    
    @testset "BlockVector" begin
        a_data = [1,2,3]
        a = BlockVector(a_data,[1,2])
        a[1] = 2
        @test a == [2,2,3]
        @test a_data == [1,2,3]
        a = BlockVector(a_data,(blockedrange([1,2]),))
        a[1] = 2
        @test a == [2,2,3]
        @test a_data == [1,2,3]
        a = PseudoBlockVector(a_data,[1,2])
        a[1] = 2
        @test a == [2,2,3]
        @test a_data == [2,2,3]
        a = PseudoBlockVector(a_data,(blockedrange([1,2]),))
        a[1] = 3
        @test a == [3,2,3]
        @test a_data == [3,2,3]
    end
    @testset "BlockMatrix" begin
        a_data = [1 2; 3 4]
        a = BlockMatrix(a_data,[1,1],[2])
        a[1] = 2
        @test a == [2 2; 3 4]
        @test a_data == [1 2; 3 4]
        a = BlockMatrix(a_data,blockedrange.(([1,1],[2])))
        a[1] = 2
        @test a == [2 2; 3 4]
        @test a_data == [1 2; 3 4]
        a = PseudoBlockMatrix(a_data,[1,1],[2])
        a[1] = 2
        @test a == [2 2; 3 4]
        @test a_data == [2 2; 3 4]
        a = PseudoBlockMatrix(a_data, blockedrange.(([1,1],[2])))
        a[1] = 3
        @test a == [3 2; 3 4]
        @test a_data == [3 2; 3 4]
    end
end

@testset "block indexing" begin
    BA_1 = BlockArray(undef_blocks, Vector{Float64}, [1,2,3])
    @test Base.IndexStyle(typeof(BA_1)) == IndexCartesian()

    a_1 = rand(2)
    BA_1[Block(2)] = a_1
    @test BA_1[BlockIndex(2, 1)] == a_1[1]
    @test BA_1[BlockIndex(2, 2)] == a_1[2]
    @test BA_1[Block(2)] == a_1
    @test BA_1[2] == a_1[1]

    @test_throws DimensionMismatch (BA_1[Block(3)] = rand(4))
    @test_throws BlockBoundsError blockcheckbounds(BA_1, 4)
    @test_throws BlockBoundsError BA_1[Block(4)]

    BA_2 = BlockArray(undef_blocks, Matrix{Float64}, [1,2], [3,4])
    a_2 = rand(1,4)
    BA_2[Block(1,2)] = a_2
    @test BA_2[Block(1,2)] == a_2
    BA_2[Block(1,2)] = a_2

    @test BA_2[1,5] == a_2[2]
    @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
end

@testset "misc block tests" begin
    for BlockType in (BlockArray, PseudoBlockArray)
        a_1 = rand(6)
        BA_1 = BlockType(a_1, [1,2,3])
        @test Array(BA_1) == a_1
        @test blocksize(BA_1) == (3,)
        @test blocksize(BA_1,1) == 3
        @test eltype(similar(BA_1, Float32)) == Float32
        q = rand(1)
        BA_1[Block(1)] = q
        BA_1[BlockIndex(3, 2)] = a_1[5]
        @test BA_1[Block(1)] == q
        if BlockType == PseudoBlockArray
            q2 = zero(q)
            getblock!(q2, BA_1, 1)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(2), BA_1, 1)
            fill!(q2, 0)
            getblock!(q2, BA_1, 1)
            @test q2 == q
        end
        fill!(BA_1, 1.0)
        @test BA_1 == ones(size(BA_1))
        ran = rand(size(BA_1)...)
        copyto!(BA_1, ran)
        @test BA_1 == ran

        a_1_sparse = sprand(6, 0.9)
        BA_1_sparse = BlockType(a_1_sparse, [1,2,3])
        @test Array(BA_1_sparse) == a_1_sparse
        BA_1_sparse[4] = 3.0
        @test BA_1_sparse[4] == 3.0


        a_2 = rand(3, 7)
        BA_2 = BlockType(a_2, [1,2], [3,4])
        @test Array(BA_2) == a_2
        @test blocksize(BA_2) == (2,2)
        @test blocksize(BA_2, 1) == 2
        BA_2[BlockIndex((2,1), (2,2))] = a_2[3,2]
        @test eltype(similar(BA_2, Float32)) == Float32
        q = rand(1,4)
        BA_2[Block(1,2)] = q
        @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
        @test BA_2[Block(1,2)] == q
        if BlockType == PseudoBlockArray
            q2 = zero(q)
            getblock!(q2, BA_2, 1, 2)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(1,5), BA_2, 1, 2)
        end
        fill!(BA_2, 1.0)
        @test BA_2 == ones(size(BA_2))
        ran = rand(size(BA_2)...)
        copyto!(BA_2, ran)
        @test BA_2 == ran

        a_2_sparse = sprand(3, 7, 0.9)
        BA_2_sparse = BlockType(a_2_sparse, [1,2], [3,4])
        @test Array(BA_2_sparse) == a_2_sparse
        BA_2_sparse[1,2] = 3.0
        @test BA_2_sparse[1,2] == 3.0

        a_3 = rand(3, 7,4)
        BA_3 = BlockType(a_3, [1,2], [3,4], [1,2,1])
        @test Array(BA_3) == a_3
        @test blocksize(BA_3) == (2,2,3)
        @test blocksize(BA_3, 1) == 2
        @test blocksize(BA_3, 3) == 3
        BA_3[BlockIndex((1,1,1), (1,1,1))] = a_3[1,1,1]
        @test eltype(similar(BA_3, Float32)) == Float32
        q = rand(1,4,2)
        BA_3[Block(1,2,2)] = q
        @test BA_3[Block(1,2,2)] == q
        if BlockType == PseudoBlockArray
            q3 = zero(q)
            getblock!(q3, BA_3, 1, 2, 2)
            @test q3 == q
            @test_throws DimensionMismatch getblock!(zeros(1,3,2), BA_3, 1, 2,2)
        end
        fill!(BA_3, 1.0)
        @test BA_3 == ones(size(BA_3))
        ran = rand(size(BA_3)...)
        copyto!(BA_3, ran)
        @test BA_3 == ran
    end
end

@testset "convert" begin
    # Could probably be DRY'd.
    A = PseudoBlockArray(rand(2,3), [1,1], [2,1])
    C = convert(BlockArray, A)
    @test C == A == BlockArray(A)
    @test eltype(C) == eltype(A)

    C = convert(BlockArray{Float32}, A)
    @test C ≈ A ≈ BlockArray(A)
    @test eltype(C) == Float32

    C = convert(BlockArray{Float32, 2}, A)
    @test C ≈ A ≈ BlockArray(A)
    @test eltype(C) == Float32

    Ã = PseudoBlockArray(rand(2,3), Fill(1,2), [2,1])
    @test convert(typeof(A), Ã) == Ã
    
    @test PseudoBlockArray(A, axes(Ã)) isa typeof(Ã)
    @test PseudoBlockArray(A, axes(Ã)) == A    


    A = BlockArray(rand(2,3), [1,1], [2,1])
    C = convert(PseudoBlockArray, A)
    @test C == A == PseudoBlockArray(A)
    @test eltype(C) == eltype(A)

    C = convert(PseudoBlockArray{Float32}, A)
    @test C ≈ A ≈ PseudoBlockArray(A)
    @test eltype(C) == Float32

    C = convert(PseudoBlockArray{Float32, 2}, A)
    @test C ≈ A ≈ PseudoBlockArray(A)
    @test eltype(C) == Float32
end

@testset "string" begin
    A = BlockArray(rand(4, 5), [1,3], [2,3]);
    buf = IOBuffer()
    Base.showerror(buf, BlockBoundsError(A, (3,2)))
    @test String(take!(buf)) == "BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArray{Float64,2,Array{Array{Float64,2},2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}} at block index [3,2]"

    A = PseudoBlockArray(rand(4, 5), [1,3], [2,3]);
    Base.showerror(buf, BlockBoundsError(A, (3,2)))
    @test String(take!(buf)) == "BlockBoundsError: attempt to access 2×2-blocked 4×5 PseudoBlockArray{Float64,2,Array{Float64,2},Tuple{BlockedUnitRange{Array{Int64,1}},BlockedUnitRange{Array{Int64,1}}}} at block index [3,2]"
end

@testset "replstring" begin
    @test stringmime("text/plain",BlockArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])) == "2×2-blocked 4×4 BlockArray{Int64,2}:\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"
    @test stringmime("text/plain",PseudoBlockArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])) == "2×2-blocked 4×4 PseudoBlockArray{Int64,2}:\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"
    design = zeros(Int16,6,9);
    A = BlockArray(design,[6],[4,5])
    @test stringmime("text/plain",A) == "1×2-blocked 6×9 BlockArray{Int16,2}:\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0"
    A = PseudoBlockArray(design,[6],[4,5])
    @test stringmime("text/plain",A) == "1×2-blocked 6×9 PseudoBlockArray{Int16,2}:\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0"
end

@testset "AbstractVector{Int} blocks" begin
    A = BlockArray(ones(6,6), 1:3, 1:3)
    @test A[1,1] == 1
    @test A[Block(2,3)] == ones(2,3)

    A = BlockArray(undef_blocks, Matrix{Float64}, 1:3, 1:3)
    A[Block(2,3)] = ones(2,3)
    @test A[Block(2,3)] == ones(2,3)
end

@testset "Strided array interface" begin
    A = PseudoBlockArray{Float64}(undef, 1:3, 1:3)
    fill!(A, 1)
    @test strides(A) == (1, size(A,1))
    x = randn(size(A,2))
    y = similar(x)
    @test BLAS.gemv!('N', 2.0, A, x, 0.0, y) ≈ 2A*x
end

@testset "lmul!/rmul!" begin
    A = PseudoBlockArray{Float64}(undef, 1:3)
    @test fill!(A, NaN) === A
    @test all(isnan, lmul!(0.0, copy(A))) == all(isnan, lmul!(0.0, Array(A)))
    @test lmul!(false, copy(A)) == lmul!(false, Array(A))
    @test lmul!(0.0, A) === A
    @test fill!(A, NaN) === A
    @test all(isnan, rmul!(copy(A), 0.0)) == all(isnan, rmul!(Array(A), 0.0))
    @test rmul!(copy(A), false) == rmul!(Array(A), false)
    @test rmul!(A, 0.0) === A

    A = BlockArray{Float64}(undef, 1:3)
    @test fill!(A, NaN) === A
    @test all(isnan, lmul!(0.0, copy(A))) == all(isnan, lmul!(0.0, Array(A)))
    @test lmul!(false, copy(A)) == lmul!(false, Array(A))
    @test lmul!(0.0, A) === A
    @test fill!(A, NaN) === A
    @test all(isnan, rmul!(copy(A), 0.0)) == all(isnan, rmul!(Array(A), 0.0))
    @test rmul!(copy(A), false) == rmul!(Array(A), false)
    @test rmul!(A, 0.0) === A
end

@testset "copy" begin
    A = PseudoBlockArray(randn(6), 1:3)
    B = copy(A)
    @test typeof(A) == typeof(B)
    @test axes(A) === axes(B)
    @test A == B
    B[1] = 2
    @test B[1] == 2
    @test A[1] ≠ 2

    A = BlockArray(randn(6), 1:3)
    B = copy(A)
    @test typeof(A) == typeof(B)
    @test axes(A) === axes(B)
    @test A == B
    B[1] = 2
    @test B[1] == 2
    @test A[1] ≠ 2
end

@testset "const block size" begin
    N = 10
    A = mortar(fill([1,2], N), Fill(2,N))
    B = PseudoBlockArray(vcat(fill([1,2], N)...),  Fill(2,N))
    @test A == vcat(A.blocks...) == B
    @test A[Block(1)] == B[Block(1)] == [1,2]
end

@testset "mixed blocks #92" begin
    A = BlockArray{Any}(undef_blocks, [1,2], [3,2])
    A.blocks[1,1] = fill(1.0,1,3)
    A.blocks[1,2] = fill(2,1,2)
    A.blocks[2,1] = fill(3//3,2,3)
    A.blocks[2,2] = fill(4.0f0,2,2)
    @test A[1,1] == 1.0
    @test A[2,1] == 1//1

    B = Matrix{Matrix}(undef,2,2)
    B[1,1] = fill(1.0,1,3)
    B[1,2] = fill(2,1,2)
    B[2,1] = fill(3//3,2,3)
    B[2,2] = fill(4.0f0,2,2)
    @test mortar(B) == A
    @test mortar(B)[1,1] == 1.0
end

@testset "reshape" begin
    A = BlockArray(1:6, 1:3)
    @test reshape(A, Val(2)) isa PseudoBlockArray{Int64,2,Array{Int64,2},Tuple{BlockedUnitRange{Array{Int64,1}},Base.OneTo{Int64}}}
    @test reshape(A, Val(2)) == PseudoBlockArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1)))
    @test reshape(A, (blockedrange(Fill(2,3)),))[Block(1)] == 1:2

    A = PseudoBlockArray(1:6, 1:3)
    @test reshape(A, Val(2)) isa typeof(PseudoBlockArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1))))
    @test reshape(A, Val(2)) == PseudoBlockArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1)))
    @test reshape(A, (blockedrange(Fill(2,3)),))[Block(1)] == 1:2
end

@testset "*" begin
    A = BlockArray(randn(6,6), 1:3,1:3)
    Ã = PseudoBlockArray(A)
    b = randn(6)
    @test A*b isa PseudoBlockVector{Float64}
    @test Ã*b isa PseudoBlockVector{Float64}
    @test A*b ≈ Ã*b ≈ Matrix(A)*b 
end

@testset "Blockindex" begin
    a = PseudoBlockArray(randn(3), [1,2])
    @test a[Block(1)[1]] == a[1]
    @test a[Block(1)[1:1]] == a[1:1]
    A = PseudoBlockArray(randn(3,3), [1,2], [1,2])
    @test A[Block(1)[1], Block(1)[1]] == A[Block(1,1)[1,1]] == A[1,1]
    @test A[Block(1)[1:1], Block(1)[1:1]] == A[Block(1,1)[1:1,1:1]] == A[1:1,1:1]
    @test A[Block(1)[1:1], Block(1)[1]] == BlockArray(A)[Block(1)[1:1], Block(1)[1]] == A[1:1,1] 
    @test A[Block(1)[1], Block(1)[1:1]] == BlockArray(A)[Block(1)[1], Block(1)[1:1]] == A[1,1:1] 
end