-- Golden test: data — deterministic text output comparison
-- @golden
-- @covers lurek.data.encodeJSON

describe("golden: data JSON/TOML serialization round-trip", function()
    it("produces deterministic text output", function()

        local output = {}
        local tbl = {name = "test", value = 42, nested = {a = 1}}
        local json = lurek.data.encodeJSON(tbl)
        output[#output + 1] = "json=" .. json
        local text = table.concat(output, "\n") .. "\n"

        local path = evidence_output_dir("data") .. "data_golden.txt"
        ensure_evidence_dir("data")
        local f = io.open(path, "w")
        if f then f:write(text); f:close() end
        expect_evidence_created(path)
    end)

    it("matches golden sample", function()
        local evidence = evidence_output_dir("data") .. "data_golden.txt"
        local golden = "tests/lua/golden/samples/data/data_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)

test_summary()
