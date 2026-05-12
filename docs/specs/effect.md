# effect

## General Info

- Module group: `Platform Services`
- Source path: `src/effect/`
- Lua API path(s): `src/lua_api/effect_api.rs`
- Primary Lua namespace: `lurek.effect`
- Rust test path(s): tests/rust/unit/effect_tests.rs
- Lua test path(s): tests/lua/unit/test_effect_core_unit.lua, tests/lua/integration/test_effect_camera.lua, tests/lua/integration/test_effect_light.lua, tests/lua/evidence/test_effect_evidence.lua

## Summary

The `effect` module owns Lurek2D's post-processing and image-effect pipeline — a Platform Services tier module that applies full-screen or region-based visual transformations on top of the rendered game scene. It is the home for blur, bloom, distortion, colour grading, scanlines, vignette, pixelation, lens distortion, weather overlays, screen flash/shake/fade, and custom WGSL fragment shaders. All effect state flows through the render command queue and has no coupling to physics, audio, ECS, or input.

**PostFxStack — the full-frame pipeline.** `PostFxStack` is the ordered container for full-screen post-processing passes. `PostFxEffect` describes one pass: an `PostFxEffectType` variant selecting the built-in shader, a parameter map (`HashMap<String, f32>` for intensity, radius, threshold, etc.), an enabled flag, and an optional custom WGSL shader handle. Effects are applied in stack order after the main world and UI passes are complete.

**ImageEffect — per-object effects.** `ImageEffect` is a smaller effect descriptor attached to individual image or sprite draws. It supports the same preset library but applies only to the texture it is attached to before it is composited into the scene, enabling per-sprite chromatic aberration, desaturation, or custom shader effects.

**Presets library.** `presets.rs` registers a library of commonly needed named effects as `PostFxEffect` templates: gaussian blur, box blur, chromatic aberration, CRT scanlines, colour inversion, sepia, pixelation, edge detection, sharpening, and a classic vignette. Lua scripts apply these by name without writing WGSL.

**Dedicated preset types.** Three additional source files add first-class preset types with their own parameter sets:
- `color_grade.rs` — `ColorGrade`: separate shadow, midtone, and highlight tint controls with saturation and exposure.
- `lens_distort.rs` — `LensDistort`: barrel and pincushion optical lens distortion with configurable strength and aberration.
- `scanline.rs` — `Scanline`: CRT-style horizontal scanline overlay with line height, brightness, and colour shift.

**Overlay — top-level screen controller.** `Overlay` aggregates all ambient, atmospheric, weather, and transient screen-state into a single controller polled by the renderer each frame:
- `AmbientState`: time-of-day tint and brightness.
- `FogState`, `CloudState`, `HeatHazeState`, `VignetteState`, `FilmGrainState`, `LightningState` (atmosphere).
- `WaterOverlay`: UV-distortion water surface with depth tint.
- `WeatherState`: rain/snow particle simulation with wind and intensity.
- `ScreenEffects`: flash (timed full-screen colour), shake (positional offset), fade (in/out alpha transition).
- `TransitionState`: cross-fade, wipe, and slide screen-transition management.

**Render integration.** `render.rs` emits `RenderCommand::BeginPostFx` / `RenderCommand::EndPostFx` / `RenderCommand::ApplyPostFx` markers into the command queue. The GPU renderer processes these after the main draw pass: for each effect in the stack, it binds the effect's shader (all built-in WGSL sources are embedded at compile time), pushes uniform parameters, and renders a full-screen textured quad reading from the previous pass's output.

**Lua surface.** `lurek.effect.newStack()` → `PostFxStack` userdata. `stack:add(effectName, params)`, `stack:remove(i)`, `stack:enable(i)`, `stack:disable(i)`. `lurek.effect.newImageEffect(name, params)` → `ImageEffect` userdata (attached to image draws). `lurek.effect.newColorGrade(params)`, `newLensDistort(params)`, `newScanline(params)`. Overlay: `lurek.effect.overlay.*` for ambient, fog, vignette, weather, flash, shake, fade.

