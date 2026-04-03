//! Registers the `luna.localization.*` internationalization API.
//!
//! Provides a structured translation system supporting multiple languages,
//! fallback chains, pluralization, variable interpolation, and language-change
//! callbacks.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

/// Stores all localization data: loaded translations, active/base language,
/// and change callbacks.
struct LocalizationState {
    /// langCode -> registry key holding the translations table
    languages: HashMap<String, LuaRegistryKey>,
    active: Option<String>,
    base: Option<String>,
    /// onChange callback registry keys
    on_change: Vec<LuaRegistryKey>,
}

impl LocalizationState {
    fn new() -> Self {
        Self {
            languages: HashMap::new(),
            active: None,
            base: None,
            on_change: Vec::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Navigate a nested Lua table using dot-separated keys.
/// Returns the resolved value or Nil.
fn resolve_key<'lua>(_lua: &'lua Lua, table: &LuaTable<'lua>, key: &str) -> LuaResult<LuaValue<'lua>> {
    let parts: Vec<&str> = key.split('.').collect();
    let mut current: LuaValue = LuaValue::Table(table.clone());

    for part in &parts {
        match current {
            LuaValue::Table(t) => {
                current = t.get::<_, LuaValue>(*part)?;
            }
            _ => return Ok(LuaValue::Nil),
        }
    }
    Ok(current)
}

/// Interpolate `{varName}` placeholders in a string.
fn interpolate(text: &str, vars: &LuaTable) -> LuaResult<String> {
    let mut result = text.to_string();
    // Simple brace interpolation: find all {name} patterns
    let mut start = 0;
    while let Some(open_pos) = result[start..].find('{') {
        let open = start + open_pos;
        let close = match result[open..].find('}') {
            Some(pos) => open + pos,
            None => break,
        };
        let var_name = &result[open + 1..close];
        if let Ok(val) = vars.get::<_, LuaValue>(var_name.to_string()) {
            let replacement = match val {
                LuaValue::String(s) => s.to_str().unwrap_or("").to_string(),
                LuaValue::Integer(i) => i.to_string(),
                LuaValue::Number(n) => n.to_string(),
                LuaValue::Boolean(b) => b.to_string(),
                _ => {
                    start = close + 1;
                    continue;
                }
            };
            result = format!("{}{}{}", &result[..open], replacement, &result[close + 1..]);
            start = open + replacement.len();
        } else {
            start = close + 1;
        }
    }
    Ok(result)
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers `luna.localization.*` functions.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let loc = lua.create_table()?;
    let state = Rc::new(RefCell::new(LocalizationState::new()));

    // luna.localization.loadTable(langCode, translations)
    {
        let st = state.clone();
        /// Load table.
        ///
        /// @param lang : string
        /// @param table : table
        loc.set(
            "loadTable",
            lua.create_function(move |lua, (lang, table): (String, LuaTable)| {
                let key = lua.create_registry_value(table)?;
                let mut s = st.borrow_mut();
                if let Some(old) = s.languages.insert(lang, key) {
                    lua.remove_registry_value(old)?;
                }
                Ok(())
            })?,
        )?;
    }

    // luna.localization.setLanguage(langCode)
    {
        let st = state.clone();
        /// Sets the language.
        ///
        /// @param lang : string
        loc.set(
            "setLanguage",
            lua.create_function(move |lua, lang: String| {
                let mut s = st.borrow_mut();
                s.active = Some(lang);
                // Collect callback keys to call outside borrow
                let keys: Vec<&LuaRegistryKey> = s.on_change.iter().collect();
                let funcs: Vec<LuaFunction> = keys
                    .iter()
                    .filter_map(|k| lua.registry_value::<LuaFunction>(k).ok())
                    .collect();
                drop(s);
                for func in funcs {
                    func.call::<_, ()>(())?;
                }
                Ok(())
            })?,
        )?;
    }

    // luna.localization.getLanguage() -> string | nil
    {
        let st = state.clone();
        /// Returns the language.
        ///
        /// @return any
        loc.set(
            "getLanguage",
            lua.create_function(move |_lua, ()| {
                Ok(st.borrow().active.clone())
            })?,
        )?;
    }

    // luna.localization.setBase(langCode)
    {
        let st = state.clone();
        /// Sets the base.
        ///
        /// @param lang : string
        loc.set(
            "setBase",
            lua.create_function(move |_lua, lang: String| {
                st.borrow_mut().base = Some(lang);
                Ok(())
            })?,
        )?;
    }

    // luna.localization.getBase() -> string | nil
    {
        let st = state.clone();
        /// Returns the base.
        ///
        /// @return any
        loc.set(
            "getBase",
            lua.create_function(move |_lua, ()| {
                Ok(st.borrow().base.clone())
            })?,
        )?;
    }

    // luna.localization.hasLanguage(langCode) -> boolean
    {
        let st = state.clone();
        /// Returns true if language.
        ///
        /// @param lang : string
        /// @return any
        loc.set(
            "hasLanguage",
            lua.create_function(move |_lua, lang: String| {
                Ok(st.borrow().languages.contains_key(&lang))
            })?,
        )?;
    }

    // luna.localization.getAvailableLanguages() -> table<string>
    {
        let st = state.clone();
        /// Returns the available languages.
        ///
        /// @return any
        loc.set(
            "getAvailableLanguages",
            lua.create_function(move |lua, ()| {
                let s = st.borrow();
                let table = lua.create_table()?;
                for (i, lang) in s.languages.keys().enumerate() {
                    table.set(i + 1, lang.as_str())?;
                }
                Ok(table)
            })?,
        )?;
    }

    // luna.localization.t(key, vars?) -> string
    {
        let st = state.clone();
        /// T.
        ///
        /// @param key : string
        /// @param vars : table?
        /// @return any
        loc.set(
            "t",
            lua.create_function(move |lua, (key, vars): (String, Option<LuaTable>)| {
                let s = st.borrow();

                // Try active language first
                let mut resolved = LuaValue::Nil;
                if let Some(ref active) = s.active {
                    if let Some(reg_key) = s.languages.get(active) {
                        let table: LuaTable = lua.registry_value(reg_key)?;
                        resolved = resolve_key(lua, &table, &key)?;
                    }
                }

                // Fallback to base language
                if matches!(resolved, LuaValue::Nil) {
                    if let Some(ref base) = s.base {
                        if let Some(reg_key) = s.languages.get(base) {
                            let table: LuaTable = lua.registry_value(reg_key)?;
                            resolved = resolve_key(lua, &table, &key)?;
                        }
                    }
                }

                // If still nil, return the raw key
                if matches!(resolved, LuaValue::Nil) {
                    return Ok(key);
                }

                // Handle pluralization: if resolved value is a table with one/other
                if let LuaValue::Table(ref t) = resolved {
                    if let Some(ref v) = vars {
                        if let Ok(count) = v.get::<_, i64>("count") {
                            let plural_key = if count == 1 { "one" } else { "other" };
                            if let Ok(LuaValue::String(s)) = t.get::<_, LuaValue>(plural_key) {
                                let text = s.to_str().unwrap_or("").to_string();
                                return if let Some(ref v) = vars {
                                    interpolate(&text, v)
                                } else {
                                    Ok(text)
                                };
                            }
                        }
                    }
                    // Table but no count → return key as fallback
                    return Ok(key);
                }

                // Handle string value
                if let LuaValue::String(s) = resolved {
                    let text = s.to_str().unwrap_or("").to_string();
                    if let Some(ref v) = vars {
                        interpolate(&text, v)
                    } else {
                        Ok(text)
                    }
                } else {
                    Ok(key)
                }
            })?,
        )?;
    }

    // luna.localization.onChange(callback)
    {
        let st = state.clone();
        /// On change.
        ///
        /// @param callback : function
        loc.set(
            "onChange",
            lua.create_function(move |lua, callback: LuaFunction| {
                let key = lua.create_registry_value(callback)?;
                st.borrow_mut().on_change.push(key);
                Ok(())
            })?,
        )?;
    }

    // luna.localization.offChange(callback)
    // Note: Since we store registry keys, we compare the function identity
    // by checking if the registry value equals the callback.
    {
        let st = state.clone();
        /// Off change.
        ///
        /// @param callback : function
        loc.set(
            "offChange",
            lua.create_function(move |lua, callback: LuaFunction| {
                let mut s = st.borrow_mut();
                let mut found_idx = None;
                for (i, key) in s.on_change.iter().enumerate() {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        if func == callback {
                            found_idx = Some(i);
                            break;
                        }
                    }
                }
                if let Some(idx) = found_idx {
                    let key = s.on_change.remove(idx);
                    lua.remove_registry_value(key)?;
                }
                Ok(())
            })?,
        )?;
    }

    /// Localization on this Object.
    ///
    /// # Returns
    /// The result.
    luna.set("localization", loc)?;
    Ok(())
}
