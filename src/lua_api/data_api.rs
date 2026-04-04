//! Registers the `luna.data.*` LÖVE2D-compatible binary data API.
//!
//! Provides the Lua-side `luna.data` namespace with functions that mirror the
//! LÖVE2D `love.data.*` surface: `pack`, `unpack`, `getPackedSize`,
//! `compress`, `decompress`, `encode`, `decode`, `hash`, `newByteData`,
//! and `newDataView`.
//!
//! `luna.data.pack` / `luna.data.unpack` use the LÖVE2D format string
//! (`"<"` / `">"` prefix for endianness, single-char type codes such as `"b"`, `"H"`,
//! `"f"`, `"z"`, `"s"`, etc.) for byte-for-byte compatibility with LÖVE2D data files.
//! TOML round-trip helpers are also exposed here as `luna.data.parseToml` and
//! `luna.data.encodeToml`.
//! Luna2D Binary Pack Format (space-separated type tokens) is available via
//! `luna.data.write` / `luna.data.read` / `luna.data.size`.

use std::sync::Arc;

use mlua::prelude::*;

use crate::data::{self, ByteData, BinValue, DataView, PackValue};

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

    // ── LÖVE2D pack API ─────────────────────────────────────────────────────

    // luna.data.pack(format, ...) -> string
    /// Packs values into a binary byte string using the LÖVE2D format string.
    /// The format prefix ``<`` / ``>`` selects little/big endian (default: little).
    /// Single-char type codes: b/B (int8/uint8), h/H (int16/uint16),
    /// i/I (int32/uint32), l/L (int64/uint64), f (float32), d (float64),
    /// z (null-terminated string), s (length-prefixed string), x (pad byte).
    /// @param format : string
    /// @return any
    data_table.set(
        "pack",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            let bd = data::pack(&fmt, &pvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // luna.data.unpack(format, data, offset?) -> values..., next_pos
    /// Unpacks values from a LÖVE2D-format binary byte string.
    /// Returns all decoded values followed by the next unread byte offset.
    /// @param format : string
    /// @param raw_data : string
    /// @param offset : integer?
    /// @return any
    data_table.set(
        "unpack",
        lua.create_function(
            |lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
                let off = offset.unwrap_or(0);
                let (values, next_pos) =
                    data::unpack(&fmt, raw.as_bytes(), off).map_err(LuaError::RuntimeError)?;
                let mut result = pack_values_to_lua(lua, values)?;
                result.push(LuaValue::Integer(next_pos as i64));
                Ok(LuaMultiValue::from_vec(result))
            },
        )?,
    )?;

    // luna.data.getPackedSize(format, ...) -> integer
    /// Returns the number of bytes the given format and values would occupy.
    /// @param format : string
    /// @return any
    data_table.set(
        "getPackedSize",
        lua.create_function(|_, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            data::get_packed_size(&fmt, &pvs)
                .map_err(LuaError::RuntimeError)
                .map(|n| n as i64)
        })?,
    )?;

    // ── Compression ─────────────────────────────────────────────────────────

    // luna.data.compress(format, data, level?)
    /// Compresses data using the given algorithm (''deflate'', ''gzip'', ''lz4'').
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
    /// Decompresses data using the given algorithm (''deflate'', ''gzip'', ''lz4'').
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

    // ── Encoding ────────────────────────────────────────────────────────────

    // luna.data.encode(format, data)
    /// Encodes binary data using the given format (''base64'', ''hex'').
    /// @param format_str : string
    /// @param raw_data : string
    /// @return any
    data_table.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format =
                data::EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;

    // luna.data.decode(format, text)
    /// Decodes encoded text back to binary using the given format (''base64'', ''hex'').
    /// @param format_str : string
    /// @param encoded : string
    /// @return any
    data_table.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format =
                data::EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // ── Hashing ─────────────────────────────────────────────────────────────

    // luna.data.hash(algorithm, data)
    /// Returns the cryptographic hash (md5, sha1, sha256, sha512) of the input.
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

    // ── ByteData + DataView ──────────────────────────────────────────────────

    // luna.data.newByteData(size_or_string)
    /// Creates a new mutable byte buffer of the given size or from a string.
    /// @param value : any
    data_table.set(
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

    // ── TOML helpers ─────────────────────────────────────────────────────────

    // luna.data.parseToml(toml_string) -> table
    /// Parses a TOML string and returns a Lua table representation.
    /// @param toml_string : string
    /// @return any
    data_table.set(
        "parseToml",
        lua.create_function(|lua, toml_string: String| {
            let val =
                data::toml_convert::parse_toml(&toml_string).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, val)
        })?,
    )?;

    // luna.data.encodeToml(table) -> string
    /// Encodes a Lua table as a TOML string.
    /// @param tbl : table
    /// @return any
    data_table.set(
        "encodeToml",
        lua.create_function(|lua, tbl: LuaTable| {
            let val = lua_table_to_toml(lua, tbl)?;
            let s = data::toml_convert::encode_toml(&val).map_err(LuaError::RuntimeError)?;
            Ok(s)
        })?,
    )?;

    // ── Luna2D Binary Pack Format ─────────────────────────────────────────────

    // luna.data.write(format, ...) -> string
    /// Writes values using the Luna2D Binary Pack Format (space-separated type tokens).
    /// @param format : string
    /// @return any
    data_table.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bvs = lua_values_to_bin(vals);
            let bd = data::bin_write(&fmt, &bvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // luna.data.read(format, data, offset?) -> ...
    /// Reads values using the Luna2D Binary Pack Format.
    /// @param format : string
    /// @param data : string
    /// @param offset : integer?
    /// @return any
    data_table.set(
        "read",
        lua.create_function(|lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
            let bytes = raw.as_bytes().to_vec();
            let (bvs, _) =
                data::bin_read(&fmt, &bytes, offset.unwrap_or(0)).map_err(LuaError::RuntimeError)?;
            let lv = bin_values_to_lua(lua, bvs)?;
            Ok(LuaMultiValue::from_vec(lv))
        })?,
    )?;

    // luna.data.size(format) -> integer
    /// Returns the byte size of a Luna2D Binary Pack Format string.
    /// @param format : string
    /// @return integer
    data_table.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;

    luna.set("data", data_table)?;
    Ok(())
}

