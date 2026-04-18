-- tests/lua/golden/test_data_golden.lua
describe("JSON round-trip golden", function()
    it("encodes table to expected JSON string", function()
        local data = { name = "test", value = 42 }
        local json = lurek.data.encode(data, "json")
        local expected = '{"name":"test","value":42}'
        expect_equal(expected, json)
    end)
end)
test_summary()
