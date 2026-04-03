use std::collections::HashMap;

/// Built-in effect types for the post-processing pipeline.
///
/// Each variant maps to a distinct full-screen shader pass implemented in
/// `lua_api`. The `Custom` variant defers to an external shader ID supplied
/// via `PostFxEffect::new_custom`. Use `PostFxEffectType::from_name` to
/// parse effect names from Lua strings, and `PostFxEffect::default_params`
/// to retrieve the canonical starting parameters for each type.
///
/// # Variants
/// - `Bloom` — HDR bloom with threshold and intensity parameters.
/// - `Blur` — Gaussian blur with configurable radius and strength.
/// - `Crt` — CRT monitor simulation with scanline strength.
/// - `Godrays` — Light ray / god ray screen-space effect with intensity.
/// - `Vignette` — Screen edge darkening with configurable strength.
/// - `ColourGrade` — Colour grading with brightness, contrast, and saturation.
/// - `Chromatic` — Chromatic aberration with pixel offset.
/// - `Pixelate` — Block pixelation effect with configurable block size.
/// - `Sepia` — Warm sepia tone mapping with configurable strength.
/// - `Grayscale` — Desaturate to greyscale with configurable strength.
/// - `Invert` — Colour inversion with configurable strength.
/// - `Scanlines` — Horizontal scanline bars (CRT-free) with strength and spacing.
/// - `EdgeDetect` — Sobel edge detection outline with configurable strength.
/// - `HueShift` — Hue rotation in degrees.
/// - `Noise` — Random per-pixel noise with configurable strength.
/// - `Custom` — User-provided shader pass created via `newPass()`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PostFxEffectType {
    /// HDR bloom with threshold + intensity parameters.
    Bloom,
    /// Gaussian blur with radius parameter.
    Blur,
    /// CRT monitor simulation with scanline strength.
    Crt,
    /// Light ray / god ray effect with intensity.
    Godrays,
    /// Screen edge darkening with strength.
    Vignette,
    /// Colour grading / tone mapping.
    ColourGrade,
    /// Chromatic aberration with offset.
    Chromatic,
    /// Block pixelation effect.
    Pixelate,
    /// Warm sepia tone mapping.
    Sepia,
    /// Desaturate to greyscale.
    Grayscale,
    /// Colour inversion.
    Invert,
    /// Horizontal scanline bars (CRT-free).
    Scanlines,
    /// Sobel edge detection outline.
    EdgeDetect,
    /// Hue rotation in degrees.
    HueShift,
    /// Random per-pixel noise.
    Noise,
    /// Custom shader pass (created via `newPass()`).
    Custom,
}

impl PostFxEffectType {
    /// Parses a string name into an effect type.
    ///
    /// # Parameters
    /// - `name` — `&str` — One of the built-in effect names.
    ///
    /// # Returns
    /// `Option<Self>` — `None` if the name is unrecognised.
    pub fn from_name(name: &str) -> Option<Self> {
        match name {
            "bloom" => Some(Self::Bloom),
            "blur" => Some(Self::Blur),
            "crt" => Some(Self::Crt),
            "godrays" => Some(Self::Godrays),
            "vignette" => Some(Self::Vignette),
            "colourgrade" => Some(Self::ColourGrade),
            "chromatic" => Some(Self::Chromatic),
            "pixelate" => Some(Self::Pixelate),
            "sepia" => Some(Self::Sepia),
            "grayscale" => Some(Self::Grayscale),
            "invert" => Some(Self::Invert),
            "scanlines" => Some(Self::Scanlines),
            "edgedetect" => Some(Self::EdgeDetect),
            "hueshift" => Some(Self::HueShift),
            "noise" => Some(Self::Noise),
            _ => None,
        }
    }

    /// Returns the string name of this effect type.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn name(&self) -> &'static str {
        match self {
            Self::Bloom => "bloom",
            Self::Blur => "blur",
            Self::Crt => "crt",
            Self::Godrays => "godrays",
            Self::Vignette => "vignette",
            Self::ColourGrade => "colourgrade",
            Self::Chromatic => "chromatic",
            Self::Pixelate => "pixelate",
            Self::Sepia => "sepia",
            Self::Grayscale => "grayscale",
            Self::Invert => "invert",
            Self::Scanlines => "scanlines",
            Self::EdgeDetect => "edgedetect",
            Self::HueShift => "hueshift",
            Self::Noise => "noise",
            Self::Custom => "custom",
        }
    }

    /// Returns the default parameters for this built-in effect type.
    ///
    /// Each built-in effect ships with carefully chosen defaults that look
    /// reasonable out of the box: bloom at 0.7 threshold / 1.0 intensity;
    /// blur at radius 2.0 / strength 1.0; CRT scanlines at 0.3; godrays at
    /// intensity 1.0; vignette at strength 0.5; colour grading at neutral
    /// 1.0 / 1.0 / 1.0; chromatic aberration at offset 2.0. Returns an
    /// empty map for `Custom` effects since custom shaders define their own
    /// uniform interfaces.
    ///
    /// # Returns
    /// `HashMap<String, f32>` — Canonical default parameters for this effect.
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
        }
        m
    }
}
