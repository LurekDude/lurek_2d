//! Translation catalog: language maps, key resolution, and fallback chains.
//!
//! A [`Catalog`] holds message tables keyed by locale code (e.g. `"en-US"`).
//! Keys are dot-separated paths into nested string tables.  When a key is
//! missing in the requested locale the catalog walks a configurable fallback
//! chain before returning the key itself as a last resort.
//!
//! ## Caching
//! [`Catalog::categories`] and [`Catalog::build_index`] cache their results
//! using interior mutability.  The cache is keyed by the active locale string
//! and is automatically invalidated when [`Catalog::load`], [`Catalog::unload`],
//! [`Catalog::set_key`], or [`Catalog::merge`] are called.  Direct writes to the
//! public `locale` or `tables` fields bypass cache invalidation; use the API
//! methods for full cache coherence.

use std::cell::RefCell;
use std::collections::HashMap;

use serde_json;

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

// ── CoverageGap ───────────────────────────────────────────────────────────

/// A key present in the reference locale but absent in one or more others.
///
/// Returned by [`Catalog::coverage_gaps`] to help authors find untranslated
/// strings across loaded language tables.
///
/// # Fields
/// - `key` — `String`. The missing translation key.
/// - `missing_in` — `Vec<String>`. Locale codes that lack this key.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverageGap {
    /// The translation key that is missing.
    pub key: String,
    /// Locale codes where this key is absent.
    pub missing_in: Vec<String>,
}

// ── Catalog ───────────────────────────────────────────────────────────────