// ── pack value helpers ────────────────────────────────────────────────────────

/// Converts a `LuaMultiValue` to a `Vec<PackValue>` for passing to the LÖVE2D pack API.
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

/// Converts a `Vec<PackValue>` back to Lua values for returning from unpack.
fn pack_values_to_lua<'lua>(
    lua: &'lua Lua,
    vals: Vec<PackValue>,
) -> LuaResult<Vec<LuaValue<'lua>>> {
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

// ── DataView userdata ─────────────────────────────────────────────────────────

/// Lua userdata wrapper for `DataView` from `crate::data`.
struct LuaDataView {
    /// The underlying read-only byte-buffer view.
    inner: DataView,
}

impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner
                .get_u8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner
                .get_i8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner
                .get_i16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner
                .get_u16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner
                .get_i32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner
                .get_u32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner
                .get_f32(offset)
                .map(|v| v as f64)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.get_size() as i64));
    }
}

// ── TOML ↔ Lua conversion helpers ────────────────────────────────────────────

/// Converts a `toml::Value` into a Lua value (table, string, integer, number, bool, or nil).
fn toml_value_to_lua<'lua>(lua: &'lua Lua, val: toml::Value) -> LuaResult<LuaValue<'lua>> {
    match val {
        toml::Value::String(s) => lua.create_string(s.as_bytes()).map(LuaValue::String),
        toml::Value::Integer(n) => Ok(LuaValue::Integer(n)),
        toml::Value::Float(f) => Ok(LuaValue::Number(f)),
        toml::Value::Boolean(b) => Ok(LuaValue::Boolean(b)),
        toml::Value::Datetime(dt) => lua
            .create_string(dt.to_string().as_bytes())
            .map(LuaValue::String),
        toml::Value::Array(arr) => {
            let tbl = lua.create_table()?;
            for (i, v) in arr.into_iter().enumerate() {
                tbl.raw_set(i + 1, toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
        toml::Value::Table(map) => {
            let tbl = lua.create_table()?;
            for (k, v) in map {
                tbl.raw_set(k, toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
    }
}

/// Converts a Lua table to a `toml::Value::Table` for encoding.
fn lua_table_to_toml<'lua>(lua: &'lua Lua, tbl: LuaTable<'lua>) -> LuaResult<toml::Value> {
    let mut map = toml::map::Map::new();
    for pair in tbl.pairs::<LuaValue, LuaValue>() {
        let (k, v) = pair?;
        let key = match k {
            LuaValue::String(s) => s
                .to_str()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                .to_string(),
            LuaValue::Integer(n) => n.to_string(),
            _ => continue,
        };
        let tv = lua_value_to_toml(lua, v)?;
        map.insert(key, tv);
    }
    Ok(toml::Value::Table(map))
}

/// Converts any Lua value to a `toml::Value` for encoding.
fn lua_value_to_toml<'lua>(lua: &'lua Lua, val: LuaValue<'lua>) -> LuaResult<toml::Value> {
    match val {
        LuaValue::String(s) => Ok(toml::Value::String(
            s.to_str()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                .to_string(),
        )),
        LuaValue::Integer(n) => Ok(toml::Value::Integer(n)),
        LuaValue::Number(f) => Ok(toml::Value::Float(f)),
        LuaValue::Boolean(b) => Ok(toml::Value::Boolean(b)),
        LuaValue::Table(t) => lua_table_to_toml(lua, t),
        LuaValue::Nil => Err(LuaError::RuntimeError(
            "cannot encode nil as TOML value".to_string(),
        )),
        _ => Err(LuaError::RuntimeError(
            "unsupported value type for TOML encoding".to_string(),
        )),
    }
}

// ── bin pack helpers ──────────────────────────────────────────────────────────

/// Converts a `LuaMultiValue` into a `Vec<BinValue>` for the Luna2D Binary Pack write API.
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

/// Converts a `Vec<BinValue>` into a `Vec<LuaValue>` for returning from the read API.
fn bin_values_to_lua<'lua>(lua: &'lua Lua, vals: Vec<BinValue>) -> LuaResult<Vec<LuaValue<'lua>>> {
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
