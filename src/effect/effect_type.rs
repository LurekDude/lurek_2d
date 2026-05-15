//! - Post-processing effect type enumeration and name registry.
//! - Canonical lowercase name mapping for Lua-facing effect lookup.
//! - Debug label generation for renderer diagnostics.
//! - Default parameter tables for each built-in effect.
//! - Built-in effect catalog excluding the custom shader pass.

use std::collections::HashMap;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
/// Enumerates the built-in post-processing effect implementations.
pub enum PostFxEffectType {
    /// Bright-pass glow accumulation.
    Bloom,
    /// General-purpose image blurring.
    Blur,
    /// CRT-style curvature and scan artifact treatment.
    Crt,
    /// Radial light shaft rendering.
    Godrays,
    /// Edge darkening around the viewport.
    Vignette,
    /// Brightness, contrast, and saturation grading.
    ColourGrade,
    /// Chromatic aberration channel offsets.
    Chromatic,
    /// Block-based pixelation.
    Pixelate,
    /// Brown-tinted sepia toning.
    Sepia,
    /// Monochrome luminance conversion.
    Grayscale,
    /// Channel inversion.
    Invert,
    /// Horizontal scanline overlay.
    Scanlines,
    /// Edge detection filter.
    EdgeDetect,
    /// Hue rotation in color space.
    HueShift,
    /// Procedural noise overlay.
    Noise,
    /// Renderer-provided custom shader pass.
    Custom,
    /// Focus-based blur around a focal point.
    DepthOfField,
    /// Multi-sample motion blur.
    MotionBlur,
    /// Palette remapping blend.
    PaletteSwap,
    /// Color lookup-table grading.
    ColorLut,
    /// Water-like screen distortion.
    WaterDistort,
    /// Image sharpening filter.
    Sharpen,
    /// Ordered dithering quantization.
    Dither,
    /// Outline extraction and compositing.
    Outline,
}
/// Name resolution, parameter defaults, and debug utilities for effect types.
impl PostFxEffectType {
    /// Bidirectional mapping from effect variant to its canonical lowercase string.
    const NAME_MAP: &'static [(Self, &'static str)] = &[
        (Self::Bloom, "bloom"),
        (Self::Blur, "blur"),
        (Self::Crt, "crt"),
        (Self::Godrays, "godrays"),
        (Self::Vignette, "vignette"),
        (Self::ColourGrade, "colourgrade"),
        (Self::Chromatic, "chromatic"),
        (Self::Pixelate, "pixelate"),
        (Self::Sepia, "sepia"),
        (Self::Grayscale, "grayscale"),
        (Self::Invert, "invert"),
        (Self::Scanlines, "scanlines"),
        (Self::EdgeDetect, "edgedetect"),
        (Self::HueShift, "hueshift"),
        (Self::Noise, "noise"),
        (Self::Custom, "custom"),
        (Self::DepthOfField, "depthoffield"),
        (Self::MotionBlur, "motionblur"),
        (Self::PaletteSwap, "paletteswap"),
        (Self::ColorLut, "colorlut"),
        (Self::WaterDistort, "waterdistort"),
        (Self::Sharpen, "sharpen"),
        (Self::Dither, "dither"),
        (Self::Outline, "outline"),
    ];
    /// Ordered list of all non-custom built-in effect types.
    const BUILT_IN_TYPES: &'static [Self] = &[
        Self::Bloom,
        Self::Blur,
        Self::Crt,
        Self::Godrays,
        Self::Vignette,
        Self::ColourGrade,
        Self::Chromatic,
        Self::Pixelate,
        Self::Sepia,
        Self::Grayscale,
        Self::Invert,
        Self::Scanlines,
        Self::EdgeDetect,
        Self::HueShift,
        Self::Noise,
        Self::DepthOfField,
        Self::MotionBlur,
        Self::PaletteSwap,
        Self::ColorLut,
        Self::WaterDistort,
        Self::Sharpen,
        Self::Dither,
        Self::Outline,
    ];
    /// Resolves a lowercase built-in effect name into the matching enum entry.
    pub fn from_name(name: &str) -> Option<Self> {
        Self::BUILT_IN_TYPES
            .iter()
            .copied()
            .find(|effect_type| effect_type.name() == name)
    }
    /// Returns the lowercase names for all non-custom built-in effect types.
    pub fn built_in_names() -> Vec<&'static str> {
        Self::BUILT_IN_TYPES
            .iter()
            .map(|effect_type| effect_type.name())
            .collect()
    }
    /// Returns the lowercase canonical name for this effect type.
    pub fn name(&self) -> &'static str {
        Self::NAME_MAP
            .iter()
            .find(|(effect_type, _)| effect_type == self)
            .map(|(_, name)| *name)
            .expect("PostFxEffectType::NAME_MAP must include every enum variant")
    }
    /// Returns the uppercase debug label used in renderer diagnostics.
    pub fn debug_label(&self) -> &'static str {
        match self {
            Self::Vignette => "VIGNETTE",
            Self::Grayscale => "GRAYSCALE",
            Self::Chromatic => "CHROMATIC",
            Self::Blur => "BLUR",
            Self::Pixelate => "PIXELATE",
            Self::Invert => "INVERT",
            Self::Sepia => "SEPIA",
            Self::Scanlines => "SCANLINES",
            Self::Bloom => "BLOOM",
            Self::Crt => "CRT",
            Self::Godrays => "GODRAYS",
            Self::ColourGrade => "COLOUR_GRADE",
            Self::EdgeDetect => "EDGE_DETECT",
            Self::HueShift => "HUE_SHIFT",
            Self::Noise => "NOISE",
            Self::Custom => "CUSTOM",
            Self::DepthOfField => "DEPTH_OF_FIELD",
            Self::MotionBlur => "MOTION_BLUR",
            Self::PaletteSwap => "PALETTE_SWAP",
            Self::ColorLut => "COLOR_LUT",
            Self::WaterDistort => "WATER_DISTORT",
            Self::Sharpen => "SHARPEN",
            Self::Dither => "DITHER",
            Self::Outline => "OUTLINE",
        }
    }
    /// Returns the default scalar parameter map for this effect type.
    pub fn default_params(&self) -> HashMap<String, f32> {
        let mut m = HashMap::new();
        match self {
            Self::Bloom => {
                m.insert("threshold".into(), 0.7);
                m.insert("intensity".into(), 1.0);
            }
            Self::Blur => {
                m.insert("radius".into(), 2.0);
                m.insert("strength".into(), 1.0);
            }
            Self::Crt => {
                m.insert("scanline_strength".into(), 0.3);
            }
            Self::Godrays => {
                m.insert("intensity".into(), 1.0);
            }
            Self::Vignette => {
                m.insert("strength".into(), 0.5);
            }
            Self::ColourGrade => {
                m.insert("brightness".into(), 1.0);
                m.insert("contrast".into(), 1.0);
                m.insert("saturation".into(), 1.0);
            }
            Self::Chromatic => {
                m.insert("offset".into(), 2.0);
            }
            Self::Pixelate => {
                m.insert("block_size".into(), 4.0);
            }
            Self::Sepia => {
                m.insert("strength".into(), 1.0);
            }
            Self::Grayscale => {
                m.insert("strength".into(), 1.0);
            }
            Self::Invert => {
                m.insert("strength".into(), 1.0);
            }
            Self::Scanlines => {
                m.insert("strength".into(), 0.5);
                m.insert("spacing".into(), 4.0);
            }
            Self::EdgeDetect => {
                m.insert("strength".into(), 1.0);
            }
            Self::HueShift => {
                m.insert("angle".into(), 0.0);
            }
            Self::Noise => {
                m.insert("strength".into(), 0.1);
            }
            Self::Custom => {}
            Self::DepthOfField => {
                m.insert("focus_x".into(), 0.5);
                m.insert("focus_y".into(), 0.5);
                m.insert("strength".into(), 0.8);
                m.insert("radius".into(), 8.0);
            }
            Self::MotionBlur => {
                m.insert("strength".into(), 0.4);
                m.insert("samples".into(), 8.0);
            }
            Self::PaletteSwap => {
                m.insert("mix".into(), 1.0);
            }
            Self::ColorLut => {
                m.insert("strength".into(), 1.0);
            }
            Self::WaterDistort => {
                m.insert("amplitude".into(), 0.005);
                m.insert("frequency".into(), 15.0);
                m.insert("speed".into(), 2.0);
            }
            Self::Sharpen => {
                m.insert("strength".into(), 0.5);
            }
            Self::Dither => {
                m.insert("palette_size".into(), 8.0);
                m.insert("matrix_size".into(), 4.0);
            }
            Self::Outline => {
                m.insert("color_r".into(), 0.0);
                m.insert("color_g".into(), 0.0);
                m.insert("color_b".into(), 0.0);
                m.insert("thickness".into(), 1.0);
            }
        }
        m
    }
}
