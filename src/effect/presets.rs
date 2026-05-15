//! - Built-in post-processing effect presets (retro TV, horror, dream, neon, sepia).
//! - Preset construction with viewport-sized stack initialization.
//! - Static name lookup for canonical preset identifiers.

use super::effect::PostFxEffect;
use super::effect_type::PostFxEffectType;
use super::stack::PostFxStack;

/// Bundle a preset name, its effect list, and a prepared stack ordering.
#[derive(Debug, Clone)]
pub struct EffectPreset {
    /// Stable preset identifier exposed to callers.
    pub name: &'static str,
    /// Effect instances that make up this preset.
    pub effects: Vec<PostFxEffect>,
    /// Stack ordering that enables every effect in the preset.
    pub stack: PostFxStack,
}
/// Returns the canonical names of all built-in post-effect presets.
pub fn preset_names() -> Vec<&'static str> {
    vec!["retro_tv", "horror", "dream", "neon", "sepia_age"]
}
/// Builds a named preset and initializes a stack sized for the target viewport.
pub fn build_preset(name: &str, width: u32, height: u32) -> Option<EffectPreset> {
    let effects: Vec<PostFxEffect> = match name.to_ascii_lowercase().as_str() {
        "retro_tv" => build_retro_tv(),
        "horror" => build_horror(),
        "dream" => build_dream(),
        "neon" => build_neon(),
        "sepia_age" => build_sepia_age(),
        _ => return None,
    };
    let count = effects.len();
    let mut stack = PostFxStack::new(width, height);
    for i in 0..count {
        stack.add(i);
    }
    Some(EffectPreset {
        name: preset_static_name(name),
        effects,
        stack,
    })
}
/// Builds the retro TV preset effect chain.
fn build_retro_tv() -> Vec<PostFxEffect> {
    let mut bloom = PostFxEffect::new(PostFxEffectType::Bloom);
    bloom.set_param("threshold", 0.6);
    bloom.set_param("intensity", 0.4);
    let mut crt = PostFxEffect::new(PostFxEffectType::Crt);
    crt.set_param("curvature", 0.3);
    let mut scan = PostFxEffect::new(PostFxEffectType::Scanlines);
    scan.set_param("intensity", 0.35);
    let mut chrom = PostFxEffect::new(PostFxEffectType::Chromatic);
    chrom.set_param("offset", 0.003);
    vec![bloom, crt, scan, chrom]
}
/// Builds the horror preset effect chain.
fn build_horror() -> Vec<PostFxEffect> {
    let mut vignette = PostFxEffect::new(PostFxEffectType::Vignette);
    vignette.set_param("radius", 0.55);
    vignette.set_param("softness", 0.4);
    let mut noise = PostFxEffect::new(PostFxEffectType::Noise);
    noise.set_param("strength", 0.12);
    let mut gray = PostFxEffect::new(PostFxEffectType::Grayscale);
    gray.set_param("strength", 0.6);
    let mut chrom = PostFxEffect::new(PostFxEffectType::Chromatic);
    chrom.set_param("offset", 0.002);
    vec![vignette, noise, gray, chrom]
}
/// Builds the dream preset effect chain.
fn build_dream() -> Vec<PostFxEffect> {
    let mut bloom = PostFxEffect::new(PostFxEffectType::Bloom);
    bloom.set_param("threshold", 0.3);
    bloom.set_param("intensity", 0.9);
    let mut blur = PostFxEffect::new(PostFxEffectType::Blur);
    blur.set_param("radius", 2.0);
    let mut hue = PostFxEffect::new(PostFxEffectType::HueShift);
    hue.set_param("hue", 20.0);
    vec![bloom, blur, hue]
}
/// Builds the neon preset effect chain.
fn build_neon() -> Vec<PostFxEffect> {
    let mut edge = PostFxEffect::new(PostFxEffectType::EdgeDetect);
    edge.set_param("threshold", 0.1);
    let mut hue = PostFxEffect::new(PostFxEffectType::HueShift);
    hue.set_param("hue", 160.0);
    let mut bloom = PostFxEffect::new(PostFxEffectType::Bloom);
    bloom.set_param("threshold", 0.4);
    bloom.set_param("intensity", 0.7);
    vec![edge, hue, bloom]
}
/// Builds the aged sepia preset effect chain.
fn build_sepia_age() -> Vec<PostFxEffect> {
    let mut sepia = PostFxEffect::new(PostFxEffectType::Sepia);
    sepia.set_param("strength", 0.85);
    let mut noise = PostFxEffect::new(PostFxEffectType::Noise);
    noise.set_param("strength", 0.08);
    let mut vignette = PostFxEffect::new(PostFxEffectType::Vignette);
    vignette.set_param("radius", 0.65);
    vignette.set_param("softness", 0.35);
    vec![sepia, noise, vignette]
}
/// Maps a user-supplied preset name to the stored static preset identifier.
fn preset_static_name(name: &str) -> &'static str {
    match name.to_ascii_lowercase().as_str() {
        "horror" => "horror",
        "dream" => "dream",
        "neon" => "neon",
        "sepia_age" => "sepia_age",
        _ => "retro_tv",
    }
}
