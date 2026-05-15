//! - CSS color string parsing: hex, `rgb()`, `rgba()`, `hsl()`, `hsla()`, and named keywords.
//! - Component extraction for RGB bytes/percent, alpha, hue (deg/turn/rad), and percent values.
//! - HSL-to-RGB conversion with full hue normalization.
//! - Named color lookup covering the CSS basic and extended keyword set.
//! - All outputs normalized to `[f32; 4]` in the 0.0–1.0 range.

use crate::math::Color;
/// Parse a CSS color string and return normalized RGBA components, or `None` when unsupported.
pub fn parse_css_color_rgba(raw: &str) -> Option<[f32; 4]> {
    let value = raw.trim().to_ascii_lowercase();
    if value.is_empty() {
        return None;
    }
    if let Some(color) = Color::from_hex(&value) {
        return Some([color.r, color.g, color.b, color.a]);
    }
    if let Some(inner) = value
        .strip_prefix("rgba(")
        .and_then(|s| s.strip_suffix(')'))
    {
        let parts = split_color_args(inner);
        if parts.len() == 4 {
            let r = parse_rgb_component(parts[0])?;
            let g = parse_rgb_component(parts[1])?;
            let b = parse_rgb_component(parts[2])?;
            let a = parse_alpha_component(parts[3])?;
            return Some([r, g, b, a]);
        }
    }
    if let Some(inner) = value.strip_prefix("rgb(").and_then(|s| s.strip_suffix(')')) {
        let parts = split_color_args(inner);
        if parts.len() == 3 {
            let r = parse_rgb_component(parts[0])?;
            let g = parse_rgb_component(parts[1])?;
            let b = parse_rgb_component(parts[2])?;
            return Some([r, g, b, 1.0]);
        }
    }
    if let Some(inner) = value
        .strip_prefix("hsla(")
        .and_then(|s| s.strip_suffix(')'))
    {
        let parts = split_color_args(inner);
        if parts.len() == 4 {
            let h = parse_hue_component(parts[0])?;
            let s = parse_percent_component(parts[1])?;
            let l = parse_percent_component(parts[2])?;
            let a = parse_alpha_component(parts[3])?;
            let (r, g, b) = hsl_to_rgb(h, s, l);
            return Some([r, g, b, a]);
        }
    }
    if let Some(inner) = value.strip_prefix("hsl(").and_then(|s| s.strip_suffix(')')) {
        let parts = split_color_args(inner);
        if parts.len() == 3 {
            let h = parse_hue_component(parts[0])?;
            let s = parse_percent_component(parts[1])?;
            let l = parse_percent_component(parts[2])?;
            let (r, g, b) = hsl_to_rgb(h, s, l);
            return Some([r, g, b, 1.0]);
        }
    }
    match value.as_str() {
        "transparent" => Some([0.0, 0.0, 0.0, 0.0]),
        "white" => Some([1.0, 1.0, 1.0, 1.0]),
        "black" => Some([0.0, 0.0, 0.0, 1.0]),
        "red" => Some([1.0, 0.0, 0.0, 1.0]),
        "green" => Some([0.0, 0.5, 0.0, 1.0]),
        "lime" => Some([0.0, 1.0, 0.0, 1.0]),
        "blue" => Some([0.0, 0.0, 1.0, 1.0]),
        "yellow" => Some([1.0, 1.0, 0.0, 1.0]),
        "cyan" | "aqua" => Some([0.0, 1.0, 1.0, 1.0]),
        "magenta" | "fuchsia" => Some([1.0, 0.0, 1.0, 1.0]),
        "gray" | "grey" => Some([0.5, 0.5, 0.5, 1.0]),
        "silver" => Some([0.75, 0.75, 0.75, 1.0]),
        "maroon" => Some([0.5, 0.0, 0.0, 1.0]),
        "olive" => Some([0.5, 0.5, 0.0, 1.0]),
        "purple" => Some([0.5, 0.0, 0.5, 1.0]),
        "teal" => Some([0.0, 0.5, 0.5, 1.0]),
        "navy" => Some([0.0, 0.0, 0.5, 1.0]),
        "orange" => Some([1.0, 0.647_058_84, 0.0, 1.0]),
        "brown" => Some([0.647_058_84, 0.164_705_89, 0.164_705_89, 1.0]),
        "gold" => Some([1.0, 0.843_137_26, 0.0, 1.0]),
        "pink" => Some([1.0, 0.752_941_2, 0.796_078_44, 1.0]),
        "violet" => Some([0.933_333_34, 0.509_803_95, 0.933_333_34, 1.0]),
        "indigo" => Some([0.294_117_66, 0.0, 0.509_803_95, 1.0]),
        "beige" => Some([0.960_784_3, 0.960_784_3, 0.862_745_1, 1.0]),
        "coral" => Some([1.0, 0.498_039_22, 0.313_725_5, 1.0]),
        "crimson" => Some([0.862_745_1, 0.078_431_375, 0.235_294_12, 1.0]),
        _ => None,
    }
}
/// Split comma-separated color arguments and trim each segment.
fn split_color_args(inner: &str) -> Vec<&str> {
    inner.split(',').map(str::trim).collect()
}
/// Parse an RGB component from bytes or percent and clamp it to the 0.0-1.0 range.
fn parse_rgb_component(raw: &str) -> Option<f32> {
    if let Some(percent) = raw.strip_suffix('%') {
        let value = percent.trim().parse::<f32>().ok()?;
        return Some((value / 100.0).clamp(0.0, 1.0));
    }
    let value = raw.trim().parse::<f32>().ok()?;
    Some((value / 255.0).clamp(0.0, 1.0))
}
/// Parse an alpha component from bytes or percent and clamp it to the 0.0-1.0 range.
fn parse_alpha_component(raw: &str) -> Option<f32> {
    if let Some(percent) = raw.strip_suffix('%') {
        let value = percent.trim().parse::<f32>().ok()?;
        return Some((value / 100.0).clamp(0.0, 1.0));
    }
    let value = raw.trim().parse::<f32>().ok()?;
    Some(value.clamp(0.0, 1.0))
}
/// Parse a percent component and clamp it to the 0.0-1.0 range.
fn parse_percent_component(raw: &str) -> Option<f32> {
    let value = raw.trim().strip_suffix('%')?.trim().parse::<f32>().ok()?;
    Some((value / 100.0).clamp(0.0, 1.0))
}
/// Parse hue values in degrees, turns, radians, or bare degrees and normalize them.
fn parse_hue_component(raw: &str) -> Option<f32> {
    let input = raw.trim();
    let hue_degrees = if let Some(value) = input.strip_suffix("deg") {
        value.trim().parse::<f32>().ok()?
    } else if let Some(value) = input.strip_suffix("turn") {
        value.trim().parse::<f32>().ok()? * 360.0
    } else if let Some(value) = input.strip_suffix("rad") {
        value.trim().parse::<f32>().ok()? * (180.0 / std::f32::consts::PI)
    } else {
        input.parse::<f32>().ok()?
    };
    let mut normalized = hue_degrees % 360.0;
    if normalized < 0.0 {
        normalized += 360.0;
    }
    Some(normalized)
}
/// Convert HSL color components into normalized RGB values.
fn hsl_to_rgb(h: f32, s: f32, l: f32) -> (f32, f32, f32) {
    if s <= f32::EPSILON {
        return (l, l, l);
    }
    let c = (1.0 - (2.0 * l - 1.0).abs()) * s;
    let h_prime = h / 60.0;
    let x = c * (1.0 - ((h_prime % 2.0) - 1.0).abs());
    let (r1, g1, b1) = if (0.0..1.0).contains(&h_prime) {
        (c, x, 0.0)
    } else if (1.0..2.0).contains(&h_prime) {
        (x, c, 0.0)
    } else if (2.0..3.0).contains(&h_prime) {
        (0.0, c, x)
    } else if (3.0..4.0).contains(&h_prime) {
        (0.0, x, c)
    } else if (4.0..5.0).contains(&h_prime) {
        (x, 0.0, c)
    } else {
        (c, 0.0, x)
    };
    let m = l - c * 0.5;
    (
        (r1 + m).clamp(0.0, 1.0),
        (g1 + m).clamp(0.0, 1.0),
        (b1 + m).clamp(0.0, 1.0),
    )
}