**Scope boundary.** Platform Services tier. Depends on `render` (command types), `image`, `runtime`. Lua bridge in `src/lua_api/effect_api.rs`.

**Ownership clarifications.**
- Screen shake in `effect` is overlay-level screen-space shake (`Overlay::trigger_shake` / `ShakeState`). Camera shake in `camera` remains camera-transform shake. They are intentionally separate control points.
- `effect::AmbientState` controls post-process ambient tint as an overlay visual layer. `light::LightWorld.ambient` controls gameplay/world light accumulation in the light system. They are separate domains.
- `effect::WeatherState` is lightweight full-screen weather overlay particles. The `particle` module remains the general-purpose emitter/runtime for gameplay particles.

## Files

- `ambient.rs`: Defines time-of-day ambient lighting state.
- `atmosphere.rs`: Defines cloud, fog, heat haze, vignette, film grain, and lightning state structs.
- `draw.rs`: Provides CPU-side fallback drawing helpers for post-processing stacks.
- `effect.rs`: Defines PostFxEffect, the parameter bag for a single post-processing pass.
- `effect_type.rs`: Defines PostFxEffectType and the default parameter presets for built-in effect kinds.
- `image_effect.rs`: Defines ImageEffect, a smaller effect chain attached to individual image draws.
- `mod.rs`: Declares the effect submodules and re-exports the public post-processing and overlay types.
- `overlay.rs`: Defines Overlay, the top-level screen-effect controller that aggregates ambient, atmospheric, weather, and transient screen effects.
- `presets.rs`: Preset effect stacks for common visual styles.
- `render.rs`: Generates render-command markers for beginning, ending, and applying post-processing capture.
- `screen_effects.rs`: Defines flash, shake, and fade state.
- `stack.rs`: Defines PostFxStack, the ordered full-frame post-processing pipeline container.
- `transition.rs`: Screen-transition effect data model for [`super::PostFxStack`].
- `water_overlay.rs`: Water surface overlay with UV distortion and depth-tint controls.
- `weather.rs`: Defines weather particle types, live particles, and weather simulation state.

## Types

- `AmbientState` (`struct`, `ambient.rs`): Time-of-day ambient tint controller used by Overlay.
- `CloudState` (`struct`, `atmosphere.rs`): Cloud shadow overlay state.
- `FogState` (`struct`, `atmosphere.rs`): Atmospheric fog state.
- `HeatHazeState` (`struct`, `atmosphere.rs`): Heat haze distortion state.
- `VignetteState` (`struct`, `atmosphere.rs`): Vignette screen-edge darkening state.
- `FilmGrainState` (`struct`, `atmosphere.rs`): Film grain noise overlay state.
- `LightningState` (`struct`, `atmosphere.rs`): Lightning flash state.
- `PostFxEffect` (`struct`, `effect.rs`): One post-processing pass with effect type, parameter map, enabled flag, and optional custom shader handle.
- `PostFxEffectType` (`enum`, `effect_type.rs`): Enum naming the built-in post-processing pass types and their default parameter sets.
- `ImageEffect` (`struct`, `image_effect.rs`): Ordered per-image effect chain that converts to lightweight shader pass descriptors.
- `Overlay` (`struct`, `overlay.rs`): Top-level per-frame overlay state that updates ambient, weather, flashes, fades, shake, and atmospheric effects together.
- `EffectPreset` (`struct`, `presets.rs`): A fully configured preset: an ordered stack of effects with their data.
- `FlashState` (`struct`, `screen_effects.rs`): Flash screen effect state.
- `ShakeState` (`struct`, `screen_effects.rs`): Shake screen effect state.
- `FadeState` (`struct`, `screen_effects.rs`): Fade screen effect state.
- `PostFxStack` (`struct`, `stack.rs`): Ordered full-frame post-processing pipeline with per-pass enabled flags and capture dimensions.
- `TransitionKind` (`enum`, `transition.rs`): The visual style of a screen transition.
- `ScreenTransition` (`struct`, `transition.rs`): Frame-by-frame state machine for a screen transition.
- `WaterOverlayState` (`struct`, `water_overlay.rs`): Full-screen water-surface overlay state.
- `WeatherType` (`enum`, `weather.rs`): Weather particle types supported by the effect system.
- `WeatherParticle` (`struct`, `weather.rs`): A single weather particle in the effect's weather system.
- `WeatherState` (`struct`, `weather.rs`): Weather particle simulation state including type, wind, intensity, and live particles.

