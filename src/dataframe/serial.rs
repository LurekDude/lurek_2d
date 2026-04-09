//! CSV, JSON, and LVDF binary serialization for DataFrame.
//!
//! This module is part of Lurek2D's `dataframe` subsystem and provides the implementation
//! details for serial-related operations and data management.
//! Primary functions: `from_csv()`, `to_csv()`, `from_json()`, `to_json()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::dataframe::frame::{CellValue, DataFrame};

// ---------------------------------------------------------------------------
// CSV (RFC 4180)
// ---------------------------------------------------------------------------

/// Parse a CSV string into a DataFrame. Returns a fully initialised instance with all fields set to their initial values.
///
/// # Parameters
/// - `s` — `&str`.
///
/// # Returns
/// `Result<DataFrame, String>`.
///
/// Handles quoted fields (embedded commas, newlines, escaped quotes `""`).
/// Auto-detects column types: tries f64 → bool → keeps as Text.
pub fn from_csv(s: &str) -> Result<DataFrame, String> {
    let records = parse_csv_records(s)?;
    if records.is_empty() {
        return Ok(DataFrame::new());
    }

    let headers: Vec<String> = records[0].iter().map(|h| h.to_string()).collect();
    let ncols = headers.len();
    let mut data: Vec<Vec<CellValue>> = vec![Vec::new(); ncols];

    for (row_i, record) in records.iter().skip(1).enumerate() {
        if record.len() != ncols {
            return Err(format!(
                "CSV row {} has {} fields, expected {ncols}",
                row_i + 2,
                record.len()
            ));
        }
        for (ci, field) in record.iter().enumerate() {
            data[ci].push(auto_detect_type(field));
        }
    }

    Ok(DataFrame::from_raw(headers, data))
}

/// Auto-detect the type of a CSV field value.
fn auto_detect_type(s: &str) -> CellValue {
    if s.is_empty() {
        return CellValue::Nil;
    }
    // Try number
    if let Ok(n) = s.parse::<f64>() {
        return CellValue::Number(n);
    }
    // Try bool
    match s.to_lowercase().as_str() {
        "true" => return CellValue::Bool(true),
        "false" => return CellValue::Bool(false),
        _ => {}
    }
    CellValue::Text(s.to_string())
}

/// Parse CSV text into a list of records (each record is a list of fields).
fn parse_csv_records(s: &str) -> Result<Vec<Vec<String>>, String> {
    let mut records: Vec<Vec<String>> = Vec::new();
    let mut current_record: Vec<String> = Vec::new();
    let mut current_field = String::new();
    let mut in_quotes = false;
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    let mut i = 0;

    while i < len {
        let c = chars[i];
        if in_quotes {
            if c == '"' {
                // Check for escaped quote ""
                if i + 1 < len && chars[i + 1] == '"' {
                    current_field.push('"');
                    i += 2;
                    continue;
                }
                // End of quoted field
                in_quotes = false;
                i += 1;
                continue;
            }
            current_field.push(c);
            i += 1;
        } else {
            match c {
                '"' => {
                    in_quotes = true;
                    i += 1;
                }
                ',' => {
                    current_record.push(std::mem::take(&mut current_field));
                    i += 1;
                }
                '\r' => {
                    // Handle \r\n or bare \r
                    current_record.push(std::mem::take(&mut current_field));
                    records.push(std::mem::take(&mut current_record));
                    if i + 1 < len && chars[i + 1] == '\n' {
                        i += 2;
                    } else {
                        i += 1;
                    }
                }
                '\n' => {
                    current_record.push(std::mem::take(&mut current_field));
                    records.push(std::mem::take(&mut current_record));
                    i += 1;
                }
                _ => {
                    current_field.push(c);
                    i += 1;
                }
            }
        }
    }

    // Final field/record
    if !current_field.is_empty() || !current_record.is_empty() {
        current_record.push(current_field);
        records.push(current_record);
    }

    Ok(records)
}

