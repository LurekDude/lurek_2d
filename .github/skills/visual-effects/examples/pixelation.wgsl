@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let pixel_size = vec2<f32>(4.0, 4.0) / luna_ScreenSize;
    let snapped    = floor(uv / pixel_size) * pixel_size;
    return textureSample(tex, smp, snapped);
}
