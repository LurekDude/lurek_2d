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
- `Occluder` (`struct`, `occluder.rs`): Polygon shadow caster with vertices, transform, opacity, mask, and enabled state.
- `ShadowFilter` (`enum`, `shadow.rs`): Enum selecting the shadow edge filtering quality.
- `LightTransition` (`struct`, `transition.rs`): Linearly interpolates a [`super::Light2D`]'s color, intensity, and radius from their current values to target values over a fixed duration.

## Functions

- `Attenuation::new` (`attenuation.rs`): Creates a new `Attenuation` with all three coefficients.
- `Attenuation::factor` (`attenuation.rs`): Computes the attenuation factor at a given distance.
- `Attenuation::draw_attenuation_curves_to_image` (`attenuation.rs`): Draw multiple attenuation curves side-by-side.
- `FlickerConfig::new` (`flicker.rs`): Creates a new enabled `FlickerConfig` with the given speed and strength.
- `FlickerConfig::multiplier` (`flicker.rs`): Computes the intensity multiplier for the current phase.
- `FlickerConfig::advance` (`flicker.rs`): Advances the phase by `dt` seconds.
- `Light2D::new` (`light2d.rs`): Creates a new white light at `(x, y)` with the given radius.
- `Light2D::set_position` (`light2d.rs`): Sets the light's world-space position.
- `Light2D::get_position` (`light2d.rs`): Returns the light's world-space position as `(x, y)`.
- `Light2D::set_radius` (`light2d.rs`): Sets the light's influence radius.
- `Light2D::get_radius` (`light2d.rs`): Returns the light's influence radius.
- `Light2D::set_color` (`light2d.rs`): Sets the light's tint color.
- `Light2D::get_color` (`light2d.rs`): Returns the light's tint color.
- `Light2D::set_intensity` (`light2d.rs`): Sets the light's brightness multiplier.
- `Light2D::get_intensity` (`light2d.rs`): Returns the light's brightness multiplier.
- `Light2D::set_enabled` (`light2d.rs`): Sets whether the light is active.
- `Light2D::is_enabled` (`light2d.rs`): Returns whether the light is active.
- `Light2D::set_energy` (`light2d.rs`): Sets the energy scaling factor (scales radius and intensity together).
- `Light2D::get_energy` (`light2d.rs`): Returns the energy scaling factor.
- `Light2D::set_blend_mode` (`light2d.rs`): Sets the light blend mode.
- `Light2D::get_blend_mode` (`light2d.rs`): Returns the light blend mode.
- `Light2D::set_falloff` (`light2d.rs`): Sets the falloff mode controlling intensity decay.
- `Light2D::get_falloff` (`light2d.rs`): Returns the falloff mode.
- `Light2D::set_shadow_enabled` (`light2d.rs`): Sets whether this light casts shadows.
- `Light2D::is_shadow_enabled` (`light2d.rs`): Returns whether this light casts shadows.
- `Light2D::set_shadow_color` (`light2d.rs`): Sets the shadow region color.
- `Light2D::get_shadow_color` (`light2d.rs`): Returns the shadow region color.
- `Light2D::set_shadow_filter` (`light2d.rs`): Sets the shadow edge filter quality.
- `Light2D::get_shadow_filter` (`light2d.rs`): Returns the shadow edge filter quality.
- `Light2D::set_shadow_smooth` (`light2d.rs`): Sets the shadow edge smoothing factor.
- `Light2D::get_shadow_smooth` (`light2d.rs`): Returns the shadow edge smoothing factor.
- `Light2D::set_light_mask` (`light2d.rs`): Sets the light interaction bitmask.
- `Light2D::get_light_mask` (`light2d.rs`): Returns the light interaction bitmask.
- `Light2D::set_shadow_mask` (`light2d.rs`): Sets the shadow casting bitmask.
- `Light2D::get_shadow_mask` (`light2d.rs`): Returns the shadow casting bitmask.
- `Light2D::set_light_type` (`light2d.rs`): Sets the geometric light type.
- `Light2D::get_light_type` (`light2d.rs`): Returns the geometric light type.
- `Light2D::set_direction` (`light2d.rs`): Sets the direction angle in radians (for Directional and Spot lights).
- `Light2D::get_direction` (`light2d.rs`): Returns the direction angle in radians.
- `Light2D::set_inner_angle` (`light2d.rs`): Sets the inner cone angle in radians for Spot lights.
- `Light2D::get_inner_angle` (`light2d.rs`): Returns the inner cone angle in radians.
- `Light2D::set_outer_angle` (`light2d.rs`): Sets the outer cone angle in radians for Spot lights.
- `Light2D::get_outer_angle` (`light2d.rs`): Returns the outer cone angle in radians.
- `Light2D::set_attenuation` (`light2d.rs`): Sets the custom attenuation coefficients.
- `Light2D::get_attenuation` (`light2d.rs`): Returns the custom attenuation coefficients.
- `Light2D::flicker_mut` (`light2d.rs`): Returns a mutable reference to the flicker configuration.
- `Light2D::flicker` (`light2d.rs`): Returns a shared reference to the flicker configuration.
- `Light2D::set_group_id` (`light2d.rs`): Sets the group identifier for batch operations.
- `Light2D::get_group_id` (`light2d.rs`): Returns the group identifier.
- `Light2D::set_volumetric` (`light2d.rs`): Sets whether this light hints at volumetric scattering.
- `Light2D::is_volumetric` (`light2d.rs`): Returns whether this light hints at volumetric scattering.
- `Light2D::apply_lua_opts` (`light2d.rs`): Applies configuration fields from a Lua options table to this `Light2D`.
- `Light2D::draw_falloff_comparison_to_image` (`light2d.rs`): Draw a side-by-side comparison of falloff modes as radial gradients.
- `LightWorld::new` (`light_world.rs`): Creates a new empty `LightWorld` with default settings.
- `LightWorld::add_light` (`light_world.rs`): Inserts a light and returns its key.
- `LightWorld::add_occluder` (`light_world.rs`): Inserts an occluder and returns its key.
- `LightWorld::remove_light` (`light_world.rs`): Removes a light by key, returning it if found.
- `LightWorld::remove_occluder` (`light_world.rs`): Removes an occluder by key, returning it if found.
- `LightWorld::get_light` (`light_world.rs`): Returns a shared reference to a light by key.
- `LightWorld::get_light_mut` (`light_world.rs`): Returns a mutable reference to a light by key.
- `LightWorld::get_occluder` (`light_world.rs`): Returns a shared reference to an occluder by key.
- `LightWorld::get_occluder_mut` (`light_world.rs`): Returns a mutable reference to an occluder by key.
- `LightWorld::light_count` (`light_world.rs`): Returns the number of lights in the world.
- `LightWorld::occluder_count` (`light_world.rs`): Returns the number of occluders in the world.
- `LightWorld::clear` (`light_world.rs`): Removes all lights and occluders, resets ambient to default.
- `LightWorld::has_active_lights` (`light_world.rs`): Returns `true` if any light in the world is enabled.
- `LightWorld::set_group_enabled` (`light_world.rs`): Sets the enabled state for all lights in the given group.
- `LightWorld::set_group_intensity` (`light_world.rs`): Sets the intensity for all lights in the given group.
- `LightWorld::set_group_color` (`light_world.rs`): Sets the color for all lights in the given group.
- `LightWorld::group_count` (`light_world.rs`): Returns the number of lights in the given group.
- `LightWorld::advance_flickers` (`light_world.rs`): Advances flicker phase for all lights with flicker enabled.
- `LightWorld::draw_to_image` (`light_world.rs`): Render the accumulated lightmap to an image.
- `LightWorld::ambient_color_hint` (`light_world.rs`): Returns the current ambient colour as an RGBA tuple in `[0.0, 1.0]`.
- `LightWorld::directional_light_hints` (`light_world.rs`): Returns a list of position and direction hints for all enabled directional lights.
- `Occluder::new` (`occluder.rs`): Creates a new occluder from the given polygon vertices.
- `Occluder::set_vertices` (`occluder.rs`): Sets the polygon vertices.
- `Occluder::from_flat_coords` (`occluder.rs`): Creates an `Occluder` from a flat `{x1, y1, x2, y2, ...}` coordinate sequence.
- `Occluder::get_vertices` (`occluder.rs`): Returns a reference to the polygon vertices.
- `Occluder::set_position` (`occluder.rs`): Sets the translation offset.
- `Occluder::get_position` (`occluder.rs`): Returns the translation offset.
- `Occluder::set_opacity` (`occluder.rs`): Sets the shadow opacity (0.0–1.0).
- `Occluder::get_opacity` (`occluder.rs`): Returns the shadow opacity.
- `Occluder::set_light_mask` (`occluder.rs`): Sets the light interaction bitmask.
- `Occluder::get_light_mask` (`occluder.rs`): Returns the light interaction bitmask.
- `Occluder::set_enabled` (`occluder.rs`): Sets whether this occluder is active.
- `Occluder::is_enabled` (`occluder.rs`): Returns whether this occluder is active.
- `LightTransition::new` (`transition.rs`): Creates a new `LightTransition` starting from the given snapshot of the light's current state.
- `LightTransition::update` (`transition.rs`): Advances the transition by `dt` seconds and returns the current `(color, intensity, radius)` snapshot, or `None` when the transition has completed.
- `LightTransition::progress` (`transition.rs`): Returns the fractional progress `[0, 1]` of the transition.

