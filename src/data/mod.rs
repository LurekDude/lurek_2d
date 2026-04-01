//! Binary data manipulation, compression, hashing, and encoding.
//!
//! Provides `ByteData` for raw byte buffers, plus compression (deflate/gzip/lz4/zlib),
//! cryptographic hashing (MD5/SHA family), and encoding (base64/hex).
//! Also includes TOML parsing and encoding.

/// Raw byte buffer for binary data manipulation.
pub mod byte_data;
/// Deflate, gzip, lz4, and zlib compression/decompression.
pub mod compress;
/// Base64 and hex encoding/decoding.
pub mod encode;
/// Cryptographic hash functions (MD5, SHA-1, SHA-256, SHA-512).
pub mod hash;
/// TOML parsing and encoding.
pub mod toml_convert;

pub use byte_data::ByteData;
pub use compress::{compress, decompress, CompressFormat};
pub use encode::{decode, encode, EncodeFormat};
pub use hash::{hash, HashAlgorithm};
