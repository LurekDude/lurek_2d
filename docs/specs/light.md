# light

## General Info

- Module group: `Platform Services`
- Source path: `src/light/`
- Lua API path(s): `src/lua_api/light_api.rs`
- Primary Lua namespace: `lurek.light`
- Rust test path(s): tests/rust/unit/light_tests.rs
- Lua test path(s): tests/lua/unit/test_light.lua, tests/lua/stress/test_light_stress.lua, tests/lua/integration/test_light_render.lua, tests/lua/evidence/test_evidence_light.lua

## Summary

The `light` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `math`, `runtime`. Its responsibility should stay inside the Platform Services group rather than absorb behavior owned by those neighbors.

## Files

- `attenuation.rs`: Defines coefficient-based attenuation for custom distance decay.
- `blend_mode.rs`: Defines how light mixes with the scene.
- `falloff.rs`: Defines the high-level radial falloff enum.
- `flicker.rs`: Defines flicker configuration and phase advancement helpers.
- `light2d.rs`: Defines Light2D, the main per-light data record with position, radius, color, intensity, masks, shadows, geometry, attenuation, flicker, and grouping.
- `light_type.rs`: Defines the geometric light-type enum for point, directional, and spot lights.
- `light_world.rs`: Defines LightWorld, the keyed container for active lights, occluders, ambient color, limits, and group operations.
- `mod.rs`: Declares the lighting submodules and re-exports the public light types.
- `occluder.rs`: Defines Occluder, a polygon shadow caster with transform, opacity, mask, and enabled state.
- `shadow.rs`: Defines the shadow edge-filter enum.
- `transition.rs`: Smooth linear transition for light color, intensity, and radius.

## Types

- `Attenuation` (`struct`, `attenuation.rs`): Coefficient-based custom falloff model.
- `LightBlendMode` (`enum`, `blend_mode.rs`): Enum controlling additive, subtractive, or mixed scene contribution.
- `FalloffMode` (`enum`, `falloff.rs`): Enum describing how intensity decays from center to edge.
- `FlickerConfig` (`struct`, `flicker.rs`): Time-varying intensity modulation for torches, unstable lights, and similar effects.
- `Light2D` (`struct`, `light2d.rs`): Main per-light data container used by Lua and the renderer-facing lighting world.
- `LightType` (`enum`, `light_type.rs`): Enum distinguishing point, directional, and spot light behavior.
- `LightWorld` (`struct`, `light_world.rs`): Owner of the light and occluder pools, ambient settings, limits, and group operations.
- `NormalMapLightHint` (`struct`, `light_world.rs`): Snapshot of a single light's normal-map binding used by the renderer for surface shading.
- `Occluder` (`struct`, `occluder.rs`): Polygon shadow caster with vertices, transform, opacity, mask, and enabled state.
- `ShadowFilter` (`enum`, `shadow.rs`): Enum selecting the shadow edge filtering quality.
- `LightTransition` (`struct`, `transition.rs`): Linearly interpolates a [`super::Light2D`]'s color, intensity, and radius from their current values to target values over a fixed duration.

## Functions

