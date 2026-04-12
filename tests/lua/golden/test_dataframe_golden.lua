-- Golden test: dataframe — deterministic text output comparison
-- @golden
-- @covers lurek.dataframe.new
-- @covers DataFrame:addColumn
-- @covers DataFrame:sum
-- @covers DataFrame:mean

describe("golden: dataframe DataFrame deterministic statistics", function()
    it("produces deterministic text output", function()

        local output = {}
        local df = lurek.dataframe.new()
        df:addColumn("values", {10, 20, 30, 40, 50})
        output[#output + 1] = "row_count=5"
        output[#output + 1] = "sum=" .. string.format("%.6f", df:sum("values"))
        output[#output + 1] = "mean=" .. string.format("%.6f", df:mean("values"))
        local text = table.concat(output, "\n") .. "\n"

        local path = evidence_output_dir("dataframe") .. "dataframe_golden.txt"
        ensure_evidence_dir("dataframe")
        local f = io.open(path, "w")
        if f then f:write(text); f:close() end
        expect_evidence_created(path)
    end)

    it("matches golden sample", function()
        local evidence = evidence_output_dir("dataframe") .. "dataframe_golden.txt"
        local golden = "tests/lua/golden/samples/dataframe/dataframe_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)

test_summary()
