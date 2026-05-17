-- content/examples/effect.lua
-- lurek.effect API examples: post-processing, overlays, transitions, and image effects.
-- Run: cargo run -- content/examples/effect.lua

-- =============================================================================
-- Module-level constructors
-- =============================================================================

--@api-stub: lurek.effect.newEffect
-- Creates a built-in post-processing effect by type name
do
  -- newEffect() is the primary way to create post-processing effects.
  -- Pass a built-in type name like "bloom", "crt", "vignette", "blur", etc.
  -- The returned handle lets you configure shader parameters before adding
  -- the effect to a post-processing stack.
  local bloom = lurek.effect.newEffect("bloom")

  -- Configure the bloom: threshold controls which pixels glow (higher = only
  -- very bright areas), intensity controls how strong the glow appears.
  bloom:setThreshold(0.6)
  bloom:setIntensity(1.5)

  -- Useful to verify whether an effect is engine-built-in vs. custom shader.
  -- Built-in effects can be serialized by name alone in save files.
  lurek.log.info("bloom built-in=" .. tostring(bloom:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newCustomEffect
-- Creates a custom post-processing effect that references an existing shader id
do
  -- When the built-in effects are not enough, use a custom WGSL shader.
  -- First create the shader via lurek.render.newShader(), then pass the
  -- returned shader id here. The custom effect exposes the same parameter
  -- interface so it can be used interchangeably in stacks.
  local shader_id = 7  -- shader handle obtained from lurek.render.newShader()
  local glitch = lurek.effect.newCustomEffect(shader_id)

  -- Custom effects accept arbitrary named parameters passed to the shader
  -- through the PostFxParams uniform buffer (p[0]..p[2] slots).
  glitch:setParameter("intensity", 0.4)
  glitch:setParameter("block_size", 8.0)

  -- Custom effects report isBuiltIn() == false, which means you need to
  -- ship the shader source alongside any save data referencing them.
  lurek.log.info("custom fx built-in=" .. tostring(glitch:isBuiltIn()), "fx")
end

--@api-stub: lurek.effect.newStack
-- Creates a post-processing stack using optional dimensions or the current window size
do
  -- A stack is an ordered pipeline of effects applied to the framebuffer.
  -- The capture/apply pattern: beginCapture() → draw your scene → endCapture() → apply().
  -- Optional width/height set the render target size; omit to use window size.
  local stack = lurek.effect.newStack()

  -- Effects are processed in the order they are added. Here bloom brightens
  -- highlights first, then vignette darkens edges for a cinematic look.
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))

  lurek.log.info("stack ready w=" .. stack:getWidth() .. " h=" .. stack:getHeight(), "fx")
end

--@api-stub: lurek.effect.newPresetStack
-- Creates a named preset post-processing stack with optional dimensions
do
  -- Preset stacks bundle multiple effects under a single name for common looks.
  -- "retro_tv" might include CRT scanlines, chromatic aberration, and vignette.
  -- Pass explicit dimensions when your game renders at a fixed internal resolution.
  local crt = lurek.effect.newPresetStack("retro_tv", 1280, 720)

  -- Typical draw loop: capture all scene drawing, then apply the full chain.
  function lurek.draw()
    crt:beginCapture()
    -- All lurek.render calls here are captured into the effect framebuffer.
    crt:endCapture()
    crt:apply()  -- Renders the processed result to the screen.
  end
end

--@api-stub: lurek.effect.newPass
-- Creates a custom post-processing pass from an existing shader id
do
  -- newPass() is an alias for newCustomEffect() — both create a custom
  -- shader-based effect. Use whichever name reads better in your code.
  local shader_id = 3  -- a shader for edge-detection outlines
  local edge_pass = lurek.effect.newPass(shader_id)

  -- Set shader parameters that control the edge detection sensitivity.
  edge_pass:setParameter("threshold", 0.2)
  edge_pass:setParameter("line_width", 1.5)

  lurek.log.debug("pass enabled=" .. tostring(edge_pass:isEnabled()), "fx")
end

--@api-stub: lurek.effect.getEffectTypes
-- Returns all built-in post-processing effect type names
do
  -- Use this to discover available built-in effects at runtime.
  -- Useful for debug menus, effect browsers, or validation.
  -- Built-in types include: bloom, blur, crt, godrays, vignette,
  -- colourgrade, chromatic, pixelate, sepia, grayscale, invert,
  -- scanlines, edge_detect, hue_shift, noise, depth_of_field,
  -- motion_blur, palette_swap, color_lut, water_distort, sharpen,
  -- dither, outline.
  local types = lurek.effect.getEffectTypes()
  for i, name in ipairs(types) do
    lurek.log.info("[" .. i .. "] " .. name, "fx-types")
  end
end

--@api-stub: lurek.effect.newImageEffect
-- Creates an image effect chain from no arguments, a type name and optional parameters, or a chain table
do
  -- Image effect chains apply post-processing to individual Image objects
  -- rather than the full screen. Three creation patterns:
  --   newImageEffect()                  — empty chain, add effects later
  --   newImageEffect("blur", {radius=3})— single effect with params
  --   newImageEffect({...})             — array of effect entries

  -- Array form: each entry has a "type" and optional parameter fields.
  -- This is ideal for defining a fixed look (e.g. a "polaroid" filter).
  local chain = lurek.effect.newImageEffect({
    { type = "blur", radius = 3.0 },
    { type = "vignette", strength = 0.4 },
  })

  -- The chain can later be applied to an Image to produce a processed copy.
  lurek.log.info("image chain count=" .. chain:effectCount(), "fx")
end

--@api-stub: lurek.effect.newOverlay
-- Creates an overlay controller for screen effects using optional dimensions
do
  -- Overlays handle screen-level visual effects that are NOT shader-based:
  -- screen shake, flash, fade, weather particles, fog, ambient color,
  -- film grain, vignette, heat haze, cloud shadows, water distortion.
  -- They update every frame and render on top of the scene.
  local overlay = lurek.effect.newOverlay(1280, 720)

  -- Set up a rainy atmosphere: weather particles + fog + wind.
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
  overlay:setWeatherIntensity(0.7)
  overlay:setWindSpeed(60.0)
  overlay:setWindDirection(math.pi * 0.75)  -- blowing left

  -- The overlay MUST be updated every frame to advance animations.
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: lurek.effect.newTransition
-- Creates a timed screen transition with optional kind, duration, and color
do
  -- Screen transitions are timed full-screen effects for scene changes.
  -- Kinds: "fade", "wipe", "iris", "dissolve", etc.
  -- Duration is in seconds. Color is an RGBA table for the transition fill.
  local trans = lurek.effect.newTransition("wipe", 0.75, {0, 0, 0, 1})

  -- Call play() to start forward, reverse() to go backward.
  trans:play()

  -- update(dt) returns true while the transition is still active.
  -- Once it returns false (or isDone() is true), the scene switch is safe.
  function lurek.process(dt)
    if trans:update(dt) then
      lurek.log.debug("trans p=" .. string.format("%.2f", trans:progress()), "fx")
    end
  end
end

--@api-stub: lurek.effect.setShaderErrorDisplay
-- Enables or disables renderer shader error display overlays
do
  -- During development, enable this to see shader compilation errors
  -- rendered directly on screen as a pink overlay with error text.
  -- Disable for release builds to avoid exposing internals to players.
  local in_dev = true
  lurek.effect.setShaderErrorDisplay(in_dev)
  lurek.log.info("shader err display=" .. tostring(in_dev), "fx-dev")
end

--@api-stub: lurek.effect.getShaderErrorDisplay
-- Returns whether renderer shader error display overlays are enabled
do
  -- Check this before shipping to ensure the debug overlay is off.
  if lurek.effect.getShaderErrorDisplay() then
    lurek.log.warn("dev shader error overlay is ON - disable for shipping", "fx-dev")
  end
end

-- =============================================================================
-- PostFxEffect methods
-- =============================================================================

--@api-stub: LPostFxEffect:getTypeName
-- Returns the type name of this post fx effect.
do
  -- getTypeName() returns the effect type string (e.g. "bloom", "crt").
  -- Use this for serialization, debug display, or dynamic effect menus.
  local eff = lurek.effect.newEffect("crt")
  local name = eff:getTypeName()
  lurek.log.info("active fx: " .. name, "fx")
end

--@api-stub: LPostFxEffect:isBuiltIn
-- Returns true if this post fx effect built in.
do
  -- Built-in effects can be recreated from just their type name.
  -- Custom shader effects need additional data (the shader source).
  -- Use this to decide how to serialize an effect chain to a save file.
  local eff = lurek.effect.newEffect("vignette")
  if eff:isBuiltIn() then
    lurek.log.info("safe to serialise '" .. eff:getTypeName() .. "' by name", "fx")
  end
end

--@api-stub: LPostFxStack:isEnabled
-- Returns true if this post fx effect is currently enabled.
do
  -- Effects can be toggled without removing them from the stack.
  -- This is cheaper than add/remove for effects you toggle often
  -- (e.g. bloom off during inventory screens for clarity).
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setEnabled(false)
  if not bloom:isEnabled() then
    lurek.log.debug("bloom currently muted", "fx")
  end
