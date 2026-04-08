//! Translation catalog: language maps, key resolution, and fallback chains.
//!
//! A [`Catalog`] holds message tables keyed by locale code (e.g. `"en-US"`).
//! Keys are dot-separated paths into nested string tables.  When a key is
//! missing in the requested locale the catalog walks a configurable fallback
//! chain before returning the key itself as a last resort.

use std::collections::HashMap;

// ── CatalogError ──────────────────────────────────────────────────────────

/// Errors produced by catalog operations.
///
/// # Variants
/// - `UnknownLocale` — The requested locale is not loaded.
/// - `KeyNotFound` — The key was not found in any fallback locale.
#[derive(Debug, thiserror::Error)]
pub enum CatalogError {
    /// Locale not registered.
    #[error("unknown locale: {0}")]
    UnknownLocale(String),
    /// Key not found after fallback exhaustion.
    #[error("key not found: {0}")]
    KeyNotFound(String),
}

// ── Catalog ───────────────────────────────────────────────────────────────

/// Multi-locale string catalog with dot-path key resolution.
///
/// # Fields
/// - `locale` — `String`.
/// - `fallbacks` — `Vec<String>`.
/// - `tables` — `HashMap<String, HashMap<String, String>>`.
#[derive(Debug, Default)]
pub struct Catalog {
    /// Active locale code (e.g. `"en-US"`).
    pub locale: String,
    /// Ordered fallback locale chain queried after the active locale.
    pub fallbacks: Vec<String>,
    /// All loaded locale tables. Inner maps are flat dot-separated key → value.
    pub tables: HashMap<String, HashMap<String, String>>,
}

impl Catalog {
    /// Creates an empty catalog.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Loads or replaces a locale's flat string table.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    /// - `table` — `HashMap<String, String>`.
    pub fn load(&mut self, locale: &str, table: HashMap<String, String>) {
        self.tables.insert(locale.to_string(), table);
    }

