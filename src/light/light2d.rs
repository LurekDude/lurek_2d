//! 2D point light data container for lighting systems.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for light2d-related operations and data management.
//! Key types exported from this module: `Light2D`.
//! Primary functions: `new()`, `set_position()`, `get_position()`, `set_radius()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::engine::log_messages::{LT01, LT02, LT03};
use crate::light::attenuation::Attenuation;
use crate::light::blend_mode::LightBlendMode;
use crate::light::falloff::FalloffMode;
use crate::light::flicker::FlickerConfig;
use crate::light::light_type::LightType;
use crate::light::shadow::ShadowFilter;
use crate::log_msg;
use crate::math::Color;
use mlua::prelude::{LuaError, LuaResult, LuaTable, LuaValue};


/// 2D point light with position, radius, color, intensity, and shadow settings.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `radius` — `f32`.
/// - `color` — `Color`.
/// - `intensity` — `f32`.
/// - `enabled` — `bool`.
/// - `energy` — `f32`.
/// - `blend_mode` — `LightBlendMode`.
/// - `falloff` — `FalloffMode`.
/// - `shadow_enabled` — `bool`.
/// - `shadow_color` — `Color`.
/// - `shadow_filter` — `ShadowFilter`.
/// - `shadow_smooth` — `f32`.
/// - `light_mask` — `u16`.
/// - `shadow_mask` — `u16`.
/// - `light_type` — `LightType`.
/// - `direction` — `f32`.
/// - `inner_angle` — `f32`.
/// - `outer_angle` — `f32`.
/// - `attenuation` — `Attenuation`.
/// - `flicker` — `FlickerConfig`.
/// - `group_id` — `u16`.
/// - `volumetric` — `bool`.
///
/// Stores all parameters needed to describe a circular light source
/// in 2D space: position, reach, tint, brightness, and on/off state,
/// plus energy scaling, blend mode, falloff curve, shadow settings,
/// light geometry type, custom attenuation, flicker effects, and grouping.
pub struct Light2D {
    /// X position of the light in world space.
    pub x: f32,
    /// Y position of the light in world space.
    pub y: f32,
    /// Radius of the light's influence area.
    pub radius: f32,
    /// Tint color of the light.
    pub color: Color,
    /// Brightness multiplier (0.0 = off, 1.0 = normal).
    pub intensity: f32,
    /// Whether the light is active.
    pub enabled: bool,
    /// Scales radius and intensity together (default 1.0).
    pub energy: f32,
    /// How the light color mixes with the scene.
    pub blend_mode: LightBlendMode,
    /// How intensity decays from center to edge.
    pub falloff: FalloffMode,
    /// Whether this light casts shadows.
    pub shadow_enabled: bool,
    /// Color used for shadow regions.
    pub shadow_color: Color,
    /// Edge quality filter for shadow boundaries.
    pub shadow_filter: ShadowFilter,
    /// Smoothing factor for shadow edges (default 1.0).
    pub shadow_smooth: f32,
    /// Bitmask controlling which occluders this light illuminates.
    pub light_mask: u16,
    /// Bitmask controlling which occluders cast shadows from this light.
    pub shadow_mask: u16,
    /// Geometric type: point, directional, or spot.
    pub light_type: LightType,
    /// Direction angle in radians (used by Directional and Spot types).
    pub direction: f32,
    /// Inner cone angle in radians for Spot lights (full intensity zone).
    pub inner_angle: f32,
    /// Outer cone angle in radians for Spot lights (fade-to-zero zone).
    pub outer_angle: f32,
    /// Custom attenuation coefficients for distance-based intensity decay.
    pub attenuation: Attenuation,
    /// Built-in flicker effect configuration.
    pub flicker: FlickerConfig,
    /// Group identifier for batch operations (default 0).
    pub group_id: u16,
    /// Whether this light hints at volumetric scattering.
    pub volumetric: bool,
}

impl Light2D {
    /// Creates a new white light at `(x, y)` with the given radius.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `radius` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Defaults: color = white, intensity = 1.0, enabled = true.
    pub fn new(x: f32, y: f32, radius: f32) -> Self {
        log_msg!(debug, LT01, "({}, {}) r={}", x, y, radius);
        Self {
            x,
            y,
            radius,
            color: Color::WHITE,
            intensity: 1.0,
            enabled: true,
            energy: 1.0,
            blend_mode: LightBlendMode::default(),
            falloff: FalloffMode::default(),
            shadow_enabled: false,
            shadow_color: Color::BLACK,
            shadow_filter: ShadowFilter::default(),
            shadow_smooth: 1.0,
            light_mask: 0xFFFF,
            shadow_mask: 0xFFFF,
            light_type: LightType::default(),
            direction: 0.0,
            inner_angle: std::f32::consts::FRAC_PI_6,
            outer_angle: std::f32::consts::FRAC_PI_4,
            attenuation: Attenuation::default(),
            flicker: FlickerConfig::default(),
            group_id: 0,
            volumetric: false,
        }
    }

