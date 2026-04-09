//! Base64 and hex encoding/decoding for data serialization.
//!
//! This module is part of Lurek2D's `data` subsystem and provides the implementation
//! details for encode-related operations and data management.
//! Key types exported from this module: `EncodeFormat`.
//! Primary functions: `parse_str()`, `encode()`, `decode()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use base64::Engine;

/// Supported encoding formats. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Base64` — Base64 variant.
/// - `Hex` — Hex variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EncodeFormat {
    /// Base64 (RFC 4648 standard alphabet).
    Base64,
    /// Hexadecimal (lowercase).
    Hex,
}

impl EncodeFormat {
    /// Parse a format name string. Returns an error if the source data is malformed or missing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn parse_str(s: &str) -> Result<Self, String> {
        match s.to_lowercase().as_str() {
            "base64" => Ok(EncodeFormat::Base64),
            "hex" => Ok(EncodeFormat::Hex),
            _ => Err(format!(
                "Unknown encoding format: '{}'. Use 'base64' or 'hex'.",
                s
            )),
        }
    }
}

/// Encode bytes into a string using the specified format.
///
/// # Parameters
/// - `format` — `EncodeFormat`.
/// - `data` — `&[u8]`.
///
/// # Returns
/// `String`.
pub fn encode(format: EncodeFormat, data: &[u8]) -> String {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD.encode(data),
        EncodeFormat::Hex => hex::encode(data),
    }
}

/// Decode a string back into bytes using the specified format.
///
/// # Parameters
/// - `format` — `EncodeFormat`.
/// - `text` — `&str`.
///
/// # Returns
/// `Result<Vec<u8>, String>`.
pub fn decode(format: EncodeFormat, text: &str) -> Result<Vec<u8>, String> {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD
            .decode(text)
            .map_err(|e| format!("Base64 decode error: {}", e)),
        EncodeFormat::Hex => hex::decode(text).map_err(|e| format!("Hex decode error: {}", e)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Parsing ────────────────────────────────────────────────────────────────

    #[test]
    fn parse_str_base64_valid() {
        assert_eq!(
            EncodeFormat::parse_str("base64").unwrap(),
            EncodeFormat::Base64
        );
    }

    #[test]
    fn parse_str_hex_valid() {
        assert_eq!(EncodeFormat::parse_str("hex").unwrap(), EncodeFormat::Hex);
    }

    #[test]
    fn parse_str_invalid_returns_err() {
        assert!(EncodeFormat::parse_str("binary").is_err());
    }

    // ── Round-trips ────────────────────────────────────────────────────────────

    #[test]
    fn base64_encode_decode_roundtrip() {
        let data = b"Lurek2D engine test";
        let encoded = encode(EncodeFormat::Base64, data);
        let decoded = decode(EncodeFormat::Base64, &encoded).unwrap();
        assert_eq!(decoded.as_slice(), data.as_ref());
    }

    #[test]
    fn hex_encode_decode_roundtrip() {
        let data: &[u8] = &[0x00, 0xFF, 0x7F, 0x80];
        let encoded = encode(EncodeFormat::Hex, data);
        let decoded = decode(EncodeFormat::Hex, &encoded).unwrap();
        assert_eq!(decoded, data);
    }

    #[test]
    fn hex_encode_known_value() {
        let encoded = encode(EncodeFormat::Hex, &[0xDE, 0xAD, 0xBE, 0xEF]);
        assert_eq!(encoded, "deadbeef");
    }
}
