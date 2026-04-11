//! CSV parsing and serialization for Lurek2D.
//!
//! Converts between CSV strings and `SerialValue` using the `csv` crate.
//! Parses CSV rows into ordered maps keyed by header columns.

use super::lua_table::SerialValue;
use indexmap::IndexMap;

/// Options for CSV parsing and serialization.
///
/// # Fields
/// - `delimiter` — `u8`. Field separator byte (default `b','`).
/// - `has_headers` — `bool`. Whether the first row is a header row (default `true`).
pub struct CsvOptions {
    /// Field separator byte.
    pub delimiter: u8,
    /// Whether the first row contains column headers.
    pub has_headers: bool,
}

impl Default for CsvOptions {
    fn default() -> Self {
        Self {
            delimiter: b',',
            has_headers: true,
        }
    }
}

/// Parse a CSV string into a `SerialValue`.
///
/// Returns a `SerialValue::Seq` of rows. Each row is a `SerialValue::Map`
/// keyed by column headers when `has_headers` is true, or a `SerialValue::Seq`
/// of string values otherwise.
///
/// # Parameters
/// - `s` — `&str`. CSV text.
/// - `opts` — `CsvOptions`. Parse options.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn from_csv(s: &str, opts: CsvOptions) -> Result<SerialValue, String> {
    let mut reader = csv::ReaderBuilder::new()
        .delimiter(opts.delimiter)
        .has_headers(opts.has_headers)
        .from_reader(s.as_bytes());

    if opts.has_headers {
        let headers: Vec<String> = reader
            .headers()
            .map_err(|e| format!("CSV parse error: {e}"))?
            .iter()
            .map(|h| h.to_string())
            .collect();

        let mut rows = Vec::new();
        for result in reader.records() {
            let record = result.map_err(|e| format!("CSV parse error: {e}"))?;
            let mut map = IndexMap::new();
            for (i, field) in record.iter().enumerate() {
                let key = headers.get(i).cloned().unwrap_or_else(|| i.to_string());
                map.insert(key, SerialValue::Str(field.to_string()));
            }
            rows.push(SerialValue::Map(map));
        }
        Ok(SerialValue::Seq(rows))
    } else {
        let mut rows = Vec::new();
        for result in reader.records() {
            let record = result.map_err(|e| format!("CSV parse error: {e}"))?;
            let fields: Vec<SerialValue> = record
                .iter()
                .map(|f| SerialValue::Str(f.to_string()))
                .collect();
            rows.push(SerialValue::Seq(fields));
        }
        Ok(SerialValue::Seq(rows))
    }
}

/// Serialize a `SerialValue` to a CSV string.
///
/// Converts a `SerialValue::Seq` of `SerialValue::Map` rows to CSV.
///
/// # Parameters
/// - `val` — `&SerialValue`. A sequence of maps (rows).
/// - `opts` — `CsvOptions`. Serialization options.
///
/// # Returns
/// `Result<String, String>`.
pub fn to_csv(val: &SerialValue, opts: CsvOptions) -> Result<String, String> {
    let rows = match val {
        SerialValue::Seq(rows) => rows,
        _ => return Err("to_csv: expected a sequence of rows".to_string()),
    };

    let mut out = Vec::new();
    let mut writer = csv::WriterBuilder::new()
        .delimiter(opts.delimiter)
        .from_writer(&mut out);

    // Collect headers from the first row if has_headers
    if opts.has_headers {
        if let Some(first) = rows.first() {
            match first {
                SerialValue::Map(map) => {
                    let headers: Vec<&str> = map.keys().map(|k| k.as_str()).collect();
                    writer
                        .write_record(&headers)
                        .map_err(|e| format!("CSV encode error: {e}"))?;
                }
                _ => return Err("to_csv: rows must be maps when has_headers is true".to_string()),
            }
        }
    }

    for row in rows {
        match row {
            SerialValue::Map(map) => {
                let values: Vec<String> = map.values().map(serial_value_to_csv_field).collect();
                writer
                    .write_record(&values)
                    .map_err(|e| format!("CSV encode error: {e}"))?;
            }
            SerialValue::Seq(fields) => {
                let values: Vec<String> = fields.iter().map(serial_value_to_csv_field).collect();
                writer
                    .write_record(&values)
                    .map_err(|e| format!("CSV encode error: {e}"))?;
            }
            _ => return Err("to_csv: each row must be a map or sequence".to_string()),
        }
    }

    writer
        .flush()
        .map_err(|e| format!("CSV encode error: {e}"))?;
    drop(writer);
    String::from_utf8(out).map_err(|e| format!("CSV encode error: {e}"))
}

/// Convert a `SerialValue` to a CSV field string.
fn serial_value_to_csv_field(val: &SerialValue) -> String {
    match val {
        SerialValue::Null => String::new(),
        SerialValue::Bool(b) => b.to_string(),
        SerialValue::Int(n) => n.to_string(),
        SerialValue::Float(f) => f.to_string(),
        SerialValue::Str(s) => s.clone(),
        SerialValue::Seq(_) | SerialValue::Map(_) => "[complex]".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::serial::lua_table::SerialValue;

    #[test]
    fn from_csv_with_headers_returns_seq_of_maps() {
        let csv = "name,score\nalice,10\nbob,20\n";
        let result = from_csv(csv, CsvOptions::default()).unwrap();
        match result {
            SerialValue::Seq(rows) => {
                assert_eq!(rows.len(), 2);
                match &rows[0] {
                    SerialValue::Map(m) => {
                        assert!(matches!(m.get("name"), Some(SerialValue::Str(s)) if s == "alice"));
                    }
                    other => panic!("expected Map, got {:?}", other),
                }
            }
            other => panic!("expected Seq, got {:?}", other),
        }
    }

    #[test]
    fn from_csv_no_headers_returns_seq_of_seqs() {
        let csv = "a,b\nc,d\n";
        let opts = CsvOptions { has_headers: false, ..CsvOptions::default() };
        let result = from_csv(csv, opts).unwrap();
        match result {
            SerialValue::Seq(rows) => assert_eq!(rows.len(), 2),
            other => panic!("expected Seq, got {:?}", other),
        }
    }
}
