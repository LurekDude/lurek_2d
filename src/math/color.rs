//! RGBA float color type plus gamma/linear conversion and HSL/HSV helpers.
//! Colors are stored as linear f32 in [0, 1] range; sRGB conversion is explicit via
//! `gamma_to_linear` / `linear_to_gamma`. Used by rendering, UI, particles, and tween.
//! Does not own palette management or per-asset color profiles.

/// Linear RGBA float color; all channels are in [0.0, 1.0] unless explicitly noted.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Color {
    /// Red channel, linear [0, 1].
    pub r: f32,
    /// Green channel, linear [0, 1].
    pub g: f32,
    /// Blue channel, linear [0, 1].
    pub b: f32,
    /// Alpha channel, linear [0, 1]; 0 = fully transparent, 1 = fully opaque.
    pub a: f32,
}

impl Color {
    /// Opaque white (1, 1, 1, 1).
    pub const WHITE: Color = Color {
        r: 1.0,
        g: 1.0,
        b: 1.0,
        a: 1.0,
    };
    /// Opaque black (0, 0, 0, 1).
    pub const BLACK: Color = Color {
        r: 0.0,
        g: 0.0,
        b: 0.0,
        a: 1.0,
    };
    /// Opaque red (1, 0, 0, 1).
    pub const RED: Color = Color {
        r: 1.0,
        g: 0.0,
        b: 0.0,
        a: 1.0,
    };
    /// Opaque green (0, 1, 0, 1).
    pub const GREEN: Color = Color {
        r: 0.0,
        g: 1.0,
        b: 0.0,
        a: 1.0,
    };
    /// Opaque blue (0, 0, 1, 1).
    pub const BLUE: Color = Color {
        r: 0.0,
        g: 0.0,
        b: 1.0,
        a: 1.0,
    };
    /// Lurek2D default background color (dark indigo-purple).
    pub const LUREK_BG: Color = Color {
        r: 0.15,
        g: 0.12,
        b: 0.25,
        a: 1.0,
    };
    /// Lurek2D branding accent color (warm gold).
    pub const LUREK_ACCENT: Color = Color {
        r: 0.85,
        g: 0.75,
        b: 0.45,
        a: 1.0,
    };

    /// Construct a Color from four f32 components.
    pub const fn new(r: f32, g: f32, b: f32, a: f32) -> Self {
        Color { r, g, b, a }
    }

    /// Construct a Color from four u8 components, normalising each to [0, 1].
    pub fn from_u8(r: u8, g: u8, b: u8, a: u8) -> Self {
        Color {
            r: r as f32 / 255.0,
            g: g as f32 / 255.0,
            b: b as f32 / 255.0,
            a: a as f32 / 255.0,
        }
    }

    /// Return the four components as clamped u8 values (r, g, b, a).
    pub fn to_u8(&self) -> (u8, u8, u8, u8) {
        (
            (self.r * 255.0) as u8,
            (self.g * 255.0) as u8,
            (self.b * 255.0) as u8,
            (self.a * 255.0) as u8,
        )
    }

    /// Return the color packed as a 24-bit RGB u32 (alpha discarded).
    pub fn to_rgb_u32(&self) -> u32 {
        let (r, g, b, _) = self.to_u8();
        ((r as u32) << 16) | ((g as u32) << 8) | (b as u32)
    }

    /// Parse a hex color string (`#RRGGBB` or `#RRGGBBAA`); returns None on parse failure.
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

    /// Return this color converted to `(hue_degrees, saturation, lightness)` tuple.
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

/// Default color is opaque white.
impl Default for Color {
    fn default() -> Self {
        Color::WHITE
    }
}

/// Convert HSV `(hue 0–359, saturation 0–1, value 0–1)` to an RGB u8 triple.
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

/// Convert a single sRGB gamma-encoded component `c` to a linear value.
pub fn gamma_to_linear(c: f32) -> f32 {
    if c <= 0.04045 {
        c / 12.92
    } else {
        ((c + 0.055) / 1.055).powf(2.4)
    }
}

/// Convert a single linear component `c` back to sRGB gamma-encoded value.
pub fn linear_to_gamma(c: f32) -> f32 {
    if c <= 0.0031308 {
        c * 12.92
    } else {
        1.055 * c.powf(1.0 / 2.4) - 0.055
    }
}

/// Convert HSL `(hue_degrees, saturation 0–1, lightness 0–1)` to an opaque Color.
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
        if t < 0.0 {
            t += 1.0;
        }
        if t > 1.0 {
            t -= 1.0;
        }
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
