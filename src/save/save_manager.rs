use crate::data::compress::{compress, decompress, CompressFormat};
use crate::log_msg;
use crate::runtime::log_messages::{SV01, SV02, SV03, SV04};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use mlua::prelude::{LuaError, LuaResult, LuaValue};
use std::collections::HashMap;
#[derive(Debug, Clone, Default)]
pub struct SlotMeta {
    pub slot: String,
    pub timestamp: f64,
    pub version: i32,
    pub summary: String,
}
#[derive(Debug, Default)]
pub struct SaveManager {
    schema_version: i32,
    registered: Vec<String>,
    dirty: bool,
    auto_save: Option<(f64, String)>,
    auto_save_elapsed: f64,
    migration_versions: Vec<i32>,
    summary: String,
}
impl SaveManager {
    pub fn new() -> Self {
        log_msg!(debug, SV01);
        Self::default()
    }
    pub fn register(&mut self, name: impl Into<String>) {
        let name = name.into();
        if !self.registered.contains(&name) {
            log_msg!(debug, SV02, "{}", name);
            self.registered.push(name);
        }
    }
    pub fn unregister(&mut self, name: &str) {
        log_msg!(debug, SV03, "{}", name);
        self.registered.retain(|n| n != name);
    }
    pub fn registered_names(&self) -> &[String] {
        &self.registered
    }
    pub fn set_schema_version(&mut self, version: i32) {
        self.schema_version = version;
    }
    pub fn schema_version(&self) -> i32 {
        self.schema_version
    }
    pub fn add_migration(&mut self, from_version: i32) {
        if !self.migration_versions.contains(&from_version) {
            self.migration_versions.push(from_version);
            self.migration_versions.sort();
        }
    }
    pub fn applicable_migrations(&self, from: i32) -> Vec<i32> {
        self.migration_versions
            .iter()
            .copied()
            .filter(|&v| v >= from && v < self.schema_version)
            .collect()
    }
    pub fn mark_dirty(&mut self) {
        self.dirty = true;
    }
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }
    pub fn clear_dirty(&mut self) {
        self.dirty = false;
    }
    pub fn enable_auto_save(&mut self, interval: f64, slot: impl Into<String>) {
        let slot = slot.into();
        log_msg!(debug, SV04, "{} @ {:.3}s", slot, interval);
        self.auto_save = Some((interval, slot));
        self.auto_save_elapsed = 0.0;
    }
    pub fn disable_auto_save(&mut self) {
        self.auto_save = None;
        self.auto_save_elapsed = 0.0;
    }
    pub fn update(&mut self, dt: f64) -> Option<String> {
        if let Some((interval, ref slot)) = self.auto_save {
            self.auto_save_elapsed += dt;
            if self.dirty && self.auto_save_elapsed >= interval {
                self.auto_save_elapsed = 0.0;
                return Some(slot.clone());
            }
        }
        None
    }
    pub fn reset(&mut self) {
        *self = Self::default();
    }
    pub fn slot_path(slot: &str) -> String {
        format!("save/slot_{}.sav", slot)
    }
    pub fn set_summary(&mut self, summary: String) {
        self.summary = summary;
    }
    pub fn summary(&self) -> &str {
        &self.summary
    }
    pub fn parse_save_string(content: &str) -> Result<String, String> {
        if content.trim().is_empty() {
            return Err("save file is empty".to_string());
        }
        Ok(content.to_string())
    }
}
pub fn serialize_table(data: &HashMap<String, SaveValue>, depth: u32) -> Result<String, String> {
    if depth > 32 {
        return Err("serialization depth limit exceeded (>32)".to_string());
    }
    let mut out = String::from("{\n");
    let indent = "  ".repeat((depth + 1) as usize);
    let close_indent = "  ".repeat(depth as usize);
    for (key, value) in data {
        let key_str = if is_lua_identifier(key) {
            key.clone()
        } else {
            format!("[\"{}\"]", escape_lua_str(key))
        };
        out.push_str(&format!(
            "{}{} = {},\n",
            indent,
            key_str,
            serialize_value(value, depth + 1)?
        ));
    }
    out.push_str(&format!("{}}}", close_indent));
    Ok(out)
}
pub fn serialize_value(value: &SaveValue, depth: u32) -> Result<String, String> {
    match value {
        SaveValue::Nil => Ok("nil".to_string()),
        SaveValue::Bool(b) => Ok(b.to_string()),
        SaveValue::Number(n) => Ok(format!("{}", n)),
        SaveValue::Str(s) => Ok(format!("\"{}\"", escape_lua_str(s))),
        SaveValue::Table(t) => serialize_table(t, depth),
    }
}
#[derive(Debug, Clone)]
pub enum SaveValue {
    Nil,
    Bool(bool),
    Number(f64),
    Str(String),
    Table(HashMap<String, SaveValue>),
}
impl SaveValue {
    pub fn from_lua(value: &LuaValue) -> LuaResult<Self> {
        match value {
            LuaValue::Nil => Ok(SaveValue::Nil),
            LuaValue::Boolean(b) => Ok(SaveValue::Bool(*b)),
            LuaValue::Integer(i) => Ok(SaveValue::Number(*i as f64)),
            LuaValue::Number(n) => Ok(SaveValue::Number(*n)),
            LuaValue::String(s) => Ok(SaveValue::Str(s.to_str()?.to_string())),
            LuaValue::Table(t) => {
                let mut map = HashMap::new();
                for pair in t.clone().pairs::<LuaValue, LuaValue>() {
                    let (k, v) = pair?;
                    let key_str = match &k {
                        LuaValue::String(s) => s.to_str()?.to_string(),
                        LuaValue::Integer(i) => i.to_string(),
                        LuaValue::Number(n) => format!("{}", n),
                        _ => {
                            return Err(LuaError::RuntimeError(format!(
                                "cannot serialize table key of type {}",
                                k.type_name()
                            )))
                        }
                    };
                    map.insert(key_str, SaveValue::from_lua(&v)?);
                }
                Ok(SaveValue::Table(map))
            }
            other => Err(LuaError::RuntimeError(format!(
                "cannot serialize value of type {}",
                other.type_name()
            ))),
        }
    }
}
fn is_lua_identifier(s: &str) -> bool {
    let mut chars = s.chars();
    match chars.next() {
        Some(c) if c.is_ascii_alphabetic() || c == '_' => {}
        _ => return false,
    }
    chars.all(|c| c.is_ascii_alphanumeric() || c == '_')
}
fn escape_lua_str(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\0', "\\0")
}
const COMPRESSED_MARKER: &str = "--[[COMPRESSED]]";
pub fn compress_save_content(plain: &str) -> Result<String, String> {
    let compressed = compress(plain.as_bytes(), CompressFormat::Lz4, 1)?;
    let encoded = BASE64.encode(&compressed);
    Ok(format!("{}\nreturn \"{}\"\n", COMPRESSED_MARKER, encoded))
}
pub fn decompress_save_content(raw: &str) -> Result<String, String> {
    if !raw.starts_with(COMPRESSED_MARKER) {
        return Ok(raw.to_string());
    }
    let encoded = raw
        .lines()
        .nth(1)
        .and_then(|line| line.strip_prefix("return \""))
        .and_then(|s| s.strip_suffix('"'))
        .unwrap_or_default();
    let compressed = BASE64
        .decode(encoded)
        .map_err(|e| format!("base64 decode: {}", e))?;
    let bytes = decompress(&compressed, CompressFormat::Lz4)?;
    String::from_utf8(bytes).map_err(|e| format!("utf8: {}", e))
}