end

--@api-stub: LPostFxStack:setEnabled
-- Sets whether this post fx effect is enabled and accepts input.
do
  -- Toggle effects on/off based on game state.
  -- Example: disable heavy CRT filter on low-end hardware.
  local crt = lurek.effect.newEffect("crt")
  local low_quality = true
  crt:setEnabled(not low_quality)
end

--@api-stub: LPostFxEffect:setParameter
-- Sets the parameter of this post fx effect.
do
  -- setParameter() is the generic way to set any shader uniform.
  -- Built-in effects expose named parameters like "threshold", "intensity",
  -- "radius", "strength", etc. Custom shaders can use any name.
  -- Parameters map to the PostFxParams uniform buffer in the shader.
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setParameter("threshold", 0.5)
  bloom:setParameter("intensity", 1.2)
  lurek.log.debug("bloom configured", "fx")
end

--@api-stub: LPostFxEffect:hasParameter
-- Returns true if this post fx effect has a parameter.
do
  -- Check before setting to avoid silent no-ops or catch typos.
  -- Useful when building generic effect editors or loading presets
  -- where parameter names come from user data.
  local eff = lurek.effect.newEffect("crt")
  if eff:hasParameter("scanline_strength") then
    eff:setParameter("scanline_strength", 0.7)
  end
end

--@api-stub: LPostFxEffect:getParameterNames
-- Returns the parameter names of this post fx effect.
do
  -- Enumerate all tunable parameters for an effect.
  -- Use this to build dynamic UI sliders or dump effect state.
  local eff = lurek.effect.newEffect("colourgrade")
  for _, name in ipairs(eff:getParameterNames()) do
    lurek.log.info("colourgrade param: " .. name, "fx-edit")
  end
end

--@api-stub: LPostFxEffect:getEffectType
-- Returns the effect type of this post fx effect.
do
  -- getEffectType() returns the renderer-level type name.
  -- For built-in effects this matches getTypeName().
  local eff = lurek.effect.newEffect("sepia")
  local kind = eff:getEffectType()
  lurek.log.info("kind=" .. kind, "fx")
end

--@api-stub: LPostFxEffect:getType
-- Returns the type of this post fx effect.
do
  -- getType() is equivalent to getEffectType() — use whichever reads
  -- better in your code.
  local eff = lurek.effect.newEffect("invert")
  if eff:getType() == "invert" then
    lurek.log.debug("invert pass detected", "fx")
  end
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name string for this post fx effect handle.
do
  -- type() returns the Lua object type string "PostFxEffect" — not the
  -- effect's renderer type. Use getTypeName() for the effect identity.
  local eff = lurek.effect.newEffect("bloom")
  lurek.log.debug("handle type: " .. eff:type(), "fx")
end

--@api-stub: LScreenTransition:typeOf
-- Returns true if this post fx effect handle matches the given type name string.
do
  -- typeOf() checks Lua type inheritance. All handles inherit from "Object".
  -- Use this for polymorphic code that handles multiple effect handle types.
  local eff = lurek.effect.newEffect("blur")
  if eff:typeOf("Object") then
    lurek.log.debug("eff inherits from Object", "fx")
  end
end

--@api-stub: LPostFxEffect:setThreshold
-- Sets the threshold of this post fx effect.
do
  -- Threshold controls which pixels pass through to the effect.
  -- For bloom: only pixels brighter than threshold will glow.
  -- Range 0.0-1.0; lower = more glow, higher = only brightest spots.
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setThreshold(0.75)
  lurek.log.debug("bloom threshold set", "fx")
end

--@api-stub: LPostFxEffect:setIntensity
-- Sets the intensity of this post fx effect.
do
  -- Intensity is a multiplier for the effect strength.
  -- For godrays: higher values produce stronger light shafts.
  -- Typical range 0.0-3.0; values above 1.0 amplify the effect.
  local godrays = lurek.effect.newEffect("godrays")
  godrays:setIntensity(1.4)
end

--@api-stub: LPostFxEffect:setRadius
-- Sets the radius of this post fx effect.
do
  -- Radius controls the spread area of the effect in pixels.
  -- For blur: larger radius = stronger blur but higher GPU cost.
  -- Keep moderate (1-8) for real-time; use larger for static images.
  local blur = lurek.effect.newEffect("blur")
  blur:setRadius(4.0)
end

--@api-stub: LPostFxEffect:setStrength
-- Sets the strength of this post fx effect.
do
  -- Strength is a 0.0-1.0 normalized intensity for effects that use it.
  -- For vignette: 0.0 = no darkening, 1.0 = maximum edge darkening.
  -- Clamp user input to [0,1] to prevent visual artifacts.
  local vig = lurek.effect.newEffect("vignette")
  local from_slider = 0.6
  vig:setStrength(math.max(0.0, math.min(1.0, from_slider)))
end

--@api-stub: LPostFxEffect:setScanlineStrength
-- Sets the scanline strength of this post fx effect.
do
  -- CRT scanlines simulate old TV displays. Strength 0.0-1.0 controls
  -- how visible the horizontal lines are. Combine with setIntensity()
  -- for the overall CRT phosphor glow.
  local crt = lurek.effect.newEffect("crt")
  crt:setScanlineStrength(0.35)
  crt:setIntensity(1.0)
end

--@api-stub: LPostFxEffect:setOffset
-- Sets the offset of this post fx effect.
do
  -- Chromatic aberration splits color channels by an offset in pixels.
  -- Small values (1-3) add subtle realism; large values (5+) give a
  -- glitch/VHS look. Great combined with screen shake on impact.
  local chroma = lurek.effect.newEffect("chromatic")
  chroma:setOffset(2.0)
end

--@api-stub: LPostFxEffect:setBrightness
-- Sets the brightness of this post fx effect.
do
  -- Brightness is an additive shift applied to all pixels.
  -- Range roughly -0.5 to +0.5. Negative = darker, positive = lighter.
  -- Use with colourgrade for day/night transitions or flash effects.
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setBrightness(0.05)
end

--@api-stub: LPostFxEffect:setContrast
-- Sets the contrast of this post fx effect.
do
  -- Contrast multiplier: 1.0 = normal, <1.0 = washed out, >1.0 = punchy.
  -- Good for making pixel art pop (1.1-1.2) or creating dream sequences (<0.9).
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setContrast(1.15)
end

--@api-stub: LPostFxEffect:setSaturation
-- Sets the saturation of this post fx effect.
do
  -- Saturation multiplier: 1.0 = normal, 0.0 = grayscale, >1.0 = vivid.
  -- Desaturate during flashback scenes or when the player is injured.
  local grade = lurek.effect.newEffect("colourgrade")
  grade:setSaturation(0.7)  -- slightly desaturated for a moody atmosphere
end

-- =============================================================================
-- PostFxStack methods
-- =============================================================================

--@api-stub: LPostFxStack:add
-- Adds a post fx effect to this post fx stack.
do
  -- add() appends an effect at the end of the pipeline.
  -- Order matters: effects process left-to-right. Put blur before bloom
  -- for soft glow; put bloom before blur for spread highlights.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack size=" .. stack:getEffectCount(), "fx")
end

--@api-stub: LPostFxStack:remove
-- Removes a post fx effect from this post fx stack.
do
  -- remove() takes the effect handle and removes the first match.
  -- Returns true if found. Use this for dynamic pipelines where
  -- effects are added/removed based on gameplay (e.g. losing CRT
  -- when the player "fixes" the TV in a puzzle game).
  local stack = lurek.effect.newStack()
  local crt = lurek.effect.newEffect("crt")
  stack:add(crt)
  local removed = stack:remove(crt)
  lurek.log.debug("crt removed=" .. tostring(removed), "fx")
end

--@api-stub: LPostFxStack:isEnabled
-- Returns true if this post fx stack slot is currently enabled.
do
  -- Check if a specific slot (1-based position) is enabled.
  -- Disabled slots are skipped during apply() without removing them.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  if stack:isEnabled(1) then
    lurek.log.debug("slot 1 active", "fx")
  end
end

--@api-stub: LImageEffect:getEffectCount
-- Returns the number of effect items in this post fx stack.
do
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("crt"))
  -- Use getEffectCount() to iterate effects by index, build debug
  -- displays, or validate that the stack matches expected configuration.
  for i = 1, stack:getEffectCount() do
    local effect = assert(stack:getEffect(i))
    lurek.log.info("slot " .. i .. " = " .. effect:getTypeName(), "fx")
  end
end

--@api-stub: LImageEffect:getEffect
-- Returns the effect handle at a one-based position in this post fx stack.
do
  -- getEffect() uses 1-based indexing (Lua convention).
  -- Returns nil for out-of-range indices. Use to modify effects
  -- already in the stack without keeping a separate reference.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("vignette"))
  local first = stack:getEffect(1)
  if first then first:setStrength(0.8) end
