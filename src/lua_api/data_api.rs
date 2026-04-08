//! `luna.data` — Binary data manipulation, compression, hashing, and encoding.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;

use crate::data::{
    self, BinValue, ByteData, CompressFormat, DataView, EncodeFormat, HashAlgorithm, PackValue,
};

// -------------------------------------------------------------------------------
// LuaDataView UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`DataView`].
pub struct LuaDataView {
    inner: DataView,
}

impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- getUInt8 --
        /// Reads an unsigned 8-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner
                .get_u8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt8 --
        /// Reads a signed 8-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner
                .get_i8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt16 --
        /// Reads a signed 16-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner
                .get_i16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt16 --
        /// Reads an unsigned 16-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner
                .get_u16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt32 --
        /// Reads a signed 32-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner
                .get_i32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt32 --
        /// Reads an unsigned 32-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner
                .get_u32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getFloat --
        /// Reads a 32-bit float at the given offset.
        /// @param offset : integer
        /// @return number
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner
                .get_f32(offset)
                .map(|v| v as f64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getDouble --
        /// Reads a 64-bit float at the given offset.
        /// @param offset : integer
        /// @return number
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });

        // -- getSize --
        /// Returns the size of this view in bytes.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| {
            Ok(this.inner.get_size() as i64)
        });

    }
}

// -------------------------------------------------------------------------------
// Pack conversion helpers
// -------------------------------------------------------------------------------

/// Converts a `LuaMultiValue` to `Vec<PackValue>` for the pack API.
fn lua_values_to_pack(vals: LuaMultiValue) -> Vec<PackValue> {
    vals.into_iter()
        .map(|v| match v {
            LuaValue::Integer(n) => PackValue::Int(n),
            LuaValue::Number(n) => PackValue::Double(n),
            LuaValue::String(s) => PackValue::Str(s.to_str().unwrap_or("").to_string()),
            LuaValue::Boolean(b) => PackValue::Int(b as i64),
            _ => PackValue::Int(0),
        })
        .collect()
}

/// Converts `Vec<PackValue>` back to Lua values for returning from unpack.
fn pack_values_to_lua(lua: &Lua, vals: Vec<PackValue>) -> LuaResult<Vec<LuaValue<'_>>> {
    vals.into_iter()
        .map(|v| match v {
            PackValue::Int(n) => Ok(LuaValue::Integer(n)),
            PackValue::UInt(n) => Ok(LuaValue::Integer(n as i64)),
            PackValue::Float(f) => Ok(LuaValue::Number(f as f64)),
            PackValue::Double(f) => Ok(LuaValue::Number(f)),
            PackValue::Str(s) => lua.create_string(s.as_bytes()).map(LuaValue::String),
            PackValue::Bytes(b) => lua.create_string(&b[..]).map(LuaValue::String),
        })
        .collect()
}

// -------------------------------------------------------------------------------
// Bin conversion helpers
// -------------------------------------------------------------------------------

/// Converts a `LuaMultiValue` to `Vec<BinValue>` for the Luna2D bin pack write API.
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

