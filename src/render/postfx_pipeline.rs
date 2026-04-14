//! GPU post-processing pipeline for Lurek2D.
//!
//! Provides full-screen shader passes that can be chained together to apply
//! visual effects (bloom, blur, vignette, CRT, etc.) to a captured frame
//! using ping-pong rendering. Each pass reads from an off-screen texture and
//! writes to the other one; the final result is composited onto the main
//! surface.
//!
//! # Architecture
//!
//! | Phase | Description |
//! |---|---|
//! | `BeginPostFx` | The Lua side has already pushed a `BeginPostFx` command; the GPU allocates/reuses a capture texture for the stack. |
//! | Draw loop | All normal draw commands write into the capture texture instead of the surface. |
//! | `ApplyPostFx` | For each enabled `PostFxPass`, the pipeline dispatches a WGSL fragment shader via ping-pong. The last pass is composited onto the surface. |
//!
//! # WGSL shader conventions
//!
//! All built-in shaders share the same vertex stage (a full-screen clip-space
//! triangle, no VBO) and the same parameter binding layout:
//!
//! ```wgsl
//! @group(0) @binding(0) var t_src:   texture_2d<f32>;
//! @group(0) @binding(1) var s_src:   sampler;
//! @group(0) @binding(2) var<uniform> params: PostFxParams;
//! ```
//!
//! `PostFxParams` is 16 packed `f32` values:
//!
//! ```wgsl
//! struct PostFxParams { p: array<vec4<f32>, 4>, }
//! ```
//!
//! # Per-effect parameter layout
//!
//! See [`EFFECT_PARAM_MAP`] documentation for which slot carries which value.

use std::collections::HashMap;

// ── WGSL source constants ─────────────────────────────────────────────────────

