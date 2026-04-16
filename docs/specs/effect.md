# effect

## General Info

- Module group: `Platform Services`
- Source path: `src/effect/`
- Lua API path(s): `src/lua_api/effect_api.rs`
- Primary Lua namespace: `lurek.effect`
- Rust test path(s): tests/rust/unit/fx_tests.rs, tests/rust/unit/postfx_tests.rs, tests/rust/unit/fx_screen_tests.rs
- Lua test path(s): tests/lua/unit/test_image_effect.lua and related image-effect evidence suites

## Summary

The `effect` module owns Lurek2D's post-processing and image-effect pipeline. Its purpose is to apply full-screen or region-based visual transformations — blur, bloom, distortion, color grading, scanlines, vignette, pixelation, and custom WGSL fragment shaders — on top of the already-rendered game scene by compositing successive passes through CPU-side image buffers or GPU canvas render-to-texture.

The central type is `ImageEffect`, a description of one post-processing pass. An effect holds a `ShaderPassDescriptor` that names the WGSL shader, its bind group layout, and any uniform parameters (floats for intensity, radius, seed, color, etc.). Assembling multiple `ImageEffect` values into an `EffectChain` produces a sorted multi-pass pipeline where each pass reads from the previous pass's output and writes to the next pass's input texture. The final pass writes to the screen.

`presets.rs` registers a library of commonly needed effects — gaussian blur, chromatic aberration, CRT scanlines, color inversion, sepia, and others — as named `ImageEffect` templates that Lua scripts can apply by name without writing WGSL themselves. Custom shader effects are supported by providing an inline WGSL string and a parameter table.

At render time, effects are queued as `RenderCommand::PostProcess` entries. The GPU renderer processes these commands after the main world pass and UI pass, binding each effect's shader and rendering a full-screen textured quad. All WGSL shader sources for built-in presets are embedded statically at compile time.

The effect module does not own scene rendering or sprite drawing. It only describes and manages the post-process layer. Physics, input, audio, and ECS have no coupling to this module.

Three new source files add dedicated post-processing presets as first-class types. `color_grade.rs` introduces `ColorGrade`, a configurable color-grading pass with separate shadow, midtone, and highlight tint controls. `lens_distort.rs` introduces `LensDistort` for barrel and pincushion optical lens distortion. `scanline.rs` introduces `Scanline` for CRT-style horizontal scanline overlays. Each type is constructed from Lua via `lurek.effect.newColorGrade()`, `lurek.effect.newLensDistort()`, and `lurek.effect.newScanline()`, with their full parameter sets exposed as Lua method chains on the returned userdata.

**Scope boundary**: Platform Services tier. Depends on `render` (command types), `image`, `runtime`. Lua bridge in `src/lua_api/fx_api.rs`.

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
- `WeatherType` (`enum`, `weather.rs`): Weather particle types supported by the overlay system.
- `WeatherParticle` (`struct`, `weather.rs`): A single weather particle in the overlay's weather system.
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
- `Overlay::resize` (`overlay.rs`): Resizes the overlay canvas dimensions.
- `Overlay::get_width` (`overlay.rs`): Returns the overlay canvas width in pixels.
- `Overlay::get_height` (`overlay.rs`): Returns the overlay canvas height in pixels.
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
- `lurek.effect.newImageEffect`: Creates a new per-image effect chain. Accepts:
- `lurek.effect.newOverlay`: Creates a new screen overlay controller for weather, flash, shake, and fade effects.
- `lurek.effect.newTransition`: Creates a new screen-transition controller. `kind` is one of:
- `lurek.effect.setShaderErrorDisplay`: Enables or disables the overlay that renders shader compile errors as red text
- `lurek.effect.getShaderErrorDisplay`: Returns whether shader error display is currently enabled.

### `ImageEffect` Methods
- `ImageEffect:addEffect`: Creates a new effect by type name, appends it, and returns the shared PostFxEffect.
- `ImageEffect:getEffect`: Returns the effect at the given 1-based index or with the given type name.
- `ImageEffect:removeEffect`: Removes the effect at the given 1-based index or with the given type name.
- `ImageEffect:clearEffects`: Removes all effects from the chain.
- `ImageEffect:clear`: Removes all effects from the chain (alias for clearEffects).
- `ImageEffect:effectCount`: Returns the number of effects in the chain.
- `ImageEffect:getEffectCount`: Returns the number of effects in the chain (alias for effectCount).
- `ImageEffect:clone`: Returns a deep copy of this ImageEffect chain.
- `ImageEffect:save`: Stub: no-op serialisation placeholder.
- `ImageEffect:type`: Returns the type name "ImageEffect".
- `ImageEffect:typeOf`: Returns true when the given name matches "ImageEffect" or a parent type.
- `ImageEffect:removeByIndex`: Removes the effect at the given 0-based index from the chain.
- `ImageEffect:removeByName`: Removes the first effect matching the given type name.

