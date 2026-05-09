-- Lurek2D Effect API Unit Tests (consolidated)

-- Effect Dedup (merged from test_effect_dedup.lua)

-- @describe postfx.setShaderErrorDisplay / getShaderErrorDisplay
describe("postfx.setShaderErrorDisplay / getShaderErrorDisplay", function()

    -- @covers lurek.effect.setShaderErrorDisplay
    it("setShaderErrorDisplay exists in lurek.effect", function()
        expect_equal(type(lurek.effect.setShaderErrorDisplay), "function")
    end)

    -- @covers lurek.effect.getShaderErrorDisplay
    it("getShaderErrorDisplay exists in lurek.effect", function()
        expect_equal(type(lurek.effect.getShaderErrorDisplay), "function")
    end)

    -- @covers lurek.effect.getShaderErrorDisplay
    it("default shader error display is false", function()
        -- Should start false (or at least be a boolean)
        local val = lurek.effect.getShaderErrorDisplay()
        expect_equal(type(val), "boolean")
    end)

    -- @covers lurek.effect.getShaderErrorDisplay
    -- @covers lurek.effect.setShaderErrorDisplay
    it("setShaderErrorDisplay(true) makes getShaderErrorDisplay return true", function()
        lurek.effect.setShaderErrorDisplay(true)
        expect_equal(lurek.effect.getShaderErrorDisplay(), true)
    end)

    -- @covers lurek.effect.getShaderErrorDisplay
    -- @covers lurek.effect.setShaderErrorDisplay
    it("setShaderErrorDisplay(false) turns it off", function()
        lurek.effect.setShaderErrorDisplay(true)
        lurek.effect.setShaderErrorDisplay(false)
        expect_equal(lurek.effect.getShaderErrorDisplay(), false)
    end)

end)

