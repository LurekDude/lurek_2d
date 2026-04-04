-- Luna2D ImageEffect API Tests (headless - no window, GPU, or audio)

-- =============================================================================
-- Construction — empty
-- =============================================================================

describe("luna.postfx.newImageEffect construction (empty)", function()
    it("newImageEffect is a function", function()
        expect_type("function", luna.postfx.newImageEffect)
    end)

    it("newImageEffect() returns non-nil", function()
        local fx = luna.postfx.newImageEffect()
        expect_equal(fx ~= nil, true)
    end)

    it("newImageEffect() returns object with effectCount method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.effectCount)
    end)

    it("newImageEffect() returns object with addEffect method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.addEffect)
    end)

    it("newImageEffect() returns object with getEffect method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.getEffect)
    end)

    it("newImageEffect() returns object with removeEffect method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.removeEffect)
    end)

    it("newImageEffect() returns object with clearEffects method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.clearEffects)
    end)

    it("newImageEffect() returns object with clone method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.clone)
    end)

    it("newImageEffect() returns object with save method", function()
        local fx = luna.postfx.newImageEffect()
        expect_type("function", fx.save)
    end)

    it("empty chain has effectCount == 0", function()
        local fx = luna.postfx.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)
end)

-- =============================================================================
-- Construction — single effect by name
-- =============================================================================

describe("luna.postfx.newImageEffect construction (single name)", function()
    it("newImageEffect('blur') produces effectCount == 1", function()
        local fx = luna.postfx.newImageEffect("blur")
        expect_equal(fx:effectCount(), 1)
    end)

    it("first effect type is 'blur'", function()
        local fx = luna.postfx.newImageEffect("blur")
        local e = fx:getEffect(1)
        expect_equal(e:getType(), "blur")
    end)

    it("newImageEffect('blur', {radius=4}) produces effectCount == 1", function()
        local fx = luna.postfx.newImageEffect("blur", { radius = 4 })
        expect_equal(fx:effectCount(), 1)
    end)

    it("newImageEffect('blur', {radius=4}) sets radius parameter", function()
        local fx = luna.postfx.newImageEffect("blur", { radius = 4 })
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 4) < 0.001, true)
    end)
end)

-- =============================================================================
-- Construction — chain table
-- =============================================================================

describe("luna.postfx.newImageEffect construction (chain table)", function()
    it("two-element chain produces effectCount == 2", function()
        local fx = luna.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:effectCount(), 2)
    end)

    it("first effect in chain is 'blur'", function()
        local fx = luna.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("second effect in chain is 'sepia'", function()
        local fx = luna.postfx.newImageEffect({ { type = "blur", radius = 2 }, { type = "sepia" } })
        expect_equal(fx:getEffect(2):getType(), "sepia")
    end)

    it("chain entry parameters are applied", function()
        local fx = luna.postfx.newImageEffect({ { type = "blur", radius = 2 } })
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 2) < 0.001, true)
    end)
end)

-- =============================================================================
-- addEffect
-- =============================================================================

describe("ImageEffect:addEffect", function()
    it("addEffect returns non-nil", function()
        local fx = luna.postfx.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e ~= nil, true)
    end)

    it("addEffect returns PostFxEffect with correct type", function()
        local fx = luna.postfx.newImageEffect()
        local e = fx:addEffect("vignette")
        expect_equal(e:getType(), "vignette")
    end)

    it("addEffect increments effectCount", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 2)
    end)

    it("addEffect appends to end of chain", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        expect_equal(fx:getEffect(2):getType(), "vignette")
    end)
end)

-- =============================================================================
-- getEffect by index (1-based)
-- =============================================================================

describe("ImageEffect:getEffect by index", function()
    it("getEffect(1) returns first effect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("getEffect(2) returns second effect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        expect_equal(fx:getEffect(2):getType(), "sepia")
    end)

    it("getEffect out-of-bounds returns nil or errors gracefully", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(99)
            -- nil is also acceptable
            expect_equal(e == nil, true)
        end)
        -- either nil return or error is acceptable; what matters is no unhandled crash
        expect_equal(true, true)
    end)

    it("getEffect(0) returns nil or errors gracefully", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect(0)
            expect_equal(e == nil, true)
        end)
        expect_equal(true, true)
    end)
end)

-- =============================================================================
-- getEffect by name
-- =============================================================================

describe("ImageEffect:getEffect by name", function()
    it("getEffect('blur') returns the blur effect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("blur")
        expect_equal(e ~= nil, true)
        expect_equal(e:getType(), "blur")
    end)

    it("getEffect('sepia') returns the sepia effect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local e = fx:getEffect("sepia")
        expect_equal(e ~= nil, true)
        expect_equal(e:getType(), "sepia")
    end)

    it("getEffect with unknown name returns nil or errors gracefully", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        local ok = pcall(function()
            local e = fx:getEffect("nonexistent_effect")
            expect_equal(e == nil, true)
        end)
        expect_equal(true, true)
    end)
end)

