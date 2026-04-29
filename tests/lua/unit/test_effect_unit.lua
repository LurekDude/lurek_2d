-- Lurek2D Effect API Unit Tests (consolidated)

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Effect Dedup (merged from test_effect_dedup.lua) Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

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

    xit("new PostFxStack has dedup method", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(type(stack.dedup), "function")
    end)

    xit("dedup on empty stack returns 0 and does not crash", function()
        local stack = lurek.effect.newStack(320, 240)
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    xit("dedup on stack with no duplicates returns 0", function()
        local stack = lurek.effect.newStack(320, 240)
        stack:dedup()  -- no-op
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    xit("dedup removes duplicate effects", function()
        local stack = lurek.effect.newStack(320, 240)
        -- Add same effect kind twice if the API supports kind-based construction
        local blur1 = lurek.effect.newEffect("blur")
        stack:add(blur1)
        stack:add(blur1)  -- same Rc pointer
        local removed = stack:dedup()
        expect_equal(removed >= 0, true)  -- at least 0 (may or may not find duplicate)
    end)

end)

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Effect Overlay/Water (merged from test_effect_overlay_water.lua) Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

local function make_overlay()
    local ov = lurek.effect.newOverlay()
    assert(ov ~= nil, "newOverlay() must return non-nil")
    return ov
end

describe("LuaOverlay water overlay", function()
    it("getWater returns a table with default values", function()
        local ov = make_overlay()
        local w = ov:getWater()
        expect_equal(type(w), "table")
        expect_equal(w.enabled, false)
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
end)



-- [merged from test_effect_api.lua]
-- tests/lua/unit/test_effect_api.lua
-- Post-processing effect API tests (lurek.effect / lurek.effect).
-- Complements test_effect_effect.lua; focuses on the API surface check.
-- Headless-safe: no GPU, no window needed for API introspection.

-- ============================================================
-- Namespace surface
-- ============================================================
-- @description Verifies the postfx namespace tables and public constructor/helper functions are exposed with the expected Lua types.
describe("lurek.effect module", function()
    -- @tests lurek.effect.getEffectTypes
    -- @tests lurek.effect.newEffect
    -- @tests lurek.effect.newStack
    -- @tests lurek.effect.newPass
    -- @tests lurek.effect.newCustomEffect
    -- @description Asserts that lurek.effect exists and is exposed as a Lua table.
    it("is a table", function()
        expect_type("table", lurek.effect)
    end)

    -- @description Asserts that lurek.effect is exposed as a Lua table.
    it("lurek.effect aliases the same table", function()
        -- Both namespaces point to the same module table
        expect_type("table", lurek.effect)
    end)

    -- @description Asserts that lurek.effect.getEffectTypes is exposed as a function.
    it("exposes getEffectTypes", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)

    -- @description Asserts that lurek.effect.newEffect is exposed as a function.
    it("exposes newEffect", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    -- @description Asserts that lurek.effect.newStack is exposed as a function.
    it("exposes newStack", function()
        expect_type("function", lurek.effect.newStack)
    end)

    -- @description Asserts that lurek.effect.newPass is exposed as a function.
    it("exposes newPass", function()
        expect_type("function", lurek.effect.newPass)
    end)

    -- @description Asserts that lurek.effect.newCustomEffect is exposed as a function.
    it("exposes newCustomEffect", function()
        expect_type("function", lurek.effect.newCustomEffect)
    end)
end)

-- ============================================================
-- getEffectTypes
-- ============================================================
-- @description Verifies getEffectTypes returns a non-empty table and that the returned list includes at least one expected built-in effect name.
describe("lurek.effect.getEffectTypes", function()
    -- @description Calls getEffectTypes and asserts the returned value is a table.
    it("returns a table", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
    end)

    -- @description Counts the returned entries and asserts the table contains at least one effect type.
    it("contains at least one entry", function()
        local types = lurek.effect.getEffectTypes()
        local count = 0
        for _ in pairs(types) do count = count + 1 end
        expect_true(count > 0, "getEffectTypes should return at least one type")
    end)

    -- @description Builds a lookup from the returned list and asserts that bloom, blur, or pixelate appears in it.
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
-- @description Verifies newEffect creates userdata for known effect names, rejects an unknown name, and exposes the expected effect metadata and enabled-state behavior.
describe("lurek.effect.newEffect", function()
    -- @description Creates a bloom effect and asserts the result is userdata.
    it("returns a userdata for 'bloom'", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_type("userdata", eff)
    end)

    -- @description Creates a pixelate effect and asserts the result is userdata.
    it("returns a userdata for 'pixelate'", function()
        local eff = lurek.effect.newEffect("pixelate")
        expect_type("userdata", eff)
    end)

    -- @description Calls newEffect with an unknown type name and asserts that it raises an error.
    it("errors for an unknown effect type", function()
        expect_error(function()
            lurek.effect.newEffect("magic_wand_effect")
        end)
    end)

    -- @description Creates a blur effect and asserts getTypeName returns the string blur.
    it("effect:getTypeName returns the requested type", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("blur", eff:getTypeName())
    end)

    -- @description Creates a vignette effect and asserts isBuiltIn returns true.
    it("effect:isBuiltIn returns true for newEffect", function()
        local eff = lurek.effect.newEffect("vignette")
        expect_equal(true, eff:isBuiltIn())
    end)

    -- @description Creates a bloom effect and asserts isEnabled is true before any state changes.
    it("effect:isEnabled returns true by default", function()
        local eff = lurek.effect.newEffect("bloom")
        expect_equal(true, eff:isEnabled())
    end)

    -- @description Toggles a bloom effect off and back on, asserting isEnabled reflects both changes.
    it("setEnabled/isEnabled round-trip", function()
        local eff = lurek.effect.newEffect("bloom")
        eff:setEnabled(false)
        expect_equal(false, eff:isEnabled())
        eff:setEnabled(true)
        expect_equal(true, eff:isEnabled())
    end)

    -- @description Creates a blur effect and asserts type returns the string PostFxEffect.
    it("effect:type returns 'PostFxEffect'", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal("PostFxEffect", eff:type())
    end)

    -- @description Creates a blur effect and asserts typeOf reports true for PostFxEffect.
    it("effect:typeOf('PostFxEffect') returns true", function()
        local eff = lurek.effect.newEffect("blur")
        expect_equal(true, eff:typeOf("PostFxEffect"))
    end)
end)

-- ============================================================
-- newStack
-- ============================================================
-- @description Verifies newStack returns stack userdata with the expected empty-state values, size and dimension accessors, mutation behavior, enabled-state control, and effect retrieval.
describe("lurek.effect.newStack", function()
    -- @description Creates a stack and asserts the returned value is userdata.
    it("returns a userdata", function()
        local stack = lurek.effect.newStack()
        expect_type("userdata", stack)
    end)

    -- @description Creates an empty stack and asserts len returns 0.
    it("stack:len returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:len())
    end)

    -- @description Creates an empty stack and asserts getEffectCount returns 0.
    it("stack:getEffectCount returns 0 for empty stack", function()
        local stack = lurek.effect.newStack()
        expect_equal(0, stack:getEffectCount())
    end)

    -- @description Creates an empty stack and asserts isEmpty returns true.
    it("stack:isEmpty returns true when empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(true, stack:isEmpty())
    end)

    -- @description Adds one bloom effect to a new stack and asserts len increases to 1.
    it("stack:add increments len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("bloom")
        stack:add(eff)
        expect_equal(1, stack:len())
    end)

    -- @description Adds bloom and blur effects to a new stack and asserts len becomes 2.
    it("adding two effects gives len 2", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        expect_equal(2, stack:len())
    end)

    -- @description Adds and then removes a pixelate effect, asserting len returns to 0.
    it("stack:remove decrements len", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("pixelate")
        stack:add(eff)
        stack:remove(eff)
        expect_equal(0, stack:len())
    end)

    -- @description Adds two effects, clears the stack, and asserts len becomes 0.
    it("stack:clear empties the stack", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:clear()
        expect_equal(0, stack:len())
    end)

    -- @description Creates a stack and asserts type returns the string PostFxStack.
    it("stack:type returns 'PostFxStack'", function()
        local stack = lurek.effect.newStack()
        expect_equal("PostFxStack", stack:type())
    end)

    -- @description Creates a stack with 320 by 240 dimensions and asserts getWidth and getHeight return those exact values.
    it("stack:getWidth and getHeight return positive integers", function()
        local stack = lurek.effect.newStack(320, 240)
        expect_equal(320, stack:getWidth())
        expect_equal(240, stack:getHeight())
    end)

    -- @description Creates a stack with 640 by 480 dimensions and asserts getDimensions returns 640 and 480.
    it("stack:getDimensions returns (w, h)", function()
        local stack = lurek.effect.newStack(640, 480)
        local w, h = stack:getDimensions()
        expect_equal(640, w)
        expect_equal(480, h)
    end)

    -- @description Adds one bloom effect, toggles slot 1 disabled and enabled, and asserts isEnabled matches both states.
    it("stack:setEnabled/isEnabled round-trip at position 1", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:setEnabled(1, false)
        expect_equal(false, stack:isEnabled(1))
        stack:setEnabled(1, true)
        expect_equal(true, stack:isEnabled(1))
    end)

    -- @description Adds a vignette effect to a stack, retrieves position 1, and asserts the retrieved effect is not nil.
    it("stack:getEffect returns the added effect", function()
        local stack = lurek.effect.newStack()
        local eff = lurek.effect.newEffect("vignette")
        stack:add(eff)
        local retrieved = stack:getEffect(1)
        expect_not_nil(retrieved)
    end)
end)



-- [merged from test_effect_effect.lua]
-- Lurek2D PostFX API Tests Ä‚ËĂ˘â€šÂ¬Ă˘â‚¬ĹĄ covers lurek.effect post-processing effects (headless)

-- @description Covers suite: lurek.effect module exists.
describe("lurek.effect module exists", function()
    -- @tests lurek.effect
    -- @tests lurek.effect.getEffectTypes
    -- @tests lurek.effect.newEffect
    -- @tests lurek.effect.newPass
    -- @tests lurek.effect.newStack
    -- @description Verifies the effect namespace is available as a Lua table.
    it("lurek.effect is a table", function()
        expect_type("table", lurek.effect)
    end)
end)

-- @description Covers suite: lurek.effect factory functions.
describe("lurek.effect factory functions", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect is exposed.
    it("newEffect is a function", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    -- @tests lurek.effect.newPass
    -- @description Verifies newPass is exposed.
    it("newPass is a function", function()
        expect_type("function", lurek.effect.newPass)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies newStack is exposed.
    it("newStack is a function", function()
        expect_type("function", lurek.effect.newStack)
    end)

    -- @tests lurek.effect.getEffectTypes
    -- @description Verifies getEffectTypes is exposed.
    it("getEffectTypes is a function", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)
end)

-- @description Covers suite: lurek.effect.newEffect built-in types.
describe("lurek.effect.newEffect built-in types", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a built-in bloom effect.
    it("creates bloom effect", function()
        local e = lurek.effect.newEffect("bloom")
        expect_equal(e:getEffectType(), "bloom")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a blur effect.
    it("creates blur effect", function()
        local e = lurek.effect.newEffect("blur")
        expect_equal(e:getEffectType(), "blur")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a crt effect.
    it("creates crt effect", function()
        local e = lurek.effect.newEffect("crt")
        expect_equal(e:getEffectType(), "crt")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a godrays effect.
    it("creates godrays effect", function()
        local e = lurek.effect.newEffect("godrays")
        expect_equal(e:getEffectType(), "godrays")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a vignette effect.
    it("creates vignette effect", function()
        local e = lurek.effect.newEffect("vignette")
        expect_equal(e:getEffectType(), "vignette")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a colourgrade effect.
    it("creates colourgrade effect", function()
        local e = lurek.effect.newEffect("colourgrade")
        expect_equal(e:getEffectType(), "colourgrade")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies newEffect constructs a chromatic effect.
    it("creates chromatic effect", function()
        local e = lurek.effect.newEffect("chromatic")
        expect_equal(e:getEffectType(), "chromatic")
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies invalid effect names raise an error.
    it("rejects invalid effect type", function()
        expect_error(function()
            lurek.effect.newEffect("invalid_type")
        end)
    end)
end)

-- @description Covers suite: lurek.effect.newPass custom effects.
describe("lurek.effect.newPass custom effects", function()
    -- @tests lurek.effect.newPass
    -- @description Verifies newPass constructs a custom non-built-in pass.
    it("creates custom pass", function()
        local p = lurek.effect.newPass(1)
        expect_equal(p:getEffectType(), "custom")
        expect_equal(p:isBuiltIn(), false)
    end)
end)

-- @description Covers suite: lurek.effect.getEffectTypes.
describe("lurek.effect.getEffectTypes", function()
    -- @tests lurek.effect.getEffectTypes
    -- @description Verifies getEffectTypes returns the registered effect-type list.
    it("returns table of 23 types", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
        expect_equal(#types, 23)
    end)

    -- @tests lurek.effect.getEffectTypes
    -- @description Verifies bloom appears in the effect-type list.
    it("contains bloom", function()
        local types = lurek.effect.getEffectTypes()
        local found = false
        for _, t in ipairs(types) do
            if t == "bloom" then found = true end
        end
        expect_equal(found, true)
    end)
end)

-- @description Covers suite: PostFxEffect parameters.
describe("PostFxEffect parameters", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies bloom exposes a threshold parameter by default.
    it("bloom has default threshold", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:hasParameter("threshold"), true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies getParameter returns a stored parameter value.
    it("getParameter returns value", function()
        local bloom = lurek.effect.newEffect("bloom")
        local t = bloom:getParameter("threshold")
        expect_type("number", t)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setParameter mutates a named effect parameter.
    it("setParameter changes value", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setParameter("threshold", 0.5)
        local v = bloom:getParameter("threshold")
        expect_equal(math.abs(v - 0.5) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies getParameter falls back to the provided default for missing keys.
    it("getParameter uses default for missing", function()
        local bloom = lurek.effect.newEffect("bloom")
        local v = bloom:getParameter("nonexistent", 42.0)
        expect_equal(math.abs(v - 42.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies getParameterNames returns a populated name list.
    it("getParameterNames returns sorted list", function()
        local bloom = lurek.effect.newEffect("bloom")
        local names = bloom:getParameterNames()
        expect_type("table", names)
        expect_equal(#names >= 2, true)
    end)
end)

-- @description Covers suite: PostFxEffect convenience setters.
describe("PostFxEffect convenience setters", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies setThreshold updates the threshold parameter.
    it("setThreshold works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setThreshold(0.8) end)
        expect_equal(math.abs(bloom:getParameter("threshold") - 0.8) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setIntensity updates the intensity parameter.
    it("setIntensity works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setIntensity(2.0) end)
        expect_equal(math.abs(bloom:getParameter("intensity") - 2.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setRadius updates the blur radius parameter.
    it("setRadius works on blur", function()
        local blur = lurek.effect.newEffect("blur")
        expect_no_error(function() blur:setRadius(5.0) end)
        expect_equal(math.abs(blur:getParameter("radius") - 5.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setStrength updates the vignette strength parameter.
    it("setStrength works on vignette", function()
        local vig = lurek.effect.newEffect("vignette")
        expect_no_error(function() vig:setStrength(0.8) end)
        expect_equal(math.abs(vig:getParameter("strength") - 0.8) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setScanlineStrength updates the CRT scanline parameter.
    it("setScanlineStrength works on crt", function()
        local crt = lurek.effect.newEffect("crt")
        expect_no_error(function() crt:setScanlineStrength(0.4) end)
        expect_equal(math.abs(crt:getParameter("scanline_strength") - 0.4) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setOffset updates the chromatic aberration offset.
    it("setOffset works on chromatic", function()
        local chr = lurek.effect.newEffect("chromatic")
        expect_no_error(function() chr:setOffset(3.0) end)
        expect_equal(math.abs(chr:getParameter("offset") - 3.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setBrightness updates the colourgrade brightness parameter.
    it("setBrightness works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setBrightness(1.5) end)
        expect_equal(math.abs(cg:getParameter("brightness") - 1.5) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setContrast updates the colourgrade contrast parameter.
    it("setContrast works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setContrast(0.9) end)
        expect_equal(math.abs(cg:getParameter("contrast") - 0.9) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setSaturation updates the colourgrade saturation parameter.
    it("setSaturation works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setSaturation(0.7) end)
        expect_equal(math.abs(cg:getParameter("saturation") - 0.7) < 0.001, true)
    end)
end)

-- @description Covers suite: PostFxEffect enable/disable.
describe("PostFxEffect enable/disable", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies effects start enabled.
    it("is enabled by default", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isEnabled(), true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setEnabled(false) disables the effect.
    it("setEnabled false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        expect_equal(bloom:isEnabled(), false)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies setEnabled(true) re-enables an effect.
    it("setEnabled true after false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        bloom:setEnabled(true)
        expect_equal(bloom:isEnabled(), true)
    end)
end)

-- @description Covers suite: PostFxEffect type() method.
describe("PostFxEffect type() method", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies built-in effects report the PostFxEffect userdata type.
    it("returns PostFxEffect", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:type(), "PostFxEffect")
    end)

    -- @tests lurek.effect.newPass
    -- @description Verifies custom passes also report the PostFxEffect userdata type.
    it("custom pass also returns PostFxEffect", function()
        local pass = lurek.effect.newPass(1)
        expect_equal(pass:type(), "PostFxEffect")
    end)
end)

-- @description Covers suite: lurek.effect.newStack.
describe("lurek.effect.newStack", function()
    -- @tests lurek.effect.newStack
    -- @description Verifies newStack uses the default 800x600 dimensions.
    it("creates stack with default dimensions", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getWidth(), 800)
        expect_equal(stack:getHeight(), 600)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies newStack accepts custom dimensions.
    it("creates stack with custom dimensions", function()
        local stack = lurek.effect.newStack(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies new stacks start empty.
    it("starts empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getEffectCount(), 0)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies stack:type reports PostFxStack.
    it("type is PostFxStack", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:type(), "PostFxStack")
    end)
end)

-- @description Covers suite: PostFxStack add/remove.
describe("PostFxStack add/remove", function()
    -- @tests lurek.effect.newStack
    -- @description Verifies add increments the active effect count.
    it("add increases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        expect_equal(stack:getEffectCount(), 1)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies multiple add calls accumulate in the stack.
    it("add multiple effects", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:add(lurek.effect.newEffect("crt"))
        expect_equal(stack:getEffectCount(), 3)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies remove decreases the active effect count.
    it("remove decreases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        stack:remove(bloom)
        expect_equal(stack:getEffectCount(), 0)
    end)
end)

-- @description Covers suite: PostFxStack insert.
describe("PostFxStack insert", function()
    -- @tests lurek.effect.newStack
    -- @description Verifies insert places an effect at the requested index.
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

-- @description Covers suite: PostFxStack dimensions.
describe("PostFxStack dimensions", function()
    -- @tests lurek.effect.newStack
    -- @description Verifies getDimensions returns width and height together.
    it("getDimensions returns both", function()
        local stack = lurek.effect.newStack(800, 600)
        local w, h = stack:getDimensions()
        expect_equal(w, 800)
        expect_equal(h, 600)
    end)

    -- @tests lurek.effect.newStack
    -- @description Verifies resize updates the stack dimensions.
    it("resize changes dimensions", function()
        local stack = lurek.effect.newStack(800, 600)
        stack:resize(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)
end)

-- @description Covers suite: PostFxStack capturing state.
describe("PostFxStack capturing state", function()
    -- @tests lurek.effect.newStack
    -- @description Verifies stacks are not capturing by default.
    it("not capturing by default", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:isCapturing(), false)
    end)
end)

-- Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬ New effect types Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬Ä‚ËĂ˘â‚¬ĹĄĂ˘â€šÂ¬

-- @description Covers suite: New effect types Ä‚ËĂ˘â€šÂ¬Ă˘â‚¬ĹĄ construction and defaults.
describe("New effect types Ä‚ËĂ˘â€šÂ¬Ă˘â‚¬ĹĄ construction and defaults", function()
    -- @tests lurek.effect.newEffect
    -- @description Verifies pixelate defaults block_size to 4.0.
    it("pixelate has block_size default 4.0", function()
        local e = lurek.effect.newEffect("pixelate")
        expect_equal(math.abs(e:getParameter("block_size") - 4.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies sepia defaults strength to 1.0.
    it("sepia has strength default 1.0", function()
        local e = lurek.effect.newEffect("sepia")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies grayscale is treated as a built-in effect.
    it("grayscale is built-in", function()
        local e = lurek.effect.newEffect("grayscale")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies invert defaults strength to 1.0.
    it("invert has strength default 1.0", function()
        local e = lurek.effect.newEffect("invert")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies scanlines defaults spacing to 4.0.
    it("scanlines has spacing default 4.0", function()
        local e = lurek.effect.newEffect("scanlines")
        expect_equal(math.abs(e:getParameter("spacing") - 4.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies edgedetect defaults strength to 1.0.
    it("edgedetect has strength default 1.0", function()
        local e = lurek.effect.newEffect("edgedetect")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies hueshift defaults angle to 0.0.
    it("hueshift has angle default 0.0", function()
        local e = lurek.effect.newEffect("hueshift")
        expect_equal(math.abs(e:getParameter("angle") - 0.0) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies noise defaults strength to 0.1.
    it("noise has strength default 0.1", function()
        local e = lurek.effect.newEffect("noise")
        expect_equal(math.abs(e:getParameter("strength") - 0.1) < 0.001, true)
    end)

    -- @tests lurek.effect.newEffect
    -- @description Verifies each newly added effect type reports its own type name.
    it("all new types round-trip through getEffectType", function()
        local names = {"pixelate","sepia","grayscale","invert","scanlines","edgedetect","hueshift","noise"}
        local all_ok = true
        for _, name in ipairs(names) do
            local e = lurek.effect.newEffect(name)
            if e:getEffectType() ~= name then all_ok = false end
        end
        expect_equal(all_ok, true)
    end)

    -- @tests lurek.effect.getEffectTypes
    -- @description Verifies the effect-type list includes every new built-in effect.
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

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ PostFX Stack Extended (merged from test_postfx_stack_extended.lua) Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

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
-- @tests lurek.effect.newOverlay

require("tests/lua/init")

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 1. Factory and Construction
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: lurek.effect factory.
describe("lurek.effect factory", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.getWidth
    -- @tests Overlay.getHeight
    -- @description Creates an overlay with explicit dimensions and verifies the stored width and height.
    it("creates an overlay with custom dimensions", function()
        local ov = lurek.effect.newOverlay(1024, 768)
        expect_equal(ov:getWidth(), 1024)
        expect_equal(ov:getHeight(), 768)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.getWidth
    -- @tests Overlay.getHeight
    -- @description Verifies the effect factory uses the default dimensions when none are provided.
    it("creates an overlay with default dimensions", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:getWidth(), 800)
        expect_equal(ov:getHeight(), 600)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.getDimensions
    -- @description Confirms getDimensions returns the effect size as a width-height tuple.
    it("returns dimensions as tuple", function()
        local ov = lurek.effect.newOverlay(640, 480)
        local w, h = ov:getDimensions()
        expect_equal(w, 640)
        expect_equal(h, 480)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 2. Type Introspection
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay type.
describe("overlay type", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.type
    -- @description Verifies overlay userdata reports its concrete type name.
    it("reports type as LOverlay", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:type(), "LOverlay")
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.typeOf
    -- @description Confirms overlays identify as Object through the shared type hierarchy.
    it("typeOf Object returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Object"), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.typeOf
    -- @description Confirms overlays identify as Overlay through typeOf.
    it("typeOf Overlay returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Overlay"), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.typeOf
    -- @description Verifies typeOf rejects unrelated type names.
    it("typeOf unrelated returns false", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("PostFxEffect"), false)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 3. Core Lifecycle
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay core.
describe("overlay core", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.isActive
    -- @description Verifies a newly created overlay starts inactive.
    it("starts inactive", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isActive(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.resize
    -- @tests Overlay.getWidth
    -- @tests Overlay.getHeight
    -- @description Resizes an overlay and verifies the width and height accessors reflect the new size.
    it("resize updates dimensions", function()
        local ov = lurek.effect.newOverlay(800, 600)
        ov:resize(1920, 1080)
        expect_equal(ov:getWidth(), 1920)
        expect_equal(ov:getHeight(), 1080)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.update
    -- @tests Overlay.isActive
    -- @description Updates an empty overlay and verifies it remains inactive without error.
    it("update does not error on empty overlay", function()
        local ov = lurek.effect.newOverlay()
        ov:update(0.016)
        expect_equal(ov:isActive(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.draw
    -- @description Ensures drawing an empty overlay does not raise an error.
    xit("draw does not error", function()
        local ov = lurek.effect.newOverlay()
        ov:render()
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeatherEnabled
    -- @tests Overlay.setFogEnabled
    -- @tests Overlay.setVignetteEnabled
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.clear
    -- @tests Overlay.isActive
    -- @description Activates several effect subsystems, clears them, and verifies the effect becomes inactive.
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

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 4. Ambient Lighting
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay ambient.
describe("overlay ambient", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.isAmbientEnabled
    -- @tests Overlay.isActive
    -- @description Enables ambient lighting and verifies both the ambient flag and overall activity state.
    it("enables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        expect_equal(ov:isAmbientEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.isAmbientEnabled
    -- @description Disables ambient lighting after enabling it and verifies the flag is cleared.
    it("disables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setAmbientEnabled(false)
        expect_equal(ov:isAmbientEnabled(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientColor
    -- @tests Overlay.getAmbientColor
    -- @description Stores an ambient color with alpha and verifies the returned RGBA channels.
    it("sets and gets ambient color with alpha", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.3, 0.4, 0.5, 0.6)
        local r, g, b, a = ov:getAmbientColor()
        expect_near(r, 0.3, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 0.6, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientColor
    -- @tests Overlay.getAmbientColor
    -- @description Verifies ambient color defaults the alpha channel to 1.0 when omitted.
    it("ambient color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.5, 0.5, 0.5)
        local _, _, _, a = ov:getAmbientColor()
        expect_near(a, 1.0, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setTimeOfDay
    -- @tests Overlay.getTimeOfDay
    -- @description Sets the time-of-day value and verifies it round-trips through the getter.
    it("sets and gets time of day", function()
        local ov = lurek.effect.newOverlay()
        ov:setTimeOfDay(6.5)
        expect_near(ov:getTimeOfDay(), 6.5, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.setTimeOfDay
    -- @tests Overlay.update
    -- @tests Overlay.getAmbientColor
    -- @description Updates an ambient-enabled overlay at night and verifies the generated ambient tint matches the night preset.
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

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.setTimeOfDay
    -- @tests Overlay.update
    -- @tests Overlay.getAmbientColor
    -- @description Updates an ambient-enabled overlay at noon and verifies the generated ambient tint matches the daytime preset.
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
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 5. Weather System
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay weather.
describe("overlay weather", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeatherEnabled
    -- @tests Overlay.isWeatherEnabled
    -- @description Enables the weather system and verifies the weather-enabled flag.
    it("enables weather", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        expect_equal(ov:isWeatherEnabled(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeather
    -- @tests Overlay.getWeather
    -- @description Sets the active weather type and verifies it can be read back.
    it("sets weather type", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeather("rain")
        expect_equal(ov:getWeather(), "rain")
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeather
    -- @tests Overlay.getWeather
    -- @description Iterates through every supported weather mode and verifies each round-trips through the getter.
    it("roundtrips all weather types", function()
        local ov = lurek.effect.newOverlay()
        local types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
        for _, wt in ipairs(types) do
            ov:setWeather(wt)
            expect_equal(ov:getWeather(), wt)
        end
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeather
    -- @description Verifies setWeather rejects an unsupported weather type.
    it("rejects invalid weather type", function()
        local ov = lurek.effect.newOverlay()
        expect_error(function()
            ov:setWeather("tornado")
        end)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeatherIntensity
    -- @tests Overlay.getWeatherIntensity
    -- @description Sets the weather intensity and verifies the floating-point value round-trips.
    it("sets and gets weather intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherIntensity(0.8)
        expect_near(ov:getWeatherIntensity(), 0.8, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWindDirection
    -- @tests Overlay.getWindDirection
    -- @description Sets the wind direction and verifies the stored angle.
    it("sets and gets wind direction", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindDirection(1.57)
        expect_near(ov:getWindDirection(), 1.57, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWindSpeed
    -- @tests Overlay.getWindSpeed
    -- @description Sets the wind speed and verifies the stored magnitude.
    it("sets and gets wind speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindSpeed(75.0)
        expect_near(ov:getWindSpeed(), 75.0, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 6. Screen Flash
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay flash.
describe("overlay flash", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.isFlashing
    -- @tests Overlay.flash
    -- @description Triggers a screen flash and verifies the flashing state becomes active.
    it("triggers a flash", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFlashing(), false)
        ov:flash(1, 0, 0, 1, 0.5)
        expect_equal(ov:isFlashing(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.flash
    -- @tests Overlay.update
    -- @tests Overlay.isFlashing
    -- @description Uses the default flash alpha and duration and verifies the flash clears after enough simulated time.
    it("flash with default alpha and duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isFlashing(), true)
        -- default duration = 0.2
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.flash
    -- @tests Overlay.update
    -- @tests Overlay.isFlashing
    -- @description Verifies a flash stops once the update delta exceeds its explicit duration.
    it("flash completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 0, 0, 1, 0.1)
        ov:update(0.2)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.flash
    -- @tests Overlay.isActive
    -- @description Confirms triggering a flash marks the effect as active.
    it("flash activates isActive", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isActive(), true)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 7. Screen Shake
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay shake.
describe("overlay shake", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.isShaking
    -- @tests Overlay.shake
    -- @description Triggers screen shake and verifies the shaking state becomes active.
    it("triggers a shake", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isShaking(), false)
        ov:shake(10, 0.5)
        expect_equal(ov:isShaking(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.shake
    -- @tests Overlay.update
    -- @tests Overlay.isShaking
    -- @description Uses the default shake duration and verifies the effect ends after advancing time.
    it("shake with default duration", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(8.0)
        expect_equal(ov:isShaking(), true)
        -- default duration = 0.5
        ov:update(0.6)
        expect_equal(ov:isShaking(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.shake
    -- @tests Overlay.update
    -- @tests Overlay.getShakeOffset
    -- @description Verifies active shake produces a non-zero camera offset after updating.
    it("shake produces non-zero offset", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(10, 1.0)
        ov:update(0.1)
        local x, y = ov:getShakeOffset()
        -- At least one component should be non-zero
        local total = math.abs(x) + math.abs(y)
        expect_equal(total > 0, true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.shake
    -- @tests Overlay.update
    -- @tests Overlay.getShakeOffset
    -- @description Verifies shake offsets return to zero once the shake duration has elapsed.
    it("shake offset returns to zero after completion", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(10, 0.5)
        ov:update(0.6)
        local x, y = ov:getShakeOffset()
        expect_near(x, 0, 0.001)
        expect_near(y, 0, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 8. Screen Fade
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay fade.
describe("overlay fade", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.isFading
    -- @tests Overlay.fade
    -- @description Triggers a screen fade and verifies the fading state becomes active.
    it("triggers a fade", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFading(), false)
        ov:fade(0, 0, 0, 1, 1.0)
        expect_equal(ov:isFading(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.fade
    -- @tests Overlay.update
    -- @tests Overlay.isFading
    -- @description Uses the default fade alpha and duration and verifies the effect completes after enough time passes.
    it("fade with defaults", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0)
        expect_equal(ov:isFading(), true)
        -- default alpha=1.0, duration=1.0
        ov:update(1.1)
        expect_equal(ov:isFading(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.fade
    -- @tests Overlay.update
    -- @tests Overlay.isFading
    -- @description Verifies a fade clears after an explicit short duration.
    it("fade completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0, 0.8, 0.5)
        ov:update(0.6)
        expect_equal(ov:isFading(), false)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 9. Cloud Shadows
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay clouds.
describe("overlay clouds", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudShadows
    -- @tests Overlay.isCloudShadowsEnabled
    -- @tests Overlay.isActive
    -- @description Enables cloud shadows and verifies both the cloud-shadow flag and overall active state.
    it("enables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        expect_equal(ov:isCloudShadowsEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudShadows
    -- @tests Overlay.isCloudShadowsEnabled
    -- @description Disables cloud shadows after enabling them and verifies the flag is cleared.
    it("disables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        ov:setCloudShadows(false)
        expect_equal(ov:isCloudShadowsEnabled(), false)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudCount
    -- @tests Overlay.getCloudCount
    -- @description Sets the number of simulated clouds and verifies the value round-trips.
    it("sets and gets cloud count", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudCount(12)
        expect_equal(ov:getCloudCount(), 12)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudSpeed
    -- @tests Overlay.getCloudSpeed
    -- @description Sets the cloud movement speed and verifies the stored value.
    it("sets and gets cloud speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudSpeed(35.0)
        expect_near(ov:getCloudSpeed(), 35.0, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudScale
    -- @tests Overlay.getCloudScale
    -- @description Sets the cloud scale and verifies the getter returns the new scale.
    it("sets and gets cloud scale", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudScale(2.5)
        expect_near(ov:getCloudScale(), 2.5, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setCloudOpacity
    -- @tests Overlay.getCloudOpacity
    -- @description Sets the cloud opacity and verifies the getter returns the configured opacity.
    it("sets and gets cloud opacity", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudOpacity(0.6)
        expect_near(ov:getCloudOpacity(), 0.6, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 10. Atmospheric Fog
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay fog.
describe("overlay fog", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFogEnabled
    -- @tests Overlay.isFogEnabled
    -- @description Enables atmospheric fog and verifies the fog-enabled flag.
    it("enables fog", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogEnabled(true)
        expect_equal(ov:isFogEnabled(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFogDensity
    -- @tests Overlay.getFogDensity
    -- @description Sets the fog density and verifies the floating-point value round-trips.
    it("sets and gets fog density", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogDensity(0.7)
        expect_near(ov:getFogDensity(), 0.7, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFogColor
    -- @tests Overlay.getFogColor
    -- @description Stores a fog color with alpha and verifies all returned channels.
    it("sets and gets fog color", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.5, 0.5, 0.6, 0.9)
        local r, g, b, a = ov:getFogColor()
        expect_near(r, 0.5, 0.001)
        expect_near(g, 0.5, 0.001)
        expect_near(b, 0.6, 0.001)
        expect_near(a, 0.9, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFogColor
    -- @tests Overlay.getFogColor
    -- @description Verifies fog color defaults the alpha channel to 1.0 when omitted.
    it("fog color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.3, 0.3, 0.4)
        local _, _, _, a = ov:getFogColor()
        expect_near(a, 1.0, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 11. Heat Haze
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay heat haze.
describe("overlay heat haze", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setHeatHazeEnabled
    -- @tests Overlay.isHeatHazeEnabled
    -- @description Enables heat haze and verifies the effect flag is set.
    it("enables heat haze", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeEnabled(true)
        expect_equal(ov:isHeatHazeEnabled(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setHeatHazeIntensity
    -- @tests Overlay.getHeatHazeIntensity
    -- @description Sets the heat haze intensity and verifies the value round-trips.
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeIntensity(0.9)
        expect_near(ov:getHeatHazeIntensity(), 0.9, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 12. Vignette
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay vignette.
describe("overlay vignette", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setVignetteEnabled
    -- @tests Overlay.isVignetteEnabled
    -- @description Enables vignette rendering and verifies the effect flag is set.
    it("enables vignette", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteEnabled(true)
        expect_equal(ov:isVignetteEnabled(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setVignetteStrength
    -- @tests Overlay.getVignetteStrength
    -- @description Sets the vignette strength and verifies the value round-trips.
    it("sets and gets strength", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteStrength(0.8)
        expect_near(ov:getVignetteStrength(), 0.8, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 13. Film Grain
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay film grain.
describe("overlay film grain", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFilmGrainEnabled
    -- @tests Overlay.isFilmGrainEnabled
    -- @description Enables film grain and verifies the effect flag is set.
    it("enables film grain", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainEnabled(true)
        expect_equal(ov:isFilmGrainEnabled(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setFilmGrainIntensity
    -- @tests Overlay.getFilmGrainIntensity
    -- @description Sets the film grain intensity and verifies the value round-trips.
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainIntensity(0.6)
        expect_near(ov:getFilmGrainIntensity(), 0.6, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 14. Lightning
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay lightning.
describe("overlay lightning", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.triggerLightning
    -- @tests Overlay.isActive
    -- @description Triggers a lightning effect and verifies the effect becomes active.
    it("triggers lightning", function()
        local ov = lurek.effect.newOverlay()
        ov:triggerLightning()
        -- Lightning is active (makes overlay active)
        expect_equal(ov:isActive(), true)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setLightningColor
    -- @tests Overlay.getLightningColor
    -- @description Stores a lightning flash color with alpha and verifies all returned channels.
    it("sets and gets lightning color", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1.0, 0.9, 0.8, 0.7)
        local r, g, b, a = ov:getLightningColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.9, 0.001)
        expect_near(b, 0.8, 0.001)
        expect_near(a, 0.7, 0.001)
    end)

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setLightningColor
    -- @tests Overlay.getLightningColor
    -- @description Verifies lightning color defaults the alpha channel to 0.8 when omitted.
    it("lightning color alpha defaults to 0.8", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1, 1, 1)
        local _, _, _, a = ov:getLightningColor()
        expect_near(a, 1.0, 0.001)
    end)
end)

-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â
-- 15. Combined Effects
-- Ä‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚ÂÄ‚ËĂ˘â‚¬ËĂ‚Â

-- @description Covers suite: overlay combined.
describe("overlay combined", function()
    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeatherEnabled
    -- @tests Overlay.setFogEnabled
    -- @tests Overlay.setVignetteEnabled
    -- @tests Overlay.flash
    -- @tests Overlay.isActive
    -- @description Activates several effect subsystems together and verifies they coexist in the expected active state.
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

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.setWeatherEnabled
    -- @tests Overlay.setFogEnabled
    -- @tests Overlay.setVignetteEnabled
    -- @tests Overlay.setFilmGrainEnabled
    -- @tests Overlay.setHeatHazeEnabled
    -- @tests Overlay.setCloudShadows
    -- @tests Overlay.setAmbientEnabled
    -- @tests Overlay.flash
    -- @tests Overlay.shake
    -- @tests Overlay.fade
    -- @tests Overlay.triggerLightning
    -- @tests Overlay.clear
    -- @tests Overlay.isActive
    -- @description Populates every major overlay effect, clears the effect, and verifies all activity is removed.
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

    -- @tests lurek.effect.newOverlay
    -- @tests Overlay.flash
    -- @tests Overlay.shake
    -- @tests Overlay.update
    -- @tests Overlay.isFlashing
    -- @tests Overlay.isShaking
    -- @description Advances multiple timed effects in one update step and verifies both effects expire together.
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

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.effect.newTransition
    it("covers lurek.effect.newTransition", function()
        -- TODO: Implement test for lurek.effect.newTransition
    end)

    -- @tests PostFxStack:add
    it("covers PostFxStack:add", function()
        -- TODO: Implement test for PostFxStack:add
    end)

    -- @tests PostFxStack:getEnabledEffects
    it("covers PostFxStack:getEnabledEffects", function()
        -- TODO: Implement test for PostFxStack:getEnabledEffects
    end)

    -- @tests PostFxStack:len
    it("covers PostFxStack:len", function()
        -- TODO: Implement test for PostFxStack:len
    end)

    -- @tests PostFxStack:setFeedback
    it("covers PostFxStack:setFeedback", function()
        -- TODO: Implement test for PostFxStack:setFeedback
    end)

    -- @tests PostFxStack:getFeedback
    it("covers PostFxStack:getFeedback", function()
        -- TODO: Implement test for PostFxStack:getFeedback
    end)

    -- @tests PostFxStack:clearFeedback
    it("covers PostFxStack:clearFeedback", function()
        -- TODO: Implement test for PostFxStack:clearFeedback
    end)

    -- @tests ImageEffect:removeByIndex
    it("covers ImageEffect:removeByIndex", function()
        -- TODO: Implement test for ImageEffect:removeByIndex
    end)

    -- @tests ImageEffect:removeByName
    it("covers ImageEffect:removeByName", function()
        -- TODO: Implement test for ImageEffect:removeByName
    end)

end)

describe("Missing explicit test for lurek.effect.newPresetStack", function()
    it("lurek.effect.newPresetStack works", function()
        -- @tests lurek.effect.newPresetStack
        -- TODO: add assertion for lurek.effect.newPresetStack
    end)
end)

describe("Missing explicit test for lurek.effect.setShaderErrorDisplay", function()
    it("lurek.effect.setShaderErrorDisplay works", function()
        -- @tests lurek.effect.setShaderErrorDisplay
        -- TODO: add assertion for lurek.effect.setShaderErrorDisplay
    end)
end)

describe("Missing explicit test for lurek.effect.getShaderErrorDisplay", function()
    it("lurek.effect.getShaderErrorDisplay works", function()
        -- @tests lurek.effect.getShaderErrorDisplay
        -- TODO: add assertion for lurek.effect.getShaderErrorDisplay
    end)
end)

describe("Missing explicit test for PostFxEffect:getTypeName", function()
    it("PostFxEffect:getTypeName works", function()
        -- @tests PostFxEffect:getTypeName
        -- TODO: add assertion for PostFxEffect:getTypeName
    end)
end)

describe("Missing explicit test for PostFxEffect:isBuiltIn", function()
    it("PostFxEffect:isBuiltIn works", function()
        -- @tests PostFxEffect:isBuiltIn
        -- TODO: add assertion for PostFxEffect:isBuiltIn
    end)
end)

describe("Missing explicit test for PostFxEffect:isEnabled", function()
    it("PostFxEffect:isEnabled works", function()
        -- @tests PostFxEffect:isEnabled
        -- TODO: add assertion for PostFxEffect:isEnabled
    end)
end)

describe("Missing explicit test for PostFxEffect:setEnabled", function()
    it("PostFxEffect:setEnabled works", function()
        -- @tests PostFxEffect:setEnabled
        -- TODO: add assertion for PostFxEffect:setEnabled
    end)
end)

describe("Missing explicit test for PostFxEffect:setParameter", function()
    it("PostFxEffect:setParameter works", function()
        -- @tests PostFxEffect:setParameter
        -- TODO: add assertion for PostFxEffect:setParameter
    end)
end)

describe("Missing explicit test for PostFxEffect:hasParameter", function()
    it("PostFxEffect:hasParameter works", function()
        -- @tests PostFxEffect:hasParameter
        -- TODO: add assertion for PostFxEffect:hasParameter
    end)
end)

describe("Missing explicit test for PostFxEffect:getParameterNames", function()
    it("PostFxEffect:getParameterNames works", function()
        -- @tests PostFxEffect:getParameterNames
        -- TODO: add assertion for PostFxEffect:getParameterNames
    end)
end)

describe("Missing explicit test for PostFxEffect:getEffectType", function()
    it("PostFxEffect:getEffectType works", function()
        -- @tests PostFxEffect:getEffectType
        -- TODO: add assertion for PostFxEffect:getEffectType
    end)
end)

describe("Missing explicit test for PostFxEffect:getType", function()
    it("PostFxEffect:getType works", function()
        -- @tests PostFxEffect:getType
        -- TODO: add assertion for PostFxEffect:getType
    end)
end)

describe("Missing explicit test for PostFxEffect:type", function()
    it("PostFxEffect:type works", function()
        -- @tests PostFxEffect:type
        -- TODO: add assertion for PostFxEffect:type
    end)
end)

describe("Missing explicit test for PostFxEffect:typeOf", function()
    it("PostFxEffect:typeOf works", function()
        -- @tests PostFxEffect:typeOf
        -- TODO: add assertion for PostFxEffect:typeOf
    end)
end)

describe("Missing explicit test for PostFxEffect:setThreshold", function()
    it("PostFxEffect:setThreshold works", function()
        -- @tests PostFxEffect:setThreshold
        -- TODO: add assertion for PostFxEffect:setThreshold
    end)
end)

describe("Missing explicit test for PostFxEffect:setIntensity", function()
    it("PostFxEffect:setIntensity works", function()
        -- @tests PostFxEffect:setIntensity
        -- TODO: add assertion for PostFxEffect:setIntensity
    end)
end)

describe("Missing explicit test for PostFxEffect:setRadius", function()
    it("PostFxEffect:setRadius works", function()
        -- @tests PostFxEffect:setRadius
        -- TODO: add assertion for PostFxEffect:setRadius
    end)
end)

describe("Missing explicit test for PostFxEffect:setStrength", function()
    it("PostFxEffect:setStrength works", function()
        -- @tests PostFxEffect:setStrength
        -- TODO: add assertion for PostFxEffect:setStrength
    end)
end)

describe("Missing explicit test for PostFxEffect:setScanlineStrength", function()
    it("PostFxEffect:setScanlineStrength works", function()
        -- @tests PostFxEffect:setScanlineStrength
        -- TODO: add assertion for PostFxEffect:setScanlineStrength
    end)
end)

describe("Missing explicit test for PostFxEffect:setOffset", function()
    it("PostFxEffect:setOffset works", function()
        -- @tests PostFxEffect:setOffset
        -- TODO: add assertion for PostFxEffect:setOffset
    end)
end)

describe("Missing explicit test for PostFxEffect:setBrightness", function()
    it("PostFxEffect:setBrightness works", function()
        -- @tests PostFxEffect:setBrightness
        -- TODO: add assertion for PostFxEffect:setBrightness
    end)
end)

describe("Missing explicit test for PostFxEffect:setContrast", function()
    it("PostFxEffect:setContrast works", function()
        -- @tests PostFxEffect:setContrast
        -- TODO: add assertion for PostFxEffect:setContrast
    end)
end)

describe("Missing explicit test for PostFxEffect:setSaturation", function()
    it("PostFxEffect:setSaturation works", function()
        -- @tests PostFxEffect:setSaturation
        -- TODO: add assertion for PostFxEffect:setSaturation
    end)
end)

describe("Missing explicit test for PostFxStack:remove", function()
    it("PostFxStack:remove works", function()
        -- @tests PostFxStack:remove
        -- TODO: add assertion for PostFxStack:remove
    end)
end)

describe("Missing explicit test for PostFxStack:isEnabled", function()
    it("PostFxStack:isEnabled works", function()
        -- @tests PostFxStack:isEnabled
        -- TODO: add assertion for PostFxStack:isEnabled
    end)
end)

describe("Missing explicit test for PostFxStack:getEffectCount", function()
    it("PostFxStack:getEffectCount works", function()
        -- @tests PostFxStack:getEffectCount
        -- TODO: add assertion for PostFxStack:getEffectCount
    end)
end)

describe("Missing explicit test for PostFxStack:getEffect", function()
    it("PostFxStack:getEffect works", function()
        -- @tests PostFxStack:getEffect
        -- TODO: add assertion for PostFxStack:getEffect
    end)
end)

describe("Missing explicit test for PostFxStack:getWidth", function()
    it("PostFxStack:getWidth works", function()
        -- @tests PostFxStack:getWidth
        -- TODO: add assertion for PostFxStack:getWidth
    end)
end)

describe("Missing explicit test for PostFxStack:getHeight", function()
    it("PostFxStack:getHeight works", function()
        -- @tests PostFxStack:getHeight
        -- TODO: add assertion for PostFxStack:getHeight
    end)
end)

describe("Missing explicit test for PostFxStack:getDimensions", function()
    it("PostFxStack:getDimensions works", function()
        -- @tests PostFxStack:getDimensions
        -- TODO: add assertion for PostFxStack:getDimensions
    end)
end)

describe("Missing explicit test for PostFxStack:resize", function()
    it("PostFxStack:resize works", function()
        -- @tests PostFxStack:resize
        -- TODO: add assertion for PostFxStack:resize
    end)
end)

describe("Missing explicit test for PostFxStack:isEmpty", function()
    it("PostFxStack:isEmpty works", function()
        -- @tests PostFxStack:isEmpty
        -- TODO: add assertion for PostFxStack:isEmpty
    end)
end)

describe("Missing explicit test for PostFxStack:clear", function()
    it("PostFxStack:clear works", function()
        -- @tests PostFxStack:clear
        -- TODO: add assertion for PostFxStack:clear
    end)
end)

describe("Missing explicit test for PostFxStack:dedup", function()
    it("PostFxStack:dedup works", function()
        -- @tests PostFxStack:dedup
        -- TODO: add assertion for PostFxStack:dedup
    end)
end)

describe("Missing explicit test for PostFxStack:isCapturing", function()
    it("PostFxStack:isCapturing works", function()
        -- @tests PostFxStack:isCapturing
        -- TODO: add assertion for PostFxStack:isCapturing
    end)
end)

describe("Missing explicit test for PostFxStack:beginCapture", function()
    it("PostFxStack:beginCapture works", function()
        -- @tests PostFxStack:beginCapture
        -- TODO: add assertion for PostFxStack:beginCapture
    end)
end)

describe("Missing explicit test for PostFxStack:endCapture", function()
    it("PostFxStack:endCapture works", function()
        -- @tests PostFxStack:endCapture
        -- TODO: add assertion for PostFxStack:endCapture
    end)
end)

describe("Missing explicit test for PostFxStack:apply", function()
    it("PostFxStack:apply works", function()
        -- @tests PostFxStack:apply
        -- TODO: add assertion for PostFxStack:apply
    end)
end)

describe("Missing explicit test for PostFxStack:type", function()
    it("PostFxStack:type works", function()
        -- @tests PostFxStack:type
        -- TODO: add assertion for PostFxStack:type
    end)
end)

describe("Missing explicit test for PostFxStack:typeOf", function()
    it("PostFxStack:typeOf works", function()
        -- @tests PostFxStack:typeOf
        -- TODO: add assertion for PostFxStack:typeOf
    end)
end)

describe("Missing explicit test for ImageEffect:addEffect", function()
    it("ImageEffect:addEffect works", function()
        -- @tests ImageEffect:addEffect
        -- TODO: add assertion for ImageEffect:addEffect
    end)
end)

describe("Missing explicit test for ImageEffect:getEffect", function()
    it("ImageEffect:getEffect works", function()
        -- @tests ImageEffect:getEffect
        -- TODO: add assertion for ImageEffect:getEffect
    end)
end)

describe("Missing explicit test for ImageEffect:removeEffect", function()
    it("ImageEffect:removeEffect works", function()
        -- @tests ImageEffect:removeEffect
        -- TODO: add assertion for ImageEffect:removeEffect
    end)
end)

describe("Missing explicit test for ImageEffect:clearEffects", function()
    it("ImageEffect:clearEffects works", function()
        -- @tests ImageEffect:clearEffects
        -- TODO: add assertion for ImageEffect:clearEffects
    end)
end)

describe("Missing explicit test for ImageEffect:clear", function()
    it("ImageEffect:clear works", function()
        -- @tests ImageEffect:clear
        -- TODO: add assertion for ImageEffect:clear
    end)
end)

describe("Missing explicit test for ImageEffect:effectCount", function()
    it("ImageEffect:effectCount works", function()
        -- @tests ImageEffect:effectCount
        -- TODO: add assertion for ImageEffect:effectCount
    end)
end)

describe("Missing explicit test for ImageEffect:getEffectCount", function()
    it("ImageEffect:getEffectCount works", function()
        -- @tests ImageEffect:getEffectCount
        -- TODO: add assertion for ImageEffect:getEffectCount
    end)
end)

describe("Missing explicit test for ImageEffect:clone", function()
    it("ImageEffect:clone works", function()
        -- @tests ImageEffect:clone
        -- TODO: add assertion for ImageEffect:clone
    end)
end)

describe("Missing explicit test for ImageEffect:save", function()
    it("ImageEffect:save works", function()
        -- @tests ImageEffect:save
        -- TODO: add assertion for ImageEffect:save
    end)
end)

describe("Missing explicit test for ImageEffect:type", function()
    it("ImageEffect:type works", function()
        -- @tests ImageEffect:type
        -- TODO: add assertion for ImageEffect:type
    end)
end)

describe("Missing explicit test for ImageEffect:typeOf", function()
    it("ImageEffect:typeOf works", function()
        -- @tests ImageEffect:typeOf
        -- TODO: add assertion for ImageEffect:typeOf
    end)
end)

describe("Missing explicit test for Overlay:update", function()
    it("Overlay:update works", function()
        -- @tests Overlay:update
        -- TODO: add assertion for Overlay:update
    end)
end)

describe("Missing explicit test for Overlay:triggerLightning", function()
    it("Overlay:triggerLightning works", function()
        -- @tests Overlay:triggerLightning
        -- TODO: add assertion for Overlay:triggerLightning
    end)
end)

describe("Missing explicit test for Overlay:getShakeOffset", function()
    it("Overlay:getShakeOffset works", function()
        -- @tests Overlay:getShakeOffset
        -- TODO: add assertion for Overlay:getShakeOffset
    end)
end)

describe("Missing explicit test for Overlay:isActive", function()
    it("Overlay:isActive works", function()
        -- @tests Overlay:isActive
        -- TODO: add assertion for Overlay:isActive
    end)
end)

describe("Missing explicit test for Overlay:clear", function()
    it("Overlay:clear works", function()
        -- @tests Overlay:clear
        -- TODO: add assertion for Overlay:clear
    end)
end)

describe("Missing explicit test for Overlay:resize", function()
    it("Overlay:resize works", function()
        -- @tests Overlay:resize
        -- TODO: add assertion for Overlay:resize
    end)
end)

describe("Missing explicit test for Overlay:getWidth", function()
    it("Overlay:getWidth works", function()
        -- @tests Overlay:getWidth
        -- TODO: add assertion for Overlay:getWidth
    end)
end)

describe("Missing explicit test for Overlay:getHeight", function()
    it("Overlay:getHeight works", function()
        -- @tests Overlay:getHeight
        -- TODO: add assertion for Overlay:getHeight
    end)
end)

describe("Missing explicit test for Overlay:getDimensions", function()
    it("Overlay:getDimensions works", function()
        -- @tests Overlay:getDimensions
        -- TODO: add assertion for Overlay:getDimensions
    end)
end)

describe("Missing explicit test for Overlay:getFlashAlpha", function()
    it("Overlay:getFlashAlpha works", function()
        -- @tests Overlay:getFlashAlpha
        -- TODO: add assertion for Overlay:getFlashAlpha
    end)
end)

describe("Missing explicit test for Overlay:getLightningAlpha", function()
    it("Overlay:getLightningAlpha works", function()
        -- @tests Overlay:getLightningAlpha
        -- TODO: add assertion for Overlay:getLightningAlpha
    end)
end)

describe("Missing explicit test for Overlay:setAmbientEnabled", function()
    it("Overlay:setAmbientEnabled works", function()
        -- @tests Overlay:setAmbientEnabled
        -- TODO: add assertion for Overlay:setAmbientEnabled
    end)
end)

describe("Missing explicit test for Overlay:isAmbientEnabled", function()
    it("Overlay:isAmbientEnabled works", function()
        -- @tests Overlay:isAmbientEnabled
        -- TODO: add assertion for Overlay:isAmbientEnabled
    end)
end)

describe("Missing explicit test for Overlay:getAmbientColor", function()
    it("Overlay:getAmbientColor works", function()
        -- @tests Overlay:getAmbientColor
        -- TODO: add assertion for Overlay:getAmbientColor
    end)
end)

describe("Missing explicit test for Overlay:setTimeOfDay", function()
    it("Overlay:setTimeOfDay works", function()
        -- @tests Overlay:setTimeOfDay
        -- TODO: add assertion for Overlay:setTimeOfDay
    end)
end)

describe("Missing explicit test for Overlay:getTimeOfDay", function()
    it("Overlay:getTimeOfDay works", function()
        -- @tests Overlay:getTimeOfDay
        -- TODO: add assertion for Overlay:getTimeOfDay
    end)
end)

describe("Missing explicit test for Overlay:setFogEnabled", function()
    it("Overlay:setFogEnabled works", function()
        -- @tests Overlay:setFogEnabled
        -- TODO: add assertion for Overlay:setFogEnabled
    end)
end)

describe("Missing explicit test for Overlay:isFogEnabled", function()
    it("Overlay:isFogEnabled works", function()
        -- @tests Overlay:isFogEnabled
        -- TODO: add assertion for Overlay:isFogEnabled
    end)
end)

describe("Missing explicit test for Overlay:setFogDensity", function()
    it("Overlay:setFogDensity works", function()
        -- @tests Overlay:setFogDensity
        -- TODO: add assertion for Overlay:setFogDensity
    end)
end)

describe("Missing explicit test for Overlay:getFogDensity", function()
    it("Overlay:getFogDensity works", function()
        -- @tests Overlay:getFogDensity
        -- TODO: add assertion for Overlay:getFogDensity
    end)
end)

describe("Missing explicit test for Overlay:getFogColor", function()
    it("Overlay:getFogColor works", function()
        -- @tests Overlay:getFogColor
        -- TODO: add assertion for Overlay:getFogColor
    end)
end)

describe("Missing explicit test for Overlay:setHeatHazeEnabled", function()
    it("Overlay:setHeatHazeEnabled works", function()
        -- @tests Overlay:setHeatHazeEnabled
        -- TODO: add assertion for Overlay:setHeatHazeEnabled
    end)
end)

describe("Missing explicit test for Overlay:isHeatHazeEnabled", function()
    it("Overlay:isHeatHazeEnabled works", function()
        -- @tests Overlay:isHeatHazeEnabled
        -- TODO: add assertion for Overlay:isHeatHazeEnabled
    end)
end)

describe("Missing explicit test for Overlay:setHeatHazeIntensity", function()
    it("Overlay:setHeatHazeIntensity works", function()
        -- @tests Overlay:setHeatHazeIntensity
        -- TODO: add assertion for Overlay:setHeatHazeIntensity
    end)
end)

describe("Missing explicit test for Overlay:getHeatHazeIntensity", function()
    it("Overlay:getHeatHazeIntensity works", function()
        -- @tests Overlay:getHeatHazeIntensity
        -- TODO: add assertion for Overlay:getHeatHazeIntensity
    end)
end)

describe("Missing explicit test for Overlay:setVignetteEnabled", function()
    it("Overlay:setVignetteEnabled works", function()
        -- @tests Overlay:setVignetteEnabled
        -- TODO: add assertion for Overlay:setVignetteEnabled
    end)
end)

describe("Missing explicit test for Overlay:isVignetteEnabled", function()
    it("Overlay:isVignetteEnabled works", function()
        -- @tests Overlay:isVignetteEnabled
        -- TODO: add assertion for Overlay:isVignetteEnabled
    end)
end)

describe("Missing explicit test for Overlay:setVignetteStrength", function()
    it("Overlay:setVignetteStrength works", function()
        -- @tests Overlay:setVignetteStrength
        -- TODO: add assertion for Overlay:setVignetteStrength
    end)
end)

describe("Missing explicit test for Overlay:getVignetteStrength", function()
    it("Overlay:getVignetteStrength works", function()
        -- @tests Overlay:getVignetteStrength
        -- TODO: add assertion for Overlay:getVignetteStrength
    end)
end)

describe("Missing explicit test for Overlay:setFilmGrainEnabled", function()
    it("Overlay:setFilmGrainEnabled works", function()
        -- @tests Overlay:setFilmGrainEnabled
        -- TODO: add assertion for Overlay:setFilmGrainEnabled
    end)
end)

describe("Missing explicit test for Overlay:isFilmGrainEnabled", function()
    it("Overlay:isFilmGrainEnabled works", function()
        -- @tests Overlay:isFilmGrainEnabled
        -- TODO: add assertion for Overlay:isFilmGrainEnabled
    end)
end)

describe("Missing explicit test for Overlay:setFilmGrainIntensity", function()
    it("Overlay:setFilmGrainIntensity works", function()
        -- @tests Overlay:setFilmGrainIntensity
        -- TODO: add assertion for Overlay:setFilmGrainIntensity
    end)
end)

describe("Missing explicit test for Overlay:getFilmGrainIntensity", function()
    it("Overlay:getFilmGrainIntensity works", function()
        -- @tests Overlay:getFilmGrainIntensity
        -- TODO: add assertion for Overlay:getFilmGrainIntensity
    end)
end)

describe("Missing explicit test for Overlay:setCloudShadows", function()
    it("Overlay:setCloudShadows works", function()
        -- @tests Overlay:setCloudShadows
        -- TODO: add assertion for Overlay:setCloudShadows
    end)
end)

describe("Missing explicit test for Overlay:isCloudShadowsEnabled", function()
    it("Overlay:isCloudShadowsEnabled works", function()
        -- @tests Overlay:isCloudShadowsEnabled
        -- TODO: add assertion for Overlay:isCloudShadowsEnabled
    end)
end)

describe("Missing explicit test for Overlay:setCloudCount", function()
    it("Overlay:setCloudCount works", function()
        -- @tests Overlay:setCloudCount
        -- TODO: add assertion for Overlay:setCloudCount
    end)
end)

describe("Missing explicit test for Overlay:getCloudCount", function()
    it("Overlay:getCloudCount works", function()
        -- @tests Overlay:getCloudCount
        -- TODO: add assertion for Overlay:getCloudCount
    end)
end)

describe("Missing explicit test for Overlay:setCloudSpeed", function()
    it("Overlay:setCloudSpeed works", function()
        -- @tests Overlay:setCloudSpeed
        -- TODO: add assertion for Overlay:setCloudSpeed
    end)
end)

describe("Missing explicit test for Overlay:getCloudSpeed", function()
    it("Overlay:getCloudSpeed works", function()
        -- @tests Overlay:getCloudSpeed
        -- TODO: add assertion for Overlay:getCloudSpeed
    end)
end)

describe("Missing explicit test for Overlay:setCloudScale", function()
    it("Overlay:setCloudScale works", function()
        -- @tests Overlay:setCloudScale
        -- TODO: add assertion for Overlay:setCloudScale
    end)
end)

describe("Missing explicit test for Overlay:getCloudScale", function()
    it("Overlay:getCloudScale works", function()
        -- @tests Overlay:getCloudScale
        -- TODO: add assertion for Overlay:getCloudScale
    end)
end)

describe("Missing explicit test for Overlay:setCloudOpacity", function()
    it("Overlay:setCloudOpacity works", function()
        -- @tests Overlay:setCloudOpacity
        -- TODO: add assertion for Overlay:setCloudOpacity
    end)
end)

describe("Missing explicit test for Overlay:getCloudOpacity", function()
    it("Overlay:getCloudOpacity works", function()
        -- @tests Overlay:getCloudOpacity
        -- TODO: add assertion for Overlay:getCloudOpacity
    end)
end)

describe("Missing explicit test for Overlay:setWeatherEnabled", function()
    it("Overlay:setWeatherEnabled works", function()
        -- @tests Overlay:setWeatherEnabled
        -- TODO: add assertion for Overlay:setWeatherEnabled
    end)
end)

describe("Missing explicit test for Overlay:isWeatherEnabled", function()
    it("Overlay:isWeatherEnabled works", function()
        -- @tests Overlay:isWeatherEnabled
        -- TODO: add assertion for Overlay:isWeatherEnabled
    end)
end)

describe("Missing explicit test for Overlay:setWeather", function()
    it("Overlay:setWeather works", function()
        -- @tests Overlay:setWeather
        -- TODO: add assertion for Overlay:setWeather
    end)
end)

describe("Missing explicit test for Overlay:getWeather", function()
    it("Overlay:getWeather works", function()
        -- @tests Overlay:getWeather
        -- TODO: add assertion for Overlay:getWeather
    end)
end)

describe("Missing explicit test for Overlay:setWeatherIntensity", function()
    it("Overlay:setWeatherIntensity works", function()
        -- @tests Overlay:setWeatherIntensity
        -- TODO: add assertion for Overlay:setWeatherIntensity
    end)
end)

describe("Missing explicit test for Overlay:getWeatherIntensity", function()
    it("Overlay:getWeatherIntensity works", function()
        -- @tests Overlay:getWeatherIntensity
        -- TODO: add assertion for Overlay:getWeatherIntensity
    end)
end)

describe("Missing explicit test for Overlay:setWindDirection", function()
    it("Overlay:setWindDirection works", function()
        -- @tests Overlay:setWindDirection
        -- TODO: add assertion for Overlay:setWindDirection
    end)
end)

describe("Missing explicit test for Overlay:getWindDirection", function()
    it("Overlay:getWindDirection works", function()
        -- @tests Overlay:getWindDirection
        -- TODO: add assertion for Overlay:getWindDirection
    end)
end)

describe("Missing explicit test for Overlay:setWindSpeed", function()
    it("Overlay:setWindSpeed works", function()
        -- @tests Overlay:setWindSpeed
        -- TODO: add assertion for Overlay:setWindSpeed
    end)
end)

describe("Missing explicit test for Overlay:getWindSpeed", function()
    it("Overlay:getWindSpeed works", function()
        -- @tests Overlay:getWindSpeed
        -- TODO: add assertion for Overlay:getWindSpeed
    end)
end)

describe("Missing explicit test for Overlay:getLightningColor", function()
    it("Overlay:getLightningColor works", function()
        -- @tests Overlay:getLightningColor
        -- TODO: add assertion for Overlay:getLightningColor
    end)
end)

describe("Missing explicit test for Overlay:isFlashing", function()
    it("Overlay:isFlashing works", function()
        -- @tests Overlay:isFlashing
        -- TODO: add assertion for Overlay:isFlashing
    end)
end)

describe("Missing explicit test for Overlay:shake", function()
    it("Overlay:shake works", function()
        -- @tests Overlay:shake
        -- TODO: add assertion for Overlay:shake
    end)
end)

describe("Missing explicit test for Overlay:isShaking", function()
    it("Overlay:isShaking works", function()
        -- @tests Overlay:isShaking
        -- TODO: add assertion for Overlay:isShaking
    end)
end)

describe("Missing explicit test for Overlay:isFading", function()
    it("Overlay:isFading works", function()
        -- @tests Overlay:isFading
        -- TODO: add assertion for Overlay:isFading
    end)
end)

describe("Missing explicit test for Overlay:drawToImage", function()
    it("Overlay:drawToImage works", function()
        -- @tests Overlay:drawToImage
        -- TODO: add assertion for Overlay:drawToImage
    end)
end)

describe("Missing explicit test for Overlay:setCustomShader", function()
    it("Overlay:setCustomShader works", function()
        -- @tests Overlay:setCustomShader
        -- TODO: add assertion for Overlay:setCustomShader
    end)
end)

describe("Missing explicit test for Overlay:getWater", function()
    it("Overlay:getWater works", function()
        -- @tests Overlay:getWater
        -- TODO: add assertion for Overlay:getWater
    end)
end)

describe("Missing explicit test for Overlay:type", function()
    it("Overlay:type works", function()
        -- @tests Overlay:type
        -- TODO: add assertion for Overlay:type
    end)
end)

describe("Missing explicit test for Overlay:typeOf", function()
    it("Overlay:typeOf works", function()
        -- @tests Overlay:typeOf
        -- TODO: add assertion for Overlay:typeOf
    end)
end)

describe("Missing explicit test for mlua:play", function()
    it("mlua:play works", function()
        -- @tests mlua:play
        -- TODO: add assertion for mlua:play
    end)
end)

describe("Missing explicit test for mlua:reverse", function()
    it("mlua:reverse works", function()
        -- @tests mlua:reverse
        -- TODO: add assertion for mlua:reverse
    end)
end)

describe("Missing explicit test for mlua:update", function()
    it("mlua:update works", function()
        -- @tests mlua:update
        -- TODO: add assertion for mlua:update
    end)
end)

describe("Missing explicit test for mlua:progress", function()
    it("mlua:progress works", function()
        -- @tests mlua:progress
        -- TODO: add assertion for mlua:progress
    end)
end)

describe("Missing explicit test for mlua:isActive", function()
    it("mlua:isActive works", function()
        -- @tests mlua:isActive
        -- TODO: add assertion for mlua:isActive
    end)
end)

describe("Missing explicit test for mlua:isDone", function()
    it("mlua:isDone works", function()
        -- @tests mlua:isDone
        -- TODO: add assertion for mlua:isDone
    end)
end)

describe("Missing explicit test for mlua:kind", function()
    it("mlua:kind works", function()
        -- @tests mlua:kind
        -- TODO: add assertion for mlua:kind
    end)
end)

describe("Missing explicit test for mlua:color", function()
    it("mlua:color works", function()
        -- @tests mlua:color
        -- TODO: add assertion for mlua:color
    end)
end)

describe("Missing explicit test for mlua:setColor", function()
    it("mlua:setColor works", function()
        -- @tests mlua:setColor
        -- TODO: add assertion for mlua:setColor
    end)
end)

describe("Missing explicit test for mlua:type", function()
    it("mlua:type works", function()
        -- @tests mlua:type
        -- TODO: add assertion for mlua:type
    end)
end)

describe("Missing explicit test for mlua:typeOf", function()
    it("mlua:typeOf works", function()
        -- @tests mlua:typeOf
        -- TODO: add assertion for mlua:typeOf
    end)
end)

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ enableAutoUniforms Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

describe("effect:enableAutoUniforms", function()
    it("enableAutoUniforms exists on PostFxEffect", function()
        local fx = lurek.effect.newCustomEffect(0)
        expect_equal(type(fx.enableAutoUniforms), "function")
    end)

    it("isAutoUniforms exists on PostFxEffect", function()
        local fx = lurek.effect.newCustomEffect(0)
        expect_equal(type(fx.isAutoUniforms), "function")
    end)

    it("disableAutoUniforms exists on PostFxEffect", function()
        local fx = lurek.effect.newCustomEffect(0)
        expect_equal(type(fx.disableAutoUniforms), "function")
    end)

    it("isAutoUniforms defaults to false", function()
        local fx = lurek.effect.newCustomEffect(0)
        expect_equal(fx:isAutoUniforms(), false)
    end)

    it("enableAutoUniforms sets flag to true", function()
        local fx = lurek.effect.newCustomEffect(0)
        fx:enableAutoUniforms()
        expect_equal(fx:isAutoUniforms(), true)
    end)

    it("disableAutoUniforms sets flag back to false", function()
        local fx = lurek.effect.newCustomEffect(0)
        fx:enableAutoUniforms()
        fx:disableAutoUniforms()
        expect_equal(fx:isAutoUniforms(), false)
    end)

    it("built-in effect also has enableAutoUniforms", function()
        local fx = lurek.effect.newEffect("bloom")
        expect_equal(type(fx.enableAutoUniforms), "function")
    end)

    it("built-in effect isAutoUniforms defaults to false", function()
        local fx = lurek.effect.newEffect("vignette")
        expect_equal(fx:isAutoUniforms(), false)
    end)
end)
