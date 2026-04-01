//! TOML parsing and encoding for Luna2D.
//!
//! Converts between TOML strings and Lua tables. Supports the full TOML spec
//! via the `toml` crate, mapping types to their Lua equivalents.

/// Parse a TOML string into a `toml::Value`.
///
/// # Parameters
/// - `input` — `&str`.
///
/// # Returns
/// `Result<toml::Value, String>`.
pub fn parse_toml(input: &str) -> Result<toml::Value, String> {
    input
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))
}

/// Encode a `toml::Value` into a TOML string.
///
/// # Parameters
/// - `value` — `&toml::Value`.
///
/// # Returns
/// `Result<String, String>`.
pub fn encode_toml(value: &toml::Value) -> Result<String, String> {
    match value {
        toml::Value::Table(t) => toml::to_string(t).map_err(|e| format!("TOML encode error: {e}")),
        _ => Err("encodeToml expects a table value".into()),
    }
}
