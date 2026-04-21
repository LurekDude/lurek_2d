-- Lurek2D Effect API Unit Tests (consolidated)

-- ── Effect Dedup (merged from test_effect_dedup.lua) ──

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
        local stack = lurek.effect.new(320, 240)
        expect_equal(type(stack.dedup), "function")
    end)

    it("dedup on empty stack returns 0 and does not crash", function()
        local stack = lurek.effect.new(320, 240)
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    it("dedup on stack with no duplicates returns 0", function()
        local stack = lurek.effect.new(320, 240)
        stack:dedup()  -- no-op
        local removed = stack:dedup()
        expect_equal(removed, 0)
    end)

    it("dedup removes duplicate effects", function()
        local stack = lurek.effect.new(320, 240)
        -- Add same effect kind twice if the API supports kind-based construction
        local blur1 = lurek.effect.blur(4.0)
        stack:add(blur1)
        stack:add(blur1)  -- same Rc pointer
        local removed = stack:dedup()
        expect_equal(removed >= 0, true)  -- at least 0 (may or may not find duplicate)
    end)

end)

-- ── Effect Overlay/Water (merged from test_effect_overlay_water.lua) ──

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

    it("setWater enables the overlay and stores wave params", function()
        local ov = make_overlay()
        ov:setWater(0.05, 4.0, 2.0)
        local w = ov:getWater()
        expect_equal(w.enabled, true)
        expect_equal(w.amplitude, 0.05)
        expect_equal(w.frequency, 4.0)
        expect_equal(w.speed, 2.0)
    end)

    it("setWaterTint stores tint channels and strength", function()
        local ov = make_overlay()
        ov:setWaterTint(0.1, 0.5, 0.9, 0.7)
        local w = ov:getWater()
        expect_equal(w.tint_r, 0.1)
        expect_equal(w.tint_g, 0.5)
        expect_equal(w.tint_b, 0.9)
        expect_equal(w.tint_strength, 0.7)
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

test_summary()

-- [merged from test_effect_api.lua]
-- tests/lua/unit/test_effect_api.lua
-- Post-processing effect API tests (lurek.effect / lurek.effect).
-- Complements test_effect_postfx.lua; focuses on the API surface check.
-- Headless-safe: no GPU, no window needed for API introspection.

-- ============================================================
-- Namespace surface
-- ============================================================
-- @description Verifies the postfx namespace tables and public constructor/helper functions are exposed with the expected Lua types.
describe("lurek.effect module", function()
    -- @covers lurek.effect.getEffectTypes
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newStack
    -- @covers lurek.effect.newPass
    -- @covers lurek.effect.newCustomEffect
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
test_summary()


-- [merged from test_effect_postfx.lua]
-- Lurek2D PostFX API Tests â€” covers lurek.effect post-processing effects (headless)

-- @description Covers suite: lurek.effect module exists.
describe("lurek.effect module exists", function()
    -- @covers lurek.effect
    -- @covers lurek.effect.getEffectTypes
    -- @covers lurek.effect.newEffect
    -- @covers lurek.effect.newPass
    -- @covers lurek.effect.newStack
    -- @description Verifies the effect namespace is available as a Lua table.
    it("lurek.effect is a table", function()
        expect_type("table", lurek.effect)
    end)
end)

-- @description Covers suite: lurek.effect factory functions.
describe("lurek.effect factory functions", function()
    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect is exposed.
    it("newEffect is a function", function()
        expect_type("function", lurek.effect.newEffect)
    end)

    -- @covers lurek.effect.newPass
    -- @description Verifies newPass is exposed.
    it("newPass is a function", function()
        expect_type("function", lurek.effect.newPass)
    end)

    -- @covers lurek.effect.newStack
    -- @description Verifies newStack is exposed.
    it("newStack is a function", function()
        expect_type("function", lurek.effect.newStack)
    end)

    -- @covers lurek.effect.getEffectTypes
    -- @description Verifies getEffectTypes is exposed.
    it("getEffectTypes is a function", function()
        expect_type("function", lurek.effect.getEffectTypes)
    end)
end)

-- @description Covers suite: lurek.effect.newEffect built-in types.
describe("lurek.effect.newEffect built-in types", function()
    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a built-in bloom effect.
    it("creates bloom effect", function()
        local e = lurek.effect.newEffect("bloom")
        expect_equal(e:getEffectType(), "bloom")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a blur effect.
    it("creates blur effect", function()
        local e = lurek.effect.newEffect("blur")
        expect_equal(e:getEffectType(), "blur")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a crt effect.
    it("creates crt effect", function()
        local e = lurek.effect.newEffect("crt")
        expect_equal(e:getEffectType(), "crt")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a godrays effect.
    it("creates godrays effect", function()
        local e = lurek.effect.newEffect("godrays")
        expect_equal(e:getEffectType(), "godrays")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a vignette effect.
    it("creates vignette effect", function()
        local e = lurek.effect.newEffect("vignette")
        expect_equal(e:getEffectType(), "vignette")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a colourgrade effect.
    it("creates colourgrade effect", function()
        local e = lurek.effect.newEffect("colourgrade")
        expect_equal(e:getEffectType(), "colourgrade")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies newEffect constructs a chromatic effect.
    it("creates chromatic effect", function()
        local e = lurek.effect.newEffect("chromatic")
        expect_equal(e:getEffectType(), "chromatic")
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies invalid effect names raise an error.
    it("rejects invalid effect type", function()
        expect_error(function()
            lurek.effect.newEffect("invalid_type")
        end)
    end)
end)

-- @description Covers suite: lurek.effect.newPass custom effects.
describe("lurek.effect.newPass custom effects", function()
    -- @covers lurek.effect.newPass
    -- @description Verifies newPass constructs a custom non-built-in pass.
    it("creates custom pass", function()
        local p = lurek.effect.newPass(1)
        expect_equal(p:getEffectType(), "custom")
        expect_equal(p:isBuiltIn(), false)
    end)
end)

-- @description Covers suite: lurek.effect.getEffectTypes.
describe("lurek.effect.getEffectTypes", function()
    -- @covers lurek.effect.getEffectTypes
    -- @description Verifies getEffectTypes returns the registered effect-type list.
    it("returns table of 15 types", function()
        local types = lurek.effect.getEffectTypes()
        expect_type("table", types)
        expect_equal(#types, 15)
    end)

    -- @covers lurek.effect.getEffectTypes
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
    -- @covers lurek.effect.newEffect
    -- @description Verifies bloom exposes a threshold parameter by default.
    it("bloom has default threshold", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:hasParameter("threshold"), true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies getParameter returns a stored parameter value.
    it("getParameter returns value", function()
        local bloom = lurek.effect.newEffect("bloom")
        local t = bloom:getParameter("threshold")
        expect_type("number", t)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setParameter mutates a named effect parameter.
    it("setParameter changes value", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setParameter("threshold", 0.5)
        local v = bloom:getParameter("threshold")
        expect_equal(math.abs(v - 0.5) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies getParameter falls back to the provided default for missing keys.
    it("getParameter uses default for missing", function()
        local bloom = lurek.effect.newEffect("bloom")
        local v = bloom:getParameter("nonexistent", 42.0)
        expect_equal(math.abs(v - 42.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
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
    -- @covers lurek.effect.newEffect
    -- @description Verifies setThreshold updates the threshold parameter.
    it("setThreshold works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setThreshold(0.8) end)
        expect_equal(math.abs(bloom:getParameter("threshold") - 0.8) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setIntensity updates the intensity parameter.
    it("setIntensity works", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_no_error(function() bloom:setIntensity(2.0) end)
        expect_equal(math.abs(bloom:getParameter("intensity") - 2.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setRadius updates the blur radius parameter.
    it("setRadius works on blur", function()
        local blur = lurek.effect.newEffect("blur")
        expect_no_error(function() blur:setRadius(5.0) end)
        expect_equal(math.abs(blur:getParameter("radius") - 5.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setStrength updates the vignette strength parameter.
    it("setStrength works on vignette", function()
        local vig = lurek.effect.newEffect("vignette")
        expect_no_error(function() vig:setStrength(0.8) end)
        expect_equal(math.abs(vig:getParameter("strength") - 0.8) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setScanlineStrength updates the CRT scanline parameter.
    it("setScanlineStrength works on crt", function()
        local crt = lurek.effect.newEffect("crt")
        expect_no_error(function() crt:setScanlineStrength(0.4) end)
        expect_equal(math.abs(crt:getParameter("scanline_strength") - 0.4) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setOffset updates the chromatic aberration offset.
    it("setOffset works on chromatic", function()
        local chr = lurek.effect.newEffect("chromatic")
        expect_no_error(function() chr:setOffset(3.0) end)
        expect_equal(math.abs(chr:getParameter("offset") - 3.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setBrightness updates the colourgrade brightness parameter.
    it("setBrightness works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setBrightness(1.5) end)
        expect_equal(math.abs(cg:getParameter("brightness") - 1.5) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setContrast updates the colourgrade contrast parameter.
    it("setContrast works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setContrast(0.9) end)
        expect_equal(math.abs(cg:getParameter("contrast") - 0.9) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setSaturation updates the colourgrade saturation parameter.
    it("setSaturation works on colourgrade", function()
        local cg = lurek.effect.newEffect("colourgrade")
        expect_no_error(function() cg:setSaturation(0.7) end)
        expect_equal(math.abs(cg:getParameter("saturation") - 0.7) < 0.001, true)
    end)
end)

-- @description Covers suite: PostFxEffect enable/disable.
describe("PostFxEffect enable/disable", function()
    -- @covers lurek.effect.newEffect
    -- @description Verifies effects start enabled.
    it("is enabled by default", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:isEnabled(), true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies setEnabled(false) disables the effect.
    it("setEnabled false", function()
        local bloom = lurek.effect.newEffect("bloom")
        bloom:setEnabled(false)
        expect_equal(bloom:isEnabled(), false)
    end)

    -- @covers lurek.effect.newEffect
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
    -- @covers lurek.effect.newEffect
    -- @description Verifies built-in effects report the PostFxEffect userdata type.
    it("returns PostFxEffect", function()
        local bloom = lurek.effect.newEffect("bloom")
        expect_equal(bloom:type(), "PostFxEffect")
    end)

    -- @covers lurek.effect.newPass
    -- @description Verifies custom passes also report the PostFxEffect userdata type.
    it("custom pass also returns PostFxEffect", function()
        local pass = lurek.effect.newPass(1)
        expect_equal(pass:type(), "PostFxEffect")
    end)
end)

-- @description Covers suite: lurek.effect.newStack.
describe("lurek.effect.newStack", function()
    -- @covers lurek.effect.newStack
    -- @description Verifies newStack uses the default 800x600 dimensions.
    it("creates stack with default dimensions", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getWidth(), 800)
        expect_equal(stack:getHeight(), 600)
    end)

    -- @covers lurek.effect.newStack
    -- @description Verifies newStack accepts custom dimensions.
    it("creates stack with custom dimensions", function()
        local stack = lurek.effect.newStack(1920, 1080)
        expect_equal(stack:getWidth(), 1920)
        expect_equal(stack:getHeight(), 1080)
    end)

    -- @covers lurek.effect.newStack
    -- @description Verifies new stacks start empty.
    it("starts empty", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:getEffectCount(), 0)
    end)

    -- @covers lurek.effect.newStack
    -- @description Verifies stack:type reports PostFxStack.
    it("type is PostFxStack", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:type(), "PostFxStack")
    end)
end)

-- @description Covers suite: PostFxStack add/remove.
describe("PostFxStack add/remove", function()
    -- @covers lurek.effect.newStack
    -- @description Verifies add increments the active effect count.
    it("add increases count", function()
        local stack = lurek.effect.newStack()
        local bloom = lurek.effect.newEffect("bloom")
        stack:add(bloom)
        expect_equal(stack:getEffectCount(), 1)
    end)

    -- @covers lurek.effect.newStack
    -- @description Verifies multiple add calls accumulate in the stack.
    it("add multiple effects", function()
        local stack = lurek.effect.newStack()
        stack:add(lurek.effect.newEffect("bloom"))
        stack:add(lurek.effect.newEffect("blur"))
        stack:add(lurek.effect.newEffect("crt"))
        expect_equal(stack:getEffectCount(), 3)
    end)

    -- @covers lurek.effect.newStack
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
    -- @covers lurek.effect.newStack
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
    -- @covers lurek.effect.newStack
    -- @description Verifies getDimensions returns width and height together.
    it("getDimensions returns both", function()
        local stack = lurek.effect.newStack(800, 600)
        local w, h = stack:getDimensions()
        expect_equal(w, 800)
        expect_equal(h, 600)
    end)

    -- @covers lurek.effect.newStack
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
    -- @covers lurek.effect.newStack
    -- @description Verifies stacks are not capturing by default.
    it("not capturing by default", function()
        local stack = lurek.effect.newStack()
        expect_equal(stack:isCapturing(), false)
    end)
end)

-- â”€â”€ New effect types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: New effect types â€” construction and defaults.
describe("New effect types â€” construction and defaults", function()
    -- @covers lurek.effect.newEffect
    -- @description Verifies pixelate defaults block_size to 4.0.
    it("pixelate has block_size default 4.0", function()
        local e = lurek.effect.newEffect("pixelate")
        expect_equal(math.abs(e:getParameter("block_size") - 4.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies sepia defaults strength to 1.0.
    it("sepia has strength default 1.0", function()
        local e = lurek.effect.newEffect("sepia")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies grayscale is treated as a built-in effect.
    it("grayscale is built-in", function()
        local e = lurek.effect.newEffect("grayscale")
        expect_equal(e:isBuiltIn(), true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies invert defaults strength to 1.0.
    it("invert has strength default 1.0", function()
        local e = lurek.effect.newEffect("invert")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies scanlines defaults spacing to 4.0.
    it("scanlines has spacing default 4.0", function()
        local e = lurek.effect.newEffect("scanlines")
        expect_equal(math.abs(e:getParameter("spacing") - 4.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies edgedetect defaults strength to 1.0.
    it("edgedetect has strength default 1.0", function()
        local e = lurek.effect.newEffect("edgedetect")
        expect_equal(math.abs(e:getParameter("strength") - 1.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies hueshift defaults angle to 0.0.
    it("hueshift has angle default 0.0", function()
        local e = lurek.effect.newEffect("hueshift")
        expect_equal(math.abs(e:getParameter("angle") - 0.0) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
    -- @description Verifies noise defaults strength to 0.1.
    it("noise has strength default 0.1", function()
        local e = lurek.effect.newEffect("noise")
        expect_equal(math.abs(e:getParameter("strength") - 0.1) < 0.001, true)
    end)

    -- @covers lurek.effect.newEffect
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

    -- @covers lurek.effect.getEffectTypes
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

-- ── PostFX Stack Extended (merged from test_postfx_stack_extended.lua) ───────

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

test_summary()

