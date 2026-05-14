
use crate::log_msg;
use crate::render::renderer::TextureData;
use crate::runtime::error::{EngineError, EngineResult};
use crate::runtime::log_messages::TX01_TEX_DECODED;
use crate::runtime::resource_keys::TextureKey;
use slotmap::SlotMap;
use std::path::Path;
/// Texture color space stored alongside decoded pixels.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TextureColorSpace {
    /// Standard sRGB texture data.
    Srgb,
    /// Linear texture data.
    Linear,
}
/// CPU-side texture handle and its uploaded dimensions.
pub struct Texture {
    /// Slot-map key for the backing texture data.
    pub key: TextureKey,
    /// Texture width in pixels.
    pub width: u32,
    /// Texture height in pixels.
    pub height: u32,
}
/// Premultiply RGB channels by alpha for each RGBA pixel in place.
pub fn premultiply_alpha_rgba8_in_place(pixels: &mut [u8]) {
    for chunk in pixels.chunks_exact_mut(4) {
        let a = chunk[3] as f32 / 255.0;
        chunk[0] = (chunk[0] as f32 * a) as u8;
        chunk[1] = (chunk[1] as f32 * a) as u8;
        chunk[2] = (chunk[2] as f32 * a) as u8;
    }
}
impl Texture {
    /// Parse a texture color-space label and return the matching enum value.
    pub fn parse_color_space(value: &str) -> Option<TextureColorSpace> {
        match value.to_ascii_lowercase().as_str() {
            "srgb" => Some(TextureColorSpace::Srgb),
            "linear" => Some(TextureColorSpace::Linear),
            _ => None,
        }
    }
    /// Load a texture with sRGB color space by default.
    pub fn load<P: AsRef<Path>>(
        path: P,
        textures: &mut SlotMap<TextureKey, TextureData>,
    ) -> EngineResult<Self> {
        Self::load_with_color_space(path, textures, TextureColorSpace::Srgb)
    }
    /// Load a texture from disk, premultiply alpha, and store it in the texture pool.
    pub fn load_with_color_space<P: AsRef<Path>>(
        path: P,
        textures: &mut SlotMap<TextureKey, TextureData>,
        color_space: TextureColorSpace,
    ) -> EngineResult<Self> {
        let img = ::image::open(&path).map_err(|e| {
            let path_str = path.as_ref().display().to_string();
            if path_str.contains("No such file") || matches!(e, ::image::ImageError::IoError(_)) {
                EngineError::ResourceNotFound(format!("{}: {}", path_str, e))
            } else {
                EngineError::RenderError(format!("Failed to decode image '{}': {}", path_str, e))
            }
        })?;
        let rgba = img.to_rgba8();
        let (width, height) = rgba.dimensions();
        let mut pixels = rgba.into_raw();
        premultiply_alpha_rgba8_in_place(&mut pixels);
        let key = textures.insert(TextureData {
            pixels,
            width,
            height,
            color_space,
        });
        log_msg!(debug, TX01_TEX_DECODED, "{}x{}", width, height);
        Ok(Texture { key, width, height })
    }
    /// Create a texture from RGBA bytes using sRGB color space.
    pub fn from_rgba(
        width: u32,
        height: u32,
        pixels: Vec<u8>,
        textures: &mut SlotMap<TextureKey, TextureData>,
    ) -> EngineResult<Self> {
        Self::from_rgba_with_color_space(width, height, pixels, textures, TextureColorSpace::Srgb)
    }
    /// Create a texture from RGBA bytes and store it in the texture pool.
    pub fn from_rgba_with_color_space(
        width: u32,
        height: u32,
        mut pixels: Vec<u8>,
        textures: &mut SlotMap<TextureKey, TextureData>,
        color_space: TextureColorSpace,
    ) -> EngineResult<Self> {
        let expected = (width * height * 4) as usize;
        if pixels.len() != expected {
            return Err(EngineError::RenderError(format!(
                "Expected {} bytes for {}x{} RGBA, got {}",
                expected,
                width,
                height,
                pixels.len()
            )));
        }
        premultiply_alpha_rgba8_in_place(&mut pixels);
        let key = textures.insert(TextureData {
            pixels,
            width,
            height,
            color_space,
        });
        Ok(Texture { key, width, height })
    }
}
