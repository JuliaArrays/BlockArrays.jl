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

Base.sum(B::BlockArray; dims=:, kw...) = mapreduce(identity, Base.add_sum, B; dims, kw...)
function Base.mapreduce(::typeof(identity), op::typeof(Base.add_sum), B::BlockArray;
                        dims=:, kw...)
    if dims isa Colon && !isempty(B.blocks)
        return mapreduce(block -> mapreduce(identity, op, block), op, B.blocks; kw...)
    end
    return invoke(mapreduce, Tuple{Any,Any,AbstractArray}, identity, op, B; dims, kw...)
end
Base.mapreduce(::typeof(identity), op::typeof(Base.add_sum), B::BlockVector;
               dims=:, kw...) =
    invoke(mapreduce, Tuple{typeof(identity),typeof(op),BlockArray},
           identity, op, B; dims, kw...)

function Base.sum(f, B::BlockArray; dims=:, kw...)
    if dims isa Colon && !isempty(B.blocks)
        return mapreduce(block -> sum(f, block), Base.add_sum, B.blocks; kw...)
    end
    return invoke(sum, Tuple{Any,AbstractArray}, f, B; dims, kw...)
end

function LinearAlgebra.norm(B::BlockArray, p::Real=2)
    if p == 2 && !isempty(B.blocks)
        return mapreduce(norm, hypot, B.blocks)
    end
    return invoke(norm, Tuple{Any,Real}, B, p)
end

# support sum, need to return something analogous to Base.OneTo(1) but same type
Base.reduced_index(::BR) where BR<:AbstractBlockedUnitRange = convert(BR, Base.OneTo(1))
