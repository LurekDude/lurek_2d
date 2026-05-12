# camera

## General Info

- Module group: `Platform Services`
- Source path: `src/camera/`
- Lua API path(s): `src/lua_api/camera_api.rs`
- Primary Lua namespace: `lurek.camera`
- Rust test path(s): tests/rust/unit/camera_tests.rs, tests/rust/stress/camera_fuzz_tests.rs
- Lua test path(s): tests/lua/unit/test_camera.lua, tests/lua/stress/test_camera_stress.lua, tests/lua/integration/test_tween_camera.lua, tests/lua/integration/test_tilemap_camera.lua, tests/lua/integration/test_scene_camera.lua, tests/lua/integration/test_parallax_camera.lua, tests/lua/integration/test_input_camera.lua, tests/lua/integration/test_render_camera.lua

## Summary

The `camera` module provides Lurek2D's camera, viewport, and cinematic effects system — a Platform Services tier module that imports only from `crate::math`, making it usable in tests and non-rendering contexts without platform dependencies.

**Camera2D — the primary type.** `Camera2D` holds position, zoom level, rotation angle, and a full set of gameplay follow behaviours:
- *Smooth follow*: spring-based exponential lerp toward a target entity position with configurable `follow_speed`.
- *Dead zone*: a rectangular region around the camera center where the target can move without triggering camera movement.
- *Look-ahead*: optional velocity-based forward prediction so the camera shows more of where the player is heading.
- *Bounds clamping*: the camera can be constrained to a world-space AABB so it never shows outside the level.
- *Screen shake*: time-decaying additive offset with configurable magnitude and frequency, applied after follow computation.
- *Zoom constraints*: optional min/max zoom levels with damping for smooth transitions.
- *Rotation constraints*: optional min/max rotation angles with damping for smooth transitions.
- *Follow presets*: configurable camera profiles (tight, cinematic, balanced, aggressive) for common gameplay scenarios.

`Camera` is the minimal flat variant — position, zoom, rotation — and `view_matrix()` produces the `Mat3` applied to all world-space draw commands.

**Viewport.** `Viewport` maps the fixed logical game resolution onto the physical window through three `ScaleMode` variants: `Letterbox` (preserve aspect ratio with bars), `Stretch` (fill window ignoring aspect ratio), and `PixelPerfect` (integer-only scaling). `ViewportScale` extends `Viewport` with scaled content-dimension tracking for the render transform stack. Both now use a shared `ScaleMode::compute_transforms()` helper to eliminate code duplication.

**Cinematic effects.** `effects.rs` adds three time-based overlays applied on top of follow and shake:
- `ZoomPulse`: brief zoom-in that decays back to base zoom via a sine envelope — useful for hit impacts.
- `CameraSway`: sinusoidal x/y offset oscillation for underwater or rocking effects.
- `CameraBreathing`: subtle periodic zoom oscillation for a living-camera feel during cutscenes.
All effects are now integrated into rendering via `effective_zoom()` and `effect_offset()`.

**Camera path.** `path.rs` provides `CameraPath` for smooth world-space waypoint following over a fixed duration (linear interpolation between consecutive waypoints), and `CameraZoomTween` (alias: `ZoomTween`) for zoom-level transitions. Both are non-blocking — `update(dt)` drives them and returns `true` when complete.

**Easing-aware camera motion.** Camera follow and zoom transitions now support easing modes beyond linear interpolation. `Camera2D` exposes follow easing (`linear`, `smoothstep`, `easeout`) and `ZoomTween` supports camera-local easing variants.

**Multi-camera orchestration.** `multi.rs` adds `CameraRig2D`, a named camera rig for split-screen (`left`/`right`), minimap (`main`/`minimap`), and picture-in-picture (`main`/`pip`) layouts.

**Parallax scaling.** Per-camera parallax factors map layer scroll speeds to the camera's view-matrix. `set_parallax_factor(layer_id, factor)` / `get_parallax_factor(layer_id)` / `clear_parallax_factors()` let each camera drive a different parallax coefficient, enabling split-screen scenes with independent depth illusions.

