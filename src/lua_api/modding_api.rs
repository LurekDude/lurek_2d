//! `luna.modding` - Mod discovery, dependency resolution, load ordering, and hot-reload.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::modding::{ModInfo, ModManager};
use std::collections::HashMap;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Reads a Lua info table into a [`ModInfo`].
pub fn mod_info_from_table(tbl: &LuaTable) -> LuaResult<ModInfo> {
    let id: String = tbl
        .get::<_, String>("id")
        .map_err(|_| LuaError::RuntimeError("newMod requires 'id' field".into()))?;
    let dependencies = tbl
        .get::<_, LuaTable>("dependencies")
        .map(|deps| deps.sequence_values::<String>().flatten().collect())
        .unwrap_or_default();
    Ok(ModInfo::from_parts(
        id,
        tbl.get::<_, String>("name").ok(),
        tbl.get::<_, String>("version").ok(),
        tbl.get::<_, String>("author").ok(),
        tbl.get::<_, String>("description").ok(),
        tbl.get::<_, i32>("priority").ok(),
        dependencies,
    ))
}

/// Writes a [`ModInfo`] to a Lua table.
fn mod_info_to_table<'a>(lua: &'a Lua, info: &ModInfo) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    t.set("id", info.id.as_str())?;
    t.set("name", info.name.as_str())?;
    t.set("version", info.version.as_str())?;
    t.set("author", info.author.as_str())?;
    t.set("description", info.description.as_str())?;
    t.set("priority", info.priority)?;
    t.set("enabled", info.enabled)?;
    t.set("loaded", info.loaded)?;
    if let Some(ref p) = info.path {
        t.set("path", p.as_str() as &str)?;
    }
    let deps = lua.create_table()?;
    for (i, dep) in info.dependencies.iter().enumerate() {
        deps.set(i + 1, dep.as_str() as &str)?;
    }
    t.set("dependencies", deps)?;
    Ok(t)
}

/// Converts an iterator of [`ModInfo`] references into a Lua array of info tables.
fn mod_infos_to_table<'a, 'lua>(
    lua: &'lua Lua,
    infos: impl Iterator<Item = &'a ModInfo>,
) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    for (i, info) in infos.enumerate() {
        t.set(i + 1, mod_info_to_table(lua, info)?)?;
    }
    Ok(t)
}

/// Converts a string slice into a Lua array of strings.
fn string_slice_to_table<'a>(lua: &'a Lua, items: &[String]) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    for (i, s) in items.iter().enumerate() {
        t.set(i + 1, s.as_str())?;
    }
    Ok(t)
}

// -------------------------------------------------------------------------------
// LuaMod UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ModInfo`] with per-mod hook and config storage.
pub struct LuaMod {
    pub(super) inner: ModInfo,
    hooks: HashMap<String, LuaRegistryKey>,
    config: Option<LuaRegistryKey>,
}

impl LuaMod {
    /// Creates a new [`LuaMod`] from a [`ModInfo`].
    pub fn new(inner: ModInfo) -> Self {
        Self {
            inner,
            hooks: HashMap::new(),
            config: None,
        }
    }
}

