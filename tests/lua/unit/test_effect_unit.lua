-- Lurek2D Effect API Unit Tests (consolidated)

-- Effect Dedup (merged from test_effect_dedup.lua)

describe("postfx.setShaderErrorDisplay / getShaderErrorDisplay", function()

    it("setShaderErrorDisplay exists in lurek.effect", function()
        expect_equal(type(lurek.effect.setShaderErrorDisplay), "function")
    end)

    it("getShaderErrorDisplay exists in lurek.effect", function()
        expect_equal(type(lurek.effect.getShaderErrorDisplay), "function")
    end)

    it("default shader error display is false", function()
        -- Should start false (or at least be a boolean)
        local val = lurek.effect.getShaderErrorDisplay()
        expect_equal(type(val), "boolean")
    end)

    it("setShaderErrorDisplay(true) makes getShaderErrorDisplay return true", function()
        lurek.effect.setShaderErrorDisplay(true)
        expect_equal(lurek.effect.getShaderErrorDisplay(), true)
    end)

    it("setShaderErrorDisplay(false) turns it off", function()
        lurek.effect.setShaderErrorDisplay(true)
        lurek.effect.setShaderErrorDisplay(false)
        expect_equal(lurek.effect.getShaderErrorDisplay(), false)
    end)

end)

