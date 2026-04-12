-- Golden test: physics — compare evidence output against golden samples
-- @golden

describe("golden: physics evidence comparison", function()
    it("matches golden sample for draw_debug.png", function()
        local evidence = evidence_output_dir("physics") .. "draw_debug.png"
        local golden = "tests/lua/golden/samples/physics/draw_debug.png"
        expect_golden_file_match(evidence, golden)
    end)
end)

test_summary()
