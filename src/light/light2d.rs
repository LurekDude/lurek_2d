use crate::light::attenuation::Attenuation;
use crate::light::blend_mode::LightBlendMode;
use crate::light::falloff::FalloffMode;
use crate::light::flicker::FlickerConfig;
use crate::light::light_type::LightType;
use crate::light::shadow::ShadowFilter;
use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{LT01, LT02, LT03};
pub struct Light2D {
    pub x: f32,
    pub y: f32,
    pub radius: f32,
    pub color: Color,
    pub intensity: f32,
    pub enabled: bool,
    pub energy: f32,
    pub blend_mode: LightBlendMode,
    pub falloff: FalloffMode,
    pub shadow_enabled: bool,
    pub shadow_color: Color,
    pub shadow_filter: ShadowFilter,
    pub shadow_smooth: f32,
    pub shadow_softness: f32,
    pub light_mask: u16,
    pub shadow_mask: u16,
    pub light_type: LightType,
    pub direction: f32,
    pub inner_angle: f32,
    pub outer_angle: f32,
    pub attenuation: Attenuation,
    pub flicker: FlickerConfig,
    pub group_id: u16,
    pub volumetric: bool,
    pub normal_map_path: Option<String>,
    pub normal_strength: f32,
}
impl Light2D {
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
    pub fn set_position(&mut self, x: f32, y: f32) {
        log_msg!(trace, LT02, "({}, {})", x, y);
        self.x = x;
        self.y = y;
    }
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }
    pub fn set_radius(&mut self, radius: f32) {
        log_msg!(trace, LT03, "{}", radius);
        self.radius = radius;
    }
    pub fn get_radius(&self) -> f32 {
        self.radius
    }
    pub fn set_color(&mut self, color: Color) {
        self.color = color;
    }
    pub fn get_color(&self) -> Color {
        self.color
    }
    pub fn set_intensity(&mut self, intensity: f32) {
        self.intensity = intensity;
    }
    pub fn get_intensity(&self) -> f32 {
        self.intensity
    }
    pub fn set_enabled(&mut self, enabled: bool) {
        self.enabled = enabled;
    }
    pub fn is_enabled(&self) -> bool {
        self.enabled
    }
    pub fn set_energy(&mut self, energy: f32) {
        self.energy = energy;
    }
    pub fn get_energy(&self) -> f32 {
        self.energy
    }
    pub fn set_blend_mode(&mut self, mode: LightBlendMode) {
        self.blend_mode = mode;
    }
    pub fn get_blend_mode(&self) -> LightBlendMode {
        self.blend_mode
    }
    pub fn set_falloff(&mut self, mode: FalloffMode) {
        self.falloff = mode;
    }
    pub fn get_falloff(&self) -> FalloffMode {
        self.falloff
    }
    pub fn set_shadow_enabled(&mut self, enabled: bool) {
        self.shadow_enabled = enabled;
    }
    pub fn is_shadow_enabled(&self) -> bool {
        self.shadow_enabled
    }
    pub fn set_shadow_color(&mut self, color: Color) {
        self.shadow_color = color;
    }
    pub fn get_shadow_color(&self) -> Color {
        self.shadow_color
    }
    pub fn set_shadow_filter(&mut self, filter: ShadowFilter) {
        self.shadow_filter = filter;
    }
    pub fn get_shadow_filter(&self) -> ShadowFilter {
        self.shadow_filter
    }
    pub fn set_shadow_smooth(&mut self, smooth: f32) {
        self.shadow_smooth = smooth;
    }
    pub fn get_shadow_smooth(&self) -> f32 {
        self.shadow_smooth
    }
    pub fn set_shadow_softness(&mut self, softness: f32) {
        self.shadow_softness = softness;
    }
    pub fn get_shadow_softness(&self) -> f32 {
        self.shadow_softness
    }
    pub fn set_light_mask(&mut self, mask: u16) {
        self.light_mask = mask;
    }
    pub fn get_light_mask(&self) -> u16 {
        self.light_mask
    }
    pub fn set_shadow_mask(&mut self, mask: u16) {
        self.shadow_mask = mask;
    }
    pub fn get_shadow_mask(&self) -> u16 {
        self.shadow_mask
    }
    pub fn set_light_type(&mut self, light_type: LightType) {
        self.light_type = light_type;
    }
    pub fn get_light_type(&self) -> LightType {
        self.light_type
    }
    pub fn set_direction(&mut self, direction: f32) {
        self.direction = direction;
    }
    pub fn get_direction(&self) -> f32 {
        self.direction
    }
    pub fn set_inner_angle(&mut self, angle: f32) {
        self.inner_angle = angle;
    }
    pub fn get_inner_angle(&self) -> f32 {
        self.inner_angle
    }
    pub fn set_outer_angle(&mut self, angle: f32) {
        self.outer_angle = angle;
    }
    pub fn get_outer_angle(&self) -> f32 {
        self.outer_angle
    }
    pub fn set_attenuation(&mut self, attenuation: Attenuation) {
        self.attenuation = attenuation;
    }
    pub fn get_attenuation(&self) -> Attenuation {
        self.attenuation
    }
    pub fn flicker_mut(&mut self) -> &mut FlickerConfig {
        &mut self.flicker
    }
    pub fn flicker(&self) -> &FlickerConfig {
        &self.flicker
    }
    pub fn set_group_id(&mut self, group_id: u16) {
        self.group_id = group_id;
    }
    pub fn get_group_id(&self) -> u16 {
        self.group_id
    }
    pub fn set_volumetric(&mut self, volumetric: bool) {
        self.volumetric = volumetric;
    }
    pub fn is_volumetric(&self) -> bool {
        self.volumetric
    }
    pub fn set_normal_map_path(&mut self, path: String) {
        self.normal_map_path = Some(path);
    }
    pub fn clear_normal_map_path(&mut self) {
        self.normal_map_path = None;
    }
    pub fn get_normal_map_path(&self) -> Option<&str> {
        self.normal_map_path.as_deref()
    }
    pub fn set_normal_strength(&mut self, strength: f32) {
        self.normal_strength = strength;
    }
    pub fn get_normal_strength(&self) -> f32 {
        self.normal_strength
    }
}
impl Light2D {
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
