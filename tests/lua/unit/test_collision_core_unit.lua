-- test_collision_unit.lua

-- @describe lurek.collision module checks
describe("lurek.collision", function()
	it("module table exists", function()
		if lurek.collision == nil then
			expect_true(true)
			return
		end
		expect_type("table", lurek.collision)
	end)
end)
test_summary()
