####################################
# The AbstractBlockArray interface #
####################################

"""
    abstract AbstractBlockArray{T, N} <: AbstractArray{T, N}

The abstract type that represents a blocked array. Types that implement
the `AbstractBlockArray` interface should subtype from this type.

** Typealiases **

* `AbstractBlockMatrix{T}` -> `AbstractBlockArray{T, 2}`

* `AbstractBlockVector{T}` -> `AbstractBlockArray{T, 1}`

* `AbstractBlockVecOrMat{T}` -> `Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}`
"""
abstract AbstractBlockArray{T, N} <: AbstractArray{T, N}
typealias AbstractBlockMatrix{T} AbstractBlockArray{T, 2}
typealias AbstractBlockVector{T} AbstractBlockArray{T, 1}
typealias AbstractBlockVecOrMat{T} Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}

block2string(b, s) = string(join(map(string,b), '×'), "-blocked ", Base.dims2string(s))
Base.summary(a::AbstractBlockArray) = string(block2string(nblocks(a), size(a)), " ", typeof(a))
Base.similar{T}(block_array::AbstractBlockArray{T}) = similar(block_array, T)
Base.linearindexing{BA <: AbstractBlockArray}(::Type{BA}) = Base.LinearSlow()

"""
    nblocks(A, [dim...])

Returns a tuple containing the number of blocks in a block array.  Optionally you can specify
the dimension(s) you want the number of blocks for.

```jlcon
julia> A =  BlockArray(rand(5,4,6), [1,4], [1,2,1], [1,2,2,1]);

julia> nblocks(A)
(2,3,4)

julia> nblocks(A, 2)
3

julia> nblocks(A, 3, 2)
(4,3)
```
"""
nblocks(block_array::AbstractBlockArray, i::Int) = nblocks(block_array)[i]

function nblocks{N}(block_array::AbstractBlockArray, i::Vararg{Int, N})
    if N == 0
        throw(error("nblocks(A) not implemented"))
    end
    b = nblocks(block_array)
    return ntuple(k-> b[i[k]], Val{N})
end