**Render integration.** `render.rs` converts camera state into `RenderCommand` sequences: push transform → translate (with sway and shake offsets) → rotate → scale (using effective zoom) → pop transform. The bridge layer invokes this before the game's draw callback so Lua scripts see the camera applied transparently, including all active effects.

`render.rs` also provides allocation-free append helpers so hot-path camera application can reuse the global render command buffer without per-frame temporary `Vec<RenderCommand>` allocations.

**Coordinate helpers.** `world_to_screen(x, y)` and `screen_to_world(x, y)` convert between coordinate spaces using the current view-matrix and viewport scale, exposed to Lua for picking and UI-anchoring.

**Lua surface.** Core methods: `getPosition()`, `setPosition`, `getZoom`, `setZoom`, `getRotation`, `setRotation`, `setTarget()`, `setDeadZone(w, h)`, `setBounds(xmin, ymin, xmax, ymax)`, `shake(magnitude, duration)`, `toWorld`, `toScreen`.

Follow behavior: `setFollowSmooth(speed)`, `setLookAhead(multiplier)`, `update(dt)`.

Follow easing and resize helpers: `setFollowEasing(mode)`, `getFollowEasing()`, `onWindowResize(windowW, windowH)`, `onWindowResizeScaled(gameW, gameH, windowW, windowH, mode)`.

Constraints: `setZoomConstraints(min, max)`, `getZoomConstraints()`, `setZoomDamping(factor)`, `getZoomDamping()`, `setRotationConstraints(min, max)`, `getRotationConstraints()`, `setRotationDamping(factor)`, `getRotationDamping()`.

Presets: `presetTightFollow()`, `presetCinematicFollow()`, `presetBalancedFollow()`, `presetAggressiveFollow()`.

Path and zoom: `followPath(waypoints, duration)`, `stopPath()`, `pathProgress()`, `zoomTo(target, duration)`, `stopZoom()`, `updateZoom(dt)`.

Effects: `zoomPulse(amplitude, duration)`, `startSway(amplitude_x, amplitude_y, frequency, decay)`, `stopSway()`, `isSway()`, `startBreathing(amplitude, rate)`, `stopBreathing()`, `isBreathing()`, `getEffectiveZoom()`, `getEffectOffset()`.

Parallax: `setParallaxFactor(layer, factor)`, `getParallaxFactor(layer)`, `clearParallaxFactors()`.

Render: `apply()`, `reset()`, `attach()`, `detach()`.

Rig: `newRig()`, `LCameraRig:splitScreen()`, `LCameraRig:minimap()`, `LCameraRig:pictureInPicture()`, `LCameraRig:setPosition()`, `LCameraRig:setZoom()`, `LCameraRig:setTarget()`, `LCameraRig:updateAll()`, `LCameraRig:apply()`, `LCameraRig:getViewport()`, `LCameraRig:names()`, `LCameraRig:remove()`, `LCameraRig:has()`.

**Scope boundary.** Platform Services tier. Depends only on `math`. Lua bridge in `src/lua_api/camera_api.rs`.

## Files

- `effects.rs`: Cinematic camera effects: zoom pulse, sway, and breathing.
- `mod.rs`: Declares the camera submodules and re-exports the public camera and viewport surface.
- `multi.rs`: Named multi-camera rig orchestration for split-screen, minimap, and picture-in-picture.
- `path.rs`: Camera path follower and smooth-zoom tween for [`super::Camera2D`].
- `render.rs`: Converts Camera and Camera2D state into push, translate, rotate, scale, and pop render commands.
- `types.rs`: Defines Camera and Camera2D, including transforms, follow logic, bounds, shake, and coordinate conversion.
- `viewport.rs`: Defines ScaleMode and Viewport for logical-resolution scaling and coordinate mapping.
- `viewport_scale.rs`: Defines ViewportScale, a viewport helper that also tracks scaled output dimensions.

