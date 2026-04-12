-- Golden test: procgen — compare evidence output against golden samples
-- @golden

describe("golden: procgen evidence comparison", function()
    it("matches golden sample for noise_map.png", function()
        local evidence = evidence_output_dir("procgen") .. "noise_map.png"
        local golden = "tests/lua/golden/samples/procgen/noise_map.png"
        expect_golden_file_match(evidence, golden)
    end)
end)

test_summary()