/// Serialize a DataFrame to CSV format.
impl DataFrame {
    /// Serialize to CSV string (RFC 4180). Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `String`.
    #[allow(clippy::needless_range_loop)]
    pub fn to_csv(&self) -> String {
        let mut out = String::new();
        // Header row
        for (i, name) in self.columns().iter().enumerate() {
            if i > 0 {
                out.push(',');
            }
            csv_write_field(&mut out, name);
        }
        out.push('\n');
        // Data rows
        let nrows = self.nrows();
        let data = self.raw_data();
        for row_idx in 0..nrows {
            for ci in 0..self.ncols() {
                if ci > 0 {
                    out.push(',');
                }
                let s = data[ci][row_idx].to_string();
                csv_write_field(&mut out, &s);
            }
            out.push('\n');
        }
        out
    }
}

/// Write a field to CSV, quoting if necessary.
fn csv_write_field(out: &mut String, field: &str) {
    if field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r') {
        out.push('"');
        for c in field.chars() {
            if c == '"' {
                out.push('"');
            }
            out.push(c);
        }
        out.push('"');
    } else {
        out.push_str(field);
    }
}

// ---------------------------------------------------------------------------
// JSON (hand-rolled)
// ---------------------------------------------------------------------------

/// Parse JSON (array-of-objects) into a DataFrame.
///
/// # Parameters
/// - `s` — `&str`.
///
/// # Returns
/// `Result<DataFrame, String>`.
///
/// Expects format: `[{"col1": val1, "col2": val2}, ...]`
/// Maps JSON types: number→Number, string→Text, true/false→Bool, null→Nil.
pub fn from_json(s: &str) -> Result<DataFrame, String> {
    let trimmed = s.trim();
    if trimmed.is_empty() || trimmed == "[]" {
        return Ok(DataFrame::new());
    }
    if !trimmed.starts_with('[') {
        return Err("JSON must be an array of objects".to_string());
    }

    let objects = parse_json_array(trimmed)?;
    if objects.is_empty() {
        return Ok(DataFrame::new());
    }

    // Collect all column names in order of first appearance
    let mut col_names: Vec<String> = Vec::new();
    for obj in &objects {
        for (key, _) in obj {
            if !col_names.contains(key) {
                col_names.push(key.clone());
            }
        }
    }

    let ncols = col_names.len();
    let nrows = objects.len();
    let mut data: Vec<Vec<CellValue>> = vec![Vec::with_capacity(nrows); ncols];

    for obj in &objects {
        let lookup: std::collections::HashMap<&str, &CellValue> =
            obj.iter().map(|(k, v)| (k.as_str(), v)).collect();
        for (ci, name) in col_names.iter().enumerate() {
            let val = lookup
                .get(name.as_str())
                .cloned()
                .cloned()
                .unwrap_or(CellValue::Nil);
            data[ci].push(val);
        }
    }

    Ok(DataFrame::from_raw(col_names, data))
}

/// Parse a JSON array of objects. Returns a Vec of objects where each object
/// is a Vec of (key, CellValue) pairs.
fn parse_json_array(s: &str) -> Result<Vec<Vec<(String, CellValue)>>, String> {
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    let mut pos = 0;

    pos = skip_ws(&chars, pos);
    if pos >= len || chars[pos] != '[' {
        return Err("expected '['".to_string());
    }
    pos += 1;

    let mut objects = Vec::new();
    loop {
        pos = skip_ws(&chars, pos);
        if pos >= len {
            return Err("unexpected end of JSON".to_string());
        }
        if chars[pos] == ']' {
            break;
        }
        if !objects.is_empty() {
            if chars[pos] != ',' {
                return Err(format!("expected ',' at position {pos}"));
            }
            pos += 1;
            pos = skip_ws(&chars, pos);
        }
        let (obj, new_pos) = parse_json_object(&chars, pos)?;
        objects.push(obj);
        pos = new_pos;
    }

    Ok(objects)
}