## Functions

- `AmbientState::compute_color_from_time` (`ambient.rs`): Computes the ambient colour from time-of-day.
- `PostFxStack::draw_to_image` (`draw.rs`): Render the post-processing stack to a CPU image for headless testing.
- `PostFxEffect::new` (`effect.rs`): Creates a new built-in effect with default parameters.
- `PostFxEffect::new_custom` (`effect.rs`): Creates a custom shader pass effect.
- `PostFxEffect::set_parameter` (`effect.rs`): Sets a named float parameter, inserting it if it does not yet exist.
- `PostFxEffect::get_parameter` (`effect.rs`): Gets a named float parameter, returning `default` if not set.
- `PostFxEffect::has_parameter` (`effect.rs`): Returns `true` if the named parameter key exists in this effect's map.
- `PostFxEffect::get_parameter_names` (`effect.rs`): Returns a sorted alphabetical list of all parameter names.
- `PostFxEffect::get_type_name` (`effect.rs`): Returns the canonical string name of this effect's type.
- `PostFxEffect::is_built_in` (`effect.rs`): Returns `true` if this is a built-in effect (not a custom shader pass).
- `PostFxEffect::new_disabled` (`effect.rs`): Creates a new built-in effect that starts disabled.
- `PostFxEffect::set_param` (`effect.rs`): Alias for [`set_parameter`].
- `PostFxEffect::get_param_or` (`effect.rs`): Alias for [`get_parameter`].
- `PostFxEffectType::from_name` (`effect_type.rs`): Parses a string name into an effect type.
- `PostFxEffectType::name` (`effect_type.rs`): Returns the string name of this effect type.
- `PostFxEffectType::default_params` (`effect_type.rs`): Returns the default parameters for this built-in effect type.
- `ImageEffect::new` (`image_effect.rs`): Creates a new empty effect chain with the given label.
- `ImageEffect::add_effect` (`image_effect.rs`): Wraps `effect` in an `Rc<RefCell<>>` and appends it to the end of the chain.
- `ImageEffect::add_effect_rc` (`image_effect.rs`): Appends a pre-shared effect reference to the end of the chain.
- `ImageEffect::get_effect_by_index` (`image_effect.rs`): Returns a shared reference to the effect at the given 0-based index, or `None`.
- `ImageEffect::get_effect_by_name` (`image_effect.rs`): Returns a shared reference to the first effect whose type name matches `name`, or `None`.
- `ImageEffect::remove_by_index` (`image_effect.rs`): Removes the effect at the given 0-based index.
- `ImageEffect::remove_by_name` (`image_effect.rs`): Removes the first effect whose type name matches `name`.
- `ImageEffect::clear` (`image_effect.rs`): Removes all effects from the chain.
- `ImageEffect::effect_count` (`image_effect.rs`): Returns the number of effects in the chain.
- `ImageEffect::to_passes` (`image_effect.rs`): Converts the effect chain to lightweight [`ShaderPassDescriptor`] values for the Tier-1 graphics layer.
- `Overlay::new` (`overlay.rs`): Creates a new overlay with the given dimensions.
- `Overlay::update` (`overlay.rs`): Advances all active effects by delta time.
- `Overlay::trigger_flash` (`overlay.rs`): Triggers a screen flash with the given colour and duration.
- `Overlay::trigger_shake` (`overlay.rs`): Triggers a screen shake with the given intensity and duration.
- `Overlay::trigger_fade` (`overlay.rs`): Triggers a fade to the given colour.
- `Overlay::trigger_lightning` (`overlay.rs`): Triggers a one-shot lightning flash effect.
- `Overlay::get_shake_offset` (`overlay.rs`): Returns the current shake pixel offset.
- `Overlay::is_active` (`overlay.rs`): Returns whether any effect is currently active.
- `Overlay::clear` (`overlay.rs`): Resets all effects to their inactive defaults.
- `Overlay::resize` (`overlay.rs`): Resizes the effect canvas dimensions.
- `Overlay::get_width` (`overlay.rs`): Returns the effect canvas width in pixels.
- `Overlay::get_height` (`overlay.rs`): Returns the effect canvas height in pixels.
- `Overlay::get_dimensions` (`overlay.rs`): Returns both overlay canvas dimensions as `(width, height)`.
- `Overlay::get_flash_alpha` (`overlay.rs`): Returns the current flash overlay alpha (0.0 when inactive).
- `Overlay::get_lightning_alpha` (`overlay.rs`): Returns the current lightning overlay alpha (0.0 when inactive).
- `Overlay::build_render_commands` (`overlay.rs`): Builds the per-frame GPU render commands for all active overlay effects.
- `Overlay::draw_state_to_image` (`overlay.rs`): Renders a diagnostic image showing the current overlay state.
- `Overlay::draw_flash_sequence_to_image` (`overlay.rs`): Render a flash-alpha progression as a horizontal strip of panels.
- `Overlay::draw_shake_trail_to_image` (`overlay.rs`): Render a shake-offset trail as dots on a canvas.
- `Overlay::draw_fade_transition_to_image` (`overlay.rs`): Render a fade-alpha progression as a horizontal strip of panels.
- `Overlay::draw_trigger_panel_to_image` (`overlay.rs`): Render a 4-panel trigger visualization (flash, shake, fade, lightning).
- `preset_names` (`presets.rs`): Returns a list of all available preset names.
- `build_preset` (`presets.rs`): Builds a named preset stack, returning `None` when the name is unknown.
- `PostFxStack::begin_capture_command` (`render.rs`): Returns the `BeginPostFx` command that starts scene capture.
- `PostFxStack::end_capture_command` (`render.rs`): Returns the `EndPostFx` command that stops scene capture.
- `PostFxStack::apply_command` (`render.rs`): Returns the `ApplyPostFx` command that applies all enabled effects.
- `PostFxStack::generate_render_commands` (`render.rs`): Returns the full sequence of render commands for the effect stack.
- `ShakeState::next_random` (`screen_effects.rs`): Advances a simple xorshift PRNG and returns a value in [-1, 1].
- `PostFxStack::new` (`stack.rs`): Creates a new post-processing stack with the given canvas dimensions.
- `PostFxStack::add` (`stack.rs`): Appends an effect index to the end of the chain.
- `PostFxStack::remove` (`stack.rs`): Removes an effect index from the chain.
- `PostFxStack::insert` (`stack.rs`): Inserts an effect at a specific 1-based position.
- `PostFxStack::set_enabled` (`stack.rs`): Sets the enabled state for an effect in the chain.
- `PostFxStack::is_enabled` (`stack.rs`): Gets the enabled state for an effect in the chain.
- `PostFxStack::get_effect_count` (`stack.rs`): Returns the number of effects in the chain.
- `PostFxStack::get_effect` (`stack.rs`): Returns the effect index at a 1-based position.
- `PostFxStack::enabled_effects` (`stack.rs`): Returns the indices of all enabled effects in order.
- `PostFxStack::resize` (`stack.rs`): Resizes the internal canvas dimensions.
- `PostFxStack::get_width` (`stack.rs`): Returns the canvas width.
- `PostFxStack::get_height` (`stack.rs`): Returns the canvas height.
- `PostFxStack::get_dimensions` (`stack.rs`): Returns both canvas dimensions as `(width, height)`.
- `PostFxStack::len` (`stack.rs`): Returns the number of effects currently in the chain.
- `PostFxStack::is_empty` (`stack.rs`): Returns `true` if the chain contains no effects.
- `PostFxStack::clear` (`stack.rs`): Removes all effects from the chain.
- `PostFxStack::dedup_indices` (`stack.rs`): Removes duplicate effect indices from the chain, keeping the first occurrence of each index and discarding subsequent duplicates.
- `PostFxStack::draw_info_to_image` (`stack.rs`): Renders a diagnostic image showing the effect stack layout.
- `PostFxStack::draw_stack_management_to_image` (`stack.rs`): Render the stack state as two side-by-side column layouts.
- `PostFxStack::draw_effect_catalog_to_image` (`stack.rs`): Render a catalog grid of effect types with representative visual patterns.
- `PostFxStack::draw_effect_parameters_to_image` (`stack.rs`): Render a parameter showcase grid for PostFx effects.
- `PostFxStack::draw_effect_type_bars_to_image` (`stack.rs`): Render a bar preview for a small set of PostFx effect types.
- `PostFxStack::draw_effect_types_to_image` (`stack.rs`): Render a bar preview for a list of PostFx effect types, auto-assigning colours and counting parameters.
- `TransitionKind::from_str` (`transition.rs`): Parses the kind from a Lua string.
- `TransitionKind::name` (`transition.rs`): Returns the canonical lower-case name of this kind.
- `ScreenTransition::new` (`transition.rs`): Creates a new `ScreenTransition`.
- `ScreenTransition::play` (`transition.rs`): Starts the transition playing forward (hides the scene).
- `ScreenTransition::reverse` (`transition.rs`): Starts the transition playing in reverse (reveals the scene).
- `ScreenTransition::update` (`transition.rs`): Advances the transition by `dt` seconds.
- `ScreenTransition::progress` (`transition.rs`): Returns the fractional progress `[0, 1]` of the transition.
- `ScreenTransition::is_active` (`transition.rs`): Returns `true` if the transition is currently running.
- `ScreenTransition::is_done` (`transition.rs`): Returns `true` if the transition has completed.
- `WaterOverlayState::new` (`water_overlay.rs`): Creates a new disabled `WaterOverlayState` with default wave parameters.
- `WaterOverlayState::update` (`water_overlay.rs`): Advances the animation clock by `dt` seconds.
- `WaterOverlayState::reset` (`water_overlay.rs`): Resets all parameters and the animation clock to their defaults.
- `WeatherType::from_name` (`weather.rs`): Parses a string name into a weather type.
- `WeatherType::name` (`weather.rs`): Returns the string name of this weather type.

