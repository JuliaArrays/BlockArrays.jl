using BlockArrays, Test

@testset "Khatri Rao Product (size)" begin
    #A size
    m = 5
    n = 6

    #A block size
    mi = [3, 2]
    ni = [4, 1, 1]
    #B size
    p = 8
    q = 7
    
    #B block size
    pi = [5, 3]
    qi = [3, 2, 2]

    @assert sum(mi) == m
    @assert sum(ni) == n
    @assert sum(qi) == q
    @assert sum(pi) == p

    A = BlockArray(ones(m, n), mi, ni)
    B = BlockArray(ones(p, q), pi, qi)

    AB = khatri_rao(A, B)
    
    @test blocksize(AB) == blocksize(A)
    @test blocksize(AB) == blocksize(B)

    #Test: Size of resulting blocks
    for i in 1:blocksize(AB)[1]
        for j in 1:blocksize(AB)[2]
            @test size(AB[Block(i, j)]) == (mi[i]*pi[i], ni[j]*qi[j])
        end
    end
end

@testset "Khatri Rao Product (constant blocks)" begin
    #A size
    m = 5
    n = 6

    #A block size
    mi = [3, 2]
    ni = [4, 1, 1]
    #B size
    p = 8
    q = 7
    
    #B block size
    pi = [5, 3]
    qi = [3, 2, 2]

    @assert sum(mi) == m
    @assert sum(ni) == n
    @assert sum(qi) == q
    @assert sum(pi) == p

    A = BlockArray(ones(m, n), mi, ni)
    B = BlockArray(ones(p, q), pi, qi)

    #Test: Resulting values for a matrix of constant sub-blocks
    for i in 1:blocksize(A)[1]
        for j in 1:blocksize(A)[2]
            A[Block(i, j)] .*= i+j
        end
    end

    for i in 1:blocksize(B)[1]
        for j in 1:blocksize(B)[2]
            B[Block(i, j)] .*= i+j+10
        end
    end

    AB = khatri_rao(A, B)

    for i in 1:blocksize(AB)[1]
        for j in 1:blocksize(AB)[2]
            @test AB[Block(i, j)] ≈ (i+j)*(i+j+10)*ones(mi[i]*pi[i], ni[j]*qi[j])
        end
    end

end

@testset "Khatri Rao Product (wrong blocksize)" begin

    A = BlockArray(ones(1, 2), [1], [1,1])
    B = BlockArray(ones(2, 2), [1,1], [1,1])

    @test_throws AssertionError khatri_rao(A, B)
end

@testset "Khatri Rao Product (Matrix)" begin

    A = ones(1, 2)
    B = ones(2, 2)

    @test khatri_rao(A, B) ≈ kron(A, B)
end