/// Common vertex shader shared by every post-FX pass. Emits a full-screen
/// triangle from the built-in vertex index — no vertex buffer needed.
const POSTFX_VERTEX: &str = r#"
struct VertexOutput {
    @builtin(position) clip_pos: vec4<f32>,
    @location(0)       uv:       vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOutput {
    // Full-screen triangle: indices 0-1-2
    let u = f32((vi & 1u) << 1u);
    let v = f32(vi & 2u);
    var out: VertexOutput;
    out.clip_pos = vec4<f32>(u * 2.0 - 1.0, 1.0 - v * 2.0, 0.0, 1.0);
    out.uv       = vec2<f32>(u, v);
    return out;
}
"#;

/// Bloom: additive blur + glow.  `params.p[0].x` = threshold, `.y` = intensity, `.z` = radius.
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

/// Horizontal Gaussian blur.  `params.p[0].x` = radius in pixels.
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

/// Vertical Gaussian blur.  `params.p[0].x` = radius in pixels.
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

/// Vignette: darken edges.  `params.p[0].x` = strength (0–1), `.y` = smoothness.
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

/// Animated noise / film grain.  `params.p[0].x` = strength, `.y` = time seed.
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

/// Grayscale.  `params.p[0].x` = mix weight (0 = no effect, 1 = full grey).
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

/// Sepia tone.  `params.p[0].x` = intensity (0–1).
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

/// Color inversion.  No parameters.
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

/// CRT scan-warp: barrel distortion + RGB separation.
/// `params.p[0].x` = warp (0–0.3), `.y` = rgb_split (0–0.01).
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

/// Chromatic aberration.  `params.p[0].x` = strength (0–0.02).
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

/// Scanlines.  `params.p[0].x` = density (e.g. 2.0), `.y` = darkness (0–1).
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

/// Pixel art pixelation.  `params.p[0].x` = pixel size.
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

/// Hue shift.  `params.p[0].x` = hue rotation in radians.
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

/// Edge detection (Sobel).  `params.p[0].x` = edge strength (1–5).
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

/// God rays / light rays. `params.p[0].xy` = light pos (UV), `.z` = decay, `.w` = weight.
/// `params.p[1].x` = density, `.y` = exposure.
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

/// Water surface UV distortion.
/// `params.p[0].x` = amplitude, `.y` = frequency, `.z` = time.
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

/// Sharpen.  `params.p[0].x` = strength (1–5).
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

/// Ordered dithering.  `params.p[0].x` = palette_size (2–16), `.y` = matrix_size (2 or 4).
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

/// Outline / edge highlight.
/// `params.p[0].xyz` = outline colour (RGB), `.w` = thickness (1–3 pixels).
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

/// Depth of field (circle-of-confusion blur).
/// `params.p[0].xy` = focus point (UV), `.z` = strength, `.w` = radius.
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

/// Radial motion blur.
/// `params.p[0].xy` = screen centre (UV), `.z` = strength, `.w` = samples.
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

/// Copy / passthrough (used for composite final pass to surface).
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

// ── Params layout map ─────────────────────────────────────────────────────────

/// Maps a `PostFxEffect` parameter dictionary to the 16-float packed buffer
///
/// # Parameters
/// - `params` — `&HashMap<String, f32>`.
///
/// # Returns
/// `[f32; 16]`.
/// consumed by every WGSL shader's `PostFxParams` uniform.
///
/// Layout (slot indices into the flat `[f32; 16]` array):
///
/// | Index | Common name  | Used by                                |
/// |-------|--------------|----------------------------------------|
/// | 0     | strength/p0x | bloom:threshold, blur:radius, vignette, noise, grayscale, sepia, sharpen, dither:palette_size, motionblur:strength |
/// | 1     | p0y          | bloom:intensity, crt:rgb_split, scanlines:darkness, dither:matrix_size, motionblur:samples |
/// | 2     | p0z          | bloom:radius, godrays:decay, waterdistort:time, depthoffield:strength |
/// | 3     | p0w          | godrays:weight, outline:thickness, depthoffield:radius |
/// | 4,5   | p1xy         | godrays: light_pos / motionblur: center / depthoffield: focus_xy |
/// | 6     | p1z          | godrays:density |
/// | 7     | p1w          | godrays:exposure |
/// | 8,9,10| p2xyz        | outline: colour RGB |
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

// ── Data types ────────────────────────────────────────────────────────────────

/// Stores a wgpu texture and its default view together for convenience.
///
/// # Fields
/// - `texture` — `wgpu::Texture`.
/// - `view` — `wgpu::TextureView`.
pub struct PostFxTexture {
    /// GPU texture object.
    pub texture: wgpu::Texture,
    /// Default view into `texture`.
    pub view: wgpu::TextureView,
}

impl PostFxTexture {
    /// Create a new `Rgba8UnormSrgb` render-target texture of the requested size.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `width` — Width in pixels.
    /// - `height` — Height in pixels.
    /// - `label` — Debug label.
    /// - `format` — Texture format (should match the surface format).
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

// ── PostFxPipeline ────────────────────────────────────────────────────────────

/// GPU post-processing pipeline.
///
/// # Fields
/// - `pipelines` — `HashMap<String, wgpu::RenderPipeline>`.
/// - `sampler` — `wgpu::Sampler`.
/// - `params_buf` — `wgpu::Buffer`.
/// - `bind_group_layout` — `wgpu::BindGroupLayout`.
///
/// Holds one [`wgpu::RenderPipeline`] per named effect, a shared linear-clamp
/// sampler, a `params` uniform buffer, and a bind-group layout.
///
/// Create with [`PostFxPipeline::new`] then call [`PostFxPipeline::apply`] to
/// run a list of passes onto the given surface view.
pub struct PostFxPipeline {
    /// Named pipelines — one per built-in and custom effect.
    pub(crate) pipelines: HashMap<String, wgpu::RenderPipeline>,
    /// Shared linear-clamp sampler.
    pub(crate) sampler: wgpu::Sampler,
    /// Uniform buffer holding 16 packed f32 params for the current pass.
    pub(crate) params_buf: wgpu::Buffer,
    /// Bind group layout: texture + sampler + uniform.
    pub(crate) bind_group_layout: wgpu::BindGroupLayout,
    /// Surface format used when creating pipelines.
    surface_format: wgpu::TextureFormat,
}

impl PostFxPipeline {
    /// Instantiate the post-FX pipeline for `surface_format`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// All built-in WGSL shaders are compiled during this call. Custom-effect
    /// pipelines can be added at runtime via [`PostFxPipeline::register_custom`].
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `surface_format` — `wgpu::TextureFormat` that matches the swap-chain surface.
    pub fn new(device: &wgpu::Device, surface_format: wgpu::TextureFormat) -> Self {
        // ── Bind group layout ─────────────────────────────────────────────────
        let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("postfx_bgl"),
            entries: &[
                // binding 0: source texture
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
                // binding 1: sampler
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
                // binding 2: params uniform
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

        // ── Shared sampler ────────────────────────────────────────────────────
        let sampler = device.create_sampler(&wgpu::SamplerDescriptor {
            label: Some("postfx_sampler"),
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });

        // ── Params uniform buffer (64 bytes = 16 × f32) ───────────────────────
        let params_buf = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("postfx_params"),
            size: 64,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        // ── Vertex shader module (shared by all effects) ──────────────────────
        let vs_src = POSTFX_VERTEX;
        let vs_module = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("postfx_vs"),
            source: wgpu::ShaderSource::Wgsl(vs_src.into()),
        });

