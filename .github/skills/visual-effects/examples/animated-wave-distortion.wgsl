@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let offset = sin(uv.y * 30.0 + luna_Time * 3.0) * 0.005;
    let distorted = vec2<f32>(uv.x + offset, uv.y);
    return textureSample(tex, smp, distorted);
}
