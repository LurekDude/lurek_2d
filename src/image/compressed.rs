//! Compressed GPU texture data from DDS/DXT files.
//!
//! Provides [`CompressedImageData`] for loading DXT1/DXT3/DXT5/BC7 textures
//! from DDS files without CPU-side decompression.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::engine::EngineError;

/// GPU-compressed texture format identifier.
///
/// # Variants
/// - `Dxt1` — Dxt1 variant.
/// - `Dxt3` — Dxt3 variant.
/// - `Dxt5` — Dxt5 variant.
/// - `Bc7` — Bc7 variant.
/// - `Etc1` — Etc1 variant.
/// - `Etc2Rgb` — Etc2Rgb variant.
/// - `Etc2Rgba` — Etc2Rgba variant.
/// - `Unknown` — Unknown or unsupported format.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CompressedFormat {
    Dxt1,
    Dxt3,
    Dxt5,
    Bc7,
    Etc1,
    Etc2Rgb,
    Etc2Rgba,
    Unknown,
}

impl CompressedFormat {
    /// Return the Lua-facing format name string.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            CompressedFormat::Dxt1 => "dxt1",
            CompressedFormat::Dxt3 => "dxt3",
            CompressedFormat::Dxt5 => "dxt5",
            CompressedFormat::Bc7 => "bc7",
            CompressedFormat::Etc1 => "etc1",
            CompressedFormat::Etc2Rgb => "etc2_rgb",
            CompressedFormat::Etc2Rgba => "etc2_rgba",
            CompressedFormat::Unknown => "unknown",
        }
    }
}

/// CPU-side holder for GPU-compressed texture data loaded from a DDS file.
///
/// Does NOT decompress pixels — the raw compressed bytes are for direct GPU upload.
/// The `mipmaps` vector holds the raw data for the base level (index 0) and any
/// additional mip levels. Upper mip levels beyond level 0 are stored as empty
/// slices in this lightweight holder.
///
/// # Fields
/// - `format` — `CompressedFormat`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `mipmaps` — `Vec<Vec<u8>>`.
#[derive(Debug, Clone)]
pub struct CompressedImageData {
    /// Detected compressed format.
    pub format: CompressedFormat,
    /// Width in pixels of the base mip level.
    pub width: u32,
    /// Height in pixels of the base mip level.
    pub height: u32,
    /// Raw compressed bytes per mip level (index 0 = base level).
    pub mipmaps: Vec<Vec<u8>>,
}

impl CompressedImageData {
    /// Load compressed texture data from DDS file bytes.
    ///
    /// Returns `Unknown` format rather than failing when the format is unrecognised.
    ///
    /// # Parameters
    /// - `bytes` — `&[u8]`.
    ///
    /// # Returns
    /// `Result<Self, EngineError>`.
    pub fn from_dds(bytes: &[u8]) -> Result<Self, EngineError> {
        let dds = ddsfile::Dds::read(std::io::Cursor::new(bytes))
            .map_err(|e| EngineError::FileSystemError(format!("DDS parse error: {e}")))?;

        let format = detect_format(&dds);
        let width = dds.get_width();
        let height = dds.get_height();
        let mip_count = dds.get_num_mipmap_levels().max(1);

        // Collect the base-level raw data. ddsfile stores all mip levels in one
        // flat `data` field; we store mip 0 as the full slice and placeholder
        // empty vecs for higher levels so mip count queries are accurate.
        let base_data = dds
            .get_data(0)
            .map_err(|e| EngineError::FileSystemError(format!("DDS data error: {e}")))?
            .to_vec();

        let mut mipmaps = Vec::with_capacity(mip_count as usize);
        mipmaps.push(base_data);
        for _ in 1..mip_count {
            mipmaps.push(vec![]);
        }

        Ok(Self {
            format,
            width,
            height,
            mipmaps,
        })
    }

    /// Return image dimensions as `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Return the number of mipmap levels stored.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_mipmap_count(&self) -> u32 {
        self.mipmaps.len() as u32
    }

    /// Return the Lua-facing format name string.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_format(&self) -> &str {
        self.format.as_str()
    }
}

/// Detect the compressed format from a parsed DDS file.
///
/// # Parameters
/// - `dds` — `&ddsfile::Dds`.
///
/// # Returns
/// `CompressedFormat`.
fn detect_format(dds: &ddsfile::Dds) -> CompressedFormat {
    if let Some(dxgi) = dds.get_dxgi_format() {
        use ddsfile::DxgiFormat;
        return match dxgi {
            DxgiFormat::BC1_UNorm | DxgiFormat::BC1_UNorm_sRGB => CompressedFormat::Dxt1,
            DxgiFormat::BC2_UNorm | DxgiFormat::BC2_UNorm_sRGB => CompressedFormat::Dxt3,
            DxgiFormat::BC3_UNorm | DxgiFormat::BC3_UNorm_sRGB => CompressedFormat::Dxt5,
            DxgiFormat::BC7_UNorm | DxgiFormat::BC7_UNorm_sRGB => CompressedFormat::Bc7,
            _ => CompressedFormat::Unknown,
        };
    }
    if let Some(d3d) = dds.get_d3d_format() {
        use ddsfile::D3DFormat;
        return match d3d {
            D3DFormat::DXT1 => CompressedFormat::Dxt1,
            D3DFormat::DXT3 => CompressedFormat::Dxt3,
            D3DFormat::DXT5 => CompressedFormat::Dxt5,
            _ => CompressedFormat::Unknown,
        };
    }
    CompressedFormat::Unknown
}