end

--@api-stub: LPostFxStack:getEnabledEffects
-- Returns the enabled effects of this post fx stack.
do
  -- Returns only effects whose passes are currently enabled.
  -- Useful for debug HUDs showing active effects or for
  -- performance monitoring (count active passes).
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  for _, eff in ipairs(stack:getEnabledEffects()) do
    lurek.log.debug("enabled: " .. eff:getTypeName(), "fx")
  end
end

--@api-stub: LOverlay:getWidth
-- Returns the width of this post fx stack.
do
  -- The stack width is the render target width in pixels.
  -- Verify this matches your game's internal resolution.
  local stack = lurek.effect.newStack(1920, 1080)
  if stack:getWidth() ~= 1920 then
    lurek.log.warn("stack width drift: " .. stack:getWidth(), "fx")
  end
end

--@api-stub: LOverlay:getHeight
-- Returns the height of this post fx stack.
do
  -- Stack height is the render target height. Check this against
  -- minimum requirements for UI rendering above the effect layer.
  local stack = lurek.effect.newStack(1280, 720)
  if stack:getHeight() < 480 then
    lurek.log.warn("stack height too small for HUD layout", "fx")
  end
end

--@api-stub: LOverlay:getDimensions
-- Returns the dimensions of this post fx stack.
do
  -- Returns width, height as two values. Useful for aspect ratio
  -- calculations or passing to overlay/UI systems.
  local stack = lurek.effect.newStack()
  local w, h = stack:getDimensions()
  lurek.log.info("stack target = " .. w .. "x" .. h, "fx")
end

--@api-stub: LOverlay:resize
-- Performs the resize operation on this post fx stack.
do
  -- Call resize() when the window changes size or when switching
  -- between internal resolutions (e.g. settings menu resolution change).
  -- This recreates the render targets at the new dimensions.
  local stack = lurek.effect.newStack(800, 600)
  local new_w, new_h = 1600, 900
  stack:resize(new_w, new_h)
  lurek.log.info("stack resized to " .. new_w .. "x" .. new_h, "fx")
end

--@api-stub: LPostFxStack:len
-- Returns the number of effects in this post fx stack.
do
  -- len() is equivalent to getEffectCount(). Use whichever
  -- reads more naturally in your code.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  lurek.log.debug("stack len=" .. stack:len(), "fx")
end

--@api-stub: LPostFxStack:isEmpty
-- Returns true if this post fx stack contains no items.
do
  -- Check isEmpty() before beginCapture() to skip the capture overhead
  -- when no effects are configured (e.g. "no effects" quality setting).
  local stack = lurek.effect.newStack()
  if stack:isEmpty() then
    lurek.log.debug("post-fx pipeline empty - skipping capture", "fx")
  end
end

--@api-stub: LOverlay:clear
-- Clears all items from this post fx stack.
do
  -- clear() removes all effects and resets pass state.
  -- Use when switching scenes that need completely different effects.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("crt"))
  stack:clear()
  lurek.log.info("pipeline cleared, count=" .. stack:getEffectCount(), "fx")
end

--@api-stub: LPostFxStack:dedup
-- Removes duplicate effect handles from this post fx stack.
do
  -- dedup() removes duplicate references while preserving first occurrences.
  -- This can happen if code accidentally adds the same handle twice.
  -- Returns the number of duplicates removed.
  local stack = lurek.effect.newStack()
  local bloom = lurek.effect.newEffect("bloom")
  stack:add(bloom); stack:add(bloom)
  local removed = stack:dedup()
  lurek.log.info("dedup removed " .. tostring(removed) .. " duplicate slot(s)", "fx")
end

--@api-stub: LPostFxStack:isCapturing
-- Returns true if this post fx stack is currently capturing.
do
  -- isCapturing() returns true between beginCapture() and endCapture().
  -- Use for assertions or to guard against nested captures.
  local stack = lurek.effect.newStack()
  function lurek.draw()
    stack:beginCapture()
    assert(stack:isCapturing(), "post-fx capture should be active here")
    -- Draw scene content here — it goes into the effect framebuffer.
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: LPostFxStack:beginCapture
-- Starts post-effect capture on this post fx stack.
do
  -- beginCapture() redirects all subsequent draw calls into the stack's
  -- internal framebuffer. Everything drawn between begin/end will have
  -- the stack's effects applied when apply() is called.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.draw()
    stack:beginCapture()
    -- All scene rendering (sprites, tilemaps, particles) goes here.
    stack:endCapture(); stack:apply()
  end
end

--@api-stub: LPostFxStack:endCapture
-- Ends post-effect capture on this post fx stack.
do
  -- endCapture() finalizes the captured framebuffer content.
  -- After this call, apply() processes the captured image through
  -- each enabled effect in order and outputs the result.
  local stack = lurek.effect.newStack()
  function lurek.draw()
    stack:beginCapture()
    -- Scene draws happen between begin and end.
    stack:endCapture()
    stack:apply()
  end
end

--@api-stub: LPostFxStack:apply
-- Applies all enabled effects in this post fx stack.
do
  -- apply() runs the full post-processing pipeline on the captured frame.
  -- Call this AFTER endCapture(). The processed result is drawn to screen.
  -- Draw UI elements AFTER apply() so they are not affected by effects.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  function lurek.draw()
    stack:beginCapture(); stack:endCapture()
    stack:apply()
    -- Draw HUD/UI here — not affected by bloom.
  end
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name string for this post fx stack handle.
do
  -- Returns "PostFxStack" — the Lua handle type, not the effect type.
  local stack = lurek.effect.newStack()
  if stack:type() == "PostFxStack" then
    lurek.log.debug("got a real post-fx stack", "fx")
  end
end

--@api-stub: LScreenTransition:typeOf
-- Returns true if this post fx stack handle matches the given type name string.
do
  -- All Lurek handles inherit from "Object".
  local stack = lurek.effect.newStack()
  assert(stack:typeOf("Object"), "PostFxStack should inherit Object")
end

--@api-stub: LPostFxStack:setFeedback
-- Sets the feedback blend factor of this post fx stack.
do
  -- Feedback blends the previous frame's output into the current frame.
  -- Values 0.0-1.0: 0.0 = no trail, 0.85 = strong ghosting/motion trail.
  -- Use for dream sequences, time-slow effects, or ghostly trails.
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.85)
  lurek.log.info("feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: LPostFxStack:getFeedback
-- Returns the feedback blend factor of this post fx stack.
do
  -- Values are clamped to [0.0, 1.0] internally.
  -- Use to display the current feedback level in a debug HUD.
  local stack = lurek.effect.newStack()
  stack:setFeedback(2.0)  -- will be clamped to 1.0
  lurek.log.info("clamped feedback=" .. stack:getFeedback(), "fx")
end

--@api-stub: LPostFxStack:clearFeedback
-- Resets the feedback blend factor to zero.
do
  -- clearFeedback() immediately stops the trail effect.
  -- Call when exiting a dream sequence to snap back to clean rendering.
  local stack = lurek.effect.newStack()
  stack:setFeedback(0.6)
  stack:clearFeedback()
  lurek.log.debug("feedback cleared=" .. stack:getFeedback(), "fx")
end

-- =============================================================================
-- ImageEffect methods
-- =============================================================================

--@api-stub: LImageEffect:addEffect
-- Adds a built-in effect to this image effect chain.
do
  -- addEffect() appends a built-in effect by type name and returns its handle.
  -- Use the handle to configure parameters. This pattern lets you build
  -- image processing chains incrementally (e.g. thumbnail generation).
  local chain = lurek.effect.newImageEffect()
  local blur = chain:addEffect("blur")
  blur:setRadius(2.5)
  lurek.log.info("chain size=" .. chain:effectCount(), "fx")
end

--@api-stub: LImageEffect:getEffect
-- Returns an effect from this image effect chain by index or name.
do
  -- getEffect() accepts a 1-based integer index or a type name string.
  -- Returns nil if not found. Use to modify effects after chain creation.
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }})
  local vig = chain:getEffect("vignette")
  if vig then vig:setStrength(0.5) end
end

--@api-stub: LImageEffect:removeEffect
-- Removes an effect from this image effect chain by index or name.
do
  -- removeEffect() accepts a 1-based index or type name.
  -- Returns true if an effect was removed. Use for dynamic chains
  -- where effects are toggled based on user settings.
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  local removed = chain:removeEffect("blur")
  lurek.log.debug("blur removed=" .. tostring(removed) .. " count=" .. chain:effectCount(), "fx")
end

--@api-stub: LImageEffect:clearEffects
-- Clears all effects from this image effect chain.
do
  -- clearEffects() empties the chain. The handle remains valid and
  -- you can add new effects afterward for a completely different look.
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  chain:clearEffects()
  assert(chain:effectCount() == 0, "chain should be empty")
end

--@api-stub: LOverlay:clear
-- Clears all items from this image effect chain.
do
  -- clear() is equivalent to clearEffects() — use whichever name
  -- reads better in your context.
  local chain = lurek.effect.newImageEffect({{ type = "crt" }})
  chain:clear()
  lurek.log.debug("chain cleared", "fx")