- `Attenuation::new` (`attenuation.rs`): Create a new attenuation with explicit constant, linear, and quadratic coefficients.
- `Attenuation::factor` (`attenuation.rs`): Return attenuation factor at `distance`; returns 1.0 when denominator is <= 0.
- `Attenuation::draw_attenuation_curves_to_image` (`attenuation.rs`): Render labeled attenuation curve plots for each config into an `ImageData` for debug output.
- `FlickerConfig::new` (`flicker.rs`): Create an enabled flicker with given speed and strength; phase starts at 0.
- `FlickerConfig::multiplier` (`flicker.rs`): Return the current intensity multiplier; returns 1.0 when disabled.
- `FlickerConfig::advance` (`flicker.rs`): Advance the flicker phase by `dt` seconds, wrapping at TAU.
- `Light2D::new` (`light2d.rs`): Create a point light at `(x, y)` with `radius`; all other fields default.
- `Light2D::set_position` (`light2d.rs`): Set world-space position and log at trace level.
- `Light2D::get_position` (`light2d.rs`): Return world-space `(x, y)` position.
- `Light2D::set_radius` (`light2d.rs`): Set the light radius and log at trace level.
- `Light2D::get_radius` (`light2d.rs`): Return the current light radius.
- `Light2D::set_color` (`light2d.rs`): Set the RGBA tint color.
- `Light2D::get_color` (`light2d.rs`): Return the RGBA tint color.
- `Light2D::set_intensity` (`light2d.rs`): Set the intensity multiplier.
- `Light2D::get_intensity` (`light2d.rs`): Return the intensity multiplier.
- `Light2D::set_enabled` (`light2d.rs`): Enable or disable this light.
- `Light2D::is_enabled` (`light2d.rs`): Return whether the light is enabled.
- `Light2D::set_energy` (`light2d.rs`): Set the energy scale.
- `Light2D::get_energy` (`light2d.rs`): Return the energy scale.
- `Light2D::set_blend_mode` (`light2d.rs`): Set the accumulation blend mode.
- `Light2D::get_blend_mode` (`light2d.rs`): Return the accumulation blend mode.
- `Light2D::set_falloff` (`light2d.rs`): Set the radial falloff curve.
- `Light2D::get_falloff` (`light2d.rs`): Return the radial falloff curve.
- `Light2D::set_shadow_enabled` (`light2d.rs`): Enable or disable shadow casting.
- `Light2D::is_shadow_enabled` (`light2d.rs`): Return whether shadow casting is enabled.
- `Light2D::set_shadow_color` (`light2d.rs`): Set the shadow tint color.
- `Light2D::get_shadow_color` (`light2d.rs`): Return the shadow tint color.
- `Light2D::set_shadow_filter` (`light2d.rs`): Set the shadow filter quality preset.
- `Light2D::get_shadow_filter` (`light2d.rs`): Return the shadow filter quality preset.
- `Light2D::set_shadow_smooth` (`light2d.rs`): Set the shadow edge smooth factor.
- `Light2D::get_shadow_smooth` (`light2d.rs`): Return the shadow edge smooth factor.
- `Light2D::set_shadow_softness` (`light2d.rs`): Set the overall shadow softness scale.
- `Light2D::get_shadow_softness` (`light2d.rs`): Return the overall shadow softness scale.
- `Light2D::set_light_mask` (`light2d.rs`): Set the layer bitmask for which geometry this light illuminates.
- `Light2D::get_light_mask` (`light2d.rs`): Return the illumination layer bitmask.
- `Light2D::set_shadow_mask` (`light2d.rs`): Set the layer bitmask for which geometry casts shadows.
- `Light2D::get_shadow_mask` (`light2d.rs`): Return the shadow caster layer bitmask.
- `Light2D::set_light_type` (`light2d.rs`): Set the light type discriminant.
- `Light2D::get_light_type` (`light2d.rs`): Return the light type discriminant.
- `Light2D::set_direction` (`light2d.rs`): Set the spot-light direction angle in radians.
- `Light2D::get_direction` (`light2d.rs`): Return the spot-light direction angle in radians.
- `Light2D::set_inner_angle` (`light2d.rs`): Set the inner cone half-angle in radians for spot lights.
- `Light2D::get_inner_angle` (`light2d.rs`): Return the inner cone half-angle in radians.
- `Light2D::set_outer_angle` (`light2d.rs`): Set the outer cone half-angle in radians for spot lights.
- `Light2D::get_outer_angle` (`light2d.rs`): Return the outer cone half-angle in radians.
- `Light2D::set_attenuation` (`light2d.rs`): Set the quadratic attenuation coefficients.
- `Light2D::get_attenuation` (`light2d.rs`): Return the quadratic attenuation coefficients.
- `Light2D::flicker_mut` (`light2d.rs`): Return a mutable reference to the flicker config.
- `Light2D::flicker` (`light2d.rs`): Return a shared reference to the flicker config.
- `Light2D::set_group_id` (`light2d.rs`): Set the group id for light batching.
- `Light2D::get_group_id` (`light2d.rs`): Return the group id.
- `Light2D::set_volumetric` (`light2d.rs`): Enable or disable volumetric scattering.
- `Light2D::is_volumetric` (`light2d.rs`): Return whether volumetric scattering is enabled.
- `Light2D::set_normal_map_path` (`light2d.rs`): Set the normal map texture path, replacing any previous value.
- `Light2D::clear_normal_map_path` (`light2d.rs`): Clear the normal map texture path.
- `Light2D::get_normal_map_path` (`light2d.rs`): Return the normal map texture path if set.
- `Light2D::set_normal_strength` (`light2d.rs`): Set the normal map contribution strength; range [0.0, 1.0].
- `Light2D::get_normal_strength` (`light2d.rs`): Return the normal map contribution strength.
- `Light2D::draw_falloff_comparison_to_image` (`light2d.rs`): Render falloff comparison panels for each mode into an `ImageData` debug image.
- `LightWorld::new` (`light_world.rs`): Create an empty world with ambient=0.1, disabled, and max_lights=64.
- `LightWorld::add_light` (`light_world.rs`): Insert a light, enable the world if it was disabled, and return its key.
- `LightWorld::add_occluder` (`light_world.rs`): Insert an occluder and return its key.
- `LightWorld::remove_light` (`light_world.rs`): Remove a light by key and evict it from the flicker index; returns the removed light or `None`.
- `LightWorld::remove_occluder` (`light_world.rs`): Remove an occluder by key; returns the removed occluder or `None`.
- `LightWorld::get_light` (`light_world.rs`): Return a shared reference to the light at `key`, or `None` if not present.
- `LightWorld::get_light_mut` (`light_world.rs`): Return a mutable reference to the light at `key`, or `None` if not present.
- `LightWorld::get_occluder` (`light_world.rs`): Return a shared reference to the occluder at `key`, or `None` if not present.
- `LightWorld::get_occluder_mut` (`light_world.rs`): Return a mutable reference to the occluder at `key`, or `None` if not present.
- `LightWorld::light_count` (`light_world.rs`): Return the number of registered lights.
- `LightWorld::occluder_count` (`light_world.rs`): Return the number of registered occluders.
- `LightWorld::clear` (`light_world.rs`): Remove all lights and occluders and reset ambient to 0.1 gray.
- `LightWorld::has_active_lights` (`light_world.rs`): Return `true` if any registered light has `enabled = true`.
- `LightWorld::set_group_enabled` (`light_world.rs`): Set `enabled` on all lights in `group_id`.
- `LightWorld::set_group_intensity` (`light_world.rs`): Set `intensity` on all lights in `group_id`.
- `LightWorld::set_group_color` (`light_world.rs`): Set `color` on all lights in `group_id`.
- `LightWorld::group_count` (`light_world.rs`): Return the count of lights in `group_id`.
- `LightWorld::advance_flickers` (`light_world.rs`): Advance all flickering lights by `dt` seconds; rebuilds the flicker index if stale.
- `LightWorld::reindex_flickers` (`light_world.rs`): Rebuild the flicker key index from all lights that have flicker enabled.
- `LightWorld::draw_to_image` (`light_world.rs`): Render an approximate light-map preview of this world into an `ImageData` debug image.
- `LightWorld::ambient_color_hint` (`light_world.rs`): Return ambient color as an RGBA `[f32; 4]` array for shader upload.
- `LightWorld::directional_light_hints` (`light_world.rs`): Return `(x, y, direction)` tuples for all enabled directional lights.
- `LightWorld::normal_map_light_hints` (`light_world.rs`): Return `NormalMapLightHint` snapshots for all enabled lights that have a normal map path.
- `Occluder::new` (`occluder.rs`): Create an occluder from vertices; panics if count is outside 3..=512.
- `Occluder::set_vertices` (`occluder.rs`): Replace vertices; panics if new count is outside 3..=512.
- `Occluder::from_flat_coords` (`occluder.rs`): Build an occluder from a flat `[x, y, x, y, ...]` coordinate slice; returns error on invalid length.
- `Occluder::get_vertices` (`occluder.rs`): Return the vertex slice.
- `Occluder::set_position` (`occluder.rs`): Set the world-space position offset.
- `Occluder::get_position` (`occluder.rs`): Return the world-space position offset.
- `Occluder::set_opacity` (`occluder.rs`): Set shadow opacity; expected range [0.0, 1.0].
- `Occluder::get_opacity` (`occluder.rs`): Return shadow opacity.
- `Occluder::set_light_mask` (`occluder.rs`): Set the light-layer bitmask.
- `Occluder::get_light_mask` (`occluder.rs`): Return the light-layer bitmask.
- `Occluder::set_enabled` (`occluder.rs`): Enable or disable this occluder.
- `Occluder::is_enabled` (`occluder.rs`): Return whether this occluder is enabled.
- `LightTransition::new` (`transition.rs`): Create a new active transition between the given from/to values over `duration` seconds.
- `LightTransition::update` (`transition.rs`): Advance by `dt` seconds and return `Some((color, intensity, radius))`; returns `None` if inactive.
- `LightTransition::progress` (`transition.rs`): Return the normalised progress in [0.0, 1.0]; returns 1.0 when duration is zero.

