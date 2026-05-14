
use crate::data::byte_data::ByteData;
pub enum PackValue {
    /// Store signed integer value.
    Int(i64),
    /// Store unsigned integer value.
    UInt(u64),
    /// Store f32 value.
    Float(f32),
    /// Store f64 value.
    Double(f64),
    /// Store UTF-8 string value.
    Str(String),
    /// Store raw bytes value.
    Bytes(Vec<u8>),
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Select byte order for scalar reads and writes.
enum Endian {
    /// Use little-endian byte order.
    Little,
    /// Use big-endian byte order.
    Big,
}
/// Pack values by format string and return ByteData or error.
pub fn pack(format: &str, values: &[PackValue]) -> Result<ByteData, String> {
    let mut buf = Vec::new();
    let mut endian = Endian::Little;
    let mut val_idx = 0usize;
    for ch in format.chars() {
        match ch {
            '<' => {
                endian = Endian::Little;
            }
            '>' => {
                endian = Endian::Big;
            }
            'x' => {
                buf.push(0u8);
            }
            'b' => {
                let v = get_as_i64(values, val_idx, 'b')?;
                val_idx += 1;
                buf.push(v as i8 as u8);
            }
            'B' => {
                let v = get_as_u64(values, val_idx, 'B')?;
                val_idx += 1;
                buf.push((v & 0xFF) as u8);
            }
            'h' => {
                let v = get_as_i64(values, val_idx, 'h')? as i16;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'H' => {
                let v = get_as_u64(values, val_idx, 'H')? as u16;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'i' => {
                let v = get_as_i64(values, val_idx, 'i')? as i32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'I' => {
                let v = get_as_u64(values, val_idx, 'I')? as u32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'l' => {
                let v = get_as_i64(values, val_idx, 'l')?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'L' => {
                let v = get_as_u64(values, val_idx, 'L')?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'f' => {
                let v = get_as_f64(values, val_idx, 'f')? as f32;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            'd' | 'n' => {
                let v = get_as_f64(values, val_idx, ch)?;
                val_idx += 1;
                let b = if endian == Endian::Little {
                    v.to_le_bytes()
                } else {
                    v.to_be_bytes()
                };
                buf.extend_from_slice(&b);
            }
            's' => {
                let s = get_as_string(values, val_idx, 's')?;
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
            'z' => {
                let s = get_as_string(values, val_idx, 'z')?;
                val_idx += 1;
                buf.extend_from_slice(s.as_bytes());
                buf.push(0u8);
            }
            _ => {
                return Err(format!("pack: unknown format character '{}'", ch));
            }
        }
    }
    Ok(ByteData::from_bytes(buf))
}
/// Unpack values by format string and return values with next offset.
pub fn unpack(format: &str, data: &[u8], offset: usize) -> Result<(Vec<PackValue>, usize), String> {
    let mut values = Vec::new();
    let mut endian = Endian::Little;
    let mut pos = offset;
    for ch in format.chars() {
        match ch {
            '<' => {
                endian = Endian::Little;
            }
            '>' => {
                endian = Endian::Big;
            }
            'x' => {
                check_bounds(data, pos, 1, 'x')?;
                pos += 1;
            }
            'b' => {
                let b = read1(data, pos, 'b')?;
                pos += 1;
                values.push(PackValue::Int(b as i8 as i64));
            }
            'B' => {
                let b = read1(data, pos, 'B')?;
                pos += 1;
                values.push(PackValue::UInt(b as u64));
            }
            'h' => {
                let [a, b] = read2(data, pos, 'h')?;
                pos += 2;
                let v = if endian == Endian::Little {
                    i16::from_le_bytes([a, b])
                } else {
                    i16::from_be_bytes([a, b])
                };
                values.push(PackValue::Int(v as i64));
            }
            'H' => {
                let [a, b] = read2(data, pos, 'H')?;
                pos += 2;
                let v = if endian == Endian::Little {
                    u16::from_le_bytes([a, b])
                } else {
                    u16::from_be_bytes([a, b])
                };
                values.push(PackValue::UInt(v as u64));
            }
            'i' => {
                let [a, b, c, d] = read4(data, pos, 'i')?;
                pos += 4;
                let v = if endian == Endian::Little {
                    i32::from_le_bytes([a, b, c, d])
                } else {
                    i32::from_be_bytes([a, b, c, d])
                };
                values.push(PackValue::Int(v as i64));
            }
            'I' => {
                let [a, b, c, d] = read4(data, pos, 'I')?;
                pos += 4;
                let v = if endian == Endian::Little {
                    u32::from_le_bytes([a, b, c, d])
                } else {
                    u32::from_be_bytes([a, b, c, d])
                };
                values.push(PackValue::UInt(v as u64));
            }
            'l' => {
                let arr = read8(data, pos, 'l')?;
                pos += 8;
                let v = if endian == Endian::Little {
                    i64::from_le_bytes(arr)
                } else {
                    i64::from_be_bytes(arr)
                };
                values.push(PackValue::Int(v));
            }
            'L' => {
                let arr = read8(data, pos, 'L')?;
                pos += 8;
                let v = if endian == Endian::Little {
                    u64::from_le_bytes(arr)
                } else {
                    u64::from_be_bytes(arr)
                };
                values.push(PackValue::UInt(v));
            }
            'f' => {
                let [a, b, c, d] = read4(data, pos, 'f')?;
                pos += 4;
                let v = if endian == Endian::Little {
                    f32::from_le_bytes([a, b, c, d])
                } else {
                    f32::from_be_bytes([a, b, c, d])
                };
                values.push(PackValue::Float(v));
            }
            'd' | 'n' => {
                let arr = read8(data, pos, ch)?;
                pos += 8;
                let v = if endian == Endian::Little {
                    f64::from_le_bytes(arr)
                } else {
                    f64::from_be_bytes(arr)
                };
                values.push(PackValue::Double(v));
            }
            's' => {
                let [a, b, c, d] = read4(data, pos, 's')?;
                pos += 4;
                let len = if endian == Endian::Little {
                    u32::from_le_bytes([a, b, c, d])
                } else {
                    u32::from_be_bytes([a, b, c, d])
                } as usize;
                check_bounds(data, pos, len, 's')?;
                let s = String::from_utf8_lossy(&data[pos..pos + len]).into_owned();
                pos += len;
                values.push(PackValue::Str(s));
            }
            'z' => {
                let start = pos;
                while pos < data.len() && data[pos] != 0 {
                    pos += 1;
                }
                if pos >= data.len() {
                    return Err(format!(
                        "unpack 'z': null terminator not found starting at offset {}",
                        start
                    ));
                }
                let s = String::from_utf8_lossy(&data[start..pos]).into_owned();
                pos += 1;
                values.push(PackValue::Str(s));
            }
            _ => {
                return Err(format!("unpack: unknown format character '{}'", ch));
            }
        }
    }
    Ok((values, pos))
}
/// Compute packed byte size for format and provided values.
pub fn get_packed_size(format: &str, values: &[PackValue]) -> Result<usize, String> {
    let mut size = 0usize;
    let mut str_idx = 0usize;
    for ch in format.chars() {
        match ch {
            '<' | '>' => {}
            'x' => {
                size += 1;
            }
            'b' | 'B' => {
                size += 1;
            }
            'h' | 'H' => {
                size += 2;
            }
            'i' | 'I' | 'f' => {
                size += 4;
            }
            'l' | 'L' | 'd' | 'n' => {
                size += 8;
            }
            's' => {
                let s = get_as_string(values, str_idx, 's')?;
                str_idx += 1;
                size += 4 + s.len();
            }
            'z' => {
                let s = get_as_string(values, str_idx, 'z')?;
                str_idx += 1;
                size += s.len() + 1;
            }
            _ => {
                return Err(format!("getPackedSize: unknown format character '{}'", ch));
            }
        }
    }
    Ok(size)
}
/// Extract value at index as i64; return error when missing or wrong type.
fn get_as_i64(values: &[PackValue], idx: usize, fmt: char) -> Result<i64, String> {
    match values.get(idx) {
        Some(PackValue::Int(n)) => Ok(*n),
        Some(PackValue::UInt(n)) => Ok(*n as i64),
        Some(PackValue::Float(f)) => Ok(*f as i64),
        Some(PackValue::Double(d)) => Ok(*d as i64),
        Some(_) => Err(format!(
            "pack '{}': expected integer at value index {}",
            fmt, idx
        )),
        None => Err(format!(
            "pack '{}': not enough values (expected index {})",
            fmt, idx
        )),
    }
}
/// Extract value at index as u64; return error when missing or wrong type.
fn get_as_u64(values: &[PackValue], idx: usize, fmt: char) -> Result<u64, String> {
    match values.get(idx) {
        Some(PackValue::UInt(n)) => Ok(*n),
        Some(PackValue::Int(n)) => Ok(*n as u64),
        Some(PackValue::Float(f)) => Ok(*f as u64),
        Some(PackValue::Double(d)) => Ok(*d as u64),
        Some(_) => Err(format!(
            "pack '{}': expected unsigned integer at value index {}",
            fmt, idx
        )),
        None => Err(format!(
            "pack '{}': not enough values (expected index {})",
            fmt, idx
        )),
    }
}
/// Extract value at index as f64; return error when missing or wrong type.
fn get_as_f64(values: &[PackValue], idx: usize, fmt: char) -> Result<f64, String> {
    match values.get(idx) {
        Some(PackValue::Double(d)) => Ok(*d),
        Some(PackValue::Float(f)) => Ok(*f as f64),
        Some(PackValue::Int(n)) => Ok(*n as f64),
        Some(PackValue::UInt(n)) => Ok(*n as f64),
        Some(_) => Err(format!(
            "pack '{}': expected numeric at value index {}",
            fmt, idx
        )),
        None => Err(format!(
            "pack '{}': not enough values (expected index {})",
            fmt, idx
        )),
    }
}
/// Extract value at index as String; return error when missing or not text.
fn get_as_string(values: &[PackValue], idx: usize, fmt: char) -> Result<String, String> {
    match values.get(idx) {
        Some(PackValue::Str(s)) => Ok(s.clone()),
        Some(PackValue::Bytes(b)) => String::from_utf8(b.clone()).map_err(|e| {
            format!(
                "pack '{}': bytes at index {} are not valid UTF-8: {}",
                fmt, idx, e
            )
        }),
        Some(_) => Err(format!(
            "pack '{}': expected string at value index {}",
            fmt, idx
        )),
        None => Err(format!(
            "pack '{}': not enough values (expected index {})",
            fmt, idx
        )),
    }
}
/// Check that slice has enough bytes at pos for count; return bounds error otherwise.
fn check_bounds(data: &[u8], pos: usize, count: usize, fmt: char) -> Result<(), String> {
    if pos + count > data.len() {
        Err(format!(
            "unpack '{}': buffer underflow at offset {} (need {}, have {})",
            fmt,
            pos,
            count,
            data.len()
        ))
    } else {
        Ok(())
    }
}
/// Read one byte at pos; return error on out-of-bounds.
fn read1(data: &[u8], pos: usize, fmt: char) -> Result<u8, String> {
    check_bounds(data, pos, 1, fmt)?;
    Ok(data[pos])
}
/// Read two bytes at pos; return error on out-of-bounds.
fn read2(data: &[u8], pos: usize, fmt: char) -> Result<[u8; 2], String> {
    check_bounds(data, pos, 2, fmt)?;
    Ok([data[pos], data[pos + 1]])
}
/// Read four bytes at pos; return error on out-of-bounds.
fn read4(data: &[u8], pos: usize, fmt: char) -> Result<[u8; 4], String> {
    check_bounds(data, pos, 4, fmt)?;
    Ok([data[pos], data[pos + 1], data[pos + 2], data[pos + 3]])
}
/// Read eight bytes at pos; return error on out-of-bounds.
fn read8(data: &[u8], pos: usize, fmt: char) -> Result<[u8; 8], String> {
    check_bounds(data, pos, 8, fmt)?;
    Ok([
        data[pos],
        data[pos + 1],
        data[pos + 2],
        data[pos + 3],
        data[pos + 4],
        data[pos + 5],
        data[pos + 6],
        data[pos + 7],
    ])
}