## Types

- `ZoomPulse` (`struct`, `effects.rs`): Zoom pulse effect — brief zoom-in that decays back to the original zoom via a sine envelope.
- `CameraSway` (`struct`, `effects.rs`): Camera sway — sinusoidal x/y offset oscillation for rocking or underwater effects.
- `CameraBreathing` (`struct`, `effects.rs`): Camera breathing — subtle periodic zoom oscillation for a "living camera" feel.
- `CameraPath` (`struct`, `path.rs`): Animates a camera along a series of world-space waypoints over a fixed duration using linear interpolation between consecutive points.
- `CameraTweenEasing` (`enum`, `path.rs`): Easing mode for camera-local tweening.
- `CameraZoomTween` (`struct`, `path.rs`): Smoothly transitions a camera zoom level from a start value to a target value over a fixed duration.
- `ZoomTween` (`type`, `path.rs`): Backward-compatible alias for `CameraZoomTween`.
- `Camera` (`struct`, `types.rs`): Lightweight camera state with position, zoom, rotation, and view-matrix generation.
- `Camera2D` (`struct`, `types.rs`): Gameplay-facing 2D camera with follow targets, dead zones, look-ahead, bounds clamping, shake, and coordinate helpers.
- `ScaleMode` (`enum`, `viewport.rs`): Enum selecting letterbox, stretch, or pixel-perfect viewport behavior.
- `Viewport` (`struct`, `viewport.rs`): Logical-resolution mapper that computes scale and offset for letterbox, stretch, and pixel-perfect modes.
- `ViewportScale` (`struct`, `viewport_scale.rs`): Viewport variant that also tracks scaled pixel dimensions for transform-stack integration.

## Functions