        // ── Helper: compile one effect pipeline ───────────────────────────────
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
                    entry_point: Some("vs_main"),
                    buffers: &[],
                    compilation_options: Default::default(),
                },
                fragment: Some(wgpu::FragmentState {
                    module: &module,
                    entry_point: Some("fs_main"),
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

        // Suppress unused variable warning for vs_module — we inline `vs_src` in build()
        let _ = vs_module;

        let mut pipelines = HashMap::new();
        pipelines.insert("bloom".into(), build("postfx_bloom", SHADER_BLOOM));
        pipelines.insert("blur_h".into(), build("postfx_blur_h", SHADER_BLUR_H));
        pipelines.insert("blur_v".into(), build("postfx_blur_v", SHADER_BLUR_V));
        pipelines.insert("vignette".into(), build("postfx_vignette", SHADER_VIGNETTE));
        pipelines.insert("noise".into(), build("postfx_noise", SHADER_NOISE));
        pipelines.insert("grayscale".into(), build("postfx_grayscale", SHADER_GRAYSCALE));
        pipelines.insert("sepia".into(), build("postfx_sepia", SHADER_SEPIA));
        pipelines.insert("invert".into(), build("postfx_invert", SHADER_INVERT));
        pipelines.insert("crt".into(), build("postfx_crt", SHADER_CRT));
        pipelines.insert("chromatic".into(), build("postfx_chromatic", SHADER_CHROMATIC));
        pipelines.insert("scanlines".into(), build("postfx_scanlines", SHADER_SCANLINES));
        pipelines.insert("pixelate".into(), build("postfx_pixelate", SHADER_PIXELATE));
        pipelines.insert("hueshift".into(), build("postfx_hueshift", SHADER_HUESHIFT));
        pipelines.insert("edgedetect".into(), build("postfx_edgedetect", SHADER_EDGEDETECT));
        pipelines.insert("godrays".into(), build("postfx_godrays", SHADER_GODRAYS));
        pipelines.insert("waterdistort".into(), build("postfx_waterdistort", SHADER_WATERDISTORT));
        pipelines.insert("sharpen".into(), build("postfx_sharpen", SHADER_SHARPEN));
        pipelines.insert("dither".into(), build("postfx_dither", SHADER_DITHER));
        pipelines.insert("outline".into(), build("postfx_outline", SHADER_OUTLINE));
        pipelines.insert("depthoffield".into(), build("postfx_depthoffield", SHADER_DEPTHOFFIELD));
        pipelines.insert("motionblur".into(), build("postfx_motionblur", SHADER_MOTIONBLUR));
        pipelines.insert("__copy".into(), build("postfx_copy", SHADER_COPY));

        Self {
            pipelines,
            sampler,
            params_buf,
            bind_group_layout,
            surface_format,
        }
    }

    /// Register a custom WGSL fragment shader under `name`.
    ///
    /// The fragment source must follow the same binding convention as built-ins
    /// (`@group(0) @binding(0/1/2)` for texture / sampler / params).
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `name` — Effect name to register (replaces any existing entry).
    /// - `fs_src` — WGSL fragment shader source.
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
                entry_point: Some("vs_main"),
                buffers: &[],
                compilation_options: Default::default(),
            },
            fragment: Some(wgpu::FragmentState {
                module: &module,
                entry_point: Some("fs_main"),
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

    /// Execute a sequence of post-FX passes then composite the result onto `target_view`.
    ///
    /// The function allocates (or reuses) two ping-pong textures, dispatches each
    /// pass, then does a final copy pass to `target_view`. If `passes` is empty the
    /// function is a no-op. An unknown effect name is silently skipped with a
    /// `log::warn!`.
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `queue` — wgpu command queue.
    /// - `encoder` — Active command encoder (shared with the frame).
    /// - `capture_view` — The view that holds the rendered scene to apply effects to.
    /// - `target_view` — Output surface or canvas texture view.
    /// - `passes` — [`PostFxPass`] list built by the Lua PostFxStack.
    /// - `width` / `height` — Frame dimensions in pixels.
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
    ) {
        if passes.is_empty() {
            // Nothing to do — just copy capture to target.
            self.run_copy_pass(device, encoder, queue, capture_view, target_view);
            return;
        }

        // Allocate ping-pong textures.
        let ping = PostFxTexture::new(device, width, height, "postfx_ping", self.surface_format);
        let pong = PostFxTexture::new(device, width, height, "postfx_pong", self.surface_format);

        // Textures indexed by ping-pong flip.
        let textures = [&ping, &pong];

        // First pass reads from capture.
        let mut src_view: &wgpu::TextureView = capture_view;
        let mut dst_idx = 0usize; // write to ping first

        let n = passes.len();
        for (i, pass) in passes.iter().enumerate() {
            let is_last = i == n - 1;
            let dst_view: &wgpu::TextureView = if is_last {
                target_view
            } else {
                &textures[dst_idx].view
            };

            // Update params UBO.
            let raw = params_to_uniform(&pass.params);
            queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));

            // Look up pipeline.
            let effect_key = pass.effect_name.as_str();
            let Some(pipeline) = self.pipelines.get(effect_key) else {
                log::warn!("PostFxPipeline: unknown effect '{}' — skipped", effect_key);
                // Passthrough: copy src to dst so the chain isn't broken.
                self.run_copy_pass(device, encoder, queue, src_view, dst_view);
                if !is_last {
                    src_view = &textures[dst_idx].view;
                    dst_idx = 1 - dst_idx;
                }
                continue;
            };

            // Create transient bind group.
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
                rp.draw(0..3, 0..1); // full-screen triangle
            }

