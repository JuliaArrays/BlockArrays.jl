function Base.convert(::Type{BlockArray{T, N}}, A::PseudoBlockArray{T2, N}) where {T,T2,N}
    BlockArray(convert(Array{T, N}, Array(A)), A.block_sizes)
end
Base.convert(::Type{BlockArray{T, N, R}}, A::PseudoBlockArray{T2, N}) where {T,T2,N,R} = convert(BlockArray{T, N}, A)
Base.convert(::Type{BlockArray{T1}}, A::PseudoBlockArray{T2, N}) where {T1,T2,N} = convert(BlockArray{T1, N}, A)
Base.convert(::Type{BlockArray}, A::PseudoBlockArray{T, N}) where {T,N} = convert(BlockArray{T, N}, A)
BlockArray(A::BlockArray) = convert(BlockArray, A)

function Base.convert(::Type{PseudoBlockArray{T, N}}, A::BlockArray{T2, N}) where {T,T2,N}
    PseudoBlockArray(convert(Array{T, N}, Array(A)), A.block_sizes)
end
Base.convert(::Type{PseudoBlockArray{T, N, R}}, A::BlockArray{T2, N}) where {T,T2,N,R} = convert(PseudoBlockArray{T, N}, A)
Base.convert(::Type{PseudoBlockArray}, A::BlockArray{T, N}) where {T,N} = convert(PseudoBlockArray{T, N}, A)
Base.convert(::Type{PseudoBlockArray{T1}}, A::BlockArray{T2, N}) where {T1,T2,N} = convert(PseudoBlockArray{T1, N}, A)
PseudoBlockArray(A::BlockArray) = convert(PseudoBlockArray, A)
