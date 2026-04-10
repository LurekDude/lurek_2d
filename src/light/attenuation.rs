//! Custom attenuation coefficients for light falloff curves.

/// Custom attenuation coefficients controlling light intensity decay.
///
/// # Fields
/// - `constant` — `f32`.
/// - `linear` — `f32`.
/// - `quadratic` — `f32`.
///
/// The effective intensity at distance `d` is:
/// `intensity / (constant + linear * d + quadratic * d * d)`.
/// Defaults: constant = 1.0, linear = 0.0, quadratic = 0.0 (no custom attenuation).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Attenuation {
    /// Constant term (default 1.0); prevents division by zero.
    pub constant: f32,
    /// Linear decay coefficient (default 0.0).
    pub linear: f32,
    /// Quadratic decay coefficient (default 0.0).
    pub quadratic: f32,
}

impl Attenuation {
    /// Creates a new `Attenuation` with all three coefficients.
    ///
    /// # Parameters
    /// - `constant` — `f32`.
    /// - `linear` — `f32`.
    /// - `quadratic` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(constant: f32, linear: f32, quadratic: f32) -> Self {
        Self {
            constant,
            linear,
            quadratic,
        }
    }

    /// Computes the attenuation factor at a given distance.
    ///
    /// # Parameters
    /// - `distance` — `f32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn factor(&self, distance: f32) -> f32 {
        let denom = self.constant + self.linear * distance + self.quadratic * distance * distance;
        if denom <= 0.0 {
            1.0
        } else {
            1.0 / denom
        }
    }

    /// Draw multiple attenuation curves side-by-side.
    ///
    /// # Parameters
    /// - `configs` — `&[(Attenuation, &str)]`. Attenuation + label pairs.
    /// - `max_distance` — `f32`. X-axis max distance.
    /// - `width` — `u32`. Image width.
    /// - `height` — `u32`. Image height.
    ///
    /// # Returns
    /// `ImageData`.
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
            (230, 80, 80), (80, 230, 80), (80, 80, 230),
            (230, 230, 80), (230, 80, 230), (80, 230, 230),
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
                        x as i32 + 10, oy + bar_max,
                        x as i32 + 10, oy + bar_max - bar_h,
                        r, g, b, 200,
                    );
                }
            }
            img.draw_label(label, 10, oy, 200, 200, 200);
        }

        img.draw_label("ATTENUATION CURVES", (width / 3) as i32, (height - 10) as i32, 100, 255, 100);
        img
    }
}

impl Default for Attenuation {
    fn default() -> Self {
        Self {
            constant: 1.0,
            linear: 0.0,
            quadratic: 0.0,
        }
    }
}