## Lua API Reference

- Binding path(s): `src/lua_api/light_api.rs`
- Namespace: `lurek.light`

### Module Functions
- `lurek.light.newLight`: Creates a light and applies optional light settings.
- `lurek.light.newOccluder`: Creates an occluder from a flat vertex coordinate table and optional settings.
- `lurek.light.setAmbient`: Sets global ambient light color.
- `lurek.light.getAmbient`: Returns global ambient light color.
- `lurek.light.setEnabled`: Enables or disables the shared light world.
- `lurek.light.isEnabled`: Returns whether the shared light world is enabled.
- `lurek.light.getLightCount`: Returns the number of live lights.
- `lurek.light.getOccluderCount`: Returns the number of live occluders.
- `lurek.light.getMaxLights`: Returns the maximum configured light count.
- `lurek.light.setMaxLights`: Sets the maximum configured light count, clamped to 1 through 256.
- `lurek.light.clear`: Removes all lights and occluders from the light world.
- `lurek.light.setGroupEnabled`: Enables or disables all lights in a group.
- `lurek.light.setGroupIntensity`: Sets intensity for all lights in a group.
- `lurek.light.setGroupColor`: Sets color for all lights in a group.
- `lurek.light.getGroupCount`: Returns the number of lights in a group.
- `lurek.light.advanceFlickers`: Advances flicker animation for all indexed flickering lights.
- `lurek.light.syncAmbient`: Returns the light world's ambient color hint.
- `lurek.light.getGodRayHints`: Returns directional light hints for god-ray style effects.
- `lurek.light.getNormalMapHints`: Returns light hints that reference normal maps.

