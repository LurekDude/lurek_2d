//! Own compression and decompression helpers wrapping flate2 (deflate/gzip/zlib) and lz4_flex.
//! Supports full-buffer, chunk-list, and generic streaming paths. Codec and level are caller-selected.
//! A private `ChunkReader` adapter implements `Read` over a slice list for the chunk path.
//! Does not own file I/O; callers pre-read bytes. Primary consumer is `src/lua_api/data_api.rs`.

use std::io::{Cursor, Read, Write};
#[derive(Debug, Clone, Copy, PartialEq)]
/// Select compression codec.
pub enum CompressFormat {
    /// Use raw DEFLATE stream.
    Deflate,
    /// Use gzip container and DEFLATE payload.
    Gzip,
    /// Use lz4 frame with prepended size helper.
    Lz4,
    /// Use zlib container and DEFLATE payload.
    Zlib,
}
impl CompressFormat {
    /// Parse codec label and return variant or error.
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
/// Compress full byte slice and return compressed bytes.
pub fn compress(data: &[u8], format: CompressFormat, level: u32) -> Result<Vec<u8>, String> {
    let mut out = Vec::new();
    compress_stream(Cursor::new(data), &mut out, format, level)?;
    Ok(out)
}
/// Decompress full byte slice and return decoded bytes.
pub fn decompress(data: &[u8], format: CompressFormat) -> Result<Vec<u8>, String> {
    let mut out = Vec::new();
    decompress_stream(Cursor::new(data), &mut out, format)?;
    Ok(out)
}
/// Compress concatenated chunks and return compressed bytes.
pub fn compress_chunks(
    chunks: &[&[u8]],
    format: CompressFormat,
    level: u32,
) -> Result<Vec<u8>, String> {
    let level = level.min(9);
    let compression = flate2::Compression::new(level);
    match format {
        CompressFormat::Deflate => {
            let mut encoder = flate2::write::DeflateEncoder::new(Vec::new(), compression);
            for chunk in chunks {
                encoder
                    .write_all(chunk)
                    .map_err(|e| format!("Deflate compress error: {}", e))?;
            }
            encoder
                .finish()
                .map_err(|e| format!("Deflate finish error: {}", e))
        }
        CompressFormat::Gzip => {
            let mut encoder = flate2::write::GzEncoder::new(Vec::new(), compression);
            for chunk in chunks {
                encoder
                    .write_all(chunk)
                    .map_err(|e| format!("Gzip compress error: {}", e))?;
            }
            encoder
                .finish()
                .map_err(|e| format!("Gzip finish error: {}", e))
        }
        CompressFormat::Zlib => {
            let mut encoder = flate2::write::ZlibEncoder::new(Vec::new(), compression);
            for chunk in chunks {
                encoder
                    .write_all(chunk)
                    .map_err(|e| format!("Zlib compress error: {}", e))?;
            }
            encoder
                .finish()
                .map_err(|e| format!("Zlib finish error: {}", e))
        }
        CompressFormat::Lz4 => {
            let total_len = chunks.iter().map(|c| c.len()).sum();
            let mut input = Vec::with_capacity(total_len);
            for chunk in chunks {
                input.extend_from_slice(chunk);
            }
            Ok(lz4_flex::compress_prepend_size(&input))
        }
    }
}
/// Decompress concatenated chunks and return decoded bytes.
pub fn decompress_chunks(chunks: &[&[u8]], format: CompressFormat) -> Result<Vec<u8>, String> {
    let mut out = Vec::new();
    let mut reader = ChunkReader::new(chunks);
    decompress_stream(&mut reader, &mut out, format)?;
    Ok(out)
}
/// Hold state for reading over a borrowed slice list as a single `Read` stream.
struct ChunkReader<'a> {
    /// Hold borrowed slice list being read.
    chunks: &'a [&'a [u8]],
    /// Track current chunk index.
    chunk_idx: usize,
    /// Track byte offset within current chunk.
    offset: usize,
}
impl<'a> ChunkReader<'a> {
    /// Create reader over slice list starting at first byte.
    fn new(chunks: &'a [&'a [u8]]) -> Self {
        Self {
            chunks,
            chunk_idx: 0,
            offset: 0,
        }
    }
}
/// Implement `Read` over a flattened view of borrowed byte slices for chunk compression.
impl Read for ChunkReader<'_> {
    /// Read bytes into output buffer and return number of copied bytes.
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        if buf.is_empty() {
            return Ok(0);
        }
        let mut written = 0;
        while written < buf.len() {
            if self.chunk_idx >= self.chunks.len() {
                break;
            }
            let chunk = self.chunks[self.chunk_idx];
            if self.offset >= chunk.len() {
                self.chunk_idx += 1;
                self.offset = 0;
                continue;
            }
            let remaining_in_chunk = chunk.len() - self.offset;
            let remaining_out = buf.len() - written;
            let to_copy = remaining_in_chunk.min(remaining_out);
            buf[written..written + to_copy]
                .copy_from_slice(&chunk[self.offset..self.offset + to_copy]);
            self.offset += to_copy;
            written += to_copy;
        }
        Ok(written)
    }
}
/// Compress bytes from reader into writer using selected codec.
pub fn compress_stream<R: Read, W: Write>(
    mut reader: R,
    mut writer: W,
    format: CompressFormat,
    level: u32,
) -> Result<(), String> {
    let level = level.min(9);
    let compression = flate2::Compression::new(level);
    match format {
        CompressFormat::Deflate => {
            let mut encoder = flate2::write::DeflateEncoder::new(writer, compression);
            std::io::copy(&mut reader, &mut encoder)
                .map_err(|e| format!("Deflate compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Deflate finish error: {}", e))?;
            Ok(())
        }
        CompressFormat::Gzip => {
            let mut encoder = flate2::write::GzEncoder::new(writer, compression);
            std::io::copy(&mut reader, &mut encoder)
                .map_err(|e| format!("Gzip compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Gzip finish error: {}", e))?;
            Ok(())
        }
        CompressFormat::Zlib => {
            let mut encoder = flate2::write::ZlibEncoder::new(writer, compression);
            std::io::copy(&mut reader, &mut encoder)
                .map_err(|e| format!("Zlib compress error: {}", e))?;
            encoder
                .finish()
                .map_err(|e| format!("Zlib finish error: {}", e))?;
            Ok(())
        }
        CompressFormat::Lz4 => {
            let mut input = Vec::new();
            reader
                .read_to_end(&mut input)
                .map_err(|e| format!("LZ4 read error: {}", e))?;
            let compressed = lz4_flex::compress_prepend_size(&input);
            writer
                .write_all(&compressed)
                .map_err(|e| format!("LZ4 write error: {}", e))
        }
    }
}
/// Decompress bytes from reader into writer using selected codec.
pub fn decompress_stream<R: Read, W: Write>(
    mut reader: R,
    mut writer: W,
    format: CompressFormat,
) -> Result<(), String> {
    match format {
        CompressFormat::Deflate => {
            let mut decoder = flate2::read::DeflateDecoder::new(reader);
            std::io::copy(&mut decoder, &mut writer)
                .map_err(|e| format!("Deflate decompress error: {}", e))?;
            Ok(())
        }
        CompressFormat::Gzip => {
            let mut decoder = flate2::read::GzDecoder::new(reader);
            std::io::copy(&mut decoder, &mut writer)
                .map_err(|e| format!("Gzip decompress error: {}", e))?;
            Ok(())
        }
        CompressFormat::Zlib => {
            let mut decoder = flate2::read::ZlibDecoder::new(reader);
            std::io::copy(&mut decoder, &mut writer)
                .map_err(|e| format!("Zlib decompress error: {}", e))?;
            Ok(())
        }
        CompressFormat::Lz4 => {
            let mut input = Vec::new();
            reader
                .read_to_end(&mut input)
                .map_err(|e| format!("LZ4 read error: {}", e))?;
            let decompressed = lz4_flex::decompress_size_prepended(&input)
                .map_err(|e| format!("LZ4 decompress error: {}", e))?;
            writer
                .write_all(&decompressed)
                .map_err(|e| format!("LZ4 write error: {}", e))
        }
    }
}