## Lua API Reference

- Binding path(s): `src/lua_api/effect_api.rs`
- Namespace: `lurek.effect`

### Module Functions
- `lurek.effect.newEffect`: Creates a new built-in post-processing effect by type name.
- `lurek.effect.newCustomEffect`: Creates a custom shader post-processing effect.
- `lurek.effect.newStack`: Creates a new post-processing pipeline stack.
- `lurek.effect.newPresetStack`: Creates a pre-configured effect stack from a named preset.
- `lurek.effect.newPass`: Creates a custom-shader post-processing effect (alias for newCustomEffect).
- `lurek.effect.getEffectTypes`: Returns the list of all built-in effect type names.
- `lurek.effect.newImageEffect`: Creates a new per-image effect chain.
- `lurek.effect.newOverlay`: Creates a new screen overlay controller for weather, flash, shake, and fade effects.
- `lurek.effect.newTransition`: Creates a new screen-transition controller.
- `lurek.effect.setShaderErrorDisplay`: Enables or disables on-screen shader error display.
- `lurek.effect.getShaderErrorDisplay`: Returns whether shader error display is currently enabled.

### `LImageEffect` Methods
- `LImageEffect:addEffect`: Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
- `LImageEffect:getEffect`: Returns the effect at the given 1-based index or with the given type name.
- `LImageEffect:removeEffect`: Removes the effect at the given 1-based index or with the given type name.
- `LImageEffect:clearEffects`: Removes all effects from the chain.
- `LImageEffect:clear`: Removes all effects from the chain (alias for clearEffects).
- `LImageEffect:effectCount`: Returns the number of effects in the chain.
- `LImageEffect:getEffectCount`: Returns the number of effects in the chain (alias for effectCount).
- `LImageEffect:clone`: Returns a deep copy of this ImageEffect chain.
- `LImageEffect:save`: Stub: no-op serialisation placeholder.
- `LImageEffect:type`: Returns the type name of this object.
- `LImageEffect:typeOf`: Returns true when the given name matches this object or a parent type.
- `LImageEffect:removeByIndex`: Removes the effect at the given 0-based index from the chain.
- `LImageEffect:removeByName`: Removes the first effect matching the given type name.

