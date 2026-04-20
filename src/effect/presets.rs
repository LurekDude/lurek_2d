//! Preset effect stacks for common visual styles.
//!
//! Provides named factories that return a pre-configured
//! [`PostFxStack`] + matching [`PostFxEffect`] list ready to push into
//! the render queue. All presets are self-contained — every effect's
//! parameters are tuned for a pleasant out-of-the-box experience.

use super::effect::PostFxEffect;
use super::effect_type::PostFxEffectType;
use super::stack::PostFxStack;

/// A fully configured preset: an ordered stack of effects with their data.
///
/// # Fields
/// - `name` — `&'static str`.
/// - `effects` — `Vec<PostFxEffect>`.
/// - `stack` — `PostFxStack`.
#[derive(Debug, Clone)]
pub struct EffectPreset {
    /// Human-readable label (e.g. `"retro_tv"`).
    pub name: &'static str,
    /// The effects in stack order. Each element pairs to the matching
    /// `PostFxStack` entry at the same index.
    pub effects: Vec<PostFxEffect>,
    /// The underlying stack descriptor (indices are 0..effects.len()).
    pub stack: PostFxStack,
}

/// Returns a list of all available preset names.
///
/// # Returns
/// `Vec<&'static str>` — sorted slice of preset name strings.
pub fn preset_names() -> Vec<&'static str> {
    vec!["retro_tv", "horror", "dream", "neon", "sepia_age"]
}

/// Builds a named preset stack, returning `None` when the name is unknown.
///
/// # Parameters
/// - `name` — `&str` — Case-insensitive preset identifier.
/// - `width` — `u32` — Capture width in pixels.
/// - `height` — `u32` — Capture height in pixels.
///
/// # Returns
/// `Option<EffectPreset>`
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

// ── Individual preset builders ────────────────────────────────────────────────

/// CRT + Scanlines + Chromatic aberration + soft Bloom.
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

/// Vignette + film-grain noise + desaturation + subtle ChromaticAberration.
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

/// Heavy Bloom + soft Blur + gentle HueShift for a dreamy render.
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

/// EdgeDetect → HueShift → Bloom for a cyberpunk neon aesthetic.
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

/// Sepia tone + FilmGrain + Vignette for an aged-photograph feel.
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

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns a static string slice for a known preset name (lowercase).
fn preset_static_name(name: &str) -> &'static str {
    match name.to_ascii_lowercase().as_str() {
        "horror" => "horror",
        "dream" => "dream",
        "neon" => "neon",
        "sepia_age" => "sepia_age",
        _ => "retro_tv",
    }
}
