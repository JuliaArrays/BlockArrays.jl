###
# based on julia/base/range.jl
###
module FirstStepRange
using Base

import Base: el_same, StepRangeLen, step, step_hp, getindex, unsafe_getindex, length, first, last, iterate, OneTo, promote_rule, isempty, show, ==, -, +
import Base: _reverse
import Base: broadcasted
using Base.Broadcast: DefaultArrayStyle
import FillArrays: steprangelen

export FirstStepRangeLen, FirstStepRanges, firststeprangelen

"""
    FirstStepRangeLen(step::S, len) where S
    FirstStepRangeLen{T}(step::S, len) where {S, T}

A range `r` where `r[i]` produces values of type `T` (in the first
form, `T` is deduced automatically), a `step`, and the `len`gth. The `step` is also the starting
value `r[1]`. This is used to encode block lasts corresponding to a fixed block size.
"""
struct FirstStepRangeLen{S,L<:Integer} <: AbstractRange{S}
    step::S      # step value
    len::L       # length of the range

    function FirstStepRangeLen{S,L}(step::S, len::Integer) where {S,L}
        if S <: Integer && !isinteger(step + step)
            throw(ArgumentError("FirstStepRangeLen{<:Integer} cannot have non-integer step"))
        end
        len = convert(L, len)
        len >= zero(len) || throw(ArgumentError("length cannot be negative, got $len"))
        L1 = oneunit(typeof(len))
        return new(step, len)
    end
end

FirstStepRangeLen{S}(step::S, len::Integer) where {S} =
    FirstStepRangeLen{S,typeof(len)}(step, len)
FirstStepRangeLen(step::S, len::Integer) where {S} =
    FirstStepRangeLen{S,typeof(len)}(step, len)

firststeprangelen(a...) = FirstStepRangeLen(a...)


isempty(r::FirstStepRangeLen) = length(r) == 0

step(r::FirstStepRangeLen) = r.step
step_hp(r::FirstStepRangeLen) = r.step
length(r::FirstStepRangeLen) = r.len
first(r::FirstStepRangeLen) = unsafe_getindex(r, 1)
last(r::FirstStepRangeLen) = unsafe_getindex(r, length(r))

StepRangeLen(r::FirstStepRangeLen{T}) where T = StepRangeLen{T}(first(r), step(r), length(r))
steprangelen(r::FirstStepRangeLen) = steprangelen(first(r), step(r), length(r))

iterate(r::FirstStepRangeLen, i...) = iterate(StepRangeLen(r), i...)
unsafe_getindex(r::FirstStepRangeLen{T}, i::Integer) where T = T(step(r)i)
getindex(r::FirstStepRangeLen{T}, s::OrdinalRange{S}) where {T, S<:Integer} = steprangelen(r)[s]

function show(io::IO, r::FirstStepRangeLen)
    if !iszero(step(r))
        print(io, repr(first(r)), ':', repr(step(r)), ':', repr(last(r)))
    else
        # ugly temporary printing, to avoid 0:0:0 etc.
        print(io, "FirstStepRangeLen(", repr(first(r)), ", ", repr(step(r)), ", ", repr(length(r)), ")")
    end
end

==(r::FirstStepRangeLen, s::FirstStepRangeLen) =
    (isempty(r) & isempty(s)) | ((length(r) == length(s)) & (last(r) == last(s)))

==(r::FirstStepRangeLen{T}, s::Union{StepRange{T},StepRangeLen{T,T}}) where {T} = StepRangeLen(r) == s
==(r::Union{StepRange{T},StepRangeLen{T,T}}, s::FirstStepRangeLen{T}) where {T} = r == StepRangeLen(s)
    

-(r::FirstStepRangeLen{S,L}) where {S,L} = FirstStepRangeLen{S,L}(-r.step, r.len)

function promote_rule(::Type{FirstStepRangeLen{S1,L1}},::Type{FirstStepRangeLen{S2,L2}}) where {S1,S2,L1,L2}
    S, L = promote_type(S1, S2), promote_type(L1, L2)
    FirstStepRangeLen{S,L}
end
FirstStepRangeLen{S,L}(r::FirstStepRangeLen{S,L}) where {S,L} = r
FirstStepRangeLen{S,L}(r::FirstStepRangeLen) where {S,L} =
    FirstStepRangeLen{S,L}(convert(S, r.step), convert(L, r.len))
FirstStepRangeLen{T}(r::FirstStepRangeLen) where {T} =
    FirstStepRangeLen(convert(T, r.step), r.len)

promote_rule(a::Type{FirstStepRangeLen{S,L}}, ::Type{OR}) where {S,L,OR<:AbstractRange} =
    promote_rule(a, FirstStepRangeLen{eltype(OR), eltype(OR), Int})

promote_rule(::Type{LinRange{A,L}}, b::Type{FirstStepRangeLen{S2,L2}}) where {A,L,S2,L2} =
    promote_rule(FirstStepRangeLen{A,L}, b)


_reverse(r::FirstStepRangeLen, ::Colon) = typeof(r)(negate(r.step), length(r), offset)

function +(r1::FirstStepRangeLen{S}, r2::FirstStepRangeLen{S}) where {S}
    len = length(r1)
    (len == length(r2) ||
     throw(DimensionMismatch("argument dimensions must match: length of r1 is $len, length of r2 is $(length(r2))")))
    FirstStepRangeLen(step(r1)+step(r2), len)
end

-(r1::FirstStepRangeLen, r2::FirstStepRangeLen) = +(r1, -r2)


const FirstStepRanges = Union{FirstStepRangeLen, OneTo}


######
# from base/broadcast.jl
######

broadcasted(::DefaultArrayStyle{1}, ::typeof(-), r::FirstStepRangeLen) = FirstStepRangeLen(negate(r.step), length(r))
for op in (:+, :-)
    @eval begin
        broadcasted(::DefaultArrayStyle{1}, ::typeof($op), r::FirstStepRangeLen{T}, x::Number) where T = broadcasted(DefaultArrayStyle{1}(), $op, StepRangeLen(r), x)
        broadcasted(::DefaultArrayStyle{1}, ::typeof($op), x::Number, r::FirstStepRangeLen{T}) where T = broadcasted(DefaultArrayStyle{1}(), $op, x, StepRangeLen(r))
    end
end
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), x::Number, r::FirstStepRangeLen{T}) where {T} =
    FirstStepRangeLen{typeof(x*T(r.step))}(x*r.step, length(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(*), r::FirstStepRangeLen{T}, x::Number) where {T} =
    FirstStepRangeLen{typeof(T(r.step)*x)}(r.step*x, length(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(/), r::FirstStepRangeLen{T}, x::Number) where {T} =
    FirstStepRangeLen{typeof(T(r.step)/x)}(r.step/x, length(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(\), x::Number, r::FirstStepRangeLen) = FirstStepRangeLen(x\r.step, length(r))
broadcasted(::DefaultArrayStyle{1}, ::typeof(big), r::FirstStepRangeLen) = FirstStepRangeLen(big(r.step), length(r))

end # module