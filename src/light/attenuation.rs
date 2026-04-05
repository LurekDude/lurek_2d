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