### `LOverlay` Methods
- `LOverlay:update`: Advances all effect subsystems by the given delta time.
- `LOverlay:triggerFlash`: Triggers a screen-wide colour flash effect.
- `LOverlay:triggerShake`: Triggers a screen shake effect with the given intensity and duration.
- `LOverlay:triggerFade`: Triggers a screen fade effect to the given colour and alpha.
- `LOverlay:triggerLightning`: Triggers a lightning flash effect.
- `LOverlay:getShakeOffset`: Returns the current shake displacement as x, y.
- `LOverlay:isActive`: Returns true if any effect subsystem is currently active.
- `LOverlay:clear`: Resets all effect subsystems to their default inactive state.
- `LOverlay:resize`: Resizes the effect to match new window dimensions.
- `LOverlay:getWidth`: Returns the effect width.
- `LOverlay:getHeight`: Returns the effect height.
- `LOverlay:getDimensions`: Returns the effect width and height.
- `LOverlay:getFlashAlpha`: Returns the current flash overlay alpha value.
- `LOverlay:getLightningAlpha`: Returns the current lightning overlay alpha value.
- `LOverlay:setAmbientEnabled`: Enables or disables the ambient light layer.
- `LOverlay:isAmbientEnabled`: Returns whether the ambient light layer is active.
- `LOverlay:setAmbientColor`: Sets the ambient light tint colour; alpha defaults to 1.0.
- `LOverlay:getAmbientColor`: Returns the current ambient tint as r, g, b, a components.
- `LOverlay:setTimeOfDay`: Sets the simulated time-of-day (0-24) which drives ambient colour.
- `LOverlay:getTimeOfDay`: Returns the current simulated time-of-day (0-24).
- `LOverlay:setFogEnabled`: Enables or disables the fog layer.
- `LOverlay:isFogEnabled`: Returns whether the fog layer is active.
- `LOverlay:setFogDensity`: Sets the fog density (0.0 = clear, 1.0 = fully opaque).
- `LOverlay:getFogDensity`: Returns the current fog density.
- `LOverlay:setFogColor`: Sets the fog tint colour; alpha defaults to 1.0.
- `LOverlay:getFogColor`: Returns the current fog tint as r, g, b, a components.
- `LOverlay:setHeatHazeEnabled`: Enables or disables the heat-haze distortion layer.
- `LOverlay:isHeatHazeEnabled`: Returns whether the heat-haze layer is active.
- `LOverlay:setHeatHazeIntensity`: Sets the heat-haze distortion intensity (0.0-1.0).
- `LOverlay:getHeatHazeIntensity`: Returns the current heat-haze distortion intensity.
- `LOverlay:setVignetteEnabled`: Enables or disables the screen-edge vignette layer.
- `LOverlay:isVignetteEnabled`: Returns whether the vignette layer is active.
- `LOverlay:setVignetteStrength`: Sets the vignette darkening strength (0.0-1.0).
- `LOverlay:getVignetteStrength`: Returns the current vignette strength.
- `LOverlay:setFilmGrainEnabled`: Enables or disables the film-grain noise layer.
- `LOverlay:isFilmGrainEnabled`: Returns whether the film-grain layer is active.
- `LOverlay:setFilmGrainIntensity`: Sets the film-grain noise intensity (0.0-1.0).
- `LOverlay:getFilmGrainIntensity`: Returns the current film-grain intensity.
- `LOverlay:setCloudShadows`: Enables or disables scrolling cloud-shadow projection.
- `LOverlay:isCloudShadowsEnabled`: Returns whether cloud shadows are active.
- `LOverlay:setCloudCount`: Sets the number of cloud shadow instances to render.
- `LOverlay:getCloudCount`: Returns the current cloud shadow instance count.
- `LOverlay:setCloudSpeed`: Sets the horizontal scroll speed of cloud shadows in pixels per second.
- `LOverlay:getCloudSpeed`: Returns the current cloud shadow scroll speed.
- `LOverlay:setCloudScale`: Sets the scale multiplier applied to each cloud shadow.
- `LOverlay:getCloudScale`: Returns the current cloud shadow scale.
- `LOverlay:setCloudOpacity`: Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
- `LOverlay:getCloudOpacity`: Returns the current cloud shadow opacity.
- `LOverlay:setWeatherEnabled`: Enables or disables the weather particle system.
- `LOverlay:isWeatherEnabled`: Returns whether the weather particle system is active.
- `LOverlay:setWeather`: Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
- `LOverlay:getWeather`: Returns the name of the current weather type.
- `LOverlay:setWeatherIntensity`: Sets the particle spawn rate multiplier (0.0-1.0).
- `LOverlay:getWeatherIntensity`: Returns the current weather intensity.
- `LOverlay:setWindDirection`: Sets the wind direction in radians (0 = right, Ď€/2 = down).
- `LOverlay:getWindDirection`: Returns the current wind direction in radians.
- `LOverlay:setWindSpeed`: Sets the wind speed applied to weather particles in units per second.
- `LOverlay:getWindSpeed`: Returns the current wind speed.
- `LOverlay:setLightningColor`: Sets the lightning flash tint colour; alpha defaults to 1.0.
- `LOverlay:getLightningColor`: Returns the lightning flash tint as r, g, b, a components.
- `LOverlay:flash`: Triggers a full-screen colour flash; alpha defaults to 1.0, duration to 0.2 s.
- `LOverlay:isFlashing`: Returns true while a flash effect is in progress.
- `LOverlay:shake`: Triggers a camera shake; duration defaults to 0.5 s.
- `LOverlay:isShaking`: Returns true while a shake effect is in progress.
- `LOverlay:fade`: Animates a full-screen colour fade; alpha defaults to 1.0, duration to 1.0 s.
- `LOverlay:isFading`: Returns true while a fade effect is in progress.
- `LOverlay:render`: Emits GPU render commands for all active overlay effects.
- `LOverlay:drawToImage`: Renders the effect state (flash, fade, effects) to a CPU ImageData.
- `LOverlay:setWater`: Enables the water overlay and sets its wave parameters.
- `LOverlay:setWaterTint`: Sets the water tint colour and blend strength.
- `LOverlay:setCustomShader`: Assigns a custom shader name to the effect.
- `LOverlay:getWater`: Returns a table describing the current water overlay state.
- `LOverlay:type`: Returns the type name of this object.
- `LOverlay:typeOf`: Returns true if this object is of the given type.