    /// Sets the light's world-space position. Replaces the current position value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_position(&mut self, x: f32, y: f32) {
        log_msg!(trace, LT02, "({}, {})", x, y);
        self.x = x;
        self.y = y;
    }

    /// Returns the light's world-space position as `(x, y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }

    /// Sets the light's influence radius. Replaces the current radius value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `radius` — `f32`.
    pub fn set_radius(&mut self, radius: f32) {
        log_msg!(trace, LT03, "{}", radius);
        self.radius = radius;
    }

    /// Returns the light's influence radius. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_radius(&self) -> f32 {
        self.radius
    }

    /// Sets the light's tint color. Replaces the current color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }

    /// Returns the light's tint color. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Color`.
    pub fn get_color(&self) -> Color {
        self.color
    }

    /// Sets the light's brightness multiplier. Replaces the current intensity value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `intensity` — `f32`.
    pub fn set_intensity(&mut self, intensity: f32) {
        self.intensity = intensity;
    }

    /// Returns the light's brightness multiplier.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_intensity(&self) -> f32 {
        self.intensity
    }

    /// Sets whether the light is active. Replaces the current enabled value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }

    /// Returns whether the light is active. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    /// Sets the energy scaling factor (scales radius and intensity together).
    ///
    /// # Parameters
    /// - `energy` — `f32`.
    pub fn set_energy(&mut self, energy: f32) {
        self.energy = energy;
    }

    /// Returns the energy scaling factor.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_energy(&self) -> f32 {
        self.energy
    }

    /// Sets the light blend mode.
    ///
    /// # Parameters
    /// - `mode` — `LightBlendMode`.
    pub fn set_blend_mode(&mut self, mode: LightBlendMode) {
        self.blend_mode = mode;
    }

    /// Returns the light blend mode.
    ///
    /// # Returns
    /// `LightBlendMode`.
    pub fn get_blend_mode(&self) -> LightBlendMode {
        self.blend_mode
    }

    /// Sets the falloff mode controlling intensity decay.
    ///
    /// # Parameters
    /// - `mode` — `FalloffMode`.
    pub fn set_falloff(&mut self, mode: FalloffMode) {
        self.falloff = mode;
    }

    /// Returns the falloff mode.
    ///
    /// # Returns
    /// `FalloffMode`.
    pub fn get_falloff(&self) -> FalloffMode {
        self.falloff
    }

    /// Sets whether this light casts shadows.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_shadow_enabled(&mut self, enabled: bool) {
        self.shadow_enabled = enabled;
    }

    /// Returns whether this light casts shadows.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_shadow_enabled(&self) -> bool {
        self.shadow_enabled
    }

    /// Sets the shadow region color.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_shadow_color(&mut self, color: Color) {
        self.shadow_color = color;
    }

    /// Returns the shadow region color.
    ///
    /// # Returns
    /// `Color`.
    pub fn get_shadow_color(&self) -> Color {
        self.shadow_color
    }

    /// Sets the shadow edge filter quality.
    ///
    /// # Parameters
    /// - `filter` — `ShadowFilter`.
    pub fn set_shadow_filter(&mut self, filter: ShadowFilter) {
        self.shadow_filter = filter;
    }

    /// Returns the shadow edge filter quality.
    ///
    /// # Returns
    /// `ShadowFilter`.
    pub fn get_shadow_filter(&self) -> ShadowFilter {
        self.shadow_filter
    }

    /// Sets the shadow edge smoothing factor.
    ///
    /// # Parameters
    /// - `smooth` — `f32`.
    pub fn set_shadow_smooth(&mut self, smooth: f32) {
        self.shadow_smooth = smooth;
    }

    /// Returns the shadow edge smoothing factor.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_shadow_smooth(&self) -> f32 {
        self.shadow_smooth
    }

    /// Sets the light interaction bitmask.
    ///
    /// # Parameters
    /// - `mask` — `u16`.
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }

    /// Returns the light interaction bitmask.
    ///
    /// # Returns
    /// `u16`.
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }

    /// Sets the shadow casting bitmask.
    ///
    /// # Parameters
    /// - `mask` — `u16`.
    pub fn set_shadow_mask(&mut self, mask: u16) {
        self.shadow_mask = mask;
    }

    /// Returns the shadow casting bitmask.
    ///
    /// # Returns
    /// `u16`.
    pub fn get_shadow_mask(&self) -> u16 {
        self.shadow_mask
    }

    /// Sets the geometric light type.
    ///
    /// # Parameters
    /// - `light_type` — `LightType`.
    pub fn set_light_type(&mut self, light_type: LightType) {
        self.light_type = light_type;
    }

    /// Returns the geometric light type.
    ///
    /// # Returns
    /// `LightType`.
    pub fn get_light_type(&self) -> LightType {
        self.light_type
    }

    /// Sets the direction angle in radians (for Directional and Spot lights).
    ///
    /// # Parameters
    /// - `direction` — `f32`.
    pub fn set_direction(&mut self, direction: f32) {
        self.direction = direction;
    }

    /// Returns the direction angle in radians.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_direction(&self) -> f32 {
        self.direction
    }

    /// Sets the inner cone angle in radians for Spot lights.
    ///
    /// # Parameters
    /// - `angle` — `f32`.
    pub fn set_inner_angle(&mut self, angle: f32) {
        self.inner_angle = angle;
    }

    /// Returns the inner cone angle in radians.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_inner_angle(&self) -> f32 {
        self.inner_angle
    }

    /// Sets the outer cone angle in radians for Spot lights.
    ///
    /// # Parameters
    /// - `angle` — `f32`.
    pub fn set_outer_angle(&mut self, angle: f32) {
        self.outer_angle = angle;
    }

    /// Returns the outer cone angle in radians.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_outer_angle(&self) -> f32 {
        self.outer_angle
    }

    /// Sets the custom attenuation coefficients.
    ///
    /// # Parameters
    /// - `attenuation` — `Attenuation`.
    pub fn set_attenuation(&mut self, attenuation: Attenuation) {
        self.attenuation = attenuation;
    }

    /// Returns the custom attenuation coefficients.
    ///
    /// # Returns
    /// `Attenuation`.
    pub fn get_attenuation(&self) -> Attenuation {
        self.attenuation
    }

    /// Returns a mutable reference to the flicker configuration.
    ///
    /// # Returns
    /// `&mut FlickerConfig`.
    pub fn flicker_mut(&mut self) -> &mut FlickerConfig {
        &mut self.flicker
    }

    /// Returns a shared reference to the flicker configuration.
    ///
    /// # Returns
    /// `&FlickerConfig`.
    pub fn flicker(&self) -> &FlickerConfig {
        &self.flicker
    }

    /// Sets the group identifier for batch operations.
    ///
    /// # Parameters
    /// - `group_id` — `u16`.
    pub fn set_group_id(&mut self, group_id: u16) {
        self.group_id = group_id;
    }

    /// Returns the group identifier.
    ///
    /// # Returns
    /// `u16`.
    pub fn get_group_id(&self) -> u16 {
        self.group_id
    }

    /// Sets whether this light hints at volumetric scattering.
    ///
    /// # Parameters
    /// - `volumetric` — `bool`.
    pub fn set_volumetric(&mut self, volumetric: bool) {
        self.volumetric = volumetric;
    }

    /// Returns whether this light hints at volumetric scattering.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_volumetric(&self) -> bool {
        self.volumetric
    }
}


