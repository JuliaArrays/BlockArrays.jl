"""
    blockappend!(dest::BlockVector, sources...) -> dest

Append blocks from `sources` to `dest`.  The number of blocks in `dest` are
increased by `sum(blocklength, sources)`.

This function avoids copying the elements of the blocks in `sources` when
these blocks are compatible with `dest`.  Importantly, this means that
mutating `sources` afterwards alters the items in `dest` and it may even
break the invariance of `dest` if the length of `sources` are changed.

The blocks in `dest` must not alias with `sources` or components of them.
For example, the result of `blockappend!(x, x)` is undefined.

# Examples
```jldoctest
julia> using BlockArrays

julia> blockappend!(mortar([[1], [2, 3]]), mortar([[4, 5]]))
3-blocked 5-element BlockVector{Int64}:
 1
 ─
 2
 3
 ─
 4
 5
```
"""
blockappend!(dest::BlockVector, s1, s2, sources...) =
    foldl(blockappend!, (s1, s2, sources...); init = dest)

function blockappend!(dest::BlockVector{<:Any,T}, src::BlockVector{<:Any,T}) where {T}
    append!(dest.blocks, src.blocks)
    offset = last(dest.axes[1]) + 1 - src.axes[1].first
    append!(dest.axes[1].lasts, (n + offset for n in src.axes[1].lasts))
    return dest
end

function blockappend!(
    dest::BlockVector{<:Any,<:AbstractArray{T}},
    src::PseudoBlockVector{<:Any,T},
) where {T}
    if blocklength(src) == 1
        return _blockpush!(dest, src.blocks)
    else
        return blockappend_fallback!(dest, src)
    end
end

blockappend!(
    dest::BlockVector{<:Any,<:AbstractArray{T}},
    src::T,
) where {T<:AbstractVector} = _blockpush!(dest, src)

blockappend!(dest::BlockVector{<:Any,<:Any}, src::AbstractVector) =
    blockappend_fallback!(dest, src)

blockappend_fallback!(dest::BlockVector{<:Any,<:AbstractArray{T}}, src) where {T} =
    blockappend!(dest, mortar([convert(T, @view src[b]) for b in blockaxes(src, 1)]))

"""
    blockpush!(dest::BlockVector, blocks...) -> dest

Push `blocks` to the end of `dest`.

This function avoids copying the elements of the `blocks` when these blocks
are compatible with `dest`.  Importantly, this means that mutating `blocks`
afterwards alters the items in `dest` and it may even break the invariance
of `dest` if the length of `blocks` are changed.

# Examples
```jldoctest
julia> using BlockArrays

julia> blockpush!(mortar([[1], [2, 3]]), [4, 5], [6])
4-blocked 6-element BlockVector{Int64}:
 1
 ─
 2
 3
 ─
 4
 5
 ─
 6
```
"""
blockpush!(dest::BlockVector, blocks...) = foldl(blockpush!, blocks; init = dest)

blockpush!(dest::BlockVector{<:Any,<:AbstractArray{T}}, block::T) where {T} =
    _blockpush!(dest, block)

blockpush!(dest::BlockVector, block) = _blockpush!(dest, _newblockfor(dest, block))

_newblockfor(dest, block) =
    if Iterators.IteratorSize(block) isa Union{Base.HasShape,Base.HasLength}
        copyto!(eltype(dest.blocks)(undef, length(block)), block)
    else
        foldl(push!, block; init = eltype(dest.blocks)(undef, 0))
    end

function _blockpush!(dest, block)
    push!(dest.blocks, block)
    push!(dest.axes[1].lasts, last(dest.axes[1]) + length(block))
    return dest
end

"""
    blockpushfirst!(dest::BlockVector, blocks...) -> dest

Push `blocks` to the beginning of `dest`.  See also [`blockpush!`](@ref).

This function avoids copying the elements of the `blocks` when these blocks
are compatible with `dest`.  Importantly, this means that mutating `blocks`
afterwards alters the items in `dest` and it may even break the invariance
of `dest` if the length of `blocks` are changed.

# Examples
```jldoctest
julia> using BlockArrays

julia> blockpushfirst!(mortar([[1], [2, 3]]), [4, 5], [6])
4-blocked 6-element BlockVector{Int64}:
 4
 5
 ─
 6
 ─
 1
 ─
 2
 3
```
"""
blockpushfirst!(A::BlockVector, b1, b2, blocks...) =
    foldl(blockpushfirst!, reverse((b1, b2, blocks...)); init = A)

blockpushfirst!(dest::BlockVector{<:Any,<:AbstractArray{T}}, block::T) where {T} =
    _blockpushfirst!(dest, block)

blockpushfirst!(dest::BlockVector{<:Any,<:Any}, block) =
    _blockpushfirst!(dest, _newblockfor(dest, block))

