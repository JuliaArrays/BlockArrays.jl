module TestBlocks

using Test, BlockArrays
import BlockArrays: eachblockaxes1

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

    @testset "blocks::BlockMatrix{::MyString}" begin
        # test printing with ANSI escape sequences & textwidth(::Char) ≠ 1
        struct MyString
            s::String
        end
        function Base.show(io::IO, x::MyString)
            if all(isnumeric, x.s)
                printstyled(io, x.s; bold=true, color=:green)
            elseif all(isascii, x.s)
                printstyled(io, x.s, color=:red)
                print(io, " ascii!")
            else
                print(io, x.s)
            end
        end

        B = BlockArray(undef_blocks, Matrix{MyString}, [1,2], [1,2])
        B[Block(1), Block(1)] = [MyString("abc");;]
        B[Block(1), Block(2)] = [MyString("123") MyString("γ");]
        B[Block(2), Block(1)] = [MyString("γ"); MyString("1");;]
        B[Block(2), Block(2)] = [MyString("⛵⛵⛵⛵⛵") MyString("x"); MyString("⛵⛵⛵") MyString("4")]
        
        strip_ansi(s) = reduce(*, filter(c->!(c isa Base.ANSIDelimiter), 
                                         map(last, Base.ANSIIterator(s))))
        reference_str = "2×2-blocked 3×3 BlockMatrix{$(@__MODULE__).MyString}:\n \e[31mabc\e[39m ascii!  │  \e[32m\e[1m123\e[22m\e[39m         γ       \n ────────────┼──────────────────────\n γ           │  ⛵⛵⛵⛵⛵  \e[31mx\e[39m ascii!\n \e[32m\e[1m1\e[22m\e[39m           │  ⛵⛵⛵      \e[32m\e[1m4\e[22m\e[39m       "
        @test strip_ansi(sprint(show, "text/plain", B; context=stdout)) == strip_ansi(reference_str)
        @test strip_ansi(sprint(show, "text/plain", B)) == strip_ansi(reference_str)
    end

    @testset "blocks(::BlockedVector)" begin
        v0 = rand(3)
        vb = BlockedArray(v0, [1, 2])
        @test size(blocks(vb)) == (2,)
        blocks(vb)[1] = [123]
        @test v0[1] == 123
        @test parent(blocks(vb)[1]) === v0

        # toplevel = true:
        str = sprint(show, "text/plain", blocks(vb))
        @test occursin("blocks of BlockedArray of", str)

        # toplevel = false:
        str = sprint(show, "text/plain", view(blocks(vb), 1:1))
        @test occursin("::BlocksView{…,::BlockedArray{…,", str)
    end

    @testset "blocks(::BlockedMatrix)" begin
        m0 = rand(2, 4)
        mb = BlockedArray(m0, [1, 1], [2, 1, 1])
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
        @test occursin("blocks of BlockedArray of", str)

        # toplevel = false:
        str = sprint(show, "text/plain", view(blocks(mb), 1:1, 1:1))
        @test occursin("::BlocksView{…,::BlockedArray{…,", str)
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

@testset "blocksizes" begin
    @testset "blocksizes" begin
        v = Array(reshape(1:20, (5, 4)))
        A = BlockArray(v, [2, 3], [3, 1])
        @test blocklengths.(axes(A)) == ([2, 3], [3, 1])
        bs = @inferred(blocksizes(A))
        @test @inferred(size(bs)) == (2, 2)
        @test @inferred(length(bs)) == 4
        @test @inferred(axes(bs)) == (1:2, 1:2)
        @test @inferred(eltype(bs)) ≡ Tuple{Int,Int}
        @test bs == [(2, 3) (2, 1); (3, 3) (3, 1)]
        @test @inferred(bs[1, 1]) ≡ (2, 3)
        @test @inferred(bs[2, 1]) ≡ (3, 3)
        @test @inferred(bs[1, 2]) ≡ (2, 1)
        @test @inferred(bs[2, 2]) ≡ (3, 1)
        @test @inferred(bs[1]) ≡ (2, 3)
        @test @inferred(bs[2]) ≡ (3, 3)
        @test @inferred(bs[3]) ≡ (2, 1)
        @test @inferred(bs[4]) ≡ (3, 1)
        @test @inferred((x -> blocksizes(x, 1))(A)) == [2, 3]
        @test @inferred((x -> blocksizes(x, 2))(A)) == [3, 1]
    end

    @testset "Inference: issue #425" begin
        x = BlockedArray(rand(4, 4), [2, 2], [2, 2])
        bs1 = @inferred (x -> blocksizes(x, 1))(x)
        @test bs1 == [2,2]
        bs4 = @inferred (x -> blocksizes(x, 4))(x)
        @test bs4 == 1:1
    end
