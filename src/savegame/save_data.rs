//! Save/load slot system with collectors, schema versioning, dirty tracking,
//! and auto-save.

use std::collections::HashMap;

/// Metadata extracted from a save slot.
///
/// # Fields
/// - `slot` — `String`.
/// - `timestamp` — `f64`.
/// - `version` — `i32`.
/// - `summary` — `String`.
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
}

impl SaveManager {
    /// Create a new empty SaveManager.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a named collector module.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    pub fn register(&mut self, name: impl Into<String>) {
        let name = name.into();
        if !self.registered.contains(&name) {
            self.registered.push(name);
        }
    }

    /// Unregister a collector by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn unregister(&mut self, name: &str) {
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
    /// - `version` — `i32`.
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
    /// - `from_version` — `i32`.
    pub fn add_migration(&mut self, from_version: i32) {
        if !self.migration_versions.contains(&from_version) {
            self.migration_versions.push(from_version);
            self.migration_versions.sort();
        }
    }

    /// Get migration versions >=`from` and < current, in ascending order.
    ///
    /// # Parameters
    /// - `from` — `i32`.
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
    /// - `interval` — `f64`.
    /// - `slot` — `impl Into<String>`.
    pub fn enable_auto_save(&mut self, interval: f64, slot: impl Into<String>) {
        self.auto_save = Some((interval, slot.into()));
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
    /// - `dt` — `f64`.
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

    /// Reset all state.
    pub fn reset(&mut self) {
        *self = Self::default();
    }
}

/// Serialize a simple Lua-compatible value hierarchy into a `return { ... }` string.
///
/// # Parameters
/// - `data` — `&HashMap<String, SaveValue>`.
/// - `depth` — `u32`.
///
/// # Returns
/// `Result<String, String>`.
///
/// Supports nil, bool, number (f64), string, and nested tables (HashMap).
/// Does not handle userdata, functions, or circular references.
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

/// Serialize a single value.
///
/// # Parameters
/// - `value` — `&SaveValue`.
/// - `depth` — `u32`.
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
/// - `Nil` — Nil variant.
/// - `Bool` — Bool variant.
/// - `Number` — Number variant.
/// - `Str` — Str variant.
/// - `Table` — Table variant.
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn save_manager_defaults() {
        let sm = SaveManager::new();
        assert_eq!(sm.schema_version(), 0);
        assert!(!sm.is_dirty());
        assert!(sm.registered_names().is_empty());
    }

    #[test]
    fn register_unregister() {
        let mut sm = SaveManager::new();
        sm.register("player");
        sm.register("inventory");
        assert_eq!(sm.registered_names().len(), 2);
        sm.unregister("player");
        assert_eq!(sm.registered_names(), &["inventory"]);
    }

    #[test]
    fn dirty_tracking() {
        let mut sm = SaveManager::new();
        assert!(!sm.is_dirty());
        sm.mark_dirty();
        assert!(sm.is_dirty());
        sm.clear_dirty();
        assert!(!sm.is_dirty());
    }

    #[test]
    fn auto_save_triggers() {
        let mut sm = SaveManager::new();
        sm.enable_auto_save(5.0, "quick");
        sm.mark_dirty();
        assert!(sm.update(4.0).is_none());
        assert_eq!(sm.update(1.5).unwrap(), "quick");
    }

    #[test]
    fn auto_save_not_when_clean() {
        let mut sm = SaveManager::new();
        sm.enable_auto_save(1.0, "slot");
        assert!(sm.update(2.0).is_none()); // not dirty
    }

    #[test]
    fn migrations() {
        let mut sm = SaveManager::new();
        sm.set_schema_version(5);
        sm.add_migration(1);
        sm.add_migration(3);
        sm.add_migration(7); // above current
        let applicable = sm.applicable_migrations(2);
        assert_eq!(applicable, vec![3]);
    }

    #[test]
    fn serialize_simple() {
        let mut data = HashMap::new();
        data.insert("name".to_string(), SaveValue::Str("hero".to_string()));
        data.insert("level".to_string(), SaveValue::Number(5.0));
        data.insert("active".to_string(), SaveValue::Bool(true));
        let s = serialize_table(&data, 0).unwrap();
        assert!(s.contains("name = \"hero\""));
        assert!(s.contains("level = 5"));
        assert!(s.contains("active = true"));
    }

    #[test]
    fn serialize_depth_limit() {
        let inner = HashMap::new();
        let mut current = SaveValue::Table(inner);
        for _ in 0..35 {
            let mut t = HashMap::new();
            t.insert("nested".to_string(), current);
            current = SaveValue::Table(t);
        }
        if let SaveValue::Table(t) = current {
            let result = serialize_table(&t, 0);
            assert!(result.is_err());
        }
    }

    #[test]
    fn reset_clears_all() {
        let mut sm = SaveManager::new();
        sm.register("a");
        sm.set_schema_version(3);
        sm.mark_dirty();
        sm.enable_auto_save(1.0, "slot");
        sm.reset();
        assert!(!sm.is_dirty());
        assert_eq!(sm.schema_version(), 0);
        assert!(sm.registered_names().is_empty());
    }
}
