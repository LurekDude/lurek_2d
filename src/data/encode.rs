//! Base64 and hex encoding/decoding for data serialization.

use base64::Engine;

/// Supported encoding formats.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EncodeFormat {
    /// Base64 (RFC 4648 standard alphabet).
    Base64,
    /// Hexadecimal (lowercase).
    Hex,
}

impl EncodeFormat {
    /// Parse a format name string.
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
pub fn encode(format: EncodeFormat, data: &[u8]) -> String {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD.encode(data),
        EncodeFormat::Hex => hex::encode(data),
    }
}

/// Decode a string back into bytes using the specified format.
pub fn decode(format: EncodeFormat, text: &str) -> Result<Vec<u8>, String> {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD
            .decode(text)
            .map_err(|e| format!("Base64 decode error: {}", e)),
        EncodeFormat::Hex => hex::decode(text).map_err(|e| format!("Hex decode error: {}", e)),
    }
}
