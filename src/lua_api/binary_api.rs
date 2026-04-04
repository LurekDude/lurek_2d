//! Registers the `luna.binary.*` binary buffer, compression, hashing, encoding, and pack API.
//!
//! Provides the Lua-side `luna.binary` namespace with functions for creating byte buffers,
//! compressing and decompressing data, computing hashes, encoding/decoding base64/hex, and
//! the Luna2D Binary Pack Format (write/read/size).
//!
//! All public items are documented. See the parent module for architectural context.

use std::sync::Arc;

use mlua::prelude::*;

use crate::binary::{self, BinValue, ByteData, DataView};

/// Registers the `luna.binary` table on the provided `luna` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let bin_table = lua.create_table()?;

    // luna.binary.newByteData(size_or_string)
    /// Creates a new mutable byte buffer of the given size or from a string.
    /// @param value : any
    bin_table.set(
        "newByteData",
        lua.create_function(|lua, value: LuaValue| {
            let byte_data = match value {
                LuaValue::Integer(size) => ByteData::new(size.max(0) as usize),
                LuaValue::Number(size) => ByteData::new(size.max(0.0) as usize),
                LuaValue::String(s) => ByteData::from_string(
                    s.to_str()
                        .map_err(|e| LuaError::RuntimeError(e.to_string()))?,
                ),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "newByteData expects a number (size) or string".to_string(),
                    ))
                }
            };
            lua.create_userdata(byte_data)
        })?,
    )?;

    // luna.binary.compress(format, data, level?)
    /// Compresses data using the given algorithm (''deflate'', ''gzip'', ''lz4'').
    /// @param format_str : string
    /// @param raw_data : string
    /// @param level : integer?
    /// @return any
    bin_table.set(
        "compress",
        lua.create_function(
            |_, (format_str, raw_data, level): (String, LuaString, Option<u32>)| {
                let format = binary::CompressFormat::parse_str(&format_str)
                    .map_err(LuaError::RuntimeError)?;
                let level = level.unwrap_or(6);
                let result = binary::compress(raw_data.as_bytes(), format, level)
                    .map_err(LuaError::RuntimeError)?;
                Ok(result)
            },
        )?,
    )?;

    // luna.binary.decompress(format, data)
    /// Decompresses data using the given algorithm.
    /// @param format_str : string
    /// @param compressed_data : string
    /// @return any
    bin_table.set(
        "decompress",
        lua.create_function(|_, (format_str, compressed_data): (String, LuaString)| {
            let format = binary::CompressFormat::parse_str(&format_str)
                .map_err(LuaError::RuntimeError)?;
            let result = binary::decompress(compressed_data.as_bytes(), format)
                .map_err(LuaError::RuntimeError)?;
            Ok(result)
        })?,
    )?;

    // luna.binary.hash(algorithm, data)
    /// Returns the cryptographic hash (md5, sha1, sha256, sha512) of the input.
    /// @param algo_str : string
    /// @param raw_data : string
    /// @return any
    bin_table.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = binary::HashAlgorithm::parse_str(&algo_str)
                .map_err(LuaError::RuntimeError)?;
            Ok(binary::hash(algo, raw_data.as_bytes()))
        })?,
    )?;

    // luna.binary.encode(format, data)
    /// Encodes binary data using the given format (''base64'', ''hex'').
    /// @param format_str : string
    /// @param raw_data : string
    /// @return any
    bin_table.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format = binary::EncodeFormat::parse_str(&format_str)
                .map_err(LuaError::RuntimeError)?;
            Ok(binary::encode(format, raw_data.as_bytes()))
        })?,
    )?;

    // luna.binary.decode(format, text)
    /// Decodes encoded text back to binary using the given format (''base64'', ''hex'').
    /// @param format_str : string
    /// @param encoded : string
    /// @return any
    bin_table.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format = binary::EncodeFormat::parse_str(&format_str)
                .map_err(LuaError::RuntimeError)?;
            let result = binary::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // luna.binary.write(format, ...) -> string (raw bytes)
    /// Packs values into a binary byte string using the Luna2D Binary Pack Format.
    /// Format: space-separated tokens (u8 u16 u32 u64 i8 i16 i32 i64 f32 f64 bool str cstr pad).
    /// Optional leading token: le (little-endian, default) or be (big-endian).
    /// @param format : string
    /// @return any
    bin_table.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bv = lua_values_to_bin(vals);
            let bd = binary::write(&fmt, &bv).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // luna.binary.read(format, data, offset?) -> values..., next_pos
    /// Reads values from a binary byte string using the Luna2D Binary Pack Format.
    /// Returns all decoded values followed by the next unread byte offset.
    /// @param format : string
    /// @param data : string
    /// @param offset : integer?
    /// @return any
    bin_table.set(
        "read",
        lua.create_function(
            |lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
                let off = offset.unwrap_or(0);
                let (values, next_pos) = binary::read(&fmt, raw.as_bytes(), off)
                    .map_err(LuaError::RuntimeError)?;
                let mut result = bin_values_to_lua(lua, values)?;
                result.push(LuaValue::Integer(next_pos as i64));
                Ok(LuaMultiValue::from_vec(result))
            },
        )?,
    )?;

    // luna.binary.size(format) -> integer
    /// Returns the fixed byte count the given format would produce.
    /// Errors if the format contains variable-length tokens (str, cstr).
    /// @param format : string
    /// @return any
    bin_table.set(
        "size",
        lua.create_function(|_, fmt: String| {
            binary::measure_size(&fmt)
                .map_err(LuaError::RuntimeError)
                .map(|n| n as i64)
        })?,
    )?;

    // luna.binary.newDataView(data, offset?, size?) -> DataView
    /// Creates a read-only windowed view into a byte string.
    /// @param data : string
    /// @param offset : integer?
    /// @param size : integer?
    /// @return any
    bin_table.set(
        "newDataView",
        lua.create_function(
            |_, (raw, offset, size): (LuaString, Option<usize>, Option<usize>)| {
                let bytes: Arc<Vec<u8>> = Arc::new(raw.as_bytes().to_vec());
                let total = bytes.len();
                let off = offset.unwrap_or(0);
                let sz = size.unwrap_or_else(|| total.saturating_sub(off));
                let dv = DataView::new_slice(bytes, off, sz).map_err(LuaError::RuntimeError)?;
                Ok(LuaDataView { inner: dv })
            },
        )?,
    )?;

    luna.set("binary", bin_table)?;
    Ok(())
}

