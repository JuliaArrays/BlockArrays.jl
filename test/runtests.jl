using BlockArrays
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

include("test_blockindices.jl")

@enum blockenums u=1 γ=2 ξ=3

let
    BA_1 = BlockArray(Vector{Float64}, [1,2,3])
    a_1 = rand(2)
    BA_1[Block(2)] = a_1
    @test BA_1[γ] == a_1
    @test BA_1[Block(2)] == a_1
    @test BA_1[2] == a_1[1]
    @test_throws DimensionMismatch BA_1[Block(3)] = rand(4)
    @test_throws BlockBoundsError blockcheckbounds(BA_1, 4)
    @test_throws BlockBoundsError BA_1[Block(4)]

    BA_2 = BlockArray(Matrix{Float64}, [1,2], [3,4])
    a_2 = rand(1,4)
    BA_2[Block(1,2)] = a_2
    @test BA_2[Block(1,2)] == a_2
    BA_2[Block(1,2)] = zeros(1,4)
    BA_2[u, γ] = a_2
    @test BA_2[u, γ] == a_2

    @test BA_2[1,5] == a_2[2]
    @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
end

let
    for BlockType in (BlockArray, PseudoBlockArray)
        a_1 = rand(6)
        BA_1 = BlockType(a_1, [1,2,3])
        @test full(BA_1) == a_1
        @test nblocks(BA_1) == (3,)
        @test nblocks(BA_1,1) == 3
        @test eltype(similar(BA_1, Float32)) == Float32
        q = rand(1)
        BA_1[Block(1)] = q
        @test BA_1[Block(1)] == q
        @test BA_1[u] == q
        if BlockType == PseudoBlockArray
            q2 = zeros(q)
            getblock!(q2, BA_1, 1)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(2), BA_1, 1)
            fill!(q2, 0)
            getblock!(q2, BA_1, u)
            @test q2 == q
        end
        fill!(BA_1, 1.0)
        @test BA_1 == ones(size(BA_1))
        ran = rand(size(BA_1))
        copy!(BA_1, ran)
        @test BA_1 == ran

        a_1_sparse = sprand(6, 0.9)
        BA_1_sparse = BlockType(a_1_sparse, [1,2,3])
        @test full(BA_1_sparse) == a_1_sparse
        BA_1_sparse[4] = 3.0
        @test BA_1_sparse[4] == 3.0


        a_2 = rand(3, 7)
        BA_2 = BlockType(a_2, [1,2], [3,4])
        @test full(BA_2) == a_2
        @test nblocks(BA_2) == (2,2)
        @test nblocks(BA_2, 1) == 2
        @test nblocks(BA_2, 2, 1) == (2, 2)
        @test eltype(similar(BA_2, Float32)) == Float32
        q = rand(1,4)
        BA_2[Block(1,2)] = q
        @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)
        @test BA_2[Block(1,2)] == q
        @test BA_2[u,γ] == q
        if BlockType == PseudoBlockArray
            q2 = zeros(q)
            getblock!(q2, BA_2, 1, 2)
            @test q2 == q
            @test_throws DimensionMismatch getblock!(zeros(1,5), BA_2, 1, 2)
            fill!(q2, 0)
            getblock!(q2, BA_2, u, γ)
            @test q2 == q
        end
        fill!(BA_2, 1.0)
        @test BA_2 == ones(size(BA_2))
        ran = rand(size(BA_2))
        copy!(BA_2, ran)
        @test BA_2 == ran

        a_2_sparse = sprand(3, 7, 0.9)
        BA_2_sparse = BlockType(a_2_sparse, [1,2], [3,4])
        @test full(BA_2_sparse) == a_2_sparse
        BA_2_sparse[1,2] = 3.0
        @test BA_2_sparse[1,2] == 3.0

        a_3 = rand(3, 7,4)
        BA_3 = BlockType(a_3, [1,2], [3,4], [1,2,1])
        @test full(BA_3) == a_3
        @test nblocks(BA_3) == (2,2,3)
        @test nblocks(BA_3, 1) == 2
        @test nblocks(BA_3, 3, 1) == (3, 2)
        @test nblocks(BA_3, 3) == 3
        @test eltype(similar(BA_3, Float32)) == Float32
        q = rand(1,4,2)
        BA_3[Block(1,2,2)] = q
        @test BA_3[Block(1,2,2)] == q
        @test BA_3[u, γ, γ] == q
        if BlockType == PseudoBlockArray
            q3 = zeros(q)
            getblock!(q3, BA_3, 1, 2, 2)
            @test q3 == q
            @test_throws DimensionMismatch getblock!(zeros(1,3,2), BA_3, 1, 2,2)
            fill!(q3, 0)
            getblock!(q3, BA_3, u, γ, γ)
            @test q3 == q
        end
        fill!(BA_3, 1.0)
        @test BA_3 == ones(size(BA_3))
        ran = rand(size(BA_3))
        copy!(BA_3, ran)
        @test BA_3 == ran
    end
end

let
    A = BlockArray(rand(4, 5), [1,3], [2,3]);
    buf = IOBuffer()
    Base.showerror(buf, BlockBoundsError(A, (3,2)))
    @test takebuf_string(buf) == "BlockBoundsError: attempt to access 2×2-blocked 4×5 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [3,2]"
end

replstrmime(x) = stringmime("text/plain", x)
@test replstrmime(BlockArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])) == "2×2-blocked 4×4 BlockArrays.BlockArray{Int64,2,Array{Int64,2}}:\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"
let
    for BlockType in (BlockArray, PseudoBlockArray)
        for T in (Float32, Float64, Int32, Int64)
            for (BA_1, BA_2) in ((BlockType(rand(T, 6), [1,2,3]), BlockType(rand(T, 6), [1,2,3])),
                                 (BlockType(rand(T, 3, 7), [1,2], [3,4]), BlockType(rand(T, 3, 7), [1,2], [3,4])))
                for f in Base.flatten((BlockArrays.UNARY_FUNCS, map(i -> i[1], BlockArrays.REDUCTION_FUNCS)))
                    @eval func = $f
                    print(BlockType, " ", T, " ", f, " ")
                    if !method_exists(func, Tuple{T})
                        println("Skipped no method!")
                        continue
                    end
                    local res
                    try
                        res = func(BA_1)
                    catch e
                        (isa(e, DomainError) || isa(e, Base.Math.AmosException)) || rethrow(e)
                        println("Skipped exception!")
                        continue
                    end
                    @test res ≈ func(full(BA_1))
                    println("OK!")
                end

                for f in Base.flatten((BlockArrays.BINARY_FUNCS, BlockArrays.BOOLEAN_BINARY_FUNCS))
                    @eval func = $f
                    print(BlockType, " ", T, " ", f, " ")
                    A = rand(T)
                    if !method_exists(func, Tuple{T, T})
                        println("Skipped no method!")
                        continue
                    end
                    local res, res_scal_1, res_scal_2
                    try
                        res = func(BA_1, BA_2)
                        #res_scal_1 = func(BA_1, A)
                        #res_scal_2 = func(A, BA_2)
                    catch e
                        (isa(e, DomainError) || isa(e, Base.Math.AmosException)) || rethrow(e)
                        println("Skipped!")
                        continue
                    end
                    @test isequal(res, func(full(BA_1), full(BA_2)))
                    #@test isequal(res_scal_1, func(full(BA_1), A))
                    #@test isequal(res_scal_2, func(A, full(BA_2)))
                    println("OK!")
                end
            end
        end
    end
end
