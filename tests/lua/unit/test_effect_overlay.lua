-- tests/lua/unit/test_effect_overlay.lua
-- BDD tests for the lurek.effect.* screen-effect overlay API.
-- @covers lurek.effect.newOverlay

require("tests/lua/init")

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 1. Factory and Construction
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: lurek.effect factory.
describe("lurek.effect factory", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.getWidth
    -- @covers Overlay.getHeight
    -- @description Creates an overlay with explicit dimensions and verifies the stored width and height.
    it("creates an overlay with custom dimensions", function()
        local ov = lurek.effect.newOverlay(1024, 768)
        expect_equal(ov:getWidth(), 1024)
        expect_equal(ov:getHeight(), 768)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.getWidth
    -- @covers Overlay.getHeight
    -- @description Verifies the overlay factory uses the default dimensions when none are provided.
    it("creates an overlay with default dimensions", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:getWidth(), 800)
        expect_equal(ov:getHeight(), 600)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.getDimensions
    -- @description Confirms getDimensions returns the overlay size as a width-height tuple.
    it("returns dimensions as tuple", function()
        local ov = lurek.effect.newOverlay(640, 480)
        local w, h = ov:getDimensions()
        expect_equal(w, 640)
        expect_equal(h, 480)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 2. Type Introspection
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay type.
describe("overlay type", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.type
    -- @description Verifies overlay userdata reports its concrete type name.
    it("reports type as Overlay", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:type(), "Overlay")
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.typeOf
    -- @description Confirms overlays identify as Object through the shared type hierarchy.
    it("typeOf Object returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Object"), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.typeOf
    -- @description Confirms overlays identify as Overlay through typeOf.
    it("typeOf Overlay returns true", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("Overlay"), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.typeOf
    -- @description Verifies typeOf rejects unrelated type names.
    it("typeOf unrelated returns false", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:typeOf("PostFxEffect"), false)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 3. Core Lifecycle
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay core.
describe("overlay core", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.isActive
    -- @description Verifies a newly created overlay starts inactive.
    it("starts inactive", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isActive(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.resize
    -- @covers Overlay.getWidth
    -- @covers Overlay.getHeight
    -- @description Resizes an overlay and verifies the width and height accessors reflect the new size.
    it("resize updates dimensions", function()
        local ov = lurek.effect.newOverlay(800, 600)
        ov:resize(1920, 1080)
        expect_equal(ov:getWidth(), 1920)
        expect_equal(ov:getHeight(), 1080)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.update
    -- @covers Overlay.isActive
    -- @description Updates an empty overlay and verifies it remains inactive without error.
    it("update does not error on empty overlay", function()
        local ov = lurek.effect.newOverlay()
        ov:update(0.016)
        expect_equal(ov:isActive(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.draw
    -- @description Ensures drawing an empty overlay does not raise an error.
    it("draw does not error", function()
        local ov = lurek.effect.newOverlay()
        ov:draw()
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeatherEnabled
    -- @covers Overlay.setFogEnabled
    -- @covers Overlay.setVignetteEnabled
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.clear
    -- @covers Overlay.isActive
    -- @description Activates several overlay subsystems, clears them, and verifies the overlay becomes inactive.
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

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 4. Ambient Lighting
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay ambient.
describe("overlay ambient", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.isAmbientEnabled
    -- @covers Overlay.isActive
    -- @description Enables ambient lighting and verifies both the ambient flag and overall activity state.
    it("enables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        expect_equal(ov:isAmbientEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.isAmbientEnabled
    -- @description Disables ambient lighting after enabling it and verifies the flag is cleared.
    it("disables ambient lighting", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientEnabled(true)
        ov:setAmbientEnabled(false)
        expect_equal(ov:isAmbientEnabled(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientColor
    -- @covers Overlay.getAmbientColor
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientColor
    -- @covers Overlay.getAmbientColor
    -- @description Verifies ambient color defaults the alpha channel to 1.0 when omitted.
    it("ambient color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setAmbientColor(0.5, 0.5, 0.5)
        local _, _, _, a = ov:getAmbientColor()
        expect_near(a, 1.0, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setTimeOfDay
    -- @covers Overlay.getTimeOfDay
    -- @description Sets the time-of-day value and verifies it round-trips through the getter.
    it("sets and gets time of day", function()
        local ov = lurek.effect.newOverlay()
        ov:setTimeOfDay(6.5)
        expect_near(ov:getTimeOfDay(), 6.5, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.setTimeOfDay
    -- @covers Overlay.update
    -- @covers Overlay.getAmbientColor
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.setTimeOfDay
    -- @covers Overlay.update
    -- @covers Overlay.getAmbientColor
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

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 5. Weather System
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay weather.
describe("overlay weather", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeatherEnabled
    -- @covers Overlay.isWeatherEnabled
    -- @description Enables the weather system and verifies the weather-enabled flag.
    it("enables weather", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherEnabled(true)
        expect_equal(ov:isWeatherEnabled(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeather
    -- @covers Overlay.getWeather
    -- @description Sets the active weather type and verifies it can be read back.
    it("sets weather type", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeather("rain")
        expect_equal(ov:getWeather(), "rain")
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeather
    -- @covers Overlay.getWeather
    -- @description Iterates through every supported weather mode and verifies each round-trips through the getter.
    it("roundtrips all weather types", function()
        local ov = lurek.effect.newOverlay()
        local types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
        for _, wt in ipairs(types) do
            ov:setWeather(wt)
            expect_equal(ov:getWeather(), wt)
        end
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeather
    -- @description Verifies setWeather rejects an unsupported weather type.
    it("rejects invalid weather type", function()
        local ov = lurek.effect.newOverlay()
        expect_error(function()
            ov:setWeather("tornado")
        end)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeatherIntensity
    -- @covers Overlay.getWeatherIntensity
    -- @description Sets the weather intensity and verifies the floating-point value round-trips.
    it("sets and gets weather intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setWeatherIntensity(0.8)
        expect_near(ov:getWeatherIntensity(), 0.8, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWindDirection
    -- @covers Overlay.getWindDirection
    -- @description Sets the wind direction and verifies the stored angle.
    it("sets and gets wind direction", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindDirection(1.57)
        expect_near(ov:getWindDirection(), 1.57, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWindSpeed
    -- @covers Overlay.getWindSpeed
    -- @description Sets the wind speed and verifies the stored magnitude.
    it("sets and gets wind speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setWindSpeed(75.0)
        expect_near(ov:getWindSpeed(), 75.0, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 6. Screen Flash
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay flash.
describe("overlay flash", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.isFlashing
    -- @covers Overlay.flash
    -- @description Triggers a screen flash and verifies the flashing state becomes active.
    it("triggers a flash", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFlashing(), false)
        ov:flash(1, 0, 0, 1, 0.5)
        expect_equal(ov:isFlashing(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.flash
    -- @covers Overlay.update
    -- @covers Overlay.isFlashing
    -- @description Uses the default flash alpha and duration and verifies the flash clears after enough simulated time.
    it("flash with default alpha and duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isFlashing(), true)
        -- default duration = 0.2
        ov:update(0.3)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.flash
    -- @covers Overlay.update
    -- @covers Overlay.isFlashing
    -- @description Verifies a flash stops once the update delta exceeds its explicit duration.
    it("flash completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 0, 0, 1, 0.1)
        ov:update(0.2)
        expect_equal(ov:isFlashing(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.flash
    -- @covers Overlay.isActive
    -- @description Confirms triggering a flash marks the overlay as active.
    it("flash activates isActive", function()
        local ov = lurek.effect.newOverlay()
        ov:flash(1, 1, 1)
        expect_equal(ov:isActive(), true)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 7. Screen Shake
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay shake.
describe("overlay shake", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.isShaking
    -- @covers Overlay.shake
    -- @description Triggers screen shake and verifies the shaking state becomes active.
    it("triggers a shake", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isShaking(), false)
        ov:shake(10, 0.5)
        expect_equal(ov:isShaking(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.shake
    -- @covers Overlay.update
    -- @covers Overlay.isShaking
    -- @description Uses the default shake duration and verifies the effect ends after advancing time.
    it("shake with default duration", function()
        local ov = lurek.effect.newOverlay()
        ov:shake(8.0)
        expect_equal(ov:isShaking(), true)
        -- default duration = 0.5
        ov:update(0.6)
        expect_equal(ov:isShaking(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.shake
    -- @covers Overlay.update
    -- @covers Overlay.getShakeOffset
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.shake
    -- @covers Overlay.update
    -- @covers Overlay.getShakeOffset
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

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 8. Screen Fade
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay fade.
describe("overlay fade", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.isFading
    -- @covers Overlay.fade
    -- @description Triggers a screen fade and verifies the fading state becomes active.
    it("triggers a fade", function()
        local ov = lurek.effect.newOverlay()
        expect_equal(ov:isFading(), false)
        ov:fade(0, 0, 0, 1, 1.0)
        expect_equal(ov:isFading(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.fade
    -- @covers Overlay.update
    -- @covers Overlay.isFading
    -- @description Uses the default fade alpha and duration and verifies the effect completes after enough time passes.
    it("fade with defaults", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0)
        expect_equal(ov:isFading(), true)
        -- default alpha=1.0, duration=1.0
        ov:update(1.1)
        expect_equal(ov:isFading(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.fade
    -- @covers Overlay.update
    -- @covers Overlay.isFading
    -- @description Verifies a fade clears after an explicit short duration.
    it("fade completes after duration", function()
        local ov = lurek.effect.newOverlay()
        ov:fade(0, 0, 0, 0.8, 0.5)
        ov:update(0.6)
        expect_equal(ov:isFading(), false)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 9. Cloud Shadows
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay clouds.
describe("overlay clouds", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudShadows
    -- @covers Overlay.isCloudShadowsEnabled
    -- @covers Overlay.isActive
    -- @description Enables cloud shadows and verifies both the cloud-shadow flag and overall active state.
    it("enables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        expect_equal(ov:isCloudShadowsEnabled(), true)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudShadows
    -- @covers Overlay.isCloudShadowsEnabled
    -- @description Disables cloud shadows after enabling them and verifies the flag is cleared.
    it("disables cloud shadows", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudShadows(true)
        ov:setCloudShadows(false)
        expect_equal(ov:isCloudShadowsEnabled(), false)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudCount
    -- @covers Overlay.getCloudCount
    -- @description Sets the number of simulated clouds and verifies the value round-trips.
    it("sets and gets cloud count", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudCount(12)
        expect_equal(ov:getCloudCount(), 12)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudSpeed
    -- @covers Overlay.getCloudSpeed
    -- @description Sets the cloud movement speed and verifies the stored value.
    it("sets and gets cloud speed", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudSpeed(35.0)
        expect_near(ov:getCloudSpeed(), 35.0, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudScale
    -- @covers Overlay.getCloudScale
    -- @description Sets the cloud scale and verifies the getter returns the new scale.
    it("sets and gets cloud scale", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudScale(2.5)
        expect_near(ov:getCloudScale(), 2.5, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setCloudOpacity
    -- @covers Overlay.getCloudOpacity
    -- @description Sets the cloud opacity and verifies the getter returns the configured opacity.
    it("sets and gets cloud opacity", function()
        local ov = lurek.effect.newOverlay()
        ov:setCloudOpacity(0.6)
        expect_near(ov:getCloudOpacity(), 0.6, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 10. Atmospheric Fog
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay fog.
describe("overlay fog", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFogEnabled
    -- @covers Overlay.isFogEnabled
    -- @description Enables atmospheric fog and verifies the fog-enabled flag.
    it("enables fog", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogEnabled(true)
        expect_equal(ov:isFogEnabled(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFogDensity
    -- @covers Overlay.getFogDensity
    -- @description Sets the fog density and verifies the floating-point value round-trips.
    it("sets and gets fog density", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogDensity(0.7)
        expect_near(ov:getFogDensity(), 0.7, 0.001)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFogColor
    -- @covers Overlay.getFogColor
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFogColor
    -- @covers Overlay.getFogColor
    -- @description Verifies fog color defaults the alpha channel to 1.0 when omitted.
    it("fog color alpha defaults to 1.0", function()
        local ov = lurek.effect.newOverlay()
        ov:setFogColor(0.3, 0.3, 0.4)
        local _, _, _, a = ov:getFogColor()
        expect_near(a, 1.0, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 11. Heat Haze
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay heat haze.
describe("overlay heat haze", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setHeatHazeEnabled
    -- @covers Overlay.isHeatHazeEnabled
    -- @description Enables heat haze and verifies the effect flag is set.
    it("enables heat haze", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeEnabled(true)
        expect_equal(ov:isHeatHazeEnabled(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setHeatHazeIntensity
    -- @covers Overlay.getHeatHazeIntensity
    -- @description Sets the heat haze intensity and verifies the value round-trips.
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setHeatHazeIntensity(0.9)
        expect_near(ov:getHeatHazeIntensity(), 0.9, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 12. Vignette
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay vignette.
describe("overlay vignette", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setVignetteEnabled
    -- @covers Overlay.isVignetteEnabled
    -- @description Enables vignette rendering and verifies the effect flag is set.
    it("enables vignette", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteEnabled(true)
        expect_equal(ov:isVignetteEnabled(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setVignetteStrength
    -- @covers Overlay.getVignetteStrength
    -- @description Sets the vignette strength and verifies the value round-trips.
    it("sets and gets strength", function()
        local ov = lurek.effect.newOverlay()
        ov:setVignetteStrength(0.8)
        expect_near(ov:getVignetteStrength(), 0.8, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 13. Film Grain
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay film grain.
describe("overlay film grain", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFilmGrainEnabled
    -- @covers Overlay.isFilmGrainEnabled
    -- @description Enables film grain and verifies the effect flag is set.
    it("enables film grain", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainEnabled(true)
        expect_equal(ov:isFilmGrainEnabled(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setFilmGrainIntensity
    -- @covers Overlay.getFilmGrainIntensity
    -- @description Sets the film grain intensity and verifies the value round-trips.
    it("sets and gets intensity", function()
        local ov = lurek.effect.newOverlay()
        ov:setFilmGrainIntensity(0.6)
        expect_near(ov:getFilmGrainIntensity(), 0.6, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 14. Lightning
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay lightning.
describe("overlay lightning", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.triggerLightning
    -- @covers Overlay.isActive
    -- @description Triggers a lightning effect and verifies the overlay becomes active.
    it("triggers lightning", function()
        local ov = lurek.effect.newOverlay()
        ov:triggerLightning()
        -- Lightning is active (makes overlay active)
        expect_equal(ov:isActive(), true)
    end)

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setLightningColor
    -- @covers Overlay.getLightningColor
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setLightningColor
    -- @covers Overlay.getLightningColor
    -- @description Verifies lightning color defaults the alpha channel to 0.8 when omitted.
    it("lightning color alpha defaults to 0.8", function()
        local ov = lurek.effect.newOverlay()
        ov:setLightningColor(1, 1, 1)
        local _, _, _, a = ov:getLightningColor()
        expect_near(a, 0.8, 0.001)
    end)
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
-- 15. Combined Effects
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- @description Covers suite: overlay combined.
describe("overlay combined", function()
    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeatherEnabled
    -- @covers Overlay.setFogEnabled
    -- @covers Overlay.setVignetteEnabled
    -- @covers Overlay.flash
    -- @covers Overlay.isActive
    -- @description Activates several overlay subsystems together and verifies they coexist in the expected active state.
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.setWeatherEnabled
    -- @covers Overlay.setFogEnabled
    -- @covers Overlay.setVignetteEnabled
    -- @covers Overlay.setFilmGrainEnabled
    -- @covers Overlay.setHeatHazeEnabled
    -- @covers Overlay.setCloudShadows
    -- @covers Overlay.setAmbientEnabled
    -- @covers Overlay.flash
    -- @covers Overlay.shake
    -- @covers Overlay.fade
    -- @covers Overlay.triggerLightning
    -- @covers Overlay.clear
    -- @covers Overlay.isActive
    -- @description Populates every major overlay effect, clears the overlay, and verifies all activity is removed.
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

    -- @covers lurek.effect.newOverlay
    -- @covers Overlay.flash
    -- @covers Overlay.shake
    -- @covers Overlay.update
    -- @covers Overlay.isFlashing
    -- @covers Overlay.isShaking
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