// ── write/read helpers ────────────────────────────────────────────────────────

/// Converts a `LuaMultiValue` into a `Vec<BinValue>` for passing to the write API.
fn lua_values_to_bin(vals: LuaMultiValue) -> Vec<BinValue> {
    vals.into_iter()
        .map(|v| match v {
            LuaValue::Integer(n) => BinValue::I64(n),
            LuaValue::Number(n) => BinValue::F64(n),
            LuaValue::String(s) => BinValue::Str(s.to_str().unwrap_or("").to_string()),
            LuaValue::Boolean(b) => BinValue::Bool(b),
            _ => BinValue::I64(0),
        })
        .collect()
}

/// Converts a `Vec<BinValue>` into a `Vec<LuaValue>` for returning from read.
fn bin_values_to_lua<'lua>(
    lua: &'lua Lua,
    vals: Vec<BinValue>,
) -> LuaResult<Vec<LuaValue<'lua>>> {
    vals.into_iter()
        .map(|v| match v {
            BinValue::U8(n)  => Ok(LuaValue::Integer(n as i64)),
            BinValue::U16(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::U32(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::U64(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::I8(n)  => Ok(LuaValue::Integer(n as i64)),
            BinValue::I16(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::I32(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::I64(n) => Ok(LuaValue::Integer(n)),
            BinValue::F32(f) => Ok(LuaValue::Number(f as f64)),
            BinValue::F64(f) => Ok(LuaValue::Number(f)),
            BinValue::Bool(b) => Ok(LuaValue::Boolean(b)),
            BinValue::Str(s) => lua.create_string(&s).map(LuaValue::String),
            BinValue::Bytes(b) => lua.create_string(&b[..]).map(LuaValue::String),
        })
        .collect()
}

// ── DataView userdata ─────────────────────────────────────────────────────────

/// Lua userdata wrapper for `DataView`.
struct LuaDataView {
    /// The underlying read-only byte-buffer view.
    inner: DataView,
}

impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner.get_u8(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner.get_i8(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner.get_i16(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner.get_u16(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner.get_i32(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner.get_u32(offset).map(|v| v as i64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner.get_f32(offset).map(|v| v as f64).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.get_size() as i64));
    }
}