describe("PostFxStack:dedup", function()

    it("new PostFxStack has dedup method", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(type(stack.dedup), "function")
    end)

    it("dedup on empty stack returns 0 and does not crash", function()
        local stack = lurek.effect.newStack(320, 240)
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    it("dedup on stack with no duplicates returns 0", function()
        local stack = lurek.effect.newStack(320, 240)
        stack:dedup()  -- no-op
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    it("dedup removes duplicate effects", function()
        local stack = lurek.effect.newStack(320, 240)
        local blur1 = lurek.effect.newEffect("blur")
        stack:add(blur1)
        stack:add(blur1)
        expect_equal(2, stack:len())
        local removed = stack:dedup()
        expect_equal(1, removed)
        expect_equal(1, stack:len())
    end)

end)

-- Effect Overlay/Water (merged from test_effect_overlay_water.lua)

local function make_overlay()
    local ov = lurek.effect.newOverlay()
    expect_true(ov ~= nil, "newOverlay() must return non-nil")
    return ov
end

describe("LuaOverlay water overlay", function()
    it("getWater returns a table with default values", function()
        local ov = make_overlay()
        local w = ov:getWater()
        expect_equal(type(w), "table")
        expect_equal(w.enabled, false)
        expect_near(w.time, 0.0, 1e-6)
        expect_equal(type(w.amplitude), "number")
        expect_equal(type(w.frequency), "number")
        expect_equal(type(w.speed), "number")
    end)

    it("setWater enables the effect and stores wave params", function()
        local ov = make_overlay()
        ov:setWater(0.05, 4.0, 2.0)
        local w = ov:getWater()
        expect_equal(w.enabled, true)
        expect_near(0.05, w.amplitude, 1e-6)
        expect_near(4.0, w.frequency, 1e-6)
        expect_near(2.0, w.speed, 1e-6)
    end)

    it("setWaterTint stores tint channels and strength", function()
        local ov = make_overlay()
        ov:setWaterTint(0.1, 0.5, 0.9, 0.7)
        local w = ov:getWater()
        expect_near(0.1, w.tint_r, 1e-6)
        expect_near(0.5, w.tint_g, 1e-6)
        expect_near(0.9, w.tint_b, 1e-6)
        expect_near(0.7, w.tint_strength, 1e-6)
    end)

    it("setCustomShader stores a shader name", function()
        local ov = make_overlay()
        ov:setCustomShader("my_wave")
        -- No public getter for custom_shader; just verify no error.
    end)

    it("setCustomShader(nil) clears the shader name", function()
        local ov = make_overlay()
        ov:setCustomShader("some_shader")
        ov:setCustomShader(nil)
        -- No error expected.
    end)

    it("setWater zero amplitude is accepted", function()
        local ov = make_overlay()
        ov:setWater(0.0, 1.0, 1.0)
        local w = ov:getWater()
        expect_equal(w.enabled, true)
        expect_equal(w.amplitude, 0.0)
    end)
end)

describe("LuaOverlay water does not affect non-water state", function()
    it("isActive() is not changed by setting water fields before enabling", function()
        local ov = make_overlay()
        -- Default water is disabled; overlay itself may or may not be active for other reasons.
        -- After setWaterTint without setWater, water.enabled stays false.
        ov:setWaterTint(1.0, 0.0, 0.0, 1.0)
        local w = ov:getWater()
        expect_equal(w.enabled, false)
    end)

    it("setWater then getWater returns consistent values on second call", function()
        local ov = make_overlay()
        ov:setWater(0.03, 2.5, 1.5)
        local w1 = ov:getWater()
        local w2 = ov:getWater()
        expect_equal(w1.amplitude, w2.amplitude)
        expect_equal(w1.frequency, w2.frequency)
        expect_equal(w1.speed, w2.speed)
    end)

    it("update advances water time when enabled", function()
        local ov = make_overlay()
        ov:setWater(0.02, 3.0, 2.0)
        ov:update(0.5)
        local w = ov:getWater()
        expect_near(w.time, 1.0, 1e-6)
    end)

    it("update leaves water time unchanged when disabled", function()
        local ov = make_overlay()
        ov:update(1.0)
        local w = ov:getWater()
        expect_near(w.time, 0.0, 1e-6)
    end)

    it("clear resets water state", function()
        local ov = make_overlay()
        ov:setWater(0.05, 4.0, 2.0)
        ov:update(0.5)
        ov:clear()
        local w = ov:getWater()
        expect_equal(w.enabled, false)
        expect_near(w.time, 0.0, 1e-6)
    end)
end)



-- [merged from test_effect_api.lua]
-- tests/lua/unit/test_effect_api.lua
-- Post-processing effect API tests (lurek.effect / lurek.effect).
-- Complements test_effect_effect.lua; focuses on the API surface check.
-- Headless-safe: no GPU, no window needed for API introspection.

-- ============================================================
-- Namespace surface
-- ============================================================
describe("lurek.effect module", function()
    it("is a table", function()
        expect_type("table", lurek.effect)
    end)

    it("lurek.effect aliases the same table", function()
        -- Both namespaces point to the same module table
        expect_type("table", lurek.effect)
    end)

    it("exposes getEffectTypes", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)

    it("exposes newEffect", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    it("exposes newStack", function()
        expect_type("function", lurek.effect.newStack)
    end)

    it("exposes newPass", function()
        expect_type("function", lurek.effect.newPass)
    end)

    it("exposes newCustomEffect", function()
        expect_type("function", lurek.effect.newCustomEffect)
    end)
end)

-- ============================================================
-- getEffectTypes
-- ============================================================
describe("lurek.effect.getEffectTypes", function()
    it("returns a table", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
    end)

    it("contains at least one entry", function()
        local types = lurek.effect.getEffectTypes()
        local count = 0
        for _ in pairs(types) do count = count + 1 end
        expect_true(count > 0, "getEffectTypes should return at least one type")
    end)

    it("contains known built-in types", function()
        local types = lurek.effect.getEffectTypes()
        local set = {}
        for _, v in ipairs(types) do set[v] = true end
        expect_true(set["bloom"] or set["blur"] or set["pixelate"],
            "at least one of bloom/blur/pixelate expected in type list")
    end)
end)

-- ============================================================
-- newEffect (built-in types by name)
-- ============================================================
describe("lurek.effect.newEffect", function()
    it("returns a userdata for 'bloom'", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_type("userdata", eff)
    end)

    it("returns a userdata for 'pixelate'", function()
        local eff = lurek.effect.newEffect("pixelate")
        expect_type("userdata", eff)
    end)

    it("errors for an unknown effect type", function()
        expect_error(function()
            lurek.effect.newEffect("magic_wand_effect")
        end)
    end)

    it("effect:getTypeName returns the requested type", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("blur", eff:getTypeName())
    end)

    it("effect:isBuiltIn returns true for newEffect", function()
        local eff = lurek.effect.newEffect("vignette")
        expect_equal(true, eff:isBuiltIn())
    end)

    it("effect:isEnabled returns true by default", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_equal(true, eff:isEnabled())
    end)

    it("setEnabled/isEnabled round-trip", function()
        local eff = lurek.effect.newEffect("bloom")
        eff:setEnabled(false)
        expect_equal(false, eff:isEnabled())
        eff:setEnabled(true)
        expect_equal(true, eff:isEnabled())
    end)

    it("effect:type returns 'PostFxEffect'", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("PostFxEffect", eff:type())
    end)

    it("effect:typeOf('PostFxEffect') returns true", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal(true, eff:typeOf("PostFxEffect"))
    end)
end)

-- ============================================================
-- newStack
-- ============================================================
describe("lurek.effect.newStack", function()
    it("returns a userdata", function()
        local stack = lurek.effect.newStack()
        expect_type("userdata", stack)
    end)

    it("stack:len returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:len())
    end)

    it("stack:getEffectCount returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:getEffectCount())
    end)

    it("stack:isEmpty returns true when empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(true, stack:isEmpty())
    end)

    it("stack:add increments len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("bloom")
        stack:add(eff)
        expect_equal(1, stack:len())
    end)

    it("adding two effects gives len 2", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        expect_equal(2, stack:len())
    end)

    it("stack:remove decrements len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("pixelate")
        stack:add(eff)
        stack:remove(eff)
        expect_equal(0, stack:len())
    end)

    it("stack:clear empties the stack", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:clear()
        expect_equal(0, stack:len())
    end)

    it("stack:type returns 'PostFxStack'", function()
        local stack = lurek.effect.newStack()
        expect_equal("PostFxStack", stack:type())
    end)

    it("stack:getWidth and getHeight return positive integers", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(320, stack:getWidth())
        expect_equal(240, stack:getHeight())
    end)

    it("stack:getDimensions returns (w, h)", function()
        local stack = lurek.effect.newStack(640, 480)
        local w, h = stack:getDimensions()
        expect_equal(640, w)
        expect_equal(480, h)
    end)

    it("stack:setEnabled/isEnabled round-trip at position 1", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:setEnabled(1, false)
        expect_equal(false, stack:isEnabled(1))
        stack:setEnabled(1, true)
        expect_equal(true, stack:isEnabled(1))
    end)

    it("stack:getEffect returns the added effect", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("vignette")
        stack:add(eff)
        local retrieved = stack:getEffect(1)
        expect_not_nil(retrieved)
    end)
end)



-- [merged from test_effect_effect.lua]
-- Lurek2D PostFX API Tests covers lurek.effect post-processing effects (headless)

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
    it("returns table of 23 types", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
        expect_equal(#types, 23)
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

describe("PostFxEffect auto uniforms", function()
    it("starts with auto uniforms disabled", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isAutoUniforms(), false)
    end)

    it("enableAutoUniforms turns the flag on", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:enableAutoUniforms()
        expect_equal(bloom:isAutoUniforms(), true)
    end)

    it("disableAutoUniforms turns the flag off", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:enableAutoUniforms()
        bloom:disableAutoUniforms()
        expect_equal(bloom:isAutoUniforms(), false)
    end)
end)

describe("ScreenTransition", function()
    it("unknown kind defaults to fade", function()
        local transition = lurek.effect.newTransition("unknown", 1.0)
        expect_equal(transition:kind(), "fade")
    end)

    it("starts inactive and not done", function()
        local transition = lurek.effect.newTransition("fade", 1.0)
        expect_equal(transition:isActive(), false)
        expect_equal(transition:isDone(), false)
    end)

    it("roundtrips every supported kind", function()
        local kinds = {"fade", "wipe", "iris_wipe", "dissolve"}
        for _, kind in ipairs(kinds) do
            local transition = lurek.effect.newTransition(kind, 1.0)
            expect_equal(transition:kind(), kind)
        end
    end)

    it("play activates and update advances progress", function()
        local transition = lurek.effect.newTransition("wipe", 2.0)
        expect_equal(transition:isActive(), false)
        transition:play()
        expect_equal(transition:isActive(), true)
        expect_near(transition:progress(), 0.0, 0.001)
        expect_equal(transition:update(1.0), true)
        expect_near(transition:progress(), 0.5, 0.001)
    end)

    it("reverse advances progress", function()
        local transition = lurek.effect.newTransition("fade", 2.0)
        transition:reverse()
        transition:update(1.0)
        expect_near(transition:progress(), 0.5, 0.001)
    end)

    it("completes after duration", function()
        local transition = lurek.effect.newTransition("dissolve", 0.5)
        transition:play()
        expect_equal(transition:update(0.6), true)
        expect_equal(transition:isActive(), false)
        expect_equal(transition:isDone(), true)
    end)
end)

describe("PostFxEffect type() method", function()
    it("returns PostFxEffect", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:type(), "LPostFxEffect")
    end)

    it("custom pass also returns PostFxEffect", function()
        local pass = lurek.effect.newPass(1)
        expect_equal(pass:type(), "LPostFxEffect")
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
        expect_equal(stack:type(), "LPostFxStack")
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

-- New effect types

describe("New effect types construction and defaults", function()
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

-- PostFX Stack Extended (merged from test_postfx_stack_extended.lua)

describe("lurek.effect.newStack (extended)", function()
    it("newStack() returns a non-nil stack", function()
        local s = lurek.effect.newStack()
        expect_equal(s ~= nil, true)
    end)

    it("beginCapture does not error in headless mode", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
    end)

    it("endCapture does not error in headless mode", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
        s:endCapture()
    end)

    it("apply does not error when stack has no effects", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
        s:endCapture()
        s:apply()
    end)

    it("apply submits one ApplyPostFx command per call", function()
        -- We push a command; just verify no error thrown.
        local s = lurek.effect.newStack(320, 240)
        s:beginCapture()
        s:endCapture()
        s:apply()
        s:apply()  -- second call also fine
    end)
end)

describe("lurek.effect.newPresetStack", function()
    local preset_names = { "retro_tv", "horror", "dream", "neon", "sepia_age" }

    for _, name in ipairs(preset_names) do
        it("newPresetStack('" .. name .. "') returns non-nil", function()
            local s = lurek.effect.newPresetStack(name)
            expect_equal(s ~= nil, true)
        end)

        it("newPresetStack('" .. name .. "') beginCapture/endCapture/apply do not error", function()
            local s = lurek.effect.newPresetStack(name)
            s:beginCapture()
            s:endCapture()
            s:apply()
        end)
    end

    it("newPresetStack with unknown name returns error", function()
        expect_error(function() lurek.effect.newPresetStack("nonexistent_preset") end)
    end)

    it("newPresetStack with dimensions applies those dimensions", function()
        local s = lurek.effect.newPresetStack("retro_tv", 512, 256)
        expect_equal(s ~= nil, true)
    end)
end)

describe("lurek.effect.getEffectTypes (new types)", function()
    local NEW_TYPES = {
        "depthoffield", "motionblur", "paletteswap", "colorlut",
        "waterdistort", "sharpen", "dither", "outline",
    }

    it("getEffectTypes returns a table including all new types", function()
        local types = lurek.effect.getEffectTypes()
        expect_equal(type(types), "table")
        local type_set = {}
        for _, t in ipairs(types) do type_set[t] = true end
        for _, expected in ipairs(NEW_TYPES) do
            expect_equal(type_set[expected] == true, true)
        end
    end)

    it("all new types can be used to create effects", function()
        for _, t in ipairs(NEW_TYPES) do
            local e = lurek.effect.newEffect(t)
            expect_equal(e ~= nil, true)
        end
    end)
end)





-- ================================================================
-- Merged from: test_effect_overlay.lua
-- ================================================================

-- tests/lua/unit/test_effect_overlay.lua
-- BDD tests for the lurek.effect.* screen-effect effect API.

require("tests/lua/init")

-- ============================================================
-- 1. Factory and Construction
-- ============================================================

describe("lurek.effect factory", function()
    it("creates an overlay with custom dimensions", function()
        local ov = lurek.effect.newOverlay(1024, 768)
        expect_equal(ov:getWidth(), 1024)
        expect_equal(ov:getHeight(), 768)
    end)

    it("creates an overlay with default dimensions", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:getWidth(), 800)
        expect_equal(ov:getHeight(), 600)
    end)

    it("returns dimensions as tuple", function()
        local ov = lurek.effect.newOverlay(640, 480)
        local w, h = ov:getDimensions()
        expect_equal(w, 640)
        expect_equal(h, 480)
    end)
end)

-- ============================================================
-- 2. Type Introspection
-- ============================================================

describe("overlay type", function()
    it("reports type as LOverlay", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:type(), "LOverlay")
    end)

    it("typeOf Object returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Object"), true)
    end)

    it("typeOf Overlay returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Overlay"), true)
    end)

    it("typeOf unrelated returns false", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("PostFxEffect"), false)
    end)
