module BlockArraysLazyArraysExt

import BlockArrays
import LazyArrays

BlockArrays._broadcaststyle(S::LazyArrays.LazyArrayStyle{1}) = S

end