### `Overlay` Methods
- `Overlay:update`: Advances all overlay subsystems by the given delta time.
- `Overlay:triggerLightning`: Triggers a lightning flash effect.
- `Overlay:getShakeOffset`: Returns the current shake displacement as x, y.
- `Overlay:isActive`: Returns true if any overlay subsystem is currently active.
- `Overlay:clear`: Resets all overlay subsystems to their default inactive state.
- `Overlay:resize`: Resizes the overlay to match new window dimensions.
- `Overlay:getWidth`: Returns the overlay width.
- `Overlay:getHeight`: Returns the overlay height.
- `Overlay:getDimensions`: Returns the overlay width and height.
- `Overlay:getFlashAlpha`: Returns the current flash overlay alpha value.
- `Overlay:getLightningAlpha`: Returns the current lightning overlay alpha value.
- `Overlay:setAmbientEnabled`: Enables or disables the ambient light layer.
- `Overlay:isAmbientEnabled`: Returns whether the ambient light layer is active.
- `Overlay:getAmbientColor`: Returns the current ambient tint as r, g, b, a components.
- `Overlay:setTimeOfDay`: Sets the simulated time-of-day (0–24) which drives ambient colour.
- `Overlay:getTimeOfDay`: Returns the current simulated time-of-day (0–24).
- `Overlay:setFogEnabled`: Enables or disables the fog layer.
- `Overlay:isFogEnabled`: Returns whether the fog layer is active.
- `Overlay:setFogDensity`: Sets the fog density (0.0 = clear, 1.0 = fully opaque).
- `Overlay:getFogDensity`: Returns the current fog density.
- `Overlay:getFogColor`: Returns the current fog tint as r, g, b, a components.
- `Overlay:setHeatHazeEnabled`: Enables or disables the heat-haze distortion layer.
- `Overlay:isHeatHazeEnabled`: Returns whether the heat-haze layer is active.
- `Overlay:setHeatHazeIntensity`: Sets the heat-haze distortion intensity (0.0–1.0).
- `Overlay:getHeatHazeIntensity`: Returns the current heat-haze distortion intensity.
- `Overlay:setVignetteEnabled`: Enables or disables the screen-edge vignette layer.
- `Overlay:isVignetteEnabled`: Returns whether the vignette layer is active.
- `Overlay:setVignetteStrength`: Sets the vignette darkening strength (0.0–1.0).
- `Overlay:getVignetteStrength`: Returns the current vignette strength.
- `Overlay:setFilmGrainEnabled`: Enables or disables the film-grain noise layer.
- `Overlay:isFilmGrainEnabled`: Returns whether the film-grain layer is active.
- `Overlay:setFilmGrainIntensity`: Sets the film-grain noise intensity (0.0–1.0).
- `Overlay:getFilmGrainIntensity`: Returns the current film-grain intensity.
- `Overlay:setCloudShadows`: Enables or disables scrolling cloud-shadow projection.
- `Overlay:isCloudShadowsEnabled`: Returns whether cloud shadows are active.
- `Overlay:setCloudCount`: Sets the number of cloud shadow instances to render.
- `Overlay:getCloudCount`: Returns the current cloud shadow instance count.
- `Overlay:setCloudSpeed`: Sets the horizontal scroll speed of cloud shadows in pixels per second.
- `Overlay:getCloudSpeed`: Returns the current cloud shadow scroll speed.
- `Overlay:setCloudScale`: Sets the scale multiplier applied to each cloud shadow.
- `Overlay:getCloudScale`: Returns the current cloud shadow scale.
- `Overlay:setCloudOpacity`: Sets the opacity of cloud shadows (0.0 = invisible, 1.0 = fully dark).
- `Overlay:getCloudOpacity`: Returns the current cloud shadow opacity.
- `Overlay:setWeatherEnabled`: Enables or disables the weather particle system.
- `Overlay:isWeatherEnabled`: Returns whether the weather particle system is active.
- `Overlay:setWeather`: Sets the active weather type by name ("none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen").
- `Overlay:getWeather`: Returns the name of the current weather type.
- `Overlay:setWeatherIntensity`: Sets the particle spawn rate multiplier (0.0–1.0).
- `Overlay:getWeatherIntensity`: Returns the current weather intensity.
- `Overlay:setWindDirection`: Sets the wind direction in radians (0 = right, π/2 = down).
- `Overlay:getWindDirection`: Returns the current wind direction in radians.
- `Overlay:setWindSpeed`: Sets the wind speed applied to weather particles in units per second.
- `Overlay:getWindSpeed`: Returns the current wind speed.
- `Overlay:getLightningColor`: Returns the lightning flash tint as r, g, b, a components.
- `Overlay:isFlashing`: Returns true while a flash effect is in progress.
- `Overlay:shake`: Triggers a camera shake; duration defaults to 0.5 s.
- `Overlay:isShaking`: Returns true while a shake effect is in progress.
- `Overlay:isFading`: Returns true while a fade effect is in progress.
- `Overlay:render`: Emits GPU render commands for all active overlay effects (flash, fade, lightning, vignette).
- `Overlay:drawToImage`: Renders the overlay state (flash, fade, effects) to a CPU ImageData.
- `Overlay:setCustomShader`: Assigns a custom shader name to the overlay, or clears it when `nil` is passed.
- `Overlay:getWater`: Returns a table describing the current water overlay state.
- `Overlay:type`: Returns the type name of this object ("Overlay").
- `Overlay:typeOf`: Returns true if this object is of the given type ("Object" or "Overlay").

