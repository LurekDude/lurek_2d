//! `lurek.i18n` -- Localization bindings for in-memory catalogs, locale selection, fallback lists, translation lookup, interpolation, plural and gender variants, search indexes, formatting helpers, locale validation, and coverage gap reports.

use crate::i18n::format::{format_date, format_number, locale_separators};
use crate::i18n::{
    detect_system_locale, flat_table_from_json, flat_table_from_toml, interpolate, is_rtl,
    is_valid_locale_code, Catalog, PluralForm,
};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Shared localization state held by all `lurek.i18n` functions.
struct LocalizationShared {
    /// Translation catalog with active locale and fallback list.
    catalog: Catalog,
    /// Lua callbacks invoked when the active language changes.
    on_change: Vec<LuaRegistryKey>,
    /// Optional base locale string used by tooling and game code.
    base: String,
}
impl LocalizationShared {
    /// Creates empty localization state with no base locale.
    fn new() -> Self {
        Self {
            catalog: Catalog::new(),
            on_change: Vec::new(),
            base: String::new(),
        }
    }
}
/// Flattens nested Lua translation tables into dot-separated string entries.
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
            LuaValue::String(s) => {
                out.insert(full_key, s.to_str().unwrap_or("").to_string());
            }
            LuaValue::Integer(n) => {
                out.insert(full_key, n.to_string());
            }
            LuaValue::Number(f) => {
                out.insert(full_key, f.to_string());
            }
            LuaValue::Boolean(b) => {
                out.insert(full_key, b.to_string());
            }
            _ => {}
        }
    }
}
/// Registers `lurek.i18n` localization catalog, lookup, formatting, and coverage helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let loc = lua.create_table()?;
    let shared = Rc::new(RefCell::new(LocalizationShared::new()));
    let s = shared.clone();
    // -- loadTable --
    /// Loads translations for a locale from a nested Lua table flattened with dot-separated keys.
    /// @param | locale | string | Locale code to load.
    /// @param | tbl | table | Translation table containing strings, numbers, booleans, or nested tables.
    loc.set(
        "loadTable",
        lua.create_function(move |_lua, (locale, tbl): (String, LuaTable)| {
            let mut flat = HashMap::new();
            flatten_lua_table(&tbl, "", &mut flat);
            s.borrow_mut().catalog.load(&locale, flat);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- unloadTable --
    /// Removes all translations for a locale from the catalog.
    /// @param | locale | string | Locale code to unload.
    /// @return | boolean | True when a locale table was removed.
    loc.set(
        "unloadTable",
        lua.create_function(move |_, locale: String| Ok(s.borrow_mut().catalog.unload(&locale)))?,
    )?;
    let s = shared.clone();
    // -- setLanguage --
    /// Sets the active locale and invokes registered change callbacks with new and old locale values.
    /// @param | locale | string | Locale code to activate.
    loc.set(
        "setLanguage",
        lua.create_function(move |lua, locale: String| {
            let old;
            let callbacks: Vec<LuaFunction>;
            {
                let mut st = s.borrow_mut();
                old = st.catalog.locale.clone();
                st.catalog.locale = locale.clone();
                callbacks = st
                    .on_change
                    .iter()
                    .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                    .collect();
            }
            for cb in callbacks {
                let _: LuaMultiValue = cb.call((locale.clone(), old.clone()))?;
            }
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- getLanguage --
    /// Returns the active locale code string.
    /// @return | string | Active locale string, or nil when no locale is active.
    loc.set(
        "getLanguage",
        lua.create_function(move |lua, ()| {
            let locale = s.borrow().catalog.locale.clone();
            if locale.is_empty() {
                Ok(LuaValue::Nil)
            } else {
                Ok(LuaValue::String(lua.create_string(&locale)?))
            }
        })?,
    )?;
    let s = shared.clone();
    // -- getLanguages --
    /// Returns sorted locale codes currently loaded in the catalog.
    /// @return | string[] | Array table of locale codes.
    loc.set(
        "getLanguages",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let mut locales = st.catalog.locales();
            locales.sort();
            let tbl = lua.create_table()?;
            for (i, name) in locales.iter().enumerate() {
                tbl.set(i + 1, *name)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- setFallbacks --
    /// Replaces the fallback locale list used for missing translations.
    /// @param | locales | table | Array table of locale codes in fallback order.
    loc.set(
        "setFallbacks",
        lua.create_function(move |_, locales: LuaTable| {
            let mut fbs = Vec::new();
            for (_, v) in locales.pairs::<LuaValue, String>().flatten() {
                fbs.push(v);
            }
            s.borrow_mut().catalog.fallbacks = fbs;
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- getFallbacks --
    /// Returns fallback locale codes in lookup order.
    /// @return | string[] | Array table of fallback locale codes.
    loc.set(
        "getFallbacks",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, fb) in st.catalog.fallbacks.iter().enumerate() {
                tbl.set(i + 1, fb.clone())?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- t --
    /// Translates a key using the active locale, optional variables, and optional English plural selection.
    /// @param | key | string | Translation key.
    /// @param | vars | table? | Interpolation variables.
    /// @param | count | number? | Plural count, also inserted as `{count}` when variables are used.
    /// @return | string | Translated and interpolated text, or the catalog fallback for the key.
    loc.set(
        "t",
        lua.create_function(
            move |_lua, (key, vars, count): (String, Option<LuaTable>, Option<f64>)| {
                let st = s.borrow();
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
                let result = if let Some(tbl) = vars {
                    let mut map = HashMap::new();
                    for (k, v) in tbl.pairs::<String, String>().flatten() {
                        map.insert(k, v);
                    }
                    if let Some(n) = count {
                        map.entry("count".to_string())
                            .or_insert_with(|| format!("{n}"));
                    }
                    interpolate(&raw, &map)
                } else {
                    raw
                };
                Ok(result)
            },
        )?,
    )?;
    let s = shared.clone();
    // -- hasKey --
    /// Returns whether the catalog contains a translation key in active or fallback locales.
    /// @param | key | string | Translation key to check.
    /// @return | boolean | True when the key is available.
    loc.set(
        "hasKey",
        lua.create_function(move |_, key: String| Ok(s.borrow().catalog.has_key(&key)))?,
    )?;
    let s = shared.clone();
    // -- getKeys --
    /// Returns sorted translation keys known to the catalog.
    /// @return | string[] | Translation keys.
    loc.set(
        "getKeys",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let mut keys = st.catalog.keys();
            keys.sort();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i + 1, *k)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- setKey --
    /// Sets one translation value for one locale and key.
    /// @param | locale | string | Locale code to update.
    /// @param | key | string | Translation key.
    /// @param | value | string | Translation text.
    loc.set(
        "setKey",
        lua.create_function(move |_, (locale, key, value): (String, String, String)| {
            s.borrow_mut().catalog.set_key(&locale, &key, &value);
            Ok(())
        })?,
    )?;
    // -- interpolate --
    /// Replaces `{name}` placeholders in a template using string variables.
    /// @param | template | string | Template text containing placeholders.
    /// @param | vars | table | Map table from placeholder names to replacement strings.
    /// @return | string | Interpolated text.
    loc.set(
        "interpolate",
        lua.create_function(|_, (template, vars): (String, LuaTable)| {
            let mut map = HashMap::new();
            for (k, v) in vars.pairs::<String, String>().flatten() {
                map.insert(k, v);
            }
            Ok(interpolate(&template, &map))
        })?,
    )?;
    // -- pluralFor --
    /// Returns the English plural category key for a number.
    /// @param | n | number | Count used for plural selection.
    /// @return | string | Plural category, usually `one` or `other`.
    loc.set(
        "pluralFor",
        lua.create_function(|_, n: f64| Ok(PluralForm::english(n).key().to_string()))?,
    )?;
    let s = shared.clone();
    // -- onLanguageChange --
    /// Registers a callback invoked when the active locale changes.
    /// @param | cb | function | Callback receiving `(new_locale, old_locale)`.
    loc.set(
        "onLanguageChange",
        lua.create_function(move |lua, cb: LuaFunction| {
            let key = lua.create_registry_value(cb)?;
            s.borrow_mut().on_change.push(key);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- hasLanguage --
    /// Returns whether a locale has translations loaded.
    /// @param | locale | string | Locale code to check.
    /// @return | boolean | True when the locale exists in the catalog.
    loc.set(
        "hasLanguage",
        lua.create_function(move |_, locale: String| Ok(s.borrow().catalog.has_locale(&locale)))?,
    )?;
    let s = shared.clone();
    // -- getAvailableLanguages --
    /// Returns sorted locale codes currently loaded in the catalog.
    /// @return | string[] | Array table of locale codes.
    loc.set(
        "getAvailableLanguages",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let mut locales = st.catalog.locales();
            locales.sort();
            let tbl = lua.create_table()?;
            for (i, name) in locales.iter().enumerate() {
                tbl.set(i + 1, *name)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- setBase --
    /// Sets the base locale string stored by the localization module.
    /// @param | locale | string | Base locale code.
    loc.set(
        "setBase",
        lua.create_function(move |_, locale: String| {
            s.borrow_mut().base = locale.clone();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- getBase --
    /// Returns the base locale string stored by the localization module.
    /// @return | string | Base locale code, or an empty string when unset.
    loc.set(
        "getBase",
        lua.create_function(move |_, ()| Ok(s.borrow().base.clone()))?,
    )?;
    let s = shared.clone();
    // -- onChange --
    /// Registers a locale-change callback using the shorter alias name.
    /// @param | cb | function | Callback receiving `(new_locale, old_locale)`.
    loc.set(
        "onChange",
        lua.create_function(move |lua, cb: LuaFunction| {
            let key = lua.create_registry_value(cb)?;
            s.borrow_mut().on_change.push(key);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- offChange --
    /// Removes every registered locale-change callback.
    loc.set(
        "offChange",
        lua.create_function(move |lua, ()| {
            let keys: Vec<_> = s.borrow_mut().on_change.drain(..).collect();
            for k in keys {
                lua.remove_registry_value(k)?;
            }
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- keyCount --
    /// Returns the number of translation keys known to the catalog.
    /// @return | integer | Translation key count.
    loc.set(
        "keyCount",
        lua.create_function(move |_, ()| Ok(s.borrow().catalog.key_count()))?,
    )?;
    let s = shared.clone();
    // -- categories --
    /// Returns top-level translation key categories.
    /// @return | string[] | Category names.
    loc.set(
        "categories",
        lua.create_function(move |lua, ()| {
            let cats = s.borrow().catalog.categories();
            let tbl = lua.create_table()?;
            for (i, c) in cats.iter().enumerate() {
                tbl.set(i + 1, c.as_str())?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- keysInCategory --
    /// Returns translation keys belonging to one category prefix.
    /// @param | category | string | Category prefix.
    /// @return | string[] | Translation keys.
    loc.set(
        "keysInCategory",
        lua.create_function(move |lua, category: String| {
            let keys = s
                .borrow()
                .catalog
                .keys_in_category(&category)
                .iter()
                .map(|s| s.to_string())
                .collect::<Vec<_>>();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- search --
    /// Searches translation keys and values for a query string.
    /// @param | query | string | Search query.
    /// @param | limit | integer? | Maximum result count; zero or nil means no truncation.
    /// @return | table | Array of rows with `key` and `value` fields.
    /// @field | key | string | Translation key.
    /// @field | value | string | Translated value.
    loc.set(
        "search",
        lua.create_function(move |lua, (query, limit): (String, Option<usize>)| {
            let results = s
                .borrow()
                .catalog
                .search(&query, limit.unwrap_or(0))
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_string()))
                .collect::<Vec<_>>();
            let tbl = lua.create_table()?;
            for (i, (k, v)) in results.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'key' operation.
                row.set("key", k.as_str())?;
                /// Performs the 'value' operation.
                row.set("value", v.as_str())?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- buildIndex --
    /// Builds a word-to-keys search index from the catalog.
    /// @return | string[] | Map table from normalized words to arrays of translation keys.
    loc.set(
        "buildIndex",
        lua.create_function(move |lua, ()| {
            let index = s.borrow().catalog.build_index();
            let tbl = lua.create_table()?;
            for (word, keys) in &index {
                let kt = lua.create_table()?;
                for (i, k) in keys.iter().enumerate() {
                    kt.set(i + 1, k.as_str())?;
                }
                tbl.set(word.as_str(), kt)?;
            }
            Ok(tbl)
        })?,
    )?;
    // -- searchIndexed --
    /// Searches a prebuilt word index and returns matching keys.
    /// @param | index | table | Index table returned by `buildIndex`.
    /// @param | query | string | Search query.
    /// @param | limit | integer? | Maximum key count; zero or nil means no truncation.
    /// @return | string[] | Matching translation keys.
    loc.set(
        "searchIndexed",
        lua.create_function(
            move |lua, (index, query, limit): (LuaTable, String, Option<usize>)| {
                let words: Vec<String> = query
                    .split_whitespace()
                    .map(|w| {
                        w.to_lowercase()
                            .trim_matches(|c: char| !c.is_alphanumeric())
                            .to_string()
                    })
                    .filter(|w| !w.is_empty())
                    .collect();
                if words.is_empty() {
                    return lua.create_table();
                }
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
                for (i, k) in keys.iter().enumerate() {
                    tbl.set(i + 1, k.as_str())?;
                }
                Ok(tbl)
            },
        )?,
    )?;
    let s = shared.clone();
    // -- mergeLocale --
    /// Merges flat translation entries into an existing locale.
    /// @param | locale | string | Locale code to merge into.
    /// @param | entries | table | Map table from translation keys to strings.
    loc.set(
        "mergeLocale",
        lua.create_function(move |_, (locale, entries): (String, LuaTable)| {
            let mut map = std::collections::HashMap::new();
            for pair in entries.pairs::<String, String>() {
                let (k, v) = pair?;
                map.insert(k, v);
            }
            s.borrow_mut().catalog.merge(&locale, map);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    // -- formatNumber --
    /// Formats a number with locale-aware separators and optional decimal precision.
    /// @param | n | number | Number to format.
    /// @param | opts | table? | Table with `decimals` field, defaulting to 2.
    /// @return | string | Formatted number string.
    loc.set(
        "formatNumber",
        lua.create_function(move |_, (n, opts): (f64, Option<LuaTable>)| {
            let decimals = opts
                .and_then(|t| t.get::<_, Option<u32>>("decimals").ok().flatten())
                .unwrap_or(2) as usize;
            let locale = s.borrow().catalog.locale.clone();
            let (decimal_sep, thousands_sep) = locale_separators(&locale);
            Ok(format_number(n, decimals, decimal_sep, thousands_sep))
        })?,
    )?;
    let s = shared.clone();
    // -- formatDate --
    /// Formats a timestamp with the active locale and a named format.
    /// @param | timestamp | integer | Unix timestamp value.
    /// @param | fmt | string? | Format name, defaulting to `short`.
    /// @return | string | Formatted date string.
    loc.set(
        "formatDate",
        lua.create_function(move |_, (timestamp, fmt): (i64, Option<String>)| {
            let locale = s.borrow().catalog.locale.clone();
            let fmt = fmt.as_deref().unwrap_or("short");
            Ok(format_date(timestamp, fmt, &locale))
        })?,
    )?;
    let s = shared.clone();
    // -- tGender --
    /// Translates a gender-specific key variant when present, then falls back to the base key.
    /// @param | key | string | Base translation key.
    /// @param | gender | string | Gender suffix appended to the key.
    /// @param | vars | table? | Interpolation variables.
    /// @return | string | Gender-specific or fallback translated text.
    loc.set(
        "tGender",
        lua.create_function(
            move |_, (key, gender, vars): (String, String, Option<LuaTable>)| {
                let gendered_key = format!("{}.{}", key, gender.to_lowercase());
                let borrowed = s.borrow();
                let raw = if borrowed.catalog.has_key(&gendered_key) {
                    borrowed.catalog.translate(&gendered_key).to_owned()
                } else {
                    borrowed.catalog.translate(&key).to_owned()
                };
                drop(borrowed);
                let result = if let Some(tbl) = vars {
                    let mut out = raw;
                    for (k, v) in tbl.pairs::<String, String>().flatten() {
                        out = out.replace(&format!("{{{}}}", k), &v);
                    }
                    out
                } else {
                    raw
                };
                Ok(result)
            },
        )?,
    )?;
    let s = shared.clone();
    // -- getLoadedLocales --
    /// Returns locale codes currently loaded in the catalog.
    /// @return | string[] | Array table of loaded locale codes.
    loc.set(
        "getLoadedLocales",
        lua.create_function(move |lua, ()| {
            let binding = s.borrow();
            let locales = binding.catalog.locales();
            let tbl = lua.create_table()?;
            for (i, locale) in locales.iter().enumerate() {
                tbl.set(i + 1, *locale)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    // -- isRTL --
    /// Returns whether a locale is written right-to-left.
    /// @param | locale | string? | Locale code; defaults to the active locale.
    /// @return | boolean | True for right-to-left locales.
    loc.set(
        "isRTL",
        lua.create_function(move |_, locale: Option<String>| {
            let code = locale.unwrap_or_else(|| s.borrow().catalog.locale.clone());
            Ok(is_rtl(&code))
        })?,
    )?;
    // -- validateLocale --
    /// Returns whether a locale code has a valid syntax.
    /// @param | locale | string | Locale code to validate.
    /// @return | boolean | True when the code is valid.
    loc.set(
        "validateLocale",
        lua.create_function(|_, locale: String| Ok(is_valid_locale_code(&locale)))?,
    )?;
    // -- detectLocale --
    /// Detects the system locale when available.
    /// @return | string | Locale string, or nil when detection fails.
    loc.set(
        "detectLocale",
        lua.create_function(|lua, ()| match detect_system_locale() {
            Some(code) => Ok(LuaValue::String(lua.create_string(&code)?)),
            None => Ok(LuaValue::Nil),
        })?,
    )?;
    let s = shared.clone();
    // -- loadString --
    /// Loads translations for a locale from TOML or JSON source text.
    /// @param | locale | string | Locale code to load.
    /// @param | content | string | TOML or JSON translation source.
    /// @param | format | string | Source format, either `toml` or `json`.
    loc.set(
        "loadString",
        lua.create_function(
            move |_, (locale, content, format): (String, String, String)| {
                let flat = match format.to_lowercase().as_str() {
                    "toml" => flat_table_from_toml(&content).map_err(mlua::Error::RuntimeError)?,
                    "json" => flat_table_from_json(&content).map_err(mlua::Error::RuntimeError)?,
                    other => {
                        return Err(mlua::Error::RuntimeError(format!(
                            "loadString: unknown format '{}'; expected 'toml' or 'json'",
                            other
                        )))
                    }
                };
                s.borrow_mut().catalog.load(&locale, flat);
                Ok(())
            },
        )?,
    )?;
    let s = shared.clone();
    // -- localeCoverage --
    /// Returns missing translation keys for all locales compared to a reference locale.
    /// @param | reference | string | Locale code used as the coverage reference.
    /// @return | table | Array of gap rows with `key` and `missing_in` fields.
    /// @field | key | string | Translation key.
    /// @field | missing_in | string[] | Locales missing this key.
    loc.set(
        "localeCoverage",
        lua.create_function(move |lua, reference: String| {
            let gaps = s.borrow().catalog.coverage_gaps(&reference);
            let tbl = lua.create_table()?;
            for (i, gap) in gaps.iter().enumerate() {
                let row = lua.create_table()?;
                /// Performs the 'key' operation.
                row.set("key", gap.key.as_str())?;
                let missing = lua.create_table()?;
                for (j, loc) in gap.missing_in.iter().enumerate() {
                    missing.set(j + 1, loc.as_str())?;
                }
                /// Performs the 'missing_in' operation.
                row.set("missing_in", missing)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        })?,
    )?;
    /// Performs the 'i18n' operation.
    lurek.set("i18n", loc)?;
    Ok(())
}