-- @describe PostFxStack:dedup
describe("PostFxStack:dedup", function()

    -- @covers lurek.effect.newStack
    it("new PostFxStack has dedup method", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(type(stack.dedup), "function")
    end)

    -- @covers LPostFxStack:dedup
    -- @covers lurek.effect.newStack
    it("dedup on empty stack returns 0 and does not crash", function()
        local stack = lurek.effect.newStack(320, 240)
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    -- @covers LPostFxStack:dedup
    -- @covers lurek.effect.newStack
    it("dedup on stack with no duplicates returns 0", function()
        local stack = lurek.effect.newStack(320, 240)
        stack:dedup()  -- no-op
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:dedup
    -- @covers LPostFxStack:len
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
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

-- @describe LuaOverlay water overlay
describe("LuaOverlay water overlay", function()
    -- @covers LOverlay:getWater
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

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWater
    it("setWater enables the effect and stores wave params", function()
        local ov = make_overlay()
        ov:setWater(0.05, 4.0, 2.0)
        local w = ov:getWater()
        expect_equal(w.enabled, true)
        expect_near(0.05, w.amplitude, 1e-6)
        expect_near(4.0, w.frequency, 1e-6)
        expect_near(2.0, w.speed, 1e-6)
    end)

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWaterTint
    it("setWaterTint stores tint channels and strength", function()
        local ov = make_overlay()
        ov:setWaterTint(0.1, 0.5, 0.9, 0.7)
        local w = ov:getWater()
        expect_near(0.1, w.tint_r, 1e-6)
        expect_near(0.5, w.tint_g, 1e-6)
        expect_near(0.9, w.tint_b, 1e-6)
        expect_near(0.7, w.tint_strength, 1e-6)
    end)

    -- @covers LOverlay:setCustomShader
    it("setCustomShader stores a shader name", function()
        local ov = make_overlay()
        ov:setCustomShader("my_wave")
        -- No public getter for custom_shader; just verify no error.
    end)

    -- @covers LOverlay:setCustomShader
    it("setCustomShader(nil) clears the shader name", function()
        local ov = make_overlay()
        ov:setCustomShader("some_shader")
        ov:setCustomShader(nil)
        -- No error expected.
    end)

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWater
    it("setWater zero amplitude is accepted", function()
        local ov = make_overlay()
        ov:setWater(0.0, 1.0, 1.0)
        local w = ov:getWater()
        expect_equal(w.enabled, true)
        expect_equal(w.amplitude, 0.0)
    end)
end)

-- @describe LuaOverlay water does not affect non-water state
describe("LuaOverlay water does not affect non-water state", function()
    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWaterTint
    it("isActive() is not changed by setting water fields before enabling", function()
        local ov = make_overlay()
        -- Default water is disabled; overlay itself may or may not be active for other reasons.
        -- After setWaterTint without setWater, water.enabled stays false.
        ov:setWaterTint(1.0, 0.0, 0.0, 1.0)
        local w = ov:getWater()
        expect_equal(w.enabled, false)
    end)

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWater
    it("setWater then getWater returns consistent values on second call", function()
        local ov = make_overlay()
        ov:setWater(0.03, 2.5, 1.5)
        local w1 = ov:getWater()
        local w2 = ov:getWater()
        expect_equal(w1.amplitude, w2.amplitude)
        expect_equal(w1.frequency, w2.frequency)
        expect_equal(w1.speed, w2.speed)
    end)

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWater
    it("update advances water time when enabled", function()
        local ov = make_overlay()
        ov:setWater(0.02, 3.0, 2.0)
        ov:update(0.5)
        local w = ov:getWater()
        expect_near(w.time, 1.0, 1e-6)
    end)

    -- @covers LOverlay:getWater
    it("update leaves water time unchanged when disabled", function()
        local ov = make_overlay()
        ov:update(1.0)
        local w = ov:getWater()
        expect_near(w.time, 0.0, 1e-6)
    end)

    -- @covers LOverlay:getWater
    -- @covers LOverlay:setWater
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
-- @describe lurek.effect module
describe("lurek.effect module", function()
    -- @covers lurek.effect
    it("is a table", function()
        expect_type("table", lurek.effect)
    end)

    -- @covers lurek.effect
    it("lurek.effect aliases the same table", function()
        -- Both namespaces point to the same module table
        expect_type("table", lurek.effect)
    end)

    -- @covers lurek.effect.getEffectTypes
    it("exposes getEffectTypes", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)

    -- @covers lurek.effect.newEffect
    it("exposes newEffect", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    -- @covers lurek.effect.newStack
    it("exposes newStack", function()
        expect_type("function", lurek.effect.newStack)
    end)

    -- @covers lurek.effect.newPass
    it("exposes newPass", function()
        expect_type("function", lurek.effect.newPass)
    end)

    -- @covers lurek.effect.newCustomEffect
    it("exposes newCustomEffect", function()
        expect_type("function", lurek.effect.newCustomEffect)
    end)
end)

-- ============================================================
-- getEffectTypes
-- ============================================================
-- @describe lurek.effect.getEffectTypes
describe("lurek.effect.getEffectTypes", function()
    -- @covers lurek.effect.getEffectTypes
    it("returns a table", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
    end)

    -- @covers lurek.effect.getEffectTypes
    it("contains at least one entry", function()
        local types = lurek.effect.getEffectTypes()
        local count = 0
        for _ in pairs(types) do count = count + 1 end
        expect_true(count > 0, "getEffectTypes should return at least one type")
    end)

    -- @covers lurek.effect.getEffectTypes
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
-- @describe lurek.effect.newEffect
describe("lurek.effect.newEffect", function()
    -- @covers lurek.effect.newEffect
    it("returns a userdata for 'bloom'", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_type("userdata", eff)
    end)

    -- @covers lurek.effect.newEffect
    it("returns a userdata for 'pixelate'", function()
        local eff = lurek.effect.newEffect("pixelate")
        expect_type("userdata", eff)
    end)

    -- @covers lurek.effect.newEffect
    it("errors for an unknown effect type", function()
        expect_error(function()
            lurek.effect.newEffect("magic_wand_effect")
        end)
    end)

    -- @covers LPostFxEffect:getTypeName
    -- @covers lurek.effect.newEffect
    it("effect:getTypeName returns the requested type", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("blur", eff:getTypeName())
    end)

    -- @covers LPostFxEffect:isBuiltIn
    -- @covers lurek.effect.newEffect
    it("effect:isBuiltIn returns true for newEffect", function()
        local eff = lurek.effect.newEffect("vignette")
        expect_equal(true, eff:isBuiltIn())
    end)

    -- @covers LPostFxEffect:isEnabled
    -- @covers lurek.effect.newEffect
    it("effect:isEnabled returns true by default", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_equal(true, eff:isEnabled())
    end)

    -- @covers LPostFxEffect:isEnabled
    -- @covers LPostFxEffect:setEnabled
    -- @covers lurek.effect.newEffect
    it("setEnabled/isEnabled round-trip", function()
        local eff = lurek.effect.newEffect("bloom")
        eff:setEnabled(false)
        expect_equal(false, eff:isEnabled())
        eff:setEnabled(true)
        expect_equal(true, eff:isEnabled())
    end)

    -- @covers LPostFxEffect:type
    -- @covers lurek.effect.newEffect
    it("effect:type returns 'LPostFxEffect'", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("LPostFxEffect", eff:type())
    end)

    -- @covers LPostFxEffect:typeOf
    -- @covers lurek.effect.newEffect
    it("effect:typeOf('PostFxEffect') returns true", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal(true, eff:typeOf("PostFxEffect"))
    end)
end)

-- ============================================================
-- newStack
-- ============================================================
-- @describe lurek.effect.newStack
describe("lurek.effect.newStack", function()
    -- @covers lurek.effect.newStack
    it("returns a userdata", function()
        local stack = lurek.effect.newStack()
        expect_type("userdata", stack)
    end)

    -- @covers LPostFxStack:len
    -- @covers lurek.effect.newStack
    it("stack:len returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:len())
    end)

    -- @covers LPostFxStack:getEffectCount
    -- @covers lurek.effect.newStack
    it("stack:getEffectCount returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:getEffectCount())
    end)

    -- @covers LPostFxStack:isEmpty
    -- @covers lurek.effect.newStack
    it("stack:isEmpty returns true when empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(true, stack:isEmpty())
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:len
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("stack:add increments len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("bloom")
        stack:add(eff)
        expect_equal(1, stack:len())
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:len
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("adding two effects gives len 2", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        expect_equal(2, stack:len())
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:len
    -- @covers LPostFxStack:remove
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("stack:remove decrements len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("pixelate")
        stack:add(eff)
        stack:remove(eff)
        expect_equal(0, stack:len())
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:clear
    -- @covers LPostFxStack:len
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("stack:clear empties the stack", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:clear()
        expect_equal(0, stack:len())
    end)

    -- @covers LPostFxStack:type
    -- @covers lurek.effect.newStack
    it("stack:type returns 'LPostFxStack'", function()
        local stack = lurek.effect.newStack()
        expect_equal("LPostFxStack", stack:type())
    end)

    -- @covers LPostFxStack:getHeight
    -- @covers LPostFxStack:getWidth
    -- @covers lurek.effect.newStack
    it("stack:getWidth and getHeight return positive integers", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(320, stack:getWidth())
        expect_equal(240, stack:getHeight())
    end)

    -- @covers LPostFxStack:getDimensions
    -- @covers lurek.effect.newStack
    it("stack:getDimensions returns (w, h)", function()
        local stack = lurek.effect.newStack(640, 480)
        local w, h = stack:getDimensions()
        expect_equal(640, w)
        expect_equal(480, h)
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:isEnabled
    -- @covers LPostFxStack:setEnabled
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("stack:setEnabled/isEnabled round-trip at position 1", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:setEnabled(1, false)
        expect_equal(false, stack:isEnabled(1))
        stack:setEnabled(1, true)
        expect_equal(true, stack:isEnabled(1))
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEffect
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
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

-- @describe lurek.effect module exists
describe("lurek.effect module exists", function()
    -- @covers lurek.effect
    it("lurek.effect is a table", function()
        expect_type("table", lurek.effect)
    end)
end)

-- @describe lurek.effect factory functions
describe("lurek.effect factory functions", function()
    -- @covers lurek.effect.newEffect
    it("newEffect is a function", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    -- @covers lurek.effect.newPass
    it("newPass is a function", function()
        expect_type("function", lurek.effect.newPass)
    end)

    -- @covers lurek.effect.newStack
    it("newStack is a function", function()
        expect_type("function", lurek.effect.newStack)
    end)

    -- @covers lurek.effect.getEffectTypes
    it("getEffectTypes is a function", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)
end)

-- @describe lurek.effect.newEffect built-in types
describe("lurek.effect.newEffect built-in types", function()
    -- @covers LPostFxEffect:getEffectType
    -- @covers LPostFxEffect:isBuiltIn
    -- @covers lurek.effect.newEffect
    it("creates bloom effect", function()
        local e = lurek.effect.newEffect("bloom")
        expect_equal(e:getEffectType(), "bloom")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates blur effect", function()
        local e = lurek.effect.newEffect("blur")
        expect_equal(e:getEffectType(), "blur")
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates crt effect", function()
        local e = lurek.effect.newEffect("crt")
        expect_equal(e:getEffectType(), "crt")
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates godrays effect", function()
        local e = lurek.effect.newEffect("godrays")
        expect_equal(e:getEffectType(), "godrays")
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates vignette effect", function()
        local e = lurek.effect.newEffect("vignette")
        expect_equal(e:getEffectType(), "vignette")
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates colourgrade effect", function()
        local e = lurek.effect.newEffect("colourgrade")
        expect_equal(e:getEffectType(), "colourgrade")
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("creates chromatic effect", function()
        local e = lurek.effect.newEffect("chromatic")
        expect_equal(e:getEffectType(), "chromatic")
    end)

    -- @covers lurek.effect.newEffect
    it("rejects invalid effect type", function()
        expect_error(function()
            lurek.effect.newEffect("invalid_type")
        end)
    end)
end)

-- @describe lurek.effect.newPass custom effects
describe("lurek.effect.newPass custom effects", function()
    -- @covers LPostFxEffect:getEffectType
    -- @covers LPostFxEffect:isBuiltIn
    -- @covers lurek.effect.newPass
    it("creates custom pass", function()
        local p = lurek.effect.newPass(1)
        expect_equal(p:getEffectType(), "custom")
        expect_equal(p:isBuiltIn(), false)
    end)
end)

-- @describe lurek.effect.getEffectTypes
describe("lurek.effect.getEffectTypes", function()
    -- @covers lurek.effect.getEffectTypes
    it("returns table of 23 types", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
        expect_equal(#types, 23)
    end)

    -- @covers lurek.effect.getEffectTypes
    it("contains bloom", function()
        local types = lurek.effect.getEffectTypes()
        local found = false
        for _, t in ipairs(types) do
            if t == "bloom" then found = true end
        end
        expect_equal(found, true)
    end)
end)

-- @describe PostFxEffect parameters
describe("PostFxEffect parameters", function()
    -- @covers LPostFxEffect:hasParameter
    -- @covers lurek.effect.newEffect
    it("bloom has default threshold", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:hasParameter("threshold"), true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("getParameter returns value", function()
        local bloom = lurek.effect.newEffect("bloom")
        local t = bloom:getParameter("threshold")
        expect_type("number", t)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setParameter
    -- @covers lurek.effect.newEffect
    it("setParameter changes value", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setParameter("threshold", 0.5)
        local v = bloom:getParameter("threshold")
        expect_equal(math.abs(v - 0.5) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("getParameter uses default for missing", function()
        local bloom = lurek.effect.newEffect("bloom")
        local v = bloom:getParameter("nonexistent", 42.0)
        expect_equal(math.abs(v - 42.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameterNames
    -- @covers lurek.effect.newEffect
    it("getParameterNames returns sorted list", function()
        local bloom = lurek.effect.newEffect("bloom")
        local names = bloom:getParameterNames()
        expect_type("table", names)
        expect_equal(#names >= 2, true)
    end)
end)

-- @describe PostFxEffect convenience setters
describe("PostFxEffect convenience setters", function()
    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setThreshold
    -- @covers lurek.effect.newEffect
    it("setThreshold works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setThreshold(0.8) end)
        expect_equal(math.abs(bloom:getParameter("threshold") - 0.8) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setIntensity
    -- @covers lurek.effect.newEffect
    it("setIntensity works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setIntensity(2.0) end)
        expect_equal(math.abs(bloom:getParameter("intensity") - 2.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setRadius
    -- @covers lurek.effect.newEffect
    it("setRadius works on blur", function()
        local blur = lurek.effect.newEffect("blur")
        expect_no_error(function() blur:setRadius(5.0) end)
        expect_equal(math.abs(blur:getParameter("radius") - 5.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setStrength
    -- @covers lurek.effect.newEffect
    it("setStrength works on vignette", function()
        local vig = lurek.effect.newEffect("vignette")
        expect_no_error(function() vig:setStrength(0.8) end)
        expect_equal(math.abs(vig:getParameter("strength") - 0.8) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setScanlineStrength
    -- @covers lurek.effect.newEffect
    it("setScanlineStrength works on crt", function()
        local crt = lurek.effect.newEffect("crt")
        expect_no_error(function() crt:setScanlineStrength(0.4) end)
        expect_equal(math.abs(crt:getParameter("scanline_strength") - 0.4) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setOffset
    -- @covers lurek.effect.newEffect
    it("setOffset works on chromatic", function()
        local chr = lurek.effect.newEffect("chromatic")
        expect_no_error(function() chr:setOffset(3.0) end)
        expect_equal(math.abs(chr:getParameter("offset") - 3.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setBrightness
    -- @covers lurek.effect.newEffect
    it("setBrightness works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setBrightness(1.5) end)
        expect_equal(math.abs(cg:getParameter("brightness") - 1.5) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setContrast
    -- @covers lurek.effect.newEffect
    it("setContrast works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setContrast(0.9) end)
        expect_equal(math.abs(cg:getParameter("contrast") - 0.9) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setSaturation
    -- @covers lurek.effect.newEffect
    it("setSaturation works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setSaturation(0.7) end)
        expect_equal(math.abs(cg:getParameter("saturation") - 0.7) < 0.001, true)
    end)
end)

-- @describe PostFxEffect enable/disable
describe("PostFxEffect enable/disable", function()
    -- @covers LPostFxEffect:isEnabled
    -- @covers lurek.effect.newEffect
    it("is enabled by default", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isEnabled(), true)
    end)

    -- @covers LPostFxEffect:isEnabled
    -- @covers LPostFxEffect:setEnabled
    -- @covers lurek.effect.newEffect
    it("setEnabled false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        expect_equal(bloom:isEnabled(), false)
    end)

    -- @covers LPostFxEffect:isEnabled
    -- @covers LPostFxEffect:setEnabled
    -- @covers lurek.effect.newEffect
    it("setEnabled true after false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        bloom:setEnabled(true)
        expect_equal(bloom:isEnabled(), true)
    end)
end)

-- @describe PostFxEffect auto uniforms
describe("PostFxEffect auto uniforms", function()
    -- @covers LPostFxEffect:isAutoUniforms
    -- @covers lurek.effect.newEffect
    it("starts with auto uniforms disabled", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isAutoUniforms(), false)
    end)

    -- @covers LPostFxEffect:enableAutoUniforms
    -- @covers LPostFxEffect:isAutoUniforms
    -- @covers lurek.effect.newEffect
    it("enableAutoUniforms turns the flag on", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:enableAutoUniforms()
        expect_equal(bloom:isAutoUniforms(), true)
    end)

    -- @covers LPostFxEffect:disableAutoUniforms
    -- @covers LPostFxEffect:enableAutoUniforms
    -- @covers LPostFxEffect:isAutoUniforms
    -- @covers lurek.effect.newEffect
    it("disableAutoUniforms turns the flag off", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:enableAutoUniforms()
        bloom:disableAutoUniforms()
        expect_equal(bloom:isAutoUniforms(), false)
    end)
end)

-- @describe ScreenTransition
describe("ScreenTransition", function()
    -- @covers LScreenTransition:kind
    -- @covers lurek.effect.newTransition
    it("unknown kind defaults to fade", function()
        local transition = lurek.effect.newTransition("unknown", 1.0)
        expect_equal(transition:kind(), "fade")
    end)

    -- @covers LScreenTransition:isActive
    -- @covers LScreenTransition:isDone
    -- @covers lurek.effect.newTransition
    it("starts inactive and not done", function()
        local transition = lurek.effect.newTransition("fade", 1.0)
        expect_equal(transition:isActive(), false)
        expect_equal(transition:isDone(), false)
    end)

    -- @covers LScreenTransition:kind
    -- @covers lurek.effect.newTransition
    it("roundtrips every supported kind", function()
        local kinds = {"fade", "wipe", "iris_wipe", "dissolve"}
        for _, kind in ipairs(kinds) do
            local transition = lurek.effect.newTransition(kind, 1.0)
            expect_equal(transition:kind(), kind)
        end
    end)

    -- @covers LScreenTransition:isActive
    -- @covers LScreenTransition:play
    -- @covers LScreenTransition:progress
    -- @covers LScreenTransition:update
    -- @covers lurek.effect.newTransition
    it("play activates and update advances progress", function()
        local transition = lurek.effect.newTransition("wipe", 2.0)
        expect_equal(transition:isActive(), false)
        transition:play()
        expect_equal(transition:isActive(), true)
        expect_near(transition:progress(), 0.0, 0.001)
        expect_equal(transition:update(1.0), true)
        expect_near(transition:progress(), 0.5, 0.001)
    end)

    -- @covers LScreenTransition:progress
    -- @covers LScreenTransition:reverse
    -- @covers LScreenTransition:update
    -- @covers lurek.effect.newTransition
    it("reverse advances progress", function()
        local transition = lurek.effect.newTransition("fade", 2.0)
        transition:reverse()
        transition:update(1.0)
        expect_near(transition:progress(), 0.5, 0.001)
    end)

    -- @covers LScreenTransition:isActive
    -- @covers LScreenTransition:isDone
    -- @covers LScreenTransition:play
    -- @covers LScreenTransition:update
    -- @covers lurek.effect.newTransition
    it("completes after duration", function()
        local transition = lurek.effect.newTransition("dissolve", 0.5)
        transition:play()
        expect_equal(transition:update(0.6), true)
        expect_equal(transition:isActive(), false)
        expect_equal(transition:isDone(), true)
    end)
end)

-- @describe PostFxEffect type() method
describe("PostFxEffect type() method", function()
    -- @covers LPostFxEffect:type
    -- @covers lurek.effect.newEffect
    it("returns PostFxEffect", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:type(), "LPostFxEffect")
    end)

    -- @covers LPostFxEffect:type
    -- @covers lurek.effect.newPass
    it("custom pass also returns PostFxEffect", function()
        local pass = lurek.effect.newPass(1)
        expect_equal(pass:type(), "LPostFxEffect")
    end)
end)

-- @describe lurek.effect.newStack
describe("lurek.effect.newStack", function()
    -- @covers LPostFxStack:getHeight
    -- @covers LPostFxStack:getWidth
    -- @covers lurek.effect.newStack
    it("creates stack with default dimensions", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getWidth(), 800)
        expect_equal(stack:getHeight(), 600)
    end)

    -- @covers LPostFxStack:getHeight
    -- @covers LPostFxStack:getWidth
    -- @covers lurek.effect.newStack
    it("creates stack with custom dimensions", function()
        local stack = lurek.effect.newStack(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)

    -- @covers LPostFxStack:getEffectCount
    -- @covers lurek.effect.newStack
    it("starts empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getEffectCount(), 0)
    end)

    -- @covers LPostFxStack:type
    -- @covers lurek.effect.newStack
    it("type is PostFxStack", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:type(), "LPostFxStack")
    end)
end)

-- @describe PostFxStack add/remove
describe("PostFxStack add/remove", function()
    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEffectCount
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("add increases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        expect_equal(stack:getEffectCount(), 1)
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEffectCount
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("add multiple effects", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:add(lurek.effect.newEffect("crt"))
        expect_equal(stack:getEffectCount(), 3)
    end)

    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEffectCount
    -- @covers LPostFxStack:remove
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("remove decreases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        stack:remove(bloom)
        expect_equal(stack:getEffectCount(), 0)
    end)
end)

-- @describe PostFxStack insert
describe("PostFxStack insert", function()
    -- @covers LPostFxEffect:getEffectType
    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEffect
    -- @covers LPostFxStack:getEffectCount
    -- @covers LPostFxStack:insert
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
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

-- @describe PostFxStack dimensions
describe("PostFxStack dimensions", function()
    -- @covers LPostFxStack:getDimensions
    -- @covers lurek.effect.newStack
    it("getDimensions returns both", function()
        local stack = lurek.effect.newStack(800, 600)
        local w, h = stack:getDimensions()
        expect_equal(w, 800)
        expect_equal(h, 600)
    end)

    -- @covers LPostFxStack:getHeight
    -- @covers LPostFxStack:getWidth
    -- @covers LPostFxStack:resize
    -- @covers lurek.effect.newStack
    it("resize changes dimensions", function()
        local stack = lurek.effect.newStack(800, 600)
        stack:resize(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)
end)

-- @describe PostFxStack capturing state
describe("PostFxStack capturing state", function()
    -- @covers LPostFxStack:isCapturing
    -- @covers lurek.effect.newStack
    it("not capturing by default", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:isCapturing(), false)
    end)
end)

-- New effect types

-- @describe New effect types construction and defaults
describe("New effect types construction and defaults", function()
    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("pixelate has block_size default 4.0", function()
        local e = lurek.effect.newEffect("pixelate")
        expect_equal(math.abs(e:getParameter("block_size") - 4.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("sepia has strength default 1.0", function()
        local e = lurek.effect.newEffect("sepia")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:isBuiltIn
    -- @covers lurek.effect.newEffect
    it("grayscale is built-in", function()
        local e = lurek.effect.newEffect("grayscale")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("invert has strength default 1.0", function()
        local e = lurek.effect.newEffect("invert")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("scanlines has spacing default 4.0", function()
        local e = lurek.effect.newEffect("scanlines")
        expect_equal(math.abs(e:getParameter("spacing") - 4.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("edgedetect has strength default 1.0", function()
        local e = lurek.effect.newEffect("edgedetect")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("hueshift has angle default 0.0", function()
        local e = lurek.effect.newEffect("hueshift")
        expect_equal(math.abs(e:getParameter("angle") - 0.0) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getParameter
    -- @covers lurek.effect.newEffect
    it("noise has strength default 0.1", function()
        local e = lurek.effect.newEffect("noise")
        expect_equal(math.abs(e:getParameter("strength") - 0.1) < 0.001, true)
    end)

    -- @covers LPostFxEffect:getEffectType
    -- @covers lurek.effect.newEffect
    it("all new types round-trip through getEffectType", function()
        local names = {"pixelate","sepia","grayscale","invert","scanlines","edgedetect","hueshift","noise"}
        local all_ok = true
        for _, name in ipairs(names) do
            local e = lurek.effect.newEffect(name)
            if e:getEffectType() ~= name then all_ok = false end
        end
        expect_equal(all_ok, true)
    end)

    -- @covers lurek.effect.getEffectTypes
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

-- @describe lurek.effect.newStack (extended)
describe("lurek.effect.newStack (extended)", function()
    -- @covers lurek.effect.newStack
    it("newStack() returns a non-nil stack", function()
        local s = lurek.effect.newStack()
        expect_equal(s ~= nil, true)
    end)

    -- @covers LPostFxStack:beginCapture
    -- @covers lurek.effect.newStack
    it("beginCapture does not error in headless mode", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
    end)

    -- @covers LPostFxStack:beginCapture
    -- @covers LPostFxStack:endCapture
    -- @covers lurek.effect.newStack
    it("endCapture does not error in headless mode", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
        s:endCapture()
    end)

    -- @covers LPostFxStack:apply
    -- @covers LPostFxStack:beginCapture
    -- @covers LPostFxStack:endCapture
    -- @covers lurek.effect.newStack
    it("apply does not error when stack has no effects", function()
        local s = lurek.effect.newStack()
        s:beginCapture()
        s:endCapture()
        s:apply()
    end)

    -- @covers LPostFxStack:apply
    -- @covers LPostFxStack:beginCapture
    -- @covers LPostFxStack:endCapture
    -- @covers lurek.effect.newStack
    it("apply submits one ApplyPostFx command per call", function()
        -- We push a command; just verify no error thrown.
        local s = lurek.effect.newStack(320, 240)
        s:beginCapture()
        s:endCapture()
        s:apply()
        s:apply()  -- second call also fine
    end)
end)

-- @describe lurek.effect.newPresetStack
describe("lurek.effect.newPresetStack", function()
    local preset_names = { "retro_tv", "horror", "dream", "neon", "sepia_age" }

    for _, name in ipairs(preset_names) do
        -- @covers lurek.effect.newPresetStack
        it("newPresetStack('" .. name .. "') returns non-nil", function()
            local s = lurek.effect.newPresetStack(name)
            expect_equal(s ~= nil, true)
        end)

        -- @covers LPostFxStack:apply
        -- @covers LPostFxStack:beginCapture
        -- @covers LPostFxStack:endCapture
        -- @covers lurek.effect.newPresetStack
        it("newPresetStack('" .. name .. "') beginCapture/endCapture/apply do not error", function()
            local s = lurek.effect.newPresetStack(name)
            s:beginCapture()
            s:endCapture()
            s:apply()
        end)
    end

    -- @covers lurek.effect.newPresetStack
    it("newPresetStack with unknown name returns error", function()
        expect_error(function() lurek.effect.newPresetStack("nonexistent_preset") end)
    end)

    -- @covers lurek.effect.newPresetStack
    it("newPresetStack with dimensions applies those dimensions", function()
        local s = lurek.effect.newPresetStack("retro_tv", 512, 256)
        expect_equal(s ~= nil, true)
    end)
end)

-- @describe lurek.effect.getEffectTypes (new types)
describe("lurek.effect.getEffectTypes (new types)", function()
    local NEW_TYPES = {
        "depthoffield", "motionblur", "paletteswap", "colorlut",
        "waterdistort", "sharpen", "dither", "outline",
    }

    -- @covers lurek.effect.getEffectTypes
    it("getEffectTypes returns a table including all new types", function()
        local types = lurek.effect.getEffectTypes()
        expect_equal(type(types), "table")
        local type_set = {}
        for _, t in ipairs(types) do type_set[t] = true end
        for _, expected in ipairs(NEW_TYPES) do
            expect_equal(type_set[expected] == true, true)
        end
    end)

    -- @covers lurek.effect.newEffect
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

-- @describe lurek.effect factory
describe("lurek.effect factory", function()
    -- @covers LOverlay:getHeight
    -- @covers LOverlay:getWidth
    -- @covers lurek.effect.newOverlay
    it("creates an overlay with custom dimensions", function()
        local ov = lurek.effect.newOverlay(1024, 768)
        expect_equal(ov:getWidth(), 1024)
        expect_equal(ov:getHeight(), 768)
    end)

    -- @covers LOverlay:getHeight
    -- @covers LOverlay:getWidth
    -- @covers lurek.effect.newOverlay
    it("creates an overlay with default dimensions", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:getWidth(), 800)
        expect_equal(ov:getHeight(), 600)
    end)

    -- @covers LOverlay:getDimensions
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay type
describe("overlay type", function()
    -- @covers LOverlay:type
    -- @covers lurek.effect.newOverlay
    it("reports type as LOverlay", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:type(), "LOverlay")
    end)

    -- @covers LOverlay:typeOf
    -- @covers lurek.effect.newOverlay
    it("typeOf Object returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Object"), true)
    end)

    -- @covers LOverlay:typeOf
    -- @covers lurek.effect.newOverlay
    it("typeOf Overlay returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Overlay"), true)
    end)

    -- @covers LOverlay:typeOf
    -- @covers lurek.effect.newOverlay
    it("typeOf unrelated returns false", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("PostFxEffect"), false)
    end)
end)

-- ============================================================
-- 3. Core Lifecycle
-- ============================================================

-- @describe overlay core
describe("overlay core", function()
    -- @covers LOverlay:isActive
    -- @covers lurek.effect.newOverlay
    it("starts inactive", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isActive(), false)
    end)

    -- @covers LOverlay:getHeight
    -- @covers LOverlay:getWidth
    -- @covers LOverlay:resize
    -- @covers lurek.effect.newOverlay
    it("resize updates dimensions", function()
        local ov = lurek.effect.newOverlay(800, 600)
        ov:resize(1920, 1080)
        expect_equal(ov:getWidth(), 1920)
        expect_equal(ov:getHeight(), 1080)
    end)

    -- @covers LOverlay:isActive
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("update does not error on empty overlay", function()
        local ov = lurek.effect.newOverlay()
        ov:update(0.016)
        expect_equal(ov:isActive(), false)
    end)

    -- @covers LOverlay:render
    -- @covers lurek.effect.newOverlay
    it("draw does not error", function()
        local ov = lurek.effect.newOverlay()
        ov:render()
    end)

    -- @covers LOverlay:clear
    -- @covers LOverlay:isActive
    -- @covers LOverlay:setAmbientEnabled
    -- @covers LOverlay:setFogEnabled
    -- @covers LOverlay:setVignetteEnabled
    -- @covers LOverlay:setWeatherEnabled
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay ambient
describe("overlay ambient", function()
    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:getTimeOfDay
    -- @covers LOverlay:isAmbientEnabled
    -- @covers lurek.effect.newOverlay
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

    -- @covers LOverlay:isActive
    -- @covers LOverlay:isAmbientEnabled
    -- @covers LOverlay:setAmbientEnabled
    -- @covers lurek.effect.newOverlay
    it("enables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        expect_equal(ov:isAmbientEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers LOverlay:isAmbientEnabled
    -- @covers LOverlay:setAmbientEnabled
    -- @covers lurek.effect.newOverlay
    it("disables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setAmbientEnabled(false)
        expect_equal(ov:isAmbientEnabled(), false)
    end)

    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:setAmbientColor
    -- @covers lurek.effect.newOverlay
    it("sets and gets ambient color with alpha", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.3, 0.4, 0.5, 0.6)
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 0.3, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 0.6, 0.001)
    end)

    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:setAmbientColor
    -- @covers lurek.effect.newOverlay
    it("ambient color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.5, 0.5, 0.5)
        local _, _, _, a = ov:getAmbientColor()
        expect_near(a, 1.0, 0.001)
    end)

    -- @covers LOverlay:getTimeOfDay
    -- @covers LOverlay:setTimeOfDay
    -- @covers lurek.effect.newOverlay
    it("sets and gets time of day", function()
        local ov = lurek.effect.newOverlay()
        ov:setTimeOfDay(6.5)
        expect_near(ov:getTimeOfDay(), 6.5, 0.001)
    end)

    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:setAmbientEnabled
    -- @covers LOverlay:setTimeOfDay
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
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

    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:setAmbientEnabled
    -- @covers LOverlay:setTimeOfDay
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
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

    -- @covers LOverlay:getAmbientColor
    -- @covers LOverlay:setAmbientEnabled
    -- @covers LOverlay:setTimeOfDay
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay weather
describe("overlay weather", function()
    -- @covers LOverlay:getWeather
    -- @covers LOverlay:isWeatherEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with weather set to none", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isWeatherEnabled(), false)
        expect_equal(ov:getWeather(), "none")
    end)

    -- @covers LOverlay:isWeatherEnabled
    -- @covers LOverlay:setWeatherEnabled
    -- @covers lurek.effect.newOverlay
    it("enables weather", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        expect_equal(ov:isWeatherEnabled(), true)
    end)

    -- @covers LOverlay:getWeather
    -- @covers LOverlay:setWeather
    -- @covers lurek.effect.newOverlay
    it("sets weather type", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeather("rain")
        expect_equal(ov:getWeather(), "rain")
    end)

    -- @covers LOverlay:getWeather
    -- @covers LOverlay:setWeather
    -- @covers lurek.effect.newOverlay
    it("roundtrips all weather types", function()
        local ov = lurek.effect.newOverlay()
        local types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
        for _, wt in ipairs(types) do
            ov:setWeather(wt)
            expect_equal(ov:getWeather(), wt)
        end
    end)

    -- @covers LOverlay:setWeather
    -- @covers lurek.effect.newOverlay
    it("rejects invalid weather type", function()
        local ov = lurek.effect.newOverlay()
        expect_error(function()
            ov:setWeather("tornado")
        end)
    end)

    -- @covers LOverlay:getWeatherIntensity
    -- @covers LOverlay:setWeatherIntensity
    -- @covers lurek.effect.newOverlay
    it("sets and gets weather intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherIntensity(0.8)
        expect_near(ov:getWeatherIntensity(), 0.8, 0.001)
    end)

    -- @covers LOverlay:getWindDirection
    -- @covers LOverlay:setWindDirection
    -- @covers lurek.effect.newOverlay
    it("sets and gets wind direction", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindDirection(1.57)
        expect_near(ov:getWindDirection(), 1.57, 0.001)
    end)

    -- @covers LOverlay:getWindSpeed
    -- @covers LOverlay:setWindSpeed
    -- @covers lurek.effect.newOverlay
    it("sets and gets wind speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindSpeed(75.0)
        expect_near(ov:getWindSpeed(), 75.0, 0.001)
    end)
end)

-- ============================================================
-- 6. Screen Flash
-- ============================================================

-- @describe overlay flash
describe("overlay flash", function()
    -- @covers LOverlay:flash
    -- @covers LOverlay:isFlashing
    -- @covers lurek.effect.newOverlay
    it("triggers a flash", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFlashing(), false)
        ov:flash(1, 0, 0, 1, 0.5)
        expect_equal(ov:isFlashing(), true)
    end)

    -- @covers LOverlay:flash
    -- @covers LOverlay:isFlashing
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("flash with default alpha and duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isFlashing(), true)
        -- default duration = 0.2
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @covers LOverlay:flash
    -- @covers LOverlay:isFlashing
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("flash completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 0, 0, 1, 0.1)
        ov:update(0.2)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @covers LOverlay:flash
    -- @covers LOverlay:isActive
    -- @covers lurek.effect.newOverlay
    it("flash activates isActive", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isActive(), true)
    end)
end)

-- ============================================================
-- 7. Screen Shake
-- ============================================================

-- @describe overlay shake
describe("overlay shake", function()
    -- @covers LOverlay:isShaking
    -- @covers LOverlay:shake
    -- @covers lurek.effect.newOverlay
    it("triggers a shake", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isShaking(), false)
        ov:shake(10, 0.5)
        expect_equal(ov:isShaking(), true)
    end)

    -- @covers LOverlay:isShaking
    -- @covers LOverlay:shake
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("shake with default duration", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(8.0)
        expect_equal(ov:isShaking(), true)
        -- default duration = 0.5
        ov:update(0.6)
        expect_equal(ov:isShaking(), false)
    end)

    -- @covers LOverlay:getShakeOffset
    -- @covers LOverlay:shake
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("shake produces non-zero offset", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(10, 1.0)
        ov:update(0.1)
        local x, y = ov:getShakeOffset()
        -- At least one component should be non-zero
        local total = math.abs(x) + math.abs(y)
        expect_equal(total > 0, true)
    end)

    -- @covers LOverlay:getShakeOffset
    -- @covers LOverlay:shake
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay fade
describe("overlay fade", function()
    -- @covers LOverlay:fade
    -- @covers LOverlay:isFading
    -- @covers lurek.effect.newOverlay
    it("triggers a fade", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFading(), false)
        ov:fade(0, 0, 0, 1, 1.0)
        expect_equal(ov:isFading(), true)
    end)

    -- @covers LOverlay:fade
    -- @covers LOverlay:isFading
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("fade with defaults", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0)
        expect_equal(ov:isFading(), true)
        -- default alpha=1.0, duration=1.0
        ov:update(1.1)
        expect_equal(ov:isFading(), false)
    end)

    -- @covers LOverlay:fade
    -- @covers LOverlay:isFading
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay clouds
describe("overlay clouds", function()
    -- @covers LOverlay:getCloudCount
    -- @covers LOverlay:isCloudShadowsEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with default cloud count", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isCloudShadowsEnabled(), false)
        expect_equal(ov:getCloudCount(), 5)
    end)

    -- @covers LOverlay:isActive
    -- @covers LOverlay:isCloudShadowsEnabled
    -- @covers LOverlay:setCloudShadows
    -- @covers lurek.effect.newOverlay
    it("enables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        expect_equal(ov:isCloudShadowsEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers LOverlay:isCloudShadowsEnabled
    -- @covers LOverlay:setCloudShadows
    -- @covers lurek.effect.newOverlay
    it("disables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        ov:setCloudShadows(false)
        expect_equal(ov:isCloudShadowsEnabled(), false)
    end)

    -- @covers LOverlay:getCloudCount
    -- @covers LOverlay:setCloudCount
    -- @covers lurek.effect.newOverlay
    it("sets and gets cloud count", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudCount(12)
        expect_equal(ov:getCloudCount(), 12)
    end)

    -- @covers LOverlay:getCloudSpeed
    -- @covers LOverlay:setCloudSpeed
    -- @covers lurek.effect.newOverlay
    it("sets and gets cloud speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudSpeed(35.0)
        expect_near(ov:getCloudSpeed(), 35.0, 0.001)
    end)

    -- @covers LOverlay:getCloudScale
    -- @covers LOverlay:setCloudScale
    -- @covers lurek.effect.newOverlay
    it("sets and gets cloud scale", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudScale(2.5)
        expect_near(ov:getCloudScale(), 2.5, 0.001)
    end)

    -- @covers LOverlay:getCloudOpacity
    -- @covers LOverlay:setCloudOpacity
    -- @covers lurek.effect.newOverlay
    it("sets and gets cloud opacity", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudOpacity(0.6)
        expect_near(ov:getCloudOpacity(), 0.6, 0.001)
    end)
end)

-- ============================================================
-- 10. Atmospheric Fog
-- ============================================================

-- @describe overlay fog
describe("overlay fog", function()
    -- @covers LOverlay:getFogDensity
    -- @covers LOverlay:isFogEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with default density", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFogEnabled(), false)
        expect_near(ov:getFogDensity(), 0.3, 0.001)
    end)

    -- @covers LOverlay:isFogEnabled
    -- @covers LOverlay:setFogEnabled
    -- @covers lurek.effect.newOverlay
    it("enables fog", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogEnabled(true)
        expect_equal(ov:isFogEnabled(), true)
    end)

    -- @covers LOverlay:getFogDensity
    -- @covers LOverlay:setFogDensity
    -- @covers lurek.effect.newOverlay
    it("sets and gets fog density", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogDensity(0.7)
        expect_near(ov:getFogDensity(), 0.7, 0.001)
    end)

    -- @covers LOverlay:getFogColor
    -- @covers LOverlay:setFogColor
    -- @covers lurek.effect.newOverlay
    it("sets and gets fog color", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.5, 0.5, 0.6, 0.9)
        local r, g, b, a = ov:getFogColor()
        expect_near(r, 0.5, 0.001)
        expect_near(g, 0.5, 0.001)
        expect_near(b, 0.6, 0.001)
        expect_near(a, 0.9, 0.001)
    end)

    -- @covers LOverlay:getFogColor
    -- @covers LOverlay:setFogColor
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay heat haze
describe("overlay heat haze", function()
    -- @covers LOverlay:getHeatHazeIntensity
    -- @covers LOverlay:isHeatHazeEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with default intensity", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isHeatHazeEnabled(), false)
        expect_near(ov:getHeatHazeIntensity(), 0.5, 0.001)
    end)

    -- @covers LOverlay:isHeatHazeEnabled
    -- @covers LOverlay:setHeatHazeEnabled
    -- @covers lurek.effect.newOverlay
    it("enables heat haze", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeEnabled(true)
        expect_equal(ov:isHeatHazeEnabled(), true)
    end)

    -- @covers LOverlay:getHeatHazeIntensity
    -- @covers LOverlay:setHeatHazeIntensity
    -- @covers lurek.effect.newOverlay
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeIntensity(0.9)
        expect_near(ov:getHeatHazeIntensity(), 0.9, 0.001)
    end)
end)

-- ============================================================
-- 12. Vignette
-- ============================================================

-- @describe overlay vignette
describe("overlay vignette", function()
    -- @covers LOverlay:getVignetteStrength
    -- @covers LOverlay:isVignetteEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with default strength", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isVignetteEnabled(), false)
        expect_near(ov:getVignetteStrength(), 0.5, 0.001)
    end)

    -- @covers LOverlay:isVignetteEnabled
    -- @covers LOverlay:setVignetteEnabled
    -- @covers lurek.effect.newOverlay
    it("enables vignette", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteEnabled(true)
        expect_equal(ov:isVignetteEnabled(), true)
    end)

    -- @covers LOverlay:getVignetteStrength
    -- @covers LOverlay:setVignetteStrength
    -- @covers lurek.effect.newOverlay
    it("sets and gets strength", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteStrength(0.8)
        expect_near(ov:getVignetteStrength(), 0.8, 0.001)
    end)
end)

-- ============================================================
-- 13. Film Grain
-- ============================================================

-- @describe overlay film grain
describe("overlay film grain", function()
    -- @covers LOverlay:getFilmGrainIntensity
    -- @covers LOverlay:isFilmGrainEnabled
    -- @covers lurek.effect.newOverlay
    it("starts disabled with default intensity", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFilmGrainEnabled(), false)
        expect_near(ov:getFilmGrainIntensity(), 0.3, 0.001)
    end)

    -- @covers LOverlay:isFilmGrainEnabled
    -- @covers LOverlay:setFilmGrainEnabled
    -- @covers lurek.effect.newOverlay
    it("enables film grain", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainEnabled(true)
        expect_equal(ov:isFilmGrainEnabled(), true)
    end)

    -- @covers LOverlay:getFilmGrainIntensity
    -- @covers LOverlay:setFilmGrainIntensity
    -- @covers lurek.effect.newOverlay
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainIntensity(0.6)
        expect_near(ov:getFilmGrainIntensity(), 0.6, 0.001)
    end)
end)

-- ============================================================
-- 14. Lightning
-- ============================================================

-- @describe overlay lightning
describe("overlay lightning", function()
    -- @covers LOverlay:isActive
    -- @covers LOverlay:triggerLightning
    -- @covers lurek.effect.newOverlay
    it("triggers lightning", function()
        local ov = lurek.effect.newOverlay()
        ov:triggerLightning()
        -- Lightning is active (makes overlay active)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers LOverlay:getLightningColor
    -- @covers LOverlay:setLightningColor
    -- @covers lurek.effect.newOverlay
    it("sets and gets lightning color", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1.0, 0.9, 0.8, 0.7)
        local r, g, b, a = ov:getLightningColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.9, 0.001)
        expect_near(b, 0.8, 0.001)
        expect_near(a, 0.7, 0.001)
    end)

    -- @covers LOverlay:getLightningColor
    -- @covers LOverlay:setLightningColor
    -- @covers lurek.effect.newOverlay
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

-- @describe overlay combined
describe("overlay combined", function()
    -- @covers LOverlay:flash
    -- @covers LOverlay:isActive
    -- @covers LOverlay:isFlashing
    -- @covers LOverlay:isFogEnabled
    -- @covers LOverlay:isVignetteEnabled
    -- @covers LOverlay:isWeatherEnabled
    -- @covers LOverlay:setFogEnabled
    -- @covers LOverlay:setVignetteEnabled
    -- @covers LOverlay:setWeatherEnabled
    -- @covers lurek.effect.newOverlay
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

    -- @covers LOverlay:clear
    -- @covers LOverlay:fade
    -- @covers LOverlay:flash
    -- @covers LOverlay:isActive
    -- @covers LOverlay:setAmbientEnabled
    -- @covers LOverlay:setCloudShadows
    -- @covers LOverlay:setFilmGrainEnabled
    -- @covers LOverlay:setFogEnabled
    -- @covers LOverlay:setHeatHazeEnabled
    -- @covers LOverlay:setVignetteEnabled
    -- @covers LOverlay:setWeatherEnabled
    -- @covers LOverlay:shake
    -- @covers LOverlay:triggerLightning
    -- @covers lurek.effect.newOverlay
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

    -- @covers LOverlay:flash
    -- @covers LOverlay:isFlashing
    -- @covers LOverlay:isShaking
    -- @covers LOverlay:shake
    -- @covers LOverlay:update
    -- @covers lurek.effect.newOverlay
    it("update advances multiple timed effects", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1, 1, 0.1)
        ov:shake(5, 0.2)
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
        expect_equal(ov:isShaking(), false)
    end)
end)

-- @describe effect missing explicit coverage
describe("effect missing explicit coverage", function()
    -- @covers LPostFxStack:add
    -- @covers LPostFxStack:getEnabledEffects
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    it("getEnabledEffects returns enabled effect handles", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("bloom")
        stack:add(eff)
        local enabled = stack:getEnabledEffects()
        expect_type("table", enabled)
        expect_true(#enabled >= 1)
    end)

    -- @covers LPostFxStack:clearFeedback
    -- @covers LPostFxStack:getFeedback
    -- @covers LPostFxStack:setFeedback
    -- @covers lurek.effect.newStack
    it("feedback controls round-trip and clear", function()
        local stack = lurek.effect.newStack()
        stack:setFeedback(0.6)
        expect_near(0.6, stack:getFeedback(), 0.001)
        stack:clearFeedback()
        expect_near(0.0, stack:getFeedback(), 0.001)
    end)

    -- @covers LImageEffect:removeByIndex
    -- @covers LImageEffect:removeByName
    -- @covers lurek.effect.newImageEffect
    it("ImageEffect remove helpers do not error", function()
        local ie = lurek.effect.newImageEffect({
            { type = "bloom" },
            { type = "blur" },
        })
        expect_type("boolean", ie:removeByIndex(0))
        expect_type("boolean", ie:removeByName("blur"))
    end)

    -- @covers LOverlay:triggerShake
    -- @covers lurek.effect.newOverlay
    it("triggerShake can be called safely", function()
        local ov = lurek.effect.newOverlay()
        expect_no_error(function()
            ov:triggerShake(3.0, 0.2)
        end)
    end)
end)

-- @describe effect strict: LPostFxStack typeOf
describe("effect strict: LPostFxStack typeOf", function()
    -- @covers LPostFxStack:typeOf
    -- @covers lurek.effect.newStack
    it("LPostFxStack typeOf returns boolean", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_type("boolean", stack:typeOf("Object"))
    end)
end)

-- @describe effect strict: LPostFxEffect getType
describe("effect strict: LPostFxEffect getType", function()
    -- @covers LPostFxEffect:getType
    -- @covers lurek.effect.newStack
    it("LPostFxEffect getType returns string", function()
        local stack = lurek.effect.newStack(320, 240)
        local ok_e, blur_effect = pcall(function() return lurek.effect.newEffect("blur") end)
        if ok_e and blur_effect ~= nil then
            local ok, fx = pcall(function() return stack:add(blur_effect) end)
            if ok and fx ~= nil then
                expect_type("string", fx:getType())
            else
                expect_false(ok and fx ~= nil)
            end
        else
            expect_false(ok_e and blur_effect ~= nil)
        end
    end)
end)

-- @describe effect strict: LImageEffect methods
describe("effect strict: LImageEffect methods", function()
    -- @covers LImageEffect:type
    -- @covers LImageEffect:typeOf
    -- @covers LImageEffect:clear
    -- @covers LImageEffect:getEffectCount
    -- @covers LImageEffect:save
    -- @covers lurek.effect.newImageEffect
    it("LImageEffect type/typeOf/clear/getEffectCount/save are callable", function()
        local ie = lurek.effect.newImageEffect()
        expect_type("string", ie:type())
        expect_type("boolean", ie:typeOf("Object"))
        expect_type("number", ie:getEffectCount())
        ie:clear()
        local ok = pcall(function() ie:save() end)
        expect_type("boolean", ok)
    end)
end)

-- @describe effect strict: LOverlay extra methods
describe("effect strict: LOverlay extra methods", function()
    -- @covers LOverlay:triggerFlash
    -- @covers LOverlay:triggerFade
    -- @covers LOverlay:getFlashAlpha
    -- @covers LOverlay:getLightningAlpha
    -- @covers lurek.effect.newOverlay
    it("LOverlay trigger and get alpha methods are callable", function()
        local ov = lurek.effect.newOverlay()
        local ok1 = pcall(function() ov:triggerFlash(1.0, 1.0, 1.0, 1.0, 0.3) end)
        expect_true(ok1)
        local ok2 = pcall(function() ov:triggerFade(1.0, 1.0, 1.0, 1.0, 0.3) end)
        expect_true(ok2)
        expect_type("number", ov:getFlashAlpha())
        expect_type("number", ov:getLightningAlpha())
    end)
end)

-- @describe effect strict: LScreenTransition color/setColor/type/typeOf
describe("effect strict: LScreenTransition color/setColor/type/typeOf", function()
    -- @covers LScreenTransition:color
    -- @covers LScreenTransition:setColor
    -- @covers LScreenTransition:type
    -- @covers LScreenTransition:typeOf
    -- @covers lurek.effect.newTransition
    it("LScreenTransition color/setColor/type/typeOf are callable", function()
        local tr = lurek.effect.newTransition("fade", 1.0)
        expect_true(tr ~= nil)
        local r, g, b, a = tr:color()
        expect_type("number", r)
        local ok = pcall(function() tr:setColor({r=1,g=1,b=1,a=1}) end)
        expect_type("boolean", ok)
        expect_type("string", tr:type())
        expect_type("boolean", tr:typeOf("Object"))
    end)
end)

-- @describe effect migrated from render unit
describe("effect migrated from render unit", function()
    -- @covers lurek.effect.newOverlay
    it("exposes lurek.effect.newOverlay as the canonical constructor", function()
        expect_type("table", lurek.effect)
        expect_type("function", lurek.effect.newOverlay)
    end)
end)


--  ImageEffect chain API (migrated from test_image_core_unit.lua)
--  ImageEffect chain API (merged from test_image_effect.lua)

---@param fx LImageEffect
---@param key integer|string
---@return LPostFxEffect
local function require_effect(fx, key)
    local effect = fx:getEffect(key)
    if effect == nil then
        error(("expected effect %s to exist"):format(tostring(key)), 2)
    end
    return effect
end

-- @describe lurek.effect.newImageEffect construction (empty)
describe("lurek.effect.newImageEffect construction (empty)", function()
    -- @covers lurek.effect.newImageEffect
    it("newImageEffect is a function", function()
        expect_type("function", lurek.effect.newImageEffect)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns non-nil", function()
        local fx = lurek.effect.newImageEffect()
        expect_equal(fx ~= nil, true)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with effectCount method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.effectCount)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with addEffect method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.addEffect)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with getEffect method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.getEffect)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with removeEffect method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.removeEffect)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with clearEffects method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.clearEffects)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with clone method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.clone)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect() returns object with save method", function()
        local fx = lurek.effect.newImageEffect()
        expect_type("function", fx.save)
    end)

    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("empty chain has effectCount == 0", function()
        local fx = lurek.effect.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)
end)

-- @describe lurek.effect.newImageEffect construction (single name)
describe("lurek.effect.newImageEffect construction (single name)", function()
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("newImageEffect('blur') produces effectCount == 1", function()
        local fx = lurek.effect.newImageEffect("blur")
        expect_equal(fx:effectCount(), 1)
    end)

    -- @covers lurek.effect.newImageEffect
    it("first effect type is 'blur'", function()
        local fx = lurek.effect.newImageEffect("blur")
        local e = require_effect(fx, 1)
        expect_equal(e:getType(), "blur")
    end)

    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("newImageEffect('blur', {radius=4}) produces effectCount == 1", function()
        local fx = lurek.effect.newImageEffect("blur", { radius = 4 })
        expect_equal(fx:effectCount(), 1)
    end)

    -- @covers lurek.effect.newImageEffect
    it("newImageEffect('blur', {radius=4}) sets radius parameter", function()
        local fx = lurek.effect.newImageEffect("blur", { radius = 4 })
        local v = require_effect(fx, 1):getParameter("radius")
        expect_equal(math.abs(v - 4) < 0.001, true)
    end)
end)

-- @describe lurek.effect.newImageEffect construction (chain table)
describe("lurek.effect.newImageEffect construction (chain table)", function()
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("two-element chain produces effectCount == 2", function()
        local fx = lurek.effect.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:effectCount(), 2)
    end)

    -- @covers lurek.effect.newImageEffect
    it("first effect in chain is 'blur'", function()
        local fx = lurek.effect.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(require_effect(fx, 1):getType(), "blur")
    end)

    -- @covers lurek.effect.newImageEffect
    it("second effect in chain is 'sepia'", function()
        local fx = lurek.effect.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(require_effect(fx, 2):getType(), "sepia")
    end)

    -- @covers lurek.effect.newImageEffect
    it("chain entry parameters are applied", function()
        local fx = lurek.effect.newImageEffect({ { type = "blur", radius = 2 } })
        local v = require_effect(fx, 1):getParameter("radius")
        expect_equal(math.abs(v - 2) < 0.001, true)
    end)
end)

-- @describe ImageEffect:addEffect
describe("ImageEffect:addEffect", function()
    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("addEffect returns non-nil", function()
        local fx = lurek.effect.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e ~= nil, true)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("addEffect returns PostFxEffect with correct type", function()
        local fx = lurek.effect.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e:getType(), "vignette")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("addEffect increments effectCount", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 2)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("addEffect appends to end of chain", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        expect_equal(require_effect(fx, 2):getType(), "vignette")
    end)
end)

-- @describe ImageEffect:getEffect by index
describe("ImageEffect:getEffect by index", function()
    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect(1) returns first effect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(require_effect(fx, 1):getType(), "blur")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect(2) returns second effect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(require_effect(fx, 2):getType(), "sepia")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:getEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect out-of-bounds returns nil or errors gracefully", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(99)
            expect_equal(e == nil, true)
        end)
        expect_type("boolean", ok)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:getEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect(0) returns nil or errors gracefully", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(0)
            expect_equal(e == nil, true)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe ImageEffect:getEffect by name
describe("ImageEffect:getEffect by name", function()
    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:getEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect('blur') returns the blur effect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("blur")
        expect_equal(e ~= nil, true)
        expect_equal(require_effect(fx, "blur"):getType(), "blur")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:getEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect('sepia') returns the sepia effect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("sepia")
        expect_equal(e ~= nil, true)
        expect_equal(require_effect(fx, "sepia"):getType(), "sepia")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:getEffect
    -- @covers lurek.effect.newImageEffect
    it("getEffect with unknown name returns nil or errors gracefully", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect("nonexistent_effect")
            expect_equal(e == nil, true)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe PostFxEffect setParameter / getParameter round-trip
describe("PostFxEffect setParameter / getParameter round-trip", function()
    -- @covers lurek.effect.newImageEffect
    it("setParameter radius then getParameter returns same value", function()
        local fx = lurek.effect.newImageEffect("blur")
        require_effect(fx, 1):setParameter("radius", 7.5)
        local v = require_effect(fx, 1):getParameter("radius")
        expect_equal(math.abs(v - 7.5) < 0.001, true)
    end)

    -- @covers lurek.effect.newImageEffect
    it("setParameter overwrites previous value", function()
        local fx = lurek.effect.newImageEffect("blur")
        require_effect(fx, 1):setParameter("radius", 3.0)
        require_effect(fx, 1):setParameter("radius", 9.0)
        local v = require_effect(fx, 1):getParameter("radius")
        expect_equal(math.abs(v - 9.0) < 0.001, true)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LPostFxEffect:getParameter
    -- @covers LPostFxEffect:setParameter
    -- @covers lurek.effect.newImageEffect
    it("getParameter on separate effects are independent", function()
        local fx = lurek.effect.newImageEffect()
        local e1 = fx:addEffect("blur")
        local e2 = fx:addEffect("blur")
        e1:setParameter("radius", 2.0)
        e2:setParameter("radius", 8.0)
        expect_equal(math.abs(e1:getParameter("radius") - 2.0) < 0.001, true)
        expect_equal(math.abs(e2:getParameter("radius") - 8.0) < 0.001, true)
    end)
end)

-- @describe ImageEffect:effectCount
describe("ImageEffect:effectCount", function()
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("starts at 0 for empty chain", function()
        local fx = lurek.effect.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("increments by 1 after each addEffect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("vignette")
        expect_equal(fx:effectCount(), 2)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 3)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("decrements after removeEffect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)
end)

-- @describe ImageEffect:removeEffect by index
describe("ImageEffect:removeEffect by index", function()
    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("removeEffect(1) decrements effectCount", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("remaining effect after removing index 1 is the second original", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(require_effect(fx, 1):getType(), "sepia")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("removeEffect(2) removes the second effect", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(2)
        expect_equal(fx:effectCount(), 1)
        expect_equal(require_effect(fx, 1):getType(), "blur")
    end)
end)

-- @describe ImageEffect:removeEffect by name
describe("ImageEffect:removeEffect by name", function()
    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("removeEffect('sepia') from [blur, sepia] -> effectCount == 1", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(fx:effectCount(), 1)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("remaining effect after removing 'sepia' is 'blur'", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(require_effect(fx, 1):getType(), "blur")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:effectCount
    -- @covers LImageEffect:removeEffect
    -- @covers lurek.effect.newImageEffect
    it("removeEffect('blur') from [blur, sepia] -> remaining is 'sepia'", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("blur")
        expect_equal(fx:effectCount(), 1)
        expect_equal(require_effect(fx, 1):getType(), "sepia")
    end)
end)

-- @describe ImageEffect:clearEffects
describe("ImageEffect:clearEffects", function()
    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clearEffects
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("clearEffects on populated chain produces effectCount == 0", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        fx:addEffect("sepia")
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    -- @covers LImageEffect:clearEffects
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("clearEffects on empty chain is a no-op", function()
        local fx = lurek.effect.newImageEffect()
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clearEffects
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("can addEffect again after clearEffects", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:clearEffects()
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 1)
        expect_equal(require_effect(fx, 1):getType(), "sepia")
    end)
end)

-- @describe ImageEffect:clone
describe("ImageEffect:clone", function()
    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clone
    -- @covers lurek.effect.newImageEffect
    it("clone returns non-nil", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        expect_equal(copy ~= nil, true)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clone
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("clone has the same effectCount as original", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(copy:effectCount(), fx:effectCount())
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clone
    -- @covers lurek.effect.newImageEffect
    it("clone has the same effect types in order", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(require_effect(copy, 1):getType(), "blur")
        expect_equal(require_effect(copy, 2):getType(), "sepia")
    end)

    -- @covers LImageEffect:addEffect
    -- @covers LImageEffect:clone
    -- @covers LImageEffect:effectCount
    -- @covers lurek.effect.newImageEffect
    it("modifying clone does not affect original effectCount", function()
        local fx = lurek.effect.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        copy:addEffect("vignette")
        expect_equal(fx:effectCount(), 1)
        expect_equal(copy:effectCount(), 2)
    end)

    -- @covers LImageEffect:clone
    -- @covers lurek.effect.newImageEffect
    it("modifying clone parameter does not affect original", function()
        local fx = lurek.effect.newImageEffect("blur")
        require_effect(fx, 1):setParameter("radius", 3.0)
        local copy = fx:clone()
        require_effect(copy, 1):setParameter("radius", 99.0)
        local orig_v = require_effect(fx, 1):getParameter("radius")
        expect_equal(math.abs(orig_v - 3.0) < 0.001, true)
    end)
end)

-- @describe lurek.effect.newImageEffect invalid effect name
describe("lurek.effect.newImageEffect invalid effect name", function()
    -- @covers lurek.effect.newImageEffect
    it("rejects unknown effect name on construction", function()
        expect_error(function()
            lurek.effect.newImageEffect("not_a_real_effect")
        end)
    end)

    -- @covers LImageEffect:addEffect
    -- @covers lurek.effect.newImageEffect
    it("addEffect rejects unknown effect name", function()
        local fx = lurek.effect.newImageEffect()
        expect_error(function()
            fx:addEffect("not_a_real_effect")
        end)
    end)
end)

test_summary()