- `ZoomPulse::new` (`effects.rs`): Creates a new, inactive `ZoomPulse`.
- `ZoomPulse::trigger` (`effects.rs`): Triggers a new zoom pulse, replacing any active one.
- `ZoomPulse::update` (`effects.rs`): Advances the pulse by `dt` seconds and returns the current zoom delta.
- `ZoomPulse::current_delta` (`effects.rs`): Returns the current zoom delta without advancing time.
- `ZoomPulse::is_active` (`effects.rs`): Returns `true` if the pulse is currently active.
- `CameraSway::new` (`effects.rs`): Creates a new, inactive `CameraSway`.
- `CameraSway::start` (`effects.rs`): Starts or restarts the sway effect.
- `CameraSway::stop` (`effects.rs`): Stops the sway effect immediately.
- `CameraSway::update` (`effects.rs`): Advances sway by `dt` seconds and returns the `(dx, dy)` world-space offset.
- `CameraSway::current_offset` (`effects.rs`): Returns the current `(dx, dy)` sway offset without advancing time.
- `CameraSway::is_active` (`effects.rs`): Returns `true` if sway is currently active.
- `CameraBreathing::new` (`effects.rs`): Creates a new, inactive `CameraBreathing` with default parameters (`amplitude=0.005`, `rate=0.2`).
- `CameraBreathing::start` (`effects.rs`): Starts or restarts the breathing effect.
- `CameraBreathing::stop` (`effects.rs`): Stops the breathing effect.
- `CameraBreathing::update` (`effects.rs`): Advances breathing by `dt` seconds and returns the current zoom delta.
- `CameraBreathing::current_delta` (`effects.rs`): Returns the current zoom delta without advancing time.
- `CameraBreathing::is_active` (`effects.rs`): Returns `true` if breathing is currently active.
- `CameraPath::new` (`path.rs`): Creates a new `CameraPath`.
- `CameraPath::update` (`path.rs`): Advances the path by `dt` seconds and returns the current position, or `None` when the path has completed.
- `CameraPath::progress` (`path.rs`): Returns the fractional progress `[0, 1]` of the path.
- `CameraPath::reset` (`path.rs`): Resets the path back to the beginning.
- `CameraZoomTween::new` (`path.rs`): Creates a new `CameraZoomTween`.
- `CameraZoomTween::new_with_easing` (`path.rs`): Creates a new `CameraZoomTween` with explicit easing.
- `CameraZoomTween::update` (`path.rs`): Advances the tween by `dt` seconds and returns the current zoom, or `None` when the tween has completed.
- `CameraZoomTween::progress` (`path.rs`): Returns the fractional progress `[0, 1]` of the tween.
- `Camera::begin_render_commands` (`render.rs`): Produces transform-stack render commands for this camera.
- `Camera::end_render_command` (`render.rs`): Returns the `PopTransform` command that closes the camera scope.
- `Camera::generate_render_commands` (`render.rs`): Wrap `scene_commands` in the camera's transform scope.
- `Camera2D::begin_render_commands` (`render.rs`): Produces transform-stack render commands for this camera.
- `Camera2D::end_render_command` (`render.rs`): Returns the `PopTransform` command that closes the camera scope.
- `Camera2D::generate_render_commands` (`render.rs`): Wrap `scene_commands` in the camera's transform scope.
- `Camera::new` (`types.rs`): Creates a new `Camera` with the given position, zoom, and rotation.
- `Camera::view_matrix` (`types.rs`): Computes the view transformation matrix for this camera.
- `Camera::set_position` (`types.rs`): Moves the camera to `position` in world space.
- `Camera::set_zoom` (`types.rs`): Sets the camera's zoom level.
- `Camera::set_rotation` (`types.rs`): Sets the camera's rotation in radians.
- `Camera2D::new` (`types.rs`): Creates a new `Camera2D` centred at the origin with the given viewport
- `Camera2D::set_position` (`types.rs`): Sets the camera position in world space.
- `Camera2D::get_position` (`types.rs`): Returns the camera position as `(x, y)`.
- `Camera2D::set_zoom` (`types.rs`): Sets the uniform zoom factor.
- `Camera2D::get_zoom` (`types.rs`): Returns the current zoom factor.
- `Camera2D::set_rotation` (`types.rs`): Sets the rotation in radians.
- `Camera2D::get_rotation` (`types.rs`): Returns the current rotation in radians.
- `Camera2D::set_viewport` (`types.rs`): Sets the viewport rectangle in screen pixels.
- `Camera2D::get_viewport` (`types.rs`): Returns the viewport as `(x, y, w, h)`.
- `Camera2D::set_bounds` (`types.rs`): Sets world-space bounds for camera clamping.
- `Camera2D::get_bounds` (`types.rs`): Returns the world-space bounds, if set.
- `Camera2D::remove_bounds` (`types.rs`): Removes previously set bounds.
- `Camera2D::has_bounds` (`types.rs`): Returns `true` if world-space bounds are set.
- `Camera2D::move_by` (`types.rs`): Translates the camera by `(dx, dy)` in world space.
- `Camera2D::look_at` (`types.rs`): Sets the camera position directly (shorthand for [`set_position`](Self::set_position)).
- `Camera2D::to_world_coords` (`types.rs`): Converts screen coordinates to world coordinates.
- `Camera2D::to_screen_coords` (`types.rs`): Converts world coordinates to screen coordinates.
- `Camera2D::get_visible_area` (`types.rs`): Returns the world-space axis-aligned bounding box of the visible area
- `Camera2D::set_dead_zone` (`types.rs`): Sets the dead zone half-extents.
- `Camera2D::get_dead_zone` (`types.rs`): Returns the dead zone as `(width, height)` (full extents), if set.
- `Camera2D::set_target` (`types.rs`): Sets the follow target position.
- `Camera2D::get_target` (`types.rs`): Returns the current follow target, if any.
- `Camera2D::clear_target` (`types.rs`): Clears the follow target so the camera stops tracking.
- `Camera2D::set_follow_smooth` (`types.rs`): Sets the smooth follow interpolation speed.
- `Camera2D::get_follow_smooth` (`types.rs`): Returns the smooth follow speed.
- `Camera2D::set_look_ahead` (`types.rs`): Sets the look-ahead multiplier.
- `Camera2D::get_look_ahead` (`types.rs`): Returns the look-ahead multiplier.
- `Camera2D::shake` (`types.rs`): Starts a camera shake effect.
- `Camera2D::update` (`types.rs`): Processes smooth follow, camera shake, and bounds clamping.
- `Camera2D::effective_zoom` (`types.rs`): Returns the effective zoom level, combining the base zoom with active zoom pulse and breathing effect deltas.
- `Camera2D::effect_offset` (`types.rs`): Returns the current world-space position offset contributed by the active sway effect as `(dx, dy)`.
- `Camera2D::view_matrix` (`types.rs`): Computes the view matrix including the shake offset.
- `Viewport::new` (`viewport.rs`): Create a viewport with the given game dimensions and scale mode.
- `Viewport::resize` (`viewport.rs`): Recompute scale and offset based on the current window size.
- `Viewport::get_scale` (`viewport.rs`): Current scale factors `(scale_x, scale_y)`.
- `Viewport::get_offset` (`viewport.rs`): Current offset `(offset_x, offset_y)`.
- `Viewport::get_game_dimensions` (`viewport.rs`): Game dimensions `(game_width, game_height)`.
- `Viewport::get_scale_mode` (`viewport.rs`): Reference to the current scale mode.
- `Viewport::set_scale_mode` (`viewport.rs`): Set the scale mode.
- `Viewport::to_game` (`viewport.rs`): Convert screen coordinates to game coordinates.
- `Viewport::to_screen` (`viewport.rs`): Convert game coordinates to screen coordinates.
- `ViewportScale::new` (`viewport_scale.rs`): Create a viewport scale with the given game dimensions and mode.
- `ViewportScale::resize` (`viewport_scale.rs`): Recompute all derived values from the current window size.
- `ViewportScale::get_game_dimensions` (`viewport_scale.rs`): Game dimensions `(game_width, game_height)`.
- `ViewportScale::get_scaled_dimensions` (`viewport_scale.rs`): Scaled content dimensions `(scaled_width, scaled_height)`.
- `ViewportScale::get_offset` (`viewport_scale.rs`): Current offset `(offset_x, offset_y)`.
- `ViewportScale::get_scale` (`viewport_scale.rs`): Current scale factors `(scale_x, scale_y)`.
- `ViewportScale::get_mode` (`viewport_scale.rs`): Reference to the active scale mode.
- `ViewportScale::to_game_coords` (`viewport_scale.rs`): Convert screen coordinates to game coordinates.
- `ViewportScale::to_screen_coords` (`viewport_scale.rs`): Convert game coordinates to screen coordinates.

