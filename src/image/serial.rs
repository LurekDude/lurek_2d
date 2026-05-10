//! Binary serialization for [`ImageData`] and [`LayeredImage`] using the `.lim` format.
//!
//! # LIMG Format
//!
//! Lurek Image (LIMG) is a compact, self-describing binary format for both flat
//! RGBA8 images and multi-layer compositing stacks.  Pixel data is compressed
//! with zlib (deflate) using the [`flate2`] crate.
//!
//! ## File layout
//!
//! | Offset | Size | Description |
//! |--------|------|-------------|
//! | 0      | 4    | Magic: `LIMG` (ASCII) |
//! | 4      | 1    | Version: `1` |
//! | 5      | 1    | Type: `0` = flat image, `1` = layered image |
//! | 6      | …    | Payload (varies by type) |
//!
//! ### Flat image payload (type=0)
//!
//! | Field  | Size | Description |
//! |--------|------|-------------|
//! | width  | 4    | `u32` little-endian |
//! | height | 4    | `u32` little-endian |
//! | pixels | rest | zlib-compressed RGBA8 bytes |
//!
//! ### Layered image payload (type=1)
//!
//! | Field        | Size | Description |
//! |--------------|------|-------------|
//! | canvas_w     | 4    | `u32` little-endian |
//! | canvas_h     | 4    | `u32` little-endian |
//! | layer_count  | 4    | `u32` little-endian |
//! | per-layer… | —    | see below |
//!
//! #### Per-layer record
//!
//! | Field     | Size           | Description |
//! |-----------|----------------|-------------|
//! | name_len  | 2              | `u16` little-endian byte length of UTF-8 name |
//! | name      | name_len       | UTF-8 bytes (no NUL terminator) |
//! | opacity   | 4              | `f32` little-endian |
//! | visible   | 1              | `0` = hidden, `1` = visible |
//! | pixels    | rest of record | zlib-compressed RGBA8 bytes |
//!
//! The compressed pixel block for each layer is prefixed with a 4-byte
//! `u32` (little-endian) giving the **compressed byte count** so the reader
//! can extract each record without seeking.
//!
//! All public items are documented.  See the parent module for architectural
//! context.

use std::io::{Read, Write};

use flate2::read::ZlibDecoder;
use flate2::write::ZlibEncoder;
use flate2::Compression;

use super::image_data::ImageData;
use super::layers::LayeredImage;

// -------------------------------------------------------------------------------
// Constants
// -------------------------------------------------------------------------------

/// Magic bytes that identify a LIMG file.
const MAGIC: &[u8; 4] = b"LIMG";
/// Current format version.
const VERSION: u8 = 1;
/// Type flag for a flat [`ImageData`] payload.
const TYPE_FLAT: u8 = 0;
/// Type flag for a [`LayeredImage`] payload.
const TYPE_LAYERED: u8 = 1;

// -------------------------------------------------------------------------------
// Public helpers
// -------------------------------------------------------------------------------

/// Save a flat [`ImageData`] to a LIMG binary file at the given path.
///
/// Pixel data is compressed with zlib deflate at the default compression level.
/// The output file is created or truncated.  Parent directories must exist.
///
/// # Parameters
/// - `img`  — `&ImageData`. Source pixel buffer.
/// - `path` — `&str`.       Destination file path (e.g. `"output.lim"`).
///
/// # Returns
/// `Result<(), String>` — `Err` contains a human-readable message on failure.
pub fn save_image(img: &ImageData, path: &str) -> Result<(), String> {
    let data = encode_flat(img)?;
    std::fs::write(path, &data).map_err(|e| format!("LIMG write error '{}': {}", path, e))
}

/// Load a flat [`ImageData`] from a LIMG binary file.
///
/// Returns an error if the file is not a valid LIMG file, the version is
/// unsupported, or the recorded type is not `0` (flat).
///
/// # Parameters
/// - `path` — `&str`. Source file path.
///
/// # Returns
/// `Result<ImageData, String>`.
pub fn load_image(path: &str) -> Result<ImageData, String> {
    let data = std::fs::read(path).map_err(|e| format!("LIMG read error '{}': {}", path, e))?;
    load_image_from_bytes(&data, path)
}

/// Load a flat [`ImageData`] from an in-memory LIMG byte buffer.
///
/// # Parameters
/// - `data` — Complete LIMG file bytes.
/// - `label` — Human-readable source label used in error messages.
///
/// # Returns
/// `Result<ImageData, String>`.
pub fn load_image_from_bytes(data: &[u8], label: &str) -> Result<ImageData, String> {
    let (type_flag, payload) = parse_header(data)?;
    if type_flag != TYPE_FLAT {
        return Err(format!(
            "LIMG '{}': expected flat image (type 0), got type {}",
            label, type_flag
        ));
    }
    decode_flat(payload)
}

