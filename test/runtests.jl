using BlockArrays
if VERSION >= v"0.5-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

let
	BA_1 = BlockArray(Float64, [1,2,3])
	a_1 = rand(2)
	BA_1[Block(2)] = a_1
	@test BA_1[Block(2)] == a_1
	@test BA_1[2] == a_1[1]
	@test_throws ArgumentError BA_1[Block(3)] = rand(4)

	BA_2 = BlockArray(Float64, [1,2], [3,4])
	a_2 = rand(1,4)
	BA_2[Block(1,2)] = a_2
	@test BA_2[Block(1,2)] == a_2
	@test BA_2[1,5] == a_2[2]
	@test_throws ArgumentError BA_2[Block(1,2)] = rand(1,5)
end
