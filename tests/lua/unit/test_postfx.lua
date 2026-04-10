-- Lurek2D PostFX API Tests — covers lurek.effect post-processing effects (headless)
-- @covers lurek.effect.getEffectTypes
-- @covers lurek.effect.newEffect
-- @covers lurek.effect.newPass
-- @covers lurek.effect.newStack


describe("lurek.effect module exists", function()
    it("lurek.effect is a table", function()
        expect_type("table", lurek.effect)
    end)
end)

describe("lurek.effect factory functions", function()
    it("newEffect is a function", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    it("newPass is a function", function()
        expect_type("function", lurek.effect.newPass)
    end)

    it("newStack is a function", function()
        expect_type("function", lurek.effect.newStack)
    end)

    it("getEffectTypes is a function", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)
end)

describe("lurek.effect.newEffect built-in types", function()
    it("creates bloom effect", function()
        local e = lurek.effect.newEffect("bloom")
        expect_equal(e:getEffectType(), "bloom")
        expect_equal(e:isBuiltIn(), true)
    end)

    it("creates blur effect", function()
        local e = lurek.effect.newEffect("blur")
        expect_equal(e:getEffectType(), "blur")
    end)

    it("creates crt effect", function()
        local e = lurek.effect.newEffect("crt")
        expect_equal(e:getEffectType(), "crt")
    end)

    it("creates godrays effect", function()
        local e = lurek.effect.newEffect("godrays")
        expect_equal(e:getEffectType(), "godrays")
    end)

    it("creates vignette effect", function()
        local e = lurek.effect.newEffect("vignette")
        expect_equal(e:getEffectType(), "vignette")
    end)

    it("creates colourgrade effect", function()
        local e = lurek.effect.newEffect("colourgrade")
        expect_equal(e:getEffectType(), "colourgrade")
    end)

    it("creates chromatic effect", function()
        local e = lurek.effect.newEffect("chromatic")
        expect_equal(e:getEffectType(), "chromatic")
    end)

    it("rejects invalid effect type", function()
        expect_error(function()
            lurek.effect.newEffect("invalid_type")
        end)
    end)
end)

describe("lurek.effect.newPass custom effects", function()
    it("creates custom pass", function()
        local p = lurek.effect.newPass(1)
        expect_equal(p:getEffectType(), "custom")
        expect_equal(p:isBuiltIn(), false)
    end)
end)

describe("lurek.effect.getEffectTypes", function()
    it("returns table of 15 types", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
        expect_equal(#types, 15)
    end)

    it("contains bloom", function()
        local types = lurek.effect.getEffectTypes()
        local found = false
        for _, t in ipairs(types) do
            if t == "bloom" then found = true end
        end
        expect_equal(found, true)
    end)
end)

describe("PostFxEffect parameters", function()
    it("bloom has default threshold", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:hasParameter("threshold"), true)
    end)

    it("getParameter returns value", function()
        local bloom = lurek.effect.newEffect("bloom")
        local t = bloom:getParameter("threshold")
        expect_type("number", t)
    end)

    it("setParameter changes value", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setParameter("threshold", 0.5)
        local v = bloom:getParameter("threshold")
        expect_equal(math.abs(v - 0.5) < 0.001, true)
    end)

    it("getParameter uses default for missing", function()
        local bloom = lurek.effect.newEffect("bloom")
        local v = bloom:getParameter("nonexistent", 42.0)
        expect_equal(math.abs(v - 42.0) < 0.001, true)
    end)

    it("getParameterNames returns sorted list", function()
        local bloom = lurek.effect.newEffect("bloom")
        local names = bloom:getParameterNames()
        expect_type("table", names)
        expect_equal(#names >= 2, true)
    end)
end)

describe("PostFxEffect convenience setters", function()
    it("setThreshold works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setThreshold(0.8) end)
        expect_equal(math.abs(bloom:getParameter("threshold") - 0.8) < 0.001, true)
    end)

    it("setIntensity works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setIntensity(2.0) end)
        expect_equal(math.abs(bloom:getParameter("intensity") - 2.0) < 0.001, true)
    end)

    it("setRadius works on blur", function()
        local blur = lurek.effect.newEffect("blur")
        expect_no_error(function() blur:setRadius(5.0) end)
        expect_equal(math.abs(blur:getParameter("radius") - 5.0) < 0.001, true)
    end)

    it("setStrength works on vignette", function()
        local vig = lurek.effect.newEffect("vignette")
        expect_no_error(function() vig:setStrength(0.8) end)
        expect_equal(math.abs(vig:getParameter("strength") - 0.8) < 0.001, true)
    end)

    it("setScanlineStrength works on crt", function()
        local crt = lurek.effect.newEffect("crt")
        expect_no_error(function() crt:setScanlineStrength(0.4) end)
        expect_equal(math.abs(crt:getParameter("scanline_strength") - 0.4) < 0.001, true)
    end)

    it("setOffset works on chromatic", function()
        local chr = lurek.effect.newEffect("chromatic")
        expect_no_error(function() chr:setOffset(3.0) end)
        expect_equal(math.abs(chr:getParameter("offset") - 3.0) < 0.001, true)
    end)

    it("setBrightness works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setBrightness(1.5) end)
        expect_equal(math.abs(cg:getParameter("brightness") - 1.5) < 0.001, true)
    end)

    it("setContrast works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setContrast(0.9) end)
        expect_equal(math.abs(cg:getParameter("contrast") - 0.9) < 0.001, true)
    end)

    it("setSaturation works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setSaturation(0.7) end)
        expect_equal(math.abs(cg:getParameter("saturation") - 0.7) < 0.001, true)
    end)
end)

describe("PostFxEffect enable/disable", function()
    it("is enabled by default", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isEnabled(), true)
    end)

    it("setEnabled false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        expect_equal(bloom:isEnabled(), false)
    end)

    it("setEnabled true after false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        bloom:setEnabled(true)
        expect_equal(bloom:isEnabled(), true)
    end)
end)

describe("PostFxEffect type() method", function()
    it("returns PostFxEffect", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:type(), "PostFxEffect")
    end)

    it("custom pass also returns PostFxEffect", function()
        local pass = lurek.effect.newPass(1)
        expect_equal(pass:type(), "PostFxEffect")
    end)
end)

