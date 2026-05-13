//! Hashing: MD5, SHA-1, SHA-256, SHA-512, CRC-32.

use md5::Digest;
use sha1;

/// Hash algorithm selector.
///
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
    /// Parse an algorithm name string (case-insensitive).
    /// Accepts `"md5"`, `"sha1"` / `"sha-1"`, `"sha256"` / `"sha-256"`,
    /// `"sha512"` / `"sha-512"`.
    ///
    ///
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
///
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

/// Compute the CRC-32 checksum of `data` using the IEEE polynomial.
///
/// Suitable for non-security integrity checks and binary format validation.
/// The result is a `u32` returned as `u64` for ergonomic use in Lua (integers
/// are 64-bit in LuaJIT and Lua 5.4).
///
///
/// `u64` — CRC-32 value in `[0, 2³²)`.
pub fn crc32(data: &[u8]) -> u64 {
    crc32fast::hash(data) as u64
}
