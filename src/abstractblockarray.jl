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
abstract type AbstractBlockArray{T, N} <: LayoutArray{T, N} end
const AbstractBlockMatrix{T} = AbstractBlockArray{T, 2}
const AbstractBlockVector{T} = AbstractBlockArray{T, 1}
const AbstractBlockVecOrMat{T} = Union{AbstractBlockMatrix{T}, AbstractBlockVector{T}}

block2string(b, s) = string(join(map(string,b), '×'), "-blocked ", Base.dims2string(s))
_block_summary(a) = string(block2string(blocksize(a), size(a)), " ", typeof(a))
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

# If all we know is size, just return an Array which conforms to BlockArray interface
Base.similar(::Type{<:AbstractBlockArray{T,N}}, dims::Dims) where {T,N} = similar(Array{T,N}, dims)

# need to overload axes to return BlockAxis
@inline size(block_array::AbstractBlockArray) = map(length, axes(block_array))
@noinline axes(block_array::AbstractBlockArray) = throw(ArgumentError("axes for $(typeof(block_array)) is not implemented"))

BlockRange(B::AbstractBlockArray) = BlockRange(blockaxes(B))

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

```jldoctest
julia> A = BlockArray(rand(2,3), [1,1], [2,1]);

julia> blockcheckbounds(A, 3, 2)
ERROR: BlockBoundsError: attempt to access 2×2-blocked 2×3 BlockMatrix{Float64} at block index [3,2]
[...]
```
"""
@inline function blockcheckbounds(A::AbstractArray, i...)
    blockcheckbounds(Bool, A, i...) || throw(BlockBoundsError(A, i))
end

# linear block indexing
@inline function blockcheckbounds(::Type{Bool}, A::AbstractArray, i)
    blockcheckindex(Bool, BlockRange(blocklength(A)), i)
end
# cartesian block indexing
@inline function blockcheckbounds(::Type{Bool}, A::AbstractArray, i...)
    blockcheckbounds_indices(Bool, blockaxes(A), i)
end

blockcheckbounds(A::AbstractArray{T, N}, i::Block{N}) where {T,N} = blockcheckbounds(A, i.n...)
blockcheckbounds(A::AbstractArray{T, N}, i::Vararg{Block{1},N}) where {T,N} = blockcheckbounds(A, Int.(i)...)
blockcheckbounds(A::AbstractVector{T}, i::Block{1}) where {T} = blockcheckbounds(A, Int(i))

"""
    blockcheckbounds_indices(Bool, IA::Tuple{Vararg{BlockRange{1}}}, I::Tuple{Vararg{Integer}})

Return true if the "requested" indices in the tuple `Block.(I)` fall within the bounds of the "permitted"
indices specified by the tuple `IA`. This function recursively consumes elements of these tuples
in a 1-for-1 fashion.

The actual bounds-checking is performed by [`blockcheckindex`](@ref).

# Examples
```jldoctest
julia> B = BlockArray(zeros(6,6), 1:3, 1:3);

julia> blockaxes(B)
(BlockRange(Base.OneTo(3)), BlockRange(Base.OneTo(3)))

julia> BlockArrays.blockcheckbounds_indices(Bool, blockaxes(B), (1,2))
true

julia> BlockArrays.blockcheckbounds_indices(Bool, blockaxes(B), (4,1))
false
```
"""
@inline blockcheckbounds_indices(::Type{Bool}, ::Tuple{}, ::Tuple{}) = true
@inline function blockcheckbounds_indices(::Type{Bool}, blockaxes::Tuple{Vararg{BlockRange{1}}}, i::Tuple{})
    # the trailing blocks must be Block(1)
    b = first(blockaxes)
    length(b) == 1 && Int(b[]) == 1 && blockcheckbounds_indices(Bool, blockaxes[2:end], i)
end
@inline function blockcheckbounds_indices(::Type{Bool}, blockaxes::Tuple{}, i::Tuple)
    # the trailing indices must be 1
    first(i) == 1 && blockcheckbounds_indices(Bool, blockaxes, i[2:end])
end
@inline function blockcheckbounds_indices(::Type{Bool}, blockaxes::Tuple{Vararg{BlockRange{1}}}, i::Tuple)
    blockcheckindex(Bool, first(blockaxes), first(i)) &&
        blockcheckbounds_indices(Bool, blockaxes[2:end], i[2:end])
end

"""
    blockcheckindex(Bool, inds::BlockRange{1}, index::Integer)

Return `true` if `Block(index)` is within the bounds of `inds`.

