# * Those seemingly no-op `where {F, OP}` for forcing specialization.
#   See: https://github.com/JuliaLang/julia/pull/33917
# * Per-block reduction strategy is correct only for vectors.

# Let mapping transducer in `Base` compose an efficient nested loop:
Base.mapfoldl(f::F, op::OP, B::BlockVector; kw...) where {F, OP} =
    foldl(op, (f(x) for block in B.blocks for x in block); kw...)

Base.mapreduce(f::F, op::OP, B::BlockVector; kw...) where {F, OP} =
    mapfoldl(op, B.blocks; kw...) do block
        mapreduce(f, op, block; kw...)
    end

Base.mapfoldl(f::F, op::OP, B::BlockedArray; kw...) where {F, OP} =
    mapfoldl(f, op, B.blocks; kw...)

Base.mapreduce(f::F, op::OP, B::BlockedArray; kw...) where {F, OP} =
    mapreduce(f, op, B.blocks; kw...)

function Base.mapreduce(f::F, op::typeof(Base.add_sum), B::BlockArray;
                        dims=:, kw...) where F
    if dims isa Colon && !isempty(B)
        nonemptyblocks = Iterators.filter(!isempty, B.blocks)
        return mapreduce(block -> mapreduce(f, op, block), op, nonemptyblocks; kw...)
    end
    return invoke(mapreduce, Tuple{Any,Any,AbstractArray}, f, op, B; dims, kw...)
end
Base.mapreduce(f::F, op::typeof(Base.add_sum), B::BlockVector;
               dims=:, kw...) where F =
    invoke(mapreduce, Tuple{F,typeof(op),BlockArray}, f, op, B; dims, kw...)

function LinearAlgebra.norm2(B::BlockArray)
    isempty(B.blocks) && return float(norm(zero(eltype(B))))
    return mapreduce(norm, hypot, B.blocks)
end

# support sum, need to return something analogous to Base.OneTo(1) but same type
Base.reduced_index(::BR) where BR<:AbstractBlockedUnitRange = convert(BR, Base.OneTo(1))
