//! MessagePack encoding and decoding for Lurek2D.
//!
//! Converts between `SerialValue` and binary MessagePack bytes using `rmp-serde`.
//! No mlua imports — all Lua bridging lives in `src/lua_api/serial_api.rs`.

use super::lua_table::SerialValue;
use crate::log_msg;
use crate::runtime::log_messages::{SR04_MSGPACK_DEC, SR05_MSGPACK_ENC};
use indexmap::IndexMap;
use rmp_serde as rmps;
use serde::{Deserialize, Serialize};

// ── Intermediate serde-compatible representation ──────────────────────────────

/// A serde-compatible mirror of `SerialValue` used as the msgpack bridge.
///
/// We cannot derive `Serialize`/`Deserialize` directly on `SerialValue` because
/// it uses `IndexMap` and carries engine-specific semantics. `MsgValue` is a
/// minimal equivalent that round-trips cleanly through `rmp-serde`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub(super) enum MsgValue {
    /// Null / nil.
    Null,
    /// Boolean.
    Bool(bool),
    /// 64-bit signed integer.
    Int(i64),
    /// 64-bit float.
    Float(f64),
    /// UTF-8 string.
    Str(String),
    /// Ordered sequence.
    Seq(Vec<MsgValue>),
    /// String-keyed map.
    Map(std::collections::HashMap<String, MsgValue>),
}

// ── SerialValue ↔ MsgValue conversion ────────────────────────────────────────

fn serial_to_msg(val: &SerialValue) -> MsgValue {
    match val {
        SerialValue::Null => MsgValue::Null,
        SerialValue::Bool(b) => MsgValue::Bool(*b),
        SerialValue::Int(n) => MsgValue::Int(*n),
        SerialValue::Float(f) => MsgValue::Float(*f),
        SerialValue::Str(s) => MsgValue::Str(s.clone()),
        SerialValue::Seq(arr) => MsgValue::Seq(arr.iter().map(serial_to_msg).collect()),
        SerialValue::Map(map) => {
            let mut hm = std::collections::HashMap::new();
            for (k, v) in map {
                hm.insert(k.clone(), serial_to_msg(v));
            }
            MsgValue::Map(hm)
        }
    }
}

fn msg_to_serial(val: MsgValue) -> SerialValue {
    match val {
        MsgValue::Null => SerialValue::Null,
        MsgValue::Bool(b) => SerialValue::Bool(b),
        MsgValue::Int(n) => SerialValue::Int(n),
        MsgValue::Float(f) => SerialValue::Float(f),
        MsgValue::Str(s) => SerialValue::Str(s),
        MsgValue::Seq(arr) => SerialValue::Seq(arr.into_iter().map(msg_to_serial).collect()),
        MsgValue::Map(map) => {
            let mut ordered = IndexMap::new();
            for (k, v) in map {
                ordered.insert(k, msg_to_serial(v));
            }
            SerialValue::Map(ordered)
        }
    }
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Encode a `SerialValue` tree to MessagePack bytes.
///
/// # Parameters
/// - `val` — `&SerialValue`. The value to encode.
///
/// # Returns
/// `Result<Vec<u8>, String>`.
pub fn encode(val: &SerialValue) -> Result<Vec<u8>, String> {
    let mv = serial_to_msg(val);
    let bytes = rmps::to_vec_named(&mv).map_err(|e| format!("MessagePack encode error: {e}"))?;
    log_msg!(debug, SR05_MSGPACK_ENC);
    Ok(bytes)
}

/// Decode MessagePack bytes into a `SerialValue` tree.
///
/// # Parameters
/// - `bytes` — `&[u8]`. The raw MessagePack payload.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn decode(bytes: &[u8]) -> Result<SerialValue, String> {
    let mv: MsgValue = {
        let mut deserializer = rmps::Deserializer::new(std::io::Cursor::new(bytes));
        let value = MsgValue::deserialize(&mut deserializer)
            .map_err(|e| format!("MessagePack decode error: {e}"))?;
        let consumed = deserializer.get_ref().position() as usize;
        if consumed != bytes.len() {
            return Err("MessagePack decode error: trailing bytes after root value".to_string());
        }
        value
    };
    log_msg!(debug, SR04_MSGPACK_DEC);
    Ok(msg_to_serial(mv))
}

// ── serde_json::Value helpers (for backward compatibility and data_api) ──────

/// Encode a `serde_json::Value` to MessagePack bytes (lower-level, no SerialValue).
///
/// This is provided for compatibility with code that works directly with
/// `serde_json::Value`. Prefer `encode()` for new code.
///
/// # Parameters
/// - `value` — `&serde_json::Value`. The value to encode.
///
/// # Returns
/// `Result<Vec<u8>, String>`.
pub fn encode_json(value: &serde_json::Value) -> Result<Vec<u8>, String> {
    let bytes = rmps::to_vec(value).map_err(|e| format!("MessagePack encode error: {e}"))?;
    Ok(bytes)
}

/// Decode MessagePack bytes into a `serde_json::Value` (lower-level, no SerialValue).
///
/// This is provided for compatibility with code that works directly with
/// `serde_json::Value`. Prefer `decode()` for new code.
///
/// # Parameters
/// - `bytes` — `&[u8]`. The raw MessagePack payload.
///
/// # Returns
/// `Result<serde_json::Value, String>`.
pub fn decode_json(bytes: &[u8]) -> Result<serde_json::Value, String> {
    use serde::Deserialize;

    let mut deserializer = rmps::Deserializer::new(std::io::Cursor::new(bytes));
    let value = serde_json::Value::deserialize(&mut deserializer)
        .map_err(|e| format!("MessagePack decode error: {e}"))?;

    let consumed = deserializer.get_ref().position() as usize;
    if consumed != bytes.len() {
        return Err("MessagePack decode error: trailing bytes after root value".to_string());
    }

    Ok(value)
}
