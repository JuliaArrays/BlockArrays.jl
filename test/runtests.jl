using BlockArrays
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

include("test_blockindices.jl")

let
    BA_1 = BlockArray(Vector{Float64}, [1,2,3])
    a_1 = rand(2)
    BA_1[Block(2)] = a_1
    @test BA_1[Block(2)] == a_1
    @test BA_1[2] == a_1[1]
    @test_throws ArgumentError BA_1[Block(3)] = rand(4)



    BA_2 = BlockArray(Matrix{Float64}, [1,2], [3,4])
    a_2 = rand(1,4)
    BA_2[Block(1,2)] = a_2
    @test BA_2[Block(1,2)] == a_2
    @test BA_2[1,5] == a_2[2]
    @test_throws ArgumentError BA_2[Block(1,2)] = rand(1,5)

end

let
    for BlockType in (BlockArray, PseudoBlockArray)
        a_1 = rand(6)
        BA_1 = BlockType(a_1, [1,2,3])
        @test full(BA_1) == a_1
        @test nblocks(BA_1) == (3,)
        @test nblocks(BA_1,1) == 3
        @test eltype(similar(BA_1, Float32)) == Float32

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
        @test eltype(similar(BA_2, Float32)) == Float32

        a_2_sparse = sprand(3, 7, 0.9)
        BA_2_sparse = BlockType(a_2_sparse, [1,2], [3,4])
        @test full(BA_2_sparse) == a_2_sparse
        BA_2_sparse[1,2] = 3.0
        @test BA_2_sparse[1,2] == 3.0
    end
end

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