end

--@api-stub: LImageEffect:effectCount
-- Returns the number of effects in this image effect chain.
do
  -- effectCount() and getEffectCount() are equivalent.
  -- Use to check if a chain has any work to do before applying it.
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  if chain:effectCount() > 0 then
    lurek.log.info("image chain has " .. chain:effectCount() .. " passes", "fx")
  end
end

--@api-stub: LImageEffect:getEffectCount
-- Returns the number of effect items in this image effect chain.
do
  local chain = lurek.effect.newImageEffect({{ type = "sepia" }})
  lurek.log.debug("count=" .. chain:getEffectCount(), "fx")
end

--@api-stub: LImageEffect:clone
-- Creates a copy of this image effect chain.
do
  -- clone() duplicates the chain with all effects and their parameters.
  -- Use to create variants from a base look (e.g. "day" vs "night"
  -- versions of the same filter with different brightness/saturation).
  local base = lurek.effect.newImageEffect({{ type = "vignette", strength = 0.4 }})
  local night = base:clone()
  night:addEffect("colourgrade"):setBrightness(-0.1)
end

--@api-stub: LImageEffect:save
-- Saves the current state of this image effect.
do
  -- save() is a placeholder that always returns true.
  -- Future use: persist the chain configuration to disk.
  local chain = lurek.effect.newImageEffect({{ type = "bloom" }})
  if chain:save() then
    lurek.log.debug("image chain save() acknowledged", "fx")
  end
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name string for this image effect handle.
do
  -- Returns "ImageEffect" — the Lua handle type.
  local chain = lurek.effect.newImageEffect()
  if chain:type() == "ImageEffect" then
    lurek.log.debug("per-image chain detected", "fx")
  end
end

--@api-stub: LScreenTransition:typeOf
-- Returns true if this image effect handle matches the given type name string.
do
  local chain = lurek.effect.newImageEffect()
  assert(chain:typeOf("Object"), "ImageEffect should be an Object")
end

--@api-stub: LImageEffect:removeByIndex
-- Removes an effect by zero-based internal index.
do
  -- removeByIndex() uses 0-based indexing (internal engine convention).
  -- This is different from removeEffect() which uses 1-based Lua indexing.
  -- Returns true if the index was valid and an effect was removed.
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "crt" }})
  local removed = chain:removeByIndex(0)  -- removes "blur" (first slot)
  lurek.log.debug("by-index removed=" .. tostring(removed), "fx")
end

--@api-stub: LImageEffect:removeByName
-- Removes the first effect with a matching type name.
do
  -- removeByName() finds and removes the first effect matching the name.
  -- Use when you know the type but not the index.
  local chain = lurek.effect.newImageEffect({{ type = "vignette" }, { type = "sepia" }})
  chain:removeByName("vignette")
  lurek.log.debug("after by-name remove count=" .. chain:effectCount(), "fx")
end

-- =============================================================================
-- Overlay methods
-- =============================================================================

--@api-stub: LScreenTransition:update
-- Advances this overlay by the given delta time.
do
  -- update(dt) MUST be called every frame to advance all overlay animations:
  -- shake decay, flash fade, weather movement, fog animation, etc.
  -- Without this call, overlay effects freeze in their initial state.
  local overlay = lurek.effect.newOverlay()
  function lurek.process(dt)
    overlay:update(dt)
  end
end

--@api-stub: LOverlay:triggerLightning
-- Triggers a lightning flash using the overlay lightning state.
do
  -- triggerLightning() creates a sudden bright flash that decays over time.
  -- The flash color is controlled by setLightningColor().
  -- Use during storm weather for dramatic atmosphere.
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  lurek.log.info("lightning fired alpha=" .. overlay:getLightningAlpha(), "weather")
end

--@api-stub: LOverlay:getShakeOffset
-- Returns the current shake offset of this overlay.
do
  -- getShakeOffset() returns the current x,y pixel displacement.
  -- Apply this to your camera position to create the shake effect.
  -- The offset decays to zero over the shake duration.
  local overlay = lurek.effect.newOverlay()
  overlay:shake(8.0, 0.4)  -- intensity 8px, duration 0.4s
  function lurek.draw()
    local ox, oy = overlay:getShakeOffset()
    -- Use: lurek.render.push(); lurek.render.translate(ox, oy); draw scene; pop()
    lurek.log.debug("shake ox=" .. ox .. " oy=" .. oy, "shake")
  end
end

--@api-stub: LScreenTransition:isActive
-- Returns true if any overlay effect is currently active.
do
  -- isActive() is true when ANY overlay feature is running (shake, flash,
  -- weather, fog, etc). Use to skip overlay:render() when nothing is visible.
  local overlay = lurek.effect.newOverlay()
  if overlay:isActive() then
    function lurek.draw() overlay:render() end
  end
end

--@api-stub: LOverlay:clear
-- Clears all active overlay effects and resets transient state.
do
  -- clear() cancels all in-progress effects (flash, fade, shake) and
  -- resets transient state. Persistent settings (weather type) remain.
  -- Use when teleporting the player to avoid carrying over old effects.
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.5)
  overlay:clear()
  assert(not overlay:isFlashing(), "flash should be cancelled")
end

--@api-stub: LOverlay:resize
-- Resizes the overlay target dimensions.
do
  -- Call resize() when the window or render target changes size.
  -- The overlay adapts its internal buffers to the new dimensions.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:resize(1920, 1080)
  lurek.log.info("overlay resized to " .. overlay:getWidth() .. "x" .. overlay:getHeight(), "fx")
end

--@api-stub: LOverlay:getWidth
-- Returns the width of this overlay.
do
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay w=" .. overlay:getWidth(), "fx")
end

--@api-stub: LOverlay:getHeight
-- Returns the height of this overlay.
do
  local overlay = lurek.effect.newOverlay(1024, 768)
  lurek.log.debug("overlay h=" .. overlay:getHeight(), "fx")
end

--@api-stub: LOverlay:getDimensions
-- Returns the dimensions of this overlay.
do
  -- Returns width, height. Useful to pass to drawToImage() or verify
  -- the overlay matches your game's render resolution.
  local overlay = lurek.effect.newOverlay()
  local w, h = overlay:getDimensions()
  lurek.log.info("overlay = " .. w .. "x" .. h, "fx")
end

--@api-stub: LOverlay:getFlashAlpha
-- Returns the current flash alpha of this overlay.
do
  -- Flash alpha decays from the starting value toward zero over duration.
  -- Read this to sync other effects (e.g. sound volume) with the flash.
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.3)
  function lurek.process(dt)
    overlay:update(dt)
    if overlay:getFlashAlpha() > 0.5 then lurek.log.debug("flash peak", "fx") end
  end
end

--@api-stub: LOverlay:getLightningAlpha
-- Returns the current lightning alpha of this overlay.
do
  -- Lightning alpha spikes to 1.0 on trigger then decays rapidly.
  -- Use to flash environment lights in sync with the overlay.
  local overlay = lurek.effect.newOverlay()
  overlay:triggerLightning()
  function lurek.process(dt)
    overlay:update(dt)
    local a = overlay:getLightningAlpha()
    if a > 0.0 then lurek.log.debug("lightning a=" .. a, "fx") end
  end
end

--@api-stub: LOverlay:setAmbientEnabled
-- Enables or disables overlay ambient color rendering.
do
  -- Ambient color tints the entire scene (like time-of-day lighting).
  -- Enable it, then set the time or color manually.
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(20.0)  -- evening warm tint
end

--@api-stub: LOverlay:isAmbientEnabled
-- Returns true if overlay ambient color rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isAmbientEnabled() then
    lurek.log.debug("ambient layer is live", "fx")
  end
end

--@api-stub: LOverlay:getAmbientColor
-- Returns the ambient color RGBA of this overlay.
do
  -- Returns r, g, b, a. The ambient color is either computed from
  -- time-of-day or set manually via setAmbientColor().
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  local r, g, b, a = overlay:getAmbientColor()
  lurek.log.info(string.format("ambient %.2f %.2f %.2f a=%.2f", r, g, b, a), "fx")
end

--@api-stub: LOverlay:setTimeOfDay
-- Sets the time-of-day value used by ambient effects.
do
  -- Time-of-day is a float (0-24 hours) that drives the ambient color
  -- curve: dawn warm, midday bright, dusk orange, night blue.
  local overlay = lurek.effect.newOverlay()
  overlay:setAmbientEnabled(true)
  overlay:setTimeOfDay(7.5)  -- early morning
end

--@api-stub: LOverlay:getTimeOfDay
-- Returns the current time-of-day value of this overlay.
do
  -- Use to drive gameplay logic (e.g. spawn nighttime enemies).
  local overlay = lurek.effect.newOverlay()
  overlay:setTimeOfDay(18.0)
  if overlay:getTimeOfDay() > 18.0 then
    lurek.log.info("dusk - enable street lamps", "world")
  end
