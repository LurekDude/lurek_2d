use std::collections::HashMap;
const POSTFX_VERTEX: &str = r#"
struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0)       uv:       vec2<f32>,
}
@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOutput {
    let u = f32((vi & 1u) << 1u);
    let v = f32(vi & 2u);
    var out: VertexOutput;
    out.clip_pos = vec4<f32>(u * 2.0 - 1.0, 1.0 - v * 2.0, 0.0, 1.0);
    out.uv       = vec2<f32>(u, v);
    return out;
}
"#;
const SHADER_BLOOM: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let base  = textureSample(t_src, s_src, uv);
    let threshold = params.p[0].x;
    let intensity = params.p[0].y;
    let radius    = max(params.p[0].z, 0.001);
    var bloom = vec3<f32>(0.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let step = radius / dim;
    let samples = 9;
    for (var i = -2; i <= 2; i++) {
        for (var j = -2; j <= 2; j++) {
            let s = textureSample(t_src, s_src, uv + vec2<f32>(f32(i), f32(j)) * step).rgb;
            bloom += max(s - vec3<f32>(threshold), vec3<f32>(0.0));
        }
    }
    bloom /= 25.0;
    return vec4<f32>(base.rgb + bloom * intensity, base.a);
}
"#;
const SHADER_BLUR_H: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let radius = max(params.p[0].x, 1.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let step = radius / dim.x;
    var col = vec4<f32>(0.0);
    let w = array<f32, 5>(0.0625, 0.25, 0.375, 0.25, 0.0625);
    for (var i = 0; i < 5; i++) {
        col += textureSample(t_src, s_src, uv + vec2<f32>((f32(i) - 2.0) * step, 0.0)) * w[i];
    }
    return col;
}
"#;
const SHADER_BLUR_V: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let radius = max(params.p[0].x, 1.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let step = radius / dim.y;
    var col = vec4<f32>(0.0);
    let w = array<f32, 5>(0.0625, 0.25, 0.375, 0.25, 0.0625);
    for (var i = 0; i < 5; i++) {
        col += textureSample(t_src, s_src, uv + vec2<f32>(0.0, (f32(i) - 2.0) * step)) * w[i];
    }
    return col;
}
"#;
const SHADER_VIGNETTE: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let center = uv - 0.5;
    let dist = length(center);
    let str = params.p[0].x;
    let sm  = max(params.p[0].y, 0.001);
    let vig = 1.0 - smoothstep(0.4, 0.4 + sm, dist * str * 2.0);
    return vec4<f32>(col.rgb * vig, col.a);
}
"#;
const SHADER_NOISE: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let str = params.p[0].x;
    let t   = params.p[0].y;
    let n = hash(uv * 1000.0 + t) * 2.0 - 1.0;
    return vec4<f32>(col.rgb + vec3<f32>(n * str), col.a);
}
"#;
const SHADER_GRAYSCALE: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let lum = dot(col.rgb, vec3<f32>(0.299, 0.587, 0.114));
    let mix = params.p[0].x;
    return vec4<f32>(mix(col.rgb, vec3<f32>(lum), mix), col.a);
}
"#;
const SHADER_SEPIA: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let r = dot(col.rgb, vec3<f32>(0.393, 0.769, 0.189));
    let g = dot(col.rgb, vec3<f32>(0.349, 0.686, 0.168));
    let b = dot(col.rgb, vec3<f32>(0.272, 0.534, 0.131));
    let str = params.p[0].x;
    return vec4<f32>(mix(col.rgb, vec3<f32>(r, g, b), str), col.a);
}
"#;
const SHADER_INVERT: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    return vec4<f32>(1.0 - col.rgb, col.a);
}
"#;
const SHADER_CRT: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
fn barrel(uv: vec2<f32>, warp: f32) -> vec2<f32> {
    let d = uv - 0.5;
    let r2 = dot(d, d);
    return uv + d * r2 * warp;
}
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let warp = params.p[0].x;
    let rgb = params.p[0].y;
    let uvc = barrel(uv, warp);
    let r = textureSample(t_src, s_src, barrel(uv + vec2<f32>( rgb, 0.0), warp)).r;
    let g = textureSample(t_src, s_src, uvc).g;
    let b = textureSample(t_src, s_src, barrel(uv - vec2<f32>( rgb, 0.0), warp)).b;
    return vec4<f32>(r, g, b, 1.0);
}
"#;
const SHADER_CHROMATIC: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let str = params.p[0].x;
    let dir = normalize(uv - 0.5);
    let r = textureSample(t_src, s_src, uv + dir * str).r;
    let g = textureSample(t_src, s_src, uv).g;
    let b = textureSample(t_src, s_src, uv - dir * str).b;
    return vec4<f32>(r, g, b, 1.0);
}
"#;
const SHADER_SCANLINES: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let density = params.p[0].x;
    let dark    = params.p[0].y;
    let dim = vec2<f32>(textureDimensions(t_src));
    let line = floor(uv.y * dim.y / density) % 2.0;
    let factor = 1.0 - line * dark;
    return vec4<f32>(col.rgb * factor, col.a);
}
"#;
const SHADER_PIXELATE: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let px = max(params.p[0].x, 1.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let snapped = floor(uv * dim / px) * px / dim;
    return textureSample(t_src, s_src, snapped);
}
"#;
const SHADER_HUESHIFT: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
fn rgb2hsv(c: vec3<f32>) -> vec3<f32> {
    let K = vec4<f32>(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    let p = mix(vec4<f32>(c.bg, K.wz), vec4<f32>(c.gb, K.xy), step(c.b, c.g));
    let q = mix(vec4<f32>(p.xyw, c.r), vec4<f32>(c.r, p.yzx), step(p.x, c.r));
    let d = q.x - min(q.w, q.y);
    let e = 1.0e-10;
    return vec3<f32>(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
fn hsv2rgb(c: vec3<f32>) -> vec3<f32> {
    let K = vec4<f32>(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    let p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, vec3<f32>(0.0), vec3<f32>(1.0)), c.y);
}
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let shift = params.p[0].x / (2.0 * 3.14159265);
    var hsv = rgb2hsv(col.rgb);
    hsv.x = fract(hsv.x + shift);
    return vec4<f32>(hsv2rgb(hsv), col.a);
}
"#;
const SHADER_EDGEDETECT: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let str = params.p[0].x;
    let dim = vec2<f32>(textureDimensions(t_src));
    let s = 1.0 / dim;
    let tl = dot(textureSample(t_src,s_src,uv+vec2<f32>(-s.x,-s.y)).rgb,vec3<f32>(.299,.587,.114));
    let tm = dot(textureSample(t_src,s_src,uv+vec2<f32>(  0.0,-s.y)).rgb,vec3<f32>(.299,.587,.114));
    let tr_ = dot(textureSample(t_src,s_src,uv+vec2<f32>( s.x,-s.y)).rgb,vec3<f32>(.299,.587,.114));
    let ml = dot(textureSample(t_src,s_src,uv+vec2<f32>(-s.x, 0.0)).rgb,vec3<f32>(.299,.587,.114));
    let mr = dot(textureSample(t_src,s_src,uv+vec2<f32>( s.x, 0.0)).rgb,vec3<f32>(.299,.587,.114));
    let bl = dot(textureSample(t_src,s_src,uv+vec2<f32>(-s.x, s.y)).rgb,vec3<f32>(.299,.587,.114));
    let bm = dot(textureSample(t_src,s_src,uv+vec2<f32>(  0.0, s.y)).rgb,vec3<f32>(.299,.587,.114));
    let br = dot(textureSample(t_src,s_src,uv+vec2<f32>( s.x, s.y)).rgb,vec3<f32>(.299,.587,.114));
    let gx = (-tl - 2.0*ml - bl + tr_ + 2.0*mr + br);
    let gy = (-tl - 2.0*tm - tr_ + bl + 2.0*bm + br);
    let edge = clamp(length(vec2<f32>(gx, gy)) * str, 0.0, 1.0);
    return vec4<f32>(vec3<f32>(edge), 1.0);
}
"#;
const SHADER_GODRAYS: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let light_pos = params.p[0].xy;
    let decay     = params.p[0].z;
    let weight    = params.p[0].w;
    let density   = params.p[1].x;
    let exposure  = params.p[1].y;
    let SAMPLES   = 64;
    var delta_uv = (uv - light_pos) * (density / f32(SAMPLES));
    var step_uv = uv;
    var illumination = vec4<f32>(0.0);
    var illum_decay = 1.0;
    for (var i = 0; i < SAMPLES; i++) {
        step_uv -= delta_uv;
        let samp = textureSample(t_src, s_src, step_uv);
        illumination += samp * illum_decay * weight;
        illum_decay  *= decay;
    }
    return illumination * exposure + textureSample(t_src, s_src, uv);
}
"#;
const SHADER_WATERDISTORT: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let amp  = params.p[0].x;
    let freq = params.p[0].y;
    let t    = params.p[0].z;
    let dx = sin(uv.y * freq + t) * amp;
    let dy = cos(uv.x * freq + t) * amp;
    return textureSample(t_src, s_src, uv + vec2<f32>(dx, dy));
}
"#;
const SHADER_SHARPEN: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let str = params.p[0].x;
    let dim = vec2<f32>(textureDimensions(t_src));
    let s = 1.0 / dim;
    let c = textureSample(t_src, s_src, uv).rgb;
    let t_ = textureSample(t_src, s_src, uv + vec2<f32>(0.0, -s.y)).rgb;
    let l = textureSample(t_src, s_src, uv + vec2<f32>(-s.x, 0.0)).rgb;
    let r = textureSample(t_src, s_src, uv + vec2<f32>( s.x, 0.0)).rgb;
    let b = textureSample(t_src, s_src, uv + vec2<f32>(0.0,  s.y)).rgb;
    let sharpened = c * (1.0 + 4.0 * str) - (t_ + l + r + b) * str;
    let col_full = textureSample(t_src, s_src, uv);
    return vec4<f32>(clamp(sharpened, vec3<f32>(0.0), vec3<f32>(1.0)), col_full.a);
}
"#;
const SHADER_DITHER: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
fn bayer2(x: i32, y: i32) -> f32 {
    let b = array<f32,4>(0.0, 2.0, 3.0, 1.0);
    return b[(y % 2) * 2 + (x % 2)] / 4.0 - 0.5;
}
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let levels = max(params.p[0].x, 2.0);
    let dim = vec2<i32>(textureDimensions(t_src));
    let px = vec2<i32>(i32(uv.x * f32(dim.x)), i32(uv.y * f32(dim.y)));
    let threshold = bayer2(px.x, px.y) / levels;
    let dithered = floor(col.rgb * levels + threshold + 0.5) / levels;
    return vec4<f32>(clamp(dithered, vec3<f32>(0.0), vec3<f32>(1.0)), col.a);
}
"#;
const SHADER_OUTLINE: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let col = textureSample(t_src, s_src, uv);
    let outline_col = params.p[0].xyz;
    let thickness  = max(params.p[0].w, 1.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let s = thickness / dim;
    let a  = col.a;
    let aL = textureSample(t_src, s_src, uv + vec2<f32>(-s.x, 0.0)).a;
    let aR = textureSample(t_src, s_src, uv + vec2<f32>( s.x, 0.0)).a;
    let aT = textureSample(t_src, s_src, uv + vec2<f32>(0.0, -s.y)).a;
    let aB = textureSample(t_src, s_src, uv + vec2<f32>(0.0,  s.y)).a;
    let edge = clamp((aL + aR + aT + aB) - a * 4.0, 0.0, 1.0);
    return mix(col, vec4<f32>(outline_col, 1.0), edge * (1.0 - a));
}
"#;
const SHADER_DEPTHOFFIELD: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let focus  = params.p[0].xy;
    let str    = params.p[0].z;
    let radius = max(params.p[0].w, 0.001);
    let dist   = length(uv - focus);
    let blur   = clamp((dist / radius) * str, 0.0, 1.0);
    let dim = vec2<f32>(textureDimensions(t_src));
    let step = blur * 5.0 / dim;
    var col = vec4<f32>(0.0);
    let k: i32 = 3;
    for (var i = -k; i <= k; i++) {
        for (var j = -k; j <= k; j++) {
            col += textureSample(t_src, s_src, uv + vec2<f32>(f32(i), f32(j)) * step);
        }
    }
    col /= f32((2 * k + 1) * (2 * k + 1));
    return col;
}
"#;
const SHADER_MOTIONBLUR: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let center  = params.p[0].xy;
    let str     = params.p[0].z;
    let samples = max(i32(params.p[0].w), 1);
    let dir = (uv - center) * str / f32(samples);
    var col = vec4<f32>(0.0);
    for (var i = 0; i < samples; i++) {
        col += textureSample(t_src, s_src, uv - dir * f32(i));
    }
    return col / f32(samples);
}
"#;
const SHADER_COPY: &str = r#"
struct PostFxParams { p: array<vec4<f32>, 4>, }
@group(0) @binding(0) var t_src: texture_2d<f32>;
@group(0) @binding(1) var s_src: sampler;
@group(0) @binding(2) var<uniform> params: PostFxParams;
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    return textureSample(t_src, s_src, uv);
}
"#;
#[allow(dead_code)]
pub fn params_to_uniform(params: &HashMap<String, f32>) -> [f32; 16] {
    let get = |key: &str| params.get(key).copied().unwrap_or(0.0);
    [
        get("strength"),
        get("intensity"),
        get("radius"),
        get("thickness"),
        get("focus_x"),
        get("focus_y"),
        get("density"),
        get("exposure"),
        get("color_r"),
        get("color_g"),
        get("color_b"),
        get("time"),
        get("frequency"),
        get("amplitude"),
        get("samples"),
        get("palette_size"),
    ]
}
pub struct PostFxTexture {
    pub texture: wgpu::Texture,
    pub view: wgpu::TextureView,
}
impl PostFxTexture {
    pub fn new(
        device: &wgpu::Device,
        width: u32,
        height: u32,
        label: &str,
        format: wgpu::TextureFormat,
    ) -> Self {
        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some(label),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT
                | wgpu::TextureUsages::TEXTURE_BINDING
                | wgpu::TextureUsages::COPY_SRC,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        Self { texture, view }
    }
}
pub struct PostFxPipeline {
    pub(crate) pipelines: HashMap<String, wgpu::RenderPipeline>,
    pub(crate) sampler: wgpu::Sampler,
    pub(crate) params_buf: wgpu::Buffer,
    pub(crate) bind_group_layout: wgpu::BindGroupLayout,
    surface_format: wgpu::TextureFormat,
}
impl PostFxPipeline {
    pub fn new(device: &wgpu::Device, surface_format: wgpu::TextureFormat) -> Self {
        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("postfx_bgl"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                        view_dimension: wgpu::TextureViewDimension::D2,
                        multisampled: false,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 2,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
            ],
        });
        let layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("postfx_layout"),
            bind_group_layouts: &[&bind_group_layout],
            push_constant_ranges: &[],
        });
        let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("postfx_sampler"),
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });
        let params_buf = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("postfx_params"),
            size: 64,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let vs_src = POSTFX_VERTEX;
        let vs_module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("postfx_vs"),
            source: wgpu::ShaderSource::Wgsl(vs_src.into()),
        });
        let build = |name: &str, fs_src: &str| -> wgpu::RenderPipeline {
            let full_src = format!("{vs_src}\n{fs_src}");
            let module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some(name),
                source: wgpu::ShaderSource::Wgsl(full_src.into()),
            });
            device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                label: Some(name),
                layout: Some(&layout),
                vertex: wgpu::VertexState {
                    module: &module,
                    entry_point: "vs_main",
                    buffers: &[],
                    compilation_options: Default::default(),
                },
                fragment: Some(wgpu::FragmentState {
                    module: &module,
                    entry_point: "fs_main",
                    targets: &[Some(wgpu::ColorTargetState {
                        format: surface_format,
                        blend: Some(wgpu::BlendState::REPLACE),
                        write_mask: wgpu::ColorWrites::ALL,
                    })],
                    compilation_options: Default::default(),
                }),
                primitive: wgpu::PrimitiveState {
                    topology: wgpu::PrimitiveTopology::TriangleList,
                    ..Default::default()
                },
                depth_stencil: None,
                multisample: wgpu::MultisampleState::default(),
                multiview: None,
                cache: None,
            })
        };
        let _ = vs_module;
        let mut pipelines = HashMap::new();
        pipelines.insert("bloom".into(), build("postfx_bloom", SHADER_BLOOM));
        pipelines.insert("blur_h".into(), build("postfx_blur_h", SHADER_BLUR_H));
        pipelines.insert("blur_v".into(), build("postfx_blur_v", SHADER_BLUR_V));
        pipelines.insert("vignette".into(), build("postfx_vignette", SHADER_VIGNETTE));
        pipelines.insert("noise".into(), build("postfx_noise", SHADER_NOISE));
        pipelines.insert(
            "grayscale".into(),
            build("postfx_grayscale", SHADER_GRAYSCALE),
        );
        pipelines.insert("sepia".into(), build("postfx_sepia", SHADER_SEPIA));
        pipelines.insert("invert".into(), build("postfx_invert", SHADER_INVERT));
        pipelines.insert("crt".into(), build("postfx_crt", SHADER_CRT));
        pipelines.insert(
            "chromatic".into(),
            build("postfx_chromatic", SHADER_CHROMATIC),
        );
        pipelines.insert(
            "scanlines".into(),
            build("postfx_scanlines", SHADER_SCANLINES),
        );
        pipelines.insert("pixelate".into(), build("postfx_pixelate", SHADER_PIXELATE));
        pipelines.insert("hueshift".into(), build("postfx_hueshift", SHADER_HUESHIFT));
        pipelines.insert(
            "edgedetect".into(),
            build("postfx_edgedetect", SHADER_EDGEDETECT),
        );
        pipelines.insert("godrays".into(), build("postfx_godrays", SHADER_GODRAYS));
        pipelines.insert(
            "waterdistort".into(),
            build("postfx_waterdistort", SHADER_WATERDISTORT),
        );
        pipelines.insert("sharpen".into(), build("postfx_sharpen", SHADER_SHARPEN));
        pipelines.insert("dither".into(), build("postfx_dither", SHADER_DITHER));
        pipelines.insert("outline".into(), build("postfx_outline", SHADER_OUTLINE));
        pipelines.insert(
            "depthoffield".into(),
            build("postfx_depthoffield", SHADER_DEPTHOFFIELD),
        );
        pipelines.insert(
            "motionblur".into(),
            build("postfx_motionblur", SHADER_MOTIONBLUR),
        );
        pipelines.insert("__copy".into(), build("postfx_copy", SHADER_COPY));
        Self {
            pipelines,
            sampler,
            params_buf,
            bind_group_layout,
            surface_format,
        }
    }
    pub fn register_custom(&mut self, device: &wgpu::Device, name: &str, fs_src: &str) {
        let full_src = format!("{POSTFX_VERTEX}\n{fs_src}");
        let label = format!("postfx_custom_{name}");
        let layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some(&label),
            bind_group_layouts: &[&self.bind_group_layout],
            push_constant_ranges: &[],
        });
        let module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some(&label),
            source: wgpu::ShaderSource::Wgsl(full_src.into()),
        });
        let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some(&label),
            layout: Some(&layout),
            vertex: wgpu::VertexState {
                module: &module,
                entry_point: "vs_main",
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &module,
                entry_point: "fs_main",
                targets: &[Some(wgpu::ColorTargetState {
                    format: self.surface_format,
                    blend: Some(wgpu::BlendState::REPLACE),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
                compilation_options: Default::default(),
            }),
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleList,
                ..Default::default()
            },
            depth_stencil: None,
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        });
        self.pipelines.insert(name.to_string(), pipeline);
    }
    #[allow(clippy::too_many_arguments)]
    pub fn apply(
        &self,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        encoder: &mut wgpu::CommandEncoder,
        capture_view: &wgpu::TextureView,
        target_view: &wgpu::TextureView,
        passes: &[crate::render::renderer::PostFxPass],
        width: u32,
        height: u32,
        total_time: f32,
        frame_count: u64,
    ) {
        if passes.is_empty() {
            self.run_copy_pass(device, encoder, queue, capture_view, target_view);
            return;
        }
        let ping = PostFxTexture::new(device, width, height, "postfx_ping", self.surface_format);
        let pong = PostFxTexture::new(device, width, height, "postfx_pong", self.surface_format);
        let textures = [&ping, &pong];
        let mut src_view: &wgpu::TextureView = capture_view;
        let mut dst_idx = 0usize;
        let n = passes.len();
        for (i, pass) in passes.iter().enumerate() {
            let is_last = i == n - 1;
            let dst_view: &wgpu::TextureView = if is_last {
                target_view
            } else {
                &textures[dst_idx].view
            };
            let mut raw = params_to_uniform(&pass.params);
            if pass.auto_uniforms {
                raw[12] = total_time;
                raw[13] = frame_count as f32;
                raw[14] = width as f32;
                raw[15] = height as f32;
            }
            queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));
            let effect_key = pass.effect_name.as_str();
            let Some(pipeline) = self.pipelines.get(effect_key) else {
                log::warn!("PostFxPipeline: unknown effect '{}' — skipped", effect_key);
                self.run_copy_pass(device, encoder, queue, src_view, dst_view);
                if !is_last {
                    src_view = &textures[dst_idx].view;
                    dst_idx = 1 - dst_idx;
                }
                continue;
            };
            let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
                label: Some("postfx_bg"),
                layout: &self.bind_group_layout,
                entries: &[
                    wgpu::BindGroupEntry {
                        binding: 0,
                        resource: wgpu::BindingResource::TextureView(src_view),
                    },
                    wgpu::BindGroupEntry {
                        binding: 1,
                        resource: wgpu::BindingResource::Sampler(&self.sampler),
                    },
                    wgpu::BindGroupEntry {
                        binding: 2,
                        resource: self.params_buf.as_entire_binding(),
                    },
                ],
            });
            {
                let mut rp = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("postfx_pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: dst_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    ..Default::default()
                });
                rp.set_pipeline(pipeline);
                rp.set_bind_group(0, &bind_group, &[]);
                rp.draw(0..3, 0..1);
            }
            if !is_last {
                src_view = &textures[dst_idx].view;
                dst_idx = 1 - dst_idx;
            }
        }
    }
    fn run_copy_pass(
        &self,
        device: &wgpu::Device,
        encoder: &mut wgpu::CommandEncoder,
        queue: &wgpu::Queue,
        src_view: &wgpu::TextureView,
        dst_view: &wgpu::TextureView,
    ) {
        let raw = [0.0f32; 16];
        queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));
        let Some(copy_pipeline) = self.pipelines.get("__copy") else {
            return;
        };
        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("postfx_copy_bg"),
            layout: &self.bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(src_view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(&self.sampler),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: self.params_buf.as_entire_binding(),
                },
            ],
        });
        let mut rp = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("postfx_copy_pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view: dst_view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: wgpu::StoreOp::Store,
                },
            })],
            depth_stencil_attachment: None,
            ..Default::default()
        });
        rp.set_pipeline(copy_pipeline);
        rp.set_bind_group(0, &bind_group, &[]);
        rp.draw(0..3, 0..1);
    }
}
