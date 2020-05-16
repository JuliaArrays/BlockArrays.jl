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
3-blocked 5-element BlockArray{Int64,1}:
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
    isempty(src) && return dest
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
        return blockappend!(dest, src.blocks)
    else
        return blockappend_fallback!(dest, src)
    end
end

function blockappend!(
    dest::BlockVector{<:Any,<:AbstractArray{T}},
    src::T,
) where {T<:AbstractVector}
    isempty(src) && return dest
    push!(dest.blocks, src)
    push!(dest.axes[1].lasts, last(dest.axes[1]) + length(src))
    return dest
end

blockappend!(dest::BlockVector{<:Any,<:Any}, src::AbstractVector) =
    blockappend_fallback!(dest, src)

blockappend_fallback!(dest::BlockVector{<:Any,<:AbstractArray{T}}, src) where {T} =
    blockappend!(dest, mortar([convert(T, @view src[b]) for b in blockaxes(src, 1)]))

"""
    append!(dest::BlockVector, sources...)

Append items from `sources` to the last block of `dest`.

The blocks in `dest` must not alias with `sources` or components of them.
For example, the result of `append!(x, x)` is undefined.

# Examples
```jldoctest
julia> using BlockArrays

julia> append!(mortar([[1], [2, 3]]), mortar([[4], [5]]))
2-blocked 5-element BlockArray{Int64,1}:
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

function append_itr!(dest::BlockVector, ::Union{Base.HasShape,Base.HasLength}, src)
    block = dest.blocks[end]
    li = lastindex(block)
    resize!(block, length(block) + length(src))
    # Equivalent to `i = li; for x in src; ...; end` but (maybe) faster:
    foldl(src, init = li) do i, x
        Base.@_inline_meta
        i += 1
        @inbounds block[i] = x
        return i
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