"""
    blocksize(A, inds...)

Returns a tuple containing the size of the block at block index `inds...`.

```jlcon
julia> A = BlockArray(rand(5,4,6), [1,4], [1,2,1], [1,2,2,1]);

julia> blocksize(A,1,3,2)
(1,1,2)

julia> blocksize(A,2,1,3)
(4,1,2)
```
"""
function blocksize{T, N}(X, A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw(error("blocksize for ", typeof(A), "is not implemented"))
end


"""
    getblock(A, inds...)

Returns the block at blockindex `inds...`. An alternative syntax is `A[Block(inds...)].
Throws a `BlockBoundsError` if this block is out of bounds.

```jlcon
julia> A = BlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 0.190705  0.798036  │  0.471299
 --------------------┼-----------
 0.770005  0.845003  │  0.0315575

julia> getblock(A, 2, 1)
1×2 Array{Float64,2}:
 0.770005  0.845003

julia> A[Block(1,2)]
1×1 Array{Float64,2}:
 0.471299
```
"""
function getblock{T, N}(X, A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw("getblock for ", typeof(A), "is not implemented")
end


"""
    getblock!(X, A, inds...)

Stores the block at blockindex `inds` in `X` and returns it. Throws a `BlockBoundsError` if the
attempted assigned block is out of bounds.

```jlcon
julia> A = PseudoBlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 0.2062    0.0238446  │  0.0505515
 ---------------------┼-----------
 0.744768  0.225364   │  0.23028

julia> x = zeros(1,2);

julia> getblock!(x, A, 2, 1);

julia> x
1×2 Array{Float64,2}:
 0.744768  0.225364
```
"""
function getblock!{T, N}(X, A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw("getblock! for ", typeof(A), "is not implemented")
end

"""
    setblock!(A, v, inds...)

Stores the block `v` in the block at block index `inds` in `A`. An alternative syntax is `A[Block(inds...)] = v`.
Throws a `BlockBoundsError` if this block is out of bounds.

```jlcon
julia> A = PseudoBlockArray(zeros(2,3), [1,1], [2,1]);

julia> setblock!(A, [1 2], 1,1);

julia> A[Block(2,1)] = [3 4];

julia> A
2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 1.0  2.0  │  0.0
 ----------┼-----
 3.0  4.0  │  0.0
```
"""
function setblock!{T, N}(A::AbstractBlockArray{T,N}, v, ::Vararg{Int, N})
    throw("setblock! for ", typeof(A), "is not implemented")
end

"""
    BlockBoundsError([A],[inds...])

Thrown when a block indexing operation into a block array, `A`, tried to access an out-of-bounds block, `inds`.
"""
immutable BlockBoundsError <: Exception
    a::Any
    i::Any
    BlockBoundsError() = new()
    BlockBoundsError(a::AbstractBlockArray) = new(a)
    BlockBoundsError(a::AbstractBlockArray, i::ANY) = new(a,i)
end

function Base.showerror(io::IO, ex::BlockBoundsError)
    print(io, "BlockBoundsError")
    if isdefined(ex, :a)
        print(io, ": attempt to access ")
            print(io, summary(ex.a))
        if isdefined(ex, :i)
            print(io, " at block index [")
            print_joined(io, ex.i, ',')
            print(io, ']')
        end
    end
end

"""
    blockcheckbounds(A, inds...)

Throw a `BlockBoundsError` if the specified block indexes are not in bounds for the given block array. Subtypes of `AbstractBlockArray` should
specialize this method if they need to provide custom block bounds checking behaviors.

```jlcon
julia> A = BlockArray(rand(2,3), [1,1], [2,1]);

julia> blockcheckbounds(A, 3,2)
ERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [3,2]
 in blockcheckbounds(::BlockArrays.BlockArray{Float64,2,Array{Float64,2}}, ::Int64, ::Int64)
 in eval(::Module, ::Any) at ./boot.jl:226
```
"""
function blockcheckbounds{T, N}(A::AbstractBlockArray{T, N}, i::Vararg{Int, N})
    n = nblocks(A)
    for (k, idx) in enumerate(i)
        if idx <= 0 || idx > n[k]
            throw(BlockBoundsError(A, i))
        end
    end
    return
end

"""
    full(A)

Returns the full array stored in `A`.
Full is here not used in the sense of sparse vs dense but in blocked vs unblocked.

```jlcon
julia> A = BlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 0.770528  0.396896  │  0.443308
 --------------------┼----------
 0.857069  0.403512  │  0.915934

julia> full(A)
2×3 Array{Float64,2}:
 0.770528  0.396896  0.443308
 0.857069  0.403512  0.915934
```
"""
function full(A::AbstractBlockArray) end


"""
    Block(inds...)

A `Block` is simply a wrapper around a set of indices so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the a block at that block index will be returned instead of
a single element.

```jlcon
julia> A = BlockArray(rand(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 0.190705  0.798036  │  0.471299
 --------------------┼-----------
 0.770005  0.845003  │  0.0315575

julia> A[Block(1,2)]
1×1 Array{Float64,2}:
 0.471299
```
"""
immutable Block{N}
    n::NTuple{N, Int}
end

Block{N}(n::Vararg{Int, N}) = Block{N}(n)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds Base.getindex{T}(block_arr::AbstractBlockArray{T,1}, block::Block{1}) = getblock(block_arr, block.n[1])
@propagate_inbounds Base.getindex{T}(block_arr::AbstractBlockArray{T,2}, block::Block{2}) = getblock(block_arr, block.n[1], block.n[2])
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
@propagate_inbounds Base.getindex{T,N}(block_arr::AbstractBlockArray{T,N}, block::Block{N}) = getblock(block_arr, block.n...)

# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv #
@propagate_inbounds Base.setindex!{T}(block_arr::AbstractBlockArray{T,1}, v, block::Block{1}) =  setblock!(block_arr, v, block.n[1])
@propagate_inbounds Base.setindex!{T}(block_arr::AbstractBlockArray{T,2}, v, block::Block{2}) =  setblock!(block_arr, v, block.n[1], block.n[2])
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #
@propagate_inbounds Base.setindex!{T,N}(block_arr::AbstractBlockArray{T,N}, v, block::Block{N}) =  setblock!(block_arr, v, block.n...)