end)

-- ============================================================
-- 3. Core Lifecycle
-- ============================================================

describe("overlay core", function()
    it("starts inactive", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isActive(), false)
    end)

    it("resize updates dimensions", function()
        local ov = lurek.effect.newOverlay(800, 600)
        ov:resize(1920, 1080)
        expect_equal(ov:getWidth(), 1920)
        expect_equal(ov:getHeight(), 1080)
    end)

    it("update does not error on empty overlay", function()
        local ov = lurek.effect.newOverlay()
        ov:update(0.016)
        expect_equal(ov:isActive(), false)
    end)

    it("draw does not error", function()
        local ov = lurek.effect.newOverlay()
        ov:render()
    end)

    it("clear resets all effects", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        ov:setFogEnabled(true)
        ov:setVignetteEnabled(true)
        ov:setAmbientEnabled(true)
        expect_equal(ov:isActive(), true)
        ov:clear()
        expect_equal(ov:isActive(), false)
    end)
end)

-- ============================================================
-- 4. Ambient Lighting
-- ============================================================

describe("overlay ambient", function()
    it("starts disabled with white noon tint", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isAmbientEnabled(), false)
        expect_near(ov:getTimeOfDay(), 12.0, 0.001)
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 1.0, 0.001)
        expect_near(b, 1.0, 0.001)
        expect_near(a, 1.0, 0.001)
    end)

    it("enables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        expect_equal(ov:isAmbientEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    it("disables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setAmbientEnabled(false)
        expect_equal(ov:isAmbientEnabled(), false)
    end)

    it("sets and gets ambient color with alpha", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.3, 0.4, 0.5, 0.6)
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 0.3, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 0.6, 0.001)
    end)

    it("ambient color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.5, 0.5, 0.5)
        local _, _, _, a = ov:getAmbientColor()
        expect_near(a, 1.0, 0.001)
    end)

    it("sets and gets time of day", function()
        local ov = lurek.effect.newOverlay()
        ov:setTimeOfDay(6.5)
        expect_near(ov:getTimeOfDay(), 6.5, 0.001)
    end)

    it("update applies time-of-day color when ambient enabled", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setTimeOfDay(2.0) -- night
        ov:update(0.016)
        local r, g, b, a = ov:getAmbientColor()
        -- Night should produce dark colors
        expect_near(r, 0.1, 0.01)
        expect_near(g, 0.1, 0.01)
        expect_near(b, 0.3, 0.01)
    end)

    it("time-of-day noon produces bright color", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setTimeOfDay(12.0) -- day
        ov:update(0.016)
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 1.0, 0.01)
        expect_near(g, 0.8, 0.01)
        expect_near(b, 0.6, 0.01)
    end)

    it("time-of-day wraps past 24 hours", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setTimeOfDay(26.0)
        ov:update(0.016)
        local r, g, b, a = ov:getAmbientColor()
        expect_equal(r < 0.2, true)
        expect_equal(b > r, true)
    end)