/// Parse a single JSON object, returning key-value pairs and the new position.
fn parse_json_object(
    chars: &[char],
    start: usize,
) -> Result<(Vec<(String, CellValue)>, usize), String> {
    let len = chars.len();
    let mut pos = skip_ws(chars, start);
    if pos >= len || chars[pos] != '{' {
        return Err(format!("expected '{{' at position {pos}"));
    }
    pos += 1;

    let mut pairs = Vec::new();
    loop {
        pos = skip_ws(chars, pos);
        if pos >= len {
            return Err("unexpected end of JSON object".to_string());
        }
        if chars[pos] == '}' {
            pos += 1;
            break;
        }
        if !pairs.is_empty() {
            if chars[pos] != ',' {
                return Err(format!("expected ',' in object at position {pos}"));
            }
            pos += 1;
            pos = skip_ws(chars, pos);
        }

        // Key
        let (key, new_pos) = parse_json_string(chars, pos)?;
        pos = skip_ws(chars, new_pos);
        if pos >= len || chars[pos] != ':' {
            return Err(format!("expected ':' after key at position {pos}"));
        }
        pos += 1;

        // Value
        let (val, new_pos) = parse_json_value(chars, pos)?;
        pos = new_pos;
        pairs.push((key, val));
    }

    Ok((pairs, pos))
}

/// Parse a JSON string (double-quoted).
fn parse_json_string(chars: &[char], start: usize) -> Result<(String, usize), String> {
    let len = chars.len();
    let mut pos = skip_ws(chars, start);
    if pos >= len || chars[pos] != '"' {
        return Err(format!("expected '\"' at position {pos}"));
    }
    pos += 1;
    let mut s = String::new();
    while pos < len {
        let c = chars[pos];
        if c == '"' {
            return Ok((s, pos + 1));
        }
        if c == '\\' {
            pos += 1;
            if pos >= len {
                return Err("unexpected end of string escape".to_string());
            }
            match chars[pos] {
                '"' => s.push('"'),
                '\\' => s.push('\\'),
                '/' => s.push('/'),
                'n' => s.push('\n'),
                'r' => s.push('\r'),
                't' => s.push('\t'),
                'b' => s.push('\u{0008}'),
                'f' => s.push('\u{000C}'),
                'u' => {
                    // \uXXXX
                    if pos + 4 >= len {
                        return Err("incomplete \\u escape".to_string());
                    }
                    let hex: String = chars[pos + 1..pos + 5].iter().collect();
                    let code = u32::from_str_radix(&hex, 16)
                        .map_err(|_| format!("invalid \\u escape: {hex}"))?;
                    if let Some(ch) = char::from_u32(code) {
                        s.push(ch);
                    }
                    pos += 4;
                }
                other => {
                    s.push('\\');
                    s.push(other);
                }
            }
        } else {
            s.push(c);
        }
        pos += 1;
    }
    Err("unterminated string".to_string())
}