## Lua API Reference

- Binding path(s): `src/lua_api/light_api.rs`
- Namespace: `lurek.light`

### Module Functions
- `lurek.light.newLight`: Creates a new light at (x, y) with the given radius and optional settings.
- `lurek.light.newOccluder`: Creates a new shadow occluder from a vertex table and optional settings.
- `lurek.light.setAmbient`: Sets the global ambient light color.
- `lurek.light.getAmbient`: Returns the global ambient light color as (r, g, b, a).
- `lurek.light.setEnabled`: Sets whether the lighting system is active.
- `lurek.light.isEnabled`: Returns whether the lighting system is active.
- `lurek.light.getLightCount`: Returns the number of lights in the world.
- `lurek.light.getOccluderCount`: Returns the number of occluders in the world.
- `lurek.light.getMaxLights`: Returns the maximum number of lights processed per frame.
- `lurek.light.setMaxLights`: Sets the maximum number of lights processed per frame (clamped 1-256).
- `lurek.light.clear`: Removes all lights and occluders, resets ambient to default.
- `lurek.light.setGroupEnabled`: Sets the enabled state for all lights in the given group.
- `lurek.light.setGroupIntensity`: Sets the intensity for all lights in the given group.
- `lurek.light.setGroupColor`: Sets the color for all lights in the given group.
- `lurek.light.getGroupCount`: Returns the number of lights in the given group.
- `lurek.light.advanceFlickers`: Advances flicker phase for all lights with flicker enabled.
- `lurek.light.syncAmbient`: Returns the current ambient light color snapshot.
- `lurek.light.getGodRayHints`: Returns directional light hints for god-ray rendering.
- `lurek.light.getNormalMapHints`: Returns normal-map lighting hints for plugin renderers.