# Examples
```jldoctest
julia> BlockArrays.blockcheckindex(Bool, BlockRange(1:2), 1)
true

julia> BlockArrays.blockcheckindex(Bool, BlockRange(1:2), 3)
false
```
"""
@inline blockcheckindex(::Type{Bool}, inds::BlockRange{1}, i::Integer) = Block(i) in inds

@propagate_inbounds Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, block::Block{N}) where {T,N} =
    setindex!(block_arr, v, Block.(block.n)...)
@inline @propagate_inbounds function Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, block::Vararg{Block{1}, N}) where {T,N}
    blockcheckbounds(block_arr, block...)
    dest = view(block_arr, block...)
    size(dest) == size(v) || throw(DimensionMismatch(string("tried to assign $(size(v)) array to $(size(dest)) block")))
    copyto!(dest, v)
    block_arr
end

@inline @propagate_inbounds Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, blockindex::BlockIndex{N}) where {T,N} =
    view(block_arr, block(blockindex))[blockindex.α...] = v
@inline @propagate_inbounds Base.setindex!(block_arr::AbstractBlockVector{T}, v, blockindex::BlockIndex{1}) where {T} =
    view(block_arr, block(blockindex))[blockindex.α...] = v
@inline @propagate_inbounds Base.setindex!(block_arr::AbstractBlockArray{T,N}, v, blockindex::Vararg{BlockIndex{1},N}) where {T,N} =
    block_arr[BlockIndex(blockindex)] = v

viewblock(block_arr, block) = Base.invoke(view, Tuple{AbstractArray, Any}, block_arr, block)
@inline view(block_arr::AbstractBlockArray{<:Any,N}, block::Block{N}) where N = viewblock(block_arr, block)
@inline function view(block_arr::AbstractBlockArray, block::Block{1})
    blkind = BlockRange(blocksize(block_arr))[Int(block)]
    view(block_arr, blkind)
end
@inline view(block_arr::AbstractBlockVector, block::Block{1}) = viewblock(block_arr, block)
@inline @propagate_inbounds view(block_arr::AbstractBlockArray, block::Block{1}...) = view(block_arr, Block(block))

"""
    eachblock(A::AbstractBlockArray)

Create a generator that iterates over each block of an `AbstractBlockArray`
returning views.

```jldoctest
julia> v = Array(reshape(1:6, (2, 3)))
2×3 Matrix{Int64}:
 1  3  5
 2  4  6

julia> A = BlockArray(v, [1,1], [2,1])
2×2-blocked 2×3 BlockMatrix{Int64}:
 1  3  │  5
 ──────┼───
 2  4  │  6

julia> sum.(eachblock(A))
2×2 Matrix{Int64}:
 4  5
 6  6
```
"""
function eachblock(A::AbstractBlockArray)
    # blockinds = CartesianIndices(blocksize(A))
    blockinds = CartesianIndices(axes.(blocklasts.(axes(A)),1))
    (view(A, Block(Tuple(I))) for I in blockinds)
end

# Use memory layout for sub-blocks
@inline getindex(A::AbstractMatrix, kr::Colon, jr::Block{1}) = ArrayLayouts.layout_getindex(A, kr, jr)
@inline getindex(A::AbstractMatrix, kr::Block{1}, jr::Colon) = ArrayLayouts.layout_getindex(A, kr, jr)
@inline getindex(A::AbstractMatrix, kr::Block{1}, jr::AbstractVector) = ArrayLayouts.layout_getindex(A, kr, jr)
@inline getindex(A::AbstractArray{T,N}, kr::Block{1}, jrs...) where {T,N} = ArrayLayouts.layout_getindex(A, kr, jrs...)
@inline getindex(A::AbstractArray{T,N}, block::Block{N}) where {T,N} = ArrayLayouts.layout_getindex(A, block)
@inline getindex(A::AbstractMatrix, kr::AbstractVector, jr::Block) = ArrayLayouts.layout_getindex(A, kr, jr)
@inline getindex(A::AbstractMatrix, kr::BlockRange{1}, jr::BlockRange{1}) = ArrayLayouts.layout_getindex(A, kr, jr)
@inline getindex(A::LayoutMatrix, kr::BlockRange{1}, jr::BlockRange{1}) = ArrayLayouts.layout_getindex(A, kr, jr)
for Typ in (:AbstractTriangular, :Adjoint, :Transpose, :Symmetric, :Hermitian)
    @eval @inline getindex(A::$Typ{<:Any,<:LayoutMatrix}, kr::BlockRange{1}, jr::BlockRange{1}) = ArrayLayouts.layout_getindex(A, kr, jr)
end

###
# permutedims
#
# just use transpose for now
###

Base.permutedims(A::AbstractBlockVector{<:Number}) = transpose(A)
Base.permutedims(A::AbstractBlockMatrix{<:Number}) = transpose(A)


