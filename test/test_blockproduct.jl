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
    for i in blockaxes(AB,1)
        for j in blockaxes(AB,2)
            @test size(AB[i, j]) == (mi[Int(i)]*pi[Int(i)], ni[Int(j)]*qi[Int(j)])
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
    for i in blockaxes(A,1)
        for j in blockaxes(A,2)
            A[i, j] .*= Int(i)+Int(j)
        end
    end

    for i in blockaxes(B,1)
        for j in blockaxes(B,2)
            B[i, j] .*= Int(i)+Int(j)+10
        end
    end

    AB = khatri_rao(A, B)

    for i in blockaxes(AB,1)
        for j in blockaxes(AB,2)
            @test AB[i, j] ≈ (Int(i)+Int(j))*(Int(i)+Int(j)+10)*ones(mi[Int(i)]*pi[Int(i)], ni[Int(j)]*qi[Int(j)])
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

@testset "blockkron" begin
    a = [1,2]
    b = [3,4,5]
    k = blockkron(a,b)
    @test k == kron(a,b)
    @test blocksize(k) == size(a)
    @test k[Block(1)] == a[1]*b
    @test k[Block(2)] == a[2]*b
    c = 6:8
    @test blockkron(a,b,c) == kron(a,b,c)

    A = randn(2,3)
    B = randn(3,4)
    K = blockkron(A,B)
    @test K == kron(A,B)
    @test blocksize(K) == size(A)
    @test K[Block(1,1)] == A[1,1]*B
    @test K[Block(2,3)] == A[2,3]*B
    C = randn(2,5)
    @test blockkron(A,B,C) == kron(A,B,C)
end