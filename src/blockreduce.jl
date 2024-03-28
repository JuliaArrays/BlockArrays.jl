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

Base.mapfoldl(f::F, op::OP, B::PseudoBlockArray; kw...) where {F, OP} =
    mapfoldl(f, op, B.blocks; kw...)

Base.mapreduce(f::F, op::OP, B::PseudoBlockArray; kw...) where {F, OP} =
    mapreduce(f, op, B.blocks; kw...)

# support sum, need to return something analogous to Base.OneTo(1) but same type
Base.reduced_index(::BR) where BR<:AbstractBlockedUnitRange = convert(BR, Base.OneTo(1))
