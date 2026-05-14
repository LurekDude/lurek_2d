use crate::data::byte_data::ByteData;
#[derive(Debug, Clone)]
/// Hold typed values used by token-based binary packing.
pub enum BinValue {
    /// Store u8 value.
    U8(u8),
    /// Store u16 value.
    U16(u16),
    /// Store u32 value.
    U32(u32),
    /// Store u64 value.
    U64(u64),
    /// Store i8 value.
    I8(i8),
    /// Store i16 value.
    I16(i16),
    /// Store i32 value.
    I32(i32),
    /// Store i64 value.
    I64(i64),
    /// Store f32 value.
    F32(f32),
    /// Store f64 value.
    F64(f64),
    /// Store boolean value.
    Bool(bool),
    /// Store UTF-8 string value.
    Str(String),
    /// Store raw bytes value.
    Bytes(Vec<u8>),
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Represent one format token parsed from a whitespace-separated format string.
enum Token {
    /// Read or write one u8 byte.
    U8,
    /// Read or write two-byte unsigned integer.
    U16,
    /// Read or write four-byte unsigned integer.
    U32,
    /// Read or write eight-byte unsigned integer.
    U64,
    /// Read or write one signed byte.
    I8,
    /// Read or write two-byte signed integer.
    I16,
    /// Read or write four-byte signed integer.
    I32,
    /// Read or write eight-byte signed integer.
    I64,
    /// Read or write four-byte float.
    F32,
    /// Read or write eight-byte float.
    F64,
    /// Read or write one-byte boolean.
    Bool,
    /// Read or write length-prefixed UTF-8 string.
    Str,
    /// Read or write null-terminated UTF-8 string.
    CStr,
    /// Write one zero padding byte; skip on read.
    Pad,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Select byte order for multi-byte scalar reads and writes.
enum Endian {
    /// Use little-endian byte order.
    Little,
    /// Use big-endian byte order.
    Big,
}
/// Parse whitespace-separated format string into endian selector and token list.
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
            other => return Err(format!("lurek.data: unknown format token '{other}'")),
        }
    }
    Ok((endian, tokens))
}
/// Write values by token format and return ByteData or error.
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
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::U32 => {
                let v = coerce_u64(values, val_idx, "u32")? as u32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::U64 => {
                let v = coerce_u64(values, val_idx, "u64")?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
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
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::I32 => {
                let v = coerce_i64(values, val_idx, "i32")? as i32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::I64 => {
                let v = coerce_i64(values, val_idx, "i64")?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::F32 => {
                let v = coerce_f64(values, val_idx, "f32")? as f32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            Token::F64 => {
                let v = coerce_f64(values, val_idx, "f64")?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
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
                let lb = if endian == Endian::Little {
                    len.to_le_bytes()
                } else {
                    len.to_be_bytes()
                };
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
/// Read values by token format and return values with next offset.
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
                let v = if endian == Endian::Little {
                    u16::from_le_bytes(arr)
                } else {
                    u16::from_be_bytes(arr)
                };
                values.push(BinValue::U16(v));
                pos += 2;
            }
            Token::U32 => {
                check_bounds(data, pos, 4, "u32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little {
                    u32::from_le_bytes(arr)
                } else {
                    u32::from_be_bytes(arr)
                };
                values.push(BinValue::U32(v));
                pos += 4;
            }
            Token::U64 => {
                check_bounds(data, pos, 8, "u64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little {
                    u64::from_le_bytes(arr)
                } else {
                    u64::from_be_bytes(arr)
                };
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
                let v = if endian == Endian::Little {
                    i16::from_le_bytes(arr)
                } else {
                    i16::from_be_bytes(arr)
                };
                values.push(BinValue::I16(v));
                pos += 2;
            }
            Token::I32 => {
                check_bounds(data, pos, 4, "i32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little {
                    i32::from_le_bytes(arr)
                } else {
                    i32::from_be_bytes(arr)
                };
                values.push(BinValue::I32(v));
                pos += 4;
            }
            Token::I64 => {
                check_bounds(data, pos, 8, "i64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little {
                    i64::from_le_bytes(arr)
                } else {
                    i64::from_be_bytes(arr)
                };
                values.push(BinValue::I64(v));
                pos += 8;
            }
            Token::F32 => {
                check_bounds(data, pos, 4, "f32")?;
                let arr = [data[pos], data[pos + 1], data[pos + 2], data[pos + 3]];
                let v = if endian == Endian::Little {
                    f32::from_le_bytes(arr)
                } else {
                    f32::from_be_bytes(arr)
                };
                values.push(BinValue::F32(v));
                pos += 4;
            }
            Token::F64 => {
                check_bounds(data, pos, 8, "f64")?;
                let arr = read8(data, pos);
                let v = if endian == Endian::Little {
                    f64::from_le_bytes(arr)
                } else {
                    f64::from_be_bytes(arr)
                };
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
                let len = if endian == Endian::Little {
                    u32::from_le_bytes(arr)
                } else {
                    u32::from_be_bytes(arr)
                } as usize;
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
                        "lurek.data read 'cstr': null terminator not found starting at offset {start}"
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
/// Measure static size for token format without variable-width tokens.
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
                    "lurek.data size: 'str' token has variable length; cannot compute static size"
                        .to_string(),
                )
            }
            Token::CStr => {
                return Err(
                    "lurek.data size: 'cstr' token has variable length; cannot compute static size"
                        .to_string(),
                )
            }
        }
    }
    Ok(size)
}
/// Check that slice has enough bytes at pos for count; return error on underflow.
fn check_bounds(data: &[u8], pos: usize, count: usize, token: &str) -> Result<(), String> {
    if pos + count > data.len() {
        Err(format!(
            "lurek.data read '{token}': buffer underflow at offset {pos} (need {count}, have {})",
            data.len()
        ))
    } else {
        Ok(())
    }
}
/// Read eight bytes at pos without bounds check; caller must call check_bounds first.
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
/// Coerce value at index to u64; return error when missing or incompatible.
fn coerce_u64(values: &[BinValue], idx: usize, token: &str) -> Result<u64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v)) => Ok(*v as u64),
        Some(BinValue::U16(v)) => Ok(*v as u64),
        Some(BinValue::U32(v)) => Ok(*v as u64),
        Some(BinValue::U64(v)) => Ok(*v),
        Some(BinValue::I8(v)) => Ok(*v as u64),
        Some(BinValue::I16(v)) => Ok(*v as u64),
        Some(BinValue::I32(v)) => Ok(*v as u64),
        Some(BinValue::I64(v)) => Ok(*v as u64),
        Some(BinValue::F32(v)) => Ok(*v as u64),
        Some(BinValue::F64(v)) => Ok(*v as u64),
        Some(BinValue::Bool(b)) => Ok(if *b { 1 } else { 0 }),
        Some(_) => Err(format!(
            "lurek.data write '{token}': expected integer at value index {idx}"
        )),
        None => Err(format!(
            "lurek.data write '{token}': not enough values (expected index {idx})"
        )),
    }
}
/// Coerce value at index to i64; return error when missing or incompatible.
fn coerce_i64(values: &[BinValue], idx: usize, token: &str) -> Result<i64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v)) => Ok(*v as i64),
        Some(BinValue::U16(v)) => Ok(*v as i64),
        Some(BinValue::U32(v)) => Ok(*v as i64),
        Some(BinValue::U64(v)) => Ok(*v as i64),
        Some(BinValue::I8(v)) => Ok(*v as i64),
        Some(BinValue::I16(v)) => Ok(*v as i64),
        Some(BinValue::I32(v)) => Ok(*v as i64),
        Some(BinValue::I64(v)) => Ok(*v),
        Some(BinValue::F32(v)) => Ok(*v as i64),
        Some(BinValue::F64(v)) => Ok(*v as i64),
        Some(BinValue::Bool(b)) => Ok(if *b { 1 } else { 0 }),
        Some(_) => Err(format!(
            "lurek.data write '{token}': expected integer at value index {idx}"
        )),
        None => Err(format!(
            "lurek.data write '{token}': not enough values (expected index {idx})"
        )),
    }
}
/// Coerce value at index to f64; return error when missing or incompatible.
fn coerce_f64(values: &[BinValue], idx: usize, token: &str) -> Result<f64, String> {
    match values.get(idx) {
        Some(BinValue::U8(v)) => Ok(*v as f64),
        Some(BinValue::U16(v)) => Ok(*v as f64),
        Some(BinValue::U32(v)) => Ok(*v as f64),
        Some(BinValue::U64(v)) => Ok(*v as f64),
        Some(BinValue::I8(v)) => Ok(*v as f64),
        Some(BinValue::I16(v)) => Ok(*v as f64),
        Some(BinValue::I32(v)) => Ok(*v as f64),
        Some(BinValue::I64(v)) => Ok(*v as f64),
        Some(BinValue::F32(v)) => Ok(*v as f64),
        Some(BinValue::F64(v)) => Ok(*v),
        Some(BinValue::Bool(b)) => Ok(if *b { 1.0 } else { 0.0 }),
        Some(_) => Err(format!(
            "lurek.data write '{token}': expected numeric at value index {idx}"
        )),
        None => Err(format!(
            "lurek.data write '{token}': not enough values (expected index {idx})"
        )),
    }
}
/// Coerce value at index to bool; return error when missing or incompatible.
fn coerce_bool(values: &[BinValue], idx: usize, token: &str) -> Result<bool, String> {
    match values.get(idx) {
        Some(BinValue::Bool(b)) => Ok(*b),
        Some(BinValue::U8(v)) => Ok(*v != 0),
        Some(BinValue::I64(v)) => Ok(*v != 0),
        Some(_) => Err(format!(
            "lurek.data write '{token}': expected bool at value index {idx}"
        )),
        None => Err(format!(
            "lurek.data write '{token}': not enough values (expected index {idx})"
        )),
    }
}
/// Coerce value at index to string; return error when missing or incompatible.
fn coerce_str(values: &[BinValue], idx: usize, token: &str) -> Result<String, String> {
    match values.get(idx) {
        Some(BinValue::Str(s)) => Ok(s.clone()),
        Some(BinValue::Bytes(b)) => String::from_utf8(b.clone()).map_err(|e| {
            format!("lurek.data write '{token}': bytes at index {idx} are not valid UTF-8: {e}")
        }),
        Some(_) => Err(format!(
            "lurek.data write '{token}': expected string at value index {idx}"
        )),
        None => Err(format!(
            "lurek.data write '{token}': not enough values (expected index {idx})"
        )),
    }
}
