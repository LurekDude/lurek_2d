//! Luna2D Binary Pack Format — format-string based binary serialization.
//!
//! Provides `write`, `read`, and `measure_size` for the `luna.data` module.
//! Format strings use space-separated named type tokens.
//!
//! # Format string tokens
//!
//! | Token  | Type                       | Byte size  |
//! |--------|----------------------------|------------|
//! | `le`   | switch to little-endian    | (modifier) |
//! | `be`   | switch to big-endian       | (modifier) |
//! | `u8`   | unsigned 8-bit integer     | 1          |
//! | `u16`  | unsigned 16-bit integer    | 2          |
//! | `u32`  | unsigned 32-bit integer    | 4          |
//! | `u64`  | unsigned 64-bit integer    | 8          |
//! | `i8`   | signed 8-bit integer       | 1          |
//! | `i16`  | signed 16-bit integer      | 2          |
//! | `i32`  | signed 32-bit integer      | 4          |
//! | `i64`  | signed 64-bit integer      | 8          |
//! | `f32`  | 32-bit float               | 4          |
//! | `f64`  | 64-bit float               | 8          |
//! | `bool` | boolean (u8: 0=false)      | 1          |
//! | `str`  | u32-length-prefixed UTF-8  | 4 + len    |
//! | `cstr` | null-terminated UTF-8      | len + 1    |
//! | `pad`  | zero padding byte          | 1          |

use crate::data::byte_data::ByteData;

/// A Luna2D serializable binary value.
///
/// # Variants
/// - `U8` — Unsigned 8-bit integer.
/// - `U16` — Unsigned 16-bit integer.
/// - `U32` — Unsigned 32-bit integer.
/// - `U64` — Unsigned 64-bit integer.
/// - `I8` — Signed 8-bit integer.
/// - `I16` — Signed 16-bit integer.
/// - `I32` — Signed 32-bit integer.
/// - `I64` — Signed 64-bit integer.
/// - `F32` — 32-bit float.
/// - `F64` — 64-bit float.
/// - `Bool` — Boolean.
/// - `Str` — UTF-8 string.
/// - `Bytes` — Raw byte vector.
#[derive(Debug, Clone)]
pub enum BinValue {
    /// Unsigned 8-bit integer.
    U8(u8),
    /// Unsigned 16-bit integer.
    U16(u16),
    /// Unsigned 32-bit integer.
    U32(u32),
    /// Unsigned 64-bit integer.
    U64(u64),
    /// Signed 8-bit integer.
    I8(i8),
    /// Signed 16-bit integer.
    I16(i16),
    /// Signed 32-bit integer.
    I32(i32),
    /// Signed 64-bit integer.
    I64(i64),
    /// 32-bit float.
    F32(f32),
    /// 64-bit float.
    F64(f64),
    /// Boolean value.
    Bool(bool),
    /// UTF-8 string.
    Str(String),
    /// Raw byte vector.
    Bytes(Vec<u8>),
}

/// Format token parsed from a Luna2D binary format string.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Token {
    U8,
    U16,
    U32,
    U64,
    I8,
    I16,
    I32,
    I64,
    F32,
    F64,
    Bool,
    Str,
    CStr,
    Pad,
}

/// Byte order for write/read operations.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Endian {
    Little,
    Big,
}

/// Parse a Luna2D binary format string into an endianness and a token list.
///
/// # Parameters
/// - `fmt` — `&str`. Space-separated format token string.
///
/// # Returns
/// `Result<(Endian, Vec<Token>), String>`.
fn parse_format(fmt: &str) -> Result<(Endian, Vec<Token>), String> {
    let mut endian = Endian::Little;
    let mut tokens = Vec::new();
    for token in fmt.split_whitespace() {
        match token {
            "le" => endian = Endian::Little,
            "be" => endian = Endian::Big,
            "u8" => tokens.push(Token::U8),
            "u16" => tokens.push(Token::U16),
            "u32" => tokens.push(Token::U32),
            "u64" => tokens.push(Token::U64),
            "i8" => tokens.push(Token::I8),
            "i16" => tokens.push(Token::I16),
            "i32" => tokens.push(Token::I32),
            "i64" => tokens.push(Token::I64),
            "f32" => tokens.push(Token::F32),
            "f64" => tokens.push(Token::F64),
            "bool" => tokens.push(Token::Bool),
            "str" => tokens.push(Token::Str),
            "cstr" => tokens.push(Token::CStr),
            "pad" => tokens.push(Token::Pad),
            other => return Err(format!("luna.data: unknown format token '{other}'")),
        }
    }
    Ok((endian, tokens))
}

