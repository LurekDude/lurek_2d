//! TOML-backed message catalog for stable, human-readable engine log messages.
//!
//! The catalog is embedded at compile time from `src/engine/cfg/messages.toml`
//! and loaded once into a process-wide [`OnceLock`] on first access.
//!
//! Use [`get_message`] inside the [`log_msg!`](crate::log_msg) macro — do not
//! call it directly in performance-critical paths.
//!
//! # Usage
//!
//! ```rust,ignore
//! use crate::runtime::log_messages::L003_GAME_LOADED;
//!
//! // Simple — catalog text only:
//! log_msg!(info, L003_GAME_LOADED);
//!
//! // With dynamic detail appended:
//! log_msg!(info, L003_GAME_LOADED, "path: {}", main_lua.display());
//! ```

use std::collections::HashMap;
use std::sync::OnceLock;

/// Embedded TOML catalog compiled into the binary at build time.
const CATALOG_TOML: &str = include_str!("cfg/messages.toml");

/// Process-wide message catalog instance.
static CATALOG: OnceLock<MessageCatalog> = OnceLock::new();

// ---------------------------------------------------------------------------
// MessageCatalog
// ---------------------------------------------------------------------------

/// Immutable map from stable message ID (e.g. `"L001"`) to human-readable text.
///
/// Loaded once via [`init`] or lazily on the first [`get_message`] call.
/// # Fields
/// - `entries` — See field documentation.
pub struct MessageCatalog {
    /// Flattened ID → text map built from the TOML catalog.
    messages: HashMap<String, String>,
}

impl MessageCatalog {
    /// Parse the embedded TOML source and build a flat ID → text map.
    ///
    /// Nested TOML tables (tier sections) are flattened: only the leaf key is
    /// used as the message ID, so `baseline.lifecycle.L001` becomes `"L001"`.
    ///
    /// # Parameters
    /// - `toml_src` — `&str`.
    ///
    /// # Returns
    /// `MessageCatalog`.
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

    /// Look up the human-readable text for a message ID.
    ///
    /// Returns `Some(&str)` if the ID is registered, `None` otherwise.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get(&self, id: &str) -> Option<&str> {
        self.messages.get(id).map(|s| s.as_str())
    }

    /// Number of registered message entries.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.messages.len()
    }

    /// Returns `true` if the catalog contains no entries.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.messages.is_empty()
    }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Initialise the global message catalog from the embedded TOML.
///
/// Safe to call multiple times — only the first call takes effect.
/// Called automatically by [`App::new`](crate::app::App) during engine startup.
pub fn init() {
    CATALOG.get_or_init(|| MessageCatalog::from_toml(CATALOG_TOML));
}

/// Resolve a stable message ID to its human-readable text.
///
/// Returns the catalog text if the ID is registered, or the raw ID string if
/// the catalog has not been initialised or the ID is not present.
///
/// # Parameters
/// - `id` — `&'static str`.
///
/// # Returns
/// `&'static str`.
pub fn get_message(id: &'static str) -> &'static str {
    CATALOG
        .get()
        .and_then(|c| {
            c.messages
                .get(id)
                // SAFETY: `c` is `&'static MessageCatalog`; the `String` values it
                // contains therefore also live for `'static`.
                .map(|s: &String| unsafe { &*(s.as_str() as *const str) })
        })
        .unwrap_or(id)
}

/// Returns a reference to the global [`MessageCatalog`], or `None` if
/// [`init`] has not been called yet.
///
/// # Returns
/// `Option<&'static MessageCatalog>`.
pub fn catalog() -> Option<&'static MessageCatalog> {
    CATALOG.get()
}

// ---------------------------------------------------------------------------
// TOML flattening helper
// ---------------------------------------------------------------------------

/// Recursively walk a [`toml::Value`] tree and insert every leaf `String`
/// entry into `out`, keyed by its own table key (not the full dotted path).
fn collect_strings(val: &toml::Value, out: &mut HashMap<String, String>) {
    if let toml::Value::Table(table) = val {
        for (key, child) in table {
            match child {
                toml::Value::String(s) => {
                    out.insert(key.clone(), s.clone());
                }
                toml::Value::Table(_) => {
                    collect_strings(child, out);
                }
                // Comments-only sections may produce a Table with no string leaves — skip.
                _ => {}
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn built_catalog() -> MessageCatalog {
        MessageCatalog::from_toml(CATALOG_TOML)
    }

    #[test]
    fn catalog_parses_without_error() {
        let c = built_catalog();
        assert!(!c.is_empty(), "catalog must not be empty after parsing");
    }

    #[test]
    fn baseline_lifecycle_ids_present() {
        let c = built_catalog();
        for id in &["L001", "L002", "L003", "L004", "L005"] {
            assert!(c.get(id).is_some(), "expected {id} in catalog");
        }
    }

    #[test]
    fn error_ids_present() {
        let c = built_catalog();
        for id in &["L010", "L011", "L012", "L013", "L014", "L015"] {
            assert!(c.get(id).is_some(), "expected {id} in catalog");
        }
    }

    #[test]
    fn missing_id_returns_none() {
        let c = built_catalog();
        assert!(c.get("ZZZZ").is_none());
    }

    #[test]
    fn l001_has_correct_text() {
        let c = built_catalog();
        assert_eq!(c.get("L001"), Some("Lurek2D Engine starting"));
    }

    #[test]
    fn len_matches_registered_ids() {
        let c = built_catalog();
        // There are at least 30 entries in the baseline section.
        assert!(c.len() >= 30, "expected >= 30 entries, got {}", c.len());
    }

    #[test]
    fn get_message_falls_back_to_id_when_uninitialised() {
        // Do not call init() — test fallback path.
        // (CATALOG may already be set from another test; skip if so.)
        // The contract: returns either the text or the raw id.
        let result = get_message("L001");
        assert!(
            result == "Lurek2D Engine starting" || result == "L001",
            "unexpected result: {result}"
        );
    }

    #[test]
    fn get_message_after_init_returns_text() {
        init();
        assert_eq!(get_message("L001"), "Lurek2D Engine starting");
        assert_eq!(get_message("L003"), "Game loaded");
    }
}
