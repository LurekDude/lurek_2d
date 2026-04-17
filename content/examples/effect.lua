-- content/examples/effect.lua
-- Lurek2D lurek.effect API Reference
-- Run with: cargo run -- content/examples/effect
--
-- Scenario: An action RPG with full-screen post-processing (bloom, CRT, vignette),
-- a dynamic weather/day-night overlay system, image processing effects for screenshots,
-- and screen transitions (fade, dissolve, slide) between game scenes.

print("=== lurek.effect — Visual Effects & Post-Processing ===\n")

-- =============================================================================
-- Effect Creation (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.effect.newEffect -----------------------------------------
--@api-stub: lurek.effect.newEffect
-- Create a built-in post-processing effect by type name.
local bloom = lurek.effect.newEffect("bloom")
local crt = lurek.effect.newEffect("crt")
local blur = lurek.effect.newEffect("blur")
print("effects created: bloom, crt, blur")

-- ---- Stub: lurek.effect.newCustomEffect -----------------------------------
--@api-stub: lurek.effect.newCustomEffect
-- Create a custom post-processing effect from a WGSL shader file.
local custom_fx = lurek.effect.newCustomEffect("assets/shaders/pixelate.wgsl", {
    pixel_size = 4.0
})
print("custom effect: pixelate shader (4px grid)")

-- ---- Stub: lurek.effect.getEffectTypes ------------------------------------
--@api-stub: lurek.effect.getEffectTypes
-- List all available built-in effect types.
local types = lurek.effect.getEffectTypes()
print("available effect types: " .. #types)
for _, t in ipairs(types) do
    print("  - " .. t)
end

-- ---- Stub: lurek.effect.setShaderErrorDisplay -----------------------------
--@api-stub: lurek.effect.setShaderErrorDisplay
-- Show shader compilation errors on-screen (useful during development).
lurek.effect.setShaderErrorDisplay(true)
print("shader error display: ON (dev mode)")

-- ---- Stub: lurek.effect.getShaderErrorDisplay -----------------------------
--@api-stub: lurek.effect.getShaderErrorDisplay
print("shader error display: " .. tostring(lurek.effect.getShaderErrorDisplay()))

-- =============================================================================
-- PostFxEffect Object Methods — per-effect control
-- =============================================================================

-- ---- Stub: PostFxEffect:getTypeName ---------------------------------------
--@api-stub: PostFxEffect:getTypeName
print("bloom type: " .. bloom:getTypeName())
print("crt type: " .. crt:getTypeName())

-- ---- Stub: PostFxEffect:isBuiltIn -----------------------------------------
--@api-stub: PostFxEffect:isBuiltIn
print("bloom built-in: " .. tostring(bloom:isBuiltIn()))
print("custom built-in: " .. tostring(custom_fx:isBuiltIn()))

-- ---- Stub: PostFxEffect:isEnabled -----------------------------------------
--@api-stub: PostFxEffect:isEnabled
print("bloom enabled: " .. tostring(bloom:isEnabled()))

-- ---- Stub: PostFxEffect:setEnabled ----------------------------------------
--@api-stub: PostFxEffect:setEnabled
-- Toggle effects from the graphics settings menu.
bloom:setEnabled(true)
crt:setEnabled(false)
print("bloom ON, crt OFF")

-- ---- Stub: PostFxEffect:setParameter --------------------------------------
--@api-stub: PostFxEffect:setParameter
-- Set named parameters on any effect (built-in or custom).
bloom:setParameter("threshold", 0.8)
bloom:setParameter("intensity", 1.5)
bloom:setParameter("radius", 4)
print("bloom: threshold=0.8, intensity=1.5, radius=4")

-- ---- Stub: PostFxEffect:hasParameter --------------------------------------
--@api-stub: PostFxEffect:hasParameter
print("bloom has 'threshold': " .. tostring(bloom:hasParameter("threshold")))
print("bloom has 'color': " .. tostring(bloom:hasParameter("color")))

-- ---- Stub: PostFxEffect:getParameterNames ---------------------------------
--@api-stub: PostFxEffect:getParameterNames
local params = bloom:getParameterNames()
print("bloom parameters: " .. table.concat(params, ", "))

-- ---- Stub: PostFxEffect:getEffectType -------------------------------------
--@api-stub: PostFxEffect:getEffectType
print("bloom effect type: " .. tostring(bloom:getEffectType()))

-- ---- Stub: PostFxEffect:getType -------------------------------------------
--@api-stub: PostFxEffect:getType
print("bloom getType: " .. tostring(bloom:getType()))

-- ---- Stub: PostFxEffect:type ----------------------------------------------
--@api-stub: PostFxEffect:type
-- ---- Stub: PostFxEffect:typeOf --------------------------------------------
--@api-stub: PostFxEffect:typeOf
print("bloom type(): " .. tostring(bloom:type()))
print("bloom typeOf: " .. tostring(bloom:typeOf("PostFxEffect")))

-- Shorthand setters for common effect parameters:

-- ---- Stub: PostFxEffect:setThreshold --------------------------------------
--@api-stub: PostFxEffect:setThreshold
-- Brightness threshold for bloom extraction. Lower = more glow.
bloom:setThreshold(0.6)
print("bloom threshold: 0.6 (more objects glow)")

-- ---- Stub: PostFxEffect:setIntensity --------------------------------------
--@api-stub: PostFxEffect:setIntensity
bloom:setIntensity(2.0)
print("bloom intensity: 2.0 (strong glow)")

-- ---- Stub: PostFxEffect:setRadius -----------------------------------------
--@api-stub: PostFxEffect:setRadius
-- Blur radius for bloom spread. Higher = wider glow halo.
bloom:setRadius(8)
print("bloom radius: 8 (wide halo)")

-- ---- Stub: PostFxEffect:setStrength ---------------------------------------
--@api-stub: PostFxEffect:setStrength
blur:setStrength(0.5)
print("blur strength: 0.5 (subtle background blur)")

-- ---- Stub: PostFxEffect:setScanlineStrength -------------------------------
--@api-stub: PostFxEffect:setScanlineStrength
-- CRT scanline darkness. 0=invisible, 1=very prominent.
crt:setScanlineStrength(0.3)
print("CRT scanlines: 0.3 (subtle retro look)")

-- ---- Stub: PostFxEffect:setOffset -----------------------------------------
--@api-stub: PostFxEffect:setOffset
-- Chromatic aberration offset for CRT or glitch effects.
crt:setOffset(1.5)
print("CRT chromatic offset: 1.5px")

-- ---- Stub: PostFxEffect:setBrightness -------------------------------------
--@api-stub: PostFxEffect:setBrightness
-- Brightness adjustment for color correction effects.
crt:setBrightness(1.1)
print("CRT brightness: 1.1 (slightly brighter)")

-- ---- Stub: PostFxEffect:setContrast ---------------------------------------
--@api-stub: PostFxEffect:setContrast
crt:setContrast(1.2)
print("CRT contrast: 1.2 (punchier colors)")

-- ---- Stub: PostFxEffect:setSaturation -------------------------------------
--@api-stub: PostFxEffect:setSaturation
-- Desaturate when the player is low on health.
crt:setSaturation(0.4)
print("CRT saturation: 0.4 (desaturated — low health warning)")

-- =============================================================================
-- PostFx Effect Stack — compositing multiple effects
-- =============================================================================

-- ---- Stub: lurek.effect.newStack ------------------------------------------
--@api-stub: lurek.effect.newStack
-- Create an empty effect stack that composites effects in sequence.
local fx_stack = lurek.effect.newStack(800, 600)
print("effect stack created: 800x600")

-- ---- Stub: lurek.effect.newPresetStack ------------------------------------
--@api-stub: lurek.effect.newPresetStack
-- Create a stack with a pre-configured set of effects.
local retro_stack = lurek.effect.newPresetStack("retro", 800, 600)
print("retro preset stack: bloom + CRT + vignette")

-- ---- Stub: lurek.effect.newPass -------------------------------------------
--@api-stub: lurek.effect.newPass
-- Create a single render pass for manual pipeline construction.
local pass = lurek.effect.newPass("assets/shaders/downsample.wgsl", 400, 300)
print("render pass: downsample at 400x300")

-- ---- Stub: PostFxStack:add ------------------------------------------------
--@api-stub: PostFxStack:add
-- Add effects to the stack. Rendering order = insertion order.
fx_stack:add(bloom)
fx_stack:add(crt)
print("stack: bloom -> CRT (rendering order)")

-- ---- Stub: PostFxStack:remove ---------------------------------------------
--@api-stub: PostFxStack:remove
-- Remove an effect by reference.
fx_stack:remove(crt)
print("CRT removed from stack")

-- ---- Stub: PostFxStack:isEnabled ------------------------------------------
--@api-stub: PostFxStack:isEnabled
print("stack enabled: " .. tostring(fx_stack:isEnabled()))

-- ---- Stub: PostFxStack:getEffectCount -------------------------------------
--@api-stub: PostFxStack:getEffectCount
print("effects in stack: " .. fx_stack:getEffectCount())

-- ---- Stub: PostFxStack:getEffect ------------------------------------------
--@api-stub: PostFxStack:getEffect
local first_fx = fx_stack:getEffect(0)
print("first effect: " .. tostring(first_fx:getTypeName()))

-- ---- Stub: PostFxStack:getEnabledEffects ----------------------------------
--@api-stub: PostFxStack:getEnabledEffects
local enabled = fx_stack:getEnabledEffects()
print("enabled effects: " .. #enabled)

-- ---- Stub: PostFxStack:getWidth -------------------------------------------
--@api-stub: PostFxStack:getWidth
print("stack width: " .. fx_stack:getWidth())

-- ---- Stub: PostFxStack:getHeight ------------------------------------------
--@api-stub: PostFxStack:getHeight
print("stack height: " .. fx_stack:getHeight())

-- ---- Stub: PostFxStack:getDimensions --------------------------------------
--@api-stub: PostFxStack:getDimensions
local sw, sh = fx_stack:getDimensions()
print("stack dimensions: " .. sw .. "x" .. sh)

-- ---- Stub: PostFxStack:resize ---------------------------------------------
--@api-stub: PostFxStack:resize
-- Resize when window changes.
fx_stack:resize(1280, 720)
print("stack resized to 1280x720")

-- ---- Stub: PostFxStack:len -----------------------------------------------
--@api-stub: PostFxStack:len
print("stack length: " .. fx_stack:len())

-- ---- Stub: PostFxStack:isEmpty --------------------------------------------
--@api-stub: PostFxStack:isEmpty
print("stack empty: " .. tostring(fx_stack:isEmpty()))

-- ---- Stub: PostFxStack:clear ----------------------------------------------
--@api-stub: PostFxStack:clear
fx_stack:clear()
print("stack cleared (all effects removed)")

-- Re-add for further examples
fx_stack:add(bloom)

-- ---- Stub: PostFxStack:dedup ----------------------------------------------
--@api-stub: PostFxStack:dedup
-- Remove duplicate effects (same type added twice).
fx_stack:add(bloom)  -- intentional duplicate
fx_stack:dedup()
print("duplicates removed: " .. fx_stack:getEffectCount() .. " effects remain")

-- ---- Stub: PostFxStack:isCapturing ----------------------------------------
--@api-stub: PostFxStack:isCapturing
print("capturing: " .. tostring(fx_stack:isCapturing()))

-- ---- Stub: PostFxStack:beginCapture ---------------------------------------
--@api-stub: PostFxStack:beginCapture
-- Begin capturing the game render output for post-processing.
fx_stack:beginCapture()
print("capture started — game renders to offscreen buffer")

-- ---- Stub: PostFxStack:endCapture -----------------------------------------
--@api-stub: PostFxStack:endCapture
-- End capture — triggers the effect chain on the captured frame.
fx_stack:endCapture()
print("capture ended — effects applied to frame")

-- ---- Stub: PostFxStack:apply ----------------------------------------------
--@api-stub: PostFxStack:apply
-- Apply the entire effect chain to the current render target.
fx_stack:apply()
print("effect stack applied to screen")

-- ---- Stub: PostFxStack:type -----------------------------------------------
--@api-stub: PostFxStack:type
-- ---- Stub: PostFxStack:typeOf ---------------------------------------------
--@api-stub: PostFxStack:typeOf
print("stack type: " .. tostring(fx_stack:type()))
print("stack typeOf: " .. tostring(fx_stack:typeOf("PostFxStack")))

-- ---- Stub: PostFxStack:setFeedback ----------------------------------------
--@api-stub: PostFxStack:setFeedback
-- Feedback loops: previous frame's output feeds into the next frame's input.
-- Use for motion blur, echo effects, or dream sequences.
fx_stack:setFeedback(0.85)
print("feedback: 0.85 (previous frame blends in at 85%)")

-- ---- Stub: PostFxStack:getFeedback ----------------------------------------
--@api-stub: PostFxStack:getFeedback
print("feedback: " .. tostring(fx_stack:getFeedback()))

-- ---- Stub: PostFxStack:clearFeedback --------------------------------------
--@api-stub: PostFxStack:clearFeedback
fx_stack:clearFeedback()
print("feedback cleared (no more motion trail)")

-- =============================================================================
-- ImageEffect — apply effects to static images
-- =============================================================================

-- ---- Stub: lurek.effect.newImageEffect ------------------------------------
--@api-stub: lurek.effect.newImageEffect
-- Create an image effect pipeline for screenshot processing or texture generation.
local img_fx = lurek.effect.newImageEffect("assets/screenshots/scene.png")
print("image effect loaded: scene.png")

-- ---- Stub: ImageEffect:addEffect ------------------------------------------
--@api-stub: ImageEffect:addEffect
-- Chain effects on the image.
img_fx:addEffect("blur", { strength = 3 })
img_fx:addEffect("brightness", { value = 1.2 })
img_fx:addEffect("vignette", { strength = 0.5 })
print("3 effects chained: blur -> brightness -> vignette")

-- ---- Stub: ImageEffect:getEffect ------------------------------------------
--@api-stub: ImageEffect:getEffect
local img_e0 = img_fx:getEffect(0)
print("image effect 0: " .. tostring(img_e0))

-- ---- Stub: ImageEffect:removeEffect ---------------------------------------
--@api-stub: ImageEffect:removeEffect
img_fx:removeEffect("blur")
print("blur removed from image pipeline")

-- ---- Stub: ImageEffect:removeByIndex -------------------------------------
--@api-stub: ImageEffect:removeByIndex
img_fx:removeByIndex(0)
print("effect at index 0 removed")

-- ---- Stub: ImageEffect:removeByName ---------------------------------------
--@api-stub: ImageEffect:removeByName
img_fx:removeByName("vignette")
print("vignette removed by name")

-- ---- Stub: ImageEffect:clearEffects ---------------------------------------
--@api-stub: ImageEffect:clearEffects
img_fx:clearEffects()
print("all image effects cleared")

-- ---- Stub: ImageEffect:clear ----------------------------------------------
--@api-stub: ImageEffect:clear
img_fx:clear()
print("image effect pipeline fully reset")

-- ---- Stub: ImageEffect:effectCount ----------------------------------------
--@api-stub: ImageEffect:effectCount
print("image effects: " .. tostring(img_fx:effectCount()))

-- ---- Stub: ImageEffect:getEffectCount -------------------------------------
--@api-stub: ImageEffect:getEffectCount
print("image effect count: " .. tostring(img_fx:getEffectCount()))

-- ---- Stub: ImageEffect:clone ----------------------------------------------
--@api-stub: ImageEffect:clone
-- Clone the pipeline for A/B comparison testing.
local img_fx_copy = img_fx:clone()
print("image effect pipeline cloned")

-- ---- Stub: ImageEffect:save -----------------------------------------------
--@api-stub: ImageEffect:save
-- Apply all effects and save the result to a file.
img_fx:save("output/processed_scene.png")
print("processed image saved: output/processed_scene.png")

-- ---- Stub: ImageEffect:type -----------------------------------------------
--@api-stub: ImageEffect:type
-- ---- Stub: ImageEffect:typeOf ---------------------------------------------
--@api-stub: ImageEffect:typeOf
print("img_fx type: " .. tostring(img_fx:type()))
print("img_fx typeOf: " .. tostring(img_fx:typeOf("ImageEffect")))

-- =============================================================================
-- Overlay — weather, day/night, screen shake, flash, fog
-- =============================================================================

-- ---- Stub: lurek.effect.newOverlay ----------------------------------------
--@api-stub: lurek.effect.newOverlay
-- Create a full-screen overlay for weather, lighting, and camera effects.
local overlay = lurek.effect.newOverlay(800, 600)
print("overlay created: 800x600")

-- ---- Stub: Overlay:update -------------------------------------------------
--@api-stub: Overlay:update
overlay:update(0.016)
print("overlay updated (16ms frame)")

-- ---- Stub: Overlay:isActive -----------------------------------------------
--@api-stub: Overlay:isActive
print("overlay active: " .. tostring(overlay:isActive()))

-- ---- Stub: Overlay:clear --------------------------------------------------
--@api-stub: Overlay:clear
overlay:clear()
print("overlay cleared (all effects reset)")

-- ---- Stub: Overlay:resize -------------------------------------------------
--@api-stub: Overlay:resize
overlay:resize(1280, 720)
print("overlay resized to 1280x720")

-- ---- Stub: Overlay:getWidth -----------------------------------------------
--@api-stub: Overlay:getWidth
print("overlay width: " .. overlay:getWidth())

-- ---- Stub: Overlay:getHeight ----------------------------------------------
--@api-stub: Overlay:getHeight
print("overlay height: " .. overlay:getHeight())

-- ---- Stub: Overlay:getDimensions ------------------------------------------
--@api-stub: Overlay:getDimensions
local ow, oh = overlay:getDimensions()
print("overlay dimensions: " .. ow .. "x" .. oh)

-- Ambient lighting (day/night cycle)

-- ---- Stub: Overlay:setAmbientEnabled --------------------------------------
--@api-stub: Overlay:setAmbientEnabled
overlay:setAmbientEnabled(true)
print("ambient lighting enabled")

-- ---- Stub: Overlay:isAmbientEnabled ---------------------------------------
--@api-stub: Overlay:isAmbientEnabled
print("ambient enabled: " .. tostring(overlay:isAmbientEnabled()))

-- ---- Stub: Overlay:getAmbientColor ----------------------------------------
--@api-stub: Overlay:getAmbientColor
local ar, ag, ab, aa = overlay:getAmbientColor()
print("ambient color: (" .. ar .. "," .. ag .. "," .. ab .. ")")

-- ---- Stub: Overlay:setTimeOfDay -------------------------------------------
--@api-stub: Overlay:setTimeOfDay
-- Set time as 0.0-1.0 where 0.0=midnight, 0.5=noon, 1.0=midnight.
overlay:setTimeOfDay(0.75)
print("time of day: 0.75 (dusk — golden hour)")

-- ---- Stub: Overlay:getTimeOfDay -------------------------------------------
--@api-stub: Overlay:getTimeOfDay
print("time: " .. string.format("%.2f", overlay:getTimeOfDay()))

-- Fog

-- ---- Stub: Overlay:setFogEnabled ------------------------------------------
--@api-stub: Overlay:setFogEnabled
overlay:setFogEnabled(true)
print("fog enabled (eerie swamp atmosphere)")

-- ---- Stub: Overlay:isFogEnabled -------------------------------------------
--@api-stub: Overlay:isFogEnabled
print("fog enabled: " .. tostring(overlay:isFogEnabled()))

-- ---- Stub: Overlay:setFogDensity ------------------------------------------
--@api-stub: Overlay:setFogDensity
overlay:setFogDensity(0.6)
print("fog density: 0.6 (thick fog, low visibility)")

-- ---- Stub: Overlay:getFogDensity ------------------------------------------
--@api-stub: Overlay:getFogDensity
print("fog density: " .. tostring(overlay:getFogDensity()))

-- ---- Stub: Overlay:getFogColor --------------------------------------------
--@api-stub: Overlay:getFogColor
local fogr, fogg, fogb, foga = overlay:getFogColor()
print("fog color: (" .. fogr .. "," .. fogg .. "," .. fogb .. ")")

-- Heat haze

-- ---- Stub: Overlay:setHeatHazeEnabled -------------------------------------
--@api-stub: Overlay:setHeatHazeEnabled
overlay:setHeatHazeEnabled(true)
print("heat haze enabled (desert/lava area)")

-- ---- Stub: Overlay:isHeatHazeEnabled --------------------------------------
--@api-stub: Overlay:isHeatHazeEnabled
print("heat haze: " .. tostring(overlay:isHeatHazeEnabled()))

-- ---- Stub: Overlay:setHeatHazeIntensity -----------------------------------
--@api-stub: Overlay:setHeatHazeIntensity
overlay:setHeatHazeIntensity(0.3)
print("heat haze intensity: 0.3 (subtle shimmer)")

-- ---- Stub: Overlay:getHeatHazeIntensity -----------------------------------
--@api-stub: Overlay:getHeatHazeIntensity
print("heat haze: " .. tostring(overlay:getHeatHazeIntensity()))

-- Vignette

-- ---- Stub: Overlay:setVignetteEnabled -------------------------------------
--@api-stub: Overlay:setVignetteEnabled
overlay:setVignetteEnabled(true)
print("vignette enabled (cinematic frame)")

-- ---- Stub: Overlay:isVignetteEnabled --------------------------------------
--@api-stub: Overlay:isVignetteEnabled
print("vignette: " .. tostring(overlay:isVignetteEnabled()))

-- ---- Stub: Overlay:setVignetteStrength ------------------------------------
--@api-stub: Overlay:setVignetteStrength
-- Stronger when player is hurt, lighter during exploration.
overlay:setVignetteStrength(0.4)
print("vignette strength: 0.4 (subtle)")

-- ---- Stub: Overlay:getVignetteStrength ------------------------------------
--@api-stub: Overlay:getVignetteStrength
print("vignette: " .. tostring(overlay:getVignetteStrength()))

-- Film grain

-- ---- Stub: Overlay:setFilmGrainEnabled ------------------------------------
--@api-stub: Overlay:setFilmGrainEnabled
overlay:setFilmGrainEnabled(true)
print("film grain enabled (horror atmosphere)")

-- ---- Stub: Overlay:isFilmGrainEnabled -------------------------------------
--@api-stub: Overlay:isFilmGrainEnabled
print("film grain: " .. tostring(overlay:isFilmGrainEnabled()))

-- ---- Stub: Overlay:setFilmGrainIntensity ----------------------------------
--@api-stub: Overlay:setFilmGrainIntensity
overlay:setFilmGrainIntensity(0.15)
print("film grain intensity: 0.15 (subtle noise)")

-- ---- Stub: Overlay:getFilmGrainIntensity ----------------------------------
--@api-stub: Overlay:getFilmGrainIntensity
print("grain: " .. tostring(overlay:getFilmGrainIntensity()))

-- Cloud shadows

-- ---- Stub: Overlay:setCloudShadows ----------------------------------------
--@api-stub: Overlay:setCloudShadows
overlay:setCloudShadows(true)
print("cloud shadows enabled (overworld ambiance)")

-- ---- Stub: Overlay:isCloudShadowsEnabled ----------------------------------
--@api-stub: Overlay:isCloudShadowsEnabled
print("cloud shadows: " .. tostring(overlay:isCloudShadowsEnabled()))

-- ---- Stub: Overlay:setCloudCount ------------------------------------------
--@api-stub: Overlay:setCloudCount
overlay:setCloudCount(12)
print("cloud count: 12")

-- ---- Stub: Overlay:getCloudCount ------------------------------------------
--@api-stub: Overlay:getCloudCount
print("clouds: " .. tostring(overlay:getCloudCount()))

-- ---- Stub: Overlay:setCloudSpeed ------------------------------------------
--@api-stub: Overlay:setCloudSpeed
overlay:setCloudSpeed(0.3)
print("cloud speed: 0.3 (gentle drift)")

-- ---- Stub: Overlay:getCloudSpeed ------------------------------------------
--@api-stub: Overlay:getCloudSpeed
print("cloud speed: " .. tostring(overlay:getCloudSpeed()))

-- ---- Stub: Overlay:setCloudScale ------------------------------------------
--@api-stub: Overlay:setCloudScale
overlay:setCloudScale(2.0)
print("cloud scale: 2.0 (large puffy clouds)")

-- ---- Stub: Overlay:getCloudScale ------------------------------------------
--@api-stub: Overlay:getCloudScale
print("cloud scale: " .. tostring(overlay:getCloudScale()))

-- ---- Stub: Overlay:setCloudOpacity ----------------------------------------
--@api-stub: Overlay:setCloudOpacity
overlay:setCloudOpacity(0.5)
print("cloud opacity: 0.5 (semi-transparent shadows)")

-- ---- Stub: Overlay:getCloudOpacity ----------------------------------------
--@api-stub: Overlay:getCloudOpacity
print("cloud opacity: " .. tostring(overlay:getCloudOpacity()))

-- Weather system

-- ---- Stub: Overlay:setWeatherEnabled --------------------------------------
--@api-stub: Overlay:setWeatherEnabled
overlay:setWeatherEnabled(true)
print("weather enabled")

-- ---- Stub: Overlay:isWeatherEnabled ---------------------------------------
--@api-stub: Overlay:isWeatherEnabled
print("weather: " .. tostring(overlay:isWeatherEnabled()))

-- ---- Stub: Overlay:setWeather ---------------------------------------------
--@api-stub: Overlay:setWeather
-- Weather types: "rain", "snow", "ash", "sandstorm", "fireflies", "leaves".
overlay:setWeather("rain")
print("weather: rain (forest ambiance)")

-- ---- Stub: Overlay:getWeather ---------------------------------------------
--@api-stub: Overlay:getWeather
print("weather type: " .. tostring(overlay:getWeather()))

-- ---- Stub: Overlay:setWeatherIntensity ------------------------------------
--@api-stub: Overlay:setWeatherIntensity
-- 0.0=drizzle, 1.0=downpour.
overlay:setWeatherIntensity(0.7)
print("rain intensity: 0.7 (heavy rain)")

-- ---- Stub: Overlay:getWeatherIntensity ------------------------------------
--@api-stub: Overlay:getWeatherIntensity
print("rain intensity: " .. tostring(overlay:getWeatherIntensity()))

-- ---- Stub: Overlay:setWindDirection ---------------------------------------
--@api-stub: Overlay:setWindDirection
-- Wind affects rain angle and cloud movement.
overlay:setWindDirection(0.3)
print("wind direction: 0.3 radians (slight eastward)")

-- ---- Stub: Overlay:getWindDirection ---------------------------------------
--@api-stub: Overlay:getWindDirection
print("wind direction: " .. tostring(overlay:getWindDirection()))

-- ---- Stub: Overlay:setWindSpeed -------------------------------------------
--@api-stub: Overlay:setWindSpeed
overlay:setWindSpeed(2.0)
print("wind speed: 2.0 (moderate)")

-- ---- Stub: Overlay:getWindSpeed -------------------------------------------
--@api-stub: Overlay:getWindSpeed
print("wind speed: " .. tostring(overlay:getWindSpeed()))

-- Lightning & Flash

-- ---- Stub: Overlay:triggerLightning ---------------------------------------
--@api-stub: Overlay:triggerLightning
-- Trigger a lightning flash during a storm. Brief white screen flash + rumble.
overlay:triggerLightning()
print("LIGHTNING! (flash + screen shake)")

-- ---- Stub: Overlay:getLightningColor --------------------------------------
--@api-stub: Overlay:getLightningColor
local ltr, ltg, ltb, lta = overlay:getLightningColor()
print("lightning color: (" .. ltr .. "," .. ltg .. "," .. ltb .. ")")

-- ---- Stub: Overlay:getFlashAlpha ------------------------------------------
--@api-stub: Overlay:getFlashAlpha
print("flash alpha: " .. string.format("%.2f", overlay:getFlashAlpha()))

-- ---- Stub: Overlay:getLightningAlpha --------------------------------------
--@api-stub: Overlay:getLightningAlpha
print("lightning alpha: " .. string.format("%.2f", overlay:getLightningAlpha()))

-- ---- Stub: Overlay:isFlashing ---------------------------------------------
--@api-stub: Overlay:isFlashing
print("flashing: " .. tostring(overlay:isFlashing()))

-- Screen shake

-- ---- Stub: Overlay:shake --------------------------------------------------
--@api-stub: Overlay:shake
-- Screen shake: intensity 5px, duration 0.3s. Use on explosions or impacts.
overlay:shake(5.0, 0.3)
print("screen shake: 5px intensity, 0.3s duration")

-- ---- Stub: Overlay:isShaking ----------------------------------------------
--@api-stub: Overlay:isShaking
print("shaking: " .. tostring(overlay:isShaking()))

-- ---- Stub: Overlay:getShakeOffset ----------------------------------------
--@api-stub: Overlay:getShakeOffset
local shake_x, shake_y = overlay:getShakeOffset()
print("shake offset: (" .. tostring(shake_x) .. ", " .. tostring(shake_y) .. ")")

-- Fade

-- ---- Stub: Overlay:isFading -----------------------------------------------
--@api-stub: Overlay:isFading
print("fading: " .. tostring(overlay:isFading()))

-- Rendering

-- ---- Stub: Overlay:render -------------------------------------------------
--@api-stub: Overlay:render
-- Draw the overlay on top of the game scene. Call in lurek.render_ui().
overlay:render()
print("overlay rendered to screen")

-- ---- Stub: Overlay:drawToImage --------------------------------------------
--@api-stub: Overlay:drawToImage
overlay:drawToImage("output/overlay_preview.png")
print("overlay exported to PNG")

-- ---- Stub: Overlay:setCustomShader ----------------------------------------
--@api-stub: Overlay:setCustomShader
-- Replace the overlay's fragment shader with a custom one.
overlay:setCustomShader("assets/shaders/custom_overlay.wgsl")
print("custom overlay shader loaded")

-- ---- Stub: Overlay:getWater -----------------------------------------------
--@api-stub: Overlay:getWater
-- Get the water surface effect object for further configuration.
local water = overlay:getWater()
print("water effect: " .. tostring(water))

-- ---- Stub: Overlay:type ---------------------------------------------------
--@api-stub: Overlay:type
-- ---- Stub: Overlay:typeOf -------------------------------------------------
--@api-stub: Overlay:typeOf
print("overlay type: " .. tostring(overlay:type()))
print("overlay typeOf: " .. tostring(overlay:typeOf("Overlay")))

-- =============================================================================
-- Transitions — scene-change effects (mlua class)
-- =============================================================================

-- ---- Stub: lurek.effect.newTransition -------------------------------------
--@api-stub: lurek.effect.newTransition
-- Create a screen transition for scene changes.
-- Types: "fade", "dissolve", "wipe_left", "wipe_right", "circle_close", "pixelate".
local fade = lurek.effect.newTransition("fade", { duration = 1.0 })
local dissolve = lurek.effect.newTransition("dissolve", { duration = 0.8 })
print("transitions: fade (1.0s), dissolve (0.8s)")

-- ---- Stub: mlua:play ------------------------------------------------------
--@api-stub: mlua:play
-- Start the transition animation (forward direction).
fade:play()
print("fade transition playing (screen going dark)")

-- ---- Stub: mlua:reverse ---------------------------------------------------
--@api-stub: mlua:reverse
-- Play in reverse (e.g. fade-in after scene load).
fade:reverse()
print("fade reversing (screen brightening)")

-- ---- Stub: mlua:update ----------------------------------------------------
--@api-stub: mlua:update
-- Tick the transition timer. Call every frame.
fade:update(0.016)
print("transition updated (16ms)")

-- ---- Stub: mlua:progress --------------------------------------------------
--@api-stub: mlua:progress
-- Get current progress (0.0 = start, 1.0 = complete).
local prog = fade:progress()
print("transition progress: " .. string.format("%.1f%%", prog * 100))

-- ---- Stub: mlua:isActive --------------------------------------------------
--@api-stub: mlua:isActive
print("transition active: " .. tostring(fade:isActive()))

-- ---- Stub: mlua:isDone ----------------------------------------------------
--@api-stub: mlua:isDone
-- Check if the transition completed (for loading the next scene).
if fade:isDone() then
    print("transition done — safe to switch scene")
end

-- ---- Stub: mlua:kind ------------------------------------------------------
--@api-stub: mlua:kind
-- Get the transition type name.
print("transition kind: " .. fade:kind())
print("dissolve kind: " .. dissolve:kind())

-- ---- Stub: mlua:color -----------------------------------------------------
--@api-stub: mlua:color
-- Get the transition's base color.
local cr, cg, cb, ca = fade:color()
print("fade color: (" .. tostring(cr) .. "," .. tostring(cg) .. "," .. tostring(cb) .. ")")

-- ---- Stub: mlua:setColor --------------------------------------------------
--@api-stub: mlua:setColor
-- Change transition color (e.g. red flash for damage, white for teleport).
fade:setColor(0.1, 0.0, 0.0, 1.0)
print("fade color: dark red (damage transition)")

-- ---- Stub: mlua:type ------------------------------------------------------
--@api-stub: mlua:type
-- ---- Stub: mlua:typeOf ----------------------------------------------------
--@api-stub: mlua:typeOf
print("transition type: " .. tostring(fade:type()))
print("transition typeOf: " .. tostring(fade:typeOf("Transition")))

print("\n-- effect.lua example complete --")
