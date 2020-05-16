using BlockArrays, Test

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
end

@testset "popfirst!" begin
    A = mortar([[1, 2, 3], [4, 5]])
    B = []
    while !isempty(A)
        push!(B, popfirst!(A))
    end
    @test A == []
    @test B == 1:5
end
