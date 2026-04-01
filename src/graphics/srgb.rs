/// RGBA color stored as `f32` components in the range `[0.0, 1.0]`.
///
/// Used everywhere the API accepts a color: `luna.graphics.setColor`, sprite tints,
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
    /// Luna2D default background color — dark purple `(0.15, 0.12, 0.25, 1.0)`.
    pub const LUNA_BG: Color = Color {
        r: 0.15,
        g: 0.12,
        b: 0.25,
        a: 1.0,
    };
    /// Luna2D accent color — warm gold `(0.85, 0.75, 0.45, 1.0)`.
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