end

--@api-stub: LOverlay:setFogEnabled
-- Enables or disables overlay fog rendering.
do
  -- Fog renders a colored overlay that simulates distance fog or mist.
  -- Combine with density and color for atmospheric depth.
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  overlay:setFogDensity(0.4)
end

--@api-stub: LOverlay:isFogEnabled
-- Returns true if overlay fog rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if not overlay:isFogEnabled() then
    overlay:setFogEnabled(true)
  end
end

--@api-stub: LOverlay:setFogDensity
-- Sets the fog density of this overlay.
do
  -- Density 0.0-1.0: higher = thicker fog, less scene visibility.
  -- Animate this for rolling fog effects.
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local target = 0.6
  overlay:setFogDensity(target)
end

--@api-stub: LOverlay:getFogDensity
-- Returns the fog density of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFogDensity(0.3)
  lurek.log.debug("fog density=" .. overlay:getFogDensity(), "fx")
end

--@api-stub: LOverlay:getFogColor
-- Returns the fog RGBA color of this overlay.
do
  -- Default fog is usually white/gray. Set color to match your scene:
  -- green for swamp, blue for underwater, red for volcanic.
  local overlay = lurek.effect.newOverlay()
  overlay:setFogEnabled(true)
  local r, g, b = overlay:getFogColor()
  lurek.log.info(string.format("fog rgb %.2f %.2f %.2f", r, g, b), "fx")
end

--@api-stub: LOverlay:setHeatHazeEnabled
-- Enables or disables overlay heat haze rendering.
do
  -- Heat haze simulates air distortion above hot surfaces.
  -- Great for desert scenes, furnaces, or fire.
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  overlay:setHeatHazeIntensity(0.5)
end

--@api-stub: LOverlay:isHeatHazeEnabled
-- Returns true if overlay heat haze rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isHeatHazeEnabled() then
    lurek.log.debug("heat haze on", "fx")
  end
end

--@api-stub: LOverlay:setHeatHazeIntensity
-- Sets the heat haze intensity of this overlay.
do
  -- Intensity 0.0-1.0. Derive from game temperature for realism.
  -- Example: haze appears above 30C, full intensity at 50C.
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeEnabled(true)
  local temp_c = 42
  overlay:setHeatHazeIntensity(math.min(1.0, math.max(0.0, (temp_c - 30) / 20)))
end

--@api-stub: LOverlay:getHeatHazeIntensity
-- Returns the heat haze intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setHeatHazeIntensity(0.6)
  lurek.log.debug("heat haze i=" .. overlay:getHeatHazeIntensity(), "fx")
end

--@api-stub: LOverlay:setVignetteEnabled
-- Enables or disables overlay vignette rendering.
do
  -- Overlay vignette darkens screen edges independently of post-fx.
  -- Use when you want vignette without a full post-processing stack.
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.55)
end

--@api-stub: LOverlay:isVignetteEnabled
-- Returns true if overlay vignette rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isVignetteEnabled() then
    overlay:setVignetteStrength(0.7)
  end
end

--@api-stub: LOverlay:setVignetteStrength
-- Sets the vignette strength of this overlay.
do
  -- Strength 0.0-1.0: 0 = no effect, 1.0 = maximum edge darkening.
  -- Increase when the player is low on health for a tunnel-vision feel.
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteEnabled(true)
  overlay:setVignetteStrength(0.45)
end

--@api-stub: LOverlay:getVignetteStrength
-- Returns the vignette strength of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setVignetteStrength(0.5)
  lurek.log.debug("vignette s=" .. overlay:getVignetteStrength(), "fx")
end

--@api-stub: LOverlay:setFilmGrainEnabled
-- Enables or disables overlay film grain rendering.
do
  -- Film grain adds animated noise over the image. Use for horror games,
  -- retro VHS looks, or subtle texture on flat-shaded art.
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.25)
end

--@api-stub: LOverlay:isFilmGrainEnabled
-- Returns true if overlay film grain rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isFilmGrainEnabled() then
    lurek.log.debug("grain layer is live", "fx")
  end
end

--@api-stub: LOverlay:setFilmGrainIntensity
-- Sets the film grain intensity of this overlay.
do
  -- Intensity 0.0-1.0. Subtle (0.1-0.2) adds texture without distraction.
  -- Heavy (0.5+) for deliberate stylistic effect.
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainEnabled(true)
  overlay:setFilmGrainIntensity(0.18)
end

--@api-stub: LOverlay:getFilmGrainIntensity
-- Returns the film grain intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setFilmGrainIntensity(0.3)
  lurek.log.debug("grain i=" .. overlay:getFilmGrainIntensity(), "fx")
end

--@api-stub: LOverlay:setCloudShadows
-- Enables or disables overlay cloud shadow rendering.
do
  -- Cloud shadows cast moving dark patches across the scene.
  -- Great for open-world top-down games to add life to the environment.
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(8)
end

--@api-stub: LOverlay:isCloudShadowsEnabled
-- Returns true if overlay cloud shadow rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isCloudShadowsEnabled() then
    overlay:setCloudOpacity(0.4)
  end
end

--@api-stub: LOverlay:setCloudCount
-- Sets the cloud shadow count of this overlay.
do
  -- More clouds = more shadow patches. 4-8 for light cover, 12+ for overcast.
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudCount(12)
end

--@api-stub: LOverlay:getCloudCount
-- Returns the number of cloud shadows in this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudCount(6)
  lurek.log.debug("clouds=" .. overlay:getCloudCount(), "fx")
end

--@api-stub: LOverlay:setCloudSpeed
-- Sets the cloud shadow movement speed of this overlay.
do
  -- Speed in pixels/second. Higher = windier day, faster shadow movement.
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudSpeed(40.0)
end

--@api-stub: LOverlay:getCloudSpeed
-- Returns the cloud shadow speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudSpeed(25.0)
  lurek.log.debug("cloud px/s=" .. overlay:getCloudSpeed(), "fx")
end

--@api-stub: LOverlay:setCloudScale
-- Sets the cloud shadow scale of this overlay.
do
  -- Scale multiplier for shadow size. 1.0 = default, 2.0 = double size.
  -- Larger clouds feel higher altitude; smaller feel lower, more detailed.
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudScale(1.5)
end

--@api-stub: LOverlay:getCloudScale
-- Returns the cloud shadow scale of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudScale(0.8)
  lurek.log.debug("cloud scale=" .. overlay:getCloudScale(), "fx")
end

--@api-stub: LOverlay:setCloudOpacity
-- Sets the cloud shadow opacity of this overlay.
do
  -- Opacity 0.0-1.0: how dark the shadows are.
  -- 0.2-0.4 for subtle realism, 0.7+ for dramatic overcast.
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudShadows(true)
  overlay:setCloudOpacity(0.35)
end

--@api-stub: LOverlay:getCloudOpacity
-- Returns the cloud shadow opacity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setCloudOpacity(0.4)
  if overlay:getCloudOpacity() > 0.3 then
    lurek.log.info("overcast skies", "weather")
  end
end

--@api-stub: LOverlay:setWeatherEnabled
-- Enables or disables overlay weather rendering.
do
  -- Weather must be both named (setWeather) AND enabled to render.
  -- This lets you pre-configure weather without showing it yet.
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherEnabled(true)
end

--@api-stub: LOverlay:isWeatherEnabled
-- Returns true if overlay weather rendering is enabled.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:isWeatherEnabled() then
    lurek.log.debug("weather active = " .. overlay:getWeather(), "weather")
  end
end

--@api-stub: LOverlay:setWeather
-- Sets the weather type of this overlay.
do
  -- Available weather types depend on the engine; common ones:
  -- "rain", "snow", "ash", "leaves", "dust", "none".
  -- Combine with wind and intensity for the full effect.
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("snow")
  overlay:setWeatherEnabled(true)
  overlay:setWeatherIntensity(0.7)
end

--@api-stub: LOverlay:getWeather
-- Returns the current weather type name of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  lurek.log.info("current weather: " .. overlay:getWeather(), "weather")
end

--@api-stub: LOverlay:setWeatherIntensity
-- Sets the weather intensity of this overlay.
do
  -- Intensity 0.0-1.0: controls particle density/speed.
  -- 0.3 = light drizzle, 0.7 = steady rain, 1.0 = downpour.
  local overlay = lurek.effect.newOverlay()
  overlay:setWeather("rain")
  overlay:setWeatherIntensity(0.85)
end

--@api-stub: LOverlay:getWeatherIntensity
-- Returns the weather intensity of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWeatherIntensity(0.5)
  lurek.log.debug("weather i=" .. overlay:getWeatherIntensity(), "weather")
end

--@api-stub: LOverlay:setWindDirection
-- Sets the wind direction of this overlay.
do
  -- Wind direction in radians affects weather particle drift angle.
  -- 0 = right, pi/2 = down, pi = left, 3pi/2 = up.
  -- Combine with wind speed for believable weather.
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi / 4)  -- diagonal down-right
  overlay:setWindSpeed(60.0)