### `LLight` Methods
- `LLight:setPosition`: Sets this light position.
- `LLight:getPosition`: Returns this light position.
- `LLight:setRadius`: Sets this light radius.
- `LLight:getRadius`: Returns this light radius.
- `LLight:setColor`: Sets this light RGBA color.
- `LLight:getColor`: Returns this light RGBA color.
- `LLight:setIntensity`: Sets this light intensity.
- `LLight:getIntensity`: Returns this light intensity.
- `LLight:setEnergy`: Sets this light energy value.
- `LLight:getEnergy`: Returns this light energy value.
- `LLight:setBlendMode`: Sets this light blend mode.
- `LLight:getBlendMode`: Returns this light blend mode string.
- `LLight:setFalloff`: Sets this light falloff mode.
- `LLight:getFalloff`: Returns this light falloff mode string.
- `LLight:setShadowEnabled`: Enables or disables shadow casting for this light.
- `LLight:isShadowEnabled`: Returns whether this light casts shadows.
- `LLight:setShadowColor`: Sets this light shadow RGBA color.
- `LLight:getShadowColor`: Returns this light shadow RGBA color.
- `LLight:setShadowFilter`: Sets this light shadow filter.
- `LLight:getShadowFilter`: Returns this light shadow filter string.
- `LLight:setShadowSmooth`: Sets this light shadow smoothing value.
- `LLight:getShadowSmooth`: Returns this light shadow smoothing value.
- `LLight:setShadowSoftness`: Sets this light shadow softness value.
- `LLight:getShadowSoftness`: Returns this light shadow softness value.
- `LLight:setLightMask`: Sets this light's inclusion mask.
- `LLight:getLightMask`: Returns this light's inclusion mask.
- `LLight:setShadowMask`: Sets this light's shadow receiver mask.
- `LLight:getShadowMask`: Returns this light's shadow receiver mask.
- `LLight:setEnabled`: Enables or disables this light.
- `LLight:isEnabled`: Returns whether this light is enabled.
- `LLight:setLightType`: Sets this light type.
- `LLight:getLightType`: Returns this light type string.
- `LLight:setDirection`: Sets this light direction angle.
- `LLight:getDirection`: Returns this light direction angle.
- `LLight:setInnerAngle`: Sets this spot light inner cone angle.
- `LLight:getInnerAngle`: Returns this spot light inner cone angle.
- `LLight:setOuterAngle`: Sets this spot light outer cone angle.
- `LLight:getOuterAngle`: Returns this spot light outer cone angle.
- `LLight:setAttenuation`: Sets this light attenuation coefficients.
- `LLight:getAttenuation`: Returns this light attenuation coefficients.
- `LLight:setFlicker`: Configures flicker speed and strength for this light.
- `LLight:getFlicker`: Returns this light flicker speed and strength.
- `LLight:setFlickerEnabled`: Enables or disables this light flicker state.
- `LLight:isFlickerEnabled`: Returns whether this light flicker is enabled.
- `LLight:setGroupId`: Sets this light group id.
- `LLight:getGroupId`: Returns this light group id.
- `LLight:setVolumetric`: Enables or disables volumetric behavior for this light.
- `LLight:isVolumetric`: Returns whether this light is volumetric.
- `LLight:remove`: Removes this light from the shared light world.
- `LLight:isValid`: Returns whether this light handle still points to a live light.
- `LLight:addFlicker`: Adds flicker from min/max intensity range and frequency.
- `LLight:transitionTo`: Starts a transition toward target color, intensity, and radius values.
- `LLight:updateTransition`: Advances this light's active transition and applies interpolated values.
- `LLight:stopTransition`: Stops and clears this light's active transition.
- `LLight:transitionProgress`: Returns active transition progress or 1.0 when no transition is active.
- `LLight:setCookie`: Stores a cookie texture path on this Lua light handle.
- `LLight:getCookie`: Returns the cookie texture path stored on this Lua light handle.
- `LLight:clearCookie`: Clears the cookie texture path stored on this Lua light handle.
- `LLight:setNormalMap`: Sets the normal map path used by this light.
- `LLight:getNormalMap`: Returns the normal map path used by this light.
- `LLight:clearNormalMap`: Clears the normal map path used by this light.
- `LLight:setNormalStrength`: Sets this light's normal map strength.
- `LLight:getNormalStrength`: Returns this light's normal map strength.
- `LLight:type`: Returns the Lua-visible type name for this light handle.
- `LLight:typeOf`: Returns whether this light handle matches a supported type name.

