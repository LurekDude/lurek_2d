//! Registers the `luna.data.*` binary data, compression, hashing, and encoding API.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for data api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::sync::Arc;

use mlua::prelude::*;

use crate::data::{self, ByteData, DataView};

/// Registers the `luna.data` table on the provided `luna` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let data_table = lua.create_table()?;

    // luna.data.newByteData(size_or_string)
    /// Creates a new mutable byte buffer of the given size.
    /// @param value : any
    data_table.set(
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

    // luna.data.compress(format, data, level?)
    /// Compresses data using the given algorithm ('deflate', 'gzip', 'lz4').
    /// @param format_str : string
    /// @param raw_data : string
    /// @param level : integer?
    /// @return any
    data_table.set(
        "compress",
        lua.create_function(
            |_, (format_str, raw_data, level): (String, LuaString, Option<u32>)| {
                let format =
                    data::CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
                let level = level.unwrap_or(6);
                let result = data::compress(raw_data.as_bytes(), format, level)
                    .map_err(LuaError::RuntimeError)?;
                Ok(result)
            },
        )?,
    )?;

    // luna.data.decompress(format, data)
    /// Decompresses data using the given algorithm.
    /// @param format_str : string
    /// @param compressed_data : string
    /// @return any
    data_table.set(
        "decompress",
        lua.create_function(|_, (format_str, compressed_data): (String, LuaString)| {
            let format =
                data::CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decompress(compressed_data.as_bytes(), format)
                .map_err(LuaError::RuntimeError)?;
            Ok(result)
        })?,
    )?;

    // luna.data.hash(algorithm, data)
    /// Returns the cryptographic hash (md5, sha1, sha256) of the input.
    /// @param algo_str : string
    /// @param raw_data : string
    /// @return any
    data_table.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = data::HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;

    // luna.data.encode(format, data)
    /// Encodes Lua values into a binary string using a pack-format string.
    /// @param format_str : string
    /// @param raw_data : string
    /// @return any
    ///
    /// # Parameters
    /// - `format` — Pack-format string (same syntax as string.pack).
    /// - `...` — Values to encode.
    ///
    /// # Returns
    /// Binary string containing the packed bytes.
    data_table.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format =
                data::EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;

    // luna.data.decode(format, text)
    /// Decodes binary data from a buffer according to a pack-format string.
    /// @param format_str : string
    /// @param encoded : string
    ///
    /// # Parameters
    /// - `format` — Pack-format string (same syntax as string.pack).
    /// - `data` — Binary string or ByteData buffer to read from.
    ///
    /// # Returns
    /// Decoded Lua values followed by the next unread byte offset.
    data_table.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format =
                data::EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // luna.data.parseToml(str) -> table
    /// Parses a TOML string and returns a Lua table.
    /// @param input : string
    data_table.set(
        "parseToml",
        lua.create_function(|lua, input: String| {
            let value = data::toml_convert::parse_toml(&input).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;

    // luna.data.encodeToml(tbl) -> string
    /// Encodes a Lua table as a TOML string.
    /// @param table : table
    data_table.set(
        "encodeToml",
        lua.create_function(|_, table: LuaTable| {
            let value = lua_table_to_toml_value(&table)?;
            data::toml_convert::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // luna.data.pack(format, ...) -> string (raw bytes)
    /// Packs values into a binary byte string according to a format string.
    /// Compatible with LÖVE2D's data.pack API.
    /// @param format : string
    /// @return any
    data_table.set(
        "pack",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let pv = lua_values_to_pack(vals);
            let bd = data::pack::pack(&fmt, &pv).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // luna.data.unpack(format, data, pos?) -> values..., next_pos
    /// Unpacks values from a binary byte string according to a format string.
    /// Returns all decoded values followed by the next unread byte offset.
    /// @param format : string
    /// @param data : string
    /// @param pos : integer?
    /// @return any
    data_table.set(
        "unpack",
        lua.create_function(
            |lua, (fmt, raw, pos): (String, LuaString, Option<usize>)| {
                let offset = pos.unwrap_or(0);
                let (values, next_pos) =
                    data::pack::unpack(&fmt, raw.as_bytes(), offset)
                        .map_err(LuaError::RuntimeError)?;
                let mut result = pack_values_to_lua(lua, values)?;
                result.push(LuaValue::Integer(next_pos as i64));
                Ok(LuaMultiValue::from_vec(result))
            },
        )?,
    )?;

    // luna.data.getPackedSize(format, ...) -> integer
    /// Returns the total byte count that pack() would produce for the given format and values.
    /// For fixed-width types no values are needed. String types (s/z) require the values.
    /// @param format : string
    /// @return any
    data_table.set(
        "getPackedSize",
        lua.create_function(|_, (fmt, vals): (String, LuaMultiValue)| {
            let pv = lua_values_to_pack(vals);
            data::pack::get_packed_size(&fmt, &pv)
                .map_err(LuaError::RuntimeError)
                .map(|n| n as i64)
        })?,
    )?;

    // luna.data.newDataView(data, offset?, size?) -> DataView
    /// Creates a read-only windowed view into a byte string.
    /// @param data : string
    /// @param offset : integer?
    /// @param size : integer?
    /// @return any
    data_table.set(
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

    /// Data.
    luna.set("data", data_table)?;
    Ok(())
}

/// Convert a `toml::Value` to a Lua value.
fn toml_value_to_lua<'lua>(lua: &'lua Lua, value: &toml::Value) -> LuaResult<LuaValue<'lua>> {
    match value {
        toml::Value::String(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        toml::Value::Integer(n) => Ok(LuaValue::Integer(*n)),
        toml::Value::Float(f) => Ok(LuaValue::Number(*f)),
        toml::Value::Boolean(b) => Ok(LuaValue::Boolean(*b)),
        toml::Value::Datetime(dt) => Ok(LuaValue::String(lua.create_string(dt.to_string())?)),
        toml::Value::Array(arr) => {
            let t = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                t.set(i as i64 + 1, toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
        toml::Value::Table(map) => {
            let t = lua.create_table()?;
            for (k, v) in map.iter() {
                t.set(k.as_str(), toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(t))
        }
    }
}

/// Convert a Lua table to a `toml::Value`.
fn lua_table_to_toml_value(table: &LuaTable) -> LuaResult<toml::Value> {
    lua_value_to_toml(&LuaValue::Table(table.clone()))
}

/// Convert any Lua value to a `toml::Value`.
fn lua_value_to_toml(value: &LuaValue) -> LuaResult<toml::Value> {
    match value {
        LuaValue::Nil => Err(LuaError::RuntimeError(
            "encodeToml: nil values cannot be encoded in TOML".into(),
        )),
        LuaValue::Boolean(b) => Ok(toml::Value::Boolean(*b)),
        LuaValue::Integer(n) => Ok(toml::Value::Integer(*n)),
        LuaValue::Number(f) => Ok(toml::Value::Float(*f)),
        LuaValue::String(s) => Ok(toml::Value::String(
            s.to_str()
                .map_err(|e| LuaError::RuntimeError(format!("Invalid UTF-8 string: {e}")))?
                .to_string(),
        )),
        LuaValue::Table(t) => {
            // Check if this is an array (sequential integer keys starting at 1)
            let len = t.raw_len();
            if len > 0 {
                let mut arr = Vec::with_capacity(len);
                for i in 1..=len as i64 {
                    let v: LuaValue = t.get(i)?;
                    arr.push(lua_value_to_toml(&v)?);
                }
                Ok(toml::Value::Array(arr))
            } else {
                let mut map = toml::map::Map::new();
                for pair in t.clone().pairs::<String, LuaValue>() {
                    let (k, v) = pair?;
                    map.insert(k, lua_value_to_toml(&v)?);
                }
                Ok(toml::Value::Table(map))
            }
        }
        _ => Err(LuaError::RuntimeError(
            "encodeToml: unsupported value type".into(),
        )),
    }
}

// ── pack/unpack helpers ─────────────────────────────────────────────────────

/// Converts a `LuaMultiValue` into a `Vec<PackValue>` for passing to the pack API.
fn lua_values_to_pack(vals: LuaMultiValue) -> Vec<data::PackValue> {
    vals.into_iter()
        .map(|v| match v {
            LuaValue::Integer(n) => data::PackValue::Int(n),
            LuaValue::Number(n) => data::PackValue::Double(n),
            LuaValue::String(s) => {
                data::PackValue::Str(s.to_str().unwrap_or("").to_string())
            }
            _ => data::PackValue::Int(0),
        })
        .collect()
}

/// Converts a `Vec<PackValue>` into a `Vec<LuaValue>` for returning from unpack.
fn pack_values_to_lua<'lua>(
    lua: &'lua Lua,
    vals: Vec<data::PackValue>,
) -> LuaResult<Vec<LuaValue<'lua>>> {
    vals.into_iter()
        .map(|v| match v {
            data::PackValue::Int(n) => Ok(LuaValue::Integer(n)),
            data::PackValue::UInt(n) => Ok(LuaValue::Integer(n as i64)),
            data::PackValue::Float(f) => Ok(LuaValue::Number(f as f64)),
            data::PackValue::Double(d) => Ok(LuaValue::Number(d)),
            data::PackValue::Str(s) => lua.create_string(&s).map(LuaValue::String),
            data::PackValue::Bytes(b) => lua.create_string(&b[..]).map(LuaValue::String),
        })
        .collect()
}

// ── DataView userdata ───────────────────────────────────────────────────────

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