/// Save a [`LayeredImage`] to a LIMG binary file at the given path.
///
/// Each layer's pixel data is individually compressed.  Layer order, opacity,
/// visibility, and names are all preserved.
///
/// # Parameters
/// - `stack` — `&LayeredImage`. Source layer stack.
/// - `path`  — `&str`.         Destination file path.
///
/// # Returns
/// `Result<(), String>`.
pub fn save_layered(stack: &LayeredImage, path: &str) -> Result<(), String> {
    let data = encode_layered(stack)?;
    std::fs::write(path, &data).map_err(|e| format!("LIMG write error '{}': {}", path, e))
}

/// Load a [`LayeredImage`] from a LIMG binary file.
///
/// Returns an error if the file is not a valid LIMG file, the version is
/// unsupported, or the recorded type is not `1` (layered).
///
/// # Parameters
/// - `path` — `&str`. Source file path.
///
/// # Returns
/// `Result<LayeredImage, String>`.
pub fn load_layered(path: &str) -> Result<LayeredImage, String> {
    let data = std::fs::read(path).map_err(|e| format!("LIMG read error '{}': {}", path, e))?;
    load_layered_from_bytes(&data, path)
}

/// Load a [`LayeredImage`] from an in-memory LIMG byte buffer.
///
/// # Parameters
/// - `data` — Complete LIMG file bytes.
/// - `label` — Human-readable source label used in error messages.
///
/// # Returns
/// `Result<LayeredImage, String>`.
pub fn load_layered_from_bytes(data: &[u8], label: &str) -> Result<LayeredImage, String> {
    let (type_flag, payload) = parse_header(data)?;
    if type_flag != TYPE_LAYERED {
        return Err(format!(
            "LIMG '{}': expected layered image (type 1), got type {}",
            label, type_flag
        ));
    }
    decode_layered(payload)
}

// -------------------------------------------------------------------------------
// Internal encoding helpers
// -------------------------------------------------------------------------------

/// Write the 6-byte LIMG header into a new `Vec<u8>`.
fn write_header(type_flag: u8) -> Vec<u8> {
    let mut buf = Vec::with_capacity(6);
    buf.extend_from_slice(MAGIC);
    buf.push(VERSION);
    buf.push(type_flag);
    buf
}

/// Compress raw bytes with zlib deflate (default level).
fn compress(raw: &[u8]) -> Result<Vec<u8>, String> {
    let mut enc = ZlibEncoder::new(Vec::new(), Compression::default());
    enc.write_all(raw)
        .map_err(|e| format!("zlib compress error: {}", e))?;
    enc.finish()
        .map_err(|e| format!("zlib finish error: {}", e))
}

/// Decompress zlib bytes.
fn decompress(compressed: &[u8]) -> Result<Vec<u8>, String> {
    let mut dec = ZlibDecoder::new(compressed);
    let mut out = Vec::new();
    dec.read_to_end(&mut out)
        .map_err(|e| format!("zlib decompress error: {}", e))?;
    Ok(out)
}

/// Push a `u16` in little-endian byte order.
fn push_u16(buf: &mut Vec<u8>, v: u16) {
    buf.extend_from_slice(&v.to_le_bytes());
}

/// Push a `u32` in little-endian byte order.
fn push_u32(buf: &mut Vec<u8>, v: u32) {
    buf.extend_from_slice(&v.to_le_bytes());
}

/// Push a `f32` in little-endian byte order.
fn push_f32(buf: &mut Vec<u8>, v: f32) {
    buf.extend_from_slice(&v.to_le_bytes());
}

