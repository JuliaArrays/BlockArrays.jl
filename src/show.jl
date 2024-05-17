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

    row_sum = blocklasts(axes(X,1))
    if ndims(X) == 2
        col_sum = blocklasts(axes(X,2))[1:end-1]
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
            if block < blocksize(X,2) && cumul == length(axes(X,2)[Block(block)])
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

function _show_typeof(io::IO, a::BlockVector{T,Vector{Vector{T}},Tuple{DefaultBlockAxis}}) where T
    print(io, "BlockVector{")
    show(io, T)
    print(io, '}')
end

function _show_typeof(io::IO, a::BlockMatrix{T,Matrix{Matrix{T}},NTuple{2,DefaultBlockAxis}}) where T
    print(io, "BlockMatrix{")
    show(io, T)
    print(io, '}')
end

function _show_typeof(io::IO, a::BlockArray{T,N,Array{Array{T,N},N},NTuple{N,DefaultBlockAxis}}) where {T,N}
    Base.show_type_name(io, typeof(a).name)
    print(io, '{')
    show(io, T)
    print(io, ", ")
    show(io, N)
    print(io, '}')
end

# LayoutArray with blocked axes will dispatch to here
axes_print_matrix_row(::Tuple{AbstractBlockedUnitRange}, io, X, A, i, cols, sep) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
axes_print_matrix_row(::NTuple{2,AbstractBlockedUnitRange}, io, X, A, i, cols, sep) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
axes_print_matrix_row(::Tuple{AbstractUnitRange,AbstractBlockedUnitRange}, io, X, A, i, cols, sep) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)
axes_print_matrix_row(::Tuple{AbstractBlockedUnitRange,AbstractUnitRange}, io, X, A, i, cols, sep) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)

# Need to handled AbstractBlockedUnitRange, which is not a LayoutVector
Base.print_matrix_row(io::IO, X::AbstractBlockedUnitRange, A::Vector, i::Integer, cols::AbstractVector, sep::AbstractString, idxlast::Integer=last(axes(X, 2))) =
        _blockarray_print_matrix_row(io, X, A, i, cols, sep)

function _show_typeof(io::IO, a::BlockedVector{T,Vector{T},Tuple{DefaultBlockAxis}}) where T
    print(io, "BlockedVector{")
    show(io, T)
    print(io, '}')
end

function _show_typeof(io::IO, a::BlockedMatrix{T,Matrix{T},NTuple{2,DefaultBlockAxis}}) where T
    print(io, "BlockedMatrix{")
    show(io, T)
    print(io, '}')
end

function _show_typeof(io::IO, a::BlockedArray{T,N,Array{T,N},NTuple{N,DefaultBlockAxis}}) where {T,N}
    Base.show_type_name(io, typeof(a).name)
    print(io, '{')
    show(io, T)
    print(io, ", ")
    show(io, N)
    print(io, '}')
end

function Base.showarg(io::IO, A::BlockedArray, toplevel::Bool)
    if toplevel
        print(io, "BlockedArray of ")
        Base.showarg(io, A.blocks, true)
    else
        print(io, "::BlockedArray{…,")
        Base.showarg(io, A.blocks, false)
        print(io, '}')
    end
end

# Utility function to print elements of tuples as a comma-separated list
function print_tuple_elements(io::IO, @nospecialize(t))
    if !isempty(t)
        print(io, t[1])
        for n in t[2:end]
            print(io, ", ", n)
        end
    end
    return nothing
end

# Block

_typename(::Block{N,Int}) where {N} = "Block"
_typename(x::Block) = typeof(x)

function Base.show(io::IO, B::Block)
    print(io, _typename(B))
    print(io, "(")
    print_tuple_elements(io, B.n)
    print(io, ")")
end

# Block indices

function Base.show(io::IO, B::BlockIndex)
    show(io, Block(B.I...))
    print(io, "[")
    print_tuple_elements(io, B.α)
    print(io, "]")
end

function Base.show(io::IO, B::BlockIndexRange)
    show(io, Block(B))
    print(io, "[")
    print_tuple_elements(io, B.indices)
    print(io, "]")
end
Base.show(io::IO, ::MIME"text/plain", B::BlockIndexRange) = show(io, B)

Base.show(io::IO, mimetype::MIME"text/plain", a::AbstractBlockedUnitRange) =
    Base.invoke(show, Tuple{typeof(io),MIME"text/plain",AbstractArray},io, mimetype, a)

show(io::IO, r::BlockSlice) = print(io, "BlockSlice(", r.block, ",", r.indices, ")")

function Base.showarg(io::IO, @nospecialize(a::BlocksView), toplevel::Bool)
    if toplevel
        print(io, "blocks of ")
        Base.showarg(io, a.array, true)
    else
        print(io, "::BlocksView{…,")
        Base.showarg(io, a.array, false)
        print(io, '}')
    end
end

# BlockRange

Base.show(io::IO, br::BlockRange) = print(io, "BlockRange(", join(br.indices, ", "), ")")
Base.show(io::IO, ::MIME"text/plain", br::BlockRange) = show(io, br)

# AbstractBlockedUnitRange
Base.show(io::IO, b::BlockedOneTo) = print(io, BlockedOneTo, "(", blocklasts(b), ")")
