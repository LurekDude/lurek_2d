
use super::image_data::ImageData;
use super::layers::LayeredImage;
use flate2::read::ZlibDecoder;
use flate2::write::ZlibEncoder;
use flate2::Compression;
use std::io::{Read, Write};
const MAGIC: &[u8; 4] = b"LIMG";
const VERSION: u8 = 1;
const TYPE_FLAT: u8 = 0;
const TYPE_LAYERED: u8 = 1;
/// Save a flat image as LIMG bytes on disk.
pub fn save_image(img: &ImageData, path: &str) -> Result<(), String> {
    let data = encode_flat(img)?;
    std::fs::write(path, &data).map_err(|e| format!("LIMG write error '{}': {}", path, e))
}
/// Load a flat image from disk and decode it from LIMG bytes.
pub fn load_image(path: &str) -> Result<ImageData, String> {
    let data = std::fs::read(path).map_err(|e| format!("LIMG read error '{}': {}", path, e))?;
    load_image_from_bytes(&data, path)
}
/// Load a flat image from raw LIMG bytes and validate the type flag.
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
/// Save a layered image as LIMG bytes on disk.
pub fn save_layered(stack: &LayeredImage, path: &str) -> Result<(), String> {
    let data = encode_layered(stack)?;
    std::fs::write(path, &data).map_err(|e| format!("LIMG write error '{}': {}", path, e))
}
/// Load a layered image from disk and decode it from LIMG bytes.
pub fn load_layered(path: &str) -> Result<LayeredImage, String> {
    let data = std::fs::read(path).map_err(|e| format!("LIMG read error '{}': {}", path, e))?;
    load_layered_from_bytes(&data, path)
}
/// Load a layered image from raw LIMG bytes and validate the type flag.
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
/// Build a LIMG header for the requested payload type.
fn write_header(type_flag: u8) -> Vec<u8> {
    let mut buf = Vec::with_capacity(6);
    buf.extend_from_slice(MAGIC);
    buf.push(VERSION);
    buf.push(type_flag);
    buf
}
/// Compress raw bytes with zlib and return the encoded payload.
fn compress(raw: &[u8]) -> Result<Vec<u8>, String> {
    let mut enc = ZlibEncoder::new(Vec::new(), Compression::default());
    enc.write_all(raw)
        .map_err(|e| format!("zlib compress error: {}", e))?;
    enc.finish()
        .map_err(|e| format!("zlib finish error: {}", e))
}
/// Decompress zlib-compressed bytes and return the raw payload.
fn decompress(compressed: &[u8]) -> Result<Vec<u8>, String> {
    let mut dec = ZlibDecoder::new(compressed);
    let mut out = Vec::new();
    dec.read_to_end(&mut out)
        .map_err(|e| format!("zlib decompress error: {}", e))?;
    Ok(out)
}
/// Append a little-endian `u16` to a byte buffer.
fn push_u16(buf: &mut Vec<u8>, v: u16) {
    buf.extend_from_slice(&v.to_le_bytes());
}
/// Append a little-endian `u32` to a byte buffer.
fn push_u32(buf: &mut Vec<u8>, v: u32) {
    buf.extend_from_slice(&v.to_le_bytes());
}
/// Append a little-endian `f32` to a byte buffer.
fn push_f32(buf: &mut Vec<u8>, v: f32) {
    buf.extend_from_slice(&v.to_le_bytes());
}
/// Read a little-endian `u16` from a byte slice at the requested offset.
fn read_u16(buf: &[u8], offset: usize) -> Result<u16, String> {
    buf.get(offset..offset + 2)
        .map(|b| u16::from_le_bytes([b[0], b[1]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected u16)", offset))
}
/// Read a little-endian `u32` from a byte slice at the requested offset.
fn read_u32(buf: &[u8], offset: usize) -> Result<u32, String> {
    buf.get(offset..offset + 4)
        .map(|b| u32::from_le_bytes([b[0], b[1], b[2], b[3]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected u32)", offset))
}
/// Read a little-endian `f32` from a byte slice at the requested offset.
fn read_f32(buf: &[u8], offset: usize) -> Result<f32, String> {
    buf.get(offset..offset + 4)
        .map(|b| f32::from_le_bytes([b[0], b[1], b[2], b[3]]))
        .ok_or_else(|| format!("LIMG truncated at offset {} (expected f32)", offset))
}
/// Encode a flat image into a LIMG byte vector.
pub fn encode_flat(img: &ImageData) -> Result<Vec<u8>, String> {
    let mut buf = write_header(TYPE_FLAT);
    push_u32(&mut buf, img.width);
    push_u32(&mut buf, img.height);
    let compressed = compress(&img.pixels)?;
    buf.extend_from_slice(&compressed);
    Ok(buf)
}
/// Decode a flat image from a LIMG payload.
pub fn decode_flat(payload: &[u8]) -> Result<ImageData, String> {
    if payload.len() < 8 {
        return Err("LIMG flat payload too short".into());
    }
    let width = read_u32(payload, 0)?;
    let height = read_u32(payload, 4)?;
    let pixels = decompress(&payload[8..])?;
    let expected = width
        .checked_mul(height)
        .and_then(|v| v.checked_mul(4))
        .ok_or_else(|| {
            format!(
                "LIMG flat: dimensions overflow byte size calculation ({}x{})",
                width, height
            )
        })? as usize;
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
/// Encode a layered image into a LIMG byte vector.
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
/// Decode a layered image from a LIMG payload.
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
        let name_len = read_u16(payload, pos)? as usize;
        pos += 2;
        let name_end = pos
            .checked_add(name_len)
            .ok_or_else(|| format!("LIMG layered: layer {} name length overflow", i))?;
        if name_end > payload.len() {
            return Err(format!("LIMG layered: layer {} name out of bounds", i));
        }
        let name = std::str::from_utf8(&payload[pos..name_end])
            .map_err(|e| format!("LIMG layered: layer {} name is invalid UTF-8: {}", i, e))?
            .to_string();
        pos = name_end;
        let opacity = read_f32(payload, pos)?;
        pos += 4;
        if pos >= payload.len() {
            return Err(format!(
                "LIMG layered: layer {} visible flag out of bounds",
                i
            ));
        }
        let visible = payload[pos] != 0;
        pos += 1;
        let comp_len = read_u32(payload, pos)? as usize;
        pos += 4;
        let comp_end = pos
            .checked_add(comp_len)
            .ok_or_else(|| format!("LIMG layered: layer {} pixel block length overflow", i))?;
        if comp_end > payload.len() {
            return Err(format!(
                "LIMG layered: layer {} pixel block out of bounds",
                i
            ));
        }
        let pixels = decompress(&payload[pos..comp_end])?;
        pos = comp_end;
        let expected = canvas_w
            .checked_mul(canvas_h)
            .and_then(|v| v.checked_mul(4))
            .ok_or_else(|| {
                format!(
                    "LIMG layered: dimensions overflow byte size calculation ({}x{})",
                    canvas_w, canvas_h
                )
            })? as usize;
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
/// Parse a LIMG header and return the type flag plus the remaining payload.
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
