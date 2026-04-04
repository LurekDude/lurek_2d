//! Binary buffer utilities: compression, hashing, encoding, and the Luna2D Binary Pack Format.
//!
//! Provides `ByteData` for raw byte buffers, compression (deflate/gzip/lz4/zlib),
//! cryptographic hashing (MD5/SHA family), encoding (base64/hex),
//! the Luna2D Binary Pack Format (`pack` module), and a windowed byte-buffer view (`dataview` module).

/// Raw byte buffer for binary data manipulation.
pub mod byte_data;
/// Deflate, gzip, lz4, and zlib compression/decompression.
pub mod compress;
/// Windowed read-only byte-buffer view.
pub mod dataview;
/// Base64 and hex encoding/decoding.
pub mod encode;
/// Cryptographic hash functions (MD5, SHA-1, SHA-256, SHA-512).
pub mod hash;
/// Luna2D Binary Pack Format: write/read/measure_size over named-token format strings.
pub mod pack;

pub use byte_data::ByteData;
pub use compress::{compress, decompress, CompressFormat};
pub use dataview::DataView;
pub use encode::{decode, encode, EncodeFormat};
pub use hash::{hash, HashAlgorithm};
pub use pack::{write, read, measure_size, BinValue};
