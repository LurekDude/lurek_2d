//! Registers the `lurek.localization.*` internationalization and localization API.
//!
//! Thin Lua bridge that delegates to the [`localization`][crate::localization] domain module.
//! All translation tables, fallback logic, interpolation, and pluralization live
//! in [`crate::localization`]; this file converts between Lua values and domain types.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;
use crate::i18n::{interpolate, PluralForm, Catalog};

// ---------------------------------------------------------------------------
// Bridge state
// ---------------------------------------------------------------------------

struct LocalizationShared {
    catalog: Catalog,
    /// Callbacks invoked when the active language changes.
    on_change: Vec<LuaRegistryKey>,
    /// Base/fallback language code.
    base: String,
}

impl LocalizationShared {
    fn new() -> Self {
        Self {
            catalog: Catalog::new(),
            on_change: Vec::new(),
            base: String::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Flattens a nested Lua table into a `HashMap<String, String>` using
/// dot-path keys (e.g. `{greet = {hello = "Hi"}}` → `"greet.hello" = "Hi"`).
fn flatten_lua_table(tbl: &LuaTable, prefix: &str, out: &mut HashMap<String, String>) {
    for pair in tbl.clone().pairs::<LuaValue, LuaValue>() {
        let Ok((k, v)) = pair else { continue };
        let key_seg = match &k {
            LuaValue::String(s) => s.to_str().unwrap_or("?").to_string(),
            LuaValue::Integer(n) => n.to_string(),
            _ => continue,
        };
        let full_key = if prefix.is_empty() {
            key_seg.clone()
        } else {
            format!("{prefix}.{key_seg}")
        };
        match v {
            LuaValue::Table(sub) => flatten_lua_table(&sub, &full_key, out),
            LuaValue::String(s) => { out.insert(full_key, s.to_str().unwrap_or("").to_string()); }
            LuaValue::Integer(n) => { out.insert(full_key, n.to_string()); }
            LuaValue::Number(f) => { out.insert(full_key, f.to_string()); }
            LuaValue::Boolean(b) => { out.insert(full_key, b.to_string()); }
            _ => {}
        }
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers `lurek.localization.*`.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let loc = lua.create_table()?;
    let shared = Rc::new(RefCell::new(LocalizationShared::new()));

    // ── Language management ──────────────────────────────────────────────────

    /// Loads a language table under the given locale code.
    /// @param locale : string
    /// @param table : table
    let s = shared.clone();
    loc.set("loadTable", lua.create_function(move |_lua, (locale, tbl): (String, LuaTable)| {
        let mut flat = HashMap::new();
        flatten_lua_table(&tbl, "", &mut flat);
        s.borrow_mut().catalog.load(&locale, flat);
        Ok(())
    })?)?;

    /// Unloads a locale from the catalog.
    /// @param locale : string
    /// @return boolean
    let s = shared.clone();
    loc.set("unloadTable", lua.create_function(move |_, locale: String| {
        Ok(s.borrow_mut().catalog.unload(&locale))
    })?)?;

    /// Sets the active translation language.
    /// @param locale : string
    let s = shared.clone();
    loc.set("setLanguage", lua.create_function(move |lua, locale: String| {
        let old;
        let callbacks: Vec<LuaFunction>;
        {
            let mut st = s.borrow_mut();
            old = st.catalog.locale.clone();
            st.catalog.locale = locale.clone();
            callbacks = st.on_change.iter()
                .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                .collect();
        }
        for cb in callbacks {
            let _: LuaMultiValue = cb.call((locale.clone(), old.clone()))?;
        }
        Ok(())
    })?)?;

    /// Returns the currently active locale code, or nil if unset.
    /// @return string?
    let s = shared.clone();
    loc.set("getLanguage", lua.create_function(move |lua, ()| {
        let locale = s.borrow().catalog.locale.clone();
        if locale.is_empty() {
            Ok(LuaValue::Nil)
        } else {
            Ok(LuaValue::String(lua.create_string(&locale)?))
        }
    })?)?;

    /// Returns all loaded locale codes.
    /// @return table
    let s = shared.clone();
    loc.set("getLanguages", lua.create_function(move |lua, ()| {
        let st = s.borrow();
        let mut locales = st.catalog.locales();
        locales.sort();
        let tbl = lua.create_table()?;
        for (i, name) in locales.iter().enumerate() {
            tbl.set(i + 1, *name)?;
        }
        Ok(tbl)
    })?)?;

    /// Sets the ordered list of fallback locale codes tried when a key is missing.
    /// @param locales : table
    let s = shared.clone();
    loc.set("setFallbacks", lua.create_function(move |_, locales: LuaTable| {
        let mut fbs = Vec::new();
        for (_, v) in locales.pairs::<LuaValue, String>().flatten() { fbs.push(v); }
        s.borrow_mut().catalog.fallbacks = fbs;
        Ok(())
    })?)?;

    /// Returns the current fallback locale array.
    /// @return table
    let s = shared.clone();
    loc.set("getFallbacks", lua.create_function(move |lua, ()| {
        let st = s.borrow();
        let tbl = lua.create_table()?;
        for (i, fb) in st.catalog.fallbacks.iter().enumerate() {
            tbl.set(i + 1, fb.clone())?;
        }
        Ok(tbl)
    })?)?;

    // ── Translation ──────────────────────────────────────────────────────────

    /// Translates a key against the active locale with optional variable
    /// substitution and pluralization.
    /// @param key : string
    /// @param vars : table?
    /// @param count : number?
    /// @return string
    let s = shared.clone();
    loc.set("t", lua.create_function(move |_lua, (key, vars, count): (String, Option<LuaTable>, Option<f64>)| {
        let st = s.borrow();
        // Pluralization: try key.one / key.other first
        let resolved_key = if let Some(n) = count {
            let plural_key = if PluralForm::english(n).key() == "one" {
                format!("{key}.one")
            } else {
                format!("{key}.other")
            };
            if st.catalog.has_key(&plural_key) {
                plural_key
            } else {
                key.clone()
            }
        } else {
            key.clone()
        };
        let raw = st.catalog.translate(&resolved_key).to_string();
        // Variable substitution
        let result = if let Some(tbl) = vars {
            let mut map = HashMap::new();
            for (k, v) in tbl.pairs::<String, String>().flatten() { map.insert(k, v); }
            if let Some(n) = count { map.entry("count".to_string()).or_insert_with(|| format!("{n}")); }
            interpolate(&raw, &map)
        } else {
            raw
        };
        Ok(result)
    })?)?;

    /// Returns whether a key exists in the active locale.
    /// @param key : string
    /// @return boolean
    let s = shared.clone();
    loc.set("hasKey", lua.create_function(move |_, key: String| {
        Ok(s.borrow().catalog.has_key(&key))
    })?)?;

    /// Returns all known keys for the active locale.
    /// @return table
    let s = shared.clone();
    loc.set("getKeys", lua.create_function(move |lua, ()| {
        let st = s.borrow();
        let mut keys = st.catalog.keys();
        keys.sort();
        let tbl = lua.create_table()?;
        for (i, k) in keys.iter().enumerate() {
            tbl.set(i + 1, *k)?;
        }
        Ok(tbl)
    })?)?;

    /// Inserts or overwrites a single key in the given locale.
    /// @param locale : string
    /// @param key : string
    /// @param value : string
    let s = shared.clone();
    loc.set("setKey", lua.create_function(move |_, (locale, key, value): (String, String, String)| {
        s.borrow_mut().catalog.set_key(&locale, &key, &value);
        Ok(())
    })?)?;

    // ── Utilities ────────────────────────────────────────────────────────────

    /// Interpolates {name} placeholders in a template string.
    /// @param template : string
    /// @param vars : table
    /// @return string
    loc.set("interpolate", lua.create_function(|_, (template, vars): (String, LuaTable)| {
        let mut map = HashMap::new();
        for (k, v) in vars.pairs::<String, String>().flatten() { map.insert(k, v); }
        Ok(interpolate(&template, &map))
    })?)?;

    /// Returns the CLDR plural category for a number ("one" or "other", etc.).
    /// @param n : number
    /// @return string
    loc.set("pluralFor", lua.create_function(|_, n: f64| {
        Ok(PluralForm::english(n).key().to_string())
    })?)?;

    // ── Lifecycle callbacks ────────────────────────────────────────────────────

    /// Registers a callback invoked when setLanguage() is called.
    /// Callback receives (new_locale, old_locale).
    /// @param cb : function
    let s = shared.clone();
    loc.set("onLanguageChange", lua.create_function(move |lua, cb: LuaFunction| {
        let key = lua.create_registry_value(cb)?;
        s.borrow_mut().on_change.push(key);
        Ok(())
    })?)?;

    // -- Aliases and missing functions --

    /// Returns whether a locale has been loaded.
    /// @param locale : string
    /// @return boolean
    let s = shared.clone();
    loc.set("hasLanguage", lua.create_function(move |_, locale: String| {
        Ok(s.borrow().catalog.has_locale(&locale))
    })?)?;

    /// Returns all loaded locale codes (alias for getLanguages).
    /// @return table
    let s = shared.clone();
    loc.set("getAvailableLanguages", lua.create_function(move |lua, ()| {
        let st = s.borrow();
        let mut locales = st.catalog.locales();
        locales.sort();
        let tbl = lua.create_table()?;
        for (i, name) in locales.iter().enumerate() {
            tbl.set(i + 1, *name)?;
        }
        Ok(tbl)
    })?)?;

    /// Sets the base/fallback language (adds it as first fallback).
    /// @param locale : string
    let s = shared.clone();
    loc.set("setBase", lua.create_function(move |_, locale: String| {
        s.borrow_mut().base = locale.clone();
        Ok(())
    })?)?;

    /// Returns the base/fallback language.
    /// @return string
    let s = shared.clone();
    loc.set("getBase", lua.create_function(move |_, ()| {
        Ok(s.borrow().base.clone())
    })?)?;

    /// Registers a callback invoked when setLanguage() is called (alias: onChange).
    /// @param cb : function
    let s = shared.clone();
    loc.set("onChange", lua.create_function(move |lua, cb: LuaFunction| {
        let key = lua.create_registry_value(cb)?;
        s.borrow_mut().on_change.push(key);
        Ok(())
    })?)?;

    /// Unregisters all onChange callbacks.
    let s = shared.clone();
    loc.set("offChange", lua.create_function(move |lua, ()| {
        let keys: Vec<_> = s.borrow_mut().on_change.drain(..).collect();
        for k in keys {
            lua.remove_registry_value(k)?;
        }
        Ok(())
    })?)?;

    // ── Large-dataset helpers ─────────────────────────────────────────────

    /// Returns the number of keys loaded in the active locale.
    /// @return integer
    let s = shared.clone();
    loc.set("keyCount", lua.create_function(move |_, ()| {
        Ok(s.borrow().catalog.key_count())
    })?)?;

    /// Returns unique first-path-segment category prefixes for all active locale keys.
    /// @return table
    let s = shared.clone();
    loc.set("categories", lua.create_function(move |lua, ()| {
        let cats = s.borrow().catalog.categories();
        let tbl = lua.create_table()?;
        for (i, c) in cats.iter().enumerate() { tbl.set(i + 1, c.as_str())?; }
        Ok(tbl)
    })?)?;

    /// Returns all keys in the active locale whose first path segment matches category.
    /// @param category : string
    /// @return table
    let s = shared.clone();
    loc.set("keysInCategory", lua.create_function(move |lua, category: String| {
        let keys = s.borrow().catalog.keys_in_category(&category).iter().map(|s| s.to_string()).collect::<Vec<_>>();
        let tbl = lua.create_table()?;
        for (i, k) in keys.iter().enumerate() { tbl.set(i + 1, k.as_str())?; }
        Ok(tbl)
    })?)?;

    /// Searches active locale values for a substring query (case-insensitive). Returns {key, value} pairs.
    /// @param query : string
    /// @param limit : integer?
    /// @return table
    let s = shared.clone();
    loc.set("search", lua.create_function(move |lua, (query, limit): (String, Option<usize>)| {
        let results = s.borrow().catalog.search(&query, limit.unwrap_or(0)).iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect::<Vec<_>>();
        let tbl = lua.create_table()?;
        for (i, (k, v)) in results.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("key", k.as_str())?;
            row.set("value", v.as_str())?;
            tbl.set(i + 1, row)?;
        }
        Ok(tbl)
    })?)?;

    /// Builds an inverted word index for the active locale. Returns index as {word → {keys}}.
    /// Cache the result and pass to searchIndexed for fast repeated queries on large datasets.
    /// @return table
    let s = shared.clone();
    loc.set("buildIndex", lua.create_function(move |lua, ()| {
        let index = s.borrow().catalog.build_index();
        let tbl = lua.create_table()?;
        for (word, keys) in &index {
            let kt = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() { kt.set(i + 1, k.as_str())?; }
            tbl.set(word.as_str(), kt)?;
        }
        Ok(tbl)
    })?)?;

    /// Searches the provided pre-built index for entries matching all words in query.
    /// @param index : table
    /// @param query : string
    /// @param limit : integer?
    /// @return table
    loc.set("searchIndexed", lua.create_function(move |lua, (index, query, limit): (LuaTable, String, Option<usize>)| {
        let words: Vec<String> = query
            .split_whitespace()
            .map(|w| w.to_lowercase().trim_matches(|c: char| !c.is_alphanumeric()).to_string())
            .filter(|w| !w.is_empty())
            .collect();
        if words.is_empty() {
            return Ok(lua.create_table()?);
        }
        // Intersect key lists for each word
        let mut candidate_sets: Vec<std::collections::HashSet<String>> = Vec::new();
        for word in &words {
            let keys_tbl: Option<LuaTable> = index.get(word.as_str())?;
            let mut set = std::collections::HashSet::new();
            if let Some(kt) = keys_tbl {
                for pair in kt.sequence_values::<String>() {
                    set.insert(pair?);
                }
            }
            candidate_sets.push(set);
        }
        let intersection = candidate_sets.iter().skip(1).fold(
            candidate_sets.first().cloned().unwrap_or_default(),
            |acc, set| acc.intersection(set).cloned().collect(),
        );
        let mut keys: Vec<String> = intersection.into_iter().collect();
        keys.sort();
        let lim = limit.unwrap_or(0);
        if lim > 0 && keys.len() > lim {
            keys.truncate(lim);
        }
        let tbl = lua.create_table()?;
        for (i, k) in keys.iter().enumerate() { tbl.set(i + 1, k.as_str())?; }
        Ok(tbl)
    })?)?;

    /// Merges a flat key→value table into an existing locale without replacing the whole table.
    /// @param locale : string
    /// @param entries : table
    let s = shared.clone();
    loc.set("mergeLocale", lua.create_function(move |_, (locale, entries): (String, LuaTable)| {
        let mut map = std::collections::HashMap::new();
        for pair in entries.pairs::<String, String>() {
            let (k, v) = pair?;
            map.insert(k, v);
        }
        s.borrow_mut().catalog.merge(&locale, map);
        Ok(())
    })?)?;

    // -- localization namespace --
    luna.set("localization", loc)?;
    Ok(())
}
