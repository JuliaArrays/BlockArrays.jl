function Base.convert{T, T2, N}(::Type{BlockArray{T, N}}, A::PseudoBlockArray{T2, N})
    BlockArray(convert(Array{T, N}, Array(A)), A.block_sizes)
end
Base.convert{T, T2, N, R}(::Type{BlockArray{T, N, R}}, A::PseudoBlockArray{T2, N}) = convert(BlockArray{T, N}, A)
Base.convert{T1, T2, N}(::Type{BlockArray{T1}}, A::PseudoBlockArray{T2, N}) = convert(BlockArray{T1, N}, A)
Base.convert{T, N}(::Type{BlockArray}, A::PseudoBlockArray{T, N}) = convert(BlockArray{T, N}, A)
BlockArray(A::BlockArray) = convert(BlockArray, A)

function Base.convert{T, T2, N}(::Type{PseudoBlockArray{T, N}}, A::BlockArray{T2, N})
    PseudoBlockArray(convert(Array{T, N}, Array(A)), A.block_sizes)
end
Base.convert{T, T2, N, R}(::Type{PseudoBlockArray{T, N, R}}, A::BlockArray{T2, N}) = convert(PseudoBlockArray{T, N}, A)
Base.convert{T, N}(::Type{PseudoBlockArray}, A::BlockArray{T, N}) = convert(PseudoBlockArray{T, N}, A)
Base.convert{T1, T2, N}(::Type{PseudoBlockArray{T1}}, A::BlockArray{T2, N}) = convert(PseudoBlockArray{T1, N}, A)
PseudoBlockArray(A::BlockArray) = convert(PseudoBlockArray, A)