/// Write values into a binary buffer according to a Luna2D format string.
///
/// # Parameters
/// - `format` — `&str`. Space-separated format token string (e.g. `"u32 f32 str"`).
/// - `values` — `&[BinValue]`. Values to write, one per non-`pad` token in order.
///
/// # Returns
/// `Result<ByteData, String>`.
pub fn write(format: &str, values: &[BinValue]) -> Result<ByteData, String> {
    let (endian, tokens) = parse_format(format)?;
    let mut buf = Vec::new();
    let mut val_idx = 0usize;

    for token in &tokens {
        match token {
            Token::Pad => buf.push(0u8),
            Token::U8 => {
                let v = coerce_u64(values, val_idx, "u8")? as u8;
                val_idx += 1;
                buf.push(v);
            }
            Token::U16 => {
                let v = coerce_u64(values, val_idx, "u16")? as u16;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::U32 => {
                let v = coerce_u64(values, val_idx, "u32")? as u32;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::U64 => {
                let v = coerce_u64(values, val_idx, "u64")?;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::I8 => {
                let v = coerce_i64(values, val_idx, "i8")? as i8;
                val_idx += 1;
                buf.push(v as u8);
            }
            Token::I16 => {
                let v = coerce_i64(values, val_idx, "i16")? as i16;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::I32 => {
                let v = coerce_i64(values, val_idx, "i32")? as i32;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::I64 => {
                let v = coerce_i64(values, val_idx, "i64")?;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::F32 => {
                let v = coerce_f64(values, val_idx, "f32")? as f32;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::F64 => {
                let v = coerce_f64(values, val_idx, "f64")?;
                val_idx += 1;
                let b = if endian == Endian::Little { v.to_le_bytes() } else { v.to_be_bytes() };
                buf.extend_from_slice(&b);
            }
            Token::Bool => {
                let v = coerce_bool(values, val_idx, "bool")?;
                val_idx += 1;
                buf.push(if v { 1u8 } else { 0u8 });
            }
            Token::Str => {
                let s = coerce_str(values, val_idx, "str")?;
                val_idx += 1;
                let len = s.len() as u32;
                let lb = if endian == Endian::Little { len.to_le_bytes() } else { len.to_be_bytes() };
                buf.extend_from_slice(&lb);
                buf.extend_from_slice(s.as_bytes());
            }
            Token::CStr => {
                let s = coerce_str(values, val_idx, "cstr")?;
                val_idx += 1;
                buf.extend_from_slice(s.as_bytes());
                buf.push(0u8);
            }
        }
    }

    Ok(ByteData::from_bytes(buf))
}

/// Read values from a binary buffer according to a Luna2D format string.
///
/// # Parameters
/// - `format` — `&str`. Space-separated format token string.
/// - `data` — `&[u8]`. Source byte buffer.
/// - `offset` — `usize`. Starting byte offset (0-based).
///
/// # Returns
/// `Result<(Vec<BinValue>, usize), String>` — decoded values and next byte position.
pub fn read(format: &str, data: &[u8], offset: usize) -> Result<(Vec<BinValue>, usize), String> {
    let (endian, tokens) = parse_format(format)?;
    let mut values = Vec::new();
    let mut pos = offset;

    for token in &tokens {
        match token {
            Token::Pad => {
                check_bounds(data, pos, 1, "pad")?;
                pos += 1;
            }
            Token::U8 => {
                check_bounds(data, pos, 1, "u8")?;
                values.push(BinValue::U8(data[pos]));
                pos += 1;
            }
            Token::U16 => {
                check_bounds(data, pos, 2, "u16")?;
                let arr = [data[pos], data[pos + 1]];
                let v = if endian == Endian::Little { u16::from_le_bytes(arr) } else { u16::from_be_bytes(arr) };
                values.push(BinValue::U16(v));
                pos += 2;
            }
            Token::U32 => {
                check_bounds(data, pos, 4, "u32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little { u32::from_le_bytes(arr) } else { u32::from_be_bytes(arr) };
                values.push(BinValue::U32(v));
                pos += 4;
            }
            Token::U64 => {
                check_bounds(data, pos, 8, "u64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little { u64::from_le_bytes(arr) } else { u64::from_be_bytes(arr) };
                values.push(BinValue::U64(v));
                pos += 8;
            }
            Token::I8 => {
                check_bounds(data, pos, 1, "i8")?;
                values.push(BinValue::I8(data[pos] as i8));
                pos += 1;
            }
            Token::I16 => {
                check_bounds(data, pos, 2, "i16")?;
                let arr = [data[pos], data[pos + 1]];
                let v = if endian == Endian::Little { i16::from_le_bytes(arr) } else { i16::from_be_bytes(arr) };
                values.push(BinValue::I16(v));
                pos += 2;
            }
            Token::I32 => {
                check_bounds(data, pos, 4, "i32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little { i32::from_le_bytes(arr) } else { i32::from_be_bytes(arr) };
                values.push(BinValue::I32(v));
                pos += 4;
            }
            Token::I64 => {
                check_bounds(data, pos, 8, "i64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little { i64::from_le_bytes(arr) } else { i64::from_be_bytes(arr) };
                values.push(BinValue::I64(v));
                pos += 8;
            }
            Token::F32 => {
                check_bounds(data, pos, 4, "f32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little { f32::from_le_bytes(arr) } else { f32::from_be_bytes(arr) };
                values.push(BinValue::F32(v));
                pos += 4;
            }
            Token::F64 => {
                check_bounds(data, pos, 8, "f64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little { f64::from_le_bytes(arr) } else { f64::from_be_bytes(arr) };
                values.push(BinValue::F64(v));
                pos += 8;
            }
            Token::Bool => {
                check_bounds(data, pos, 1, "bool")?;
                values.push(BinValue::Bool(data[pos] != 0));
                pos += 1;
            }
            Token::Str => {
                check_bounds(data, pos, 4, "str")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let len = if endian == Endian::Little { u32::from_le_bytes(arr) } else { u32::from_be_bytes(arr) } as usize;
                pos += 4;
                check_bounds(data, pos, len, "str")?;
                let s = String::from_utf8_lossy(&data[pos..pos + len]).into_owned();
                pos += len;
                values.push(BinValue::Str(s));
            }
            Token::CStr => {
                let start = pos;
                while pos < data.len() && data[pos] != 0 {
                    pos += 1;
                }
                if pos >= data.len() {
                    return Err(format!(
                        "luna.data read 'cstr': null terminator not found starting at offset {start}"
                    ));
                }
                let s = String::from_utf8_lossy(&data[start..pos]).into_owned();
                pos += 1;
                values.push(BinValue::Str(s));
            }
        }
    }

    Ok((values, pos))
}

/// Compute the total byte size that `write` would produce for the given format string.
///
/// Returns an error if the format contains `str` or `cstr` tokens since their
/// encoded size depends on the string content.
///
/// # Parameters
/// - `format` — `&str`. Space-separated format token string.
///
/// # Returns
/// `Result<usize, String>`.
pub fn measure_size(format: &str) -> Result<usize, String> {
    let (_endian, tokens) = parse_format(format)?;
    let mut size = 0usize;

    for token in &tokens {
        match token {
            Token::Pad | Token::U8 | Token::I8 | Token::Bool => size += 1,
            Token::U16 | Token::I16 => size += 2,
            Token::U32 | Token::I32 | Token::F32 => size += 4,
            Token::U64 | Token::I64 | Token::F64 => size += 8,
            Token::Str => {
                return Err(
                    "luna.data size: 'str' token has variable length; cannot compute static size".to_string(),
                )
            }
            Token::CStr => {
                return Err(
                    "luna.data size: 'cstr' token has variable length; cannot compute static size".to_string(),
                )
            }
        }
    }

    Ok(size)
}

// ── Internal helpers ─────────────────────────────────────────────────────────

/// Assert `data[pos..pos+count]` is in bounds.
fn check_bounds(data: &[u8], pos: usize, count: usize, token: &str) -> Result<(), String> {
    if pos + count > data.len() {
        Err(format!(
            "luna.data read '{token}': buffer underflow at offset {pos} (need {count}, have {})",
            data.len()
        ))
    } else {
        Ok(())
    }
}

/// Read 8 bytes from `data` at `pos` (caller must call `check_bounds` first).
fn read8(data: &[u8], pos: usize) -> [u8; 8] {
    [
        data[pos],
        data[pos + 1],
        data[pos + 2],
        data[pos + 3],
        data[pos + 4],
        data[pos + 5],
        data[pos + 6],
        data[pos + 7],
    ]
}

/// Coerce a `BinValue` to `u64`, accepting any numeric variant.
fn coerce_u64(values: &[BinValue], idx: usize, token: &str) -> Result<u64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v))  => Ok(*v as u64),
        Some(BinValue::U16(v)) => Ok(*v as u64),
        Some(BinValue::U32(v)) => Ok(*v as u64),
        Some(BinValue::U64(v)) => Ok(*v),
        Some(BinValue::I8(v))  => Ok(*v as u64),
        Some(BinValue::I16(v)) => Ok(*v as u64),
        Some(BinValue::I32(v)) => Ok(*v as u64),
        Some(BinValue::I64(v)) => Ok(*v as u64),
        Some(BinValue::F32(v)) => Ok(*v as u64),
        Some(BinValue::F64(v)) => Ok(*v as u64),
        Some(BinValue::Bool(b)) => Ok(if *b { 1 } else { 0 }),
        Some(_) => Err(format!("luna.data write '{token}': expected integer at value index {idx}")),
        None    => Err(format!("luna.data write '{token}': not enough values (expected index {idx})")),
    }
}

/// Coerce a `BinValue` to `i64`, accepting any numeric variant.
fn coerce_i64(values: &[BinValue], idx: usize, token: &str) -> Result<i64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v))  => Ok(*v as i64),
        Some(BinValue::U16(v)) => Ok(*v as i64),
        Some(BinValue::U32(v)) => Ok(*v as i64),
        Some(BinValue::U64(v)) => Ok(*v as i64),
        Some(BinValue::I8(v))  => Ok(*v as i64),
        Some(BinValue::I16(v)) => Ok(*v as i64),
        Some(BinValue::I32(v)) => Ok(*v as i64),
        Some(BinValue::I64(v)) => Ok(*v),
        Some(BinValue::F32(v)) => Ok(*v as i64),
        Some(BinValue::F64(v)) => Ok(*v as i64),
        Some(BinValue::Bool(b)) => Ok(if *b { 1 } else { 0 }),
        Some(_) => Err(format!("luna.data write '{token}': expected integer at value index {idx}")),
        None    => Err(format!("luna.data write '{token}': not enough values (expected index {idx})")),
    }
}

/// Coerce a `BinValue` to `f64`, accepting any numeric variant.
fn coerce_f64(values: &[BinValue], idx: usize, token: &str) -> Result<f64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v))  => Ok(*v as f64),
        Some(BinValue::U16(v)) => Ok(*v as f64),
        Some(BinValue::U32(v)) => Ok(*v as f64),
        Some(BinValue::U64(v)) => Ok(*v as f64),
        Some(BinValue::I8(v))  => Ok(*v as f64),
        Some(BinValue::I16(v)) => Ok(*v as f64),
        Some(BinValue::I32(v)) => Ok(*v as f64),
        Some(BinValue::I64(v)) => Ok(*v as f64),
        Some(BinValue::F32(v)) => Ok(*v as f64),
        Some(BinValue::F64(v)) => Ok(*v),
        Some(BinValue::Bool(b)) => Ok(if *b { 1.0 } else { 0.0 }),
        Some(_) => Err(format!("luna.data write '{token}': expected numeric at value index {idx}")),
        None    => Err(format!("luna.data write '{token}': not enough values (expected index {idx})")),
    }
}

/// Coerce a `BinValue` to `bool`.
fn coerce_bool(values: &[BinValue], idx: usize, token: &str) -> Result<bool, String> {
    match values.get(idx) {
        Some(BinValue::Bool(b)) => Ok(*b),
        Some(BinValue::U8(v))  => Ok(*v != 0),
        Some(BinValue::I64(v)) => Ok(*v != 0),
        Some(_) => Err(format!("luna.data write '{token}': expected bool at value index {idx}")),
        None    => Err(format!("luna.data write '{token}': not enough values (expected index {idx})")),
    }
}

/// Coerce a `BinValue` to a `String` reference for writing.
fn coerce_str(values: &[BinValue], idx: usize, token: &str) -> Result<String, String> {
    match values.get(idx) {
        Some(BinValue::Str(s)) => Ok(s.clone()),
        Some(BinValue::Bytes(b)) => String::from_utf8(b.clone()).map_err(|e| {
            format!("luna.data write '{token}': bytes at index {idx} are not valid UTF-8: {e}")
        }),
        Some(_) => Err(format!("luna.data write '{token}': expected string at value index {idx}")),
        None    => Err(format!("luna.data write '{token}': not enough values (expected index {idx})")),
    }
}
