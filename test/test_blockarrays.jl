module TestBlockArrays

using SparseArrays, BlockArrays, FillArrays, LinearAlgebra, Test, OffsetArrays, Images
import BlockArrays: _BlockArray, blockcollect

const Fill = FillArrays.Fill

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

@testset "Block/BlockedArray" begin
    @testset "block constructors" begin
        @testset "BlockArray Constructors" begin
            ret = BlockArray{Float64}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockVector{Float64}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64,1,Vector{Vector{Float64}}}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64,1,Vector{OffsetVector{Float64,Vector{Float64}}}}(undef, 1:3)
            fill!(ret, 0)
            @test blocks(ret) isa Vector{OffsetVector{Float64,Vector{Float64}}}
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64,1,
                        OffsetVector{OffsetVector{Float64,Vector{Float64}},
                            Vector{OffsetVector{Float64,Vector{Float64}}}}}(undef, 1:3)
            fill!(ret, 0)
            @test blocks(ret) isa OffsetVector{OffsetVector{Float64,Vector{Float64}},
                                    Vector{OffsetVector{Float64,Vector{Float64}}}}
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64}(undef, (blockedrange(1:3),))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockVector{Float64}(undef, (blockedrange(1:3),))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64,1,Vector{Vector{Float64}}}(undef, (blockedrange(1:3),))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ax = blockedrange(1:3)
            ret = BlockArray{Float64,1,Vector{Vector{Float64}},Tuple{typeof(ax)}}(undef, (ax,))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float64,1,Vector{Vector{Float64}},Tuple{Base.OneTo{Int}}}(undef, (3,))
            fill!(ret, 0)
            @test size(ret) == (3,)
            @test all(iszero, ret)

            ret = BlockArrays._BlockArray([[0.0],[0.0,0.0],[0.0,0.0,0.0]], 1:3)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArrays._BlockArray([[0.0],[0.0,0.0],[0.0,0.0,0.0]], (blockedrange(1:3),))
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArrays._BlockArray(Vector[[0.0],[0.0,0.0],[0.0,0.0,0.0]], (blockedrange(1:3),))
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockArray{Float32}(undef_blocks, 1:3)
            @test eltype(ret.blocks) == Vector{Float32}
            @test_throws UndefRefError ret.blocks[1]

            ret = BlockVector{Float32}(undef_blocks, 1:3)
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
            @test size(ret) == (6,6)
            @test all(iszero, ret)

            A = [1,2,3,4,5,6]
            @test A == BlockArray(A, 1:3) == BlockArray{Int}(A, 1:3) ==
                BlockArray(A, (blockedrange(1:3),)) == BlockArray{Int}(A, (blockedrange(1:3),)) ==
                BlockArray{Float64}(A, 1:3)

            #test that Array(::BlockArray) always returns an Array
            S = spzeros(2,1)
            B = mortar(fill(S,2,2))
            A = Array(B)
            @test A isa Matrix

            # test that BlockArrays may be created from immutable arrays
            B = BlockArray(reshape(1:9,3,3), [2,1], [2,1])
            @test blocklengths.(axes(B)) == ([2,1], [2,1])
            @test blocksizes(B) == [(2,2) (2,1); (1,2) (1,1)]
            @test B == reshape([1:9;],3,3)
            @test blocks(B) isa Matrix{Matrix{Int}}

            @testset "zeros/ones" begin
                br = blockedrange(2:3)
                z = zeros(Float64, br)
                @test all(iszero, z)
                @test axes(z) == (br,)
                o = ones(Float64, br)
                @test all(isone, o)
                @test axes(o) == (br,)
            end

            # non-Int block lengths
            blocklen = big(10)^30
            blks = [Fill(1.0, blocklen), Fill(2.0, blocklen)]
            ret = BlockArray{Float64,1,typeof(blks)}(undef_blocks, [blocklen,blocklen])
            ret[Block(1)] = blks[1]
            ret[Block(2)] = blks[2]
            @test size(ret) == (2blocklen,)
            @test blocksize(ret) == (2,)
            @test blocklengths.(axes(ret)) == ([blocklen,blocklen],)
            @test ret[Block(1)] == Fill(1.0, blocklen)
            @test ret[Block(2)] == Fill(2.0, blocklen)
            @test ret[1] == 1.0
            @test ret[blocklen + 1] == 2.0
        end

        @testset "BlockedArray constructors" begin
            ret = BlockedArray{Float64}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockedArray{Float64}(undef, (blockedrange(1:3),))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret2 = BlockedArray{Float64}(ret, (blockedrange(1:3),))
            @test size(ret2) == (6,)
            @test all(iszero, ret2)

            ret = BlockedVector{Float64}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockedArray{Float64}(undef, 1:3, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,6)
            @test all(iszero, ret)

            ret = BlockedArray{Float64,1,Vector{Float64}}(undef, 1:3)
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ret = BlockedArray{Float64,1,Vector{Float64}}(undef, (blockedrange(1:3),))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            ax = blockedrange(1:3)
            ret = BlockedArray{Float64,1,Vector{Float64},Tuple{typeof(ax)}}(undef, (ax,))
            fill!(ret, 0)
            @test size(ret) == (6,)
            @test all(iszero, ret)

            A = [1,2,3,4,5,6]
            @test_throws BoundsError BlockedArray(A,10:20)
            @test A == BlockedArray(A, 1:3) == BlockedArray{Int}(A, 1:3) ==
                BlockedArray(A, (blockedrange(1:3),)) == BlockedArray{Int}(A, (blockedrange(1:3),)) ==
                BlockedArray{Float64}(A, 1:3)

            @testset "from arrays" begin
                v = [1,2,3]
                @test BlockedVector(v) == v
                @test BlockedArray(v) == v
                M = [1 2; 3 4]
                @test BlockedMatrix(M) == M
                @test BlockedArray(M) == M
            end

            # non-Int block lengths
            blocklen = big(10)^30
            ret = BlockedArray(1:2blocklen, [blocklen,blocklen])
            @test size(ret) == (2blocklen,)
            @test blocksize(ret) == (2,)
            @test blocklengths.(axes(ret)) == ([blocklen,blocklen],)
            @test ret[Block(1)] == 1:blocklen
            @test ret[Block(2)] == (blocklen+1):2blocklen
            @test ret[1] == 1
            @test ret[2blocklen] == 2blocklen
        end

        @testset "similar" begin
            ret = BlockArray{Float64}(undef, 1:3)
            @test similar(ret, Float64, (3,)) isa Vector
            @test similar(typeof(ret), axes(ret)) isa BlockArray
            @test similar(typeof(ret), (Base.OneTo(6),)) isa Array
            @test similar(Array{Float64}, axes(ret)) isa BlockedArray
            @test similar(Vector{Float64}, axes(ret)) isa BlockedArray
            @test similar(randn(5,5), Float64, axes(ret)) isa BlockedArray
            @test similar(ret, Float64, (Base.IdentityUnitRange(1:3),)) isa BlockArray

            ret = BlockedArray{Float64}(undef, 1:3)
            @test similar(ret, Float64, (blockedrange(1:3),)) isa BlockedArray
            @test similar(ret, Float64, 1, blockedrange(1:3)) isa BlockedArray
            @test similar(ret, Float64, 1, 2, blockedrange(1:3)) isa BlockedArray

            ret = BlockArray{Float64}(undef, 1:3, 1:3)
            @test similar(typeof(ret), axes(ret)) isa BlockMatrix
            @test similar(typeof(ret), (Base.OneTo(6),axes(ret,2))) isa BlockMatrix
            @test similar(typeof(ret), (1,axes(ret,2))) isa BlockMatrix
            @test similar(typeof(ret), (1,2,axes(ret,2))) isa BlockArray{<:Any,3}
            @test similar(ret, axes(ret)) isa BlockMatrix
            @test similar(ret, (Base.OneTo(6),axes(ret,2))) isa BlockMatrix
            @test similar(ret, (1,axes(ret,2))) isa BlockMatrix
            @test similar(ret, (1,2,axes(ret,2))) isa BlockArray{<:Any,3}
            @test similar(Array{Float64}, axes(ret)) isa BlockedArray
            @test similar(Vector{Float64}, axes(ret)) isa BlockedArray
            @test similar(Array{Float64}, (Base.OneTo(5), axes(ret,2))) isa BlockedArray
            @test similar(randn(5,5), Float64, axes(ret)) isa BlockedArray
            @test similar(randn(5,5), Float64, (Base.OneTo(5), axes(ret,2))) isa BlockedArray

            @test similar(randn(6,5), Float64, (blockedrange(1:3),3)) isa BlockedMatrix
            @test similar(randn(6,5), Float64, (3,blockedrange(1:3))) isa BlockedMatrix
            @test similar(randn(6,5), Float64, (3,4,blockedrange(1:3))) isa BlockedArray{<:Any,3}
            @test similar(typeof(view(randn(5),1:3)), (blockedrange(1:3),)) isa BlockedVector
            @test similar(view(randn(5),1:3), Int, (blockedrange(1:3),)) isa BlockedVector{Int}

            # Regression test for method ambiguity.
            A = Array{Float64}
            @test similar(A, blockedrange.((1:3,1:3,1:3))) isa BlockedArray{Float64,3}
            @test similar(A, blockedrange.((1:3,1:3,1:3,1:3))) isa BlockedArray{Float64,4}
            A = typeof(view(randn(4,4,4),[1,2,4],[1,2,4],[1,2,4]))
            @test similar(A, blockedrange.((1:3,1:3,1:3))) isa BlockArray{Float64,3}
            @test similar(A, blockedrange.((1:3,1:3,1:3,1:3))) isa BlockArray{Float64,4}

            b = BlockVector([1,2,3,4,5,6,7,8,9,10], (BlockedOneTo(5:5:10),))
            @test zero(b) isa typeof(b)
        end

        @testset "blockcollect" begin
            a = randn(6, 6)
            @test blockcollect(a) == a
            @test blockcollect(a) ≢ a
            @test blockcollect(a).blocks ≢ a
            # TODO: Maybe special case this to call `collect` and return a `Matrix`?
            @test blockcollect(a) isa BlockedMatrix{Float64,Matrix{Float64}}
            @test blockisequal(axes(blockcollect(a)), axes(a))
            @test blocksize(blockcollect(a)) == (1, 1)

            b = BlockedArray(randn(6, 6), [3, 3], [3, 3])
            @test blockcollect(b) == b
            @test blockcollect(b) ≢ b
            @test blockcollect(b).blocks ≢ b
            @test blockcollect(b) isa BlockedMatrix{Float64,Matrix{Float64}}
            @test blockisequal(axes(blockcollect(b)), axes(b))
            @test blocksize(blockcollect(b)) == (2, 2)

            c = BlockArray(randn(6, 6), [3, 3], [3, 3])
            @test blockcollect(c) == c
            @test blockcollect(c) ≢ c
            @test blockcollect(c) isa BlockedMatrix{Float64,Matrix{Float64}}
            @test blockisequal(axes(blockcollect(c)), axes(c))
            @test blocksize(blockcollect(c)) == (2, 2)
        end

        @test_throws DimensionMismatch BlockArray([1,2,3],[1,1])

        @testset "mortar" begin
            @testset for sizes in [(1:3,), (1:3, 1:4), (1:3, 1:4, 1:2)]
                dims = sum.(sizes)
                A = @inferred BlockArray(copy(reshape(1:prod(dims), dims)), sizes...)
                @test @inferred mortar(A.blocks) == A
                if length(dims) == 2
                    # compare with hvcat
                    rows = ntuple(_->length(sizes[2]), length(sizes[1]))
                    @test mortar(A.blocks) == hvcat(rows, permutedims(A.blocks)...)
                end
            end

            ret = @inferred mortar([spzeros(2), spzeros(3)])
            @test eltype(ret.blocks) <: SparseVector
            @test axes(ret) == (blockedrange([2, 3]),)

            ret = @inferred mortar(
                (spzeros(1, 3), spzeros(1, 4)),
                (spzeros(2, 3), spzeros(2, 4)),
                (spzeros(5, 3), spzeros(5, 4)),
            )

            a = Array(ret)
            @test a isa Array
            @test size(a) == (8, 7)
            @test all(iszero, a)
            @test eltype(ret.blocks) <: SparseMatrixCSC
            @test axes(ret) == blockedrange.(([1, 2, 5], [3, 4]))

            ret = @inferred mortar([[1, 2], [3, 4, 5]], (blockedrange([2, 3]),))
            @test eltype(ret) == Int
            @test axes(ret) == (blockedrange([2, 3]),)
            @test ret == 1:5

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

            @testset "sizes_from_blocks" begin
                blocks = reshape([rand(2,2), zeros(1,2),
                                  zeros(2,3), rand(1,3)], 2, 2);
                @test @inferred BlockArrays.sizes_from_blocks(blocks) == ([2,1], [2,3])
                blocks = reshape(
                    [rand(2,2), zeros(1,2), zeros(4,2),
                     zeros(2,3), rand(1,3), zeros(4,3),
                     zeros(2,1), zeros(1,1), rand(4,1)], 3, 3);
                @test @inferred BlockArrays.sizes_from_blocks(blocks) == ([2, 1, 4], [2, 3, 1])
            end

            t1 = (ones(Float16, 2,2), ones(Float16, 2,2))
            t2 = (ones(Float32, 2,2), ones(Float64, 2,2))
            M = @inferred mortar(t1, t2)
            @test M isa BlockMatrix{Float64}
            @test size(M) == (4,4)
            @test all(isone, M)
        end

        @testset "zero dim" begin
            zerodim = ones()
            r = blockedrange([1])
            @test view(zerodim) isa AbstractArray{Float64, 0}  #  check no type-piracy

            ret = BlockArray{Float64}(undef)
            @test ret isa BlockArray{Float64, 0}
            fill!(ret, 0)
            @test size(ret) == ()
            @test all(iszero, ret)
            @test ret[Block()] == zeros()
            @test ret[Block()[]] == 0
            @test ret[] == 0
            @test view(ret, Block()) == zeros()
            @test Array(ret) == zeros()
            ret[] = 1
            @test ret[] == 1
            @test view(ret) == ones()
            view(ret)[] = 0
            @test ret[] == 0

            ret = BlockArray(zeros())
            @test ret isa BlockArray{Float64, 0}
            @test size(ret) == ()
            @test all(iszero, ret)
            @test ret[Block()] == zeros()

            @test similar(ret) isa BlockArray{Float64, 0}
            @test similar(ret, Float32) isa BlockArray{Float32, 0}
            @test similar(ret, Float32, ()) isa BlockArray{Float32, 0}
            @test similar(ret, Float32, (r,)) isa BlockVector{Float32}
            @test similar(BlockArray(zeros(r)), Float32, ()) isa BlockArray{Float32, 0}

            ret = BlockArray(zeros(1,1))
            @test reshape(ret, ()) isa AbstractBlockArray{Float64, 0}  # may be BlockedArray
            @test size(reshape(ret, ())) == ()

            ret = BlockedArray{Float64}(undef)
            @test ret isa BlockedArray{Float64, 0}
            fill!(ret, 0)
            @test size(ret) == ()
            @test all(iszero, ret)
            @test ret[] == 0
            @test ret[Block()] == zeros()
            @test ret[Block()[]] == 0
            @test Array(ret) == zeros()
            ret[] = 1
            @test ret[] == 1
            @test view(ret) == ones()
            view(ret)[] = 0
            @test ret[] == 0

            ret = BlockedArray(zeros())
            @test size(ret) == ()
            @test all(iszero, ret)
            @test ret[Block()] == zeros()

            @test similar(ret) isa BlockedArray{Float64, 0}
            @test similar(ret, Float32) isa BlockedArray{Float32, 0}
            @test similar(ret, Float32, ()) isa BlockedArray{Float32, 0}
            @test similar(ret, Float32, (blockedrange([1]),)) isa BlockedVector{Float32}
            @test similar(zeros(r), Float32, ()) isa BlockedArray{Float32, 0}

            ret = BlockedArray(zeros(1,1))
            @test reshape(ret, ()) isa BlockedArray{Float64, 0}
            @test size(reshape(ret, ())) == ()
        end

        @testset "BlockVector" begin
            a_data = [1,2,3]
            a = BlockVector(a_data,[1,2])
            a[1] = 2
            @test a == [2,2,3]
            @test a_data == [1,2,3]
            @test a[Block(1), 1] == a[Block(1)] == [2]
            a = BlockVector(a_data,(blockedrange([1,2]),))
            a[1] = 2
            @test a == [2,2,3]
            @test a_data == [1,2,3]
            a = BlockedVector(a_data,[1,2])
            a[1] = 2
            @test a == [2,2,3]
            @test a_data == [2,2,3]
            a = BlockedVector(a_data,(blockedrange([1,2]),))
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
            a = BlockedMatrix(a_data,[1,1],[2])
            a[1] = 2
            @test a == [2 2; 3 4]
            @test a_data == [2 2; 3 4]
            a = BlockedMatrix(a_data, blockedrange.(([1,1],[2])))
            a[1] = 3
            @test a == [3 2; 3 4]
            @test a_data == [3 2; 3 4]
        end

        @testset "UniformScaling" begin
            B = BlockArray(I, fill(2,4), fill(2,5))
            @test B isa BlockMatrix{Bool}
            @test B == BlockMatrix(I, fill(2,4), fill(2,5)) ==
                        BlockArray(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        BlockMatrix(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        Matrix(I, 8, 10)

            B = BlockArray{Float64}(I, fill(2,4), fill(2,5))
            @test B isa BlockMatrix{Float64}
            @test B == BlockMatrix{Float64}(I, fill(2,4), fill(2,5)) ==
                        BlockArray{Float64}(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        BlockMatrix{Float64}(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        Matrix(I, 8, 10)

            B = BlockedArray(I, fill(2,4), fill(2,5))
            @test B isa BlockedMatrix{Bool}
            @test B == BlockedMatrix(I, fill(2,4), fill(2,5)) ==
                        BlockedArray(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        BlockedMatrix(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        Matrix(I, 8, 10)

            B = BlockedArray{Float64}(I, fill(2,4), fill(2,5))
            @test B isa BlockedMatrix{Float64}
            @test B == BlockedMatrix{Float64}(I, fill(2,4), fill(2,5)) ==
                        BlockedArray{Float64}(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        BlockedMatrix{Float64}(I, blockedrange.((fill(2,4), fill(2,5)))) ==
                        Matrix(I, 8, 10)
        end
    end

    @testset "block indexing" begin
        BA_1 = BlockArray(undef_blocks, Vector{Float64}, [1,2,3])
        @test Base.IndexStyle(typeof(BA_1)) == IndexCartesian()

        @test checkbounds(Bool, BA_1, Block(1))
        @test isnothing(checkbounds(BA_1, Block(1)))
        @test blockcheckbounds(Bool, BA_1, 1)
        @test isnothing(blockcheckbounds(BA_1, 1))
        @test checkbounds(Bool, BA_1, Block(2))
        @test isnothing(checkbounds(BA_1, Block(2)))
        @test blockcheckbounds(Bool, BA_1, 2)
        @test isnothing(blockcheckbounds(BA_1, 2))
        @test checkbounds(Bool, BA_1, Block(3))
        @test isnothing(checkbounds(BA_1, Block(3)))
        @test blockcheckbounds(Bool, BA_1, 3)
        @test isnothing(blockcheckbounds(BA_1, 3))
        @test !checkbounds(Bool, BA_1, Block(4))
        @test_throws BlockBoundsError checkbounds(BA_1, Block(4))
        @test !blockcheckbounds(Bool, BA_1, 4)
        @test_throws BlockBoundsError blockcheckbounds(BA_1, 4)

        @test checkbounds(Bool, BA_1, Block.(1:3))
        @test isnothing(checkbounds(BA_1, Block.(1:3)))
        @test blockcheckbounds(Bool, BA_1, 1:3)
        @test isnothing(blockcheckbounds(BA_1, 1:3))
        @test !checkbounds(Bool, BA_1, Block.(1:4))
        @test_throws BlockBoundsError checkbounds(BA_1, Block.(1:4))
        @test !blockcheckbounds(Bool, BA_1, 1:4)
        @test_throws BlockBoundsError blockcheckbounds(BA_1, 1:4)

        @test checkbounds(Bool, BA_1, [Block(1), Block(3)])
        @test isnothing(checkbounds(BA_1, [Block(1), Block(3)]))
        @test blockcheckbounds(Bool, BA_1, [1, 3])
        @test isnothing(blockcheckbounds(BA_1, [1, 3]))
        @test !checkbounds(Bool, BA_1, [Block(1), Block(4)])
        @test_throws BlockBoundsError checkbounds(BA_1, [Block(1), Block(4)])
        @test !blockcheckbounds(Bool, BA_1, [1, 4])
        @test_throws BlockBoundsError blockcheckbounds(BA_1, [1, 4])

        @test checkbounds(Bool, BA_1, Block(2)[2])
        @test isnothing(checkbounds(BA_1, Block(2)[2]))
        @test !checkbounds(Bool, BA_1, Block(2)[3])
        @test_throws BoundsError checkbounds(BA_1, Block(2)[3])
        @test !checkbounds(Bool, BA_1, Block(4)[2])
        @test_throws BoundsError checkbounds(BA_1, Block(4)[2])

        @test checkbounds(Bool, BA_1, Block(2)[1:2])
        @test isnothing(checkbounds(BA_1, Block(2)[1:2]))
        @test !checkbounds(Bool, BA_1, Block(2)[1:3])
        @test_throws BoundsError checkbounds(BA_1, Block(2)[1:3])

        @test checkbounds(Bool, BA_1, [Block(2)[2], Block(3)[3]])
        @test isnothing(checkbounds(BA_1, [Block(2)[2], Block(3)[3]]))
        @test !checkbounds(Bool, BA_1, [Block(2)[2], Block(2)[3]])
        @test_throws BoundsError checkbounds(BA_1, [Block(2)[2], Block(2)[3]])
        @test !checkbounds(Bool, BA_1, [Block(2)[2], Block(4)[2]])
        @test_throws BoundsError checkbounds(BA_1, [Block(2)[2], Block(4)[2]])

        a_1 = rand(2)
        BA_1[Block(2)] = a_1
        @test BA_1[BlockIndex(2, 1)] == a_1[1]
        @test BA_1[BlockIndex(2, 2)] == a_1[2]
        @test BA_1[Block(2)] == a_1
        @test BA_1[2] == a_1[1]

        @test_throws DimensionMismatch (BA_1[Block(3)] = rand(4))
        @test_throws BlockBoundsError blockcheckbounds(BA_1, 4)
        @test_throws BlockBoundsError BA_1[Block(4)]
        @test_throws BlockBoundsError blockcheckbounds(BA_1)
        @test_throws BlockBoundsError blockcheckbounds(BA_1, 4, 1)

        Bv = BlockArray(zeros(1))
        @test Bv[Block()] == Bv[] == 0
        @test Bv[Block(1)] == Bv
        @test Bv[Block(1,1)] == zeros(1,1)

        BA_2 = BlockArray(undef_blocks, Matrix{Float64}, [1,2], [3,4])
        a_2 = rand(1,4)
        BA_2[Block(1,2)] = a_2
        @test BA_2[Block(1,2)] == a_2
        BA_2[Block(1,2)] = a_2

        @test checkbounds(Bool, BA_2, Block(1,1))
        @test isnothing(checkbounds(BA_2, Block(1,1)))
        @test checkbounds(Bool, BA_2, Block(1), Block(1))
        @test isnothing(checkbounds(BA_2, Block(1), Block(1)))
        @test !checkbounds(Bool, BA_2, Block(1,3))
        @test_throws BlockBoundsError checkbounds(BA_2, Block(1,3))
        @test !checkbounds(Bool, BA_2, Block(1), Block(3))
        @test_throws BlockBoundsError checkbounds(BA_2, Block(1), Block(3))

        @test checkbounds(Bool, BA_2, BlockRange((1:2,1:2)))
        @test blockcheckbounds(Bool, BA_2, BlockRange((1:2,1:2)))
        @test isnothing(checkbounds(BA_2, BlockRange((1:2,1:2))))
        @test isnothing(blockcheckbounds(BA_2, BlockRange((1:2,1:2))))
        @test checkbounds(Bool, BA_2, Block.(1:2), Block.(1:2))
        @test checkbounds(Bool, BA_2, Block.([1,2]), Block.([1,2]))
        @test isnothing(checkbounds(BA_2, Block.(1:2), Block.(1:2)))
        @test isnothing(checkbounds(BA_2, Block.([1,2]), Block.([1,2])))
        @test blockcheckbounds(Bool, BA_2, 1:2, 1:2)
        @test blockcheckbounds(Bool, BA_2, [1,2], [1,2])
        @test isnothing(blockcheckbounds(BA_2, 1:2, 1:2))
        @test isnothing(blockcheckbounds(BA_2, Block.(1:2), Block.(1:2)))
        @test isnothing(blockcheckbounds(BA_2, [1,2], [1,2]))
        @test isnothing(blockcheckbounds(BA_2, Block.([1,2]), Block.([1,2])))

        @test !checkbounds(Bool, BA_2, BlockRange((1:2,1:3)))
        @test !blockcheckbounds(Bool, BA_2, BlockRange((1:2,1:3)))
        @test_throws BlockBoundsError checkbounds(BA_2, BlockRange((1:2,1:3)))
        @test_throws BlockBoundsError blockcheckbounds(BA_2, BlockRange((1:2,1:3)))
        @test !checkbounds(Bool, BA_2, Block.(1:2), Block.(1:3))
        @test !checkbounds(Bool, BA_2, Block.([1,2]), Block.([1,3]))
        @test_throws BlockBoundsError checkbounds(BA_2, Block.(1:2), Block.(1:3))
        @test_throws BlockBoundsError checkbounds(BA_2, Block.([1,2]), Block.([1,3]))
        @test !blockcheckbounds(Bool, BA_2, 1:2, 1:3)
        @test !blockcheckbounds(Bool, BA_2, [1,2], [1,3])
        @test_throws BlockBoundsError blockcheckbounds(BA_2, 1:2, 1:3)
        @test_throws BlockBoundsError blockcheckbounds(BA_2, Block.(1:2), Block.(1:3))
        @test_throws BlockBoundsError blockcheckbounds(BA_2, [1,2], [1,3])
        @test_throws BlockBoundsError blockcheckbounds(BA_2, Block.([1,2]), Block.([1,3]))

        @test checkbounds(Bool, BA_2, Block(1,1)[1,1])
        @test isnothing(checkbounds(BA_2, Block(1,1)[1,1]))
        @test checkbounds(Bool, BA_2, Block(1)[1], Block(1)[1])
        @test checkbounds(Bool, BA_2, Block(1,2)[1,2])
        @test !checkbounds(Bool, BA_2, Block(1,2)[2,2])
        @test checkbounds(Bool, BA_2, Block(2,2)[1:1,1:2])
        @test checkbounds(Bool, BA_2, Matrix(Block(2,2)[1:1,1:2]))
        @test isnothing(checkbounds(BA_2, Matrix(Block(2,2)[1:1,1:2])))
        @test checkbounds(Bool, BA_2, Block(1,2)[1:1,1:2])
        @test checkbounds(Bool, BA_2, Block(1)[1:1], Block(2)[1:2])
        @test !checkbounds(Bool, BA_2, Block(2,2)[1:3,1:2])
        @test !checkbounds(Bool, BA_2, Block(2)[1:3], Block(2)[1:2])
        @test checkbounds(Bool, BA_2, [Block(2)[1], Block(2)[2]], Block(2)[1:2])
        @test !checkbounds(Bool, BA_2, [Block(2)[1], Block(2)[3]], Block(2)[1:2])

        @test BA_2[1,5] == a_2[2]
        @test_throws DimensionMismatch BA_2[Block(1,2)] = rand(1,5)

        # linear block indexing
        @test blockcheckbounds(Bool, BA_2, 3)
        @test_throws BlockBoundsError blockcheckbounds(BA_2, 5)

        # trailing Block(1) indices
        BA_3 = BlockArray(undef_blocks, Matrix{Float64}, [1,3], [4])
        @test blockcheckbounds(Bool, BA_3, 1, 1)
        @test blockcheckbounds(Bool, BA_3, 2, 1)
        @test_throws BlockBoundsError blockcheckbounds(BA_3, 3, 1)
        @test_throws BlockBoundsError blockcheckbounds(BA_3, 1, 2)
        @test_throws BlockBoundsError blockcheckbounds(BA_3, 3, 2)

        BA_4 = BlockArray(zeros(2,2,1))
        @test blockcheckbounds(Bool, BA_4)
        @test blockcheckbounds(Bool, BA_4, 1)
        @test blockcheckbounds(Bool, BA_4, 1, 1)
        @test blockcheckbounds(Bool, BA_4, 1, 1, 1)
        @test blockcheckbounds(Bool, BA_4, 1, 1, 1, 1)
        @test_throws BlockBoundsError blockcheckbounds(BA_3, 1, 2)

        @testset for (T,F) in ((Fill, Fill(3,4,4)), (Ones, Ones(4,4)), (Zeros, Zeros(4,4)))
            P = BlockedArray(F, [1,3], [1,3])
            V = P[axes(P)...]
            @test V isa T
            @test V == F
            @test axes(P) == axes(V)
            @test blocks.(axes(P)) == blocks.(axes(V))
            V = P[axes(P,1), 1:2]
            @test V isa T
            @test size(V) == (size(P,1), 2)
            @test blocks(axes(V,1)) == blocks(axes(P,1))
            @test blocks(axes(V,2)) == blocks(1:2)
            V = P[1:2, axes(P,2)]
            @test V isa T
            @test size(V) == (2, size(P,2))
            @test blocks(axes(V,1)) == blocks(1:2)
            @test blocks(axes(V,2)) == blocks(axes(P,2))
        end
    end

    @testset "misc block tests" begin
        for BlockType in (BlockArray, BlockedArray)
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
            if BlockType == BlockedArray
                q2 = zero(q)
                copyto!(q2, view(BA_1, Block(1)))
                @test q2 == q
                @test_throws BoundsError copyto!(zeros(0), view(BA_1, Block(1)))
                fill!(q2, 0)
                copyto!(q2, view(BA_1, Block(1)))
                @test q2 == q

                @test Base.mightalias(BA_1, view(BA_1, Block(1,1)))
                @test_broken Base.mightalias(BA_1, axes(BA_1, 1))
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
            if BlockType == BlockedArray
                q2 = zero(q)
                copyto!(q2, view(BA_2, Block(1, 2)))
                @test q2 == q
                @test copyto!(zeros(1,5), view(BA_2, Block(1, 2))) == [BA_2[Block(1,2)] zeros(1,1)]
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
            if BlockType == BlockedArray
                q3 = zero(q)
                copyto!(q3, view(BA_3, Block(1, 2, 2)))
                @test q3 == q
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
        A = BlockedArray(rand(2,3), [1,1], [2,1])

        @test convert(AbstractMatrix{Float64}, A) ≡ convert(AbstractMatrix, A) ≡ A
        @test convert(AbstractArray{Float64}, A) ≡ convert(AbstractArray, A) ≡ A
        @test convert(AbstractMatrix{Float32}, A) == AbstractMatrix{Float32}(A)
        @test convert(AbstractArray{Float32}, A) == AbstractArray{Float32}(A)

        C = convert(BlockArray, A)
        @test C == A == BlockArray(A)
        @test eltype(C) == eltype(A)

        C = convert(BlockArray{Float32}, A)
        @test C ≈ A ≈ BlockArray(A)
        @test eltype(C) == Float32

        C = convert(BlockArray{Float32, 2}, A)
        @test C ≈ A ≈ BlockArray(A)
        @test eltype(C) == Float32

        Ã = BlockedArray(rand(2,3), Fill(1,2), [2,1])
        @test convert(typeof(A), Ã) == Ã

        @test BlockedArray(A, axes(Ã)) isa typeof(Ã)
        @test BlockedArray(A, axes(Ã)) == A


        A = BlockArray(rand(2,3), [1,1], [2,1])

        @test convert(AbstractMatrix{Float64}, A) ≡ convert(AbstractMatrix, A) ≡ A
        @test convert(AbstractArray{Float64}, A) ≡ convert(AbstractArray, A) ≡ A
        @test convert(AbstractMatrix{Float32}, A) == AbstractMatrix{Float32}(A)
        @test convert(AbstractArray{Float32}, A) == AbstractArray{Float32}(A)

        C = convert(BlockedArray, A)
        @test C == A == BlockedArray(A)
        @test eltype(C) == eltype(A)

        C = convert(BlockedArray{Float32}, A)
        @test C ≈ A ≈ BlockedArray(A)
        @test eltype(C) == Float32

        C = convert(BlockedArray{Float32, 2}, A)
        @test C ≈ A ≈ BlockedArray(A)
        @test eltype(C) == Float32

        @test convert(BlockArray, A) === A
        @test convert(BlockArray{Float64}, A) === A
        @test convert(BlockMatrix{Float64}, A) === A
        @test convert(BlockMatrix{Float64,Matrix{Matrix{Float64}}}, A) === A
    end

    @testset "string" begin
        buf = IOBuffer()
        A = BlockArray(rand(2,3), [1,1], [2,1]);
        summary(buf, A)
        s = String(take!(buf))
        @test s == summary(A)

        A = BlockArray(rand(4, 5), [1,3], [2,3]);
        Base.showerror(buf, BlockBoundsError(A, (3,2)))
        @test String(take!(buf)) == "BlockBoundsError: attempt to access $(summary(A)) at block index [3,2]"

        A = BlockedArray(rand(4, 5), [1,3], [2,3]);
        Base.showerror(buf, BlockBoundsError(A, (3,2)))
        @test String(take!(buf)) == "BlockBoundsError: attempt to access $(summary(A)) at block index [3,2]"
    end

    @testset "replstring" begin
        A = BlockArray(collect(1:4), [1,3])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 1\n ─\n 2\n 3\n 4"
        A = BlockedArray(collect(1:4), [1,3])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 1\n ─\n 2\n 3\n 4"
        A = BlockArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"
        A = BlockedArray(collect(reshape(1:16, 4, 4)), [1,3], [2,2])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 1  5  │   9  13\n ──────┼────────\n 2  6  │  10  14\n 3  7  │  11  15\n 4  8  │  12  16"
        A = BlockArray(collect(reshape(1:8, 2, 2, 2)), [1,1], [1,1], [1,1])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n[:, :, 1] =\n 1  3\n 2  4\n\n[:, :, 2] =\n 5  7\n 6  8"
        A = BlockedArray(collect(reshape(1:8, 2, 2, 2)), [1,1], [1,1], [1,1])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n[:, :, 1] =\n 1  3\n 2  4\n\n[:, :, 2] =\n 5  7\n 6  8"
        design = zeros(Int16,6,9);
        A = BlockArray(design,[6],[4,5])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0"
        A = BlockedArray(design,[6],[4,5])
        @test sprint(show, "text/plain", A) == "$(summary(A)):\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0\n 0  0  0  0  │  0  0  0  0  0"
        D = BlockedArray(Diagonal(1:3), [1,2], [2,1])
        @test sprint(show, "text/plain", D) == "$(summary(D)):\n 1  ⋅  │  ⋅\n ──────┼───\n ⋅  2  │  ⋅\n ⋅  ⋅  │  3"

        a = BlockArray{Int}(undef_blocks, [1,2])
        @test sprint(show, "text/plain", a) == "$(summary(a)):\n #undef\n ──────\n #undef\n #undef"
        B = BlockArray{Int}(undef_blocks, [1,2], [1,1])
        @test sprint(show, "text/plain", B) == "$(summary(B)):\n #undef  │  #undef\n ────────┼────────\n #undef  │  #undef\n #undef  │  #undef"
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
        A = BlockedArray{Float64}(undef, 1:3, 1:3)
        fill!(A, 1)
        @test strides(A) == (1, size(A,1))
        x = randn(size(A,2))
        y = similar(x)
        @test BLAS.gemv!('N', 2.0, A, x, 0.0, y) ≈ 2A*x
    end

    @testset "FillArrays interface" begin
        P = BlockedArray(Fill(3,4,4), [1,3], [1,3])
        @test P[1:3, 2:3] === Fill(3,3,2)
        @test P[1:3, 1] == Fill(3,3)
        @test P[2, 1:3] == Fill(3,3)
    end

    @testset "lmul!/rmul!" begin
        A = BlockedArray{Float64}(undef, 1:3)
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
        A = BlockedArray(randn(6), 1:3)
        B = copy(A)
        @test typeof(A) == typeof(B)
        @test axes(A) === axes(B)
        @test A == B
        B[1] = 2
        @test B[1] == 2
        @test A[1] ≠ 2

        A = BlockArray(randn(6), 1:3)
        B = copy(A)
        @test typeof(A) == typeof(B)
        @test axes(A) === axes(B)
        @test A == B
        B[1] = 2
        @test B[1] == 2
        @test A[1] ≠ 2
        @testset "copyto!" begin
            A = BlockedArray(randn(6), 1:3)
            B = BlockArray(randn(6), 1:3)
            @test copyto!(BlockArray{Float64}(undef, 1:3), A) == A
            @test copyto!(BlockedArray{Float64}(undef, 1:3), A) == A

            @test copyto!(BlockArray{Float64}(undef, 1:3), B) == B
            @test copyto!(BlockedArray{Float64}(undef, 1:3), B) == B
        end
    end

    @testset "const block size" begin
        N = 10
        A = mortar(fill([1,2], N), Fill(2,N))
        B = BlockedArray(vcat(fill([1,2], N)...),  Fill(2,N))
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
        @test reshape(A, Val(2)) isa BlockedArray{Int,2,Matrix{Int},Tuple{typeof(axes(A,1)),Base.OneTo{Int}}}
        @test reshape(A, Val(2)) == BlockedArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1)))
        @test reshape(A, (blockedrange(Fill(2,3)),))[Block(1)] == 1:2
        @test reshape(A, 2, 3) == reshape(A, Base.OneTo(2), 3) == reshape(Vector(A), 2, 3)
        @test reshape(A, 2, 3) == reshape(A, 2, :) == reshape(A, UInt(2), :)

        @test_throws DimensionMismatch reshape(A,3)

        A = BlockedArray(1:6, 1:3)
        @test reshape(A, Val(2)) isa typeof(BlockedArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1))))
        @test reshape(A, Val(2)) == BlockedArray(reshape(1:6,6,1), (blockedrange(1:3), Base.OneTo(1)))
        @test reshape(A, (blockedrange(Fill(2,3)),))[Block(1)] == 1:2
        @test reshape(A, 2, 3) == reshape(A, Base.OneTo(2), 3) == reshape(Vector(A), 2, 3)
        @test reshape(A, 2, 3) == reshape(A, 2, :) == reshape(A, UInt(2), :)
    end

    @testset "*" begin
        A = BlockArray(randn(6,6), 1:3,1:3)
        Ã = BlockedArray(A)
        b = randn(6)
        @test A*b isa BlockedVector{Float64}
        @test Ã*b isa BlockedVector{Float64}
        @test A*b ≈ Ã*b ≈ Matrix(A)*b
    end

    @testset "Blockindex" begin
        a = BlockedArray(randn(3), [1,2])
        @test a[Block(1)[1]] == a[1]
        @test view(a, Block(1)[1]) ≡ view(parent(a), 1)
        @test view(a, Block(1)[1]) == view(a, 1)
        @test a[Block(1)[1:1]] == a[1:1]

        A = BlockedArray(randn(3,3), [1,2], [1,2])
        @test A[Block(1)[1], Block(1)[1]] == A[Block(1,1)[1,1]] == A[1,1]
        # Regression test for #442
        @test view(A, Block(1)[1], Block(1)[1]) ≡ view(A, Block(1,1)[1,1]) ≡ view(parent(A), 1, 1)
        @test A[Block(1)[1:1], Block(1)[1:1]] == A[Block(1,1)[1:1,1:1]] == A[1:1,1:1]
        @test A[Block(1)[1:1], Block(1)[1]] == BlockArray(A)[Block(1)[1:1], Block(1)[1]] == A[1:1,1]
        @test A[Block(1)[1], Block(1)[1:1]] == BlockArray(A)[Block(1)[1], Block(1)[1:1]] == A[1,1:1]
    end

    @testset "Nested block indexing" begin
        va = BlockedArray(randn(4), [2,2])
        vb = BlockedArray(randn(4), [2,2])
        V = mortar([va,vb])
        @test V[Block(2)[Block(1)]] == view(V, Block(2)[Block(1)]) == V[Block(2)][Block(1)] == vb[Block(1)]
        @test V[Block(2)[Block(1)[2]]] == view(V, Block(2)[Block(1)[2]])[] == V[Block(2)][Block(1)[2]] == vb[Block(1)[2]]
        @test V[Block(2)[Block(1)[1:2]]] == view(V, Block(2)[Block(1)[1:2]]) == V[Block(2)][Block(1)[1:2]] == vb[Block(1)[1:2]]

        ma = BlockedArray(randn(4,4), [2,2], [2,2])
        mb = BlockedArray(randn(4,4), [2,2], [2,2])
        mc = BlockedArray(randn(4,4), [2,2], [2,2])
        md = BlockedArray(randn(4,4), [2,2], [2,2])
        M = mortar([[ma] [mc]; [mb] [md]])
        @test M[Block(2,2)[Block(1,1)]] == view(M, Block(2,2)[Block(1,1)]) == M[Block(2,2)][Block(1,1)] == md[Block(1,1)]
        @test M[Block(2,2)[Block(1,1)[2,2]]] == view(M, Block(2,2)[Block(1,1)[2,2]])[] == M[Block(2,2)][Block(1,1)[2,2]] == md[Block(1,1)[2,2]]
        @test M[Block(2,2)[Block(1,1)[1:2,2:2]]] == view(M, Block(2,2)[Block(1,1)[1:2,2:2]]) == M[Block(2,2)][Block(1,1)[1:2,2:2]] == md[Block(1,1)[1:2,2:2]]
    end
    @testset "BlockIndices" begin
        a = BlockedArray(randn(5), [2,3])
        @test a[Block(2)[[1,3]]] == a[[3,5]]
        A = BlockedArray(randn(5,5), [2,3], [2,3])
        @test A[Block(2,2)[[1,3],[2,3]]] == A[[3,5],[4,5]]
        @test A[Block(2,2)[[1,3],1:2]] == A[[3,5],3:4]
    end

    @testset "BlockIndexRange blocks" begin
        a = mortar([Block(1)[1:2], Block(3)[2:3]])
        @test a[Block(1)] === Block(1)[1:2]
        @test a[Block(2)] === Block(3)[2:3]
    end

    @testset "permutedims" begin
        for a in (BlockArray(randn(3), [1,2]), BlockedArray(randn(3), [1,2]))
            @test permutedims(a) == permutedims(Vector(a))
            blockisequal(axes(permutedims(a),2), axes(a,1))
        end

        for A in (BlockArray(randn(3,6), [1,2], 1:3), BlockedArray(randn(3,6), [1,2], 1:3))
            @test permutedims(A) == permutedims(Matrix(A))
            blockisequal(axes(permutedims(A)), axes(A))
        end
    end

    @testset "adjoint getindex" begin
        a = BlockVector(1:5, [2,1,1,1])
        @test similar(a', Int, 1, axes(a,1)) isa BlockMatrix
        @test (a')[:,Block.(1:2)] == transpose(a)[:,Block.(1:2)] == [1 2 3]
        @test (a')[:,Block.(1:2)] isa Adjoint
        @test transpose(a)[:,Block.(1:2)] isa Transpose
    end

    @testset "empty blocklengths" begin
        A = BlockVector{Float64}(undef,Int[])
        @test @inferred(isempty(blocklengths(axes(A,1))))
    end

    @testset "pretty-printing" begin
        v = Zeros(3)
        m = mortar([v])
        io = IOBuffer()
        Base.print_array(io, m)
        s1 = String(take!(io))
        Base.print_array(io, v)
        s2 = String(take!(io))
        @test s1 == s2

        d = Diagonal(Ones(2,2))
        m = mortar(reshape([d], 1, 1))
        Base.print_array(io, m)
        s1 = String(take!(io))
        Base.print_array(io, d)
        s2 = String(take!(io))
        @test s1 == s2
    end

    @testset "Array indexing" begin
        a = randn(6)
        A = randn(6,3)
        @test a[blockedrange(1:3)] isa BlockedVector
        @test A[blockedrange(1:3),:] isa BlockedMatrix
        @test A[:,blockedrange(1:2)] isa BlockedMatrix
        @test A[blockedrange(1:3),blockedrange(1:2)] isa BlockedMatrix
    end

    @testset "resize!" begin
        a = BlockedVector(collect(1:6), 1:3)
        b = resize!(a,Block(2))
        @test b == 1:3
        @test_throws BoundsError a[4] # length of a.blocks has changed
        c = resize!(b,Block(0))
        @test isempty(c)

        a = BlockVector(collect(1:6), 1:3)
        b = resize!(a,Block(2))
        @test b == 1:3
        @test_throws BoundsError a[4] # length of a.blocks has changed
        c = resize!(b,Block(0))
        @test isempty(c)
    end

    @testset "empty indexing of vectors" begin
        a = mortar([1:3, 2:6])
        @test size(a[:,Block.(1:0)]) == size(BlockedVector(a)[:,Block.(1:0)]) == (8,0)
        @test size(a[:,Block.(1:1)]) == size(BlockedVector(a)[:,Block.(1:1)]) == size(a[:,Block(1)]) == (8,1)
        @test_throws BoundsError a[:,Block.(1:2)]
        @test size(a[:,1]) == (8,)
    end

    @testset "Block-vector indexing (#184)" begin
        a = BlockArray(1:6, [1,2,2,1])
        @test a[Block.(2:3)] == a[collect(Block.(2:3))]

        for B in (BlockArray(I, fill(2,4), fill(2,5)), BlockedArray(I, fill(2,4), fill(2,5)))
            @test B[[Block(1),Block(2)], [Block(1),Block(2)]] == view(B, [Block(1),Block(2)], [Block(1), Block(2)]) == view(B, Block.(1:2), [Block(1), Block(2)])  == view(B, Block.(1:2), Block.(1:2))
            @test B[[Block(1),Block(3)], [Block(1), Block(5)]] == view(B, [Block(1),Block(3)], [Block(1), Block(5)])
        end
    end
    @testset "BlockIndex-vector indexing (#358)" begin
        a = BlockArray(randn(6, 6), [3, 3], [3, 3])
        @test a[[Block(1)[1:2], Block(2)[1:2]], [Block(1)[1:2], Block(2)[1:2]]] == [a[Block(1,1)[1:2,1:2]] a[Block(1,2)[1:2,1:2]]; a[Block(2,1)[1:2,1:2]] a[Block(2,2)[1:2,1:2]]]
        @test a[[Block(1)[1], Block(2)[2]], [Block(1)[1:2], Block(2)[1:2]]] == [a[Block(1)[1],Block(1)[1:2]]' a[Block(1)[1], Block(2)[1:2]]'; a[Block(2)[2],Block(1)[1:2]]' a[Block(2)[2], Block(2)[1:2]]']
    end
    @testset "Blocked block-vector indexing (#359)" begin
        for a in (BlockArray(randn(14, 14), 2:5, 2:5), BlockedArray(randn(14, 14), 2:5, 2:5))
            for I in (
                [Block.(1:2), Block.(3:4)],
                [[Block(1), Block(3)], [Block(2), Block(4)]],
                [[Block(1)[1:2], Block(3)[1:2]], [Block(2)[1:2], Block(4)[1:2]]],
                [[[Block(1)[1], Block(1)[2]], [Block(3)[1], Block(3)[2]]], [[Block(2)[1], Block(2)[2]], [Block(4)[1], Block(4)[2]]]],
            )
                b = a[I, I]
                for (i, j) in Iterators.product(1:length(I), 1:length(I))
                    @test a[I[i], I[j]] == b[Block(i), Block(j)]
                end
            end
        end
    end
end

end # module
