//! Base64 and hex encoding/decoding for data serialization.
//!
//! This module is part of Luna2D's `data` subsystem and provides the implementation
//! details for encode-related operations and data management.
//! Key types exported from this module: `EncodeFormat`.
//! Primary functions: `parse_str()`, `encode()`, `decode()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

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
