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
_block_summary(a) = string(block2string(blocksize(a), size(a)), " ", typeof(a))
Base.summary(a::AbstractBlockArray) = _block_summary(a)
_show_typeof(io, a) = show(io, typeof(a))
function _block_summary(io, a)    
    print(io, block2string(blocksize(a), size(a)))
    print(io, ' ')
    _show_typeof(io, a)
end
Base.summary(io::IO, a::AbstractBlockArray) = _block_summary(io, a)

# avoid to_shape which complicates axes
Base.similar(a::AbstractBlockArray{T}) where {T}                             = similar(a, T)
Base.similar(a::AbstractBlockArray, ::Type{T}) where {T}                     = similar(a, T, axes(a))
Base.similar(a::AbstractBlockArray{T}, dims::Tuple) where {T}                = similar(a, T, dims)

Base.IndexStyle(::Type{<:AbstractBlockArray}) = IndexCartesian()

# need to overload axes to return BlockAxis
@inline size(block_array::AbstractBlockArray) = map(length, axes(block_array))
@inline axes(block_array::AbstractBlockArray) = throw(error("axes for ", typeof(block_array), " is not implemented"))

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
    BlockBoundsError(a::AbstractArray) = new(a)
    BlockBoundsError(a::AbstractArray, @nospecialize(i)) = new(a,i)
end

BlockBoundsError(a::AbstractArray, I::Block) = BlockBoundsError(a, I.n)

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
@inline function blockcheckbounds(A::AbstractArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    if blockcheckbounds(Bool, A, i...)
        return
    else
        throw(BlockBoundsError(A, i))
    end
end

@inline function blockcheckbounds(::Type{Bool}, A::AbstractArray{T, N}, i::Vararg{Integer, N}) where {T,N}
    n = blockaxes(A)
    k = 0
    for idx in 1:N # using enumerate here will allocate
        k += 1
        @inbounds _i = i[idx]
        Block(_i) in n[k] || return false
    end
    return true
end

blockcheckbounds(A::AbstractArray{T, N}, i::Block{N}) where {T,N} = blockcheckbounds(A, i.n...)

# Convert to @generated...
@propagate_inbounds Base.getindex( block_arr::AbstractBlockArray{T, N}, block::Block{N}) where {T,N}       =  getblock(block_arr, block.n...)
@propagate_inbounds Base.setindex!(block_arr::AbstractBlockArray{T, N}, v, block::Block{N}) where {T,N}    =  setblock!(block_arr, v, block.n...)
@propagate_inbounds Base.getindex( block_arr::AbstractBlockVector, block::Block{1})                  =  getblock(block_arr, block.n[1])
@propagate_inbounds Base.setindex!(block_arr::AbstractBlockVector, v, block::Block{1})               =  setblock!(block_arr, v, block.n[1])
@inline Base.getindex(block_arr::AbstractBlockArray{T,N}, block::Vararg{Block{1}, N}) where {T,N}     =  getblock(block_arr, (Block(block).n)...)
@inline Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, block::Vararg{Block{1}, N}) where {T,N} =  setblock!(block_arr, v, (Block(block).n)...)