### `LPostFxEffect` Methods
- `LPostFxEffect:getTypeName`: Returns the display name of this effect type.
- `LPostFxEffect:isBuiltIn`: Returns true if this is a built-in effect, false if custom.
- `LPostFxEffect:isEnabled`: Returns whether this effect is currently active.
- `LPostFxEffect:setEnabled`: Enables or disables this effect.
- `LPostFxEffect:setParameter`: Sets a named float parameter on this effect.
- `LPostFxEffect:getParameter`: Returns a named parameter value, or the default if not set.
- `LPostFxEffect:hasParameter`: Returns true if the named parameter exists on this effect.
- `LPostFxEffect:getParameterNames`: Returns a list of all parameter names on this effect.
- `LPostFxEffect:getEffectType`: Returns the type name of this effect (alias for getTypeName).
- `LPostFxEffect:getType`: Returns the type name of this effect (alias for getTypeName).
- `LPostFxEffect:type`: Returns the type name of this object.
- `LPostFxEffect:typeOf`: Returns true when the given name matches this object or a parent type.
- `LPostFxEffect:setThreshold`: Sets the threshold parameter of this effect.
- `LPostFxEffect:setIntensity`: Sets the intensity parameter of this effect.
- `LPostFxEffect:setRadius`: Sets the radius parameter of this effect.
- `LPostFxEffect:setStrength`: Sets the strength parameter of this effect.
- `LPostFxEffect:setScanlineStrength`: Sets the scanline strength parameter of this effect.
- `LPostFxEffect:setOffset`: Sets the offset parameter of this effect.
- `LPostFxEffect:setBrightness`: Sets the brightness parameter of this effect.
- `LPostFxEffect:setContrast`: Sets the contrast parameter of this effect.
- `LPostFxEffect:setSaturation`: Sets the saturation parameter of this effect.
- `LPostFxEffect:enableAutoUniforms`: Enables auto-injection of common uniforms into shader slot p[3] each frame.
- `LPostFxEffect:disableAutoUniforms`: Disables auto-injection of common uniforms into shader slot p[3].
- `LPostFxEffect:isAutoUniforms`: Returns whether auto-uniform injection is enabled for this effect.