/// Parse a JSON value (string, number, bool, null, object, array).
fn parse_json_value(chars: &[char], start: usize) -> Result<(CellValue, usize), String> {
    let len = chars.len();
    let pos = skip_ws(chars, start);
    if pos >= len {
        return Err("unexpected end of JSON value".to_string());
    }

    match chars[pos] {
        '"' => {
            let (s, new_pos) = parse_json_string(chars, pos)?;
            Ok((CellValue::Text(s), new_pos))
        }
        't' => {
            // true
            if pos + 4 <= len && chars[pos..pos + 4].iter().collect::<String>() == "true" {
                Ok((CellValue::Bool(true), pos + 4))
            } else {
                Err(format!("unexpected token at position {pos}"))
            }
        }
        'f' => {
            // false
            if pos + 5 <= len && chars[pos..pos + 5].iter().collect::<String>() == "false" {
                Ok((CellValue::Bool(false), pos + 5))
            } else {
                Err(format!("unexpected token at position {pos}"))
            }
        }
        'n' => {
            // null
            if pos + 4 <= len && chars[pos..pos + 4].iter().collect::<String>() == "null" {
                Ok((CellValue::Nil, pos + 4))
            } else {
                Err(format!("unexpected token at position {pos}"))
            }
        }
        '-' | '0'..='9' => {
            // Number
            let mut end = pos;
            while end < len
                && (chars[end].is_ascii_digit()
                    || chars[end] == '.'
                    || chars[end] == '-'
                    || chars[end] == '+'
                    || chars[end] == 'e'
                    || chars[end] == 'E')
            {
                end += 1;
            }
            let num_str: String = chars[pos..end].iter().collect();
            let n: f64 = num_str
                .parse()
                .map_err(|_| format!("invalid number: {num_str}"))?;
            Ok((CellValue::Number(n), end))
        }
        '{' => {
            // Nested object — store as Text representation
            let (obj, new_pos) = parse_json_object(chars, pos)?;
            let repr: Vec<String> = obj.iter().map(|(k, v)| format!("{k}={v}")).collect();
            Ok((CellValue::Text(format!("{{{}}}", repr.join(","))), new_pos))
        }
        '[' => {
            // Nested array — skip and store as Text
            let (repr, new_pos) = skip_json_array(chars, pos)?;
            Ok((CellValue::Text(repr), new_pos))
        }
        _ => Err(format!(
            "unexpected character '{}' at position {pos}",
            chars[pos]
        )),
    }
}

/// Skip a JSON array, returning its text representation and the new position.
fn skip_json_array(chars: &[char], start: usize) -> Result<(String, usize), String> {
    let len = chars.len();
    let pos = start;
    if pos >= len || chars[pos] != '[' {
        return Err("expected '['".to_string());
    }
    let mut depth = 0;
    let mut end = pos;
    while end < len {
        match chars[end] {
            '[' => depth += 1,
            ']' => {
                depth -= 1;
                if depth == 0 {
                    let s: String = chars[pos..=end].iter().collect();
                    return Ok((s, end + 1));
                }
            }
            '"' => {
                // Skip string
                end += 1;
                while end < len && chars[end] != '"' {
                    if chars[end] == '\\' {
                        end += 1;
                    }
                    end += 1;
                }
            }
            _ => {}
        }
        end += 1;
    }
    Err("unterminated array".to_string())
}

/// Skip whitespace.
fn skip_ws(chars: &[char], start: usize) -> usize {
    let mut pos = start;
    while pos < chars.len() && chars[pos].is_ascii_whitespace() {
        pos += 1;
    }
    pos
}

/// Serialize a DataFrame to JSON (array-of-objects).
impl DataFrame {
    /// Serialize to JSON string (array-of-objects format).
    ///
    /// # Returns
    /// `String`.
    #[allow(clippy::needless_range_loop)]
    pub fn to_json(&self) -> String {
        let mut out = String::from("[");
        let nrows = self.nrows();
        let data = self.raw_data();
        let cols = self.columns();
        for row_idx in 0..nrows {
            if row_idx > 0 {
                out.push(',');
            }
            out.push('{');
            for (ci, name) in cols.iter().enumerate() {
                if ci > 0 {
                    out.push(',');
                }
                out.push('"');
                json_escape_string(&mut out, name);
                out.push_str("\":");
                json_write_value(&mut out, &data[ci][row_idx]);
            }
            out.push('}');
        }
        out.push(']');
        out
    }
}

/// Escape a string for JSON output.
fn json_escape_string(out: &mut String, s: &str) {
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c < '\x20' => {
                out.push_str(&format!("\\u{:04x}", c as u32));
            }
            _ => out.push(c),
        }
    }
}

/// Write a CellValue as a JSON value.
fn json_write_value(out: &mut String, val: &CellValue) {
    match val {
        CellValue::Nil => out.push_str("null"),
        CellValue::Number(n) => {
            if *n == (*n as i64) as f64 && n.is_finite() {
                out.push_str(&format!("{}", *n as i64));
            } else {
                out.push_str(&format!("{n}"));
            }
        }
        CellValue::Text(s) => {
            out.push('"');
            json_escape_string(out, s);
            out.push('"');
        }
        CellValue::Bool(b) => {
            out.push_str(if *b { "true" } else { "false" });
        }
    }
}

