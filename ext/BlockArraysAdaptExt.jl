module BlockArraysAdaptExt

using Adapt
using BlockArrays
using BlockArrays: _BlockArray, _BlockedUnitRange
import Adapt: adapt_structure

adapt_structure(to, r::BlockedUnitRange) = _BlockedUnitRange(adapt(to, r.first), map(adapt(to), r.lasts))
adapt_structure(to, r::BlockedOneTo) = BlockedOneTo(map(adapt(to), r.lasts))

adapt_structure(to, A::BlockArray) = _BlockArray(map(adapt(to), blocks(A)), map(adapt(to), axes(A)))
adapt_structure(to, A::BlockedArray) = BlockedArray(adapt(to, A.blocks), map(adapt(to), axes(A)))

end
