function _cumsum(v::Vector{Int}, endidx::Int)
    s = 0
    @inbounds for i in 1:endidx
        s += v[i]
    end
    return s
end

@inline function _sumiter(v::Vector{Int}, endidx::Int)
    s = 0
    @inbounds for i in 1:endidx
        s += v[i]
    end
    return s
end