impl LuaUserData for LuaMod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the unique mod identifier.
        /// @return string
        methods.add_method("getId", |_, this, ()| Ok(this.inner.id.clone()));

        // -- getName --
        /// Returns the display name.
        /// @return string
        methods.add_method("getName", |_, this, ()| Ok(this.inner.name.clone()));

        // -- getVersion --
        /// Returns the version string.
        /// @return string
        methods.add_method("getVersion", |_, this, ()| Ok(this.inner.version.clone()));

        // -- getAuthor --
        /// Returns the author name.
        /// @return string
        methods.add_method("getAuthor", |_, this, ()| Ok(this.inner.author.clone()));

        // -- getDescription --
        /// Returns the mod description.
        /// @return string
        methods.add_method("getDescription", |_, this, ()| {
            Ok(this.inner.description.clone())
        });

        // -- getDependencies --
        /// Returns the list of required mod IDs.
        /// @return table
        methods.add_method("getDependencies", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.dependencies)
        });

        // -- getPriority --
        /// Returns the load-order priority.
        /// @return integer
        methods.add_method("getPriority", |_, this, ()| Ok(this.inner.priority));

        // -- isEnabled --
        /// Returns whether the mod is enabled.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| Ok(this.inner.enabled));

        // -- setEnabled --
        /// Sets the enabled state.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.inner.enabled = enabled;
            Ok(())
        });

        // -- isLoaded --
        /// Returns whether the mod has been loaded.
        /// @return boolean
        methods.add_method("isLoaded", |_, this, ()| Ok(this.inner.loaded));

        // -- setHook --
        /// Registers a named hook callback, replacing any existing one.
        /// @param name : string
        /// @param func : function
        /// @return nil
        methods.add_method_mut(
            "setHook",
            |lua, this, (name, func): (String, LuaFunction)| {
                if let Some(old_key) = this.hooks.remove(&name) {
                    lua.remove_registry_value(old_key)?;
                }
                let key = lua.create_registry_value(func)?;
                this.hooks.insert(name, key);
                Ok(())
            },
        );

        // -- getHook --
        /// Returns the hook function for the given name, or nil.
        /// @param name : string
        /// @return function?
        methods.add_method("getHook", |lua, this, name: String| {
            if let Some(key) = this.hooks.get(&name) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                Ok(LuaValue::Function(func))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // -- hasHook --
        /// Returns whether a hook with the given name exists.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasHook", |_, this, name: String| {
            Ok(this.hooks.contains_key(&name))
        });

        // -- getHookNames --
        /// Returns an array of registered hook names.
        /// @return table
        methods.add_method("getHookNames", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, name) in this.hooks.keys().enumerate() {
                t.set(i + 1, name.as_str())?;
            }
            Ok(t)
        });

        // -- setConfig --
        /// Stores an arbitrary config value for this mod.
        /// @param value : table
        /// @return nil
        methods.add_method_mut("setConfig", |lua, this, value: LuaValue| {
            if let Some(old_key) = this.config.take() {
                lua.remove_registry_value(old_key)?;
            }
            let key = lua.create_registry_value(value)?;
            this.config = Some(key);
            Ok(())
        });

        // -- getConfig --
        /// Returns the stored config value, or nil.
        /// @return table?
        methods.add_method("getConfig", |lua, this, ()| {
            if let Some(key) = &this.config {
                lua.registry_value::<LuaValue>(key)
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // -- releaseRefs --
        /// Releases all hook and config registry references.
        /// @return nil
        methods.add_method_mut("releaseRefs", |lua, this, ()| {
            for (_, key) in this.hooks.drain() {
                lua.remove_registry_value(key)?;
            }
            if let Some(key) = this.config.take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Mod({})", this.inner.id))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaModManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ModManager`].
pub struct LuaModManager {
    inner: ModManager,
}

impl LuaModManager {
    /// Creates a new empty [`LuaModManager`].
    pub fn new() -> Self {
        Self {
            inner: ModManager::new(),
        }
    }
}

impl Default for LuaModManager {
    fn default() -> Self {
        Self::new()
    }
}

impl LuaUserData for LuaModManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- registerMod --
        /// Registers a mod from its Mod userdata.
        /// @param mod_ud : Mod
        /// @return nil
        methods.add_method_mut("registerMod", |_, this, ud: LuaAnyUserData| {
            let info = ud.borrow::<LuaMod>()?.inner.clone();
            this.inner.register_mod(info);
            Ok(())
        });

        // -- unregisterMod --
        /// Removes a mod by ID and returns whether it was found.
        /// @param mod_id : string
        /// @return boolean
        methods.add_method_mut("unregisterMod", |_, this, mod_id: String| {
            Ok(this.inner.unregister_mod(&mod_id))
        });

        // -- hasMod --
        /// Returns whether a mod with the given ID is registered.
        /// @param mod_id : string
        /// @return boolean
        methods.add_method("hasMod", |_, this, mod_id: String| {
            Ok(this.inner.has_mod(&mod_id))
        });

        // -- getModCount --
        /// Returns the number of registered mods.
        /// @return integer
        methods.add_method("getModCount", |_, this, ()| Ok(this.inner.mod_count()));

        // -- getAllMods --
        /// Returns an array of info tables for all registered mods.
        /// @return table
        methods.add_method("getAllMods", |lua, this, ()| {
            mod_infos_to_table(lua, this.inner.all_mods().iter())
        });

        // -- getLoadOrder --
        /// Returns an array of info tables in effective load order.
        /// @return table
        methods.add_method("getLoadOrder", |lua, this, ()| {
            let order = this.inner.load_order();
            mod_infos_to_table(lua, order.into_iter())
        });

        // -- validateDependencies --
        /// Returns an array of mod IDs with missing dependencies.
        /// @return table
        methods.add_method("validateDependencies", |lua, this, ()| {
            string_slice_to_table(lua, &this.inner.validate_dependencies())
        });

        // -- hasCircularDependencies --
        /// Returns whether any circular dependency cycles exist.
        /// @return boolean
        methods.add_method("hasCircularDependencies", |_, this, ()| {
            Ok(this.inner.has_circular_dependencies())
        });

        // -- setLoadOrder --
        /// Sets an explicit load order from an array of mod ID strings.
        /// @param order : table
        /// @return nil
        methods.add_method_mut("setLoadOrder", |_, this, order_table: LuaTable| {
            let order: Vec<String> = order_table.sequence_values::<String>().flatten().collect();
            this.inner.set_load_order(order);
            Ok(())
        });

        // -- clearLoadOrder --
        /// Clears the custom load order, reverting to priority-based sorting.
        /// @return nil
        methods.add_method_mut("clearLoadOrder", |_, this, ()| {
            this.inner.clear_load_order();
            Ok(())
        });

        // -- scanFolder --
        /// Scans a directory for mods with mod.toml and registers them.
        /// @param path : string
        /// @return table
        methods.add_method_mut("scanFolder", |lua, this, path: String| {
            let found = this.inner.scan_folder(&path);
            mod_infos_to_table(lua, found.iter())
        });

        // -- getModPath --
        /// Returns the filesystem path of a registered mod, or nil.
        /// @param mod_id : string
        /// @return string?
        methods.add_method("getModPath", |_, this, mod_id: String| {
            Ok(this.inner.get_mod(&mod_id).and_then(|m| m.path.clone()))
        });

        // -- markForReload --
        /// Marks a registered mod for hot-reload.
        /// @param mod_id : string
        /// @return boolean
        methods.add_method_mut("markForReload", |_, this, mod_id: String| {
            Ok(this.inner.mark_for_reload(&mod_id))
        });

        // -- getReloadQueue --
        /// Returns the array of mod IDs pending hot-reload.
        /// @return table
        methods.add_method("getReloadQueue", |lua, this, ()| {
            string_slice_to_table(lua, this.inner.get_reload_queue())
        });

        // -- clearReloadQueue --
        /// Clears the reload queue without reloading.
        /// @return nil
        methods.add_method_mut("clearReloadQueue", |_, this, ()| {
            this.inner.clear_reload_queue();
            Ok(())
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("ModManager({} mods)", this.inner.mod_count()))
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.modding` API table with the Lua VM.
///
/// # Parameters
/// - `lua` - `&Lua`.
/// - `luna` - `&LuaTable`.
/// - `_state` - `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newMod --
    /// Creates a new Mod from an info table with at least an `id` field.
    /// @param info : table
    /// @return Mod
    tbl.set(
        "newMod",
        lua.create_function(|lua, info: LuaTable| {
            let mod_info = mod_info_from_table(&info)?;
            lua.create_userdata(LuaMod::new(mod_info))
        })?,
    )?;

    // -- newModManager --
    /// Creates a new empty ModManager.
    /// @return ModManager
    tbl.set(
        "newModManager",
        lua.create_function(|lua, ()| lua.create_userdata(LuaModManager::new()))?,
    )?;

    luna.set("modding", tbl)?;
    Ok(())
}