end

@testset "blocklengths" begin
    v = Array(reshape(1:20, (5, 4)))
    A = BlockArray(v, [2, 3], [3, 1])
    bls = @inferred(blocklengths(A))
    @test bls == [6 2; 9 3]
    @test @inferred(length(bls)) ≡ 4
    @test @inferred(size(bls)) ≡ (2, 2)
    @test @inferred(eltype(bls)) ≡ Int
    @test @inferred(bls[1, 1]) ≡ 6
    @test @inferred(bls[2, 1]) ≡ 9
    @test @inferred(bls[1, 2]) ≡ 2
    @test @inferred(bls[2, 2]) ≡ 3
    @test @inferred(bls[1]) ≡ 6
    @test @inferred(bls[2]) ≡ 9
    @test @inferred(bls[3]) ≡ 2
    @test @inferred(bls[4]) ≡ 3
end

@testset "eachblockaxes" begin
    v = Array(reshape(1:20, (5, 4)))
    A = BlockArray(v, [2, 3], [3, 1])
    bas = @inferred(eachblockaxes(A))
    @test bas == [(Base.OneTo(2), Base.OneTo(3)) (Base.OneTo(2), Base.OneTo(1)); (Base.OneTo(3), Base.OneTo(3)) (Base.OneTo(3), Base.OneTo(1))]
    @test @inferred(length(bas)) ≡ 4
    @test @inferred(size(bas)) ≡ (2, 2)
    @test @inferred(eltype(bas)) ≡ Tuple{Base.OneTo{Int},Base.OneTo{Int}}
    @test @inferred(bas[1, 1]) ≡ (Base.OneTo(2), Base.OneTo(3))
    @test @inferred(bas[2, 1]) ≡ (Base.OneTo(3), Base.OneTo(3))
    @test @inferred(bas[1, 2]) ≡ (Base.OneTo(2), Base.OneTo(1))
    @test @inferred(bas[2, 2]) ≡ (Base.OneTo(3), Base.OneTo(1))
    @test @inferred(bas[1]) ≡ (Base.OneTo(2), Base.OneTo(3))
    @test @inferred(bas[2]) ≡ (Base.OneTo(3), Base.OneTo(3))
    @test @inferred(bas[3]) ≡ (Base.OneTo(2), Base.OneTo(1))
    @test @inferred(bas[4]) ≡ (Base.OneTo(3), Base.OneTo(1))

    bas2 = @inferred (x -> eachblockaxes(x, 2))(A)
    @test bas2 == [Base.OneTo(3), Base.OneTo(1)]
    @test length(bas2) ≡ 2
    @test size(bas2) ≡ (2,)
    @test @inferred(eltype(bas2)) ≡ Base.OneTo{Int}
    @test @inferred(bas2[1]) ≡ Base.OneTo(3)
    @test @inferred(bas2[2]) ≡ Base.OneTo(1)
    @test @inferred((x -> eachblockaxes(x, 3))(A)) == [Base.OneTo(1)]

    V = mortar([[2, 3], [4, 5, 6]])
    @test @inferred(eachblockaxes(V)) == [(Base.OneTo(2),), (Base.OneTo(3),)]
    @test @inferred((x -> eachblockaxes(x, 1))(V)) == [Base.OneTo(2), Base.OneTo(3)]
    @test @inferred((x -> eachblockaxes(x, 2))(V)) == [Base.OneTo(1)]
end

@testset "eachblockaxes1" begin
    v = Array(reshape(1:20, (5, 4)))
    A = BlockArray(v, [2, 3], [3, 1])
    bas = @inferred(eachblockaxes1(A))
    @test bas == [Base.OneTo(2), Base.OneTo(3)]
    @test @inferred(length(bas)) ≡ 2
    @test @inferred(size(bas)) ≡ (2,)
    @test @inferred(eltype(bas)) ≡ Base.OneTo{Int}
    @test @inferred(bas[1]) ≡ Base.OneTo(2)
    @test @inferred(bas[2]) ≡ Base.OneTo(3)

    @test @inferred(eachblockaxes1(mortar([[2, 3], [4, 5, 6]]))) == [Base.OneTo(2), Base.OneTo(3)]
    @test @inferred(eachblockaxes1(fill(2))) == [Base.OneTo(1)]
end

end # module
