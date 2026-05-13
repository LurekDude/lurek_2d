use super::SharedState;
use crate::serial::{
    codec::{DecodeOptions, EncodeOptions, EncodedValue, SerialFormat},
    lua_table::{from_lua, to_lua},
    CsvOptions,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
fn parse_delimiter(delim: Option<String>) -> u8 {
    delim
        .as_deref()
        .and_then(|d| d.as_bytes().first().copied())
        .unwrap_or(b',')
}
fn csv_options_from_table(opts: Option<LuaTable>) -> LuaResult<CsvOptions> {
    let mut out = CsvOptions::default();
    if let Some(t) = opts {
        let delim: Option<String> = t.get("delimiter")?;
        let headers: Option<bool> = t.get("has_headers")?;
        out.delimiter = parse_delimiter(delim);
        out.has_headers = headers.unwrap_or(true);
    }
    Ok(out)
}
fn encode_options_from_table(opts: Option<LuaTable>) -> LuaResult<EncodeOptions> {
    let mut out = EncodeOptions::default();
    if let Some(t) = opts {
        let pretty: Option<bool> = t.get("pretty")?;
        out.json_pretty = pretty.unwrap_or(false);
        out.csv = csv_options_from_table(Some(t))?;
    }
    Ok(out)
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "fromJson",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;
    tbl.set(
        "toJson",
        lua.create_function(|_, (value, pretty): (LuaValue, Option<bool>)| {
            let val = from_lua(&value)?;
            crate::serial::to_json(&val, pretty.unwrap_or(false)).map_err(LuaError::RuntimeError)
        })?,
    )?;
    tbl.set(
        "fromToml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_toml(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;
    tbl.set(
        "fromIni",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_ini(&s).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &val)
        })?,
    )?;
    tbl.set(
        "toToml",
        lua.create_function(|_, value: LuaValue| {
            let val = from_lua(&value)?;
            crate::serial::to_toml(&val).map_err(LuaError::RuntimeError)
        })?,
    )?;
    tbl.set(
        "fromCsv",
        lua.create_function(
            |lua, (s, delim, headers): (String, Option<String>, Option<bool>)| {
                let opts = CsvOptions {
                    delimiter: parse_delimiter(delim),
                    has_headers: headers.unwrap_or(true),
                };
                let val = crate::serial::from_csv(&s, opts).map_err(LuaError::RuntimeError)?;
                to_lua(lua, &val)
            },
        )?,
    )?;
    tbl.set(
        "toCsv",
        lua.create_function(
            |_, (value, delim, headers): (LuaValue, Option<String>, Option<bool>)| {
                let opts = CsvOptions {
                    delimiter: parse_delimiter(delim),
                    has_headers: headers.unwrap_or(true),
                };
                let val = from_lua(&value)?;
                crate::serial::to_csv(&val, opts).map_err(LuaError::RuntimeError)
            },
        )?,
    )?;
    tbl.set(
        "encodeMsgPack",
        lua.create_function(|lua, value: LuaValue| {
            if !matches!(value, LuaValue::Table(_)) {
                return Err(LuaError::RuntimeError(
                    "encodeMsgPack: argument must be a table".to_string(),
                ));
            }
            let val = from_lua(&value)?;
            let bytes = crate::serial::to_msgpack(&val).map_err(LuaError::RuntimeError)?;
            lua.create_string(&bytes)
        })?,
    )?;
    tbl.set(
        "decodeMsgPack",
        lua.create_function(|lua, bytes: mlua::String| {
            let val =
                crate::serial::from_msgpack(bytes.as_bytes()).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;
    tbl.set(
        "decodeXml",
        lua.create_function(|lua, s: String| {
            let val = crate::serial::from_xml(&s).map_err(LuaError::RuntimeError)?;
            crate::serial::lua_table::to_lua(lua, &val)
        })?,
    )?;
    tbl.set(
        "validate",
        lua.create_function(|_, (value, schema): (LuaValue, LuaValue)| {
            let val = from_lua(&value)?;
            let sch = from_lua(&schema)?;
            match crate::serial::validate_schema(&val, &sch) {
                Ok(()) => Ok((true, None::<String>)),
                Err(msg) => Ok((false, Some(msg))),
            }
        })?,
    )?;
    tbl.set(
        "detectFormat",
        lua.create_function(|_, s: String| {
            Ok(crate::serial::detect_format(&s).map(|f| f.as_str().to_string()))
        })?,
    )?;
    tbl.set(
        "decode",
        lua.create_function(
            |lua, (payload, format, opts): (LuaValue, Option<String>, Option<LuaTable>)| {
                let fmt = if let Some(name) = format.as_deref() {
                    Some(SerialFormat::parse(name).ok_or_else(|| {
                        LuaError::RuntimeError(
                            "decode: unknown format (expected json/toml/csv/xml/ini/msgpack)"
                                .to_string(),
                        )
                    })?)
                } else {
                    None
                };
                let val = match (payload, fmt) {
                    (LuaValue::String(bytes), Some(SerialFormat::MsgPack)) => {
                        crate::serial::decode_bytes(bytes.as_bytes(), SerialFormat::MsgPack)
                            .map_err(LuaError::RuntimeError)?
                    }
                    (LuaValue::String(text), Some(f)) => {
                        let s = text
                            .to_str()
                            .map_err(|e| {
                                LuaError::RuntimeError(format!("decode: expected UTF-8 text: {e}"))
                            })?
                            .to_string();
                        crate::serial::decode_text(
                            &s,
                            Some(f),
                            DecodeOptions {
                                csv: csv_options_from_table(opts)?,
                            },
                        )
                        .map_err(LuaError::RuntimeError)?
                    }
                    (LuaValue::String(text), None) => {
                        let s = text
                            .to_str()
                            .map_err(|e| {
                                LuaError::RuntimeError(format!(
                                    "decode: expected UTF-8 text for auto-detect: {e}"
                                ))
                            })?
                            .to_string();
                        crate::serial::decode_text(
                            &s,
                            None,
                            DecodeOptions {
                                csv: csv_options_from_table(opts)?,
                            },
                        )
                        .map_err(LuaError::RuntimeError)?
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "decode: payload must be a string".to_string(),
                        ));
                    }
                };
                to_lua(lua, &val)
            },
        )?,
    )?;
    tbl.set(
        "encode",
        lua.create_function(
            |lua, (value, format, opts): (LuaValue, String, Option<LuaTable>)| {
                let val = from_lua(&value)?;
                let fmt = SerialFormat::parse(&format).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "encode: unknown format (expected json/toml/csv/msgpack)".to_string(),
                    )
                })?;
                let encoded = crate::serial::encode(&val, fmt, encode_options_from_table(opts)?)
                    .map_err(LuaError::RuntimeError)?;
                match encoded {
                    EncodedValue::Text(s) => lua.create_string(&s),
                    EncodedValue::Binary(bytes) => lua.create_string(&bytes),
                }
            },
        )?,
    )?;
    tbl.set(
        "applyDefaults",
        lua.create_function(|lua, (value, schema): (LuaValue, LuaValue)| {
            let val = from_lua(&value)?;
            let sch = from_lua(&schema)?;
            let patched =
                crate::serial::apply_schema_defaults(&val, &sch).map_err(LuaError::RuntimeError)?;
            to_lua(lua, &patched)
        })?,
    )?;
    lurek.set("serial", tbl)?;
    Ok(())
}
