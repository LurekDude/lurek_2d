-- tests/lua/unit/test_mymodule.lua  (rename <module> to the real module name)
-- Lurek2D MyModule API Tests
-- Covers namespace surface, constructors, and representative edge cases.

-- @description Groups module-level surface checks for lurek.mymodule.
describe("lurek.mymodule module exists", function()
    -- @description Verifies the module namespace is present as a Lua table.
    it("is a table", function()
        expect_type("table", lurek.mymodule)
    end)
end)


-- @description Covers one concrete function family in the module.
describe("lurek.mymodule.myfunc", function()
    -- @description Verifies the function returns a non-nil numeric result for valid input.
    it("returns expected type", function()
        local result = lurek.mymodule.myfunc(1, 2)
        expect_not_nil(result)
        expect_type("number", result)
    end)

    -- @description Verifies the numeric result matches the expected value within tolerance.
    it("numeric results match within tolerance", function()
        expect_near(3.14159, lurek.mymodule.pi, 0.0001)
    end)
end)

test_summary()  -- REQUIRED: must be last line in every Lua test file
