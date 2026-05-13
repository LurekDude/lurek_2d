//! Message catalog loading and lookup for stable log identifiers.
//! Parses TOML once, stores flattened key-value strings, and resolves ids at runtime.

use std::collections::HashMap;
use std::sync::OnceLock;
/// Embedded message catalog source loaded from runtime config assets.
pub const CATALOG_TOML: &str = include_str!("cfg/messages.toml");
static CATALOG: OnceLock<MessageCatalog> = OnceLock::new();
/// Runtime map of log/message identifiers to display text.
pub struct MessageCatalog {
    /// Flattened message text by identifier key.
    messages: HashMap<String, &'static str>,
}
impl MessageCatalog {
    /// Parse TOML and build a message catalog map; keep empty map on parse errors.
    pub fn from_toml(toml_src: &str) -> Self {
        let mut messages = HashMap::new();
        match toml_src.parse::<toml::Value>() {
            Ok(root) => {
                collect_strings(&root, &mut messages);
            }
            Err(e) => {
                log::warn!("[L000] Failed to parse message catalog TOML: {}", e);
            }
        }
        Self { messages }
    }
    /// Fetch message text for one identifier if present.
    pub fn get(&self, id: &str) -> Option<&str> {
        self.messages.get(id).copied()
    }
    /// Count entries currently loaded in the catalog.
    pub fn len(&self) -> usize {
        self.messages.len()
    }
    /// Check whether the catalog has zero loaded entries.
    pub fn is_empty(&self) -> bool {
        self.messages.is_empty()
    }
}
/// Initialize global message catalog exactly once.
pub fn init() {
    CATALOG.get_or_init(|| MessageCatalog::from_toml(CATALOG_TOML));
}
/// Resolve static identifier to message text, or fall back to identifier itself.
pub fn get_message(id: &'static str) -> &'static str {
    CATALOG
        .get()
        .and_then(|c| c.messages.get(id).copied())
        .unwrap_or(id)
}
/// Resolve dynamic identifier to owned message text, or fall back to the input id.
pub fn resolve_message(id: &str) -> String {
    init();
    catalog()
        .and_then(|c| c.get(id))
        .map(ToOwned::to_owned)
        .unwrap_or_else(|| id.to_string())
}
/// Report whether the catalog currently contains a given identifier.
pub fn has_message(id: &str) -> bool {
    init();
    catalog().map(|c| c.get(id).is_some()).unwrap_or(false)
}
/// Return number of loaded messages after ensuring initialization.
pub fn message_count() -> usize {
    init();
    catalog().map(MessageCatalog::len).unwrap_or(0)
}
/// Return borrowed global catalog if it has already been initialized.
pub fn catalog() -> Option<&'static MessageCatalog> {
    CATALOG.get()
}
/// Recursively collect string leaves from TOML tables into `out` map.
fn collect_strings(val: &toml::Value, out: &mut HashMap<String, &'static str>) {
    if let toml::Value::Table(table) = val {
        for (key, child) in table {
            match child {
                toml::Value::String(s) => {
                    let static_str: &'static str = Box::leak(s.clone().into_boxed_str());
                    out.insert(key.clone(), static_str);
                }
                toml::Value::Table(_) => {
                    collect_strings(child, out);
                }
                _ => {}
            }
        }
    }
}
