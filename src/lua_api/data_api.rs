//! `lurek.data` - Binary data utilities for packing, hashing, compression, and encoding.

use super::SharedState;
use indexmap::IndexMap as LuaIndexMap;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;
use std::sync::Arc;

use crate::lua_api::lua_types::LurekType;
use crate::data::toml_convert;
use crate::data::{
    self, BinValue, ByteData, CompressFormat, DataView, DataWriter, EncodeFormat, HashAlgorithm,
    LuaDataView, PackValue,
};

// -------------------------------------------------------------------------------
// Pack conversion helpers
// -------------------------------------------------------------------------------

// Converts a `LuaMultiValue` to `Vec<PackValue>` for the pack API.
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

// Converts `Vec<PackValue>` back to Lua values for returning from unpack.
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

// Converts a `LuaMultiValue` to `Vec<BinValue>` for the Lurek2D bin pack write API.
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

// Converts `Vec<BinValue>` back to Lua values for returning from read.
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

// Converts a Lua string or array-like table of strings into byte chunks.
fn lua_value_to_byte_chunks(value: LuaValue) -> LuaResult<Vec<Vec<u8>>> {
    match value {
        LuaValue::String(s) => Ok(vec![s.as_bytes().to_vec()]),
        LuaValue::Table(t) => {
            let mut chunks = Vec::new();
            for (idx, value) in t.sequence_values::<LuaValue>().enumerate() {
                let value = value?;
                match value {
                    LuaValue::String(s) => chunks.push(s.as_bytes().to_vec()),
                    _ => {
                        return Err(LuaError::RuntimeError(format!(
                            "chunk table entry #{} must be a string",
                            idx + 1
                        )))
                    }
                }
            }

            if chunks.is_empty() {
                return Err(LuaError::RuntimeError(
                    "chunk table must contain at least one string".to_string(),
                ));
            }

            Ok(chunks)
        }
        _ => Err(LuaError::RuntimeError(
            "expected a string or an array-like table of strings".to_string(),
        )),
    }
}

// -------------------------------------------------------------------------------
// LuaRingBuffer UserData
// -------------------------------------------------------------------------------

/// Lua-side fixed-capacity ring buffer that holds any Lua value.
///
/// Values are stored via Lua registry keys so the garbage collector cannot
/// collect them while the buffer holds a reference.
///
/// # Fields
/// - `inner` — Ordered queue of `LuaRegistryKey` references (front = oldest).
/// - `capacity` — Maximum number of elements before oldest is overwritten.
pub struct LuaRingBuffer {
    inner: VecDeque<LuaRegistryKey>,
    capacity: usize,
}

impl LurekType for LuaRingBuffer {
    const TYPE_NAME: &'static str = "LRingBuffer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LRingBuffer", "Object"];
}

impl LuaUserData for LuaRingBuffer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- push --
        /// Pushes a value onto the ring buffer.
        /// @param | value | any | Value to store in the buffer.
        /// @return | boolean | Whether the push overwrote the oldest element.
        methods.add_method_mut("push", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            let was_full = this.inner.len() >= this.capacity;
            if was_full {
                if let Some(old_key) = this.inner.pop_front() {
                    lua.remove_registry_value(old_key)?;
                }
            }
            this.inner.push_back(key);
            // Return true if overwrote oldest (was full), false if there was space.
            Ok(was_full)
        });

        // -- pop --
        /// Removes and returns the oldest element, or nil if the buffer is empty.
        /// @return | unknown | Oldest stored Lua value, or nil when the buffer is empty.
        methods.add_method_mut("pop", |lua, this, ()| match this.inner.pop_front() {
            Some(key) => {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            }
            None => Ok(LuaValue::Nil),
        });

        // -- peek --
        /// Returns the oldest element without removing it, or nil if empty.
        /// @return | unknown | Oldest stored Lua value, or nil when the buffer is empty.
        methods.add_method("peek", |lua, this, ()| match this.inner.front() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });

        // -- peekNewest --
        /// Returns the newest element without removing it, or nil if empty.
        /// @return | unknown | Newest stored Lua value, or nil when the buffer is empty.
        methods.add_method("peekNewest", |lua, this, ()| match this.inner.back() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });

        // -- len --
        /// Returns the number of elements currently in the buffer.
        /// @return | integer | Number of elements currently stored.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));

        // -- capacity --
        /// Returns the maximum number of elements the buffer can hold.
        /// @return | integer | Maximum capacity of the buffer.
        methods.add_method("capacity", |_, this, ()| Ok(this.capacity as i64));

        // -- isEmpty --
        /// Returns true if the buffer contains no elements.
        /// @return | boolean | True when the buffer contains no elements.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));

        // -- isFull --
        /// Returns true if the buffer has reached its capacity.
        /// @return | boolean | True when the buffer has reached capacity.
        methods.add_method(
            "isFull",
            |_, this, ()| Ok(this.inner.len() >= this.capacity),
        );

        // -- clear --
        /// Removes all elements from the buffer, releasing their registry entries.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |lua, this, ()| {
            while let Some(key) = this.inner.pop_front() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- toTable --
        /// Returns all elements as an array table ordered oldest-first.
        /// @return | table | Array table ordered from oldest element to newest.
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, key) in this.inner.iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                t.set(i + 1, v)?;
            }
            Ok(t)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name `LRingBuffer`.
        methods.add_method("type", |_, _, ()| Ok("LRingBuffer"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRingBuffer" || name == "Object")
        });

    }
}