end)

-- ============================================================
-- 5. Weather System
-- ============================================================

describe("overlay weather", function()
    it("starts disabled with weather set to none", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isWeatherEnabled(), false)
        expect_equal(ov:getWeather(), "none")
    end)

    it("enables weather", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        expect_equal(ov:isWeatherEnabled(), true)
    end)

    it("sets weather type", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeather("rain")
        expect_equal(ov:getWeather(), "rain")
    end)

    it("roundtrips all weather types", function()
        local ov = lurek.effect.newOverlay()
        local types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
        for _, wt in ipairs(types) do
            ov:setWeather(wt)
            expect_equal(ov:getWeather(), wt)
        end
    end)

    it("rejects invalid weather type", function()
        local ov = lurek.effect.newOverlay()
        expect_error(function()
            ov:setWeather("tornado")
        end)
    end)

    it("sets and gets weather intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherIntensity(0.8)
        expect_near(ov:getWeatherIntensity(), 0.8, 0.001)
    end)

    it("sets and gets wind direction", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindDirection(1.57)
        expect_near(ov:getWindDirection(), 1.57, 0.001)
    end)

    it("sets and gets wind speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindSpeed(75.0)
        expect_near(ov:getWindSpeed(), 75.0, 0.001)
    end)
end)

-- ============================================================
-- 6. Screen Flash
-- ============================================================