/// Parses a blend mode string into `LightBlendMode`.
fn parse_blend_mode(s: &str) -> LuaResult<LightBlendMode> {
    match s {
        "add" => Ok(LightBlendMode::Add),
        "sub" => Ok(LightBlendMode::Sub),
        "mix" => Ok(LightBlendMode::Mix),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid blend mode '{}', expected 'add', 'sub', or 'mix'",
            s
        ))),
    }
}

/// Parses a falloff mode string into `FalloffMode`.
fn parse_falloff(s: &str) -> LuaResult<FalloffMode> {
    match s {
        "linear" => Ok(FalloffMode::Linear),
        "smooth" => Ok(FalloffMode::Smooth),
        "constant" => Ok(FalloffMode::Constant),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid falloff '{}', expected 'linear', 'smooth', or 'constant'",
            s
        ))),
    }
}

/// Parses a shadow filter string into `ShadowFilter`.
fn parse_shadow_filter(s: &str) -> LuaResult<ShadowFilter> {
    match s {
        "none" => Ok(ShadowFilter::None),
        "pcf5" => Ok(ShadowFilter::Pcf5),
        "pcf13" => Ok(ShadowFilter::Pcf13),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid shadow filter '{}', expected 'none', 'pcf5', or 'pcf13'",
            s
        ))),
    }
}

