"""
    khatri_rao(A, B)

References
* Liu, Shuangzhe, and Gõtz Trenkler (2008) Hadamard, Khatri-Rao, Kronecker and Other Matrix Products. International J. Information and Systems Sciences 4, 160–177.
* Khatri, C. G., and Rao, C. Radhakrishna (1968) Solutions to Some Functional Equations and Their Applications to Characterization of Probability Distributions. Sankhya: Indian J. Statistics, Series A 30, 167–180.
"""
function khatri_rao(A::AbstractBlockMatrix, B::AbstractBlockMatrix)
    # 
    _Ablksize = blocksize(A)
    _Bblksize = blocksize(B)

    @assert _Ablksize == _Bblksize "A and B must have the same blocksize"

    _kblk = []
    for _iblk in 1:_Ablksize[1]
        _kblk_j = []
        for _jblk in 1:_Ablksize[2]
            _Ablk = A[Block(_iblk, _jblk)]
            _Bblk = B[Block(_iblk, _jblk)]
            push!(_kblk_j, kron(_Ablk, _Bblk))
        end
        push!(_kblk, tuple(_kblk_j...))
    end
    mortar(_kblk...)
end

function khatri_rao(A::AbstractMatrix, B::AbstractMatrix)
    kron(A, B)
end