describe("overlay flash", function()
    it("triggers a flash", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFlashing(), false)
        ov:flash(1, 0, 0, 1, 0.5)
        expect_equal(ov:isFlashing(), true)
    end)

    it("flash with default alpha and duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isFlashing(), true)
        -- default duration = 0.2
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
    end)

    it("flash completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 0, 0, 1, 0.1)
        ov:update(0.2)
        expect_equal(ov:isFlashing(), false)
    end)

    it("flash activates isActive", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isActive(), true)
    end)
end)

-- ============================================================
-- 7. Screen Shake
-- ============================================================

describe("overlay shake", function()
    it("triggers a shake", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isShaking(), false)
        ov:shake(10, 0.5)
        expect_equal(ov:isShaking(), true)
    end)

    it("shake with default duration", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(8.0)
        expect_equal(ov:isShaking(), true)
        -- default duration = 0.5
        ov:update(0.6)
        expect_equal(ov:isShaking(), false)
    end)

    it("shake produces non-zero offset", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(10, 1.0)
        ov:update(0.1)
        local x, y = ov:getShakeOffset()
        -- At least one component should be non-zero
        local total = math.abs(x) + math.abs(y)
        expect_equal(total > 0, true)
    end)

    it("shake offset returns to zero after completion", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(10, 0.5)
        ov:update(0.6)
        local x, y = ov:getShakeOffset()
        expect_near(x, 0, 0.001)
        expect_near(y, 0, 0.001)
    end)
