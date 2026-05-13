use super::{
    from_csv, from_ini, from_json, from_toml, from_xml, to_csv, to_json, to_toml, CsvOptions,
};
use super::{from_msgpack, to_msgpack, SerialValue};
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SerialFormat {
    Json,
    Toml,
    Csv,
    MsgPack,
    Xml,
    Ini,
}
impl SerialFormat {
    pub fn parse(s: &str) -> Option<Self> {
        match s.trim().to_ascii_lowercase().as_str() {
            "json" => Some(Self::Json),
            "toml" => Some(Self::Toml),
            "csv" => Some(Self::Csv),
            "msgpack" | "messagepack" | "mpk" => Some(Self::MsgPack),
            "xml" => Some(Self::Xml),
            "ini" => Some(Self::Ini),
            _ => None,
        }
    }
    pub fn from_extension(path: &str) -> Option<Self> {
        let path_lower = path.to_ascii_lowercase();
        let ext = if let Some(dot_idx) = path_lower.rfind('.') {
            &path_lower[dot_idx + 1..]
        } else {
            return None;
        };
        match ext {
            "json" => Some(Self::Json),
            "toml" => Some(Self::Toml),
            "csv" => Some(Self::Csv),
            "msgpack" | "mpk" => Some(Self::MsgPack),
            "xml" => Some(Self::Xml),
            "ini" | "cfg" => Some(Self::Ini),
            _ => None,
        }
    }
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Json => "json",
            Self::Toml => "toml",
            Self::Csv => "csv",
            Self::MsgPack => "msgpack",
            Self::Xml => "xml",
            Self::Ini => "ini",
        }
    }
}
#[derive(Debug, Clone, Copy, Default)]
pub struct DecodeOptions {
    pub csv: CsvOptions,
}
#[derive(Debug, Clone, Copy, Default)]
pub struct EncodeOptions {
    pub json_pretty: bool,
    pub csv: CsvOptions,
}
pub enum EncodedValue {
    Text(String),
    Binary(Vec<u8>),
}
pub fn detect_format(input: &str) -> Option<SerialFormat> {
    let s = input.trim_start();
    if s.is_empty() {
        return None;
    }
    if (s.starts_with('{') || s.starts_with('[')) && from_json(input).is_ok() {
        return Some(SerialFormat::Json);
    }
    if s.starts_with('<') && from_xml(input).is_ok() {
        return Some(SerialFormat::Xml);
    }
    if (s.starts_with('[') || s.contains('=')) && from_toml(input).is_ok() {
        return Some(SerialFormat::Toml);
    }
    let looks_like_csv =
        s.contains('\n') && (s.contains(',') || s.contains(';') || s.contains('\t'));
    if looks_like_csv && from_csv(input, CsvOptions::default()).is_ok() {
        return Some(SerialFormat::Csv);
    }
    if s.contains('=') && from_ini(input).is_ok() {
        return Some(SerialFormat::Ini);
    }
    None
}
pub fn decode_text(
    input: &str,
    format: Option<SerialFormat>,
    opts: DecodeOptions,
) -> Result<SerialValue, String> {
    let detected = format.or_else(|| detect_format(input)).ok_or_else(|| {
        "decode_text: could not detect format (expected json/toml/csv/xml/ini)".to_string()
    })?;
    match detected {
        SerialFormat::Json => from_json(input),
        SerialFormat::Toml => from_toml(input),
        SerialFormat::Csv => from_csv(input, opts.csv),
        SerialFormat::Xml => from_xml(input),
        SerialFormat::Ini => from_ini(input),
        SerialFormat::MsgPack => {
            Err("decode_text: msgpack is binary; use decode_bytes for msgpack".to_string())
        }
    }
}
pub fn decode_bytes(input: &[u8], format: SerialFormat) -> Result<SerialValue, String> {
    match format {
        SerialFormat::MsgPack => from_msgpack(input),
        _ => Err(format!(
            "decode_bytes: format '{}' expects UTF-8 text input",
            format.as_str()
        )),
    }
}
pub fn encode(
    value: &SerialValue,
    format: SerialFormat,
    opts: EncodeOptions,
) -> Result<EncodedValue, String> {
    match format {
        SerialFormat::Json => Ok(EncodedValue::Text(to_json(value, opts.json_pretty)?)),
        SerialFormat::Toml => Ok(EncodedValue::Text(to_toml(value)?)),
        SerialFormat::Csv => Ok(EncodedValue::Text(to_csv(value, opts.csv)?)),
        SerialFormat::MsgPack => Ok(EncodedValue::Binary(to_msgpack(value)?)),
        SerialFormat::Xml => Err("encode: xml encoding is not supported".to_string()),
        SerialFormat::Ini => Err("encode: ini encoding is not supported".to_string()),
    }
}