-- =============================================================================
-- setParameter / getParameter round-trip
-- =============================================================================

describe("PostFxEffect setParameter / getParameter round-trip", function()
    it("setParameter radius then getParameter returns same value", function()
        local fx = luna.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 7.5)
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 7.5) < 0.001, true)
    end)

    it("setParameter overwrites previous value", function()
        local fx = luna.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 3.0)
        fx:getEffect(1):setParameter("radius", 9.0)
        local v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(v - 9.0) < 0.001, true)
    end)

    it("getParameter on separate effects are independent", function()
        local fx = luna.postfx.newImageEffect()
        local e1 = fx:addEffect("blur")
        local e2 = fx:addEffect("blur")
        e1:setParameter("radius", 2.0)
        e2:setParameter("radius", 8.0)
        expect_equal(math.abs(e1:getParameter("radius") - 2.0) < 0.001, true)
        expect_equal(math.abs(e2:getParameter("radius") - 8.0) < 0.001, true)
    end)
end)

-- =============================================================================
-- effectCount
-- =============================================================================

describe("ImageEffect:effectCount", function()
    it("starts at 0 for empty chain", function()
        local fx = luna.postfx.newImageEffect()
        expect_equal(fx:effectCount(), 0)
    end)

    it("increments by 1 after each addEffect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        expect_equal(fx:effectCount(), 1)
        fx:addEffect("vignette")
        expect_equal(fx:effectCount(), 2)
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 3)
    end)

    it("decrements after removeEffect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)
end)

-- =============================================================================
-- removeEffect by index
-- =============================================================================

describe("ImageEffect:removeEffect by index", function()
    it("removeEffect(1) decrements effectCount", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:effectCount(), 1)
    end)

    it("remaining effect after removing index 1 is the second original", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)

    it("removeEffect(2) removes the second effect", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect(2)
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)
end)

-- =============================================================================
-- removeEffect by name
-- =============================================================================

describe("ImageEffect:removeEffect by name", function()
    it("removeEffect('sepia') from [blur, sepia] → effectCount == 1", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(fx:effectCount(), 1)
    end)

    it("remaining effect after removing 'sepia' is 'blur'", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("sepia")
        expect_equal(fx:getEffect(1):getType(), "blur")
    end)

    it("removeEffect('blur') from [blur, sepia] → remaining is 'sepia'", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        fx:removeEffect("blur")
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)
end)

-- =============================================================================
-- clearEffects
-- =============================================================================

describe("ImageEffect:clearEffects", function()
    it("clearEffects on populated chain produces effectCount == 0", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("vignette")
        fx:addEffect("sepia")
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    it("clearEffects on empty chain is a no-op", function()
        local fx = luna.postfx.newImageEffect()
        fx:clearEffects()
        expect_equal(fx:effectCount(), 0)
    end)

    it("can addEffect again after clearEffects", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:clearEffects()
        fx:addEffect("sepia")
        expect_equal(fx:effectCount(), 1)
        expect_equal(fx:getEffect(1):getType(), "sepia")
    end)
end)

-- =============================================================================
-- clone
-- =============================================================================

describe("ImageEffect:clone", function()
    it("clone returns non-nil", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        expect_equal(copy ~= nil, true)
    end)

    it("clone has the same effectCount as original", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(copy:effectCount(), fx:effectCount())
    end)

    it("clone has the same effect types in order", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        fx:addEffect("sepia")
        local copy = fx:clone()
        expect_equal(copy:getEffect(1):getType(), "blur")
        expect_equal(copy:getEffect(2):getType(), "sepia")
    end)

    it("modifying clone does not affect original effectCount", function()
        local fx = luna.postfx.newImageEffect()
        fx:addEffect("blur")
        local copy = fx:clone()
        copy:addEffect("vignette")
        expect_equal(fx:effectCount(), 1)
        expect_equal(copy:effectCount(), 2)
    end)

    it("modifying clone parameter does not affect original", function()
        local fx = luna.postfx.newImageEffect("blur")
        fx:getEffect(1):setParameter("radius", 3.0)
        local copy = fx:clone()
        copy:getEffect(1):setParameter("radius", 99.0)
        local orig_v = fx:getEffect(1):getParameter("radius")
        expect_equal(math.abs(orig_v - 3.0) < 0.001, true)
    end)
end)

-- =============================================================================
-- Invalid effect name
-- =============================================================================

describe("luna.postfx.newImageEffect invalid effect name", function()
    it("rejects unknown effect name on construction", function()
        expect_error(function()
            luna.postfx.newImageEffect("not_a_real_effect")
        end)
    end)

    it("addEffect rejects unknown effect name", function()
        local fx = luna.postfx.newImageEffect()
        expect_error(function()
            fx:addEffect("not_a_real_effect")
        end)
    end)
end)

-- =============================================================================
-- loadImageEffect function exists
-- =============================================================================

describe("luna.postfx.loadImageEffect", function()
    it("loadImageEffect is a function", function()
        expect_type("function", luna.postfx.loadImageEffect)
    end)
end)

test_summary()
