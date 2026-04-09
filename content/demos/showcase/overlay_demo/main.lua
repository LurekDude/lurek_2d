-- examples/overlay_demo/main.lua
-- Demonstrates lurek.overlay for composable screen effects.
-- Press F to flash, S to shake, L for lightning, D to fade, C to clear.
-- Press 1-8 to cycle weather types, V to toggle vignette, G to toggle fog.
-- Run with: cargo run -- content/demos/showcase/overlay_demo

local overlay
local time_speed = 1.0  -- hours per second for time-of-day cycling
local weather_types = {"none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen"}
local current_weather = 2  -- start with rain

function lurek.init()
    overlay = lurek.overlay.newOverlay(800, 600)

    -- Enable a moody rainy-night scene
    overlay:setWeatherEnabled(true)
    overlay:setWeather("rain")
    overlay:setWeatherIntensity(0.6)
    overlay:setWindDirection(0.3)
    overlay:setWindSpeed(30.0)

    -- Ambient lighting: start at night
    overlay:setAmbientEnabled(true)
    overlay:setTimeOfDay(22.0)

    -- Fog for atmosphere
    overlay:setFogEnabled(true)
    overlay:setFogDensity(0.15)
    overlay:setFogColor(0.4, 0.4, 0.5)

    -- Subtle vignette
    overlay:setVignetteEnabled(true)
    overlay:setVignetteStrength(0.4)

    -- Cloud shadows
    overlay:setCloudShadows(true)
    overlay:setCloudCount(8)
    overlay:setCloudSpeed(15.0)
    overlay:setCloudOpacity(0.2)
end

function lurek.process(dt)
    -- Advance time of day
    local tod = overlay:getTimeOfDay() + time_speed * dt
    if tod >= 24.0 then tod = tod - 24.0 end
    overlay:setTimeOfDay(tod)

    -- Tick all overlay effects
    overlay:update(dt)
end

function lurek.render()
    -- Background gradient (simulated with two rectangles)
    local r, g, b = overlay:getAmbientColor()
    lurek.gfx.setColor(r * 0.3, g * 0.3, b * 0.3, 1)
    lurek.gfx.rectangle("fill", 0, 0, 800, 300)
    lurek.gfx.setColor(r * 0.15, g * 0.15, b * 0.15, 1)
    lurek.gfx.rectangle("fill", 0, 300, 800, 300)

    -- Ground
    lurek.gfx.setColor(0.15, 0.2, 0.1, 1)
    lurek.gfx.rectangle("fill", 0, 450, 800, 150)

    -- HUD
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Overlay Demo — Screen Effects", 20, 20)
    lurek.gfx.print(string.format("Time: %.1fh  Weather: %s  Active: %s",
        overlay:getTimeOfDay(),
        overlay:getWeather(),
        tostring(overlay:isActive())), 20, 45)
    lurek.gfx.print("F=Flash  S=Shake  L=Lightning  D=Fade  C=Clear", 20, 70)
    lurek.gfx.print("1-8=Weather  V=Vignette  G=Fog  H=HeatHaze  N=FilmGrain", 20, 95)
    lurek.gfx.print(string.format("+/- = Time speed (%.1fx)", time_speed), 20, 120)

    -- Show active effect indicators
    local y = 150
    if overlay:isFlashing() then
        lurek.gfx.setColor(1, 1, 0, 1)
        lurek.gfx.print("[FLASH]", 20, y)
        y = y + 20
    end
    if overlay:isShaking() then
        local ox, oy = overlay:getShakeOffset()
        lurek.gfx.setColor(1, 0.5, 0, 1)
        lurek.gfx.print(string.format("[SHAKE] offset: %.1f, %.1f", ox, oy), 20, y)
        y = y + 20
    end
    if overlay:isFading() then
        lurek.gfx.setColor(0.5, 0.5, 1, 1)
        lurek.gfx.print("[FADING]", 20, y)
        y = y + 20
    end
    if overlay:isFogEnabled() then
        local density = overlay:getFogDensity()
        lurek.gfx.setColor(0.7, 0.7, 0.8, 1)
        lurek.gfx.print(string.format("[FOG] density: %.2f", density), 20, y)
        y = y + 20
    end
    if overlay:isVignetteEnabled() then
        lurek.gfx.setColor(0.6, 0.4, 0.6, 1)
        lurek.gfx.print(string.format("[VIGNETTE] strength: %.2f", overlay:getVignetteStrength()), 20, y)
        y = y + 20
    end

    overlay:draw()
end

function lurek.keypressed(key)
    if key == "f" then
        overlay:flash(1, 1, 1, 0.8, 0.3)
    elseif key == "s" then
        overlay:shake(12.0, 0.5)
    elseif key == "l" then
        overlay:triggerLightning()
    elseif key == "d" then
        overlay:fade(0, 0, 0, 1.0, 2.0)
    elseif key == "c" then
        overlay:clear()
        -- Re-enable basic setup after clear
        overlay:setWeatherEnabled(true)
        overlay:setWeather(weather_types[current_weather])
        overlay:setAmbientEnabled(true)
    elseif key == "v" then
        overlay:setVignetteEnabled(not overlay:isVignetteEnabled())
    elseif key == "g" then
        overlay:setFogEnabled(not overlay:isFogEnabled())
    elseif key == "h" then
        overlay:setHeatHazeEnabled(not overlay:isHeatHazeEnabled())
        if overlay:isHeatHazeEnabled() then
            overlay:setHeatHazeIntensity(0.6)
        end
    elseif key == "n" then
        overlay:setFilmGrainEnabled(not overlay:isFilmGrainEnabled())
        if overlay:isFilmGrainEnabled() then
            overlay:setFilmGrainIntensity(0.4)
        end
    elseif key == "=" or key == "+" then
        time_speed = math.min(time_speed + 0.5, 10.0)
    elseif key == "-" then
        time_speed = math.max(time_speed - 0.5, 0.0)
    elseif key == "escape" then
        lurek.signal.quit()
    else
        -- Number keys 1-8 cycle weather types
        local num = tonumber(key)
        if num and num >= 1 and num <= 8 then
            current_weather = num
            overlay:setWeather(weather_types[current_weather])
        end
    end
end