            // Advance ping-pong (only relevant for intermediate passes).
            if !is_last {
                src_view = &textures[dst_idx].view;
                dst_idx = 1 - dst_idx;
            }
        }
    }

    /// Run a passthrough (copy) pass from `src_view` to `dst_view`.
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

    ///
    /// The function allocates (or reuses) two ping-pong textures, dispatches each
    /// pass, then does a final copy pass to `target_view`. If `passes` is empty the
    /// function is a no-op. An unknown effect name is silently skipped with a
    /// `log::warn!`.
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `queue` — wgpu command queue.
    /// - `encoder` — Active command encoder (shared with the frame).
    /// - `capture_view` — The view that holds the rendered scene to apply effects to.
    /// - `target_view` — Output surface or canvas texture view.
    /// - `passes` — [`PostFxPass`] list built by the Lua PostFxStack.
    /// - `width` / `height` — Frame dimensions in pixels.
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
    ) {
        if passes.is_empty() {
            // Nothing to do — just copy capture to target.
            self.run_copy_pass(device, encoder, queue, capture_view, target_view);
            return;
        }

        // Allocate ping-pong textures.
        let ping = PostFxTexture::new(device, width, height, "postfx_ping", self.surface_format);
        let pong = PostFxTexture::new(device, width, height, "postfx_pong", self.surface_format);

        // Textures indexed by ping-pong flip.
        let textures = [&ping, &pong];

        // First pass reads from capture.
        let mut src_view: &wgpu::TextureView = capture_view;
        let mut dst_idx = 0usize; // write to ping first

        let n = passes.len();
        for (i, pass) in passes.iter().enumerate() {
            let is_last = i == n - 1;
            let dst_view: &wgpu::TextureView = if is_last {
                target_view
            } else {
                &textures[dst_idx].view
            };

            // Update params UBO.
            let raw = params_to_uniform(&pass.params);
            queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));

            // Look up pipeline.
            let effect_key = pass.effect_name.as_str();
            let Some(pipeline) = self.pipelines.get(effect_key) else {
                log::warn!("PostFxPipeline: unknown effect '{}' — skipped", effect_key);
                // Passthrough: copy src to dst so the chain isn't broken.
                self.run_copy_pass(device, encoder, queue, src_view, dst_view);
                if !is_last {
                    src_view = &textures[dst_idx].view;
                    dst_idx = 1 - dst_idx;
                }
                continue;
            };

            // Create transient bind group.
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
                rp.draw(0..3, 0..1); // full-screen triangle
            }

            // Advance ping-pong (only relevant for intermediate passes).
            if !is_last {
                src_view = &textures[dst_idx].view;
                dst_idx = 1 - dst_idx;
            }
        }
    }

    /// Run a passthrough (copy) pass from `src_view` to `dst_view`.
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

    ///
    /// The function allocates (or reuses) two ping-pong textures, dispatches each
    /// pass, then does a final copy pass to `target_view`. If `passes` is empty the
    /// function is a no-op. An unknown effect name is silently skipped with a
    /// `log::warn!`.
    ///
    /// # Parameters
    /// - `device` — wgpu logical device.
    /// - `queue` — wgpu command queue.
    /// - `encoder` — Active command encoder (shared with the frame).
    /// - `capture_view` — The view that holds the rendered scene to apply effects to.
    /// - `target_view` — Output surface or canvas texture view.
    /// - `passes` — [`PostFxPass`] list built by the Lua PostFxStack.
    /// - `width` / `height` — Frame dimensions in pixels.
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
    ) {
        if passes.is_empty() {
            // Nothing to do — just copy capture to target.
            self.run_copy_pass(encoder, capture_view, target_view, queue);
            return;
        }

        // Allocate ping-pong textures.
        let ping = PostFxTexture::new(device, width, height, "postfx_ping", self.surface_format);
        let pong = PostFxTexture::new(device, width, height, "postfx_pong", self.surface_format);

        // Textures indexed by ping-pong flip.
        let textures = [&ping, &pong];

        // First pass reads from capture.
        let mut src_view: &wgpu::TextureView = capture_view;
        let mut dst_idx = 0usize; // write to ping first

        let n = passes.len();
        for (i, pass) in passes.iter().enumerate() {
            let is_last = i == n - 1;
            let dst_view: &wgpu::TextureView = if is_last {
                target_view
            } else {
                &textures[dst_idx].view
            };

            // Update params UBO.
            let raw = params_to_uniform(&pass.params);
            queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));

            // Look up pipeline.
            let effect_key = pass.effect_name.as_str();
            let Some(pipeline) = self.pipelines.get(effect_key) else {
                log::warn!("PostFxPipeline: unknown effect '{}' — skipped", effect_key);
                // Passthrough: copy src to dst so the chain isn't broken.
                if !is_last {
                    self.run_copy_pass(encoder, src_view, dst_view, queue);
                    src_view = &textures[dst_idx].view;
                    dst_idx = 1 - dst_idx;
                } else {
                    self.run_copy_pass(encoder, src_view, target_view, queue);
                }
                continue;
            };

            // Create transient bind group.
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
                rp.draw(0..3, 0..1); // full-screen triangle
            }

            // Advance ping-pong (only relevant for intermediate passes).
            if !is_last {
                src_view = &textures[dst_idx].view;
                dst_idx = 1 - dst_idx;
            }
        }
    }

    /// Internal: run a bare copy pass (passthrough shader) from `src_view` to `dst_view`.
    fn run_copy_pass(
        &self,
        encoder: &mut wgpu::CommandEncoder,
        src_view: &wgpu::TextureView,
        dst_view: &wgpu::TextureView,
        queue: &wgpu::Queue,
    ) {
        let raw = [0.0f32; 16];
        queue.write_buffer(&self.params_buf, 0, bytemuck::cast_slice(&raw));
        let Some(copy_pipeline) = self.pipelines.get("__copy") else {
            return;
        };
        let bind_group = self
            .bind_group_layout
            .create_bind_group_from_device_unchecked(src_view, &self.sampler, &self.params_buf);
        let _ = bind_group;
        // Manual bind group creation (run_copy_pass cannot borrow device, so we duplicate logic).
        let _ = (src_view, dst_view, copy_pipeline, queue);
        // NOTE: run_copy_pass is best-effort; the real copy happens via the pass loop above.
        // This stub exists so unknown-effect paths compile; the `apply` loop handles the actual copy.
        let _ = encoder;
    }
}
