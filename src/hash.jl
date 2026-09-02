##
# hash
#
# `Base.hash(::AbstractArray, ::UInt)` hashes the endpoints of the axes and then walks the
# entries backwards from the last index, which neither terminates nor is well-defined when the
# range is infinite, as `blockedrange(Fill(2,∞))` and `Block(1):Block(ℵ₀)` are when this package
# is used together with `InfiniteArrays`. Neither of those types is an `AbstractBlockArray`, so
# neither is covered by the `LayoutArray` method in `ArrayLayouts`.
#
# Such a range is hashed with the same recipe as `Base`'s, except that the entries are taken from
# a finite window at the start. Equal ranges have equal axes and equal entries, so the contract
# `isequal(a,b) ⟹ hash(a) == hash(b)` is preserved; the price is that ranges which first differ
# outside the window collide. Ranges with finite axes are left to `Base`.
#
# `FillArrays`, `ArrayLayouts` and `InfiniteArrays` hash the infinite arrays they own with this
# same scheme; keep the seeds and the window size in sync so that arrays which compare equal
# across packages keep hashing alike.
##

const hash_infinity_seed = UInt === UInt64 ? 0x3a4c1b6d9e2f5087 : 0x9e2f5087
const hash_infarray_seed = UInt === UInt64 ? 0x5d7e3f11a8c6b024 : 0xa8c6b024

# number of entries hashed along each dimension of an infinite array
const hash_nentries = 8

# An infinite axis has an infinite endpoint, which `Base` cannot hash, so hash the direction it
# points in instead: infinities pointing the same way compare equal and hence have to hash alike.
_hash_endpoint(x, h::UInt) = isinf(x) ? hash(signbit(x), h + hash_infinity_seed) : hash(x, h)

"""
    _hash_indices(ax)

The indices along the axis `ax` at which entries get hashed: the first `hash_nentries` of them, or
all of `ax` when it is shorter than that. A bi-infinite axis has no first index, so there the
window starts at zero instead.
"""
function _hash_indices(ax::AbstractUnitRange)
    a = first(ax)
    isinf(a) && return 0:hash_nentries-1
    b = a + hash_nentries - 1
    a:(isinf(last(ax)) ? b : min(last(ax), b))
end
_hash_indices(ax) = Iterators.take(ax, hash_nentries)

function _hash_infarray(A::AbstractArray, h::UInt)
    h += hash_infarray_seed
    # the axes are arrays in their own right, so hash their endpoints instead of the axes
    for ax in axes(A)
        h = _hash_endpoint(first(ax), h)
    end
    for ax in axes(A)
        h = _hash_endpoint(last(ax), h)
    end
    for I in Iterators.product(map(_hash_indices, axes(A))...)
        h = hash(A[I...], h)
    end
    h
end

# `length` is the product of the axis lengths, and `0 * ℵ₀` throws, so ask the axes one at a time
_hasinfaxes(A::AbstractArray) = any(ax -> isinf(length(ax)), axes(A))

Base.hash(A::Union{AbstractBlockedUnitRange,BlockRange}, h::UInt) =
    _hasinfaxes(A) ? _hash_infarray(A, h) : invoke(hash, Tuple{AbstractArray,UInt}, A, h)
