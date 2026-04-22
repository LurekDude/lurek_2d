//! SaveManager, SlotMeta, SaveValue, and Lua serialization helpers.

use std::collections::HashMap;

use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use mlua::prelude::{LuaError, LuaResult, LuaValue};

use crate::data::compress::{compress, decompress, CompressFormat};

use crate::log_msg;
use crate::runtime::log_messages::{SV01, SV02, SV03, SV04};

/// Metadata extracted from a save slot.
///
/// # Fields
/// - `slot` â€” `String`. Slot name.
/// - `timestamp` â€” `f64`. Unix epoch timestamp.
/// - `version` â€” `i32`. Schema version.
/// - `summary` â€” `String`. Optional summary string.
#[derive(Debug, Clone, Default)]
pub struct SlotMeta {
    /// Slot name.
    pub slot: String,
    /// Unix epoch timestamp.
    pub timestamp: f64,
    /// Schema version.
    pub version: i32,
    /// Optional summary string.
    pub summary: String,
}

/// Pure-data save manager providing registration of named collectors,
/// schema versioning, dirty-state tracking, and auto-save timer.
///
/// Actual serialisation and filesystem calls happen on the Lua side;
/// this struct tracks the bookkeeping.
#[derive(Debug, Default)]
pub struct SaveManager {
    /// Current schema version for new saves.
    schema_version: i32,
    /// Registered collector module names.
    registered: Vec<String>,
    /// Whether data has been modified since last save/load.
    dirty: bool,
    /// Auto-save interval (seconds) and target slot.
    auto_save: Option<(f64, String)>,
    /// Elapsed time since last auto-save.
    auto_save_elapsed: f64,
    /// Migration version keys (sorted ascending on use).
    migration_versions: Vec<i32>,
    /// User-provided summary string for save metadata.
    summary: String,
}

impl SaveManager {
    /// Create a new empty SaveManager.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, SV01);
        Self::default()
    }

    /// Register a named collector module.
    ///
    /// # Parameters
    /// - `name` â€” `impl Into<String>`. The collector module name to register.
    pub fn register(&mut self, name: impl Into<String>) {
        let name = name.into();
        if !self.registered.contains(&name) {
            log_msg!(debug, SV02, "{}", name);
            self.registered.push(name);
        }
    }

    /// Unregister a collector by name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. The collector name to unregister.
    pub fn unregister(&mut self, name: &str) {
        log_msg!(debug, SV03, "{}", name);
        self.registered.retain(|n| n != name);
    }

    /// Get registered module names.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn registered_names(&self) -> &[String] {
        &self.registered
    }

    /// Set the current schema version.
    ///
    /// # Parameters
    /// - `version` â€” `i32`. New schema version number.
    pub fn set_schema_version(&mut self, version: i32) {
        self.schema_version = version;
    }

    /// Get the current schema version.
    ///
    /// # Returns
    /// `i32`.
    pub fn schema_version(&self) -> i32 {
        self.schema_version
    }

    /// Record a migration version key.
    ///
    /// # Parameters
    /// - `from_version` â€” `i32`. The schema version this migration upgrades from.
    pub fn add_migration(&mut self, from_version: i32) {
        if !self.migration_versions.contains(&from_version) {
            self.migration_versions.push(from_version);
            self.migration_versions.sort();
        }
    }

    /// Get migration versions >=`from` and < current, in ascending order.
    ///
    /// # Parameters
    /// - `from` â€” `i32`. The schema version of the save being loaded.
    ///
    /// # Returns
    /// `Vec<i32>`.
    pub fn applicable_migrations(&self, from: i32) -> Vec<i32> {
        self.migration_versions
            .iter()
            .copied()
            .filter(|&v| v >= from && v < self.schema_version)
            .collect()
    }

    /// Mark data as dirty (modified since last save/load).
    pub fn mark_dirty(&mut self) {
        self.dirty = true;
    }

    /// Whether data is dirty.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }

    /// Clear the dirty flag (called after save/load).
    pub fn clear_dirty(&mut self) {
        self.dirty = false;
    }

    /// Enable auto-save with interval and target slot.
    ///
    /// # Parameters
    /// - `interval` â€” `f64`. Auto-save interval in seconds.
    /// - `slot` â€” `impl Into<String>`. Target save slot name.
    pub fn enable_auto_save(&mut self, interval: f64, slot: impl Into<String>) {
        let slot = slot.into();
        log_msg!(debug, SV04, "{} @ {:.3}s", slot, interval);
        self.auto_save = Some((interval, slot));
        self.auto_save_elapsed = 0.0;
    }

    /// Disable auto-save.
    pub fn disable_auto_save(&mut self) {
        self.auto_save = None;
        self.auto_save_elapsed = 0.0;
    }

    /// Advance the auto-save timer. Returns `Some(slot)` if a save should trigger.
    ///
    /// # Parameters
    /// - `dt` â€” `f64`. Delta time in seconds.
    ///
    /// # Returns
    /// `Option<String>`.
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

    /// Reset all state. After this call the container is in the same state as
    /// immediately after construction.
    pub fn reset(&mut self) {
        *self = Self::default();
    }

    /// Build the save file path for a given slot name.
    ///
    /// Slot files are stored in the `save/` directory with a `slot_` prefix
    /// and `.sav` extension.
    ///
    /// # Parameters
    /// - `slot` â€” `&str`. The slot name.
    ///
    /// # Returns
    /// `String`.
    pub fn slot_path(slot: &str) -> String {
        format!("save/slot_{}.sav", slot)
    }

    /// Set the summary string for save metadata.
    ///
    /// # Parameters
    /// - `summary` â€” `String`. The summary text.
    pub fn set_summary(&mut self, summary: String) {
        self.summary = summary;
    }

    /// Get the summary string.
    ///
    /// # Returns
    /// `&str`.
    pub fn summary(&self) -> &str {
        &self.summary
    }

    /// Validates and returns save-file content, rejecting empty input.
    ///
    /// # Parameters
    /// - `content` â€” `&str`. The raw save-file string.
    ///
    /// # Returns
    /// `Result<String, String>`.
    pub fn parse_save_string(content: &str) -> Result<String, String> {
        if content.trim().is_empty() {
            return Err("save file is empty".to_string());
        }
        Ok(content.to_string())
    }
}

