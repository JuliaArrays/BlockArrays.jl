# We just define some convenience function to make playing in the REPL easier.
# These are probably not too useful in practice.

const UNARY_FUNCS = (:-, :~, :conj, :abs,
                  :sin, :cos, :tan, :sinh, :cosh, :tanh,
                  :asin, :acos, :atan, :asinh, :acosh, :atanh,
                  :sec, :csc, :cot, :asec, :acsc, :acot,
                  :sech, :csch, :coth, :asech, :acsch, :acoth,
                  :sinc, :cosc, :cosd, :cotd, :cscd, :secd,
                  :sind, :tand, :acosd, :acotd, :acscd, :asecd,
                  :asind, :atand, :rad2deg, :deg2rad,
                  :log, :log2, :log10, :log1p, :exponent, :exp,
                  :exp2, :expm1, :cbrt, :sqrt, :erf,
                  :erfc, :erfcx, :erfi, :dawson, :ceil, :floor,
                  :trunc, :round, :significand)

const BINARY_FUNCS  = (:.+, :.-,:.*, :./, :.\, :.^,
                    :+, :-,
                   :min, :max,
                   :div, :mod)

const BOOLEAN_BINARY_FUNCS = (:.==, :.!=, :.<, :.<=, :.>, :.>=)

const REDUCTION_FUNCS = ((:maximum, :max),
                         (:minimum,  :min),
                         (:sum, :.+),
                         (:prod, :.*))

####################
# Binary functions #
####################

macro blockwise_binary(func, Tres)
    esc(quote
        @assert A.block_sizes == B.block_sizes
        block_array_new = similar(A, $Tres)
        @inbounds for I in eachindex(A.blocks)
            block_array_new.blocks[I] = $func(A.blocks[I], B.blocks[I])
        end
        return block_array_new
    end)
end


macro blockwise_binary_scalar(func, Tres, mode)
    esc(quote
        block_array_new = similar(block_array, $Tres)
        @inbounds for I in eachindex(block_array.blocks)
            if $mode == 1
                block_array_new.blocks[I] = $func(A, block_array.blocks[I])
            else
                block_array_new.blocks[I] = $func(block_array.blocks[I], A)
            end
        end
        return block_array_new
    end)
end



for f in BINARY_FUNCS
    @eval begin
        Base.$f{T1, T2, N}(A::BlockArray{T1, N}, B::BlockArray{T2, N}) = @blockwise_binary($f, Base.promote_op($f, T1, T2))

        Base.$f{T1 <: Number, T2, N}(A::T1, block_array::BlockArray{T2, N}) = @blockwise_binary_scalar($f, Base.promote_op($f, T1, T2), 1)
        Base.$f{T1, T2 <: Number, N}(block_array::BlockArray{T1, N}, A::T2) = @blockwise_binary_scalar($f, Base.promote_op($f, T1, T2), 2)
    end
end

for f in BINARY_FUNCS
    @eval begin
        Base.$f{T1, T2, N}(A::T1, B::BlockArray{T2, N}) = @blockwise_binary($f, Base.promote_op($f, T1, T2))
    end
end

for f in BOOLEAN_BINARY_FUNCS
    @eval begin
        Base.$f{T1, T2, N}(A::BlockArray{T1, N}, B::BlockArray{T2, N}) = @blockwise_binary($f, Bool)
    end
end


###################
# Unary functions #
###################

macro blockwise_unary(func, Tres)
    esc(quote
        block_array_new = similar(block_array, $Tres)
        @inbounds for I in eachindex(block_array.blocks)
            block_array_new.blocks[I] = $func(block_array.blocks[I])
        end
        return block_array_new
    end)
end


for f in UNARY_FUNCS
    @eval begin
        Base.$f{T}(block_array::BlockArray{T}) = @blockwise_unary($f, typeof($f(one(T))))
    end
end

##############
# Reductions #
##############

macro blockwise_reduction(func, merging_func)
    esc(quote
        blocks = block_array.blocks
        @assert length(blocks) > 0
        s = $func(blocks[1])
        @inbounds for i in 2:length(blocks)
            s = $merging_func(s, $func(blocks[i]))
        end
        return s
    end)
end

for (f, f_merge) in REDUCTION_FUNCS
    @eval begin
        Base.$f(block_array::BlockArray) = @blockwise_reduction($f, $f_merge)
    end
end
