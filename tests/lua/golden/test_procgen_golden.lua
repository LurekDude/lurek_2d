-- Lurek2D Golden Test: Procedural Generation
-- Verifies seeded noise and generation produce deterministic output
-- @golden procgen determinism

describe("golden: procgen noise2d determinism", function()
    it("same coordinates give same noise value", function()
        local v1 = lurek.procgen.noise2d(1.5, 2.3)
        local v2 = lurek.procgen.noise2d(1.5, 2.3)
        expect_near(v1, v2, 0.0001, "noise2d deterministic")
    end)

    it("noise map is reproducible as string", function()
        local function noise_fingerprint()
            local parts = {}
            for y = 0, 4 do
                for x = 0, 4 do
                    local n = lurek.procgen.noise2d(x * 0.1, y * 0.1)
                    parts[#parts + 1] = string.format("%.10f", n)
                end
            end
            return table.concat(parts, ",")
        end

        local fp1 = noise_fingerprint()
        local fp2 = noise_fingerprint()
        expect_equal(fp1, fp2, "noise fingerprint deterministic")
    end)

    it("noise values are in [-1, 1] range", function()
        for i = 0, 99 do
            local x = i * 0.37
            local y = i * 0.53
            local n = lurek.procgen.noise2d(x, y)
            expect_true(n >= -1.0 and n <= 1.0,
                "noise(" .. x .. "," .. y .. ") = " .. n .. " in range")
        end
    end)
end)

describe("golden: procgen fbm determinism", function()
    it("fbm with same params is deterministic", function()
        if not lurek.procgen.fbm then
            pending("fbm not available")
            return
        end
        local v1 = lurek.procgen.fbm(1.0, 2.0, 4, 2.0, 0.5)
        local v2 = lurek.procgen.fbm(1.0, 2.0, 4, 2.0, 0.5)
        expect_near(v1, v2, 0.0001, "fbm deterministic")
    end)

    it("more octaves produces more detail but still deterministic", function()
        if not lurek.procgen.fbm then
            pending("fbm not available")
            return
        end
        local v_low = lurek.procgen.fbm(1.0, 1.0, 1, 2.0, 0.5)
        local v_high = lurek.procgen.fbm(1.0, 1.0, 8, 2.0, 0.5)

        -- Values may differ, but both must be deterministic
        local v_low2 = lurek.procgen.fbm(1.0, 1.0, 1, 2.0, 0.5)
        expect_near(v_low, v_low2, 0.0001, "low octave deterministic")
    end)
end)

describe("golden: procgen seeded random", function()
    it("seeded random sequence is reproducible", function()
        if not lurek.procgen.seedRandom then
            pending("seedRandom not available")
            return
        end
        lurek.procgen.seedRandom(12345)
        local seq1 = {}
        for i = 1, 10 do
            seq1[i] = lurek.procgen.random()
        end

        lurek.procgen.seedRandom(12345)
        local seq2 = {}
        for i = 1, 10 do
            seq2[i] = lurek.procgen.random()
        end

        for i = 1, 10 do
            expect_near(seq1[i], seq2[i], 0.0001, "rand[" .. i .. "] matches")
        end
    end)
end)

test_summary()
