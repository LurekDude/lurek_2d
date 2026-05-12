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
pub const CATALOG_TOML: &str = include_str!("cfg/messages.toml");

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
    ///
    /// Values are `&'static str` obtained by leaking `Box<str>` allocations
    /// during `from_toml`.  The catalog is stored in a `static OnceLock` so
    /// these allocations live for the entire process lifetime, making the
    /// intentional leak safe and avoiding any `unsafe` lifetime extension.
    messages: HashMap<String, &'static str>,
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
        self.messages.get(id).copied()
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
        .and_then(|c| c.messages.get(id).copied())
        .unwrap_or(id)
}

/// Resolve an arbitrary message ID to its human-readable text.
///
/// Unlike [`get_message`], this accepts a non-static `&str` and returns an
/// owned `String` suitable for Lua and other dynamic callers.
///
/// # Parameters
/// - `id` — `&str`.
///
/// # Returns
/// `String`.
pub fn resolve_message(id: &str) -> String {
    init();
    catalog()
        .and_then(|c| c.get(id))
        .map(ToOwned::to_owned)
        .unwrap_or_else(|| id.to_string())
}

/// Returns `true` if the global message catalog contains the given ID.
///
/// # Parameters
/// - `id` — `&str`.
///
/// # Returns
/// `bool`.
pub fn has_message(id: &str) -> bool {
    init();
    catalog().map(|c| c.get(id).is_some()).unwrap_or(false)
}

/// Number of entries currently registered in the global message catalog.
///
/// # Returns
/// `usize`.
pub fn message_count() -> usize {
    init();
    catalog().map(MessageCatalog::len).unwrap_or(0)
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
fn collect_strings(val: &toml::Value, out: &mut HashMap<String, &'static str>) {
    if let toml::Value::Table(table) = val {
        for (key, child) in table {
            match child {
                toml::Value::String(s) => {
                    // Leak the boxed string so it lives for `'static`.  The catalog is stored in
                    // a `static OnceLock` and is never dropped, so these allocations are bounded
                    // by the number of catalog entries (≈100) and intentionally permanent.
                    let static_str: &'static str = Box::leak(s.clone().into_boxed_str());
                    out.insert(key.clone(), static_str);
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