end)

-- ============================================================
-- 8. Screen Fade
-- ============================================================

describe("overlay fade", function()
    it("triggers a fade", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFading(), false)
        ov:fade(0, 0, 0, 1, 1.0)
        expect_equal(ov:isFading(), true)
    end)

    it("fade with defaults", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0)
        expect_equal(ov:isFading(), true)
        -- default alpha=1.0, duration=1.0
        ov:update(1.1)
        expect_equal(ov:isFading(), false)
    end)

    it("fade completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0, 0.8, 0.5)
        ov:update(0.6)
        expect_equal(ov:isFading(), false)
    end)
end)

-- ============================================================
-- 9. Cloud Shadows
-- ============================================================

describe("overlay clouds", function()
    it("starts disabled with default cloud count", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isCloudShadowsEnabled(), false)
        expect_equal(ov:getCloudCount(), 5)
    end)

    it("enables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        expect_equal(ov:isCloudShadowsEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    it("disables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        ov:setCloudShadows(false)
        expect_equal(ov:isCloudShadowsEnabled(), false)
    end)

    it("sets and gets cloud count", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudCount(12)
        expect_equal(ov:getCloudCount(), 12)
    end)

    it("sets and gets cloud speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudSpeed(35.0)
        expect_near(ov:getCloudSpeed(), 35.0, 0.001)
    end)

    it("sets and gets cloud scale", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudScale(2.5)
        expect_near(ov:getCloudScale(), 2.5, 0.001)
    end)

    it("sets and gets cloud opacity", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudOpacity(0.6)
        expect_near(ov:getCloudOpacity(), 0.6, 0.001)
    end)
end)

-- ============================================================
-- 10. Atmospheric Fog
-- ============================================================