### `LLight` Methods
- `LLight:setPosition`: Sets the light's world-space position.
- `LLight:getPosition`: Returns the light's world-space position.
- `LLight:setRadius`: Sets the light's influence radius.
- `LLight:getRadius`: Returns the light's influence radius.
- `LLight:setColor`: Sets the light's tint color.
- `LLight:getColor`: Returns the light's tint color as (r, g, b, a).
- `LLight:setIntensity`: Sets the brightness multiplier.
- `LLight:getIntensity`: Returns the brightness multiplier.
- `LLight:setEnergy`: Sets the energy scaling factor.
- `LLight:getEnergy`: Returns the energy scaling factor.
- `LLight:setBlendMode`: Sets the blend mode ('add', 'sub', or 'mix').
- `LLight:getBlendMode`: Returns the blend mode as a string.
- `LLight:setFalloff`: Sets the falloff mode ('linear', 'smooth', or 'constant').
- `LLight:getFalloff`: Returns the falloff mode as a string.
- `LLight:setShadowEnabled`: Sets whether this light casts shadows.
- `LLight:isShadowEnabled`: Returns whether this light casts shadows.
- `LLight:setShadowColor`: Sets the shadow region color.
- `LLight:getShadowColor`: Returns the shadow region color as (r, g, b, a).
- `LLight:setShadowFilter`: Sets the shadow edge filter ('none', 'pcf5', or 'pcf13').
- `LLight:getShadowFilter`: Returns the shadow edge filter as a string.
- `LLight:setShadowSmooth`: Sets the shadow edge smoothing factor.
- `LLight:getShadowSmooth`: Returns the shadow edge smoothing factor.
- `LLight:setShadowSoftness`: Sets the penumbra softness multiplier for shadow edges.
- `LLight:getShadowSoftness`: Returns the penumbra softness multiplier for shadow edges.
- `LLight:setLightMask`: Sets the light interaction bitmask.
- `LLight:getLightMask`: Returns the light interaction bitmask.
- `LLight:setShadowMask`: Sets the shadow casting bitmask.
- `LLight:getShadowMask`: Returns the shadow casting bitmask.
- `LLight:setEnabled`: Sets whether this light is active.
- `LLight:isEnabled`: Returns whether this light is active.
- `LLight:setLightType`: Sets the geometric light type ('point', 'directional', or 'spot').
- `LLight:getLightType`: Returns the geometric light type as a string.
- `LLight:setDirection`: Sets the direction angle in radians.
- `LLight:getDirection`: Returns the direction angle in radians.
- `LLight:setInnerAngle`: Sets the inner cone angle in radians for spot lights.
- `LLight:getInnerAngle`: Returns the inner cone angle in radians.
- `LLight:setOuterAngle`: Sets the outer cone angle in radians for spot lights.
- `LLight:getOuterAngle`: Returns the outer cone angle in radians.
- `LLight:setAttenuation`: Sets the custom attenuation coefficients (constant, linear, quadratic).
- `LLight:getAttenuation`: Returns the custom attenuation coefficients as (constant, linear, quadratic).
- `LLight:setFlicker`: Sets the flicker effect speed and strength (enables flicker).
- `LLight:getFlicker`: Returns the flicker effect speed and strength.
- `LLight:setFlickerEnabled`: Sets whether the flicker effect is active.
- `LLight:isFlickerEnabled`: Returns whether the flicker effect is active.
- `LLight:setGroupId`: Sets the group identifier for batch operations.
- `LLight:getGroupId`: Returns the group identifier.
- `LLight:setVolumetric`: Sets whether this light hints at volumetric scattering.
- `LLight:isVolumetric`: Returns whether this light hints at volumetric scattering.
- `LLight:remove`: Removes this light from the world.
- `LLight:isValid`: Returns whether this light handle is still valid.
- `LLight:addFlicker`: Sets a flicker effect from an intensity range and frequency.
- `LLight:transitionTo`: Starts a smooth transition toward the target light properties.
- `LLight:updateTransition`: Advances the active transition and applies interpolated values.
- `LLight:stopTransition`: Cancels the active light transition.
- `LLight:transitionProgress`: Returns the fractional progress of the active transition.
- `LLight:setCookie`: Sets the texture path used as a light cookie for projection.
- `LLight:getCookie`: Returns the current cookie texture path, or `nil` if unset.
- `LLight:clearCookie`: Removes the cookie texture assignment.
- `LLight:setNormalMap`: Sets the normal-map texture path hint used by plugin renderers.
- `LLight:getNormalMap`: Returns the normal-map texture path hint, or `nil` when unset.
- `LLight:clearNormalMap`: Clears the normal-map texture path hint.
- `LLight:setNormalStrength`: Sets the normal-map response strength multiplier.
- `LLight:getNormalStrength`: Returns the normal-map response strength multiplier.
- `LLight:type`: Returns the type name of this object.
- `LLight:typeOf`: Returns true if this object is of the given type.

### `LOccluder` Methods
- `LOccluder:setVertices`: Replaces the polygon vertices from a flat table {x1,y1,x2,y2,...}.
- `LOccluder:getVertices`: Returns the polygon vertices as a flat table {x1,y1,x2,y2,...}.
- `LOccluder:setPosition`: Sets the translation offset applied to all vertices.
- `LOccluder:getPosition`: Returns the translation offset as (x, y).
- `LOccluder:setOpacity`: Sets the shadow opacity (0.0-1.0).
- `LOccluder:getOpacity`: Returns the shadow opacity.
- `LOccluder:setLightMask`: Sets the light interaction bitmask.
- `LOccluder:getLightMask`: Returns the light interaction bitmask.
- `LOccluder:setEnabled`: Sets whether this occluder is active.
- `LOccluder:isEnabled`: Returns whether this occluder is active.
- `LOccluder:remove`: Removes this occluder from the world.
- `LOccluder:isValid`: Returns whether this occluder handle is still valid.
- `LOccluder:type`: Returns the type name of this object.
- `LOccluder:typeOf`: Returns true if this object is of the given type.

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