/// Converts `Vec<BinValue>` back to Lua values for returning from read.
fn bin_values_to_lua(lua: &Lua, vals: Vec<BinValue>) -> LuaResult<Vec<LuaValue<'_>>> {
    vals.into_iter()
        .map(|v| match v {
            BinValue::U8(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::U16(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::U32(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::U64(n) => Ok(LuaValue::Integer(n as i64)),
            BinValue::I8(n) => Ok(LuaValue::Integer(n as i64)),
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

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.data` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- pack --
    /// Packs values into a binary byte string using the format string.
    /// @param format : string
    /// @return string
    tbl.set(
        "pack",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            let bd = data::pack(&fmt, &pvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // -- unpack --
    /// Unpacks values from a binary byte string, returning values followed by next offset.
    /// @param format : string
    /// @param data : string
    /// @param offset : integer?
    /// @return ...
    tbl.set(
        "unpack",
        lua.create_function(
            |lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
                let (values, next_pos) =
                    data::unpack(&fmt, raw.as_bytes(), offset.unwrap_or(0))
                        .map_err(LuaError::RuntimeError)?;
                let mut result = pack_values_to_lua(lua, values)?;
                result.push(LuaValue::Integer(next_pos as i64));
                Ok(LuaMultiValue::from_vec(result))
            },
        )?,
    )?;

    // -- getPackedSize --
    /// Returns the number of bytes the given format and values would occupy.
    /// @param format : string
    /// @return integer
    tbl.set(
        "getPackedSize",
        lua.create_function(|_, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            data::get_packed_size(&fmt, &pvs)
                .map_err(LuaError::RuntimeError)
                .map(|n| n as i64)
        })?,
    )?;

    // -- compress --
    /// Compresses data using the given algorithm (deflate, gzip, lz4).
    /// @param format : string
    /// @param data : string
    /// @param level : integer?
    /// @return string
    tbl.set(
        "compress",
        lua.create_function(
            |lua, (format_str, raw_data, level): (String, LuaString, Option<u32>)| {
                let format =
                    CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
                let result = data::compress(raw_data.as_bytes(), format, level.unwrap_or(6))
                    .map_err(LuaError::RuntimeError)?;
                lua.create_string(&result)
            },
        )?,
    )?;

    // -- decompress --
    /// Decompresses data using the given algorithm (deflate, gzip, lz4).
    /// @param format : string
    /// @param data : string
    /// @return string
    tbl.set(
        "decompress",
        lua.create_function(|lua, (format_str, compressed): (String, LuaString)| {
            let format =
                CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decompress(compressed.as_bytes(), format)
                .map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // -- encode --
    /// Encodes binary data using the given format (base64, hex).
    /// @param format : string
    /// @param data : string
    /// @return string
    tbl.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format =
                EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;

    // -- decode --
    /// Decodes encoded text back to binary (base64, hex).
    /// @param format : string
    /// @param encoded : string
    /// @return string
    tbl.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format =
                EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // -- hash --
    /// Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
    /// @param algorithm : string
    /// @param data : string
    /// @return string
    tbl.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo =
                HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;

    // -- newByteData --
    /// Creates a new mutable byte buffer from a size or string.
    /// @param value : integer|string
    /// @return ByteData
    tbl.set(
        "newByteData",
        lua.create_function(|lua, value: LuaValue| {
            let bd = match value {
                LuaValue::Integer(n) => ByteData::new(n.max(0) as usize),
                LuaValue::Number(n) => ByteData::new(n.max(0.0) as usize),
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
            lua.create_userdata(bd)
        })?,
    )?;

    // -- newDataView --
    /// Creates a read-only windowed view into a byte string.
    /// @param data : string
    /// @param offset : integer?
    /// @param size : integer?
    /// @return DataView
    tbl.set(
        "newDataView",
        lua.create_function(
            |lua, (raw, offset, size): (LuaString, Option<usize>, Option<usize>)| {
                let bytes: Arc<Vec<u8>> = Arc::new(raw.as_bytes().to_vec());
                let total = bytes.len();
                let off = offset.unwrap_or(0);
                let sz = size.unwrap_or_else(|| total.saturating_sub(off));
                let dv =
                    DataView::new_slice(bytes, off, sz).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaDataView { inner: dv })
            },
        )?,
    )?;

    // -- write --
    /// Writes values using the Luna2D Binary Pack Format.
    /// @param format : string
    /// @return string
    tbl.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bvs = lua_values_to_bin(vals);
            let bd = data::bin_write(&fmt, &bvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // -- read --
    /// Reads values using the Luna2D Binary Pack Format.
    /// @param format : string
    /// @param data : string
    /// @param offset : integer?
    /// @return ...
    tbl.set(
        "read",
        lua.create_function(|lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
            let (bvs, _) = data::bin_read(&fmt, raw.as_bytes(), offset.unwrap_or(0))
                .map_err(LuaError::RuntimeError)?;
            let lv = bin_values_to_lua(lua, bvs)?;
            Ok(LuaMultiValue::from_vec(lv))
        })?,
    )?;

    // -- size --
    /// Returns the byte size of a Luna2D Binary Pack Format string.
    /// @param format : string
    /// @return integer
    tbl.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;

    luna.set("data", tbl)?;
    Ok(())
}
