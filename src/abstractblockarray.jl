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
_show_typeof(io, a) = show(io, typeof(a))
function Base.summary(io::IO, a::AbstractBlockArray)
    print(io, block2string(nblocks(a), size(a)))
    print(io, ' ')
    _show_typeof(io, a)
end
Base.similar(block_array::AbstractBlockArray{T}) where {T} = similar(block_array, T)
Base.IndexStyle(::Type{<:AbstractBlockArray}) = IndexCartesian()

"""
    nblocks(A, [dim...])

Returns a tuple containing the number of blocks in a block array.  Optionally you can specify
the dimension(s) you want the number of blocks for.

```jldoctest; setup = quote using BlockArrays end
julia> A =  BlockArray(rand(5,4,6), [1,4], [1,2,1], [1,2,2,1]);

julia> nblocks(A)
(2, 3, 4)

julia> nblocks(A, 2)
3

julia> nblocks(A, 3, 2)
(4, 3)
```
"""
nblocks(block_array::AbstractArray, i::Integer) = nblocks(block_array)[i]

nblocks(block_array::AbstractArray, i::Vararg{Integer, N}) where {N} =
    nblocks(blocksizes(block_array), i...)


"""
    Block(inds...)

A `Block` is simply a wrapper around a set of indices or enums so that it can be used to dispatch on. By
indexing a `AbstractBlockArray` with a `Block` the a block at that block index will be returned instead of
a single element.

```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray(ones(2,3), [1, 1], [2, 1])
2×2-blocked 2×3 BlockArray{Float64,2}:
 1.0  1.0  │  1.0
 ──────────┼─────
 1.0  1.0  │  1.0

julia> A[Block(1, 1)]
1×2 Array{Float64,2}:
 1.0  1.0
```
"""
struct Block{N, T}
    n::NTuple{N, T}
    Block{N, T}(n::NTuple{N, T}) where {N, T} = new{N, T}(n)
end