function _blockpushfirst!(dest, block)
    pushfirst!(dest.blocks, block)
    dest.axes[1].lasts .+= length(block) - 1 + dest.axes[1].first
    pushfirst!(dest.axes[1].lasts, length(block))
    return dest
end

"""
    blockpop!(A::BlockVector) -> block

Pop a `block` from the end of `dest`.

# Examples
```jldoctest
julia> using BlockArrays

julia> A = mortar([[1], [2, 3]]);

julia> blockpop!(A)
2-element Vector{Int64}:
 2
 3

julia> A
1-blocked 1-element BlockVector{Int64}:
 1
```
"""
function blockpop!(A::BlockVector)
    block = pop!(A.blocks)
    pop!(A.axes[1].lasts)
    return block
end

"""
    blockpopfirst!(dest::BlockVector) -> block

Pop a `block` from the beginning of `dest`.

# Examples
```jldoctest
julia> using BlockArrays

julia> A = mortar([[1], [2, 3]]);

julia> blockpopfirst!(A)
1-element Vector{Int64}:
 1

julia> A
1-blocked 2-element BlockVector{Int64}:
 2
 3
```
"""
function blockpopfirst!(A::BlockVector)
    block = popfirst!(A.blocks)
    n = popfirst!(A.axes[1].lasts)
    A.axes[1].lasts .-= n
    return block
end

"""
    append!(dest::BlockVector, sources...)

Append items from `sources` to the last block of `dest`.

The blocks in `dest` must not alias with `sources` or components of them.
For example, the result of `append!(x, x)` is undefined.

# Examples
```jldoctest
julia> using BlockArrays

julia> append!(mortar([[1], [2, 3]]), mortar([[4], [5]]))
2-blocked 5-element BlockVector{Int64}:
 1
 ─
 2
 3
 4
 5
```
"""
Base.append!(dest::BlockVector, sources...) = foldl(append!, sources; init = dest)

Base.append!(dest::BlockVector, src) = append_itr!(dest, Base.IteratorSize(src), src)

@inline function _append_itr_foldfn!(block,i,x)
    i += 1
    @inbounds block[i] = x
    return i
end

function append_itr!(dest::BlockVector, ::Union{Base.HasShape,Base.HasLength}, src)
    block = dest.blocks[end]
    li = lastindex(block)
    resize!(block, length(block) + length(src))
    # Equivalent to `i = li; for x in src; ...; end` but (maybe) faster:
    foldl(src, init = li) do i, x
        _append_itr_foldfn!(block,i,x)
    end
    da, = dest.axes
    da.lasts[end] += length(src)
    return dest
end

function append_itr!(dest::BlockVector, ::Base.SizeUnknown, src)
    block = dest.blocks[end]
    # Equivalent to `n = 0; for x in src; ...; end` but (maybe) faster:
    n = foldl(src, init = 0) do n, x
        push!(block, x)
        return n + 1
    end
    da, = dest.axes
    da.lasts[end] += n
    return dest
end

# remove empty blocks at the end
function _squash_lasts!(A::BlockVector)
    while !isempty(A.blocks) && isempty(A.blocks[end])
        pop!(A.blocks)
        pop!(A.axes[1].lasts)
    end
end

# remove empty blocks at the beginning
function _squash_firsts!(A::BlockVector)
    while !isempty(A.blocks) && isempty(A.blocks[1])
        popfirst!(A.blocks)
        popfirst!(A.axes[1].lasts)
    end
end

"""
    pop!(A::BlockVector)

Pop the last element from the last non-empty block.  Remove all empty
blocks at the end.
"""
function Base.pop!(A::BlockVector)
    isempty(A) && throw(Argument("array must be nonempty"))
    _squash_lasts!(A)
    x = pop!(A.blocks[end])
    lasts = A.axes[1].lasts
    if isempty(A.blocks[end])
        pop!(A.blocks)
        pop!(lasts)
    else
        lasts[end] -= 1
    end
    return x
end

"""
    popfirst!(A::BlockVector)

Pop the first element from the first non-empty block.  Remove all empty
blocks at the beginning.
"""
function Base.popfirst!(A::BlockVector)
    isempty(A) && throw(Argument("array must be nonempty"))
    _squash_firsts!(A)
    x = popfirst!(A.blocks[1])
    ax, = A.axes
    if isempty(A.blocks[1])
        popfirst!(A.blocks)
        popfirst!(ax.lasts)
    else
        ax.lasts[1] -= 1
    end
    return x
end

"""
    push!(dest::BlockVector, items...)

Push items to the end of the last block.
"""
Base.push!(dest::BlockVector, items...) = append!(dest, items)

"""
    pushfirst!(A::BlockVector, items...)

Push items to the beginning of the first block.
"""
function Base.pushfirst!(A::BlockVector, items...)
    pushfirst!(A.blocks[1], items...)
    A.axes[1].lasts .+= length(items)
    return A
end