## Lua API Reference

- Binding path(s): `src/lua_api/camera_api.rs`
- Namespace: `lurek.camera`

### Module Functions
- `lurek.camera.new`: Creates a new Camera2D with the given viewport dimensions.
- `lurek.camera.newCamera`: Creates a new 2D camera with the given viewport dimensions.
- `lurek.camera.newRig`: Creates a new multi-camera rig object.

### `LCamera` Methods
- `LCamera:setPosition`: Sets the camera's world-space position to the given coordinates.
- `LCamera:getPosition`: Returns the camera's current world-space position as two values.
- `LCamera:setZoom`: Sets the camera's uniform zoom factor.
- `LCamera:getZoom`: Returns the camera's current base zoom factor (before any pulse or breathing effect is applied).
- `LCamera:setRotation`: Sets the camera rotation angle in radians.
- `LCamera:getRotation`: Returns the camera's current rotation angle in radians.
- `LCamera:setViewport`: Sets the screen-space viewport rectangle in pixels.
- `LCamera:getViewport`: Returns the current screen-space viewport rectangle as four values.
- `LCamera:setBounds`: Sets world-space rectangular bounds that clamp the camera position.
- `LCamera:removeBounds`: Removes previously set world-space bounds, allowing the camera to move freely in any direction without clamping.
- `LCamera:setTarget`: Sets the follow target position in world space.
- `LCamera:clearTarget`: Clears the follow target so the camera stops tracking any position.
- `LCamera:setFollowSmooth`: Sets the follow interpolation speed for smooth camera tracking.
- `LCamera:setDeadZone`: Sets the dead zone half-extents for camera follow.
- `LCamera:setLookAhead`: Sets the look-ahead multiplier for predictive camera follow.
- `LCamera:shake`: Starts a screen-shake effect with the given intensity and duration.
- `LCamera:update`: Advances the camera simulation by `dt` seconds.
- `LCamera:toWorld`: Converts screen-space pixel coordinates to world-space coordinates accounting for the camera's position, zoom, rotation, and viewport.
- `LCamera:toScreen`: Converts world-space coordinates to screen-space pixel coordinates accounting for the camera's position, zoom, rotation, and viewport.
- `LCamera:getVisibleArea`: Returns the axis-aligned bounding rectangle of the currently visible world area as four values.
- `LCamera:lookAt`: Instantly snaps the camera to look at the given world-space position.
- `LCamera:move`: Translates the camera by the given delta in world space.
- `LCamera:followPath`: Animates the camera along a sequence of world-space waypoints over the given duration (seconds).
- `LCamera:stopPath`: Cancels the active camera path animation immediately, leaving the camera at its current position along the path.
- `LCamera:updatePath`: Advances the path animation by `dt` seconds and applies the resulting position to the camera.
- `LCamera:pathProgress`: Returns the fractional progress `[0, 1]` of the active path, or `1` if no path is running.
- `LCamera:zoomTo`: Smoothly tweens the camera zoom from its current level to `target_zoom` over `duration` seconds.
- `LCamera:stopZoom`: Cancels the active smooth zoom tween immediately, leaving the camera at its current zoom level.
- `LCamera:updateZoom`: Advances the zoom tween by `dt` seconds and applies the resulting zoom level to the camera.
- `LCamera:setParallaxFactor`: Sets the parallax scroll factor for the named render layer.
- `LCamera:getParallaxFactor`: Returns the parallax scroll factor for the named render layer.
- `LCamera:clearParallaxFactors`: Removes all parallax factor overrides, resetting every layer to the default factor of 1.0 (no parallax).
- `LCamera:apply`: Applies this camera's transform to the render stack.
- `LCamera:reset`: Pops the camera transform from the render stack.
- `LCamera:attach`: Alias for `apply()` that queues this camera's transform onto the render command stack.
- `LCamera:detach`: Alias for `reset()` that removes this camera's transform from the render command stack.
- `LCamera:zoomPulse`: Triggers a momentary zoom-in effect that decays back to the base zoom level via a sine envelope.
- `LCamera:startSway`: Starts a sinusoidal x/y offset oscillation for ambient camera motion (e.g.
- `LCamera:stopSway`: Stops the active sway oscillation effect immediately, resetting the camera's offset back to zero.
- `LCamera:isSway`: Returns true if the sway oscillation effect is currently running.
- `LCamera:startBreathing`: Starts a subtle periodic zoom oscillation that gives the camera a "living" feel, as if the viewport is gently breathing.
- `LCamera:stopBreathing`: Stops the active breathing zoom oscillation effect immediately.
- `LCamera:isBreathing`: Returns true if the breathing zoom oscillation is currently active.
- `LCamera:getEffectiveZoom`: Returns the current zoom level including contributions from zoom pulse and breathing effects on top of the base zoom factor.
- `LCamera:getEffectOffset`: Returns the current world-space x/y offset contributed by the sway and shake effects.
- `LCamera:type`: Returns the string type name of this userdata object.
- `LCamera:typeOf`: Checks whether this object matches the given type name.

## References

- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.

## Notes

- Keep this module reference synchronized with `src/camera/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
