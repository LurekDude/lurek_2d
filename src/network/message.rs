//! Binary message serialization via MessagePack.
//!
//! Provides compact Lua table ↔ binary string conversion for efficient
//! network transport. Uses `rmp-serde` for MessagePack encoding, which
//! is 40–70% smaller than equivalent JSON for typical game messages.
//!
//! # Architecture
//!
//! [`NetValue`] mirrors the Lua type system subset that can cross the
//! network boundary: nil, boolean, integer, float, string, and nested
//! tables (represented as arrays or maps). The [`pack`] and [`unpack`]
//! functions perform the conversion; the Lua API layer converts between
//! `mlua::Value` and `NetValue` at the binding boundary.
//!
//! # Typical usage sequence
//!
//! 1. Lua calls `lurek.network.pack(table)` → `network_api.rs` converts
//!    `mlua::Value` → `NetValue`, calls [`pack`], returns binary string.
//! 2. Binary string sent over ENet / TCP / WebSocket.
//! 3. Receiver calls `lurek.network.unpack(data)` → [`unpack`] → `NetValue`,
//!    `network_api.rs` converts back to `mlua::Value`.

use serde::{Deserialize, Serialize};

use super::error::NetworkError;

/// A network-serializable value that mirrors Lua's type system.
///
/// Supports the subset of Lua types that can cross the network boundary:
/// nil, boolean, integer, float, string, and nested tables (as arrays or maps).
///
/// # Variants
/// - `Nil` — Lua `nil`.
/// - `Bool` — Lua `boolean`.
/// - `Integer` — Lua integer (i64).
/// - `Float` — Lua number (f64, non-integer).
/// - `String` — Lua string (UTF-8 or binary).
/// - `Array` — Lua sequence table (integer keys 1..n).
/// - `Map` — Lua hash table (string keys → values).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum NetValue {
    /// Lua `nil`.
    Nil,
    /// Lua `boolean`.
    Bool(bool),
    /// Lua integer (stored as i64).
    Integer(i64),
    /// Lua floating-point number (stored as f64).
    Float(f64),
    /// Lua string (may contain arbitrary bytes).
    String(String),
    /// Lua sequence table `{1, 2, 3}` — ordered array of values.
    Array(Vec<NetValue>),
    /// Lua hash table `{key = value}` — string keys mapped to values.
    Map(Vec<(String, NetValue)>),
}

/// Serialize a [`NetValue`] to MessagePack bytes.
///
/// # Parameters
/// - `value` — `&NetValue`: the value to serialize.
///
/// # Returns
/// `Result<Vec<u8>, NetworkError>` — compact binary representation.
pub fn pack(value: &NetValue) -> Result<Vec<u8>, NetworkError> {
    rmp_serde::to_vec(value).map_err(|e| NetworkError::Serialization(e.to_string()))
}

/// Deserialize MessagePack bytes into a [`NetValue`].
///
/// # Parameters
/// - `data` — `&[u8]`: MessagePack-encoded bytes.
///
/// # Returns
/// `Result<NetValue, NetworkError>` — the decoded value.
pub fn unpack(data: &[u8]) -> Result<NetValue, NetworkError> {
    rmp_serde::from_slice(data).map_err(|e| NetworkError::Serialization(e.to_string()))
}

/// Estimate the serialized size of a [`NetValue`] without allocating.
///
/// Useful for pre-flight checks against maximum packet sizes.
///
/// # Parameters
/// - `value` — `&NetValue`: the value to measure.
///
/// # Returns
/// `usize` — approximate byte size after MessagePack encoding.
#[allow(clippy::if_same_then_else)]
pub fn estimate_size(value: &NetValue) -> usize {
    match value {
        NetValue::Nil => 1,
        NetValue::Bool(_) => 1,
        NetValue::Integer(n) => {
            if *n >= 0 && *n <= 127 {
                1
            } else if *n >= -32 && *n < 0 {
                1
            } else if *n >= i8::MIN as i64 && *n <= i8::MAX as i64 {
                2
            } else if *n >= i16::MIN as i64 && *n <= i16::MAX as i64 {
                3
            } else if *n >= i32::MIN as i64 && *n <= i32::MAX as i64 {
                5
            } else {
                9
            }
        }
        NetValue::Float(_) => 9,
        NetValue::String(s) => {
            let len = s.len();
            if len <= 31 {
                1 + len
            } else if len <= 255 {
                2 + len
            } else if len <= 65535 {
                3 + len
            } else {
                5 + len
            }
        }
        NetValue::Array(items) => {
            let header = if items.len() <= 15 {
                1
            } else if items.len() <= 65535 {
                3
            } else {
                5
            };
            header + items.iter().map(estimate_size).sum::<usize>()
        }
        NetValue::Map(entries) => {
            let header = if entries.len() <= 15 {
                1
            } else if entries.len() <= 65535 {
                3
            } else {
                5
            };
            header
                + entries
                    .iter()
                    .map(|(k, v)| {
                        let key_size = estimate_size(&NetValue::String(k.clone()));
                        key_size + estimate_size(v)
                    })
                    .sum::<usize>()
        }
    }
}
