//! Data compression and decompression using deflate, gzip, zlib, and LZ4.
//!
//! This module is part of Luna2D's `data` subsystem and provides the implementation
//! details for compress-related operations and data management.
//! Key types exported from this module: `CompressFormat`.
//! Primary functions: `parse_str()`, `compress()`, `decompress()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::io::{Read, Write};

/// Supported compression formats. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Deflate` — Deflate variant.
/// - `Gzip` — Gzip variant.
/// - `Lz4` — Lz4 variant.
/// - `Zlib` — Zlib variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CompressFormat {
    /// Raw deflate.
    Deflate,
    /// Gzip container.
    Gzip,
    /// LZ4 block compression.
    Lz4,
    /// Zlib container.
    Zlib,
}

impl CompressFormat {
    /// Parse a format name string. Returns an error if the source data is malformed or missing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn parse_str(s: &str) -> Result<Self, String> {
        match s.to_lowercase().as_str() {
            "deflate" => Ok(CompressFormat::Deflate),
            "gzip" | "gz" => Ok(CompressFormat::Gzip),
            "lz4" => Ok(CompressFormat::Lz4),
            "zlib" => Ok(CompressFormat::Zlib),
            _ => Err(format!(
                "Unknown compression format: '{}'. Use 'deflate', 'gzip', 'lz4', or 'zlib'.",
                s
            )),
        }
    }
}

/// Compress data using the specified format and compression level (0-9).
///
/// # Parameters
/// - `data` — `&[u8]`.
/// - `format` — `CompressFormat`.
/// - `level` — `u32`.
///
/// # Returns
/// `Result<Vec<u8>, String>`.
pub fn compress(data: &[u8], format: CompressFormat, level: u32) -> Result<Vec<u8>, String> {
    let level = level.min(9);
    let compression = flate2::Compression::new(level);

    match format {
        CompressFormat::Deflate => {
            let mut encoder = flate2::write::DeflateEncoder::new(Vec::new(), compression);
            encoder
                .write_all(data)
                .map_err(|e| format!("Deflate compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Deflate finish error: {}", e))
        }
        CompressFormat::Gzip => {
            let mut encoder = flate2::write::GzEncoder::new(Vec::new(), compression);
            encoder
                .write_all(data)
                .map_err(|e| format!("Gzip compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Gzip finish error: {}", e))
        }
        CompressFormat::Zlib => {
            let mut encoder = flate2::write::ZlibEncoder::new(Vec::new(), compression);
            encoder
                .write_all(data)
                .map_err(|e| format!("Zlib compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Zlib finish error: {}", e))
        }
        CompressFormat::Lz4 => Ok(lz4_flex::compress_prepend_size(data)),
    }
}

/// Decompress data using the specified format.
///
/// # Parameters
/// - `data` — `&[u8]`.
/// - `format` — `CompressFormat`.
///
/// # Returns
/// `Result<Vec<u8>, String>`.
pub fn decompress(data: &[u8], format: CompressFormat) -> Result<Vec<u8>, String> {
    match format {
        CompressFormat::Deflate => {
            let mut decoder = flate2::read::DeflateDecoder::new(data);
            let mut output = Vec::new();
            decoder
                .read_to_end(&mut output)
                .map_err(|e| format!("Deflate decompress error: {}", e))?;
            Ok(output)
        }
        CompressFormat::Gzip => {
            let mut decoder = flate2::read::GzDecoder::new(data);
            let mut output = Vec::new();
            decoder
                .read_to_end(&mut output)
                .map_err(|e| format!("Gzip decompress error: {}", e))?;
            Ok(output)
        }
        CompressFormat::Zlib => {
            let mut decoder = flate2::read::ZlibDecoder::new(data);
            let mut output = Vec::new();
            decoder
                .read_to_end(&mut output)
                .map_err(|e| format!("Zlib decompress error: {}", e))?;
            Ok(output)
        }
        CompressFormat::Lz4 => lz4_flex::decompress_size_prepended(data)
            .map_err(|e| format!("LZ4 decompress error: {}", e)),
    }
}