    /// Removes a locale from the catalog.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn unload(&mut self, locale: &str) -> bool {
        self.tables.remove(locale).is_some()
    }

    /// Whether a locale is loaded.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_locale(&self, locale: &str) -> bool {
        self.tables.contains_key(locale)
    }

    /// Returns all loaded locale codes.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn locales(&self) -> Vec<&str> {
        self.tables.keys().map(String::as_str).collect()
    }

    /// Whether a key exists in the currently active locale.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_key(&self, key: &str) -> bool {
        self.tables
            .get(&self.locale)
            .map(|t| t.contains_key(key))
            .unwrap_or(false)
    }

    /// Returns all keys available in the active locale.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn keys(&self) -> Vec<&str> {
        self.tables
            .get(&self.locale)
            .map(|t| t.keys().map(String::as_str).collect())
            .unwrap_or_default()
    }

    /// Resolves a translation key using the active locale with fallback chain.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `Result<&str, CatalogError>`.
    pub fn get<'a>(&'a self, key: &str) -> Result<&'a str, CatalogError> {
        // 1. Active locale
        if let Some(v) = self.tables.get(&self.locale).and_then(|t| t.get(key)) {
            return Ok(v.as_str());
        }
        // 2. Fallback chain
        for fb in &self.fallbacks {
            if let Some(v) = self.tables.get(fb).and_then(|t| t.get(key)) {
                return Ok(v.as_str());
            }
        }
        Err(CatalogError::KeyNotFound(key.to_string()))
    }

    /// Like [`get`][Catalog::get] but returns the key itself when not found.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `&str`.
    pub fn translate<'a>(&'a self, key: &'a str) -> &'a str {
        self.get(key).unwrap_or(key)
    }

    /// Inserts or updates a single key in the given locale.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    /// - `key` — `&str`.
    /// - `value` — `&str`.
    pub fn set_key(&mut self, locale: &str, key: &str, value: &str) {
        self.tables
            .entry(locale.to_string())
            .or_default()
            .insert(key.to_string(), value.to_string());
    }

    /// Exports the given locale table as a flat `HashMap<String, String>`.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    ///
    /// # Returns
    /// `Option<HashMap<String, String>>`.
    pub fn export(&self, locale: &str) -> Option<HashMap<String, String>> {
        self.tables.get(locale).cloned()
    }

    /// Merges key-value pairs into an existing locale without replacing the whole table.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    /// - `entries` — `HashMap<String, String>`.
    pub fn merge(&mut self, locale: &str, entries: HashMap<String, String>) {
        let table = self.tables.entry(locale.to_string()).or_default();
        for (k, v) in entries {
            table.insert(k, v);
        }
    }

    /// Returns the number of keys in the active locale.
    ///
    /// # Returns
    /// `usize`.
    pub fn key_count(&self) -> usize {
        self.tables
            .get(&self.locale)
            .map(|t| t.len())
            .unwrap_or(0)
    }

    /// Returns the unique first path-segments of all keys in the active locale.
    ///
    /// For example keys `"ui.ok"`, `"ui.cancel"`, `"item.sword"` yield `["ui", "item"]`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn categories(&self) -> Vec<String> {
        let Some(table) = self.tables.get(&self.locale) else {
            return Vec::new();
        };
        let mut cats: std::collections::HashSet<String> = std::collections::HashSet::new();
        for key in table.keys() {
            let prefix = key.split('.').next().unwrap_or(key.as_str());
            cats.insert(prefix.to_string());
        }
        let mut result: Vec<String> = cats.into_iter().collect();
        result.sort();
        result
    }

    /// Returns all keys in the active locale that start with the given category prefix.
    ///
    /// # Parameters
    /// - `category` — `&str`.
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn keys_in_category<'a>(&'a self, category: &str) -> Vec<&'a str> {
        let Some(table) = self.tables.get(&self.locale) else {
            return Vec::new();
        };
        let prefix = format!("{category}.");
        let mut result: Vec<&str> = table
            .keys()
            .filter(|k| k.starts_with(&prefix) || k.as_str() == category)
            .map(String::as_str)
            .collect();
        result.sort();
        result
    }

    /// Simple substring search over values in the active locale.
    ///
    /// Returns up to `limit` `(key, value)` pairs where the value contains `query`
    /// (case-insensitive). `limit = 0` returns all matches.
    ///
    /// # Parameters
    /// - `query` — `&str`.
    /// - `limit` — `usize`.
    ///
    /// # Returns
    /// `Vec<(&str, &str)>`.
    pub fn search<'a>(&'a self, query: &str, limit: usize) -> Vec<(&'a str, &'a str)> {
        let Some(table) = self.tables.get(&self.locale) else {
            return Vec::new();
        };
        let lower = query.to_lowercase();
        let mut results: Vec<(&str, &str)> = table
            .iter()
            .filter(|(_, v)| v.to_lowercase().contains(&lower))
            .map(|(k, v)| (k.as_str(), v.as_str()))
            .collect();
        results.sort_by_key(|(k, _)| *k);
        if limit > 0 && results.len() > limit {
            results.truncate(limit);
        }
        results
    }

    /// Builds an inverted word index for the active locale.
    ///
    /// Returns a map from lowercase words to sorted lists of keys whose values
    /// contain that word. Useful as a pre-built cache for repeated `search_indexed` calls
    /// on large datasets (10k+ entries).
    ///
    /// # Returns
    /// `HashMap<String, Vec<String>>`.
    pub fn build_index(&self) -> HashMap<String, Vec<String>> {
        let Some(table) = self.tables.get(&self.locale) else {
            return HashMap::new();
        };
        let mut index: HashMap<String, Vec<String>> = HashMap::new();
        for (key, value) in table {
            for word in value.split_whitespace() {
                let word_lower = word
                    .to_lowercase()
                    .trim_matches(|c: char| !c.is_alphanumeric())
                    .to_string();
                if !word_lower.is_empty() {
                    index.entry(word_lower).or_default().push(key.clone());
                }
            }
        }
        for entries in index.values_mut() {
            entries.sort();
            entries.dedup();
        }
        index
    }
}