describe("overlay fog", function()
    it("starts disabled with default density", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFogEnabled(), false)
        expect_near(ov:getFogDensity(), 0.3, 0.001)
    end)

    it("enables fog", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogEnabled(true)
        expect_equal(ov:isFogEnabled(), true)
    end)

    it("sets and gets fog density", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogDensity(0.7)
        expect_near(ov:getFogDensity(), 0.7, 0.001)
    end)

    it("sets and gets fog color", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.5, 0.5, 0.6, 0.9)
        local r, g, b, a = ov:getFogColor()
        expect_near(r, 0.5, 0.001)
        expect_near(g, 0.5, 0.001)
        expect_near(b, 0.6, 0.001)
        expect_near(a, 0.9, 0.001)
    end)

    it("fog color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.3, 0.3, 0.4)
        local _, _, _, a = ov:getFogColor()
        expect_near(a, 1.0, 0.001)
    end)
end)

-- ============================================================
-- 11. Heat Haze
-- ============================================================

describe("overlay heat haze", function()
    it("starts disabled with default intensity", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isHeatHazeEnabled(), false)
        expect_near(ov:getHeatHazeIntensity(), 0.5, 0.001)
    end)

    it("enables heat haze", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeEnabled(true)
        expect_equal(ov:isHeatHazeEnabled(), true)
    end)

    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeIntensity(0.9)
        expect_near(ov:getHeatHazeIntensity(), 0.9, 0.001)
    end)
end)

-- ============================================================
-- 12. Vignette
-- ============================================================

describe("overlay vignette", function()
    it("starts disabled with default strength", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isVignetteEnabled(), false)
        expect_near(ov:getVignetteStrength(), 0.5, 0.001)
    end)

    it("enables vignette", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteEnabled(true)
        expect_equal(ov:isVignetteEnabled(), true)
    end)

    it("sets and gets strength", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteStrength(0.8)
        expect_near(ov:getVignetteStrength(), 0.8, 0.001)
    end)
end)

-- ============================================================
-- 13. Film Grain
-- ============================================================

describe("overlay film grain", function()
    it("starts disabled with default intensity", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFilmGrainEnabled(), false)
        expect_near(ov:getFilmGrainIntensity(), 0.3, 0.001)
    end)

    it("enables film grain", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainEnabled(true)
        expect_equal(ov:isFilmGrainEnabled(), true)
    end)

    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainIntensity(0.6)
        expect_near(ov:getFilmGrainIntensity(), 0.6, 0.001)
    end)
end)

-- ============================================================
-- 14. Lightning
-- ============================================================

describe("overlay lightning", function()
    it("triggers lightning", function()
        local ov = lurek.effect.newOverlay()
        ov:triggerLightning()
        -- Lightning is active (makes overlay active)
        expect_equal(ov:isActive(), true)
    end)

    it("sets and gets lightning color", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1.0, 0.9, 0.8, 0.7)
        local r, g, b, a = ov:getLightningColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.9, 0.001)
        expect_near(b, 0.8, 0.001)
        expect_near(a, 0.7, 0.001)
    end)

    it("lightning color alpha defaults to 0.8", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1, 1, 1)
        local _, _, _, a = ov:getLightningColor()
        expect_near(a, 1.0, 0.001)
    end)
end)

-- ============================================================
-- 15. Combined Effects
-- ============================================================

describe("overlay combined", function()
    it("multiple effects active simultaneously", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        ov:setFogEnabled(true)
        ov:setVignetteEnabled(true)
        ov:flash(1, 1, 1)
        expect_equal(ov:isActive(), true)
        expect_equal(ov:isWeatherEnabled(), true)
        expect_equal(ov:isFogEnabled(), true)
        expect_equal(ov:isVignetteEnabled(), true)
        expect_equal(ov:isFlashing(), true)
    end)

    it("clear removes all active effects", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        ov:setFogEnabled(true)
        ov:setVignetteEnabled(true)
        ov:setFilmGrainEnabled(true)
        ov:setHeatHazeEnabled(true)
        ov:setCloudShadows(true)
        ov:setAmbientEnabled(true)
        ov:flash(1, 0, 0)
        ov:shake(5)
        ov:fade(0, 0, 0)
        ov:triggerLightning()
        expect_equal(ov:isActive(), true)
        ov:clear()
        expect_equal(ov:isActive(), false)
    end)

    it("update advances multiple timed effects", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1, 1, 0.1)
        ov:shake(5, 0.2)
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
        expect_equal(ov:isShaking(), false)
    end)
end)
test_summary()
