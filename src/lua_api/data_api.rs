//! `lurek.data` — Binary data manipulation, compression, hashing, and encoding.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;
use std::sync::Arc;

use crate::data::toml_convert;
use crate::data::{
    self, BinValue, ByteData, CompressFormat, DataView, EncodeFormat, HashAlgorithm, LuaDataView,
    PackValue,
};

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

/// Converts a `LuaMultiValue` to `Vec<BinValue>` for the Lurek2D bin pack write API.
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

impl LuaUserData for LuaRingBuffer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- push --
        /// Pushes a value onto the ring buffer.
        /// Returns false if the buffer was full and the oldest element was overwritten,
        /// true if there was space available.
        /// @param value : any
        /// @return boolean
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
        /// @return any
        methods.add_method_mut("pop", |lua, this, ()| {
            match this.inner.pop_front() {
                Some(key) => {
                    let v: LuaValue = lua.registry_value(&key)?;
                    lua.remove_registry_value(key)?;
                    Ok(v)
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- peek --
        /// Returns the oldest element without removing it, or nil if empty.
        /// @return any
        methods.add_method("peek", |lua, this, ()| match this.inner.front() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });

        // -- peekNewest --
        /// Returns the newest element without removing it, or nil if empty.
        /// @return any
        methods.add_method("peekNewest", |lua, this, ()| match this.inner.back() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });

        // -- len --
        /// Returns the number of elements currently in the buffer.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));

        // -- capacity --
        /// Returns the maximum number of elements the buffer can hold.
        /// @return integer
        methods.add_method("capacity", |_, this, ()| Ok(this.capacity as i64));

        // -- isEmpty --
        /// Returns true if the buffer contains no elements.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));

        // -- isFull --
        /// Returns true if the buffer has reached its capacity.
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| {
            Ok(this.inner.len() >= this.capacity)
        });

        // -- clear --
        /// Removes all elements from the buffer, releasing their registry entries.
        methods.add_method_mut("clear", |lua, this, ()| {
            while let Some(key) = this.inner.pop_front() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- toTable --
        /// Returns all elements as an array table ordered oldest-first.
        /// @return table
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, key) in this.inner.iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                t.set(i + 1, v)?;
            }
            Ok(t)
        });
    }
}

// -------------------------------------------------------------------------------
// TOML conversion helpers
// -------------------------------------------------------------------------------

/// Converts a `toml::Value` to a `LuaValue`.
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

/// Converts a `LuaValue` to a `toml::Value`.
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
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
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
            let format = CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result =
                data::decompress(compressed.as_bytes(), format).map_err(LuaError::RuntimeError)?;
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
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
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
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
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
            let algo = HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
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
                let dv = DataView::new_slice(bytes, off, sz).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaDataView::new(dv))
            },
        )?,
    )?;

    // -- write --
    /// Writes values using the Lurek2D Binary Pack Format.
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
    /// Reads values using the Lurek2D Binary Pack Format.
    /// @param format : string
    /// @param data : string
    /// @param offset : integer?
    /// @return ...
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
    /// @param format : string
    /// @return integer
    tbl.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- parseToml --
    /// Parses a TOML string into a Lua table.
    /// @param text : string
    /// @return table
    tbl.set(
        "parseToml",
        lua.create_function(|lua, text: String| {
            let value = toml_convert::parse_toml(&text).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;

    // -- encodeToml --
    /// Encodes a Lua table into a TOML string.
    /// @param tbl : table
    /// @return string
    tbl.set(
        "encodeToml",
        lua.create_function(|_, tbl: LuaTable| {
            let value = lua_table_to_toml_value(&LuaValue::Table(tbl))?;
            toml_convert::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
    )?;

    // -- newRingBuffer --
    /// Creates a fixed-capacity ring buffer that can store any Lua value.
    /// When the buffer is full, pushing a new value overwrites the oldest.
    /// @param capacity : integer
    /// @return RingBuffer
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

    luna.set("data", tbl)?;
    Ok(())
}

/// Access structured binary data efficiently without copying.
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
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.get_size() as i64));
    }
}

impl mlua::UserData for ByteData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── getSize ──────────────────────────────────────────────
        /// Get the size.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| Ok(this.len()));
        // ── getString ──────────────────────────────────────────────
        /// Get the string representation.
        /// @return string
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        // ── getByte ──────────────────────────────────────────────
        /// Get a byte at the specified offset.
        /// @param offset : integer
        /// @return integer
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
        /// @param offset : integer
        /// @param value : integer
        /// @return nil
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
        /// Clone the ByteData.
        /// @return ByteData
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(this.clone_data())
        });

        // -- setBit --
        /// Sets or clears a single bit within the buffer.
        /// `byte_offset` is 0-based byte index, `bit_offset` is 0-7 (0 = LSB).
        /// Returns an error if indices are out of range.
        ///
        /// @param byte_offset : integer   0-based byte index
        /// @param bit_offset  : integer   bit index within byte [0..7], 0 = LSB
        /// @param value       : boolean   true = set, false = clear
        /// @return nil
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
        /// `byte_offset` is 0-based, `bit_offset` is 0–7 (0 = LSB).
        ///
        /// @param byte_offset : integer   0-based byte index
        /// @param bit_offset  : integer   bit index within byte [0..7]
        /// @return boolean
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
        /// Reads `count` consecutive bits starting at `byte_offset`/`bit_offset`
        /// and returns them packed into a u32 (LSB-first, so first bit = bit 0 of result).
        /// `count` must be in [1..32]. Reading across byte boundaries is supported.
        ///
        /// @param byte_offset : integer   0-based starting byte index
        /// @param bit_offset  : integer   starting bit within starting byte [0..7]
        /// @param count       : integer   number of bits to read [1..32]
        /// @return integer    uint32 with bits packed LSB-first
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
