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
abstract type AbstractBlockArray{T, N} <: AbstractArray{T, N} end
const AbstractBlockMatrix{T} = AbstractBlockArray{T, 2}
const AbstractBlockVector{T} = AbstractBlockArray{T, 1}
const AbstractBlockVecOrMat{T} = Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}

block2string(b, s) = string(join(map(string,b), '×'), "-blocked ", Base.dims2string(s))
Base.summary(a::AbstractBlockArray) = string(block2string(nblocks(a), size(a)), " ", typeof(a))
Base.similar{T}(block_array::AbstractBlockArray{T}) = similar(block_array, T)
Base.IndexStyle(::Type{<:AbstractBlockArray}) = IndexCartesian()

"""
    nblocks(A, [dim...])

Returns a tuple containing the number of blocks in a block array.  Optionally you can specify
the dimension(s) you want the number of blocks for.

```jldoctest
julia> A =  BlockArray(rand(5,4,6), [1,4], [1,2,1], [1,2,2,1]);

julia> nblocks(A)
(2, 3, 4)

julia> nblocks(A, 2)
3

julia> nblocks(A, 3, 2)
(4, 3)
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

```jldoctest
julia> A = BlockArray(rand(5, 4, 6), [1, 4], [1, 2, 1], [1, 2, 2, 1]);

julia> blocksize(A, 1, 3, 2)
(1, 1, 2)

julia> blocksize(A, 2, 1, 3)
(4, 1, 2)
```
"""
function blocksize{T, N}(X, A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw(error("blocksize for ", typeof(A), "is not implemented"))
end


"""
    getblock(A, inds...)

Returns the block at blockindex `inds...`. An alternative syntax is `A[Block(inds...)].
Throws a `BlockBoundsError` if this block is out of bounds.

```jldoctest
julia> v = Array(reshape(1:6, (2, 3)))
2×3 Array{Int64,2}:
 1  3  5
 2  4  6

julia> A = BlockArray(v, [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.BlockArray{Int64,2,Array{Int64,2}}:
 1  3  │  5
 ------┼---
 2  4  │  6

julia> getblock(A, 2, 1)
1×2 Array{Int64,2}:
 2  4

julia> A[Block(1, 2)]
1×1 Array{Int64,2}:
 5
```
"""
function getblock{T, N}(A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw("getblock for ", typeof(A), "is not implemented")
end


"""
    getblock!(X, A, inds...)

Stores the block at blockindex `inds` in `X` and returns it. Throws a `BlockBoundsError` if the
attempted assigned block is out of bounds.

```jldoctest
julia> A = PseudoBlockArray(ones(2, 3), [1, 1], [2, 1])
2×2-blocked 2×3 BlockArrays.PseudoBlockArray{Float64,2,Array{Float64,2}}:
 1.0  1.0  │  1.0
 ----------┼-----
 1.0  1.0  │  1.0

julia> x = zeros(1, 2);

julia> getblock!(x, A, 2, 1);

julia> x
1×2 Array{Float64,2}:
 1.0  1.0
```
"""
function getblock!{T, N}(X, A::AbstractBlockArray{T,N}, ::Vararg{Int, N})
    throw("getblock! for ", typeof(A), "is not implemented")
end

"""
    setblock!(A, v, inds...)

Stores the block `v` in the block at block index `inds` in `A`. An alternative syntax is `A[Block(inds...)] = v`.
Throws a `BlockBoundsError` if this block is out of bounds.

```jldoctest
julia> A = PseudoBlockArray(zeros(2, 3), [1, 1], [2, 1]);

julia> setblock!(A, [1 2], 1, 1);

julia> A[Block(2, 1)] = [3 4];

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
    BlockBoundsError([A], [inds...])

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
            join(io, ex.i, ',')
            print(io, ']')
        end
    end
end

"""
    blockcheckbounds(A, inds...)

Throw a `BlockBoundsError` if the specified block indexes are not in bounds for the given block array.
Subtypes of `AbstractBlockArray` should
specialize this method if they need to provide custom block bounds checking behaviors.

```jldoctest
julia> A = BlockArray(rand(2,3), [1,1], [2,1]);

julia> blockcheckbounds(A, 3, 2)
ERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}} at block index [3,2]
[...]
```
"""
@inline function blockcheckbounds{T, N}(A::AbstractBlockArray{T, N}, i::Vararg{Int, N})
    if blockcheckbounds(Bool, A, i...)
        return
    else
        throw(BlockBoundsError(A, i))
    end
end

@inline function blockcheckbounds{T, N}(::Type{Bool}, A::AbstractBlockArray{T, N}, i::Vararg{Int, N})
    n = nblocks(A)
    k = 0
    for idx in 1:N # using enumerate here will allocate
        k += 1
        @inbounds _i = i[idx]
        if _i <= 0 || _i > n[k]
            return false
        end
    end
    return true
end


"""
    Array(A::AbstractBlockArray)

Returns the array stored in `A` as a `Array`.

```jldoctest
julia> A = BlockArray(ones(2,3), [1,1], [2,1])
2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 1.0  1.0  │  1.0
 ----------┼-----
 1.0  1.0  │  1.0

julia> Array(A)
2×3 Array{Float64,2}:
 1.0  1.0  1.0
 1.0  1.0  1.0
```
"""
function Base.Array(A::AbstractBlockArray) end


"""
    Block(inds...)

A `Block` is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the a block at that block index will be returned instead of
a single element.

```jldoctest
julia> A = BlockArray(ones(2,3), [1, 1], [2, 1])
2×2-blocked 2×3 BlockArrays.BlockArray{Float64,2,Array{Float64,2}}:
 1.0  1.0  │  1.0
 ----------┼-----
 1.0  1.0  │  1.0

julia> A[Block(1, 1)]
1×2 Array{Float64,2}:
 1.0  1.0
```
"""
immutable Block{N, T}
    n::NTuple{N, T}
end

Block{N, T}(n::Vararg{T, N}) = Block{N, T}(n)


# Convert to @generated...
@propagate_inbounds Base.getindex{T, N}( block_arr::AbstractBlockArray{T, N}, block::Block{N})    =  getblock(block_arr, block.n...)
@propagate_inbounds Base.setindex!{T, N}(block_arr::AbstractBlockArray{T, N}, v, block::Block{N}) =  setblock!(block_arr, v, block.n...)