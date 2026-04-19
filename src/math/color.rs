//! RGBA color value type for the Lurek2D math layer.
//!
//! [`Color`] is a pure value type with no engine dependencies, stored as four
//! `f32` components in `[0.0, 1.0]`. Conversion to/from `u8` and packed `u32`
//! formats is provided for wgpu vertex colours and Lua interop.
//!
//! Named constructors for common colours: `WHITE`, `BLACK`, `RED`, `GREEN`,
//! `BLUE`, `TRANSPARENT`.

/// RGBA color stored as `f32` components in the range `[0.0, 1.0]`.
///
/// Used everywhere the API accepts a color: `lurek.graphic.setColor`, sprite tints,
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

    /// Creates a color from a hex string such as `"#FF8000"`, `"#FF8000FF"`, or `"FF8000"`.
    ///
    /// Supports 6-char (RGB, alpha defaults to 1.0) and 8-char (RGBA) hex strings.
    /// The leading `#` is optional.
    ///
    /// # Parameters
    /// - `hex` — Hex color string.
    ///
    /// # Returns
    /// `Option<Color>` — `None` if the string is malformed.
    pub fn from_hex(hex: &str) -> Option<Color> {
        let hex = hex.strip_prefix('#').unwrap_or(hex);
        match hex.len() {
            6 => {
                let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
                let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
                let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
                Some(Color::from_u8(r, g, b, 255))
            }
            8 => {
                let r = u8::from_str_radix(&hex[0..2], 16).ok()?;
                let g = u8::from_str_radix(&hex[2..4], 16).ok()?;
                let b = u8::from_str_radix(&hex[4..6], 16).ok()?;
                let a = u8::from_str_radix(&hex[6..8], 16).ok()?;
                Some(Color::from_u8(r, g, b, a))
            }
            _ => None,
        }
    }

    /// Converts the color to HSL (hue, saturation, lightness).
    ///
    /// # Returns
    /// `(f32, f32, f32)` — `(h, s, l)` where h is in degrees `[0, 360)`, s and l in `[0, 1]`.
    pub fn to_hsl(&self) -> (f32, f32, f32) {
        let max = self.r.max(self.g).max(self.b);
        let min = self.r.min(self.g).min(self.b);
        let l = (max + min) / 2.0;

        if (max - min).abs() < 1e-7 {
            return (0.0, 0.0, l);
        }

        let d = max - min;
        let s = if l > 0.5 {
            d / (2.0 - max - min)
        } else {
            d / (max + min)
        };

        let h = if (max - self.r).abs() < 1e-7 {
            let mut h = (self.g - self.b) / d;
            if self.g < self.b {
                h += 6.0;
            }
            h
        } else if (max - self.g).abs() < 1e-7 {
            (self.b - self.r) / d + 2.0
        } else {
            (self.r - self.g) / d + 4.0
        };

        (h * 60.0, s, l)
    }
}

impl Default for Color {
    fn default() -> Self {
        Color::WHITE
    }
}

/// Convert an HSV color to RGB byte components.
///
/// # Parameters
/// - `h` — Hue in degrees `[0, 360)`. Values outside this range are wrapped via modulo.
/// - `s` — Saturation in `[0.0, 1.0]`.
/// - `v` — Value (brightness) in `[0.0, 1.0]`.
///
/// # Returns
/// `(u8, u8, u8)` — red, green, blue components in `[0, 255]`.
pub fn hsv_to_rgb(h: u16, s: f32, v: f32) -> (u8, u8, u8) {
    let h = (h % 360) as f32;
    let c = v * s;
    let x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
    let m = v - c;
    let (r, g, b) = match (h / 60.0) as u8 {
        0 => (c, x, 0.0),
        1 => (x, c, 0.0),
        2 => (0.0, c, x),
        3 => (0.0, x, c),
        4 => (x, 0.0, c),
        _ => (c, 0.0, x),
    };
    (
        ((r + m) * 255.0) as u8,
        ((g + m) * 255.0) as u8,
        ((b + m) * 255.0) as u8,
    )
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

/// Convert an HSL color to a `Color` (alpha defaults to 1.0).
///
/// # Parameters
/// - `h` — Hue in degrees `[0, 360)`.
/// - `s` — Saturation in `[0.0, 1.0]`.
/// - `l` — Lightness in `[0.0, 1.0]`.
///
/// # Returns
/// `Color` — Fully opaque color.
pub fn hsl_to_rgb(h: f32, s: f32, l: f32) -> Color {
    if s.abs() < 1e-7 {
        return Color::new(l, l, l, 1.0);
    }

    let q = if l < 0.5 {
        l * (1.0 + s)
    } else {
        l + s - l * s
    };
    let p = 2.0 * l - q;
    let h = h / 360.0;

    let hue_to_rgb = |p: f32, q: f32, mut t: f32| -> f32 {
        if t < 0.0 { t += 1.0; }
        if t > 1.0 { t -= 1.0; }
        if t < 1.0 / 6.0 {
            return p + (q - p) * 6.0 * t;
        }
        if t < 1.0 / 2.0 {
            return q;
        }
        if t < 2.0 / 3.0 {
            return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
        }
        p
    };

    Color::new(
        hue_to_rgb(p, q, h + 1.0 / 3.0),
        hue_to_rgb(p, q, h),
        hue_to_rgb(p, q, h - 1.0 / 3.0),
        1.0,
    )
}
