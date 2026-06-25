module DocstringsTest

using Documenter
using Test
import BlockArrays

@testset "docstrings" begin
    # don't test docstrings on old versions to avoid failures due to changes in types
    if v"1.10" <= VERSION < v"1.11.0-"
        DocMeta.setdocmeta!(BlockArrays, :DocTestSetup, :(using BlockArrays); recursive=true)
        doctest(BlockArrays, manual=false)
    end
end

end
