use super::effect::PostFxEffect;
use super::effect_type::PostFxEffectType;
use super::stack::PostFxStack;
#[derive(Debug, Clone)]
pub struct EffectPreset {
    pub name: &'static str,
    pub effects: Vec<PostFxEffect>,
    pub stack: PostFxStack,
}
pub fn preset_names() -> Vec<&'static str> {
    vec!["retro_tv", "horror", "dream", "neon", "sepia_age"]
}
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
fn preset_static_name(name: &str) -> &'static str {
    match name.to_ascii_lowercase().as_str() {
        "horror" => "horror",
        "dream" => "dream",
        "neon" => "neon",
        "sepia_age" => "sepia_age",
        _ => "retro_tv",
    }
}
