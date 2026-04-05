//! `luna.light` Lua API bindings.
//!
//! Auto-generated skeleton from `src/light/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaAttenuation ────────────────────────────────────────────────────────────

pub struct LuaAttenuation(/* TODO: add key + state fields */);


impl LuaAttenuation {
    /// Computes the attenuation factor at a given distance.
    ///
    ///
    /// # Parameters
    /// - `distance` — `number` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param distance : number
    /// @return number
    pub fn factor(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaAttenuation {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("factor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaFlickerConfig ────────────────────────────────────────────────────────────

pub struct LuaFlickerConfig(/* TODO: add key + state fields */);


impl LuaFlickerConfig {
    /// Computes the intensity multiplier for the current phase.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn multiplier(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaFlickerConfig {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("multiplier", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaLight2D ────────────────────────────────────────────────────────────

pub struct LuaLight2D(/* TODO: add key + state fields */);


impl LuaLight2D {
    /// Returns the light's influence radius. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_radius(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the light's tint color. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `Color`.
    ///
    /// @return Color
    pub fn get_color(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the light's brightness multiplier.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_intensity(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the light is active. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the energy scaling factor.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_energy(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the light blend mode.
    ///
    ///
    /// # Returns
    /// `LightBlendMode`.
    ///
    /// @return LightBlendMode
    pub fn get_blend_mode(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the falloff mode.
    ///
    ///
    /// # Returns
    /// `FalloffMode`.
    ///
    /// @return FalloffMode
    pub fn get_falloff(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this light casts shadows.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_shadow_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the shadow region color.
    ///
    ///
    /// # Returns
    /// `Color`.
    ///
    /// @return Color
    pub fn get_shadow_color(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the shadow edge filter quality.
    ///
    ///
    /// # Returns
    /// `ShadowFilter`.
    ///
    /// @return ShadowFilter
    pub fn get_shadow_filter(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the shadow edge smoothing factor.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_shadow_smooth(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the light interaction bitmask.
    ///
    ///
    /// # Returns
    /// `u16`.
    ///
    /// @return u16
    pub fn get_light_mask(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the shadow casting bitmask.
    ///
    ///
    /// # Returns
    /// `u16`.
    ///
    /// @return u16
    pub fn get_shadow_mask(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the geometric light type.
    ///
    ///
    /// # Returns
    /// `LightType`.
    ///
    /// @return LightType
    pub fn get_light_type(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the direction angle in radians.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_direction(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the inner cone angle in radians.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_inner_angle(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the outer cone angle in radians.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_outer_angle(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the custom attenuation coefficients.
    ///
    ///
    /// # Returns
    /// `Attenuation`.
    ///
    /// @return Attenuation
    pub fn get_attenuation(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the group identifier.
    ///
    ///
    /// # Returns
    /// `u16`.
    ///
    /// @return u16
    pub fn get_group_id(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this light hints at volumetric scattering.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_volumetric(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaLight2D {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getRadius", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getIntensity", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEnergy", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBlendMode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFalloff", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isShadowEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getShadowColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getShadowFilter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getShadowSmooth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLightMask", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getShadowMask", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLightType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDirection", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getInnerAngle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOuterAngle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAttenuation", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGroupId", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isVolumetric", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaLightWorld ────────────────────────────────────────────────────────────

pub struct LuaLightWorld(/* TODO: add key + state fields */);


impl LuaLightWorld {
    /// Returns a shared reference to a light by key.
    ///
    ///
    /// # Parameters
    /// - `key` — `LightKey` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param key : LightKey
    /// @return Option<
    pub fn get_light(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns a shared reference to an occluder by key.
    ///
    ///
    /// # Parameters
    /// - `key` — `OccluderKey` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param key : OccluderKey
    /// @return Option<
    pub fn get_occluder(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of lights in the world.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn light_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of occluders in the world.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn occluder_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if any light in the world is enabled.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn has_active_lights(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of lights in the given group.
    ///
    ///
    /// # Parameters
    /// - `group_id` — `u16` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param group_id : u16
    /// @return integer
    pub fn group_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaLightWorld {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getLight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOccluder", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("lightCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("occluderCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasActiveLights", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("groupCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaOccluder ────────────────────────────────────────────────────────────

pub struct LuaOccluder(/* TODO: add key + state fields */);


impl LuaOccluder {
    /// Returns the translation offset.
    ///
    ///
    /// # Returns
    /// `Vec2`.
    ///
    /// @return Vec2
    pub fn get_position(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the shadow opacity.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_opacity(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the light interaction bitmask.
    ///
    ///
    /// # Returns
    /// `u16`.
    ///
    /// @return u16
    pub fn get_light_mask(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this occluder is active.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaOccluder {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getPosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOpacity", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getLightMask", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.light.* functions ──────────────────────────────────────────

/// Advances the phase by `dt` seconds.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// @param dt : number
pub fn advance(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light's world-space position. Replaces the current position value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
///
/// @param x : number
/// @param y : number
pub fn set_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light's influence radius. Replaces the current radius value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `radius` — `number` ...
///
/// @param radius : number
pub fn set_radius(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light's tint color. Replaces the current color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light's brightness multiplier. Replaces the current intensity value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `intensity` — `number` ...
///
/// @param intensity : number
pub fn set_intensity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether the light is active. Replaces the current enabled value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `enabled` — `boolean` ...
///
/// @param enabled : boolean
pub fn set_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the energy scaling factor (scales radius and intensity together).
///
///
/// # Parameters
/// - `energy` — `number` ...
///
/// @param energy : number
pub fn set_energy(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light blend mode.
///
///
/// # Parameters
/// - `mode` — `LightBlendMode` ...
///
/// @param mode : LightBlendMode
pub fn set_blend_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the falloff mode controlling intensity decay.
///
///
/// # Parameters
/// - `mode` — `FalloffMode` ...
///
/// @param mode : FalloffMode
pub fn set_falloff(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether this light casts shadows.
///
///
/// # Parameters
/// - `enabled` — `boolean` ...
///
/// @param enabled : boolean
pub fn set_shadow_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the shadow region color.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_shadow_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the shadow edge filter quality.
///
///
/// # Parameters
/// - `filter` — `ShadowFilter` ...
///
/// @param filter : ShadowFilter
pub fn set_shadow_filter(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the shadow edge smoothing factor.
///
///
/// # Parameters
/// - `smooth` — `number` ...
///
/// @param smooth : number
pub fn set_shadow_smooth(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light interaction bitmask.
///
///
/// # Parameters
/// - `mask` — `u16` ...
///
/// @param mask : u16
pub fn set_light_mask(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the shadow casting bitmask.
///
///
/// # Parameters
/// - `mask` — `u16` ...
///
/// @param mask : u16
pub fn set_shadow_mask(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the geometric light type.
///
///
/// # Parameters
/// - `light_type` — `LightType` ...
///
/// @param light_type : LightType
pub fn set_light_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the direction angle in radians (for Directional and Spot lights).
///
///
/// # Parameters
/// - `direction` — `number` ...
///
/// @param direction : number
pub fn set_direction(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the inner cone angle in radians for Spot lights.
///
///
/// # Parameters
/// - `angle` — `number` ...
///
/// @param angle : number
pub fn set_inner_angle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the outer cone angle in radians for Spot lights.
///
///
/// # Parameters
/// - `angle` — `number` ...
///
/// @param angle : number
pub fn set_outer_angle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the custom attenuation coefficients.
///
///
/// # Parameters
/// - `attenuation` — `Attenuation` ...
///
/// @param attenuation : Attenuation
pub fn set_attenuation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the group identifier for batch operations.
///
///
/// # Parameters
/// - `group_id` — `u16` ...
///
/// @param group_id : u16
pub fn set_group_id(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether this light hints at volumetric scattering.
///
///
/// # Parameters
/// - `volumetric` — `boolean` ...
///
/// @param volumetric : boolean
pub fn set_volumetric(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Inserts a light and returns its key. Auto-enables the system on first light.
///
///
/// # Parameters
/// - `light` — `Light2D` ...
///
/// # Returns
/// `LightKey`.
///
/// @param light : Light2D
/// @return LightKey
pub fn add_light(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Inserts an occluder and returns its key.
///
///
/// # Parameters
/// - `occluder` — `Occluder` ...
///
/// # Returns
/// `OccluderKey`.
///
/// @param occluder : Occluder
/// @return OccluderKey
pub fn add_occluder(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a light by key, returning it if found.
///
///
/// # Parameters
/// - `key` — `LightKey` ...
///
/// # Returns
/// `Light2D?`.
///
/// @param key : LightKey
/// @return Light2D?
pub fn remove_light(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes an occluder by key, returning it if found.
///
///
/// # Parameters
/// - `key` — `OccluderKey` ...
///
/// # Returns
/// `Occluder?`.
///
/// @param key : OccluderKey
/// @return Occluder?
pub fn remove_occluder(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a mutable reference to a light by key.
///
///
/// # Parameters
/// - `key` — `LightKey` ...
///
/// # Returns
/// `Option<`.
///
/// @param key : LightKey
/// @return Option<
pub fn get_light_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns a mutable reference to an occluder by key.
///
///
/// # Parameters
/// - `key` — `OccluderKey` ...
///
/// # Returns
/// `Option<`.
///
/// @param key : OccluderKey
/// @return Option<
pub fn get_occluder_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the enabled state for all lights in the given group.
///
///
/// # Parameters
/// - `group_id` — `u16` ...
/// - `enabled` — `boolean` ...
///
/// @param group_id : u16
/// @param enabled : boolean
pub fn set_group_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the intensity for all lights in the given group.
///
///
/// # Parameters
/// - `group_id` — `u16` ...
/// - `intensity` — `number` ...
///
/// @param group_id : u16
/// @param intensity : number
pub fn set_group_intensity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the color for all lights in the given group.
///
///
/// # Parameters
/// - `group_id` — `u16` ...
/// - `color` — `Color` ...
///
/// @param group_id : u16
/// @param color : Color
pub fn set_group_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advances flicker phase for all lights with flicker enabled.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// @param dt : number
pub fn advance_flickers(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the polygon vertices.
///
///
/// # Parameters
/// - `vertices` — `table` ...
///
/// @param vertices : table
pub fn set_vertices(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the translation offset.
///
///
/// # Parameters
/// - `position` — `Vec2` ...
///
/// @param position : Vec2
/// Sets the shadow opacity (0.0–1.0).
///
///
/// # Parameters
/// - `opacity` — `number` ...
///
/// @param opacity : number
pub fn set_opacity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the light interaction bitmask.
///
///
/// # Parameters
/// - `mask` — `u16` ...
///
/// @param mask : u16
/// Sets whether this occluder is active.
///
///
/// # Parameters
/// - `enabled` — `boolean` ...
///
/// @param enabled : boolean
/// Registers the `luna.light` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("advance", lua.create_function(advance)?)?;
    tbl.set("setPosition", lua.create_function(set_position)?)?;
    tbl.set("setRadius", lua.create_function(set_radius)?)?;
    tbl.set("setColor", lua.create_function(set_color)?)?;
    tbl.set("setIntensity", lua.create_function(set_intensity)?)?;
    tbl.set("setEnabled", lua.create_function(set_enabled)?)?;
    tbl.set("setEnergy", lua.create_function(set_energy)?)?;
    tbl.set("setBlendMode", lua.create_function(set_blend_mode)?)?;
    tbl.set("setFalloff", lua.create_function(set_falloff)?)?;
    tbl.set("setShadowEnabled", lua.create_function(set_shadow_enabled)?)?;
    tbl.set("setShadowColor", lua.create_function(set_shadow_color)?)?;
    tbl.set("setShadowFilter", lua.create_function(set_shadow_filter)?)?;
    tbl.set("setShadowSmooth", lua.create_function(set_shadow_smooth)?)?;
    tbl.set("setLightMask", lua.create_function(set_light_mask)?)?;
    tbl.set("setShadowMask", lua.create_function(set_shadow_mask)?)?;
    tbl.set("setLightType", lua.create_function(set_light_type)?)?;
    tbl.set("setDirection", lua.create_function(set_direction)?)?;
    tbl.set("setInnerAngle", lua.create_function(set_inner_angle)?)?;
    tbl.set("setOuterAngle", lua.create_function(set_outer_angle)?)?;
    tbl.set("setAttenuation", lua.create_function(set_attenuation)?)?;
    tbl.set("setGroupId", lua.create_function(set_group_id)?)?;
    tbl.set("setVolumetric", lua.create_function(set_volumetric)?)?;
    tbl.set("addLight", lua.create_function(add_light)?)?;
    tbl.set("addOccluder", lua.create_function(add_occluder)?)?;
    tbl.set("removeLight", lua.create_function(remove_light)?)?;
    tbl.set("removeOccluder", lua.create_function(remove_occluder)?)?;
    tbl.set("getLightMut", lua.create_function(get_light_mut)?)?;
    tbl.set("getOccluderMut", lua.create_function(get_occluder_mut)?)?;
    tbl.set("setGroupEnabled", lua.create_function(set_group_enabled)?)?;
    tbl.set("setGroupIntensity", lua.create_function(set_group_intensity)?)?;
    tbl.set("setGroupColor", lua.create_function(set_group_color)?)?;
    tbl.set("advanceFlickers", lua.create_function(advance_flickers)?)?;
    tbl.set("setVertices", lua.create_function(set_vertices)?)?;
    tbl.set("setPosition", lua.create_function(set_position)?)?;
    tbl.set("setOpacity", lua.create_function(set_opacity)?)?;
    tbl.set("setLightMask", lua.create_function(set_light_mask)?)?;
    tbl.set("setEnabled", lua.create_function(set_enabled)?)?;
    luna.set("light", tbl)?;
    Ok(())
}
