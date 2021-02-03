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
blocks
eachblock
blockcheckbounds
```

## BlockArray

```@docs
BlockArray
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
```


## Kronecker products
```@docs
blockkron
BlockKron
blockvec
khatri_rao
```