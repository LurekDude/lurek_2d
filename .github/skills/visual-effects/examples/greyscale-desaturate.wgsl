@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let c = textureSample(tex, smp, uv);
    let grey = dot(c.rgb, vec3<f32>(0.299, 0.587, 0.114));
    let amount = 0.8;  -- 0 = full colour, 1 = full grey
    return vec4<f32>(mix(c.rgb, vec3<f32>(grey), amount), c.a);
}
