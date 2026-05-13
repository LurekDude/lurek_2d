use super::lua_table::SerialValue;
use indexmap::IndexMap;
pub fn parse_toml(input: &str) -> Result<toml::Value, String> {
    input
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))
}
pub fn from_toml(s: &str) -> Result<SerialValue, String> {
    let v = parse_toml(s)?;
    Ok(toml_to_serial(v))
}
pub fn encode_toml(value: &toml::Value) -> Result<String, String> {
    match value {
        toml::Value::Table(t) => toml::to_string(t).map_err(|e| format!("TOML encode error: {e}")),
        _ => Err("encode_toml expects a table value".into()),
    }
}
pub fn to_toml(val: &SerialValue) -> Result<String, String> {
    let tv = serial_to_toml(val)?;
    encode_toml(&tv)
}
fn toml_to_serial(v: toml::Value) -> SerialValue {
    match v {
        toml::Value::String(s) => SerialValue::Str(s),
        toml::Value::Integer(n) => SerialValue::Int(n),
        toml::Value::Float(f) => SerialValue::Float(f),
        toml::Value::Boolean(b) => SerialValue::Bool(b),
        toml::Value::Datetime(dt) => SerialValue::Str(dt.to_string()),
        toml::Value::Array(arr) => SerialValue::Seq(arr.into_iter().map(toml_to_serial).collect()),
        toml::Value::Table(map) => {
            let mut ordered = IndexMap::new();
            for (k, v) in map {
                ordered.insert(k, toml_to_serial(v));
            }
            SerialValue::Map(ordered)
        }
    }
}
fn serial_to_toml(val: &SerialValue) -> Result<toml::Value, String> {
    match val {
        SerialValue::Null => Err("to_toml: null values are not supported in TOML".to_string()),
        SerialValue::Bool(b) => Ok(toml::Value::Boolean(*b)),
        SerialValue::Int(n) => Ok(toml::Value::Integer(*n)),
        SerialValue::Float(f) => Ok(toml::Value::Float(*f)),
        SerialValue::Str(s) => Ok(toml::Value::String(s.clone())),
        SerialValue::Seq(arr) => {
            let res: Result<Vec<_>, _> = arr.iter().map(serial_to_toml).collect();
            Ok(toml::Value::Array(res?))
        }
        SerialValue::Map(map) => {
            let mut table = toml::map::Map::new();
            for (k, v) in map {
                table.insert(k.clone(), serial_to_toml(v)?);
            }
            Ok(toml::Value::Table(table))
        }
    }
}
