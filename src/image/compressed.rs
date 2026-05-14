use crate::runtime::EngineError;
/// Compressed texture format recognized from DDS metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CompressedFormat {
    /// BC1 / DXT1 compressed texture.
    Dxt1,
    /// BC2 / DXT3 compressed texture.
    Dxt3,
    /// BC3 / DXT5 compressed texture.
    Dxt5,
    /// BC7 compressed texture.
    Bc7,
    /// ETC1 compressed texture.
    Etc1,
    /// ETC2 RGB compressed texture.
    Etc2Rgb,
    /// ETC2 RGBA compressed texture.
    Etc2Rgba,
    /// Format not recognized from DDS metadata.
    Unknown,
}
impl CompressedFormat {
    /// Return the lowercase format label string for this variant.
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
/// DDS image data with decoded mipmap payloads and detected format.
#[derive(Debug, Clone)]
pub struct CompressedImageData {
    /// Detected compressed format.
    pub format: CompressedFormat,
    /// Base image width in pixels.
    pub width: u32,
    /// Base image height in pixels.
    pub height: u32,
    /// Raw mipmap payloads from the DDS file.
    pub mipmaps: Vec<Vec<u8>>,
}
impl CompressedImageData {
    /// Decode DDS bytes into compressed image data or return a file-system error.
    pub fn from_dds(bytes: &[u8]) -> Result<Self, EngineError> {
        let dds = ddsfile::Dds::read(std::io::Cursor::new(bytes))
            .map_err(|e| EngineError::FileSystemError(format!("DDS parse error: {e}")))?;
        let format = detect_format(&dds);
        let width = dds.get_width();
        let height = dds.get_height();
        let mip_count = dds.get_num_mipmap_levels().max(1);
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
    /// Return the base image dimensions.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Return the number of mipmap levels stored in this image.
    pub fn get_mipmap_count(&self) -> u32 {
        self.mipmaps.len() as u32
    }
    /// Return the detected compressed format string.
    pub fn get_format(&self) -> &str {
        self.format.as_str()
    }
    /// Return whether the byte slice starts with the DDS magic header.
    pub fn is_dds_magic(bytes: &[u8]) -> bool {
        bytes.len() >= 4 && bytes[..4] == [0x44, 0x44, 0x53, 0x20]
    }
    /// Read a DDS file from disk and decode it into compressed image data.
    pub fn from_file(path: &str) -> Result<Self, EngineError> {
        let bytes = std::fs::read(path)
            .map_err(|e| EngineError::FileSystemError(format!("Cannot read '{}': {}", path, e)))?;
        Self::from_dds(&bytes)
    }
    /// Return whether a file on disk starts with the DDS magic header.
    pub fn is_dds_file(path: &str) -> bool {
        let Ok(mut f) = std::fs::File::open(path) else {
            return false;
        };
        let mut magic = [0u8; 4];
        use std::io::Read;
        f.read_exact(&mut magic).is_ok() && Self::is_dds_magic(&magic)
    }
}
/// Detect a compressed format from DDS metadata or return `Unknown`.
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
