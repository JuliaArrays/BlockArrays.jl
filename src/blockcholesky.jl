
##########################
# Cholesky Factorization #
##########################

"""
Instructions and examples
"""

"""
Update
1.changed all computations into in-place but there are still many allocations 
which is highly depended on the number of blocks.
For example, I took a block matrix A with n=5 and d=3 and it had 59 allocations. The build-in only have 5 instead.
I will focus on reducing these allocations.

2.I added 'cholesky' 'cholesky!' and 'cholcopy' in 'BlockArrays.jl' and included the file in my local version during the test.
"""


"""
Funtions to do

1.cholesky structure

2.check square

3.check positive definite

4.swap 'cholesky!'

"""
cholesky(A::Symmetric{<:Real,<:BlockArray},
    ::Val{false}=Val(false); check::Bool = true) = cholesky!(cholcopy(A); check = check)

function cholesky!(A::Symmetric{<:Real,<:BlockArray}; check::Bool = true)
    chol_P = parent(A)

    # Initializing the first role of blocks
    cholesky!(Symmetric(getblock(chol_P,1,1)))
    for j = 2:blocksize(A)[1]
        ldiv!(UpperTriangular(getblock(chol_P,1,1))', getblock(chol_P,1,j))
    end

        # For the left blocks
     for i = 2:blocksize(A)[1]
        for j = i:blocksize(A)[1]
            if j == i
                Pij = getblock(chol_P,i,j) # Will this asign an allocation? Or we can just use getblock() in mul! ?
                for k = 1:j-1
                    mul!(Pij,getblock(chol_P,k,j)',getblock(chol_P,k,j),-1.0,1.0)
                end
                cholesky!(Symmetric(Pij); check=check)
            else
                Pinj = getblock(chol_P,i,j)
                for k = 1:i-1
                    mul!(Pinj,getblock(chol_P,k,i)',getblock(chol_P,k,j),-1.0,1.0)
                end
                ldiv!(UpperTriangular(getblock(chol_P,i,i))', Pinj)
            end
        end
    end
    
    return UpperTriangular(chol_P)
end


