//! Own base64 and hex encode/decode helpers for opaque byte payloads in the data module.
//! Both directions are supported: bytes-to-string and string-to-bytes with descriptive errors.
//! Format selection is through an enum so callers never import codec crates directly.
//! No streaming variant; buffers must fit in memory. Primary consumer is `src/lua_api/data_api.rs`.

use base64::Engine;
#[derive(Debug, Clone, Copy, PartialEq)]
/// Select textual encoding algorithm.
pub enum EncodeFormat {
    /// Encode using standard base64 alphabet.
    Base64,
    /// Encode using lowercase hexadecimal text.
    Hex,
}
impl EncodeFormat {
    /// Parse format label and return encoding variant or error.
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
/// Encode bytes with selected format and return text.
pub fn encode(format: EncodeFormat, data: &[u8]) -> String {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD.encode(data),
        EncodeFormat::Hex => hex::encode(data),
    }
}
/// Decode text with selected format and return bytes or error.
pub fn decode(format: EncodeFormat, text: &str) -> Result<Vec<u8>, String> {
    match format {
        EncodeFormat::Base64 => base64::engine::general_purpose::STANDARD
            .decode(text)
            .map_err(|e| format!("Base64 decode error: {}", e)),
        EncodeFormat::Hex => hex::decode(text).map_err(|e| format!("Hex decode error: {}", e)),
    }
}