describe("lurek.effect.newStack", function()
    it("creates stack with default dimensions", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getWidth(), 800)
        expect_equal(stack:getHeight(), 600)
    end)

    it("creates stack with custom dimensions", function()
        local stack = lurek.effect.newStack(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)

    it("starts empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getEffectCount(), 0)
    end)

    it("type is PostFxStack", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:type(), "PostFxStack")
    end)
end)

describe("PostFxStack add/remove", function()
    it("add increases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        expect_equal(stack:getEffectCount(), 1)
    end)

    it("add multiple effects", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:add(lurek.effect.newEffect("crt"))
        expect_equal(stack:getEffectCount(), 3)
    end)

    it("remove decreases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        stack:remove(bloom)
        expect_equal(stack:getEffectCount(), 0)
    end)
end)

describe("PostFxStack insert", function()
    it("insert at position 1", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        local blur = lurek.effect.newEffect("blur")
        stack:add(bloom)
        stack:insert(1, blur)
        expect_equal(stack:getEffectCount(), 2)
        -- blur should be at position 1, bloom at position 2
        local e1 = stack:getEffect(1)
        expect_equal(e1:getEffectType(), "blur")
    end)
end)

describe("PostFxStack dimensions", function()
    it("getDimensions returns both", function()
        local stack = lurek.effect.newStack(800, 600)
        local w, h = stack:getDimensions()
        expect_equal(w, 800)
        expect_equal(h, 600)
    end)

    it("resize changes dimensions", function()
        local stack = lurek.effect.newStack(800, 600)
        stack:resize(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)
end)

describe("PostFxStack capturing state", function()
    it("not capturing by default", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:isCapturing(), false)
    end)
end)

-- ── New effect types ─────────────────────────────────────────────────────────

describe("New effect types — construction and defaults", function()
    it("pixelate has block_size default 4.0", function()
        local e = lurek.effect.newEffect("pixelate")
        expect_equal(math.abs(e:getParameter("block_size") - 4.0) < 0.001, true)
    end)

    it("sepia has strength default 1.0", function()
        local e = lurek.effect.newEffect("sepia")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    it("grayscale is built-in", function()
        local e = lurek.effect.newEffect("grayscale")
        expect_equal(e:isBuiltIn(), true)
    end)

    it("invert has strength default 1.0", function()
        local e = lurek.effect.newEffect("invert")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    it("scanlines has spacing default 4.0", function()
        local e = lurek.effect.newEffect("scanlines")
        expect_equal(math.abs(e:getParameter("spacing") - 4.0) < 0.001, true)
    end)

    it("edgedetect has strength default 1.0", function()
        local e = lurek.effect.newEffect("edgedetect")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    it("hueshift has angle default 0.0", function()
        local e = lurek.effect.newEffect("hueshift")
        expect_equal(math.abs(e:getParameter("angle") - 0.0) < 0.001, true)
    end)

    it("noise has strength default 0.1", function()
        local e = lurek.effect.newEffect("noise")
        expect_equal(math.abs(e:getParameter("strength") - 0.1) < 0.001, true)
    end)

    it("all new types round-trip through getEffectType", function()
        local names = {"pixelate","sepia","grayscale","invert","scanlines","edgedetect","hueshift","noise"}
        local all_ok = true
        for _, name in ipairs(names) do
            local e = lurek.effect.newEffect(name)
            if e:getEffectType() ~= name then all_ok = false end
        end
        expect_equal(all_ok, true)
    end)

    it("getEffectTypes includes all new types", function()
        local types = lurek.effect.getEffectTypes()
        local set = {}
        for _, t in ipairs(types) do set[t] = true end
        local required = {"pixelate","sepia","grayscale","invert","scanlines","edgedetect","hueshift","noise"}
        local all_found = true
        for _, r in ipairs(required) do
            if not set[r] then all_found = false end
        end
        expect_equal(all_found, true)
    end)
end)

test_summary()