end

--@api-stub: LOverlay:getWindDirection
-- Returns the wind direction of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindDirection(math.pi)
  lurek.log.debug("wind dir rad=" .. overlay:getWindDirection(), "weather")
end

--@api-stub: LOverlay:setWindSpeed
-- Sets the wind speed of this overlay.
do
  -- Wind speed in pixels/second. Affects weather particles and clouds.
  -- 20-40 = gentle breeze, 80-120 = strong wind, 200+ = storm.
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(120.0)
  overlay:setCloudSpeed(60.0)  -- clouds move slower than rain
end

--@api-stub: LOverlay:getWindSpeed
-- Returns the wind speed of this overlay.
do
  local overlay = lurek.effect.newOverlay()
  overlay:setWindSpeed(80.0)
  lurek.log.debug("wind=" .. overlay:getWindSpeed(), "weather")
end

--@api-stub: LOverlay:getLightningColor
-- Returns the lightning RGBA color of this overlay.
do
  -- Default lightning is bright white. Customize for colored lightning
  -- in fantasy settings (purple magic, green poison).
  local overlay = lurek.effect.newOverlay()
  local r, g, b, a = overlay:getLightningColor()
  lurek.log.info(string.format("lightning rgba %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: LOverlay:isFlashing
-- Returns true if the flash overlay is active.
do
  -- Use isFlashing() to suppress input or skip other visual effects
  -- while a flash is in progress (e.g. damage feedback).
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 0, 0, 1, 0.2)  -- red damage flash
  if overlay:isFlashing() then
    lurek.log.debug("ignoring input during damage flash", "input")
  end
end

--@api-stub: LOverlay:shake
-- Starts a screen shake with optional duration.
do
  -- shake(intensity, duration): intensity = max pixel offset, duration in seconds.
  -- Omit duration to use the default (0.5s).
  -- Apply getShakeOffset() to camera translation each frame.
  local overlay = lurek.effect.newOverlay()
  overlay:shake(12.0, 0.35)  -- heavy explosion impact
  function lurek.process(dt) overlay:update(dt) end
end

--@api-stub: LOverlay:isShaking
-- Returns true if the screen shake is active.
do
  local overlay = lurek.effect.newOverlay()
  overlay:shake(6.0, 0.25)
  if overlay:isShaking() then
    lurek.log.debug("camera shaking", "fx")
  end
end

--@api-stub: LOverlay:isFading
-- Returns true if the fade overlay is active.
do
  -- Use isFading() to wait for fade-out before switching scenes.
  local overlay = lurek.effect.newOverlay()
  overlay:fade(0, 0, 0, 1, 0.6)  -- fade to black over 0.6s
  function lurek.process(dt)
    overlay:update(dt)
    if not overlay:isFading() then lurek.log.debug("fade done", "fx") end
  end
end

--@api-stub: LOverlay:render
-- Renders overlay visual state to the current render target.
do
  -- Call render() in your draw callback to display overlay effects.
  -- Typically called AFTER scene drawing and AFTER post-fx apply.
  local overlay = lurek.effect.newOverlay()
  function lurek.draw_ui()
    overlay:render()
  end
end

--@api-stub: LOverlay:drawToImage
-- Renders overlay state into an image object.
do
  -- drawToImage() captures the overlay into a reusable Image at the given size.
  -- Use for thumbnails, minimaps, or capturing the overlay state for later.
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 1.0)
  local img = overlay:drawToImage(640, 360)
  lurek.log.info("overlay snapshot taken", "fx")
end

--@api-stub: LOverlay:setCustomShader
-- Sets or clears the custom overlay shader name.
do
  -- Override the default overlay rendering with a custom WGSL shader.
  -- Pass nil to revert to the default overlay shader.
  -- The shader receives overlay uniforms (time, weather state, etc).
  local overlay = lurek.effect.newOverlay()
  overlay:setCustomShader("shaders/post_grade.wgsl")
  -- overlay:setCustomShader(nil)  -- revert to default later
end

--@api-stub: LOverlay:getWater
-- Returns a table describing the current water effect settings.
do
  -- Returns a table with fields: enabled, amplitude, frequency, speed,
  -- tint (sub-table), depth, and time.
  local overlay = lurek.effect.newOverlay()
  local w = overlay:getWater()
  lurek.log.info("water enabled=" .. tostring(w.enabled) .. " amp=" .. w.amplitude, "fx")
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name string for this overlay handle.
do
  -- Returns "Overlay" (the Lua handle type).
  local overlay = lurek.effect.newOverlay()
  lurek.log.info("Overlay:type = " .. overlay:type(), "fx")
end

--@api-stub: LScreenTransition:typeOf
-- Returns true if this overlay handle matches the given type name string.
do
  local overlay = lurek.effect.newOverlay()
  if overlay:typeOf("Object") then
    lurek.log.debug("overlay is an Object", "fx")
  end
end

-- =============================================================================
-- ScreenTransition methods (via mlua handle)
-- =============================================================================

--@api-stub: LScreenTransition:play
-- Starts playback of this screen transition forward.
do
  -- play() begins the transition from start to end (e.g. fading in).
  -- The transition is not active until play() or reverse() is called.
  local trans = lurek.effect.newTransition("fade", 0.6, {0, 0, 0, 1})
  trans:play()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: LScreenTransition:reverse
-- Starts this screen transition in reverse from its current state.
do
  -- reverse() plays the transition backward (e.g. fade-out becomes fade-in).
  -- Use for paired transitions: play() to enter a scene, reverse() to leave.
  local trans = lurek.effect.newTransition("iris", 0.5)
  trans:reverse()
  function lurek.process(dt) trans:update(dt) end
end

--@api-stub: LScreenTransition:update
-- Advances this transition timer and returns whether it remains active.
do
  -- update(dt) returns true while the transition is still animating.
  -- When it returns false, the transition is complete (isDone() == true).
  -- Call every frame in lurek.process().
  local trans = lurek.effect.newTransition("dissolve", 0.8)
  trans:play()
  function lurek.process(dt)
    if not trans:update(dt) then lurek.log.debug("transition complete", "fx") end
  end
end

--@api-stub: LScreenTransition:progress
-- Returns normalized transition progress (0.0 to 1.0).
do
  -- progress() returns how far along the transition is.
  -- 0.0 = just started, 1.0 = fully complete.
  -- Use to sync other animations (audio fade, UI slide) with the transition.
  local trans = lurek.effect.newTransition("wipe", 1.0)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    lurek.log.debug(string.format("trans p=%.2f", trans:progress()), "fx")
  end
end

--@api-stub: LScreenTransition:isActive
-- Returns true if this screen transition is currently active.
do
  -- isActive() is true between play()/reverse() and completion.
  -- Use to pause gameplay input during transitions.
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:play()
  if trans:isActive() then
    lurek.log.debug("transition in progress - pausing input", "input")
  end
end

--@api-stub: LScreenTransition:isDone
-- Returns true if this screen transition has finished.
do
  -- isDone() becomes true once the transition reaches its end state.
  -- Use as the signal to actually load the next scene or enable input.
  local trans = lurek.effect.newTransition("fade", 0.4)
  trans:play()
  function lurek.process(dt)
    trans:update(dt)
    if trans:isDone() then lurek.log.info("ready for next scene", "scene") end
  end
end

--@api-stub: LScreenTransition:kind
-- Returns the transition kind name.
do
  -- kind() returns the string you passed at creation (e.g. "dissolve").
  -- Useful for logging or saving which transition type is active.
  local trans = lurek.effect.newTransition("dissolve", 0.5)
  lurek.log.info("transition kind=" .. trans:kind(), "fx")
end

--@api-stub: LScreenTransition:color
-- Returns the transition RGBA color.
do
  -- color() returns the r, g, b, a values of the transition fill.
  -- The transition renders this color at varying opacity/coverage.
  local trans = lurek.effect.newTransition("fade", 0.5, {0.05, 0.0, 0.1, 1.0})
  local r, g, b, a = trans:color()
  lurek.log.info(string.format("trans color %.2f %.2f %.2f %.2f", r, g, b, a), "fx")
end

--@api-stub: LScreenTransition:setColor
-- Sets the transition RGBA color from a numeric array table.
do
  -- Change the transition color mid-flight (e.g. fade-to-black becomes
  -- fade-to-white for a flash effect).
  local trans = lurek.effect.newTransition("fade", 0.5)
  trans:setColor({0.0, 0.0, 0.0, 1.0})  -- fade to black
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name string for this screen transition handle.
do
  -- Returns "ScreenTransition" or similar Lua type name.
  local trans = lurek.effect.newTransition("wipe", 0.5)
  lurek.log.info("ScreenTransition:type = " .. tostring(trans and trans:type() or "nil"), "fx")
end

--@api-stub: LScreenTransition:typeOf
-- Returns true if this screen transition handle matches the given type name string.
do
  local trans = lurek.effect.newTransition("fade", 0.5)
  if trans:typeOf("Object") then
    lurek.log.debug("transition inherits Object", "fx")
  end
