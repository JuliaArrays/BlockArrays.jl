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