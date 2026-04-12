-- Golden test: animation — compare evidence output against golden samples
-- @golden

describe("golden: animation evidence comparison", function()
    it("matches golden sample for sprite_frames.png", function()
        local evidence = evidence_output_dir("animation") .. "sprite_frames.png"
        local golden = "tests/lua/golden/samples/animation/sprite_frames.png"
        expect_golden_file_match(evidence, golden)
    end)
end)

test_summary()
