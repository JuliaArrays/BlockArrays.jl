"""
    append!(dest::BlockVector, sources...; alias = false)

Append items from `sources` to the last block of `dest`.  If `alias = true`,
append the blocks in `sources` as-is if they are compatible with the internal
block array type of `dest`.  Importantly, this means that mutating `sources`
afterwards alters the items in `dest` and it may even break the invariance
of `dest` if the length of `sources` are changed.  The elements may be copied
even if `alias = true` if the corresponding implementation does not exist.

The blocks in `dest` must not alias with `sources` or components of them.
For example, the result of `append!(x, x)` is undefined.
"""
Base.append!(dest::BlockVector, sources...; alias::Bool = false) =
    foldl((d, s) -> append!(d, s; alias = alias), sources; init = dest)

function Base.append!(dest::BlockVector, src; alias::Bool = false)
    if _blocktype(dest) === _blocktype(src) && alias
        return append_nocopy!(dest, src)
    else
        return append_copy!(dest, src)
    end
end

_blocktype(::Any) = nothing
_blocktype(::T) where {T<:AbstractArray} = T
_blocktype(::BlockArray{<:Any,<:Any,<:AbstractArray{T}}) where {T<:AbstractArray} = T
_blocktype(::PseudoBlockArray{<:Any,<:Any,T}) where {T<:AbstractArray} = T

function append_nocopy!(dest::BlockVector{<:Any,T}, src::BlockVector{<:Any,T}) where {T}
    isempty(src) && return dest
    append!(dest.blocks, src.blocks)
    offset = last(dest.axes[1]) + 1 - src.axes[1].first
    append!(dest.axes[1].lasts, (n + offset for n in src.axes[1].lasts))
    return dest
end

append_nocopy!(
    dest::BlockVector{<:Any,<:AbstractArray{T}},
    src::PseudoBlockVector{<:Any,T},
) where {T} = append_nocopy!(dest, src.blocks)

function append_nocopy!(dest::BlockVector{<:Any,<:AbstractArray{T}}, src::T) where {T}
    isempty(src) && return dest
    push!(dest.blocks, src)
    push!(dest.axes[1].lasts, last(dest.axes[1]) + length(src))
    return dest
end

append_copy!(dest::BlockVector, src) = _append_copy!(dest, Base.IteratorSize(src), src)

function _append_copy!(dest::BlockVector, ::Union{Base.HasShape,Base.HasLength}, src)
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

function _append_copy!(dest::BlockVector, ::Base.SizeUnknown, src)
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
