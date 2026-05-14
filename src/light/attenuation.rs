
/// Quadratic attenuation coefficients for distance-based light intensity falloff.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Attenuation {
    /// Constant term added to the denominator; prevents infinite brightness at zero distance.
    pub constant: f32,
    /// Linear coefficient in the denominator; controls mid-range falloff slope.
    pub linear: f32,
    /// Quadratic coefficient in the denominator; controls rapid long-range decay.
    pub quadratic: f32,
}
impl Attenuation {
    /// Create a new attenuation with explicit constant, linear, and quadratic coefficients.
    pub fn new(constant: f32, linear: f32, quadratic: f32) -> Self {
        Self {
            constant,
            linear,
            quadratic,
        }
    }
    /// Return attenuation factor at `distance`; returns 1.0 when denominator is <= 0.
    pub fn factor(&self, distance: f32) -> f32 {
        let denom = self.constant + self.linear * distance + self.quadratic * distance * distance;
        if denom <= 0.0 {
            1.0
        } else {
            1.0 / denom
        }
    }
    /// Render labeled attenuation curve plots for each config into an `ImageData` for debug output.
    pub fn draw_attenuation_curves_to_image(
        configs: &[(Attenuation, &str)],
        max_distance: f32,
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(15, 15, 20, 255);
        let count = configs.len().max(1);
        let row_height = (height.saturating_sub(20)) / count as u32;
        let plot_w = width.saturating_sub(20);
        let colors: [(u8, u8, u8); 6] = [
            (230, 80, 80),
            (80, 230, 80),
            (80, 80, 230),
            (230, 230, 80),
            (230, 80, 230),
            (80, 230, 230),
        ];
        for (i, (atten, label)) in configs.iter().enumerate() {
            let oy = 10 + i as i32 * row_height as i32;
            let bar_max = (row_height as f32 * 0.8) as i32;
            let (r, g, b) = colors[i % colors.len()];
            for x in 0..plot_w {
                let dist = x as f32 / plot_w as f32 * max_distance;
                let factor = atten.factor(dist);
                let bar_h = (factor * bar_max as f32) as i32;
                if bar_h > 0 {
                    img.draw_line(
                        x as i32 + 10,
                        oy + bar_max,
                        x as i32 + 10,
                        oy + bar_max - bar_h,
                        r,
                        g,
                        b,
                        200,
                    );
                }
            }
            img.draw_label(label, 10, oy, 200, 200, 200);
        }
        img.draw_label(
            "ATTENUATION CURVES",
            (width / 3) as i32,
            (height - 10) as i32,
            100,
            255,
            100,
        );
        img
    }
}

/// Provides no-op attenuation (constant=1, linear=0, quadratic=0) for full-intensity lights.
impl Default for Attenuation {
    fn default() -> Self {
        Self {
            constant: 1.0,
            linear: 0.0,
            quadratic: 0.0,
        }
    }
}
