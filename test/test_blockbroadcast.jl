using BlockArrays, FillArrays, LazyArrays, Test

@testset "broadcast" begin
    @testset "BlockArray" begin
        A = BlockArray(randn(6), 1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.BlockStyle{1}()
        bc = Base.broadcasted(exp,A)
        @test axes(A) === axes(bc) === axes(similar(bc, Float64))
        @test exp.(A) == exp.(Vector(A))
        @test axes(A) === axes(exp.(A))

        @test A+A isa BlockArray
        @test axes(A + A,1).lasts == axes(A .+ A,1).lasts == axes(A,1).lasts
        @test axes(A .+ 1,1).lasts == axes(A,1).lasts

        A = BlockArray(randn(6,6), 1:3,1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.BlockStyle{2}()

        @test exp.(A) == exp.(Matrix(A))
        @test axes(A) == axes(exp.(A))

        @test axes(A + A) == axes(A .+ A) == axes(A)
        @test axes(A .+ 1) == axes(A)
    end

    @testset "PseudoBlockArray" begin
        A = PseudoBlockArray(randn(6), 1:3)

        @test BlockArrays.BroadcastStyle(typeof(A)) == BlockArrays.PseudoBlockStyle{1}()


        @test exp.(A) == exp.(Vector(A))
        @test axes(A,1).lasts == axes(exp.(A),1).lasts

        @test A+A isa PseudoBlockArray
        @test axes(A + A,1).lasts == axes(A .+ A,1).lasts == axes(A,1).lasts
        @test axes(A .+ 1,1).lasts == axes(A,1).lasts

        B = PseudoBlockArray(randn(6,6), 1:3,1:3)

        @test BlockArrays.BroadcastStyle(typeof(B)) == BlockArrays.PseudoBlockStyle{2}()

        @test exp.(B) == exp.(Matrix(B))
        @test axes(B) == axes(exp.(B))

        @test axes(B + B) == axes(B .+ B) == axes(B)
        @test axes(B .+ 1) == axes(B)
        @test axes(A .+ 1 .+ B) == axes(B)
        @test A .+ 1 .+ B == Vector(A) .+ 1 .+ B == Vector(A) .+ 1 .+ Matrix(B)
    end

    @testset "Mixed" begin
        A = BlockArray(randn(6), 1:3)
        B = PseudoBlockArray(randn(6), 1:3)

        @test A + B isa BlockArray
        @test B + A isa BlockArray

        @test axes(A + B,1).lasts == axes(A,1).lasts

        C = randn(6)

        @test A + C isa BlockVector{Float64}
        @test C + A isa BlockVector{Float64}
        @test B + C isa PseudoBlockVector{Float64}
        @test C + B isa PseudoBlockVector{Float64}

        @test blocksize(A+C) == blocksize(C+A) == blocksize(A)
        @test blocksize(B+C) == blocksize(C+B) == blocksize(B)

        A = BlockArray(randn(6,6), 1:3, 1:3)
        D = Diagonal(ones(6))
        @testset "avoid stack overflow in _generic_block_broadcast" begin
            @test Base.BroadcastStyle(typeof(view(D, Block(1)[1:2], Block(1)[1:2]))) isa Base.Broadcast.DefaultArrayStyle{2}
        end
        @test blocksize(A + D) == blocksize(A)
        @test blocksize(B .+ D) == (3,1)
    end

    @testset "Mixed block sizes" begin
        A = BlockArray(randn(6), 1:3)
        B = BlockArray(randn(6), fill(2,3))
        @test blocksize(A+B) == (5,)

        A = BlockArray(randn(6,6), 1:3, 1:3)
        B = BlockArray(randn(6,6), fill(2,3), fill(3,2))

        @test blocksize(A+B) == (5,3)
    end

    @testset "UnitRange" begin
        n = 3
        x = mortar([1:4n, 1:n])
        @test eltype(x.blocks) <: UnitRange
        y = 1:length(x)
        z = randn(size(x))
        x2 = vcat(x.blocks...)
        y2 = copy(y)
        z2 = copy(z)
        @test (@. z = x + y + z; z) == (@. z2 = x2 + y2 + z2; z2)
    end

    @testset "Special broadcast" begin
        v = mortar([1:3,4:7])
        @test broadcast(+, v) isa BlockVector{Int,Vector{UnitRange{Int}}}
        @test broadcast(+, v) == v
        @test broadcast(-, v) isa BlockVector{Int,Vector{StepRange{Int,Int}}}
        @test broadcast(-, v) == -v == -Vector(v)
        @test broadcast(+, v, 1) isa BlockVector{Int,Vector{UnitRange{Int}}}
        @test broadcast(+, v, 1) == Vector(v).+1
        @test broadcast(*, 2, v) isa BlockVector{Int,Vector{StepRange{Int,Int}}}
        @test broadcast(*, 2, v) == 2Vector(v)
    end

    @testset "special axes" begin
        A = BlockArray(randn(6), Ones{Int}(6))
        B = BlockArray(randn(6), Ones{Int}(6))
        @test axes(A+B,1) === axes(A,1)

        C = BlockArray(randn(6), (BlockArrays._BlockedUnitRange(1,2:6),))
        @test axes(A+C,1) === BlockArrays._BlockedUnitRange(1,1:6)
    end

    @testset "Views" begin
        A = BlockArray(randn(6), 1:3)
        @test Base.BroadcastStyle(typeof(view(A, Block(2)))) isa Base.Broadcast.DefaultArrayStyle{1}
        V = view(A, Block.(2:3))
        @test Base.BroadcastStyle(typeof(V)) isa BlockArrays.BlockStyle{1}
        @test V .+ 1 isa BlockArray
        @test 1 .+ V isa BlockArray
        @test V .+ 1 == 1 .+ V == A[Block.(2:3)] .+ 1
        @test -V isa BlockArray
        @test -V == -A[Block.(2:3)]
    end

    @testset "Fill broadcast" begin
        A = BlockArray(randn(6), 1:3)
        @test blockisequal(axes(A .* Zeros(6)), axes(A .* zeros(6)))
        @test blockisequal(axes(A .* Ones(6)), axes(A .* ones(6)))
    end

    @testset "recurrences" begin
        N = 1000
        n = mortar(BroadcastArray(Fill,Base.OneTo(N),Base.OneTo(N)))
        k = mortar(BroadcastArray(Base.OneTo,Base.OneTo(N)))

        @test view(n, Block(5)) ≡ Fill(5,5)
        @test view(k,Block(5)) ≡ Base.OneTo(5)
        a = b = c = 0.0
        # for some reason the following was causing major slowdown. I think it 
        # went pass a limit to Base.Broadcast.flatten which caused `bc.f` to have a strange type.
        # bc = Base.Broadcast.instantiate(Base.broadcasted(/, Base.broadcasted(*, k, Base.broadcasted(-, Base.broadcasted(-, k, n), a)), Base.broadcasted(+, 2k, b+c-1)))

        bc = Base.Broadcast.instantiate(Base.broadcasted((k,n,a,b,c) -> k * (k-n-a) / (2k+(b+c-1)), k, n, a, b, c))
        @test axes(n,1) ≡ axes(k,1) ≡ axes(bc)[1] ≡ blockedrange(Base.OneTo(N))
        u = (k .* (k .- n .- a) ./ (2k .+ (b+c-1)))
        @test u == (Vector(k) .* (Vector(k) .- Vector(n) .- a) ./ (2Vector(k) .+ (b+c-1)))
        @test copyto!(u, bc) == (k .* (k .- n .- a) ./ (2k .+ (b+c-1)))
        @test @allocated(copyto!(u, bc)) ≤ 1000 
        # not clear why allocatinos so high: all allocations are coming from checking
        # axes

        u = PseudoBlockArray{Float64}(undef, collect(1:N))
        @test copyto!(u, bc) == (k .* (k .- n .- a) ./ (2k .+ (b+c-1)))
        @test @allocated(copyto!(u, bc)) ≤ 1000
    end

    @testset "type inferrence" begin
        u = BlockArray(randn(5), [2,3]);
        @inferred(copyto!(similar(u), Base.broadcasted(exp, u)))
        @test exp.(u) == exp.(Vector(u))
    end

    @testset "adjtrans" begin
        a = PseudoBlockArray(randn(6), [2,3])
        b = BlockArray(a)
        
        @test Base.BroadcastStyle(typeof(a')) isa BlockArrays.PseudoBlockStyle{2}
        @test Base.BroadcastStyle(typeof(b')) isa BlockArrays.BlockStyle{2}

        @test exp.(a') == exp.(b') == exp.(Vector(a)')
        @test exp.(a') isa PseudoBlockArray
        @test exp.(b') isa BlockArray
    end

    @testset "subarray" begin
        @testset "vector" begin
            a = PseudoBlockArray(randn(6), [2,3])
            b = BlockArray(a)

            v = view(a,Block.(1:2))
            w = view(b,Block.(1:2))
            
            @test Base.BroadcastStyle(typeof(v)) isa BlockArrays.PseudoBlockStyle{1}
            @test Base.BroadcastStyle(typeof(w)) isa BlockArrays.BlockStyle{1}

            @test exp.(v) == exp.(w) == exp.(Vector(v))
            @test exp.(v) isa PseudoBlockArray
            @test exp.(w) isa BlockArray
        end

        @testset "matrix" begin
            A = PseudoBlockArray(randn(6,3), [2,3],[1,2])
            B = BlockArray(A)

            v = view(A,1:3,Block.(1:2))
            w = view(B,1:3,Block.(1:2))
            
            @test Base.BroadcastStyle(typeof(v)) isa BlockArrays.PseudoBlockStyle{2}
            @test Base.BroadcastStyle(typeof(w)) isa BlockArrays.BlockStyle{2}

            @test exp.(v) == exp.(w) == exp.(Matrix(v))
            @test exp.(v) isa PseudoBlockArray
            @test exp.(w) isa BlockArray

            @test Base.BroadcastStyle(typeof(view(A,Block.(1:2),Block.(1:2)))) isa BlockArrays.PseudoBlockStyle{2}
            @test Base.BroadcastStyle(typeof(view(B,Block.(1:2),Block.(1:2)))) isa BlockArrays.BlockStyle{2}
        end
    end
end
