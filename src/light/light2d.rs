//! Core 2D light definition with all per-light rendering properties.
//! `Light2D` holds position, color, intensity, type, shadow config, masks, flicker, and attenuation.
//! Consumed by `LightWorld` which reads fields directly during accumulation; Lua bindings live in `src/lua_api/`.
//! Does not own rendering — it is a data container only.
//! Key dependencies: all sibling light types, `crate::math::Color`, `crate::runtime::log_messages`.

use crate::light::attenuation::Attenuation;
use crate::light::blend_mode::LightBlendMode;
use crate::light::falloff::FalloffMode;
use crate::light::flicker::FlickerConfig;
use crate::light::light_type::LightType;
use crate::light::shadow::ShadowFilter;
use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{LT01, LT02, LT03};

/// Complete 2D light definition: position, color, radius, type, shadow, masks, flicker, and attenuation.
pub struct Light2D {
    /// World-space X position of the light source.
    pub x: f32,
    /// World-space Y position of the light source.
    pub y: f32,
    /// Effective light radius in world units.
    pub radius: f32,
    /// RGBA tint color applied to the light contribution.
    pub color: Color,
    /// Intensity multiplier applied on top of energy; range [0.0, ∞).
    pub intensity: f32,
    /// Whether the light is active; when false, `LightWorld` skips it entirely.
    pub enabled: bool,
    /// Energy scale; combined with `intensity` to yield final brightness.
    pub energy: f32,
    /// Blend mode for how this light composites into the accumulation buffer.
    pub blend_mode: LightBlendMode,
    /// Radial falloff curve shape beyond the attenuation response.
    pub falloff: FalloffMode,
    /// Whether shadow casting is enabled for this light.
    pub shadow_enabled: bool,
    /// Color used to tint shadowed regions.
    pub shadow_color: Color,
    /// Shadow filter quality preset.
    pub shadow_filter: ShadowFilter,
    /// Smooth factor for shadow edge blending; higher = softer edge.
    pub shadow_smooth: f32,
    /// Overall shadow softness scale applied to the filter kernel.
    pub shadow_softness: f32,
    /// Bitmask selecting which geometry layers this light illuminates.
    pub light_mask: u16,
    /// Bitmask selecting which geometry layers cast shadows for this light.
    pub shadow_mask: u16,
    /// Discriminant between point, spot, and area variants.
    pub light_type: LightType,
    /// Direction angle in radians for spot lights; 0 = right.
    pub direction: f32,
    /// Inner cone half-angle in radians for spot lights; full brightness inside.
    pub inner_angle: f32,
    /// Outer cone half-angle in radians for spot lights; falls to zero at outer edge.
    pub outer_angle: f32,
    /// Quadratic attenuation coefficients controlling distance-based decay.
    pub attenuation: Attenuation,
    /// Sine-wave flicker config for animated intensity variation.
    pub flicker: FlickerConfig,
    /// Optional group id used to batch lights in `LightWorld`.
    pub group_id: u16,
    /// Whether volumetric scattering should be simulated for this light.
    pub volumetric: bool,
    /// Optional path to a normal map texture used for surface-lighting.
    pub normal_map_path: Option<String>,
    /// Scale applied to the normal map contribution; range [0.0, 1.0].
    pub normal_strength: f32,
}
impl Light2D {
    /// Create a point light at `(x, y)` with `radius`; all other fields default.
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
    /// Set world-space position and log at trace level.
    pub fn set_position(&mut self, x: f32, y: f32) {
        log_msg!(trace, LT02, "({}, {})", x, y);
        self.x = x;
        self.y = y;
    }
    /// Return world-space `(x, y)` position.
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }
    /// Set the light radius and log at trace level.
    pub fn set_radius(&mut self, radius: f32) {
        log_msg!(trace, LT03, "{}", radius);
        self.radius = radius;
    }
    /// Return the current light radius.
    pub fn get_radius(&self) -> f32 {
        self.radius
    }
    /// Set the RGBA tint color.
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }
    /// Return the RGBA tint color.
    pub fn get_color(&self) -> Color {
        self.color
    }
    /// Set the intensity multiplier.
    pub fn set_intensity(&mut self, intensity: f32) {
        self.intensity = intensity;
    }
    /// Return the intensity multiplier.
    pub fn get_intensity(&self) -> f32 {
        self.intensity
    }
    /// Enable or disable this light.
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }
    /// Return whether the light is enabled.
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
    /// Set the energy scale.
    pub fn set_energy(&mut self, energy: f32) {
        self.energy = energy;
    }
    /// Return the energy scale.
    pub fn get_energy(&self) -> f32 {
        self.energy
    }
    /// Set the accumulation blend mode.
    pub fn set_blend_mode(&mut self, mode: LightBlendMode) {
        self.blend_mode = mode;
    }
    /// Return the accumulation blend mode.
    pub fn get_blend_mode(&self) -> LightBlendMode {
        self.blend_mode
    }
    /// Set the radial falloff curve.
    pub fn set_falloff(&mut self, mode: FalloffMode) {
        self.falloff = mode;
    }
    /// Return the radial falloff curve.
    pub fn get_falloff(&self) -> FalloffMode {
        self.falloff
    }
    /// Enable or disable shadow casting.
    pub fn set_shadow_enabled(&mut self, enabled: bool) {
        self.shadow_enabled = enabled;
    }
    /// Return whether shadow casting is enabled.
    pub fn is_shadow_enabled(&self) -> bool {
        self.shadow_enabled
    }
    /// Set the shadow tint color.
    pub fn set_shadow_color(&mut self, color: Color) {
        self.shadow_color = color;
    }
    /// Return the shadow tint color.
    pub fn get_shadow_color(&self) -> Color {
        self.shadow_color
    }
    /// Set the shadow filter quality preset.
    pub fn set_shadow_filter(&mut self, filter: ShadowFilter) {
        self.shadow_filter = filter;
    }
    /// Return the shadow filter quality preset.
    pub fn get_shadow_filter(&self) -> ShadowFilter {
        self.shadow_filter
    }
    /// Set the shadow edge smooth factor.
    pub fn set_shadow_smooth(&mut self, smooth: f32) {
        self.shadow_smooth = smooth;
    }
    /// Return the shadow edge smooth factor.
    pub fn get_shadow_smooth(&self) -> f32 {
        self.shadow_smooth
    }
    /// Set the overall shadow softness scale.
    pub fn set_shadow_softness(&mut self, softness: f32) {
        self.shadow_softness = softness;
    }
    /// Return the overall shadow softness scale.
    pub fn get_shadow_softness(&self) -> f32 {
        self.shadow_softness
    }
    /// Set the layer bitmask for which geometry this light illuminates.
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }
    /// Return the illumination layer bitmask.
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }
    /// Set the layer bitmask for which geometry casts shadows.
    pub fn set_shadow_mask(&mut self, mask: u16) {
        self.shadow_mask = mask;
    }
    /// Return the shadow caster layer bitmask.
    pub fn get_shadow_mask(&self) -> u16 {
        self.shadow_mask
    }
    /// Set the light type discriminant.
    pub fn set_light_type(&mut self, light_type: LightType) {
        self.light_type = light_type;
    }
    /// Return the light type discriminant.
    pub fn get_light_type(&self) -> LightType {
        self.light_type
    }
    /// Set the spot-light direction angle in radians.
    pub fn set_direction(&mut self, direction: f32) {
        self.direction = direction;
    }
    /// Return the spot-light direction angle in radians.
    pub fn get_direction(&self) -> f32 {
        self.direction
    }
    /// Set the inner cone half-angle in radians for spot lights.
    pub fn set_inner_angle(&mut self, angle: f32) {
        self.inner_angle = angle;
    }
    /// Return the inner cone half-angle in radians.
    pub fn get_inner_angle(&self) -> f32 {
        self.inner_angle
    }
    /// Set the outer cone half-angle in radians for spot lights.
    pub fn set_outer_angle(&mut self, angle: f32) {
        self.outer_angle = angle;
    }
    /// Return the outer cone half-angle in radians.
    pub fn get_outer_angle(&self) -> f32 {
        self.outer_angle
    }
    /// Set the quadratic attenuation coefficients.
    pub fn set_attenuation(&mut self, attenuation: Attenuation) {
        self.attenuation = attenuation;
    }
    /// Return the quadratic attenuation coefficients.
    pub fn get_attenuation(&self) -> Attenuation {
        self.attenuation
    }
    /// Return a mutable reference to the flicker config.
    pub fn flicker_mut(&mut self) -> &mut FlickerConfig {
        &mut self.flicker
    }
    /// Return a shared reference to the flicker config.
    pub fn flicker(&self) -> &FlickerConfig {
        &self.flicker
    }
    /// Set the group id for light batching.
    pub fn set_group_id(&mut self, group_id: u16) {
        self.group_id = group_id;
    }
    /// Return the group id.
    pub fn get_group_id(&self) -> u16 {
        self.group_id
    }
    /// Enable or disable volumetric scattering.
    pub fn set_volumetric(&mut self, volumetric: bool) {
        self.volumetric = volumetric;
    }
    /// Return whether volumetric scattering is enabled.
    pub fn is_volumetric(&self) -> bool {
        self.volumetric
    }
    /// Set the normal map texture path, replacing any previous value.
    pub fn set_normal_map_path(&mut self, path: String) {
        self.normal_map_path = Some(path);
    }
    /// Clear the normal map texture path.
    pub fn clear_normal_map_path(&mut self) {
        self.normal_map_path = None;
    }
    /// Return the normal map texture path if set.
    pub fn get_normal_map_path(&self) -> Option<&str> {
        self.normal_map_path.as_deref()
    }
    /// Set the normal map contribution strength; range [0.0, 1.0].
    pub fn set_normal_strength(&mut self, strength: f32) {
        self.normal_strength = strength;
    }
    /// Return the normal map contribution strength.
    pub fn get_normal_strength(&self) -> f32 {
        self.normal_strength
    }
}
impl Light2D {
    /// Render falloff comparison panels for each mode into an `ImageData` debug image.
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
