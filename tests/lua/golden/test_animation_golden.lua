-- Golden test: animation          compare evidence output against golden samples

describe("golden: animation evidence comparison", function()
    it("matches golden sample for sprite_frames.png", function()
        local evidence = evidence_output_dir("animation") .. "sprite_frames.png"
        local golden = "tests/samples/animation/sprite_frames.png"
        expect_golden_file_match(evidence, golden)
    end)
end)
test_summary()
