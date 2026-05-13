use serde_json;
use std::cell::RefCell;
use std::collections::HashMap;
#[derive(Debug, thiserror::Error)]
pub enum CatalogError {
    #[error("unknown locale: {0}")]
    UnknownLocale(String),
    #[error("key not found: {0}")]
    KeyNotFound(String),
}
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverageGap {
    pub key: String,
    pub missing_in: Vec<String>,
}
#[derive(Debug, Default)]
pub struct Catalog {
    pub locale: String,
    pub fallbacks: Vec<String>,
    pub tables: HashMap<String, HashMap<String, String>>,
    categories_cache: RefCell<Option<(String, Vec<String>)>>,
    #[allow(clippy::type_complexity)]
    index_cache: RefCell<Option<(String, HashMap<String, Vec<String>>)>>,
}
impl Catalog {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn load(&mut self, locale: &str, table: HashMap<String, String>) {
        self.tables.insert(locale.to_string(), table);
        self.invalidate_caches();
    }
    pub fn unload(&mut self, locale: &str) -> bool {
        let removed = self.tables.remove(locale).is_some();
        if removed {
            self.invalidate_caches();
        }
        removed
    }
    pub fn has_locale(&self, locale: &str) -> bool {
        self.tables.contains_key(locale)
    }
    pub fn locales(&self) -> Vec<&str> {
        self.tables.keys().map(String::as_str).collect()
    }
    pub fn has_key(&self, key: &str) -> bool {
        self.tables
            .get(&self.locale)
            .map(|t| t.contains_key(key))
            .unwrap_or(false)
    }
    pub fn keys(&self) -> Vec<&str> {
        self.tables
            .get(&self.locale)
            .map(|t| t.keys().map(String::as_str).collect())
            .unwrap_or_default()
    }
    pub fn get<'a>(&'a self, key: &str) -> Result<&'a str, CatalogError> {
        if let Some(v) = self.tables.get(&self.locale).and_then(|t| t.get(key)) {
            return Ok(v.as_str());
        }
        for fb in &self.fallbacks {
            if let Some(v) = self.tables.get(fb).and_then(|t| t.get(key)) {
                return Ok(v.as_str());
            }
        }
        Err(CatalogError::KeyNotFound(key.to_string()))
    }
    pub fn translate<'a>(&'a self, key: &'a str) -> &'a str {
        self.get(key).unwrap_or(key)
    }
    pub fn set_key(&mut self, locale: &str, key: &str, value: &str) {
        self.tables
            .entry(locale.to_string())
            .or_default()
            .insert(key.to_string(), value.to_string());
        self.invalidate_caches();
    }
    pub fn export(&self, locale: &str) -> Option<HashMap<String, String>> {
        self.tables.get(locale).cloned()
    }
    pub fn merge(&mut self, locale: &str, entries: HashMap<String, String>) {
        let table = self.tables.entry(locale.to_string()).or_default();
        for (k, v) in entries {
            table.insert(k, v);
        }
        self.invalidate_caches();
    }
    pub fn key_count(&self) -> usize {
        self.tables.get(&self.locale).map(|t| t.len()).unwrap_or(0)
    }
    pub fn categories(&self) -> Vec<String> {
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
    pub fn build_index(&self) -> HashMap<String, Vec<String>> {
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
        *self.index_cache.borrow_mut() = Some((self.locale.clone(), index.clone()));
        index
    }
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
    fn invalidate_caches(&self) {
        *self.categories_cache.borrow_mut() = None;
        *self.index_cache.borrow_mut() = None;
    }
}
pub fn is_valid_locale_code(code: &str) -> bool {
    if code.is_empty() || code.len() > 35 {
        return false;
    }
    let mut parts = code.split(['-', '_']);
    let Some(lang) = parts.next() else {
        return false;
    };
    if lang.len() < 2 || lang.len() > 8 || !lang.chars().all(|c| c.is_ascii_alphabetic()) {
        return false;
    }
    for part in parts {
        if part.is_empty() || part.len() > 8 || !part.chars().all(|c| c.is_ascii_alphanumeric()) {
            return false;
        }
    }
    true
}
pub fn is_rtl(locale: &str) -> bool {
    const RTL_LANGS: &[&str] = &["ar", "he", "fa", "ur", "yi", "dv", "sd", "ku", "ckb"];
    let prefix = locale
        .split(['-', '_'])
        .next()
        .unwrap_or(locale)
        .to_lowercase();
    RTL_LANGS.contains(&prefix.as_str())
}
pub fn detect_system_locale() -> Option<String> {
    for var in &["LANG", "LANGUAGE", "LC_ALL", "LC_MESSAGES"] {
        if let Ok(val) = std::env::var(var) {
            if val.is_empty() || val == "C" || val == "POSIX" {
                continue;
            }
            let code = val.split('.').next().unwrap_or(val.as_str());
            let normalized = code.replace('_', "-");
            if !normalized.is_empty() {
                return Some(normalized);
            }
        }
    }
    None
}
pub fn flat_table_from_toml(input: &str) -> Result<HashMap<String, String>, String> {
    let value: toml::Value = input
        .parse::<toml::Value>()
        .map_err(|e| format!("TOML parse error: {e}"))?;
    let mut out = HashMap::new();
    flatten_toml_value(&value, "", &mut out);
    Ok(out)
}
pub fn flat_table_from_json(input: &str) -> Result<HashMap<String, String>, String> {
    let value: serde_json::Value =
        serde_json::from_str(input).map_err(|e| format!("JSON parse error: {e}"))?;
    let mut out = HashMap::new();
    flatten_json_value(&value, "", &mut out);
    Ok(out)
}
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
