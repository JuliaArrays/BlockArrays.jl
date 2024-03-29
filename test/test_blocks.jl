using Test, BlockArrays

@testset "blocks" begin
    @testset "blocks(::BlockVector)" begin
        vector_blocks = [[1, 2], [3, 4, 5], Int[]]
        @test blocks(mortar(vector_blocks)) === vector_blocks
        @test collect(blocks(mortar(vector_blocks))) == vector_blocks
    end

    @testset "blocks(::BlockMatrix)" begin
        matrix_blocks = permutedims(reshape([
            1ones(1, 3), 2ones(1, 2),
            3ones(2, 3), 4ones(2, 2),
        ], (2, 2)))
        @test blocks(mortar(matrix_blocks)) === matrix_blocks
    end

    @testset "blocks(::PseudoBlockVector)" begin
        v0 = rand(3)
        vb = PseudoBlockArray(v0, [1, 2])
        @test size(blocks(vb)) == (2,)
        blocks(vb)[1] = [123]
        @test v0[1] == 123
        @test parent(blocks(vb)[1]) === v0

        # toplevel = true:
        str = sprint(show, "text/plain", blocks(vb))
        @test occursin("blocks of PseudoBlockArray of", str)

        # toplevel = false:
        str = sprint(show, "text/plain", view(blocks(vb), 1:1))
        @test occursin("::BlocksView{…,::PseudoBlockArray{…,", str)
    end

    @testset "blocks(::PseudoBlockMatrix)" begin
        m0 = rand(2, 4)
        mb = PseudoBlockArray(m0, [1, 1], [2, 1, 1])
        @test size(blocks(mb)) == (2, 3)
        blocks(mb)[1, 1] = [123 456]
        @test m0[1, 1] == 123
        @test m0[1, 2] == 456
        @test parent(blocks(mb)[1, 1]) === m0

        # linear indexing
        @test blocks(mb)[1] == m0[1:1, 1:2]
        blocks(mb)[1] = [111 222]
        @test mb[Block(1, 1)] == [111 222]

        # toplevel = true:
        str = sprint(show, "text/plain", blocks(mb))
        @test occursin("blocks of PseudoBlockArray of", str)

        # toplevel = false:
        str = sprint(show, "text/plain", view(blocks(mb), 1:1, 1:1))
        @test occursin("::BlocksView{…,::PseudoBlockArray{…,", str)
    end

    @testset "blocks(::Vector)" begin
        v = rand(3)
        @test size(blocks(v)) == (1,)
        blocks(v)[1][1] = 123
        @test v[1] == 123
        @test parent(blocks(v)[1]) === v
    end

    @testset "blocks(::Matrix)" begin
        m = rand(2, 4)
        @test size(blocks(m)) == (1, 1)
        blocks(m)[1, 1][1, 1] = 123
        @test m[1, 1] == 123
        @test parent(blocks(m)[1, 1]) === m
    end

    @testset "blocks(::Adjoint|Transpose)" begin
        m = BlockArray([rand(ComplexF64, 2, 2) for _ in 1:3, _ in 1:5], [1, 2], [2, 3])
        @testset for i in 1:2, j in 1:2
            @test blocks(m')[i, j] == m'[Block(i), Block(j)]
            @test blocks(transpose(m))[i, j] == transpose(m)[Block(i), Block(j)]
        end
    end

    @testset "blocks(::SubArray)" begin
        vector_blocks = [[1, 2], [3, 4, 5], Int[]]
        b = view(mortar(vector_blocks), Block(1):Block(2))
        v = blocks(b)
        @test v == vector_blocks[1:2]
        v[1][1] = 111
        @test b[1] == 111
        @test parent(v) === parent(b).blocks  # special path works
    end

    @testset "blocks(::SubArray)" begin
        matrix_blocks = permutedims(reshape([
            1ones(1, 3), 2ones(1, 2),
            3ones(2, 3), 4ones(2, 2),
        ], (2, 2)))
        b = view(mortar(matrix_blocks), Block(1):Block(2), Block(2):Block(2))
        m = blocks(b)
        @test m == matrix_blocks[1:2, 2:2]
        m[1, 1][1, 1] = 111
        @test b[1, 1] == 111
        @test parent(m) === parent(b).blocks  # special path works
    end
end
