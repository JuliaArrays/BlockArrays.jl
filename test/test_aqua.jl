module AquaTest

using BlockArrays
using Test
import Aqua

@testset "Project quality" begin
    Aqua.test_all(BlockArrays, ambiguities=false)
end

end
