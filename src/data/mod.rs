//! Binary data manipulation, compression, hashing, encoding, and pack/unpack.
//!
//! Provides `ByteData` for raw byte buffers, plus compression (deflate/gzip/lz4/zlib),
//! cryptographic hashing (MD5/SHA family), encoding (base64/hex), TOML parsing,
//! binary pack/unpack (`pack` module), and a windowed byte-buffer view (`dataview` module).

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
/// Binary pack/unpack utilities compatible with the LÖVE2D `data.pack` API.
pub mod pack;
/// Luna2D Binary Pack Format — space-separated type-token serialization.
pub mod bin_pack;
/// TOML parsing and encoding.
pub mod toml_convert;

pub use byte_data::ByteData;
pub use compress::{compress, decompress, CompressFormat};
pub use dataview::DataView;
pub use encode::{decode, encode, EncodeFormat};
pub use hash::{hash, HashAlgorithm};
pub use pack::{get_packed_size, pack, unpack, PackValue};
pub use bin_pack::{measure_size as bin_measure_size, read as bin_read, write as bin_write, BinValue};