end

-- =============================================================================
-- PostFxEffect: auto-uniforms for custom shaders
-- =============================================================================

--@api-stub: LPostFxEffect:enableAutoUniforms
-- Enables automatic time and resolution uniforms for this effect.
do
  -- When enabled, the engine automatically writes time, frame count,
  -- and resolution into PostFxParams.p[3] every frame:
  --   p[3].x = elapsed time (seconds)
  --   p[3].y = frame count (f32)
  --   p[3].z = render target width (pixels)
  --   p[3].w = render target height (pixels)
  -- This saves you from manually setting these common uniforms.
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  lurek.log.debug("enableAutoUniforms called", "fx")
end

--@api-stub: LPostFxEffect:isAutoUniforms
-- Returns true if automatic uniforms are enabled for this effect.
do
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  lurek.log.debug("isAutoUniforms=" .. tostring(fx:isAutoUniforms()), "fx")
end

--@api-stub: LPostFxEffect:disableAutoUniforms
-- Disables automatic time and resolution uniforms for this effect.
do
  -- Disable if you need full control over all 4 parameter slots (p[0]-p[3]).
  -- When disabled, p[3] is free for your own shader parameters.
  local fx = lurek.effect.newCustomEffect(0)
  fx:enableAutoUniforms()
  fx:disableAutoUniforms()
  lurek.log.debug("auto_uniforms=" .. tostring(fx:isAutoUniforms()), "fx")
end

-- =============================================================================
-- Overlay: fade, flash, and trigger methods
-- =============================================================================

--@api-stub: LOverlay:fade
-- Starts a fade overlay with optional alpha and duration.
do
  -- fade(r, g, b, alpha, duration): fades the screen toward the given color.
  -- Alpha is the target opacity (1.0 = fully opaque fade).
  -- Duration is how long the fade takes in seconds.
  -- Use for scene transitions, death screens, or cinematic moments.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:fade(0, 0, 0, 1.0, 1.0)  -- 1-second fade to black
  lurek.log.info("fade started", "effect")
end

--@api-stub: LOverlay:flash
-- Starts a short flash overlay with optional alpha and duration.
do
  -- flash(r, g, b, alpha, duration): brief full-screen color burst.
  -- Default duration is 0.2s. Use for damage feedback, pickups, or impacts.
  -- White flash = healing/power-up, red = damage, cyan = shield hit.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:flash(0.15, 1, 1, 1, 1)  -- cyan flash for shield hit
  lurek.log.info("flash triggered", "effect")
end

--@api-stub: LPostFxEffect:getParameter
-- Reads a numeric shader parameter with optional default value.
do
  -- getParameter(name, default): returns the stored value or the default.
  -- Use to read back current settings for UI display or serialization.
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("bloom"))
  local effect = assert(stack:getEffect(1))
  local intensity = effect:getParameter("intensity")
  lurek.log.info("bloom intensity: " .. tostring(intensity), "effect")
end

--@api-stub: LPostFxStack:insert
-- Inserts an effect at a one-based stack position.
do
  -- insert(position, effect): inserts at the given slot, shifting others down.
  -- Use to add an effect before an existing one (e.g. vignette before CRT
  -- to darken edges before the CRT scanline pass).
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("crt"))
  stack:insert(1, lurek.effect.newEffect("vignette"))  -- vignette now processes first
  lurek.log.info("stack count: " .. stack:getEffectCount(), "effect")
end

--@api-stub: LOverlay:setAmbientColor
-- Sets the overlay ambient RGBA color.
do
  -- Manually set ambient color instead of using time-of-day auto-calculation.
  -- Use for indoor scenes where time-of-day does not apply.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setAmbientEnabled(true)
  overlay:setAmbientColor(0.1, 0.1, 0.3, 0.6)  -- blue-ish night indoor
  lurek.log.info("ambient colour set", "effect")
end

--@api-stub: LPostFxStack:setEnabled
-- Enables or disables the effect pass at a one-based stack position.
do
  -- setEnabled(position, flag): toggle individual slots without removing.
  -- Use for quality settings: disable expensive effects on low-end hardware.
  local stack = lurek.effect.newStack(800, 600)
  stack:add(lurek.effect.newEffect("bloom"))
  stack:setEnabled(1, false)  -- disable bloom at slot 1
  lurek.log.info("stack enabled: " .. tostring(stack:isEnabled(1)), "effect")
end

--@api-stub: LOverlay:setFogColor
-- Sets the fog RGBA color of this overlay.
do
  -- Set fog color to match your environment. Alpha is optional (defaults 1.0).
  -- Gray-blue for mountains, green-yellow for swamps, brown for dust storms.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setFogEnabled(true)
  overlay:setFogColor(0.6, 0.6, 0.7)  -- cool gray mountain fog
  lurek.log.info("fog colour set", "effect")
end

--@api-stub: LOverlay:setLightningColor
-- Sets the lightning RGBA color of this overlay.
do
  -- Default is bright white. Set to purple for arcane storms,
  -- green for toxic environments, etc.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setLightningColor(0.9, 0.95, 1.0)  -- slightly blue-white
  lurek.log.info("lightning colour set", "effect")
end

--@api-stub: LOverlay:setWater
-- Enables water distortion and sets wave parameters.
do
  -- setWater(amplitude, frequency, speed): enables underwater distortion.
  -- amplitude = wave height in UV space (0.01-0.05 typical)
  -- frequency = number of wave cycles (8-20 typical)
  -- speed = animation speed multiplier
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setWater(0.02, 12.0, 1.5)
  lurek.log.info("water effect set", "effect")
end

--@api-stub: LOverlay:setWaterTint
-- Sets the water tint color and strength.
do
  -- setWaterTint(r, g, b, strength): adds a color wash over the water effect.
  -- strength 0.0-1.0 controls how much the tint affects the final image.
  -- Blue-green for ocean, dark green for swamp, clear for shallow streams.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:setWater(0.02, 12.0, 1.5)
  overlay:setWaterTint(0.2, 0.6, 0.8, 0.5)  -- ocean blue tint
  lurek.log.info("water tint set", "effect")
end

--@api-stub: LOverlay:triggerFade
-- Starts a fade toward a target alpha over a duration.
do
  -- triggerFade(r, g, b, target_alpha, duration): explicit version of fade().
  -- Use when you need precise control over start vs target alpha.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerFade(0, 0, 0, 1.0, 1.5)  -- 1.5s fade to full black
  lurek.log.info("fade out triggered", "effect")
end

--@api-stub: LOverlay:triggerFlash
-- Starts a flash with explicit RGBA and duration.
do
  -- triggerFlash(r, g, b, a, duration): explicit version of flash().
  -- Use when you want full control over all parameters.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerFlash(1.0, 0.0, 0.0, 0.8, 0.12)  -- brief red damage flash
  lurek.log.info("flash triggered", "effect")
end

--@api-stub: LOverlay:triggerShake
-- Starts a screen shake with explicit intensity and duration.
do
  -- triggerShake(intensity, duration): explicit version of shake().
  -- intensity = max pixel displacement, duration in seconds.
  -- Use for explosions, heavy landings, or boss attacks.
  local overlay = lurek.effect.newOverlay(800, 600)
  overlay:triggerShake(8.0, 0.4)
  lurek.log.info("shake triggered", "effect")
end

-- =============================================================================
-- LScreenTransition methods (typed handle)
-- =============================================================================

--@api-stub: LScreenTransition:play
-- Starts this screen transition forward from its current state
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:play()
  lurek.log.info("transition playing, active=" .. tostring(tr:isActive()), "effect")
end

--@api-stub: LScreenTransition:reverse
-- Starts this screen transition in reverse from its current state
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:reverse()
  lurek.log.info("transition reversed, active=" .. tostring(tr:isActive()), "effect")
end

--@api-stub: LScreenTransition:update
-- Advances this transition timer and returns whether it remains active
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:play()
  local running = tr:update(0.1)
  lurek.log.info("still_active=" .. tostring(running), "effect")
end

--@api-stub: LScreenTransition:progress
-- Returns normalized transition progress
do
  local tr = lurek.effect.newTransition("fade", 1.0, {0, 0, 0, 1})
  tr:play()
  tr:update(0.25)
  lurek.log.info("progress=" .. tr:progress(), "effect")
end

--@api-stub: LScreenTransition:isActive
-- Returns whether the transition is currently active
do
  local tr = lurek.effect.newTransition("wipe", 0.4, {0, 0, 0, 1})
  lurek.log.info("before play: " .. tostring(tr:isActive()), "effect")
  tr:play()
  lurek.log.info("after play: " .. tostring(tr:isActive()), "effect")
end

--@api-stub: LScreenTransition:isDone
-- Returns whether the transition has finished
do
  local tr = lurek.effect.newTransition("fade", 0.1, {0, 0, 0, 1})
  tr:play()
  while not tr:isDone() do
    tr:update(0.05)
  end
  lurek.log.info("transition is done", "effect")
end

