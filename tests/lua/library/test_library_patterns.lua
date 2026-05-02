--- BDD tests for library.patterns

require("tests/lua/init")

describe("library: patterns", function()
	it("bootstraps library test environment", function()
		expect_type("table", lurek)
	end)
end)
test_summary()