/// Parses a light type string into `LightType`.
fn parse_light_type(s: &str) -> LuaResult<LightType> {
    match s {
        "point" => Ok(LightType::Point),
        "directional" => Ok(LightType::Directional),
        "spot" => Ok(LightType::Spot),
        _ => Err(LuaError::RuntimeError(format!(
            "invalid light type '{}', expected 'point', 'directional', or 'spot'",
            s
        ))),
    }
}

/// Parses an optional color table `{r, g, b [, a]}` from an opts table field.
fn parse_opt_color(opts: &LuaTable, field: &str) -> LuaResult<Option<Color>> {
    let val: LuaValue = opts.get(field)?;
    match val {
        LuaValue::Table(tbl) => {
            let r: f32 = tbl.get(1i32).unwrap_or(1.0);
            let g: f32 = tbl.get(2i32).unwrap_or(1.0);
            let b: f32 = tbl.get(3i32).unwrap_or(1.0);
            let a: f32 = tbl.get(4i32).unwrap_or(1.0);
            Ok(Some(Color::new(r, g, b, a)))
        }
        LuaValue::Nil => Ok(None),
        _ => Err(LuaError::RuntimeError(format!(
            "expected color table for '{}', got {}",
            field,
            val.type_name()
        ))),
    }
}

impl Light2D {

    /// Applies configuration fields from a Lua options table to this `Light2D`.
    ///
    /// # Parameters
    /// - `opts` — `&LuaTable`. The Lua options table.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn apply_lua_opts(&mut self, opts: &LuaTable) -> LuaResult<()> {
    if let Ok(Some(c)) = parse_opt_color(opts, "color") {
        self.set_color(c);
    }
    if let Ok(v) = opts.get::<_, f32>("intensity") {
        self.set_intensity(v);
    }
    if let Ok(v) = opts.get::<_, f32>("energy") {
        self.set_energy(v);
    }
    if let Ok(s) = opts.get::<_, String>("blend") {
        self.set_blend_mode(parse_blend_mode(&s)?);
    }
    if let Ok(s) = opts.get::<_, String>("falloff") {
        self.set_falloff(parse_falloff(&s)?);
    }
    if let Ok(v) = opts.get::<_, bool>("shadowEnabled") {
        self.set_shadow_enabled(v);
    }
    if let Ok(Some(c)) = parse_opt_color(opts, "shadowColor") {
        self.set_shadow_color(c);
    }
    if let Ok(s) = opts.get::<_, String>("shadowFilter") {
        self.set_shadow_filter(parse_shadow_filter(&s)?);
    }
    if let Ok(v) = opts.get::<_, f32>("shadowSmooth") {
        self.set_shadow_smooth(v);
    }
    if let Ok(v) = opts.get::<_, u16>("lightMask") {
        self.set_light_mask(v);
    }
    if let Ok(v) = opts.get::<_, u16>("shadowMask") {
        self.set_shadow_mask(v);
    }
    if let Ok(v) = opts.get::<_, bool>("enabled") {
        self.set_enabled(v);
    }
    if let Ok(s) = opts.get::<_, String>("type") {
        self.set_light_type(parse_light_type(&s)?);
    }
    if let Ok(v) = opts.get::<_, f32>("direction") {
        self.set_direction(v);
    }
    if let Ok(v) = opts.get::<_, f32>("innerAngle") {
        self.set_inner_angle(v);
    }
    if let Ok(v) = opts.get::<_, f32>("outerAngle") {
        self.set_outer_angle(v);
    }
    if let Ok(v) = opts.get::<_, u16>("groupId") {
        self.set_group_id(v);
    }
    if let Ok(v) = opts.get::<_, bool>("volumetric") {
        self.set_volumetric(v);
    }
    if let Ok(v) = opts.get::<_, f32>("flickerSpeed") {
        self.flicker_mut().speed = v;
        self.flicker_mut().enabled = true;
    }
    if let Ok(v) = opts.get::<_, f32>("flickerStrength") {
        self.flicker_mut().strength = v;
        self.flicker_mut().enabled = true;
    }
    if let Ok(v) = opts.get::<_, f32>("attConstant") {
        self.set_attenuation(Attenuation::new(
            v,
            self.get_attenuation().linear,
            self.get_attenuation().quadratic,
        ));
    }
    if let Ok(v) = opts.get::<_, f32>("attLinear") {
        self.set_attenuation(Attenuation::new(
            self.get_attenuation().constant,
            v,
            self.get_attenuation().quadratic,
        ));
    }
    if let Ok(v) = opts.get::<_, f32>("attQuadratic") {
        self.set_attenuation(Attenuation::new(
            self.get_attenuation().constant,
            self.get_attenuation().linear,
            v,
        ));
    }
    Ok(())
}
}