// ---------------------------------------------------------------------------
// LVDF Binary Format
// ---------------------------------------------------------------------------

// Wire format:
//   Magic:   "LVDF" (4 bytes)
//   Version: u8 = 1
//   ncols:   u32 LE
//   nrows:   u32 LE
//   For each column:
//     name_len: u32 LE
//     name:     UTF-8 bytes
//   For each column, for each row:
//     tag: u8  (0=Nil, 1=Number, 2=Text, 3=Bool)
//     payload: (Number=8 bytes f64 LE, Text=u32 LE len + bytes, Bool=1 byte, Nil=none)

impl DataFrame {
    /// Serialize to LVDF binary format. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn to_binary(&self) -> Vec<u8> {
        let mut buf = Vec::new();
        // Magic
        buf.extend_from_slice(b"LVDF");
        // Version
        buf.push(1u8);
        // ncols, nrows
        let ncols = self.ncols() as u32;
        let nrows = self.nrows() as u32;
        buf.extend_from_slice(&ncols.to_le_bytes());
        buf.extend_from_slice(&nrows.to_le_bytes());

        // Column names
        for name in self.columns() {
            let name_bytes = name.as_bytes();
            buf.extend_from_slice(&(name_bytes.len() as u32).to_le_bytes());
            buf.extend_from_slice(name_bytes);
        }

        // Cell data
        let data = self.raw_data();
        for col in data {
            for cell in col {
                match cell {
                    CellValue::Nil => buf.push(0),
                    CellValue::Number(n) => {
                        buf.push(1);
                        buf.extend_from_slice(&n.to_le_bytes());
                    }
                    CellValue::Text(s) => {
                        buf.push(2);
                        let bytes = s.as_bytes();
                        buf.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
                        buf.extend_from_slice(bytes);
                    }
                    CellValue::Bool(b) => {
                        buf.push(3);
                        buf.push(if *b { 1 } else { 0 });
                    }
                }
            }
        }

        buf
    }
}

/// Deserialize a DataFrame from LVDF binary format.
///
/// # Parameters
/// - `data` — `&[u8]`.
///
/// # Returns
/// `Result<DataFrame, String>`.
pub fn from_binary(data: &[u8]) -> Result<DataFrame, String> {
    let len = data.len();
    if len < 13 {
        return Err("LVDF data too short".to_string());
    }

    // Magic
    if &data[0..4] != b"LVDF" {
        return Err("invalid LVDF magic bytes".to_string());
    }

    // Version
    let version = data[4];
    if version != 1 {
        return Err(format!("unsupported LVDF version: {version}"));
    }

    // ncols, nrows
    let ncols = u32::from_le_bytes([data[5], data[6], data[7], data[8]]) as usize;
    let nrows = u32::from_le_bytes([data[9], data[10], data[11], data[12]]) as usize;

    // Guard against unreasonable sizes
    if ncols > 10_000 || nrows > 10_000_000 {
        return Ok(DataFrame::new());
    }

    let mut pos = 13;

    // Column names
    let mut column_names = Vec::with_capacity(ncols);
    for _ in 0..ncols {
        if pos + 4 > len {
            return Err("LVDF truncated reading column name length".to_string());
        }
        let name_len =
            u32::from_le_bytes([data[pos], data[pos + 1], data[pos + 2], data[pos + 3]]) as usize;
        pos += 4;
        if pos + name_len > len {
            return Err("LVDF truncated reading column name".to_string());
        }
        let name = std::str::from_utf8(&data[pos..pos + name_len])
            .map_err(|e| format!("invalid UTF-8 in column name: {e}"))?;
        column_names.push(name.to_string());
        pos += name_len;
    }

    // Cell data
    let mut columns: Vec<Vec<CellValue>> = vec![Vec::with_capacity(nrows); ncols];
    #[allow(clippy::needless_range_loop)]
    for ci in 0..ncols {
        for _ in 0..nrows {
            if pos >= len {
                return Err("LVDF truncated reading cell tag".to_string());
            }
            let tag = data[pos];
            pos += 1;
            let cell = match tag {
                0 => CellValue::Nil,
                1 => {
                    if pos + 8 > len {
                        return Err("LVDF truncated reading number".to_string());
                    }
                    let bytes = [
                        data[pos],
                        data[pos + 1],
                        data[pos + 2],
                        data[pos + 3],
                        data[pos + 4],
                        data[pos + 5],
                        data[pos + 6],
                        data[pos + 7],
                    ];
                    pos += 8;
                    CellValue::Number(f64::from_le_bytes(bytes))
                }
                2 => {
                    if pos + 4 > len {
                        return Err("LVDF truncated reading text length".to_string());
                    }
                    let slen = u32::from_le_bytes([
                        data[pos],
                        data[pos + 1],
                        data[pos + 2],
                        data[pos + 3],
                    ]) as usize;
                    pos += 4;
                    if pos + slen > len {
                        return Err("LVDF truncated reading text".to_string());
                    }
                    let s = std::str::from_utf8(&data[pos..pos + slen])
                        .map_err(|e| format!("invalid UTF-8 in text cell: {e}"))?;
                    pos += slen;
                    CellValue::Text(s.to_string())
                }
                3 => {
                    if pos >= len {
                        return Err("LVDF truncated reading bool".to_string());
                    }
                    let b = data[pos] != 0;
                    pos += 1;
                    CellValue::Bool(b)
                }
                _ => return Err(format!("unknown LVDF cell tag: {tag}")),
            };
            columns[ci].push(cell);
        }
    }

    Ok(DataFrame::from_raw(column_names, columns))
}

