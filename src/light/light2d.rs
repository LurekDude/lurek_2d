//! 2D point light data container for lighting systems.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for light2d-related operations and data management.
//! Key types exported from this module: `Light2D`.
//! Primary functions: `new()`, `set_position()`, `get_position()`, `set_radius()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::light::attenuation::Attenuation;
use crate::light::blend_mode::LightBlendMode;
use crate::light::falloff::FalloffMode;
use crate::light::flicker::FlickerConfig;
use crate::light::light_type::LightType;
use crate::light::shadow::ShadowFilter;
use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{LT01, LT02, LT03};

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
/// - `shadow_softness` — `f32`.
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
/// - `normal_map_path` — `Option<String>`.
/// - `normal_strength` — `f32`.
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
    /// Penumbra softness multiplier for shadow edges (default 1.0).
    pub shadow_softness: f32,
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
    /// Optional normal-map texture path hint for plugin renderers.
    pub normal_map_path: Option<String>,
    /// Strength multiplier used when applying normal-map response.
    pub normal_strength: f32,
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
            shadow_softness: 1.0,
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
            normal_map_path: None,
            normal_strength: 1.0,
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

    /// Sets the penumbra softness multiplier for shadow edges.
    ///
    /// # Parameters
    /// - `softness` — `f32`.
    pub fn set_shadow_softness(&mut self, softness: f32) {
        self.shadow_softness = softness;
    }

    /// Returns the penumbra softness multiplier for shadow edges.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_shadow_softness(&self) -> f32 {
        self.shadow_softness
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

    /// Sets or replaces the optional normal-map texture path hint.
    ///
    /// # Parameters
    /// - `path` — `String`.
    pub fn set_normal_map_path(&mut self, path: String) {
        self.normal_map_path = Some(path);
    }

    /// Clears the optional normal-map texture path hint.
    pub fn clear_normal_map_path(&mut self) {
        self.normal_map_path = None;
    }

    /// Returns the optional normal-map texture path hint.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_normal_map_path(&self) -> Option<&str> {
        self.normal_map_path.as_deref()
    }

    /// Sets the normal-map response strength multiplier.
    ///
    /// # Parameters
    /// - `strength` — `f32`.
    pub fn set_normal_strength(&mut self, strength: f32) {
        self.normal_strength = strength;
    }

    /// Returns the normal-map response strength multiplier.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_normal_strength(&self) -> f32 {
        self.normal_strength
    }
}
impl Light2D {
    /// Draw a side-by-side comparison of falloff modes as radial gradients.
    ///
    /// # Parameters
    /// - `modes` — `&[(FalloffMode, &str)]`. Mode and label pairs.
    /// - `radius` — `f32`. Light radius for each sample.
    /// - `width` — `u32`. Image width.
    /// - `height` — `u32`. Image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_falloff_comparison_to_image(
        modes: &[(FalloffMode, &str)],
        radius: f32,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(10, 10, 15, 255);

        let count = modes.len().max(1);
        let cell_w = width / count as u32;

        for (i, &(mode, name)) in modes.iter().enumerate() {
            let ox = i as i32 * cell_w as i32;
            let cx = ox + cell_w as i32 / 2;
            let cy = height as i32 / 2;
            let ri = radius as i32;

            for dy in -ri..=ri {
                for dx in -ri..=ri {
                    let dist = ((dx * dx + dy * dy) as f32).sqrt();
                    if dist > radius {
                        continue;
                    }
                    let t = dist / radius;
                    let intensity = match mode {
                        FalloffMode::Linear => 1.0 - t,
                        FalloffMode::Smooth => 1.0 - t * t,
                        FalloffMode::Constant => 1.0,
                    };
                    let px = (cx + dx) as u32;
                    let py = (cy + dy) as u32;
                    if px < width && py < height {
                        let r = (255.0 * intensity) as u8;
                        let g = (200.0 * intensity * 0.8) as u8;
                        let b = (100.0 * intensity * 0.4) as u8;
                        let existing = img.get_pixel(px, py).unwrap_or((0, 0, 0, 0));
                        let nr = r.max(existing.0);
                        let ng = g.max(existing.1);
                        let nb = b.max(existing.2);
                        img.set_pixel(px, py, nr, ng, nb, 255);
                    }
                }
            }
            img.draw_label(name, ox + 30, (height - 15) as i32, 200, 200, 200);
        }

        img.draw_label("LIGHT FALLOFF MODES", (width / 3) as i32, 3, 100, 255, 100);
        img
    }
}