// -------------------------------------------------------------------------------
// TOML conversion helpers
// -------------------------------------------------------------------------------

// Converts a `toml::Value` to a `LuaValue`.
fn toml_value_to_lua<'lua>(lua: &'lua Lua, value: &toml::Value) -> LuaResult<LuaValue<'lua>> {
    match value {
        toml::Value::String(s) => lua.create_string(s.as_bytes()).map(LuaValue::String),
        toml::Value::Integer(n) => Ok(LuaValue::Integer(*n)),
        toml::Value::Float(f) => Ok(LuaValue::Number(*f)),
        toml::Value::Boolean(b) => Ok(LuaValue::Boolean(*b)),
        toml::Value::Array(arr) => {
            let tbl = lua.create_table()?;
            for (i, v) in arr.iter().enumerate() {
                tbl.set(i + 1, toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
        toml::Value::Table(map) => {
            let tbl = lua.create_table()?;
            for (k, v) in map {
                tbl.set(k.as_str(), toml_value_to_lua(lua, v)?)?;
            }
            Ok(LuaValue::Table(tbl))
        }
        toml::Value::Datetime(dt) => lua
            .create_string(dt.to_string().as_bytes())
            .map(LuaValue::String),
    }
}

// Converts a `LuaValue` to a `toml::Value`.
fn lua_table_to_toml_value(value: &LuaValue) -> LuaResult<toml::Value> {
    match value {
        LuaValue::Boolean(b) => Ok(toml::Value::Boolean(*b)),
        LuaValue::Integer(n) => Ok(toml::Value::Integer(*n)),
        LuaValue::Number(f) => Ok(toml::Value::Float(*f)),
        LuaValue::String(s) => {
            let st = s
                .to_str()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            Ok(toml::Value::String(st.to_string()))
        }
        LuaValue::Table(tbl) => {
            // Determine if the table is an array (sequential integer keys starting at 1)
            // or a map (string keys).
            let len = tbl.raw_len();
            if len > 0 {
                // Check if it looks like a sequence
                let mut arr = Vec::new();
                for i in 1..=len {
                    let v: LuaValue = tbl.raw_get(i)?;
                    arr.push(lua_table_to_toml_value(&v)?);
                }
                Ok(toml::Value::Array(arr))
            } else {
                let mut map = toml::map::Map::new();
                for pair in tbl.clone().pairs::<LuaString, LuaValue>() {
                    let (k, v) = pair?;
                    let key = k
                        .to_str()
                        .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                    map.insert(key.to_string(), lua_table_to_toml_value(&v)?);
                }
                Ok(toml::Value::Table(map))
            }
        }
        _ => Err(LuaError::RuntimeError(
            "Cannot convert this Lua type to TOML".to_string(),
        )),
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.data` API table with the Lua VM.
/// @param | lua | Lua | Lua state that owns the module table.
/// @param | luna | LuaTable | Root `lurek` table that receives the `data` module.
/// @param | _state | SharedState | Shared engine state handle passed through registration.
/// @return | nil | Registers the module in place.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- pack --
    /// Packs values into a binary byte string using the format string.
    /// @param | format | string | Pack format string.
    /// @param | ... | any | Values to encode using the format string.
    /// @return | string | Packed bytes as a Lua string.
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
    /// @param | format | string | Pack format string.
    /// @param | data | string | Packed byte string to read from.
    /// @param | offset | integer? | Optional starting byte offset.
    /// @return | unknown | Unpacked Lua value or values.
    /// @return | integer | Next byte offset after the unpacked values.
    tbl.set(
        "unpack",
        lua.create_function(
            |lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
                let (values, next_pos) = data::unpack(&fmt, raw.as_bytes(), offset.unwrap_or(0))
                    .map_err(LuaError::RuntimeError)?;
                let mut result = pack_values_to_lua(lua, values)?;
                result.push(LuaValue::Integer(next_pos as i64));
                Ok(LuaMultiValue::from_vec(result))
            },
        )?,
    )?;

    // -- getPackedSize --
    /// Returns the number of bytes the given format and values would occupy.
    /// @param | format | string | Pack format string.
    /// @param | ... | any | Values whose packed size should be measured.
    /// @return | integer | Total packed size in bytes.
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
    /// Compresses data using the given algorithm (deflate, gzip, lz4, zlib).
    /// @param | format | string | Compression format name.
    /// @param | data | string | Raw bytes to compress.
    /// @param | level | integer? | Optional compression level.
    /// @return | string | Compressed bytes as a Lua string.
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
    /// Decompresses data using the given algorithm (deflate, gzip, lz4, zlib).
    /// @param | format | string | Compression format name.
    /// @param | data | string | Compressed bytes to decompress.
    /// @return | string | Decompressed bytes as a Lua string.
    tbl.set(
        "decompress",
        lua.create_function(|lua, (format_str, compressed): (String, LuaString)| {
            let format = CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result =
                data::decompress(compressed.as_bytes(), format).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // -- compressChunks --
    /// Compresses string chunks using the given algorithm (deflate, gzip, lz4, zlib).
    /// @param | format | string | Compression format name.
    /// @param | chunks | string | table | Byte string or array-like table of byte strings.
    /// @param | level | integer? | Optional compression level.
    /// @return | string | Compressed bytes as a Lua string.
    tbl.set(
        "compressChunks",
        lua.create_function(
            |lua, (format_str, chunks, level): (String, LuaValue, Option<u32>)| {
                let format =
                    CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
                let chunks = lua_value_to_byte_chunks(chunks)?;
                let chunk_refs: Vec<&[u8]> = chunks.iter().map(|c| c.as_slice()).collect();
                let result = data::compress_chunks(&chunk_refs, format, level.unwrap_or(6))
                    .map_err(LuaError::RuntimeError)?;
                lua.create_string(&result)
            },
        )?,
    )?;

    // -- decompressChunks --
    /// Decompresses compressed string chunks using the given algorithm (deflate, gzip, lz4, zlib).
    /// @param | format | string | Compression format name.
    /// @param | chunks | string | table | Compressed byte string or array-like table of byte strings.
    /// @return | string | Decompressed bytes as a Lua string.
    tbl.set(
        "decompressChunks",
        lua.create_function(|lua, (format_str, chunks): (String, LuaValue)| {
            let format = CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let chunks = lua_value_to_byte_chunks(chunks)?;
            let chunk_refs: Vec<&[u8]> = chunks.iter().map(|c| c.as_slice()).collect();
            let result =
                data::decompress_chunks(&chunk_refs, format).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // -- encode --
    /// Encodes binary data using the given format (base64, hex).
    /// @param | format | string | Encoding format name.
    /// @param | data | string | Raw bytes to encode.
    /// @return | string | Encoded text.
    tbl.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;

    // -- decode --
    /// Decodes encoded text back to binary (base64, hex).
    /// @param | format | string | Encoding format name.
    /// @param | encoded | string | Encoded text to decode.
    /// @return | string | Decoded raw bytes as a Lua string.
    tbl.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;

    // -- hash --
    /// Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
    /// @param | algorithm | string | Hash algorithm name.
    /// @param | data | string | Raw bytes to hash.
    /// @return | string | Hex-encoded digest string.
    tbl.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;

    // -- crc32 --
    /// Returns the CRC-32 checksum of the input data as an integer.
    /// @param | data | string | Input bytes to checksum.
    /// @return | integer | CRC-32 value in the range `[0, 2^32)`.
    tbl.set(
        "crc32",
        lua.create_function(|_, raw_data: LuaString| Ok(data::crc32(raw_data.as_bytes())))?,
    )?;

    // -- newByteData --
    /// Instantiates a raw byte data container object.
    /// @param | value | integer | number | string source data, or buffer size in bytes.
    /// @return | ByteData | New byte buffer instance.
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
    /// @param | data | string | Source byte string.
    /// @param | offset | integer? | Optional starting byte offset.
    /// @param | size | integer? | Optional view size in bytes.
    /// @return | LDataView | New read-only data view.
    tbl.set(
        "newDataView",
        lua.create_function(
            |lua, (raw, offset, size): (LuaString, Option<usize>, Option<usize>)| {
                let bytes: Arc<Vec<u8>> = Arc::new(raw.as_bytes().to_vec());
                let total = bytes.len();
                let off = offset.unwrap_or(0);
                let sz = size.unwrap_or_else(|| total.saturating_sub(off));
                let dv = DataView::new_slice(bytes, off, sz).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaDataView::new(dv))
            },
        )?,
    )?;

    // -- write --
    /// Writes values using the Lurek2D Binary Pack Format.
    /// @param | format | string | Binary pack format string.
    /// @param | ... | any | Values to write using the binary format.
    /// @return | string | Packed bytes as a Lua string.
    tbl.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bvs = lua_values_to_bin(vals);
            let bd = data::bin_write(&fmt, &bvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;

    // -- read --
    /// Reads values using the Lurek2D Binary Pack Format.
    /// @param | format | string | Binary pack format string.
    /// @param | data | string | Packed byte string to read from.
    /// @param | offset | integer? | Optional starting byte offset.
    /// @return | unknown | Decoded Lua values.
    tbl.set(
        "read",
        lua.create_function(
            |lua, (fmt, raw, offset): (String, LuaString, Option<usize>)| {
                let (bvs, _) = data::bin_read(&fmt, raw.as_bytes(), offset.unwrap_or(0))
                    .map_err(LuaError::RuntimeError)?;
                let lv = bin_values_to_lua(lua, bvs)?;
                Ok(LuaMultiValue::from_vec(lv))
            },
        )?,
    )?;

    // -- size --
    /// Returns the byte size of a Lurek2D Binary Pack Format string.
    /// @param | format | string | Binary pack format string.
    /// @return | integer | Size of the format in bytes.
    tbl.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- parseToml --
    /// Parses a TOML string into a Lua table.
    /// @param | text | string | TOML document text.
    /// @return | table | Parsed TOML value as a Lua table.
    tbl.set(
        "parseToml",
        lua.create_function(|lua, text: String| {
            let value = toml_convert::parse_toml(&text).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;

    // -- encodeToml --
    /// Encodes a Lua table into a TOML string.
    /// @param | tbl | table | Lua table to encode as TOML.
    /// @return | string | Encoded TOML document text.
    tbl.set(
        "encodeToml",
        lua.create_function(|_, tbl: LuaTable| {
            let value = lua_table_to_toml_value(&LuaValue::Table(tbl))?;
            toml_convert::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- newRingBuffer --
    /// Creates a fixed-capacity ring buffer that can store any Lua value.
    /// @param | capacity | integer | Maximum number of elements to retain.
    /// @return | LRingBuffer | New ring buffer instance.
    tbl.set(
        "newRingBuffer",
        lua.create_function(|_, capacity: usize| {
            if capacity == 0 {
                return Err(LuaError::RuntimeError(
                    "newRingBuffer: capacity must be greater than 0".to_string(),
                ));
            }
            Ok(LuaRingBuffer {
                inner: VecDeque::with_capacity(capacity),
                capacity,
            })
        })?,
    )?;

    // -- toMsgPack --
    /// Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
    /// @param | value | any | Lua value to serialize.
    /// @return | string | MessagePack bytes as a Lua string.
    tbl.set(
        "toMsgPack",
        lua.create_function(|lua, value: LuaValue| {
            let serial = crate::serial::lua_table::from_lua(&value).map_err(LuaError::external)?;
            let json_val = serial_value_to_json(&serial);
            let bytes =
                crate::data::msgpack::to_msgpack(&json_val).map_err(LuaError::RuntimeError)?;
            lua.create_string(&bytes)
        })?,
    )?;

    // -- fromMsgPack --
    /// Deserializes a MessagePack binary string back into a Lua value.
    /// @param | bytes | string | MessagePack bytes to decode.
    /// @return | unknown | Decoded Lua value.
    tbl.set(
        "fromMsgPack",
        lua.create_function(|lua, bytes: LuaString| {
            let raw: &[u8] = bytes.as_bytes();
            let json_val =
                crate::data::msgpack::from_msgpack(raw).map_err(LuaError::RuntimeError)?;
            let serial = json_value_to_serial(&json_val);
            crate::serial::lua_table::to_lua(lua, &serial)
        })?,
    )?;

    // -- newWriter --
    /// Creates a new write-cursor for building binary data.
    /// @return | LDataWriter | New binary data writer.
    tbl.set(
        "newWriter",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaDataWriter {
                inner: DataWriter::new(),
            })
        })?,
    )?;

    luna.set("data", tbl)?;
    Ok(())
}

// Converts a `crate::serial::lua_table::SerialValue` to a `serde_json::Value`.
//
// Used internally by the MessagePack API bridge.
fn serial_value_to_json(sv: &crate::serial::lua_table::SerialValue) -> serde_json::Value {
    use crate::serial::lua_table::SerialValue;
    match sv {
        SerialValue::Null => serde_json::Value::Null,
        SerialValue::Bool(b) => serde_json::Value::Bool(*b),
        SerialValue::Int(n) => serde_json::Value::Number((*n).into()),
        SerialValue::Float(f) => serde_json::Number::from_f64(*f)
            .map(serde_json::Value::Number)
            .unwrap_or(serde_json::Value::Null),
        SerialValue::Str(s) => serde_json::Value::String(s.clone()),
        SerialValue::Seq(arr) => {
            serde_json::Value::Array(arr.iter().map(serial_value_to_json).collect())
        }
        SerialValue::Map(map) => {
            let obj: serde_json::Map<String, serde_json::Value> = map
                .iter()
                .map(|(k, v)| (k.clone(), serial_value_to_json(v)))
                .collect();
            serde_json::Value::Object(obj)
        }
    }
}

// Converts a `serde_json::Value` back into a `crate::serial::lua_table::SerialValue`.
//
// Used internally by the MessagePack API bridge.
fn json_value_to_serial(val: &serde_json::Value) -> crate::serial::lua_table::SerialValue {
    use crate::serial::lua_table::SerialValue;
    match val {
        serde_json::Value::Null => SerialValue::Null,
        serde_json::Value::Bool(b) => SerialValue::Bool(*b),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                SerialValue::Int(i)
            } else if let Some(f) = n.as_f64() {
                SerialValue::Float(f)
            } else {
                SerialValue::Int(0)
            }
        }
        serde_json::Value::String(s) => SerialValue::Str(s.clone()),
        serde_json::Value::Array(arr) => {
            SerialValue::Seq(arr.iter().map(json_value_to_serial).collect())
        }
        serde_json::Value::Object(obj) => {
            let mut map = LuaIndexMap::new();
            for (k, v) in obj {
                map.insert(k.clone(), json_value_to_serial(v));
            }
            SerialValue::Map(map)
        }
    }
}

/// Access structured binary data efficiently without copying.
impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getUInt8 --
        /// Reads an unsigned 8-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Unsigned 8-bit value.
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner
                .get_u8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt8 --
        /// Reads a signed 8-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Signed 8-bit value.
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner
                .get_i8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt16 --
        /// Reads a signed 16-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Signed 16-bit value.
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner
                .get_i16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt16 --
        /// Reads an unsigned 16-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Unsigned 16-bit value.
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner
                .get_u16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt32 --
        /// Reads a signed 32-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Signed 32-bit value.
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner
                .get_i32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt32 --
        /// Reads an unsigned 32-bit integer at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | integer | Unsigned 32-bit value.
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner
                .get_u32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getFloat --
        /// Reads a 32-bit float at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | number | 32-bit floating-point value.
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner
                .get_f32(offset)
                .map(|v| v as f64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getDouble --
        /// Reads a 64-bit float at the given offset.
        /// @param | offset | integer | Byte offset relative to the view start.
        /// @return | number | 64-bit floating-point value.
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });

        // -- getSize --
        /// Returns the size of this view in bytes.
        /// @return | integer | Size of this view in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.get_size() as i64));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name `LDataView`.
        methods.add_method("type", |_, _, ()| Ok("LDataView"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataView" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaDataWriter
// -------------------------------------------------------------------------------

/// Write-cursor wrapper for the `lurek.data` module.
pub struct LuaDataWriter {
    pub(crate) inner: DataWriter,
}

impl LuaUserData for LuaDataWriter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- writeU8 --
        /// Writes an unsigned 8-bit integer.
        /// @param | value | integer | Unsigned 8-bit value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU8", |_, this, v: u8| {
            this.inner.write_u8(v);
            Ok(())
        });
        // -- writeI8 --
        /// Writes a signed 8-bit integer.
        /// @param | value | integer | Signed 8-bit value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI8", |_, this, v: i8| {
            this.inner.write_i8(v);
            Ok(())
        });
        // -- writeU16LE --
        /// Writes an unsigned 16-bit LE integer.
        /// @param | value | integer | Unsigned 16-bit value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU16LE", |_, this, v: u16| {
            this.inner.write_u16_le(v);
            Ok(())
        });
        // -- writeU16BE --
        /// Writes an unsigned 16-bit BE integer.
        /// @param | value | integer | Unsigned 16-bit value to write in big-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU16BE", |_, this, v: u16| {
            this.inner.write_u16_be(v);
            Ok(())
        });
        // -- writeI16LE --
        /// Writes a signed 16-bit LE integer.
        /// @param | value | integer | Signed 16-bit value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI16LE", |_, this, v: i16| {
            this.inner.write_i16_le(v);
            Ok(())
        });
        // -- writeU32LE --
        /// Writes an unsigned 32-bit LE integer.
        /// @param | value | integer | Unsigned 32-bit value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU32LE", |_, this, v: u32| {
            this.inner.write_u32_le(v);
            Ok(())
        });
        // -- writeI32LE --
        /// Writes a signed 32-bit LE integer.
        /// @param | value | integer | Signed 32-bit value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI32LE", |_, this, v: i32| {
            this.inner.write_i32_le(v);
            Ok(())
        });
        // -- writeF32LE --
        /// Writes a 32-bit LE float.
        /// @param | value | number | 32-bit float value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeF32LE", |_, this, v: f32| {
            this.inner.write_f32_le(v);
            Ok(())
        });
        // -- writeF64LE --
        /// Writes a 64-bit LE float.
        /// @param | value | number | 64-bit float value to write in little-endian order.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeF64LE", |_, this, v: f64| {
            this.inner.write_f64_le(v);
            Ok(())
        });
        // -- writeString --
        /// Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
        /// @param | value | string | UTF-8 string to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeString", |_, this, s: String| {
            this.inner.write_string(&s);
            Ok(())
        });
        // -- writeBytes --
        /// Writes raw bytes from a Lua string.
        /// @param | value | string | Raw bytes to append.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeBytes", |_, this, s: mlua::String| {
            this.inner.write_bytes(s.as_bytes());
            Ok(())
        });
        // -- seek --
        /// Moves the write cursor to the given position.
        /// @param | pos | integer | New write cursor position.
        /// @return | nil | No value is returned.
        methods.add_method_mut("seek", |_, this, pos: usize| {
            this.inner.seek(pos);
            Ok(())
        });
        // -- tell --
        /// Returns the current write cursor position.
        /// @return | integer | Current write cursor position.
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));
        // -- len --
        /// Returns the total buffer length.
        /// @return | integer | Total buffer length in bytes.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- toBytes --
        /// Returns the buffer contents as a Lua string.
        /// @return | string | Buffer contents as raw bytes.
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.inner.as_bytes())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name `LDataWriter`.
        methods.add_method("type", |_, _, ()| Ok("LDataWriter"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataWriter" || name == "Object")
        });
    }
}

/// Raw byte buffer for binary I/O; addressable by byte or bit offset.
impl mlua::UserData for ByteData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── getSize ──────────────────────────────────────────────
        /// Returns the total byte length of this buffer.
        /// @return | integer | Total byte length of the buffer.
        methods.add_method("getSize", |_, this, ()| Ok(this.len()));
        // ── getString ──────────────────────────────────────────────
        /// Get the string representation.
        /// @return | string | Buffer contents interpreted as a lossy UTF-8 string.
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        // ── getByte ──────────────────────────────────────────────
        /// Get a byte at the specified offset.
        /// @param | offset | integer | Zero-based byte offset.
        /// @return | integer | Byte value at the requested offset.
        methods.add_method("getByte", |_, this, offset: usize| {
            this.get_byte(offset).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                ))
            })
        });
        // ── setByte ──────────────────────────────────────────────
        /// Set a byte at the specified offset.
        /// @param | offset | integer | Zero-based byte offset.
        /// @param | value | integer | Byte value to store.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setByte", |_, this, (offset, value): (usize, u8)| {
            if this.set_byte(offset, value) {
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                )))
            }
        });
        // ── clone ──────────────────────────────────────────────
        /// Creates an independent copy of this byte buffer with identical contents.
        /// @return | ByteData | Cloned byte buffer.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(this.clone_data())
        });

        // -- setBit --
        /// Sets or clears a single bit within the buffer.
        /// @param | byte_offset | integer | Zero-based byte index.
        /// @param | bit_offset | integer | Bit index within the byte in the range `[0, 7]`.
        /// @param | value | boolean | True to set the bit, false to clear it.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setBit",
            |_, this, (byte_offset, bit_offset, value): (usize, u8, bool)| {
                if byte_offset >= this.len() {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.data: setBit byte_offset {} out of range (size={})",
                        byte_offset,
                        this.len()
                    )));
                }
                if bit_offset > 7 {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.data: setBit bit_offset {} out of range [0..7]",
                        bit_offset
                    )));
                }
                let current = this.get_byte(byte_offset).unwrap();
                let new_val = if value {
                    current | (1u8 << bit_offset)
                } else {
                    current & !(1u8 << bit_offset)
                };
                this.set_byte(byte_offset, new_val);
                Ok(())
            },
        );

        // -- getBit --
        /// Returns the value of a single bit within the buffer.
        /// @param | byte_offset | integer | Zero-based byte index.
        /// @param | bit_offset | integer | Bit index within the byte in the range `[0, 7]`.
        /// @return | boolean | Bit value at the requested position.
        methods.add_method(
            "getBit",
            |_, this, (byte_offset, bit_offset): (usize, u8)| {
                if byte_offset >= this.len() {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.data: getBit byte_offset {} out of range (size={})",
                        byte_offset,
                        this.len()
                    )));
                }
                if bit_offset > 7 {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.data: getBit bit_offset {} out of range [0..7]",
                        bit_offset
                    )));
                }
                let byte = this.get_byte(byte_offset).unwrap();
                Ok((byte >> bit_offset) & 1 == 1)
            },
        );

        // -- readBits --
        /// Reads consecutive bits and packs them into a 32-bit integer.
        /// @param | byte_offset | integer | Zero-based starting byte index.
        /// @param | bit_offset | integer | Starting bit within the starting byte in the range `[0, 7]`.
        /// @param | count | integer | Number of bits to read in the range `[1, 32]`.
        /// @return | integer | Bits packed LSB-first into a 32-bit integer.
        methods.add_method(
            "readBits",
            |_, this, (byte_offset, bit_offset, count): (usize, u8, u8)| {
                if count == 0 || count > 32 {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.data: readBits count {} out of range [1..32]",
                        count
                    )));
                }
                let mut result: u32 = 0;
                for i in 0..count {
                    let total_bit = bit_offset as usize + i as usize;
                    let b = byte_offset + total_bit / 8;
                    let bit = (total_bit % 8) as u8;
                    if b >= this.len() {
                        return Err(LuaError::RuntimeError(format!(
                            "lurek.data: readBits reads beyond buffer end (size={})",
                            this.len()
                        )));
                    }
                    let byte = this.get_byte(b).unwrap();
                    if (byte >> bit) & 1 == 1 {
                        result |= 1u32 << i;
                    }
                }
                Ok(result)
            },
        );
    }
}