// ---------------------------------------------------------------------------
// ASCII table
// ---------------------------------------------------------------------------

impl DataFrame {
    /// Format the DataFrame as an ASCII table for debug display.
    ///
    /// # Returns
    /// `String`.
    #[allow(clippy::needless_range_loop)]
    pub fn to_string_table(&self) -> String {
        let cols = self.columns();
        let nrows = self.nrows();
        let data = self.raw_data();

        if cols.is_empty() {
            return "(empty DataFrame)".to_string();
        }

        // Compute column widths
        let mut widths: Vec<usize> = cols.iter().map(|n| n.len()).collect();
        for row_idx in 0..nrows {
            for (ci, w) in widths.iter_mut().enumerate() {
                let cell_len = data[ci][row_idx].to_string().len();
                if cell_len > *w {
                    *w = cell_len;
                }
            }
        }

        let mut out = String::new();

        // Separator line
        let sep: String = widths
            .iter()
            .map(|w| "-".repeat(*w + 2))
            .collect::<Vec<_>>()
            .join("+");
        let sep = format!("+{sep}+\n");

        // Header
        out.push_str(&sep);
        out.push('|');
        for (ci, name) in cols.iter().enumerate() {
            out.push_str(&format!(" {:width$} |", name, width = widths[ci]));
        }
        out.push('\n');
        out.push_str(&sep);

        // Rows
        for row_idx in 0..nrows {
            out.push('|');
            for ci in 0..cols.len() {
                let val = data[ci][row_idx].to_string();
                out.push_str(&format!(" {:width$} |", val, width = widths[ci]));
            }
            out.push('\n');
        }
        out.push_str(&sep);

        out
    }
}

use crate::dataframe::frame::Database;

impl Database {
    /// Serialize all tables to a JSON object string.
    ///
    /// # Returns
    /// `String`.
    pub fn to_json(&self) -> String {
        let names = self.list_tables();
        let mut out = String::from("{");
        for (i, name) in names.iter().enumerate() {
            if i > 0 {
                out.push(',');
            }
            out.push('"');
            json_escape_string(&mut out, name);
            out.push_str("\":");
            if let Some(df) = self.get_table(name) {
                out.push_str(&df.to_json());
            } else {
                out.push_str("[]");
            }
        }
        out.push('}');
        out
    }
}
