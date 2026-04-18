@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let c    = textureSample(tex, smp, uv);
    let line = floor(uv.y * luna_ScreenSize.y) % 2.0;
    let scan = mix(1.0, 0.75, line);   -- darken every other row
    return vec4<f32>(c.rgb * scan, c.a);
}
