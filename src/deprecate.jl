@deprecate BlockArray(blocks::Array{R, N}, block_sizes::BlockSizes{N}) where {T, N, R <: AbstractArray{T, N}} BlockArrays._BlockArray(blocks, block_sizes)
@deprecate BlockArray(blocks::Array{R, N}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R <: AbstractArray{T, N}}  BlockArrays._BlockArray(blocks, block_sizes...)
@deprecate BlockArray(::Type{R}, block_sizes::BlockSizes{N}) where {T, N, R <: AbstractArray{T, N}} BlockArrays._BlockArray(R, block_sizes)
@deprecate BlockArray(::Type{R}, block_sizes::Vararg{AbstractVector{Int}, N}) where {T, N, R <: AbstractArray{T, N}}  BlockArrays._BlockArray(R, block_sizes...)
