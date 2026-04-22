# camera

## General Info

- Module group: `Platform Services`
- Source path: `src/camera/`
- Lua API path(s): `src/lua_api/camera_api.rs`
- Primary Lua namespace: `lurek.camera`
- Rust test path(s): tests/rust/unit/camera_tests.rs
- Lua test path(s): tests/lua/unit/test_camera.lua, tests/lua/stress/test_camera_stress.lua, tests/lua/integration/test_tween_camera.lua, tests/lua/integration/test_tilemap_camera.lua, tests/lua/integration/test_scene_camera.lua, tests/lua/integration/test_parallax_camera.lua, tests/lua/integration/test_input_camera.lua, tests/lua/integration/test_render_camera.lua

## Summary

The `camera` module provides Lurek2D's camera and viewport types for 2D rendering. It is a Foundations tier module that imports only from `crate::math`, so it can be used in tests and non-rendering contexts without any platform dependencies.

Two camera types are provided. `Camera` is the flat API variant: it holds a 2D position, zoom level, and rotation angle, and exposes `view_matrix()` to compute the `Mat3` transform applied to all world-space draw commands. `Camera2D` extends `Camera` with smooth-follow behaviour (spring-based lerp toward a target entity position), screen-shake (time-decaying offset with configurable magnitude and frequency), and axis-locked follow bounds (a dead zone rectangle the target must leave before the camera begins moving).

`Viewport` maps the fixed game resolution onto the physical window size through a configurable `ScaleMode`: `Expand` (the game canvas grows with the window), `FixedWidth` (height grows, width is fixed), `PixelPerfect` (integer scaling only), and `Stretch` (the game canvas is always stretched to fill the window with no aspect-ratio preservation). `ViewportScale` extends `Viewport` with automatic scaled-dimension tracking for integration with the render transform stack, emitting content width/height alongside the computed scale factor.

`SharedState` holds a single `Camera` field; the `lua_api/camera_api.rs` bridge exposes the full `Camera2D` method set to Lua scripts as `lurek.camera.*`.

Two new source files add cinematic camera capabilities. `effects.rs` provides `ZoomPulse` (a brief zoom-in that decays via a sine envelope), `CameraSway` (sinusoidal x/y offset oscillation for underwater or rocking effects), and `CameraBreathing` (subtle periodic zoom for a living-camera feel). `path.rs` provides `CameraPath` for smooth world-space waypoint-following over a fixed duration and `ZoomTween` for linear zoom transitions. `Camera2D` gains the computed properties `effective_zoom` and `effect_offset`. The Lua surface adds `followPath/stopPath/updatePath/pathProgress` for path-following control, `zoomTo/stopZoom/updateZoom` for zoom animation, `setParallaxFactor/getParallaxFactor/clearParallaxFactors` for per-camera parallax scaling, and `zoomPulse`, `stopSway/isSway`, and `startBreathing/stopBreathing/isBreathing` for the cinematic effect bindings.

**Scope boundary**: Foundations tier. Depends only on `math`. Lua bridge in `src/lua_api/camera_api.rs`.

## Files

- `effects.rs`: Cinematic camera effects: zoom pulse, sway, and breathing.
- `mod.rs`: Declares the camera submodules and re-exports the public camera and viewport surface.
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
- `ZoomTween` (`struct`, `path.rs`): Smoothly transitions a camera zoom level from a start value to a target value over a fixed duration (linear interpolation).
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
- `ZoomTween::new` (`path.rs`): Creates a new `ZoomTween`.
- `ZoomTween::update` (`path.rs`): Advances the tween by `dt` seconds and returns the current zoom, or `None` when the tween has completed.
- `ZoomTween::progress` (`path.rs`): Returns the fractional progress `[0, 1]` of the tween.
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

### `Camera2D` Methods
- `Camera2D:setPosition`: Sets the camera's world-space position.
- `Camera2D:getPosition`: Returns the camera's world-space position as x, y.
- `Camera2D:setZoom`: Sets the uniform zoom factor (1.0 = natural size).
- `Camera2D:getZoom`: Returns the current zoom factor.
- `Camera2D:setRotation`: Sets the rotation in radians.
- `Camera2D:getRotation`: Returns the rotation in radians.
- `Camera2D:getViewport`: Returns the current viewport as x, y, w, h.
- `Camera2D:removeBounds`: Removes previously set world-space bounds.
- `Camera2D:setTarget`: Sets the follow target position.
- `Camera2D:clearTarget`: Clears the follow target so the camera stops tracking.
- `Camera2D:setFollowSmooth`: Sets the follow smooth interpolation speed (0.0 = instant snap).
- `Camera2D:setDeadZone`: Sets the dead zone half-extents for camera follow.
- `Camera2D:setLookAhead`: Sets the look-ahead multiplier for follow prediction.
- `Camera2D:shake`: Starts a screen-shake effect.
- `Camera2D:update`: Advances the camera simulation by dt seconds.
- `Camera2D:toWorld`: Converts screen coordinates to world coordinates.
- `Camera2D:toScreen`: Converts world coordinates to screen coordinates.
- `Camera2D:getVisibleArea`: Returns the visible world area as x, y, w, h.
- `Camera2D:lookAt`: Instantly moves the camera to look at the given position.
- `Camera2D:move`: Translates the camera by dx, dy in world space.
- `Camera2D:stopPath`: Cancels the active camera path animation.
- `Camera2D:updatePath`: Advances the path animation by `dt` seconds and applies the
- `Camera2D:pathProgress`: Returns the fractional progress `[0, 1]` of the active path, or
- `Camera2D:zoomTo`: Smoothly tweens the camera zoom from its current level to
- `Camera2D:stopZoom`: Cancels the active zoom tween.
- `Camera2D:updateZoom`: Advances the zoom tween by `dt` seconds and applies the resulting
- `Camera2D:getParallaxFactor`: Returns the parallax factor for the named layer, or `1.0` if unset.
- `Camera2D:clearParallaxFactors`: Removes all parallax factor overrides.
- `Camera2D:zoomPulse`: Triggers a momentary zoom-in that decays back via a sine envelope.
- `Camera2D:stopSway`: Stops the active sway effect immediately.
- `Camera2D:isSway`: Returns true if the sway effect is currently active.
- `Camera2D:stopBreathing`: Stops the active breathing effect.
- `Camera2D:isBreathing`: Returns true if the breathing effect is currently active.
- `Camera2D:getEffectiveZoom`: Returns the current zoom level including zoom pulse and breathing deltas.
- `Camera2D:getEffectOffset`: Returns the current sway x, y world-space offset.

## References

- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.

## Notes

- Keep this module reference synchronized with `src/camera/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
