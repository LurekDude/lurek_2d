//! `lurek.data` -- Data bindings for binary packing, compression, encoding, hashing, byte buffers, data views, TOML conversion, ring buffers, and structured writers.

use super::SharedState;
use crate::data::{
    self, BinValue, ByteData, CompressFormat, DataView, DataWriter, EncodeFormat, HashAlgorithm,
    LuaDataView, PackValue,
};
use crate::lua_api::lua_types::LurekType;
use crate::serial;
use indexmap::IndexMap as LuaIndexMap;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;
use std::sync::Arc;
/// Converts Lua varargs into binary pack values.
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
/// Converts binary pack values into Lua return values.
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
/// Converts Lua varargs into binary reader and writer values.
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
/// Converts binary reader values into Lua return values.
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
/// Converts a Lua string or table of strings into byte chunks.
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
/// Lua-side fixed-capacity FIFO buffer that stores registry-protected Lua values.
pub struct LuaRingBuffer {
    /// Stored Lua registry keys in oldest-to-newest order.
    inner: VecDeque<LuaRegistryKey>,
    /// Maximum number of values retained by the buffer.
    capacity: usize,
}
impl LurekType for LuaRingBuffer {
    const TYPE_NAME: &'static str = "LRingBuffer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LRingBuffer", "Object"];
}
impl LuaUserData for LuaRingBuffer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- push --
        /// Pushes a value into the ring buffer and evicts the oldest value when full.
        /// @param | value | any | Lua value to store in the buffer.
        /// @return | boolean | True when the push evicted an older value.
        methods.add_method_mut("push", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            let was_full = this.inner.len() >= this.capacity;
            if was_full {
                if let Some(old_key) = this.inner.pop_front() {
                    lua.remove_registry_value(old_key)?;
                }
            }
            this.inner.push_back(key);
            Ok(was_full)
        });
        // -- pop --
        /// Removes and returns the oldest stored value from the ring buffer.
        /// @return | LuaValue | Oldest stored value, or nil when the buffer is empty.
        methods.add_method_mut("pop", |lua, this, ()| match this.inner.pop_front() {
            Some(key) => {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            }
            None => Ok(LuaValue::Nil),
        });
        // -- peek --
        /// Returns the oldest stored value without removing it from the ring buffer.
        /// @return | LuaValue | Oldest stored value, or nil when the buffer is empty.
        methods.add_method("peek", |lua, this, ()| match this.inner.front() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });
        // -- peekNewest --
        /// Returns the newest stored value without removing it from the ring buffer.
        /// @return | LuaValue | Newest stored value, or nil when the buffer is empty.
        methods.add_method("peekNewest", |lua, this, ()| match this.inner.back() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });
        // -- len --
        /// Returns the number of values currently stored.
        /// @return | integer | Current buffer length.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));
        // -- capacity --
        /// Returns the maximum capacity of the ring buffer.
        /// @return | integer | Maximum number of stored values.
        methods.add_method("capacity", |_, this, ()| Ok(this.capacity as i64));
        // -- isEmpty --
        /// Returns whether the ring buffer has no values.
        /// @return | boolean | True when the buffer is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));
        // -- isFull --
        /// Returns whether the ring buffer is at capacity.
        /// @return | boolean | True when the buffer length is at least its capacity.
        methods.add_method(
            "isFull",
            |_, this, ()| Ok(this.inner.len() >= this.capacity),
        );
        // -- clear --
        /// Removes every stored value and releases their registry keys.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |lua, this, ()| {
            while let Some(key) = this.inner.pop_front() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- toTable --
        /// Returns stored values in oldest-to-newest order.
        /// @return | table | Array table of stored values.
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, key) in this.inner.iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                t.set(i + 1, v)?;
            }
            Ok(t)
        });
        // -- type --
        /// Returns the Lua-visible type name for this ring buffer handle.
        /// @return | string | The string `LRingBuffer`.
        methods.add_method("type", |_, _, ()| Ok("LRingBuffer"));
        // -- typeOf --
        /// Returns whether this ring buffer handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LRingBuffer` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRingBuffer" || name == "Object")
        });
    }
}
/// Converts a TOML value into a Lua value.
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
/// Converts a Lua value into a TOML value.
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
            let len = tbl.raw_len();
            if len > 0 {
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
/// Registers the `lurek.data` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- pack --
    /// Packs Lua values into a binary string using a format string.
    /// @param | fmt | string | Binary pack format string.
    /// @param | ... | any | Values to pack according to the format.
    /// @return | string | Packed binary byte string.
    tbl.set(
        "pack",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            let bd = data::pack(&fmt, &pvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;
    // -- unpack --
    /// Unpacks values from a binary string using a format string.
    /// @param | fmt | string | Binary unpack format string.
    /// @param | raw | string | Binary byte string to unpack.
    /// @param | offset | integer? | Optional zero-based byte offset; defaults to zero.
    /// @return | LuaValue | Unpacked values followed by the next byte offset.
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
    /// Computes the packed byte size for values and a format string.
    /// @param | fmt | string | Binary pack format string.
    /// @param | ... | any | Values measured according to the format.
    /// @return | integer | Packed byte size.
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
    /// Compresses a binary string using a named compression format.
    /// @param | format_str | string | Compression format name.
    /// @param | raw_data | string | Raw binary data to compress.
    /// @param | level | integer? | Optional compression level; defaults to 6.
    /// @return | string | Compressed binary byte string.
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
    /// Decompresses a binary string using a named compression format.
    /// @param | format_str | string | Compression format name.
    /// @param | compressed | string | Compressed binary data.
    /// @return | string | Decompressed binary byte string.
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
    /// Compresses a string or table of strings as a chunked byte stream.
    /// @param | format_str | string | Compression format name.
    /// @param | chunks | any | Binary string or array table of binary strings.
    /// @param | level | integer? | Optional compression level; defaults to 6.
    /// @return | string | Compressed binary byte string.
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
    /// Decompresses a string or table of strings as a chunked byte stream.
    /// @param | format_str | string | Compression format name.
    /// @param | chunks | any | Binary string or array table of binary strings.
    /// @return | string | Decompressed binary byte string.
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
    /// Encodes a binary string using a named text encoding format.
    /// @param | format_str | string | Encoding format name.
    /// @param | raw_data | string | Raw binary data to encode.
    /// @return | string | Encoded string.
    tbl.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;
    // -- decode --
    /// Decodes a string using a named text encoding format.
    /// @param | format_str | string | Encoding format name.
    /// @param | encoded | string | Encoded string to decode.
    /// @return | string | Decoded binary byte string.
    tbl.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;
    // -- hash --
    /// Hashes a binary string with a named algorithm.
    /// @param | algo_str | string | Hash algorithm name.
    /// @param | raw_data | string | Raw binary data to hash.
    /// @return | string | Hash digest string.
    tbl.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;
    // -- crc32 --
    /// Computes CRC32 for a binary string.
    /// @param | raw_data | string | Raw binary data to checksum.
    /// @return | integer | CRC32 checksum value.
    tbl.set(
        "crc32",
        lua.create_function(|_, raw_data: LuaString| Ok(data::crc32(raw_data.as_bytes())))?,
    )?;
    // -- newByteData --
    /// Creates ByteData from a size or string.
    /// @param | value | any | Integer size for zeroed bytes, or string used as initial bytes.
    /// @return | LByteData | New LByteData userdata.
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
    /// Creates a DataView over a binary string slice.
    /// @param | raw | string | Binary byte string backing the view.
    /// @param | offset | integer? | Optional zero-based start offset; defaults to zero.
    /// @param | size | integer? | Optional view size in bytes; defaults to the remaining bytes.
    /// @return | LDataView | New data view handle.
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
    /// Writes binary values into a byte string using a format string.
    /// @param | fmt | string | Binary writer format string.
    /// @param | ... | any | Values to write according to the format.
    /// @return | string | Binary byte string containing written values.
    tbl.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bvs = lua_values_to_bin(vals);
            let bd = data::bin_write(&fmt, &bvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;
    // -- read --
    /// Reads binary values from a byte string using a format string.
    /// @param | fmt | string | Binary reader format string.
    /// @param | raw | string | Binary byte string to read.
    /// @param | offset | integer? | Optional zero-based byte offset; defaults to zero.
    /// @return | LuaValue | Values read from the byte string.
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
    /// Measures fixed byte size for a binary format string.
    /// @param | fmt | string | Binary format string to measure.
    /// @return | integer | Fixed byte size for the format.
    tbl.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;
    // -- parseToml --
    /// Parses TOML text into Lua tables and scalar values.
    /// @param | text | string | TOML document text.
    /// @return | table | Lua representation of the TOML document.
    tbl.set(
        "parseToml",
        lua.create_function(|lua, text: String| {
            let value = serial::parse_toml(&text).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;
    // -- encodeToml --
    /// Encodes a Lua table into a TOML document string.
    /// @param | tbl | table | Lua table to encode as TOML.
    /// @return | string | TOML document text.
    tbl.set(
        "encodeToml",
        lua.create_function(|_, tbl: LuaTable| {
            let value = lua_table_to_toml_value(&LuaValue::Table(tbl))?;
            serial::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
    )?;
    // -- newRingBuffer --
    /// Creates a fixed-capacity ring buffer for Lua values.
    /// @param | capacity | integer | Maximum value count; must be greater than zero.
    /// @return | LRingBuffer | New ring buffer handle.
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
    /// Encodes a Lua value into the current structured binary interchange payload.
    /// @param | value | any | Lua value to encode through the serial table converter.
    /// @return | string | Encoded binary payload.
    tbl.set(
        "toMsgPack",
        lua.create_function(|lua, value: LuaValue| {
            let serial_val =
                crate::serial::lua_table::from_lua(&value).map_err(LuaError::external)?;
            let json_val = serial_value_to_json(&serial_val);
            let bytes = crate::serial::encode_json(&json_val).map_err(LuaError::RuntimeError)?;
            lua.create_string(&bytes)
        })?,
    )?;
    // -- fromMsgPack --
    /// Decodes a structured binary interchange payload back into Lua values.
    /// @param | bytes | string | Encoded binary payload.
    /// @return | LuaValue | Decoded Lua value.
    tbl.set(
        "fromMsgPack",
        lua.create_function(|lua, bytes: LuaString| {
            let raw: &[u8] = bytes.as_bytes();
            let json_val = crate::serial::decode_json(raw).map_err(LuaError::RuntimeError)?;
            let serial = json_value_to_serial(&json_val);
            crate::serial::lua_table::to_lua(lua, &serial)
        })?,
    )?;
    // -- newWriter --
    /// Creates an empty binary data writer.
    /// @return | LDataWriter | New data writer handle.
    tbl.set(
        "newWriter",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaDataWriter {
                inner: DataWriter::new(),
            })
        })?,
    )?;
    /// Performs the 'data' operation.
    /// @return | nil | No value is returned.
    luna.set("data", tbl)?;
    Ok(())
}
/// Converts a serial Lua-table value into JSON for binary payload encoding.
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
/// Converts JSON into the serial Lua-table value representation.
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
impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getUInt8 --
        /// Reads an unsigned 8-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Unsigned 8-bit value.
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner
                .get_u8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getInt8 --
        /// Reads a signed 8-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Signed 8-bit value.
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner
                .get_i8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getInt16 --
        /// Reads a signed 16-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Signed 16-bit value.
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner
                .get_i16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getUInt16 --
        /// Reads an unsigned 16-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Unsigned 16-bit value.
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner
                .get_u16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getInt32 --
        /// Reads a signed 32-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Signed 32-bit value.
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner
                .get_i32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getUInt32 --
        /// Reads an unsigned 32-bit integer at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | integer | Unsigned 32-bit value.
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner
                .get_u32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getFloat --
        /// Reads a 32-bit float at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | number | 32-bit float value converted to Lua number.
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner
                .get_f32(offset)
                .map(|v| v as f64)
                .map_err(LuaError::RuntimeError)
        });
        // -- getDouble --
        /// Reads a 64-bit float at a byte offset.
        /// @param | offset | integer | Zero-based byte offset inside the view.
        /// @return | number | 64-bit float value.
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });
        // -- getSize --
        /// Returns this data view size in bytes.
        /// @return | integer | View size in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.get_size() as i64));
        // -- type --
        /// Returns the Lua-visible type name for this data view handle.
        /// @return | string | The string `LDataView`.
        methods.add_method("type", |_, _, ()| Ok("LDataView"));
        // -- typeOf --
        /// Returns whether this data view handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LDataView` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataView" || name == "Object")
        });
    }
}
/// Lua-side binary writer for sequential byte construction.
pub struct LuaDataWriter {
    /// Owned writer buffer and cursor.
    pub(crate) inner: DataWriter,
}
impl LuaUserData for LuaDataWriter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- writeU8 --
        /// Appends an unsigned 8-bit integer to the writer buffer.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU8", |_, this, v: u8| {
            this.inner.write_u8(v);
            Ok(())
        });
        // -- writeI8 --
        /// Appends a signed 8-bit integer to the writer buffer.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI8", |_, this, v: i8| {
            this.inner.write_i8(v);
            Ok(())
        });
        // -- writeU16LE --
        /// Appends an unsigned 16-bit integer in little-endian byte order.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU16LE", |_, this, v: u16| {
            this.inner.write_u16_le(v);
            Ok(())
        });
        // -- writeU16BE --
        /// Appends an unsigned 16-bit integer in big-endian byte order.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU16BE", |_, this, v: u16| {
            this.inner.write_u16_be(v);
            Ok(())
        });
        // -- writeI16LE --
        /// Appends a signed 16-bit integer in little-endian byte order.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI16LE", |_, this, v: i16| {
            this.inner.write_i16_le(v);
            Ok(())
        });
        // -- writeU32LE --
        /// Appends an unsigned 32-bit integer in little-endian byte order.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeU32LE", |_, this, v: u32| {
            this.inner.write_u32_le(v);
            Ok(())
        });
        // -- writeI32LE --
        /// Appends a signed 32-bit integer in little-endian byte order.
        /// @param | v | integer | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeI32LE", |_, this, v: i32| {
            this.inner.write_i32_le(v);
            Ok(())
        });
        // -- writeF32LE --
        /// Appends a 32-bit float value in little-endian byte order.
        /// @param | v | number | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeF32LE", |_, this, v: f32| {
            this.inner.write_f32_le(v);
            Ok(())
        });
        // -- writeF64LE --
        /// Appends a 64-bit float value in little-endian byte order.
        /// @param | v | number | Value to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeF64LE", |_, this, v: f64| {
            this.inner.write_f64_le(v);
            Ok(())
        });
        // -- writeString --
        /// Appends a UTF-8 encoded string to the writer buffer.
        /// @param | s | string | String contents to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeString", |_, this, s: String| {
            this.inner.write_string(&s);
            Ok(())
        });
        // -- writeBytes --
        /// Appends raw bytes from a Lua string to the writer buffer.
        /// @param | s | string | Raw byte string to write.
        /// @return | nil | No value is returned.
        methods.add_method_mut("writeBytes", |_, this, s: mlua::String| {
            this.inner.write_bytes(s.as_bytes());
            Ok(())
        });
        // -- seek --
        /// Moves the writer cursor to a specific byte position.
        /// @param | pos | integer | New cursor position in bytes.
        /// @return | nil | No value is returned.
        methods.add_method_mut("seek", |_, this, pos: usize| {
            this.inner.seek(pos);
            Ok(())
        });
        // -- tell --
        /// Returns the writer cursor position.
        /// @return | integer | Current cursor position in bytes.
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));
        // -- len --
        /// Returns the current length of the writer buffer.
        /// @return | integer | Buffer length in bytes.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- toBytes --
        /// Returns the writer buffer as a binary string.
        /// @return | string | Binary byte string containing writer contents.
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.inner.as_bytes())
        });
        // -- type --
        /// Returns the Lua-visible type name for this data writer handle.
        /// @return | string | The string `LDataWriter`.
        methods.add_method("type", |_, _, ()| Ok("LDataWriter"));
        // -- typeOf --
        /// Returns whether this data writer handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LDataWriter` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataWriter" || name == "Object")
        });
    }
}
/// Exposes byte-buffer inspection and bit editing methods to Lua.
impl mlua::UserData for ByteData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getSize --
        /// Returns the byte buffer length in bytes.
        /// @return | integer | Buffer length in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.len()));
        // -- getString --
        /// Returns the byte buffer as a string.
        /// @return | string | Byte buffer contents as a Lua string.
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        // -- getByte --
        /// Reads one byte at a zero-based offset.
        /// @param | offset | integer | Zero-based byte offset.
        /// @return | integer | Byte value from 0 to 255.
        methods.add_method("getByte", |_, this, offset: usize| {
            this.get_byte(offset).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                ))
            })
        });
        // -- setByte --
        /// Writes one byte at a zero-based offset inside the buffer.
        /// @param | offset | integer | Zero-based byte offset.
        /// @param | value | integer | Byte value from 0 to 255.
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
        // -- clone --
        /// Returns a deep copy of the entire byte buffer.
        /// @return | LByteData | New LByteData userdata containing copied bytes.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(this.clone_data())
        });
        // -- setBit --
        /// Sets or clears one bit inside a byte at the given offset.
        /// @param | byte_offset | integer | Zero-based byte offset.
        /// @param | bit_offset | integer | Bit offset from 0 to 7 inside the byte.
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
        /// Reads one bit inside a byte at the given offsets.
        /// @param | byte_offset | integer | Zero-based byte offset.
        /// @param | bit_offset | integer | Bit offset from 0 to 7 inside the byte.
        /// @return | boolean | True when the bit is set.
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
        /// Reads up to 32 bits starting at a byte and bit offset.
        /// @param | byte_offset | integer | Zero-based byte offset.
        /// @param | bit_offset | integer | Bit offset from 0 to 7 inside the starting byte.
        /// @param | count | integer | Number of bits to read, from 1 to 32.
        /// @return | integer | Unsigned integer containing the requested bits.
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
        // -- type --
        /// Returns the type name of this object for runtime type-checking.
        /// @return | string | Always returns "LByteData".
        methods.add_method("type", |_, _, ()| Ok("LByteData"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check (e.g. "LByteData" or "Object").
        /// @return | boolean | True if this object matches the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LByteData" || name == "Object")
        });
    }
}
