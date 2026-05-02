-- Golden test: procgen          compare evidence output against golden samples

describe("golden: procgen evidence comparison", function()
    it("matches golden sample for noise_map.png", function()
        local evidence = evidence_output_dir("procgen") .. "noise_map.png"
        local golden = "tests/samples/procgen/noise_map.png"
        expect_golden_file_match(evidence, golden)
        expect_golden_file_match(evidence_output_dir("procgen") .. "cellular_automata.png", "tests/samples/procgen/cellular_automata.png")
        expect_golden_file_match(evidence_output_dir("procgen") .. "cellular_cave.png", "tests/samples/procgen/cellular_cave.png")
        expect_golden_file_match(evidence_output_dir("procgen") .. "voronoi_diagram.png", "tests/samples/procgen/voronoi_diagram.png")
        expect_golden_file_match(evidence_output_dir("procgen") .. "voronoi_warped.png", "tests/samples/procgen/voronoi_warped.png")
        expect_golden_file_match(evidence_output_dir("procgen") .. "poisson_disk.png", "tests/samples/procgen/poisson_disk.png")
        expect_golden_file_match(evidence_output_dir("procgen") .. "poisson_dense.png", "tests/samples/procgen/poisson_dense.png")
end)
end)
test_summary()
