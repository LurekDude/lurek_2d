pub fn scalar_map_to_rgba_bytes(values: &[f32]) -> Vec<u8> {
    let mut out = Vec::with_capacity(values.len() * 4);
    for &v in values {
        let g = (v.clamp(0.0, 1.0) * 255.0) as u8;
        out.extend_from_slice(&[g, g, g, 255]);
    }
    out
}
