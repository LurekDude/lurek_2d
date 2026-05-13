use super::error::NetworkError;
use serde::{Deserialize, Serialize};
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum NetValue {
    Nil,
    Bool(bool),
    Integer(i64),
    Float(f64),
    String(String),
    Array(Vec<NetValue>),
    Map(Vec<(String, NetValue)>),
}
pub fn pack(value: &NetValue) -> Result<Vec<u8>, NetworkError> {
    rmp_serde::to_vec(value).map_err(|e| NetworkError::Serialization(e.to_string()))
}
pub fn unpack(data: &[u8]) -> Result<NetValue, NetworkError> {
    rmp_serde::from_slice(data).map_err(|e| NetworkError::Serialization(e.to_string()))
}
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
