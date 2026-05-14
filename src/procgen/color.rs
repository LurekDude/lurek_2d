//! Scalar-to-colour helpers for `src/procgen` map visualisation.
//! Owns `scalar_map_to_rgba_bytes` for converting normalised float maps to RGBA buffers.
//! Does not own biome colouring or advanced palette mapping — those live in `biome.rs`.

/// Convert a normalised float slice to a flat grayscale RGBA buffer; clamps each value to 0.0–1.0.
pub fn scalar_map_to_rgba_bytes(values: &[f32]) -> Vec<u8> {
    let mut out = Vec::with_capacity(values.len() * 4);
    for &v in values {
        let g = (v.clamp(0.0, 1.0) * 255.0) as u8;
        out.extend_from_slice(&[g, g, g, 255]);
    }
    out
}
    let mut out = Vec::with_capacity(values.len() * 4);
    for &v in values {
        let g = (v.clamp(0.0, 1.0) * 255.0) as u8;
        out.extend_from_slice(&[g, g, g, 255]);
    }
    out
}
