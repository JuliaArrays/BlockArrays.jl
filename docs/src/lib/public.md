```@meta
CurrentModule = BlockArrays
```

# Public Documentation

Documentation for `BlockArrays.jl`'s public interface.

See [Internal Documentation](@ref) for internal package docs covering all submodules.


## Contents

```@contents
Pages = ["public.md"]
```

## Index

```@index
Pages = ["public.md"]
```

## AbstractBlockArray interface

This sections defines the functions a subtype of `AbstractBlockArray` should define to be a part of the `AbstractBlockArray` interface. An `AbstractBlockArray{T, N}` is a subtype of `AbstractArray{T,N}` and should therefore also fulfill the [`AbstractArray` interface](http://docs.julialang.org/en/latest/manual/interfaces/#abstract-arrays).

```@docs
AbstractBlockArray
BlockBoundsError
Block
BlockIndex
blockaxes
blockisequal
blocksize
blockfirsts
blocklasts
blocklengths
blocksizes
blocks
eachblock
blockcheckbounds
```

## BlockArray

```@docs
BlockArray
BlockArray(::UndefBlocksInitializer, ::Type{R}, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N, R<:AbstractArray{T,N}}
BlockArray{T}(::UndefBlocksInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N}
BlockArray{T}(::UndefInitializer, block_sizes::Vararg{AbstractVector{<:Integer}, N}) where {T, N}
undef_blocks
UndefBlocksInitializer
mortar
blockappend!
blockpush!
blockpushfirst!
blockpop!
blockpopfirst!
Base.append!
Base.push!
Base.pushfirst!
Base.pop!
Base.popfirst!
```


## PseudoBlockArray

```@docs
PseudoBlockArray
PseudoBlockVector
PseudoBlockMatrix
Base.resize!
```


## Kronecker products
```@docs
blockkron
BlockKron
blockvec
khatri_rao
```
