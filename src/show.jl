
import Base.alignment

# A bit of a mess but does the job...

# sortedin(p, sc)
# returns true if `p` is in `sc`, assuming that `sc` is monotonically increasing.
function sortedin(x, itr)
    for y in itr
        if y == x
            return true
        elseif y > x
            return false
        end
    end
    return false
end

function _blockarray_print_matrix_row(io::IO,
        X::AbstractVecOrMat, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString)
    cumul = 0
    block = 1

    row_buf = IOBuffer()

    row_sum = cumulsizes(X,1)[2:end] .- 1
    if ndims(X) == 2
        col_sum = (cumulsizes(X,2)[2:end] .- 1)[1:end-1]
    end

    # Loop over row
    for k = 1:length(A)
        n_chars = 0
        j = cols[k]

        if isassigned(X,Int(i),Int(j)) # isassigned accepts only `Int` indices
            x = X[i,j]
            a = Base.alignment(io, x)
            sx = sprint(show, x; context=io, sizehint=0)
        else
            a = Base.undef_ref_alignment
            sx = Base.undef_ref_str
        end
        l = repeat(" ",A[k][1]-a[1]) # pad on left and right as needed
        r = repeat(" ", A[k][2]-a[2])
        prettysx = Base.replace_in_print_matrix(X,i,j,sx)
        # Print the element
        print(io, l, prettysx, r)

        # Jump forward
        n_chars += length(l) + length(prettysx) + length(r) + 2

        cumul += 1
        if ndims(X) == 2
            # Have accumulated enough for the block, should print a |
            if block < length(cumulsizes(X,2)) - 1 && cumul == blocksize(X, 2, block)
                block += 1
                cumul = 0
                print(io, "  │")
                n_chars += 3
            end
        end


        if k == 1
            n_chars -= 2
        end

        if sortedin(i, row_sum)
            print(row_buf, "─"^(n_chars-1))
            if ndims(X) == 2 && sortedin(k,col_sum)
                print(row_buf, "┼")
            else
                print(row_buf, "─")
            end
        end

        if k < length(A); print(io, sep); end
    end

    if i < size(X, 1)
        row_str = String(take!(row_buf))
        if length(row_str) > 0
            print(io, "\n ")
            print(io, row_str)
        end
    end
end


Base.print_matrix_row(io::IO,
        X::AbstractBlockVecOrMat, A::Vector,
        i::Integer, cols::AbstractVector, sep::AbstractString) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)

function _show_typeof(io::IO, a::BlockArray{T,N,Array{Array{T,N},N},DefaultBlockSizes{N}}) where {T,N}
    Base.show_type_name(io, typeof(a).name)
    print(io, '{')
    show(io, T)
    print(io, ',')
    show(io, N)
    print(io, '}')
end

function _show_typeof(io::IO, a::PseudoBlockArray{T,N,Array{T,N},DefaultBlockSizes{N}}) where {T,N}
    Base.show_type_name(io, typeof(a).name)
    print(io, '{')
    show(io, T)
    print(io, ',')
    show(io, N)
    print(io, '}')
end
