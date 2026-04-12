-- Golden test: serial — deterministic text output comparison
-- @golden
-- @covers lurek.serial.base64Encode
-- @covers lurek.serial.hexEncode

describe("golden: serial Encode/decode deterministic output", function()
    it("produces deterministic text output", function()

        local output = {}
        local b64 = lurek.serial.base64Encode("Hello, World!")
        output[#output + 1] = "base64=" .. b64
        local hex = lurek.serial.hexEncode("ABC")
        output[#output + 1] = "hex=" .. hex
        local text = table.concat(output, "\n") .. "\n"

        local path = evidence_output_dir("serial") .. "serial_golden.txt"
        ensure_evidence_dir("serial")
        local f = io.open(path, "w")
        if f then f:write(text); f:close() end
        expect_evidence_created(path)
    end)

    it("matches golden sample", function()
        local evidence = evidence_output_dir("serial") .. "serial_golden.txt"
        local golden = "tests/lua/golden/samples/serial/serial_golden.txt"
        expect_golden_text_match(evidence, golden)
    end)
end)

test_summary()
