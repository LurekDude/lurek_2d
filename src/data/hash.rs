//! Cryptographic hash functions for data integrity verification.
//!
//! This module is part of Lurek2D's `data` subsystem and provides the implementation
//! details for hash-related operations and data management.
//! Key types exported from this module: `HashAlgorithm`.
//! Primary functions: `parse_str()`, `hash()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use md5::Digest;
use sha1;

/// Supported hash algorithms. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Md5` — Md5 variant.
/// - `Sha1` — Sha1 variant.
/// - `Sha256` — Sha256 variant.
/// - `Sha512` — Sha512 variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum HashAlgorithm {
    /// MD5 (128-bit, not recommended for security).
    Md5,
    /// SHA-1 (160-bit, not recommended for security).
    Sha1,
    /// SHA-256 (256-bit).
    Sha256,
    /// SHA-512 (512-bit).
    Sha512,
}

impl HashAlgorithm {
    /// Parse an algorithm name string. Returns an error if the source data is malformed or missing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn parse_str(s: &str) -> Result<Self, String> {
        match s.to_lowercase().as_str() {
            "md5" => Ok(HashAlgorithm::Md5),
            "sha1" | "sha-1" => Ok(HashAlgorithm::Sha1),
            "sha256" | "sha-256" => Ok(HashAlgorithm::Sha256),
            "sha512" | "sha-512" => Ok(HashAlgorithm::Sha512),
            _ => Err(format!(
                "Unknown hash algorithm: '{}'. Use 'md5', 'sha1', 'sha256', or 'sha512'.",
                s
            )),
        }
    }
}

/// Compute the hash of data using the specified algorithm, returned as a hex string.
///
/// # Parameters
/// - `algorithm` — `HashAlgorithm`.
/// - `data` — `&[u8]`.
///
/// # Returns
/// `String`.
pub fn hash(algorithm: HashAlgorithm, data: &[u8]) -> String {
    match algorithm {
        HashAlgorithm::Md5 => {
            let result = md5::Md5::digest(data);
            hex::encode(result)
        }
        HashAlgorithm::Sha1 => {
            let result = sha1::Sha1::digest(data);
            hex::encode(result)
        }
        HashAlgorithm::Sha256 => {
            let result = sha2::Sha256::digest(data);
            hex::encode(result)
        }
        HashAlgorithm::Sha512 => {
            let result = sha2::Sha512::digest(data);
            hex::encode(result)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Parsing ────────────────────────────────────────────────────────────────

    #[test]
    fn parse_str_md5_valid() {
        assert_eq!(HashAlgorithm::parse_str("md5").unwrap(), HashAlgorithm::Md5);
    }

    #[test]
    fn parse_str_sha256_valid() {
        assert_eq!(
            HashAlgorithm::parse_str("sha256").unwrap(),
            HashAlgorithm::Sha256
        );
    }

    #[test]
    fn parse_str_invalid_returns_err() {
        assert!(HashAlgorithm::parse_str("blake2").is_err());
    }

    // ── Hashing ────────────────────────────────────────────────────────────────

    #[test]
    fn md5_same_input_same_output() {
        let h1 = hash(HashAlgorithm::Md5, b"hello");
        let h2 = hash(HashAlgorithm::Md5, b"hello");
        assert_eq!(h1, h2);
    }

    #[test]
    fn md5_different_inputs_different_hashes() {
        let h1 = hash(HashAlgorithm::Md5, b"hello");
        let h2 = hash(HashAlgorithm::Md5, b"world");
        assert_ne!(h1, h2);
    }

    #[test]
    fn sha256_empty_known_value() {
        let h = hash(HashAlgorithm::Sha256, b"");
        assert_eq!(
            h,
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
    }
}
