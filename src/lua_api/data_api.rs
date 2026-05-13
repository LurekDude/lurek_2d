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
        methods.add_method_mut("pop", |lua, this, ()| match this.inner.pop_front() {
            Some(key) => {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            }
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("peek", |lua, this, ()| match this.inner.front() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("peekNewest", |lua, this, ()| match this.inner.back() {
            Some(key) => lua.registry_value::<LuaValue>(key),
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));
        methods.add_method("capacity", |_, this, ()| Ok(this.capacity as i64));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));
        methods.add_method(
            "isFull",
            |_, this, ()| Ok(this.inner.len() >= this.capacity),
        );
        methods.add_method_mut("clear", |lua, this, ()| {
            while let Some(key) = this.inner.pop_front() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, key) in this.inner.iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                t.set(i + 1, v)?;
            }
            Ok(t)
        });
        methods.add_method("type", |_, _, ()| Ok("LRingBuffer"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRingBuffer" || name == "Object")
        });
    }
}
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
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "pack",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            let bd = data::pack(&fmt, &pvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;
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
    tbl.set(
        "getPackedSize",
        lua.create_function(|_, (fmt, vals): (String, LuaMultiValue)| {
            let pvs = lua_values_to_pack(vals);
            data::get_packed_size(&fmt, &pvs)
                .map_err(LuaError::RuntimeError)
                .map(|n| n as i64)
        })?,
    )?;
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
    tbl.set(
        "decompress",
        lua.create_function(|lua, (format_str, compressed): (String, LuaString)| {
            let format = CompressFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result =
                data::decompress(compressed.as_bytes(), format).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;
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
    tbl.set(
        "encode",
        lua.create_function(|_, (format_str, raw_data): (String, LuaString)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            Ok(data::encode(format, raw_data.as_bytes()))
        })?,
    )?;
    tbl.set(
        "decode",
        lua.create_function(|lua, (format_str, encoded): (String, String)| {
            let format = EncodeFormat::parse_str(&format_str).map_err(LuaError::RuntimeError)?;
            let result = data::decode(format, &encoded).map_err(LuaError::RuntimeError)?;
            lua.create_string(&result)
        })?,
    )?;
    tbl.set(
        "hash",
        lua.create_function(|_, (algo_str, raw_data): (String, LuaString)| {
            let algo = HashAlgorithm::parse_str(&algo_str).map_err(LuaError::RuntimeError)?;
            Ok(data::hash(algo, raw_data.as_bytes()))
        })?,
    )?;
    tbl.set(
        "crc32",
        lua.create_function(|_, raw_data: LuaString| Ok(data::crc32(raw_data.as_bytes())))?,
    )?;
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
    tbl.set(
        "write",
        lua.create_function(|lua, (fmt, vals): (String, LuaMultiValue)| {
            let bvs = lua_values_to_bin(vals);
            let bd = data::bin_write(&fmt, &bvs).map_err(LuaError::RuntimeError)?;
            lua.create_string(bd.as_bytes())
        })?,
    )?;
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
    tbl.set(
        "size",
        lua.create_function(|_, fmt: String| {
            data::bin_measure_size(&fmt).map_err(LuaError::RuntimeError)
        })?,
    )?;
    tbl.set(
        "parseToml",
        lua.create_function(|lua, text: String| {
            let value = serial::parse_toml(&text).map_err(LuaError::RuntimeError)?;
            toml_value_to_lua(lua, &value)
        })?,
    )?;
    tbl.set(
        "encodeToml",
        lua.create_function(|_, tbl: LuaTable| {
            let value = lua_table_to_toml_value(&LuaValue::Table(tbl))?;
            serial::encode_toml(&value).map_err(LuaError::RuntimeError)
        })?,
    )?;
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
    tbl.set(
        "fromMsgPack",
        lua.create_function(|lua, bytes: LuaString| {
            let raw: &[u8] = bytes.as_bytes();
            let json_val = crate::serial::decode_json(raw).map_err(LuaError::RuntimeError)?;
            let serial = json_value_to_serial(&json_val);
            crate::serial::lua_table::to_lua(lua, &serial)
        })?,
    )?;
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
        methods.add_method("type", |_, _, ()| Ok("LDataView"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataView" || name == "Object")
        });
    }
}
pub struct LuaDataWriter {
    pub(crate) inner: DataWriter,
}
impl LuaUserData for LuaDataWriter {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("writeU8", |_, this, v: u8| {
            this.inner.write_u8(v);
            Ok(())
        });
        methods.add_method_mut("writeI8", |_, this, v: i8| {
            this.inner.write_i8(v);
            Ok(())
        });
        methods.add_method_mut("writeU16LE", |_, this, v: u16| {
            this.inner.write_u16_le(v);
            Ok(())
        });
        methods.add_method_mut("writeU16BE", |_, this, v: u16| {
            this.inner.write_u16_be(v);
            Ok(())
        });
        methods.add_method_mut("writeI16LE", |_, this, v: i16| {
            this.inner.write_i16_le(v);
            Ok(())
        });
        methods.add_method_mut("writeU32LE", |_, this, v: u32| {
            this.inner.write_u32_le(v);
            Ok(())
        });
        methods.add_method_mut("writeI32LE", |_, this, v: i32| {
            this.inner.write_i32_le(v);
            Ok(())
        });
        methods.add_method_mut("writeF32LE", |_, this, v: f32| {
            this.inner.write_f32_le(v);
            Ok(())
        });
        methods.add_method_mut("writeF64LE", |_, this, v: f64| {
            this.inner.write_f64_le(v);
            Ok(())
        });
        methods.add_method_mut("writeString", |_, this, s: String| {
            this.inner.write_string(&s);
            Ok(())
        });
        methods.add_method_mut("writeBytes", |_, this, s: mlua::String| {
            this.inner.write_bytes(s.as_bytes());
            Ok(())
        });
        methods.add_method_mut("seek", |_, this, pos: usize| {
            this.inner.seek(pos);
            Ok(())
        });
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        methods.add_method("toBytes", |lua, this, ()| {
            lua.create_string(this.inner.as_bytes())
        });
        methods.add_method("type", |_, _, ()| Ok("LDataWriter"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataWriter" || name == "Object")
        });
    }
}
impl mlua::UserData for ByteData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSize", |_, this, ()| Ok(this.len()));
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        methods.add_method("getByte", |_, this, offset: usize| {
            this.get_byte(offset).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                ))
            })
        });
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
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(this.clone_data())
        });
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