/// Serialize a simple Lua-compatible value hierarchy into a `return { ... }` string.
///
/// Supports nil, bool, number (f64), string, and nested tables (HashMap).
/// Does not handle userdata, functions, or circular references.
///
/// # Parameters
/// - `data` â€” `&HashMap<String, SaveValue>`. The table data to serialize.
/// - `depth` â€” `u32`. Current nesting depth (internal; call with `0`).
///
/// # Returns
/// `Result<String, String>`.
pub fn serialize_table(data: &HashMap<String, SaveValue>, depth: u32) -> Result<String, String> {
    // Guard against deeply nested or circular structures.
    if depth > 32 {
        return Err("serialization depth limit exceeded (>32)".to_string());
    }
    let mut out = String::from("{\n");
    let indent = "  ".repeat((depth + 1) as usize);
    let close_indent = "  ".repeat(depth as usize);
    for (key, value) in data {
        // Bare identifiers go unquoted; keys with spaces/special chars use ["..."] syntax.
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

/// Serialize a single value.
///
/// # Parameters
/// - `value` â€” `&SaveValue`. The value to serialize.
/// - `depth` â€” `u32`. Current nesting depth.
///
/// # Returns
/// `Result<String, String>`.
pub fn serialize_value(value: &SaveValue, depth: u32) -> Result<String, String> {
    match value {
        SaveValue::Nil => Ok("nil".to_string()),
        SaveValue::Bool(b) => Ok(b.to_string()),
        SaveValue::Number(n) => Ok(format!("{}", n)),
        SaveValue::Str(s) => Ok(format!("\"{}\"", escape_lua_str(s))),
        SaveValue::Table(t) => serialize_table(t, depth),
    }
}

/// A simple value type matching the Lua subset we can serialize.
///
/// # Variants
/// - `Nil` â€” Lua nil.
/// - `Bool` â€” Lua boolean.
/// - `Number` â€” Lua number.
/// - `Str` â€” Lua string.
/// - `Table` â€” Lua table (string keys only for save data).
#[derive(Debug, Clone)]
pub enum SaveValue {
    /// Lua nil.
    Nil,
    /// Lua boolean.
    Bool(bool),
    /// Lua number.
    Number(f64),
    /// Lua string.
    Str(String),
    /// Lua table (string keys only for save data).
    Table(HashMap<String, SaveValue>),
}

impl SaveValue {
    /// Converts a [`LuaValue`] into a [`SaveValue`] for Rust-side serialization.
    ///
    /// # Parameters
    /// - `value` â€” `&LuaValue`. The Lua value to convert.
    ///
    /// # Returns
    /// `LuaResult<Self>`.
    pub fn from_lua(value: &LuaValue) -> LuaResult<Self> {
        // Recursively convert Lua values to the SaveValue subset.
        // Integer and Number both map to Number(f64) since save files don't
        // distinguish integer vs float.
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

// ── Save-file compression helpers ──────────────────────────────────────────────

/// Prefix marker written at the top of compressed save files.
const COMPRESSED_MARKER: &str = "--[[COMPRESSED]]";

/// Compress a serialised save string with LZ4, then base64-encode it.
///
/// The returned string has the form:
/// ```text
/// --[[COMPRESSED]]
/// return "<base64>"
/// ```
///
/// # Parameters
/// - `plain` — `&str`. The raw `return { ... }` save content.
///
/// # Returns
/// `Result<String, String>` — the wrapped, encoded payload, or an error message.
pub fn compress_save_content(plain: &str) -> Result<String, String> {
    let compressed = compress(plain.as_bytes(), CompressFormat::Lz4, 1)?;
    let encoded = BASE64.encode(&compressed);
    Ok(format!("{}\nreturn \"{}\"\n", COMPRESSED_MARKER, encoded))
}

/// Detect and decode a compressed save file, or pass through an uncompressed one.
///
/// If `raw` starts with the `--[[COMPRESSED]]` marker, the second line is
/// expected to contain `return "<base64>"`. The base64 payload is decoded and
/// LZ4-decompressed back to the original `return { ... }` string.
///
/// Uncompressed content is returned unchanged.
///
/// # Parameters
/// - `raw` — `&str`. The raw file content read from disk.
///
/// # Returns
/// `Result<String, String>` — the decompressed content, or an error message.
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
