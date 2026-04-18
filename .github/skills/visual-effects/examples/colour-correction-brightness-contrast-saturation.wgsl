@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    var c = textureSample(tex, smp, uv);

    // Brightness
    c = vec4<f32>(c.rgb + 0.05, c.a);

    // Contrast
    c = vec4<f32>((c.rgb - 0.5) * 1.2 + 0.5, c.a);

    // Saturation
    let lum = dot(c.rgb, vec3<f32>(0.299, 0.587, 0.114));
    c = vec4<f32>(mix(vec3<f32>(lum), c.rgb, 1.3), c.a);

    return clamp(c, vec4<f32>(0.0), vec4<f32>(1.0));
}