Block{N, T}(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block{N}(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block() = Block{0,Int}()
Block(n::Vararg{T, N}) where {N,T} = Block{N, T}(n)
Block{1}(n::Tuple{T}) where {T} = Block{1, T}(n)
Block{N}(n::NTuple{N, T}) where {N,T} = Block{N, T}(n)
Block(n::NTuple{N, T}) where {N,T} = Block{N, T}(n)

@inline function Block(blocks::NTuple{N, Block{1, T}}) where {N,T}
    Block{N, T}(ntuple(i -> blocks[i].n[1], Val(N)))
end


# The following code is taken from CartesianIndex
@inline (+)(index::Block{N}) where {N} = Block{N}(map(+, index.n))
@inline (-)(index::Block{N}) where {N} = Block{N}(map(-, index.n))

@inline (+)(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(+, index1.n, index2.n))
@inline (-)(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(-, index1.n, index2.n))
@inline min(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(min, index1.n, index2.n))
@inline max(index1::Block{N}, index2::Block{N}) where {N} =
    Block{N}(map(max, index1.n, index2.n))

@inline (+)(i::Integer, index::Block) = index+i
@inline (+)(index::Block{N}, i::Integer) where {N} = Block{N}(map(x->x+i, index.n))
@inline (-)(index::Block{N}, i::Integer) where {N} = Block{N}(map(x->x-i, index.n))
@inline (-)(i::Integer, index::Block{N}) where {N} = Block{N}(map(x->i-x, index.n))
@inline (*)(a::Integer, index::Block{N}) where {N} = Block{N}(map(x->a*x, index.n))
@inline (*)(index::Block, a::Integer) = *(a,index)

# comparison
@inline isless(I1::Block{N}, I2::Block{N}) where {N} = Base.IteratorsMD._isless(0, I1.n, I2.n)

# conversions
convert(::Type{T}, index::Block{1}) where {T<:Number} = convert(T, index.n[1])
convert(::Type{T}, index::Block) where {T<:Tuple} = convert(T, index.n)

Int(index::Block{1}) = Int(index.n[1])
Integer(index::Block{1}) = index.n[1]
Number(index::Block{1}) = index.n[1]

"""
    getblock(A, inds...)

Returns the block at blockindex `inds...`. An alternative syntax is `A[Block(inds...)].
Throws a `BlockBoundsError` if this block is out of bounds.

```jldoctest; setup = quote using BlockArrays end
julia> v = Array(reshape(1:6, (2, 3)))
2×3 Array{Int64,2}:
 1  3  5
 2  4  6

julia> A = BlockArray(v, [1,1], [2,1])
2×2-blocked 2×3 BlockArray{Int64,2}:
 1  3  │  5
 ──────┼───
 2  4  │  6

julia> getblock(A, 2, 1)
1×2 Array{Int64,2}:
 2  4

julia> A[Block(1, 2)]
1×1 Array{Int64,2}:
 5
```
"""
function getblock(A::AbstractBlockArray{T,N}, ::Vararg{Integer, N}) where {T,N}
    throw(error("getblock for ", typeof(A), " is not implemented"))
end


"""
    getblock!(X, A, inds...)

Stores the block at blockindex `inds` in `X` and returns it. Throws a `BlockBoundsError` if the
attempted assigned block is out of bounds.

```jldoctest; setup = quote using BlockArrays end
julia> A = PseudoBlockArray(ones(2, 3), [1, 1], [2, 1])
2×2-blocked 2×3 PseudoBlockArray{Float64,2}:
 1.0  1.0  │  1.0
 ──────────┼─────
 1.0  1.0  │  1.0

julia> x = zeros(1, 2);

julia> getblock!(x, A, 2, 1);

julia> x
1×2 Array{Float64,2}:
 1.0  1.0
```
"""
getblock!(X, A::AbstractBlockArray{T,N}, ::Vararg{Integer, N}) where {T,N} = throw(error("getblock! for ", typeof(A), " is not implemented"))

@inline getblock!(X, A::AbstractBlockArray{T,N}, block::Block{N}) where {T,N}             = getblock!(X, A, block.n...)
@inline getblock!(X, A::AbstractBlockVector, block::Block{1})                       = getblock!(X, A, block.n[1])
@inline getblock!(X, A::AbstractBlockArray{T, N}, block::Vararg{Block{1}, N}) where {T,N} = getblock!(X, A, (Block(block).n)...)

"""
    setblock!(A, v, inds...)

Stores the block `v` in the block at block index `inds` in `A`. An alternative syntax is `A[Block(inds...)] = v`.
Throws a `BlockBoundsError` if this block is out of bounds.

```jldoctest; setup = quote using BlockArrays end
julia> A = PseudoBlockArray(zeros(2, 3), [1, 1], [2, 1]);

julia> setblock!(A, [1 2], 1, 1);

julia> A[Block(2, 1)] = [3 4];

julia> A
2×2-blocked 2×3 PseudoBlockArray{Float64,2}:
 1.0  2.0  │  0.0
 ──────────┼─────
 3.0  4.0  │  0.0
```
"""
setblock!(A::AbstractBlockArray{T,N}, v, ::Vararg{Integer, N}) where {T,N} = throw(error("setblock! for ", typeof(A), " is not implemented"))

@inline setblock!(A::AbstractBlockArray{T, N}, v, block::Block{N}) where {T,N}      = setblock!(A, v, block.n...)
@inline setblock!(A::AbstractBlockVector, v, block::Block{1})                       = setblock!(A, v, block.n[1])
@inline setblock!(A::AbstractBlockArray{T, N}, v, block::Vararg{Block{1}, N}) where {T,N} = setblock!(A, v, (Block(block).n)...)


"""
    BlockBoundsError([A], [inds...])

Thrown when a block indexing operation into a block array, `A`, tried to access an out-of-bounds block, `inds`.
"""
struct BlockBoundsError <: Exception
    a::Any
    i::Any
    BlockBoundsError() = new()
    BlockBoundsError(a::AbstractBlockArray) = new(a)
    BlockBoundsError(a::AbstractBlockArray, @nospecialize(i)) = new(a,i)
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

```jldoctest; setup = quote using BlockArrays end
julia> A = BlockArray(rand(2,3), [1,1], [2,1]);

julia> blockcheckbounds(A, 3, 2)
ERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockArray{Float64,2,Array{Array{Float64,2},2},BlockArrays.BlockSizes{2,Tuple{Array{Int64,1},Array{Int64,1}}}} at block index [3,2]
[...]
```
"""
@inline function blockcheckbounds(A::AbstractBlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    if blockcheckbounds(Bool, A, i...)
        return
    else
        throw(BlockBoundsError(A, i))
    end
end

@inline function blockcheckbounds(::Type{Bool}, A::AbstractBlockArray{T, N}, i::Vararg{Integer, N}) where {T,N}
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

# Convert to @generated...
@propagate_inbounds Base.getindex( block_arr::AbstractBlockArray{T, N}, block::Block{N}) where {T,N}       =  getblock(block_arr, block.n...)
@propagate_inbounds Base.setindex!(block_arr::AbstractBlockArray{T, N}, v, block::Block{N}) where {T,N}    =  setblock!(block_arr, v, block.n...)
@propagate_inbounds Base.getindex( block_arr::AbstractBlockVector, block::Block{1})                  =  getblock(block_arr, block.n[1])
@propagate_inbounds Base.setindex!(block_arr::AbstractBlockVector, v, block::Block{1})               =  setblock!(block_arr, v, block.n[1])
@inline Base.getindex(block_arr::AbstractBlockArray{T,N}, block::Vararg{Block{1}, N}) where {T,N}     =  getblock(block_arr, (Block(block).n)...)
@inline Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, block::Vararg{Block{1}, N}) where {T,N} =  setblock!(block_arr, v, (Block(block).n)...)
