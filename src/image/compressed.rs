use crate::runtime::EngineError;
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
#[derive(Debug, Clone)]
pub struct CompressedImageData {
    pub format: CompressedFormat,
    pub width: u32,
    pub height: u32,
    pub mipmaps: Vec<Vec<u8>>,
}
impl CompressedImageData {
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
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn get_mipmap_count(&self) -> u32 {
        self.mipmaps.len() as u32
    }
    pub fn get_format(&self) -> &str {
        self.format.as_str()
    }
    pub fn is_dds_magic(bytes: &[u8]) -> bool {
        bytes.len() >= 4 && bytes[..4] == [0x44, 0x44, 0x53, 0x20]
    }
    pub fn from_file(path: &str) -> Result<Self, EngineError> {
        let bytes = std::fs::read(path)
            .map_err(|e| EngineError::FileSystemError(format!("Cannot read '{}': {}", path, e)))?;
        Self::from_dds(&bytes)
    }
    pub fn is_dds_file(path: &str) -> bool {
        let Ok(mut f) = std::fs::File::open(path) else {
            return false;
        };
        let mut magic = [0u8; 4];
        use std::io::Read;
        f.read_exact(&mut magic).is_ok() && Self::is_dds_magic(&magic)
    }
}
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
