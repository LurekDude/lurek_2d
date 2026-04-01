//! Registers the `luna.data.*` binary data, compression, hashing, and encoding API.

use mlua::prelude::*;

use crate::data::{self, ByteData};

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
    data_table.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = data::HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;

    // luna.data.encode(format, data)
    /// Encodes Lua values into a binary string using a pack-format string.
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
    ///
    /// # Parameters
    /// - `format` — Pack-format string (same syntax as string.pack).
    /// - `data` — Binary string or ByteData buffer to read from.
    ///
    /// # Returns
    /// Decoded Lua values followed by the next unread byte offset.
    data_table.set(
        "decode",
        lua.create_function(|_, (format_str, encoded): (String, String)| {
            let format =
                data::EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            Ok(result)
        })?,
    )?;

    // luna.data.parseToml(str) -> table
    /// Parses a TOML string and returns a Lua table.
    data_table.set(
        "parseToml",
        lua.create_function(|lua, input: String| {
            let value = data::toml_convert::parse_toml(&input).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;

    // luna.data.encodeToml(tbl) -> string
    /// Encodes a Lua table as a TOML string.
    data_table.set(
        "encodeToml",
        lua.create_function(|_, table: LuaTable| {
            let value = lua_table_to_toml_value(&table)?;
            data::toml_convert::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
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
