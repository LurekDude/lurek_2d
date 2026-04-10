-- tests/lua/unit/test_overlay.lua
-- BDD tests for the lurek.effect.* screen-effect overlay API.
-- @covers lurek.effect.newOverlay


require("tests/lua/init")

-- ═════════════════════════════════════════════════════════════════════════
-- 1. Factory and Construction
-- ═════════════════════════════════════════════════════════════════════════

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

-- ═════════════════════════════════════════════════════════════════════════
-- 2. Type Introspection
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay type", function()
    it("reports type as Overlay", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:type(), "Overlay")
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

-- ═════════════════════════════════════════════════════════════════════════
-- 3. Core Lifecycle
-- ═════════════════════════════════════════════════════════════════════════

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
        ov:draw()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 4. Ambient Lighting
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay ambient", function()
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
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 5. Weather System
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay weather", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 6. Screen Flash
-- ═════════════════════════════════════════════════════════════════════════

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

-- ═════════════════════════════════════════════════════════════════════════
-- 7. Screen Shake
-- ═════════════════════════════════════════════════════════════════════════

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

-- ═════════════════════════════════════════════════════════════════════════
-- 8. Screen Fade
-- ═════════════════════════════════════════════════════════════════════════

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

-- ═════════════════════════════════════════════════════════════════════════
-- 9. Cloud Shadows
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay clouds", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 10. Atmospheric Fog
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay fog", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 11. Heat Haze
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay heat haze", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 12. Vignette
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay vignette", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 13. Film Grain
-- ═════════════════════════════════════════════════════════════════════════

describe("overlay film grain", function()
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

-- ═════════════════════════════════════════════════════════════════════════
-- 14. Lightning
-- ═════════════════════════════════════════════════════════════════════════

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
        expect_near(a, 0.8, 0.001)
    end)
end)

-- ═════════════════════════════════════════════════════════════════════════
-- 15. Combined Effects
-- ═════════════════════════════════════════════════════════════════════════

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
