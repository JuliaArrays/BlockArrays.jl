module BlockArraysAdaptExt

using Adapt
using BlockArrays
using BlockArrays: _BlockedUnitRange
import Adapt: adapt_structure

adapt_structure(to, r::BlockedUnitRange) = _BlockedUnitRange(adapt(to, r.first), map(adapt(to), r.lasts))
adapt_structure(to, r::BlockedOneTo) = BlockedOneTo(map(adapt(to), r.lasts))

end
