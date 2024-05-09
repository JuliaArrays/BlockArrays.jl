module TestBlockDeque

using BlockArrays, Test

@testset "block dequeue" begin
    @testset "blockappend!(::BlockVector, _)" begin
        @testset for compatible in [false, true],
            srctype in [:BlockVector, :PseudoBlockVector, :PseudoBlockVector2, :Vector]

            dest = mortar([[1, 2, 3], [4, 5]])

            # Create `src` array:
            if compatible
                T = Int
            else
                T = Float64
            end
            if srctype === :BlockVector
                src = mortar([T[6, 7], T[8, 9]])
            elseif srctype === :PseudoBlockVector
                src = PseudoBlockVector(T[6:9;], [4])
            elseif srctype === :PseudoBlockVector2
                src = PseudoBlockVector(T[6:9;], [2, 2])
            elseif srctype === :Vector
                src = T[6:9;]
            else
                error("Unknown srctype = $srctype")
            end

            @test blockappend!(dest, src) === dest
            @test dest == 1:9

            @test dest[Block(1)] == [1, 2, 3]
            @test dest[Block(2)] == [4, 5]
            if blocklength(src) == 2
                @test dest[Block(3)] == [6, 7]
                @test dest[Block(4)] == [8, 9]
            elseif blocklength(src) == 1
                @test dest[Block(3)] == 6:9
            else
                error("Unexpected: blocklength(src) = ", blocklength(src))
            end

            src[1] = 666
            if compatible && srctype !== :PseudoBlockVector2
                @test dest[6] == 666
            else
                @test dest[6] == 6
            end
        end

        @testset "empty blocks" begin
            dest = mortar([[1, 2, 3], [4, 5]])
            @test blockappend!(dest, mortar([Int[]])) === dest == 1:5
            @test blocklength(dest) == 3
            @test blockappend!(dest, mortar([Int[], Int[]])) === dest == 1:5
            @test blocklength(dest) == 5
        end
    end

    @testset "blockpush!(::BlockVector, _)" begin
        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, [6]) === dest == 1:6
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, [6.0]) === dest == 1:6
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, Int[]) === dest == 1:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, (6, 7.0)) === dest == 1:7
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, (x for x in 6:7 if iseven(x))) === dest == 1:6
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpush!(dest, [6], Int[], 7:8) === dest == 1:8
        @test blocklength(dest) == 5
    end

    @testset "blockpushfirst!(::BlockVector, _)" begin
        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, [0]) === dest == 0:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, [0.0]) === dest == 0:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, Int[]) === dest == 1:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, (-1, 0.0)) === dest == -1:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, (x for x in -1:0 if iseven(x))) === dest == 0:5
        @test blocklength(dest) == 3

        dest = mortar([[1, 2, 3], [4, 5]])
        @test blockpushfirst!(dest, [-2], Int[], -1:0) === dest == -2:5
        @test blocklength(dest) == 5
    end

    @testset "blockpop!(::BlockVector, _)" begin
        A = mortar([[1, 2, 3], [4, 5]])
        @test blockpop!(A) == 4:5
        @test A == 1:3
        @test A[Block(1)] == 1:3
    end

    @testset "blockpopfirst!(::BlockVector, _)" begin
        A = mortar([[1, 2, 3], [4, 5]])
        @test blockpopfirst!(A) == 1:3
        @test A == 4:5
        @test A[Block(1)] == 4:5
    end

    @testset "append!(::BlockVector, _)" begin
        @testset "$label" for (label, itr) in [
            "UnitRange" => 6:9,
            "BlockVector" => mortar([[6, 7], [8, 9]]),
            "with length" => (x + 0 for x in 6:9),
            "no length" => (x for x in 6:9 if x > 0),
        ]
            dest = mortar([[1, 2, 3], [4, 5]])
            @test append!(dest, itr) === dest
            @test dest == 1:9
            @test dest[Block(1)] == [1, 2, 3]
            @test dest[Block(2)] == 4:9
        end
    end

    @testset "push!" begin
        A = mortar([[1, 2, 3], [4, 5]])
        push!(A, 6)
        push!(A, 7, 8, 9)
        @test A == 1:9
    end

    @testset "pushfirst!" begin
        A = mortar([[1, 2, 3], [4, 5]])
        pushfirst!(A, 0)
        pushfirst!(A, -3, -2, -1)
        @test A == -3:5
    end

    @testset "pop!" begin
        A = mortar([[1, 2, 3], [4, 5]])
        B = []
        while !isempty(A)
            push!(B, pop!(A))
        end
        @test A == []
        @test B == 5:-1:1

        @testset "empty blocks" begin
            B = BlockArray([1:6;], [1,2,3,0,0])
            @test pop!(B) == 6
            @test B == 1:5
            @test !any(isempty, blocks(B))
            @test blocklengths(axes(B,1)) == [1,2,2]
            @test blocksizes(B) == [(1,), (2,), (2,)]
        end
    end

    @testset "popfirst!" begin
        A = mortar([[1, 2, 3], [4, 5]])
        B = []
        while !isempty(A)
            push!(B, popfirst!(A))
        end
        @test A == []
        @test B == 1:5

        A = BlockArray([1:6;], [2,2,2])
        @test popfirst!(A) == 1
        @test A == 2:6
        @test blocklengths(axes(A,1)) == [1,2,2]
        @test blocksizes(A) == [(1,), (2,), (2,)]

        @testset "empty blocks" begin
            B = BlockArray([1:6;], [0,0,1,2,3])
            @test popfirst!(B) == 1
            @test B == 2:6
            @test blocklengths(axes(B,1)) == [2,3]
            @test blocksizes(B) == [(2,), (3,)]
            @test !any(isempty, blocks(B))
        end
    end
end

end # module