### `LOccluder` Methods
- `LOccluder:setVertices`: Replaces this occluder's flat vertex coordinate list.
- `LOccluder:getVertices`: Returns this occluder's flat vertex coordinate list.
- `LOccluder:setPosition`: Sets this occluder position offset.
- `LOccluder:getPosition`: Returns this occluder position offset.
- `LOccluder:setOpacity`: Sets this occluder opacity.
- `LOccluder:getOpacity`: Returns this occluder opacity.
- `LOccluder:setLightMask`: Sets this occluder's light mask.
- `LOccluder:getLightMask`: Returns this occluder's light mask.
- `LOccluder:setEnabled`: Enables or disables this occluder.
- `LOccluder:isEnabled`: Returns whether this occluder is enabled.
- `LOccluder:remove`: Removes this occluder from the shared light world.
- `LOccluder:isValid`: Returns whether this occluder handle still points to a live occluder.
- `LOccluder:type`: Returns the Lua-visible type name for this occluder handle.
- `LOccluder:typeOf`: Returns whether this occluder handle matches a supported type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- 2026-05-07 enhancements shipped in source:
	- Soft-shadow penumbra controls: `LLight:setShadowSoftness` / `LLight:getShadowSoftness` are now part of the Lua surface and are consumed by renderer shadow sampling.
	- Normal-map plugin hints: `LLight:setNormalMap`, `LLight:getNormalMap`, `LLight:clearNormalMap`, `LLight:setNormalStrength`, `LLight:getNormalStrength`, and module function `lurek.light.getNormalMapHints` expose data-only inputs for optional plugin passes.
	- Ambient bridge parity with `effect` overlay: `LOverlay:pullAmbientFromLight`, `LOverlay:pushAmbientToLight`, `LOverlay:syncAmbientWithLight(mode)` now resolve duplication between `LightWorld.ambient` and `Overlay.ambient.color` with explicit priority modes.
	- Flicker stepping now uses a secondary index of flicker-enabled lights (`LightWorld::reindex_flickers` + indexed `advance_flickers`) to reduce per-frame overhead in scenes with many static lights.
- Keep this module reference synchronized with `src/light/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