/// Multi-locale string catalog with dot-path key resolution.
///
/// # Fields
/// - `locale` — `String`.
/// - `fallbacks` — `Vec<String>`.
/// - `tables` — `HashMap<String, HashMap<String, String>>`.
///
/// Internal cache fields (`categories_cache`, `index_cache`) use interior
/// mutability and are managed automatically by the API methods.
#[derive(Debug, Default)]
pub struct Catalog {
    /// Active locale code (e.g. `"en-US"`).
    pub locale: String,
    /// Ordered fallback locale chain queried after the active locale.
    pub fallbacks: Vec<String>,
    /// All loaded locale tables. Inner maps are flat dot-separated key → value.
    pub tables: HashMap<String, HashMap<String, String>>,
    /// Cache: `Some((locale, categories))` when valid for `locale`.
    categories_cache: RefCell<Option<(String, Vec<String>)>>,
    /// Cache: `Some((locale, index))` when valid for `locale`.
    #[allow(clippy::type_complexity)]
    index_cache: RefCell<Option<(String, HashMap<String, Vec<String>>)>>,
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
        self.invalidate_caches();
    }

    /// Removes a locale from the catalog.
    ///
    /// # Parameters
    /// - `locale` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn unload(&mut self, locale: &str) -> bool {
        let removed = self.tables.remove(locale).is_some();
        if removed {
            self.invalidate_caches();
        }
        removed
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
        self.invalidate_caches();
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
        self.invalidate_caches();
    }

    /// Returns the number of keys in the active locale.
    ///
    /// # Returns
    /// `usize`.
    pub fn key_count(&self) -> usize {
        self.tables.get(&self.locale).map(|t| t.len()).unwrap_or(0)
    }

    /// Returns the unique first path-segments of all keys in the active locale.
    ///
    /// For example keys `"ui.ok"`, `"ui.cancel"`, `"item.sword"` yield `["ui", "item"]`.
    ///
    /// Results are cached per locale and invalidated by mutation methods.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn categories(&self) -> Vec<String> {
        // Return cached result if still valid for the current locale.
        {
            let cache = self.categories_cache.borrow();
            if let Some((ref cached_locale, ref cats)) = *cache {
                if cached_locale == &self.locale {
                    return cats.clone();
                }
            }
        }
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
        *self.categories_cache.borrow_mut() = Some((self.locale.clone(), result.clone()));
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
    /// Results are cached per locale and invalidated by mutation methods.
    ///
    /// # Returns
    /// `HashMap<String, Vec<String>>`.
    pub fn build_index(&self) -> HashMap<String, Vec<String>> {
        // Return cached result if still valid for the current locale.
        {
            let cache = self.index_cache.borrow();
            if let Some((ref cached_locale, ref idx)) = *cache {
                if cached_locale == &self.locale {
                    return idx.clone();
                }
            }
        }
        let Some(table) = self.tables.get(&self.locale) else {
            return HashMap::new();
        };
        // Build inverted index: for each value, split into words, normalise,
        // and record which keys contain that word.
        let mut index: HashMap<String, Vec<String>> = HashMap::new();
        for (key, value) in table {
            for word in value.split_whitespace() {
                // Strip leading/trailing punctuation and lowercase for case-insensitive matching.
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
        *self.index_cache.borrow_mut() = Some((self.locale.clone(), index.clone()));
        index
    }

    /// Returns keys present in `reference_locale` but absent in one or more other loaded locales.
    ///
    /// Use this to audit translation completeness across all loaded language tables.
    /// The returned list is sorted by key for deterministic output.
    ///
    /// # Parameters
    /// - `reference_locale` — `&str`. The locale whose key set is treated as the full set.
    ///
    /// # Returns
    /// `Vec<CoverageGap>`.
    pub fn coverage_gaps(&self, reference_locale: &str) -> Vec<CoverageGap> {
        let Some(ref_table) = self.tables.get(reference_locale) else {
            return Vec::new();
        };
        let other_locales: Vec<&str> = self
            .tables
            .keys()
            .filter(|k| k.as_str() != reference_locale)
            .map(String::as_str)
            .collect();
        if other_locales.is_empty() {
            return Vec::new();
        }
        let mut gaps: Vec<CoverageGap> = Vec::new();
        for key in ref_table.keys() {
            let missing_in: Vec<String> = other_locales
                .iter()
                .filter(|loc| {
                    !self
                        .tables
                        .get::<str>(*loc)
                        .map(|t| t.contains_key(key))
                        .unwrap_or(false)
                })
                .map(|s| s.to_string())
                .collect();
            if !missing_in.is_empty() {
                gaps.push(CoverageGap {
                    key: key.clone(),
                    missing_in,
                });
            }
        }
        gaps.sort_by(|a, b| a.key.cmp(&b.key));
        gaps
    }

    // ── Internal helpers ──────────────────────────────────────────────────

    /// Clears all derived caches. Called by every mutation method.
    fn invalidate_caches(&self) {
        *self.categories_cache.borrow_mut() = None;
        *self.index_cache.borrow_mut() = None;
    }
}

// ── Locale utilities ──────────────────────────────────────────────────────

/// Validates a locale code against a relaxed BCP 47 subset.
///
/// Accepts codes with 2–8 letter language tags, optionally followed by one or
/// more subtags (region, script, variant) of 2–8 alphanumeric characters,
/// separated by `-` or `_`.  Rejects empty strings, codes longer than 35
/// characters, and tags with non-ASCII-alphanumeric characters.
///
/// # Parameters
/// - `code` — `&str`.
///
/// # Returns
/// `bool`.
pub fn is_valid_locale_code(code: &str) -> bool {
    if code.is_empty() || code.len() > 35 {
        return false;
    }
    let mut parts = code.split(['-', '_']);
    let Some(lang) = parts.next() else {
        return false;
    };
    // Language subtag: 2–8 ASCII letters.
    if lang.len() < 2 || lang.len() > 8 || !lang.chars().all(|c| c.is_ascii_alphabetic()) {
        return false;
    }
    // Optional subtags: 1–8 ASCII alphanumeric characters each.
    for part in parts {
        if part.is_empty() || part.len() > 8 || !part.chars().all(|c| c.is_ascii_alphanumeric()) {
            return false;
        }
    }
    true
}

/// Returns `true` when the given locale uses a right-to-left writing direction.
///
/// Checks the primary language subtag against the known RTL language set:
/// Arabic (`ar`), Hebrew (`he`), Persian (`fa`), Urdu (`ur`), Yiddish (`yi`),
/// Divehi (`dv`), Central Kurdish (`ckb`), Sindhi (`sd`), and Sorani (`ku`).
///
/// # Parameters
/// - `locale` — `&str`.
///
/// # Returns
/// `bool`.
pub fn is_rtl(locale: &str) -> bool {
    const RTL_LANGS: &[&str] = &["ar", "he", "fa", "ur", "yi", "dv", "sd", "ku", "ckb"];
    let prefix = locale
        .split(['-', '_'])
        .next()
        .unwrap_or(locale)
        .to_lowercase();
    RTL_LANGS.contains(&prefix.as_str())
}

/// Attempts to detect the system locale from environment variables.
///
/// Reads `LANG`, `LANGUAGE`, `LC_ALL`, and `LC_MESSAGES` in that order and
/// returns the first non-empty, non-C, non-POSIX value after normalising `_`
/// separators to `-` and stripping any encoding suffix (e.g. `.UTF-8`).
///
/// Returns `None` when no usable locale is found in the environment.
///
/// # Returns
/// `Option<String>`.
pub fn detect_system_locale() -> Option<String> {
    for var in &["LANG", "LANGUAGE", "LC_ALL", "LC_MESSAGES"] {
        if let Ok(val) = std::env::var(var) {
            if val.is_empty() || val == "C" || val == "POSIX" {
                continue;
            }
            // Strip encoding suffix (e.g. "en_US.UTF-8" → "en_US").
            let code = val.split('.').next().unwrap_or(val.as_str());
            // Normalise underscores to hyphens.
            let normalized = code.replace('_', "-");
            if !normalized.is_empty() {
                return Some(normalized);
            }
        }
    }
    None
}

/// Loads a flat TOML string into a `HashMap<String, String>` suitable for [`Catalog::load`].
///
/// Only top-level string and nested table values are flattened into dot-path keys.
/// Non-string leaf values are converted with [`std::fmt::Display`].
///
/// # Parameters
/// - `input` — `&str`. TOML text.
///
/// # Returns
/// `Result<HashMap<String, String>, String>`.
pub fn flat_table_from_toml(input: &str) -> Result<HashMap<String, String>, String> {
    let value: toml::Value = input
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))?;
    let mut out = HashMap::new();
    flatten_toml_value(&value, "", &mut out);
    Ok(out)
}

