//! Binary data: packing, compression, hashing, encoding.

pub mod bin_pack;
pub mod byte_data;
pub mod compress;
pub mod data_writer;
pub mod dataview;
pub mod encode;
pub mod hash;
pub mod pack;
pub mod ring_buffer;
pub use bin_pack::{
    measure_size as bin_measure_size, read as bin_read, write as bin_write, BinValue,
};
pub use byte_data::ByteData;
pub use compress::{
    compress, compress_chunks, compress_stream, decompress, decompress_chunks, decompress_stream,
    CompressFormat,
};
pub use data_writer::DataWriter;
pub use dataview::{DataView, LuaDataView};
pub use encode::{decode, encode, EncodeFormat};
pub use hash::{crc32, hash, HashAlgorithm};
pub use pack::{get_packed_size, pack, unpack, PackValue};
pub use ring_buffer::RingBuffer;
