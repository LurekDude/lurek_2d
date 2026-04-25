---@diagnostic disable: undefined-global
-- CORRECT: golden test re-runs algorithm and compares against baseline
it("perlin noise value is stable across engine versions", function()
    local v = lurek.procgen.perlinNoise(0.5, 0.5, 8.0, 8.0)
    expect_near(0.0, v, 0.5)   -- value within expected range
    -- For regression: compare v against a stored snapshot value
end)

-- WRONG: golden test writes a file → should be in evidence test
it("golden generates PNG", function()
    lurek.image.savePNG(img, "tests/lua/golden/samples/particle/emitter.png")  -- WRONG
end)
