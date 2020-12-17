"""
    khatri_rao(A, B)

References
* Liu, Shuangzhe, and Gõtz Trenkler (2008) Hadamard, Khatri-Rao, Kronecker and Other Matrix Products. International J. Information and Systems Sciences 4, 160–177.
* Khatri, C. G., and Rao, C. Radhakrishna (1968) Solutions to Some Functional Equations and Their Applications to Characterization of Probability Distributions. Sankhya: Indian J. Statistics, Series A 30, 167–180.
"""
function khatri_rao(A::AbstractBlockMatrix, B::AbstractBlockMatrix)
    #
    Ablksize = blocksize(A)
    Bblksize = blocksize(B)

    @assert Ablksize == Bblksize "A and B must have the same blocksize"

    kblk = []
    for iblk in blockaxes(A,1)
        kblk_j = []
        for _jblk in blockaxes(A,2)
            Ablk = A[iblk, _jblk]
            Bblk = B[iblk, _jblk]
            push!(kblk_j, kron(Ablk, Bblk))
        end
        push!(kblk, tuple(kblk_j...))
    end
    mortar(kblk...)
end

function khatri_rao(A::AbstractMatrix, B::AbstractMatrix)
    kron(A, B)
end

""""
    BlockKron(A...)

creates a lazy representation of kron(A...) with the natural
block-structure imposed. This is a component in `blockkron(A...)`.
"""
struct BlockKron{T,N,ARGS<:Tuple} <: AbstractBlockArray{T,N}
    args::ARGS
end

BlockKron{T,N}(A...) where {T,N} = BlockKron{T,N,typeof(A)}(A)
BlockKron{T}(A::AbstractVector, B::AbstractVector, C::AbstractVector...) where {T} = BlockKron{T,1}(A, B, C...)
BlockKron{T}(A, B, C...) where {T} = BlockKron{T,2}(A, B, C...)
BlockKron(A, B, C...) = BlockKron{mapreduce(eltype,promote_type,(A,B,C...))}(A, B, C...)


size(B::BlockKron) = size(Kron(B))

size(K::BlockKron, j::Int) = prod(size.(K.args, j))
size(a::BlockKron{<:Any,1}) = (size(a,1),)
size(a::BlockKron{<:Any,2}) = (size(a,1), size(a,2))

function axes(K::BlockKron{<:Any,1})
    A,B = K.args
    (blockedrange(fill(prod(size.(tail(K.args),1)), size(K.args[1],1))),)
end

function axes(K::BlockKron{<:Any,2})
    A,B = K.args
    blockedrange.((fill(prod(size.(tail(K.args),1)), size(K.args[1],1)),
                   fill(prod(size.(tail(K.args),2)), size(K.args[1],2))))
end

kron_getindex((A,)::Tuple{AbstractVector}, k::Integer) = A[k]
function kron_getindex((A,B)::NTuple{2,AbstractVector}, k::Integer)
    K,κ = divrem(k-1, length(B))
    A[K+1]*B[κ+1]
end
kron_getindex((A,)::Tuple{AbstractMatrix}, k::Integer, j::Integer) = A[k,j]
function kron_getindex((A,B)::NTuple{2,AbstractVecOrMat}, k::Integer, j::Integer)
    K,κ = divrem(k-1, size(B,1))
    J,ξ = divrem(j-1, size(B,2))
    A[K+1,J+1]*B[κ+1,ξ+1]
end

kron_getindex(args::Tuple, k::Integer, j::Integer) = kron_getindex(tuple(BlockKron(args[1:2]...), args[3:end]...), k, j)
kron_getindex(args::Tuple, k::Integer) = kron_getindex(tuple(BlockKron(args[1:2]...), args[3:end]...), k)

getindex(K::BlockKron{<:Any,1}, k::Integer) = kron_getindex(K.args, k)
getindex(K::BlockKron{<:Any,2}, k::Integer, j::Integer) = kron_getindex(K.args, k, j)

kron_viewblock((a,b)::Tuple{Any,Any}, k::Integer) = a[k]*b
kron_viewblock(args, k::Integer) = args[1][k]*BlockKron(tail(args)...)

kron_viewblock((a,b)::Tuple{Any,Any}, k::Integer, j::Integer) = a[k,j]*b
kron_viewblock(args, k::Integer, j::Integer) = args[1][k,j]*BlockKron(tail(args)...)

viewblock(K::BlockKron{<:Any,1}, k::Block{1}) = kron_viewblock(K.args, Int(k))
viewblock(K::BlockKron{<:Any,2}, kj::Block{2}) = kron_viewblock(K.args, Int.(kj.n)...)

# const SubKron{T,M1,M2,R1,R2} = SubArray{T,2,<:BlockKron{T,M1,M2},<:Tuple{<:BlockSlice{R1},<:BlockSlice{R2}}}


# BroadcastStyle(::Type{<:SubKron{<:Any,<:Any,B,Block1,Block1}}) where B =
#     BroadcastStyle(B)


# allow dispatch on memory layout
_blockkron(_, A) = BlockArray(BlockKron(A...))


""""
    blockkron(A...)

creates a blocked version of kron(A...) with the natural
block-structure imposed.
"""
blockkron(A...) = _blockkron(map(MemoryLayout,A), A)

"""
    blockvec(A::AbstractMatrix)

creates a blocked version of `vec(A)`, with the block structure used to represent the columns.
"""
blockvec(A::AbstractMatrix) = PseudoBlockVector(vec(A), Fill(size(A,1), size(A,2)))
