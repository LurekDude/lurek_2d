//! RGBA color value type for the Lurek2D math layer.
//!
//! This module is part of Lurek2D's `math` subsystem (Baseline layer).
//! `Color` is a pure value type with no engine dependencies.
//! Key types exported from this module: `Color`.
//! Primary functions: `from_u8()`, `to_u8()`, `to_rgb_u32()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// RGBA color stored as `f32` components in the range `[0.0, 1.0]`.
///
/// Used everywhere the API accepts a color: `lurek.gfx.setColor`, sprite tints,
/// background color, etc.
///
/// # Fields
/// - `r` — Red channel, `[0.0, 1.0]`.
/// - `g` — Green channel, `[0.0, 1.0]`.
/// - `b` — Blue channel, `[0.0, 1.0]`.
/// - `a` — Alpha channel, `[0.0, 1.0]`; `1.0` = fully opaque.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Color {
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
}

impl Color {
    /// Fully opaque white `(1.0, 1.0, 1.0, 1.0)`.
    pub const WHITE: Color = Color {
        r: 1.0,
        g: 1.0,
        b: 1.0,
        a: 1.0,
    };
    /// Fully opaque black `(0.0, 0.0, 0.0, 1.0)`.
    pub const BLACK: Color = Color {
        r: 0.0,
        g: 0.0,
        b: 0.0,
        a: 1.0,
    };
    /// Fully opaque red `(1.0, 0.0, 0.0, 1.0)`.
    pub const RED: Color = Color {
        r: 1.0,
        g: 0.0,
        b: 0.0,
        a: 1.0,
    };
    /// Fully opaque green `(0.0, 1.0, 0.0, 1.0)`.
    pub const GREEN: Color = Color {
        r: 0.0,
        g: 1.0,
        b: 0.0,
        a: 1.0,
    };
    /// Fully opaque blue `(0.0, 0.0, 1.0, 1.0)`.
    pub const BLUE: Color = Color {
        r: 0.0,
        g: 0.0,
        b: 1.0,
        a: 1.0,
    };
    /// Lurek2D default background color — dark purple `(0.15, 0.12, 0.25, 1.0)`.
    pub const LUNA_BG: Color = Color {
        r: 0.15,
        g: 0.12,
        b: 0.25,
        a: 1.0,
    };
    /// Lurek2D accent color — warm gold `(0.85, 0.75, 0.45, 1.0)`.
    pub const LUNA_ACCENT: Color = Color {
        r: 0.85,
        g: 0.75,
        b: 0.45,
        a: 1.0,
    };

    /// Creates a color from `f32` RGBA components in `[0.0, 1.0]`.
    ///
    /// # Parameters
    /// - `r` — Red component.
    /// - `g` — Green component.
    /// - `b` — Blue component.
    /// - `a` — Alpha component.
    ///
    /// # Returns
    /// A new `Color`.
    pub const fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Color { r, g, b, a }
    }

    /// Creates a color from `u8` RGBA components in `[0, 255]`, normalizing to `[0.0, 1.0]`.
    ///
    /// # Parameters
    /// - `r` — Red byte.
    /// - `g` — Green byte.
    /// - `b` — Blue byte.
    /// - `a` — Alpha byte.
    ///
    /// # Returns
    /// A new `Color` with components divided by 255.
    pub fn from_u8(r: u8, g: u8, b: u8, a: u8) -> Self {
        Color {
            r: r as f32 / 255.0,
            g: g as f32 / 255.0,
            b: b as f32 / 255.0,
            a: a as f32 / 255.0,
        }
    }

    /// Converts the color to `u8` RGBA components, each in `[0, 255]`.
    ///
    /// # Returns
    /// `(u8, u8, u8, u8)` — `(red, green, blue, alpha)`.
    pub fn to_u8(&self) -> (u8, u8, u8, u8) {
        (
            (self.r * 255.0) as u8,
            (self.g * 255.0) as u8,
            (self.b * 255.0) as u8,
            (self.a * 255.0) as u8,
        )
    }

    /// Converts the color to a packed `u32` RGB value suitable for packed pixel buffers.
    ///
    /// Alpha is discarded. Bit layout: `0x00RRGGBB`.
    ///
    /// # Returns
    /// `u32` — Packed RGB value.
    pub fn to_rgb_u32(&self) -> u32 {
        let (r, g, b, _) = self.to_u8();
        ((r as u32) << 16) | ((g as u32) << 8) | (b as u32)
    }
}

impl Default for Color {
    fn default() -> Self {
        Color::WHITE
    }
}

/// Convert a single sRGB gamma-space color component to linear space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB transfer function.
///
/// # Parameters
/// - `c` — gamma-encoded sRGB channel value in `[0.0, 1.0]`
///
/// # Returns
/// Linear-light value in `[0.0, 1.0]`.
pub fn gamma_to_linear(c: f32) -> f32 {
    if c <= 0.04045 {
        c / 12.92
    } else {
        ((c + 0.055) / 1.055).powf(2.4)
    }
}

/// Convert a single linear-space color component to sRGB gamma space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB inverse transfer function.
///
/// # Parameters
/// - `c` — linear-light channel value in `[0.0, 1.0]`
///
/// # Returns
/// Gamma-encoded sRGB value in `[0.0, 1.0]`.
pub fn linear_to_gamma(c: f32) -> f32 {
    if c <= 0.0031308 {
        c * 12.92
    } else {
        1.055 * c.powf(1.0 / 2.4) - 0.055
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Constants ─────────────────────────────────────────────────────────────

    #[test]
    fn white_constant_all_channels_one() {
        let c = Color::WHITE;
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.g - 1.0).abs() < 1e-5);
        assert!((c.b - 1.0).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn black_constant_rgb_zero_alpha_one() {
        let c = Color::BLACK;
        assert!((c.r).abs() < 1e-5);
        assert!((c.g).abs() < 1e-5);
        assert!((c.b).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn from_u8_red_correct() {
        let c = Color::from_u8(255, 0, 0, 255);
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.g).abs() < 1e-5);
        assert!((c.b).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn from_u8_zero_gives_transparent_black() {
        let c = Color::from_u8(0, 0, 0, 0);
        assert!((c.r).abs() < 1e-5);
        assert!((c.a).abs() < 1e-5);
    }

    // ── Conversion ────────────────────────────────────────────────────────────

    #[test]
    fn to_u8_white_gives_255() {
        let (r, g, b, a) = Color::WHITE.to_u8();
        assert_eq!(r, 255);
        assert_eq!(g, 255);
        assert_eq!(b, 255);
        assert_eq!(a, 255);
    }

    #[test]
    fn to_rgb_u32_red_expected_value() {
        let v = Color::RED.to_rgb_u32();
        assert_eq!(v, 0x00FF_0000u32);
    }

    #[test]
    fn to_rgb_u32_blue_expected_value() {
        let v = Color::BLUE.to_rgb_u32();
        assert_eq!(v, 0x0000_00FFu32);
    }

    #[test]
    fn default_is_white() {
        let c = Color::default();
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    // ── Gamma / linear ────────────────────────────────────────────────────────

    #[test]
    fn gamma_to_linear_zero_is_zero() {
        assert!((gamma_to_linear(0.0)).abs() < 1e-5);
    }

    #[test]
    fn linear_to_gamma_zero_is_zero() {
        assert!((linear_to_gamma(0.0)).abs() < 1e-5);
    }

    #[test]
    fn gamma_linear_roundtrip() {
        let original = 0.5f32;
        let linear = gamma_to_linear(original);
        let back = linear_to_gamma(linear);
        assert!((back - original).abs() < 1e-4);
    }
}
