function _cumsum(v::Vector{Int}, range::UnitRange)
    s = 0
    for i in range
        s += v[i]
    end
    return s
end

@inline function _sumiter(v::Vector{Int}, endidx)
    s = 0
    for i in 1:endidx
        s += v[i]
    end
    return s
end
