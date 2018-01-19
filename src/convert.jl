BlockArray{T, N}(A::PseudoBlockArray{T2, N}) where {T,T2,N} = BlockArray(Array{T, N}(A), A.block_sizes)
BlockArray{T, N, R}(A::PseudoBlockArray{T2, N}) where {T,T2,N,R} = BlockArray{T, N}(A)
BlockArray{T1}(A::PseudoBlockArray{T2, N}) where {T1,T2,N} = BlockArray{T1, N}(A)
BlockArray(A::PseudoBlockArray{T, N}) where {T,N} = BlockArray{T, N}(A)

PseudoBlockArray{T, N}(A::BlockArray{T2, N}) where {T,T2,N} = PseudoBlockArray(Array{T, N}(A), A.block_sizes)
PseudoBlockArray{T, N, R}(A::BlockArray{T2, N}) where {T,T2,N,R} = PseudoBlockArray{T, N}(A)
PseudoBlockArray{T1}(A::BlockArray{T2, N}) where {T1,T2,N} = PseudoBlockArray{T1, N}(A)
PseudoBlockArray(A::BlockArray{T, N}) where {T,N} = PseudoBlockArray{T, N}(A)

convert(::Type{BA}, A::PseudoBlockArray) where BA <: BlockArray = BA(A)
convert(::Type{BA}, A::BlockArray) where BA <: PseudoBlockArray = BA(A)