/// Loads a flat JSON string into a `HashMap<String, String>` suitable for [`Catalog::load`].
///
/// Only string and nested object values are flattened into dot-path keys.
/// Non-string leaf values are converted with [`std::fmt::Display`].
///
/// # Parameters
/// - `input` — `&str`. JSON text.
///
/// # Returns
/// `Result<HashMap<String, String>, String>`.
pub fn flat_table_from_json(input: &str) -> Result<HashMap<String, String>, String> {
    let value: serde_json::Value =
        serde_json::from_str(input).map_err(|e| format!("JSON parse error: {e}"))?;
    let mut out = HashMap::new();
    flatten_json_value(&value, "", &mut out);
    Ok(out)
}

// ── Private flatten helpers ────────────────────────────────────────────────

fn flatten_toml_value(val: &toml::Value, prefix: &str, out: &mut HashMap<String, String>) {
    match val {
        toml::Value::Table(map) => {
            for (k, v) in map {
                let full = if prefix.is_empty() {
                    k.clone()
                } else {
                    format!("{prefix}.{k}")
                };
                flatten_toml_value(v, &full, out);
            }
        }
        toml::Value::String(s) => {
            if !prefix.is_empty() {
                out.insert(prefix.to_string(), s.clone());
            }
        }
        other => {
            if !prefix.is_empty() {
                out.insert(prefix.to_string(), other.to_string());
            }
        }
    }
}

fn flatten_json_value(val: &serde_json::Value, prefix: &str, out: &mut HashMap<String, String>) {
    match val {
        serde_json::Value::Object(map) => {
            for (k, v) in map {
                let full = if prefix.is_empty() {
                    k.clone()
                } else {
                    format!("{prefix}.{k}")
                };
                flatten_json_value(v, &full, out);
            }
        }
        serde_json::Value::String(s) => {
            if !prefix.is_empty() {
                out.insert(prefix.to_string(), s.clone());
            }
        }
        other => {
            if !prefix.is_empty() {
                out.insert(prefix.to_string(), other.to_string());
            }
        }
    }
}