### `LPostFxStack` Methods
- `LPostFxStack:add`: Appends a PostFxEffect to the end of the pipeline.
- `LPostFxStack:remove`: Removes the given PostFxEffect from the pipeline.
- `LPostFxStack:insert`: Inserts a PostFxEffect at a specific 1-based position in the pipeline.
- `LPostFxStack:setEnabled`: Enables or disables the effect at the given 1-based position.
- `LPostFxStack:isEnabled`: Returns whether the effect at the given 1-based position is enabled.
- `LPostFxStack:getEffectCount`: Returns the number of effects in the pipeline.
- `LPostFxStack:getEffect`: Returns the effect at the given 1-based position, or nil.
- `LPostFxStack:getEnabledEffects`: Returns a list of currently enabled effect objects.
- `LPostFxStack:getWidth`: Returns the width of the render target.
- `LPostFxStack:getHeight`: Returns the height of the render target.
- `LPostFxStack:getDimensions`: Returns width and height of the render target.
- `LPostFxStack:resize`: Resizes the render target to the given dimensions.
- `LPostFxStack:len`: Returns the total number of effect slots in the pipeline.
- `LPostFxStack:isEmpty`: Returns true if the pipeline has no effect slots.
- `LPostFxStack:clear`: Removes all effects from the pipeline.
- `LPostFxStack:dedup`: Removes duplicate effects from the pipeline.
- `LPostFxStack:isCapturing`: Returns whether the stack is currently capturing the scene.
- `LPostFxStack:beginCapture`: Begins capturing the scene for post-processing.
- `LPostFxStack:endCapture`: Ends scene capture for post-processing.
- `LPostFxStack:apply`: Applies all enabled effects in the stack and composites the result to the screen.
- `LPostFxStack:type`: Returns the type name of this object.
- `LPostFxStack:typeOf`: Returns true when the given name matches this object or a parent type.
- `LPostFxStack:setFeedback`: Sets the feedback loop intensity between `0.0` and `1.0`.
- `LPostFxStack:getFeedback`: Returns the current feedback loop intensity `[0.0, 1.0]`.
- `LPostFxStack:clearFeedback`: Resets the feedback intensity to `0.0` (disables feedback).

### `LScreenTransition` Methods
- `LScreenTransition:play`: Starts the transition playing forward (scene fades/wipes out).
- `LScreenTransition:reverse`: Starts the transition in reverse (scene fades/wipes in).
- `LScreenTransition:update`: Advances the transition by `dt` seconds.
- `LScreenTransition:progress`: Returns the fractional progress of the transition.
- `LScreenTransition:isActive`: Returns true while the transition is running.
- `LScreenTransition:isDone`: Returns true after the transition has completed.
- `LScreenTransition:kind`: Returns the transition kind name.
- `LScreenTransition:color`: Returns the fill color as four numbers: `r, g, b, a`.
- `LScreenTransition:setColor`: Updates the fill color from `{r, g, b, a?}`.
- `LScreenTransition:type`: Returns the type name of this object.
- `LScreenTransition:typeOf`: Returns true if this object is of the given type name or a parent type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/effect/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