/// Read a `u16` from a byte slice at the given offset.
fn read_u16(buf: &[u8], offset: usize) -> Result<u16, String> {
    buf.get(offset..offset + 2)
        .map(|b| u16::from_le_bytes([b[0], b[1]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected u16)", offset))
}

/// Read a `u32` from a byte slice at the given offset.
fn read_u32(buf: &[u8], offset: usize) -> Result<u32, String> {
    buf.get(offset..offset + 4)
        .map(|b| u32::from_le_bytes([b[0], b[1], b[2], b[3]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected u32)", offset))
}

/// Read a `f32` from a byte slice at the given offset.
fn read_f32(buf: &[u8], offset: usize) -> Result<f32, String> {
    buf.get(offset..offset + 4)
        .map(|b| f32::from_le_bytes([b[0], b[1], b[2], b[3]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected f32)", offset))
}

// -------------------------------------------------------------------------------
// Flat image encode / decode
// -------------------------------------------------------------------------------

/// Encode a flat [`ImageData`] into a complete LIMG binary blob.
pub fn encode_flat(img: &ImageData) -> Result<Vec<u8>, String> {
    let mut buf = write_header(TYPE_FLAT);
    push_u32(&mut buf, img.width);
    push_u32(&mut buf, img.height);
    let compressed = compress(&img.pixels)?;
    buf.extend_from_slice(&compressed);
    Ok(buf)
}

/// Decode the payload section of a flat LIMG blob.
pub fn decode_flat(payload: &[u8]) -> Result<ImageData, String> {
    if payload.len() < 8 {
        return Err("LIMG flat payload too short".into());
    }
    let width = read_u32(payload, 0)?;
    let height = read_u32(payload, 4)?;
    let pixels = decompress(&payload[8..])?;
    let expected = (width * height * 4) as usize;
    if pixels.len() != expected {
        return Err(format!(
            "LIMG flat: decompressed {} bytes, expected {} for {}x{}",
            pixels.len(),
            expected,
            width,
            height
        ));
    }
    ImageData::from_bytes(width, height, pixels).map_err(|e| format!("LIMG flat: {}", e))
}

// -------------------------------------------------------------------------------
// Layered image encode / decode
// -------------------------------------------------------------------------------

/// Encode a [`LayeredImage`] into a complete LIMG binary blob.
fn encode_layered(stack: &LayeredImage) -> Result<Vec<u8>, String> {
    let mut buf = write_header(TYPE_LAYERED);
    push_u32(&mut buf, stack.width);
    push_u32(&mut buf, stack.height);
    push_u32(&mut buf, stack.layers.len() as u32);

    for layer in &stack.layers {
        let name_bytes = layer.name.as_bytes();
        if name_bytes.len() > u16::MAX as usize {
            return Err(format!(
                "LIMG: layer name '{}' exceeds max 65535 bytes",
                layer.name
            ));
        }
        push_u16(&mut buf, name_bytes.len() as u16);
        buf.extend_from_slice(name_bytes);
        push_f32(&mut buf, layer.opacity);
        buf.push(if layer.visible { 1 } else { 0 });

        let compressed = compress(&layer.data.pixels)?;
        push_u32(&mut buf, compressed.len() as u32);
        buf.extend_from_slice(&compressed);
    }
    Ok(buf)
}

/// Decode the payload section of a layered LIMG blob.
fn decode_layered(payload: &[u8]) -> Result<LayeredImage, String> {
    if payload.len() < 12 {
        return Err("LIMG layered payload too short".into());
    }
    let canvas_w = read_u32(payload, 0)?;
    let canvas_h = read_u32(payload, 4)?;
    let layer_count = read_u32(payload, 8)? as usize;

    let mut stack = LayeredImage::new(canvas_w, canvas_h);
    let mut pos = 12usize;

    for i in 0..layer_count {
        // name
        let name_len = read_u16(payload, pos)? as usize;
        pos += 2;
        let name_end = pos + name_len;
        if name_end > payload.len() {
            return Err(format!("LIMG layered: layer {} name out of bounds", i));
        }
        let name = std::str::from_utf8(&payload[pos..name_end])
            .map_err(|e| format!("LIMG layered: layer {} name is invalid UTF-8: {}", i, e))?
            .to_string();
        pos = name_end;

        // opacity
        let opacity = read_f32(payload, pos)?;
        pos += 4;

        // visible
        if pos >= payload.len() {
            return Err(format!(
                "LIMG layered: layer {} visible flag out of bounds",
                i
            ));
        }
        let visible = payload[pos] != 0;
        pos += 1;

        // compressed pixel block length
        let comp_len = read_u32(payload, pos)? as usize;
        pos += 4;

        let comp_end = pos + comp_len;
        if comp_end > payload.len() {
            return Err(format!(
                "LIMG layered: layer {} pixel block out of bounds",
                i
            ));
        }
        let pixels = decompress(&payload[pos..comp_end])?;
        pos = comp_end;

        let expected = (canvas_w * canvas_h * 4) as usize;
        if pixels.len() != expected {
            return Err(format!(
                "LIMG layered: layer {} decompressed {} bytes, expected {}",
                i,
                pixels.len(),
                expected
            ));
        }
        let img = ImageData::from_bytes(canvas_w, canvas_h, pixels)
            .map_err(|e| format!("LIMG layered layer {}: {}", i, e))?;

        let idx = stack.add_layer(&name);
        if let Some(layer) = stack.get_layer_mut(idx) {
            layer.data = img;
            layer.opacity = opacity.clamp(0.0, 1.0);
            layer.visible = visible;
        }
    }

    Ok(stack)
}

// -------------------------------------------------------------------------------
// Header parsing
// -------------------------------------------------------------------------------

/// Validate the LIMG header and return `(type_flag, payload_slice)`.
pub fn parse_header(data: &[u8]) -> Result<(u8, &[u8]), String> {
    if data.len() < 6 {
        return Err("LIMG file too short to contain a valid header".into());
    }
    if &data[0..4] != MAGIC {
        return Err(format!("LIMG: invalid magic bytes (got {:?})", &data[0..4]));
    }
    let version = data[4];
    if version != VERSION {
        return Err(format!(
            "LIMG: unsupported version {} (only {} supported)",
            version, VERSION
        ));
    }
    let type_flag = data[5];
    Ok((type_flag, &data[6..]))
}
