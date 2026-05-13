pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + t * (b - a)
}
pub fn remap(v: f32, in_min: f32, in_max: f32, out_min: f32, out_max: f32) -> f32 {
    let t = if (in_max - in_min).abs() < 1e-7 {
        0.0
    } else {
        (v - in_min) / (in_max - in_min)
    };
    out_min + t * (out_max - out_min)
}
pub fn clamp(v: f32, min: f32, max: f32) -> f32 {
    if v < min {
        min
    } else if v > max {
        max
    } else {
        v
    }
}
pub fn sign(v: f32) -> f32 {
    if v > 0.0 {
        1.0
    } else if v < 0.0 {
        -1.0
    } else {
        0.0
    }
}
pub fn smoothstep(edge0: f32, edge1: f32, x: f32) -> f32 {
    let t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    t * t * (3.0 - 2.0 * t)
}
pub fn inverse_lerp(a: f32, b: f32, v: f32) -> f32 {
    if (b - a).abs() < 1e-7 {
        0.0
    } else {
        (v - a) / (b - a)
    }
}