### `PostFxEffect` Methods
- `PostFxEffect:getTypeName`: Returns the display name of this effect type.
- `PostFxEffect:isBuiltIn`: Returns true if this is a built-in effect, false if custom.
- `PostFxEffect:isEnabled`: Returns whether this effect is currently active.
- `PostFxEffect:setEnabled`: Enables or disables this effect.
- `PostFxEffect:setParameter`: Sets a named float parameter on this effect.
- `PostFxEffect:hasParameter`: Returns true if the named parameter exists on this effect.
- `PostFxEffect:getParameterNames`: Returns a list of all parameter names on this effect.
- `PostFxEffect:getEffectType`: Returns the type name of this effect (alias for getTypeName).
- `PostFxEffect:getType`: Returns the type name of this effect (alias for getTypeName).
- `PostFxEffect:type`: Returns the type name "PostFxEffect".
- `PostFxEffect:typeOf`: Returns true when the given name matches "PostFxEffect" or a parent type.
- `PostFxEffect:setThreshold`: Sets the threshold parameter of this effect.
- `PostFxEffect:setIntensity`: Sets the intensity parameter of this effect.
- `PostFxEffect:setRadius`: Sets the radius parameter of this effect.
- `PostFxEffect:setStrength`: Sets the strength parameter of this effect.
- `PostFxEffect:setScanlineStrength`: Sets the scanline strength parameter of this effect.
- `PostFxEffect:setOffset`: Sets the offset parameter of this effect.
- `PostFxEffect:setBrightness`: Sets the brightness parameter of this effect.
- `PostFxEffect:setContrast`: Sets the contrast parameter of this effect.
- `PostFxEffect:setSaturation`: Sets the saturation parameter of this effect.

### `PostFxStack` Methods
- `PostFxStack:add`: Appends a PostFxEffect to the end of the pipeline.
- `PostFxStack:remove`: Removes the given PostFxEffect from the pipeline.
- `PostFxStack:isEnabled`: Returns whether the effect at the given 1-based position is enabled.
- `PostFxStack:getEffectCount`: Returns the number of effects in the pipeline.
- `PostFxStack:getEffect`: Returns the effect at the given 1-based position, or nil.
- `PostFxStack:getEnabledEffects`: Returns a list of currently enabled effect objects.
- `PostFxStack:getWidth`: Returns the width of the render target.
- `PostFxStack:getHeight`: Returns the height of the render target.
- `PostFxStack:getDimensions`: Returns width and height of the render target.
- `PostFxStack:resize`: Resizes the render target to the given dimensions.
- `PostFxStack:len`: Returns the total number of effect slots in the pipeline.
- `PostFxStack:isEmpty`: Returns true if the pipeline has no effect slots.
- `PostFxStack:clear`: Removes all effects from the pipeline.
- `PostFxStack:dedup`: Removes duplicate effects from the pipeline, keeping the first occurrence
- `PostFxStack:isCapturing`: Returns whether the stack is currently capturing the scene.
- `PostFxStack:beginCapture`: Begins capturing the scene for post-processing.
- `PostFxStack:endCapture`: Ends scene capture for post-processing.
- `PostFxStack:apply`: Applies all enabled effects in the stack and composites the result to screen.
- `PostFxStack:type`: Returns the type name "PostFxStack".
- `PostFxStack:typeOf`: Returns true when the given name matches "PostFxStack" or a parent type.
- `PostFxStack:setFeedback`: Sets the feedback loop intensity. At `0.0` (default) there is no
- `PostFxStack:getFeedback`: Returns the current feedback loop intensity `[0.0, 1.0]`.
- `PostFxStack:clearFeedback`: Resets the feedback intensity to `0.0` (disables feedback).

### `mlua` Methods
- `mlua:play`: Starts the transition playing forward (scene fades/wipes out).
- `mlua:reverse`: Starts the transition in reverse (scene fades/wipes in).
- `mlua:update`: Advances the transition by `dt` seconds. Returns `true` while
- `mlua:progress`: Returns the fractional progress `[0, 1]` of the transition, taking
- `mlua:isActive`: Returns `true` while the transition is running.
- `mlua:isDone`: Returns `true` after the transition has completed.
- `mlua:kind`: Returns the transition kind name (`"fade"`, `"wipe"`, `"iris_wipe"`,
- `mlua:color`: Returns the fill color as four numbers: `r, g, b, a`.
- `mlua:setColor`: Updates the fill color from `{r, g, b, a?}`.
- `mlua:type`: Type.
- `mlua:typeOf`: Type of.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/effect/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