--@api-stub: LScreenTransition:kind
-- Returns the transition kind name
do
  local tr = lurek.effect.newTransition("iris_wipe", 0.5, {0, 0, 0, 1})
  lurek.log.info("kind=" .. tr:kind(), "effect")
end

--@api-stub: LScreenTransition:color
-- Returns the transition RGBA color
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0.1, 0.2, 0.3, 1.0})
  local r, g, b, a = tr:color()
  lurek.log.info("color r=" .. r .. " g=" .. g .. " b=" .. b, "effect")
end

--@api-stub: LScreenTransition:setColor
-- Sets the transition RGBA color from a numeric array table
do
  local tr = lurek.effect.newTransition("fade", 0.5, {0, 0, 0, 1})
  tr:setColor({1.0, 1.0, 1.0, 1.0})   -- switch to white flash
  local r, g, b = tr:color()
  lurek.log.info("updated color r=" .. r .. " g=" .. g, "effect")
end

--@api-stub: LScreenTransition:type
-- Returns the Lua-visible type name for this transition handle
do
  local screen_transition_obj = lurek.effect.newTransition(nil, nil, nil)
  local t = screen_transition_obj:type()
  lurek.log.info("LScreenTransition:type = " .. t, "effect")
end

--@api-stub: LScreenTransition:typeOf
-- Returns whether this transition handle matches a supported type name
do
  local screen_transition_obj = lurek.effect.newTransition(nil, nil, nil)
  lurek.log.info("is LScreenTransition: " .. tostring(screen_transition_obj:typeOf("LScreenTransition")), "effect")
  lurek.log.info("is wrong: " .. tostring(screen_transition_obj:typeOf("Unknown")), "effect")
end

-- =============================================================================
-- Overlay: ambient/light synchronization
-- =============================================================================

--@api-stub: LOverlay:pullAmbientFromLight
-- Copies ambient color from the shared light world into this overlay
do
  -- pullAmbientFromLight() reads the current light system ambient color
  -- and applies it to this overlay. Use when the light system is the
  -- source of truth and the overlay should mirror it.
  local overlay = lurek.effect.newOverlay()
  overlay:pullAmbientFromLight()
end

--@api-stub: LOverlay:pushAmbientToLight
-- Copies this overlay ambient color into the shared light world
do
  -- pushAmbientToLight() writes the overlay's ambient color into the
  -- shared light world. Use when the overlay (e.g. time-of-day) drives
  -- the lighting and point lights should blend with overlay ambient.
  local overlay = lurek.effect.newOverlay()
  overlay:pushAmbientToLight()
end

--@api-stub: LOverlay:syncAmbientWithLight
-- Resolves overlay and light ambient colors using a named mode and writes both stores
do
  -- syncAmbientWithLight(mode) merges overlay and light ambient colors.
  -- Modes: "light" (use light's value), "overlay" (use overlay's value),
  -- "avg" (average both), "max" (take brighter), "min" (take darker).
  -- After sync, both stores contain the resolved color.
  local overlay = lurek.effect.newOverlay()
  overlay:syncAmbientWithLight("avg")
end

print("content/examples/effect.lua")

-- =============================================================================
-- Additional LImageEffect / LOverlay / LPostFxEffect / LPostFxStack coverage
-- =============================================================================

--@api-stub: LImageEffect:clear
-- Removes every effect from this image effect chain.
do
  -- Reset a chain before rebuilding it with a different look.
  local chain = lurek.effect.newImageEffect({{ type = "blur" }, { type = "vignette" }})
  chain:clear()
  lurek.log.debug("chain cleared, count=" .. chain:effectCount(), "fx")
end

--@api-stub: LImageEffect:type
-- Returns the Lua-visible type name for this image effect handle.
do
  local chain = lurek.effect.newImageEffect()
  lurek.log.info("ImageEffect:type = " .. chain:type(), "fx")
end

--@api-stub: LImageEffect:typeOf
-- Returns whether this image effect handle matches a supported type name.
do
  local chain = lurek.effect.newImageEffect()
  lurek.log.info("is Object: " .. tostring(chain:typeOf("Object")), "fx")
end

--@api-stub: LOverlay:update
-- Advances overlay timers and animated effect state.
do
  -- Call every frame to animate weather, shake decay, and flash fade.
  local overlay = lurek.effect.newOverlay()
  overlay:shake(4.0, 0.3)
  function lurek.process(dt)
    overlay:update(dt)
  end
end

--@api-stub: LOverlay:isActive
-- Returns whether any overlay effect is currently active.
do
  -- Skip render call when nothing is visible to save draw overhead.
  local overlay = lurek.effect.newOverlay()
  overlay:flash(1, 1, 1, 1, 0.2)
  if overlay:isActive() then
    lurek.log.debug("overlay has active effects", "fx")
  end
end

--@api-stub: LOverlay:type
-- Returns the Lua-visible type name for this overlay handle.
do
  local overlay = lurek.effect.newOverlay()
  lurek.log.info("Overlay:type = " .. overlay:type(), "fx")
end

--@api-stub: LOverlay:typeOf
-- Returns whether this overlay handle matches a supported type name.
do
  local overlay = lurek.effect.newOverlay()
  lurek.log.info("is Object: " .. tostring(overlay:typeOf("Object")), "fx")
end

--@api-stub: LPostFxEffect:isEnabled
-- Returns whether this effect is enabled on its owning effect object.
do
  -- Check before applying expensive effects in a quality-options menu.
  local bloom = lurek.effect.newEffect("bloom")
  bloom:setEnabled(false)
  lurek.log.debug("bloom enabled=" .. tostring(bloom:isEnabled()), "fx")
end

--@api-stub: LPostFxEffect:setEnabled
-- Enables or disables this effect. This method is available to Lua scripts.
do
  -- Toggle effects from a settings screen without removing them.
  local crt = lurek.effect.newEffect("crt")
  crt:setEnabled(false)
  lurek.log.debug("crt disabled for performance", "fx")
end

--@api-stub: LPostFxEffect:type
-- Returns the Lua-visible type name for this post-processing effect handle.
do
  local eff = lurek.effect.newEffect("bloom")
  lurek.log.info("PostFxEffect:type = " .. eff:type(), "fx")
end

--@api-stub: LPostFxEffect:typeOf
-- Returns whether this effect handle matches a supported type name.
do
  local eff = lurek.effect.newEffect("bloom")
  lurek.log.info("is Object: " .. tostring(eff:typeOf("Object")), "fx")
end

--@api-stub: LPostFxStack:getEffectCount
-- Returns the number of effect handles in this stack.
do
  -- Monitor stack size to prevent unbounded growth.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  stack:add(lurek.effect.newEffect("vignette"))
  lurek.log.info("stack count=" .. stack:getEffectCount(), "fx")
end

--@api-stub: LPostFxStack:getEffect
-- Returns the effect handle at a one-based position.
do
  -- Retrieve an effect by slot to modify its parameters at runtime.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("bloom"))
  local eff = stack:getEffect(1)
  if eff then eff:setIntensity(1.5) end
end

--@api-stub: LPostFxStack:getWidth
-- Returns the stack render width. This method is available to Lua scripts.
do
  local stack = lurek.effect.newStack(1280, 720)
  lurek.log.info("stack width=" .. stack:getWidth(), "fx")
end

--@api-stub: LPostFxStack:getHeight
-- Returns the stack render height. This method is available to Lua scripts.
do
  local stack = lurek.effect.newStack(1280, 720)
  lurek.log.info("stack height=" .. stack:getHeight(), "fx")
end

--@api-stub: LPostFxStack:getDimensions
-- Returns the stack render dimensions.
do
  -- Get both width and height in one call.
  local stack = lurek.effect.newStack(1920, 1080)
  local w, h = stack:getDimensions()
  lurek.log.info("stack " .. w .. "x" .. h, "fx")
end

--@api-stub: LPostFxStack:resize
-- Resizes the post-processing stack render target dimensions.
do
  -- Recreate render targets when the window size changes.
  local stack = lurek.effect.newStack(800, 600)
  stack:resize(1920, 1080)
  lurek.log.info("stack resized to " .. stack:getWidth() .. "x" .. stack:getHeight(), "fx")
end

--@api-stub: LPostFxStack:clear
-- Removes all effects and pass state from this stack.
do
  -- Wipe the pipeline for a new scene with different visual needs.
  local stack = lurek.effect.newStack()
  stack:add(lurek.effect.newEffect("crt"))
  stack:clear()
  lurek.log.debug("stack cleared, count=" .. stack:getEffectCount(), "fx")
end

--@api-stub: LPostFxStack:type
-- Returns the Lua-visible type name for this post-processing stack handle.
do
  local stack = lurek.effect.newStack()
  lurek.log.info("PostFxStack:type = " .. stack:type(), "fx")
end

--@api-stub: LPostFxStack:typeOf
-- Returns whether this stack handle matches a supported type name.
do
  local stack = lurek.effect.newStack()
  lurek.log.info("is Object: " .. tostring(stack:typeOf("Object")), "fx")
end
