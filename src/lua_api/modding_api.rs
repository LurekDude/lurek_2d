use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::SharedState;
use crate::modding::{ModInfo, ModManager};

/// Lua wrapper around a single mod with hooks and config stored as registry keys.
struct LuaMod {
    info: ModInfo,
    hooks: HashMap<String, LuaRegistryKey>,
    config: Option<LuaRegistryKey>,
}

impl mlua::UserData for LuaMod {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- metadata --
        /// Returns the id.
        ///
        /// # Returns
        /// The current id.
        methods.add_method("getId", |_, this, ()| Ok(this.info.id.clone()));
        /// Returns the name.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.info.name.clone()));
        /// Returns the version.
        ///
        /// # Returns
        /// The current version.
        methods.add_method("getVersion", |_, this, ()| Ok(this.info.version.clone()));
        /// Returns the author.
        ///
        /// # Returns
        /// The current author.
        methods.add_method("getAuthor", |_, this, ()| Ok(this.info.author.clone()));
        /// Returns the description.
        ///
        /// # Returns
        /// The current description.
        methods.add_method("getDescription", |_, this, ()| {
            Ok(this.info.description.clone())
        });
        /// Returns the dependencies.
        ///
        /// # Returns
        /// The current dependencies.
        methods.add_method("getDependencies", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, dep) in this.info.dependencies.iter().enumerate() {
                t.set(i + 1, dep.as_str())?;
            }
            Ok(t)
        });
        /// Returns the priority.
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        ///
        /// # Returns
        /// The current priority.
        methods.add_method("getPriority", |_, this, ()| Ok(this.info.priority));

        // -- state --
        /// Returns `true` if enabled.
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, ()| Ok(this.info.enabled));
        /// Sets the enabled.
        ///
        /// # Parameters
        /// - `enabled` — `boolean`.
        methods.add_method_mut("setEnabled", |_, this, enabled: bool| {
            this.info.enabled = enabled;
            Ok(())
        });
        /// Returns `true` if loaded.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `func` — `function`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isLoaded", |_, this, ()| Ok(this.info.loaded));

        // -- hooks --
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

        /// Returns the hook.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current hook.
        methods.add_method("getHook", |lua, this, name: String| {
            if let Some(key) = this.hooks.get(&name) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                Ok(LuaValue::Function(func))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        /// Returns `true` if hook.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasHook", |_, this, name: String| {
            Ok(this.hooks.contains_key(&name))
        });

        /// Returns the hook names.
        ///
        /// # Returns
        /// The current hook names.
        methods.add_method("getHookNames", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, name) in this.hooks.keys().enumerate() {
                t.set(i + 1, name.as_str())?;
            }
            Ok(t)
        });

        // -- config --
        /// Sets the config.
        ///
        /// # Parameters
        /// - `value` — `any`.
        methods.add_method_mut("setConfig", |lua, this, value: LuaValue| {
            if let Some(old_key) = this.config.take() {
                lua.remove_registry_value(old_key)?;
            }
            let key = lua.create_registry_value(value)?;
            this.config = Some(key);
            Ok(())
        });

        /// Returns the config.
        ///
        /// # Returns
        /// The current config.
        methods.add_method("getConfig", |lua, this, ()| {
            if let Some(key) = &this.config {
                let val = lua.registry_value::<LuaValue>(key)?;
                Ok(val)
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // -- cleanup --
        /// Release refs on this Mod.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("releaseRefs", |lua, this, ()| {
            for (_, key) in this.hooks.drain() {
                lua.remove_registry_value(key)?;
            }
            if let Some(key) = this.config.take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}

/// Lua wrapper around a ModManager that tracks mod UserData refs.
struct LuaModManager {
    manager: ModManager,
    mods: HashMap<String, Rc<RefCell<LuaMod>>>,
}

impl LuaModManager {
    fn new() -> Self {
        Self {
            manager: ModManager::new(),
            mods: HashMap::new(),
        }
    }
}

impl mlua::UserData for LuaModManager {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds mod to the collection.
        ///
        /// # Parameters
        /// - `ud` — `userdata`.
        methods.add_method_mut("registerMod", |_, this, ud: LuaAnyUserData| {
            let borrowed = ud.borrow::<LuaMod>()?;
            let info = borrowed.info.clone();
            let id = info.id.clone();
            this.manager.register_mod(info);
            drop(borrowed);
            // Store the Rc-wrapped LuaMod for later retrieval
            let inner = ud
                .borrow::<LuaMod>()
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            // We can't easily store the UserData reference, so we store a clone of info
            // and rely on getMod returning a fresh wrapper
            drop(inner);
            // Store just the ID; getMod re-creates from manager state
            this.mods.remove(&id); // clear stale
            Ok(())
        });

        /// Removes mod from the collection.
        ///
        /// # Parameters
        /// - `mod_id` — `string`.
        methods.add_method_mut("unregisterMod", |_, this, mod_id: String| {
            this.manager.unregister_mod(&mod_id);
            this.mods.remove(&mod_id);
            Ok(())
        });

        /// Returns `true` if mod.
        ///
        /// # Parameters
        /// - `mod_id` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasMod", |_, this, mod_id: String| {
            Ok(this.manager.has_mod(&mod_id))
        });

        /// Returns the mod count.
        ///
        /// # Returns
        /// The current mod count.
        methods.add_method("getModCount", |_, this, ()| Ok(this.manager.mod_count()));

        /// Returns the all mods.
        ///
        /// # Returns
        /// The current all mods.
        methods.add_method("getAllMods", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, m) in this.manager.all_mods().iter().enumerate() {
                let info_t = lua.create_table()?;
                /// Id on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("id", m.id.as_str())?;
                /// Name on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("name", m.name.as_str())?;
                /// Version on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("version", m.version.as_str())?;
                /// Author on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("author", m.author.as_str())?;
                /// Priority on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("priority", m.priority)?;
                /// Enabled on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("enabled", m.enabled)?;
                /// Loaded on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("loaded", m.loaded)?;
                if let Some(ref p) = m.path {
                    /// Computes the shortest path between nodes.
                    ///
                    /// # Returns
                    /// The result.
                    info_t.set("path", p.as_str())?;
                }
                t.set(i + 1, info_t)?;
            }
            Ok(t)
        });

        /// Returns the load order.
        ///
        /// # Returns
        /// The current load order.
        methods.add_method("getLoadOrder", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, m) in this.manager.load_order().iter().enumerate() {
                let info_t = lua.create_table()?;
                /// Id on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("id", m.id.as_str())?;
                /// Name on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("name", m.name.as_str())?;
                /// Priority on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("priority", m.priority)?;
                /// Enabled on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("enabled", m.enabled)?;
                t.set(i + 1, info_t)?;
            }
            Ok(t)
        });

        /// Validate dependencies on this ModManager.
        ///
        /// # Returns
        /// The result.
        methods.add_method("validateDependencies", |lua, this, ()| {
            let missing = this.manager.validate_dependencies();
            let t = lua.create_table()?;
            for (i, id) in missing.iter().enumerate() {
                t.set(i + 1, id.as_str())?;
            }
            Ok(t)
        });

        /// Returns `true` if circular dependencies.
        ///
        /// # Parameters
        /// - `order_table` — `table`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasCircularDependencies", |_, this, ()| {
            Ok(this.manager.has_circular_dependencies())
        });

        // ── Load Order Control ────────────────────────────────────────────

        // Set explicit load order. Accepts a Lua array of mod ID strings.
        /// Sets the load order.
        ///
        /// # Parameters
        /// - `order_table` — `table`.
        methods.add_method_mut("setLoadOrder", |_, this, order_table: LuaTable| {
            let order: Vec<String> = order_table.sequence_values::<String>().flatten().collect();
            this.manager.set_load_order(order);
            Ok(())
        });

        // Clear custom load order, reverting to priority-based sorting.
        /// Clear load order on this ModManager.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("clearLoadOrder", |_, this, ()| {
            this.manager.clear_load_order();
            Ok(())
        });

        // ── Folder Scanning ───────────────────────────────────────────────

        // Scan a directory for mods with a `mod.toml` in each subdirectory.
        //
        // Returns a Lua array of mod info tables for discovered mods.
        // Mods are automatically registered in the manager.
        /// Scan folder on this ModManager.
        ///
        /// # Parameters
        /// - `path` — `string`.
        methods.add_method_mut("scanFolder", |lua, this, path: String| {
            let found = this.manager.scan_folder(&path);
            let t = lua.create_table()?;
            for (i, m) in found.iter().enumerate() {
                let info_t = lua.create_table()?;
                /// Id on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("id", m.id.as_str())?;
                /// Name on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("name", m.name.as_str())?;
                /// Version on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("version", m.version.as_str())?;
                /// Author on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("author", m.author.as_str())?;
                /// Priority on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("priority", m.priority)?;
                /// Enabled on this ModManager.
                ///
                /// # Returns
                /// The result.
                info_t.set("enabled", m.enabled)?;
                if let Some(ref p) = m.path {
                    /// Computes the shortest path between nodes.
                    ///
                    /// # Returns
                    /// The result.
                    info_t.set("path", p.as_str())?;
                }
                let deps_t = lua.create_table()?;
                for (j, dep) in m.dependencies.iter().enumerate() {
                    deps_t.set(j + 1, dep.as_str())?;
                }
                /// Dependencies on this ModManager.
                ///
                /// # Parameters
                /// - `mod_id` — `string`.
                info_t.set("dependencies", deps_t)?;
                t.set(i + 1, info_t)?;
            }
            Ok(t)
        });

        // Return the filesystem path of a registered mod, or nil if unknown.
        /// Returns the mod path.
        ///
        /// # Parameters
        /// - `mod_id` — `string`.
        ///
        /// # Returns
        /// The current mod path.
        methods.add_method("getModPath", |_, this, mod_id: String| {
            Ok(this.manager.get_mod(&mod_id).and_then(|m| m.path.clone()))
        });

        // ── Hot-reload Queue ──────────────────────────────────────────────

        // Mark a registered mod for hot-reload. Returns true if the mod exists.
        /// Mark for reload on this ModManager.
        ///
        /// # Parameters
        /// - `mod_id` — `string`.
        methods.add_method_mut("markForReload", |_, this, mod_id: String| {
            Ok(this.manager.mark_for_reload(&mod_id))
        });

        // Return the list of mod IDs currently pending hot-reload.
        /// Returns the reload queue.
        ///
        /// # Returns
        /// The current reload queue.
        methods.add_method("getReloadQueue", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, id) in this.manager.get_reload_queue().iter().enumerate() {
                t.set(i + 1, id.as_str())?;
            }
            Ok(t)
        });

        // Clear the reload queue.
        /// Clear reload queue on this ModManager.
        ///
        /// # Returns
        /// The result.
        methods.add_method_mut("clearReloadQueue", |_, this, ()| {
            this.manager.clear_reload_queue();
            Ok(())
        });
    }
}

/// Registers `luna.modding.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
///
/// Provides mod metadata, dependency resolution, hook dispatch,
/// and configuration storage.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let modding = lua.create_table()?;

    modding.set(
        "newMod",
        lua.create_function(|_lua, info: LuaTable| {
            let id: String = info
                .get::<_, String>("id")
                .map_err(|_| LuaError::RuntimeError("newMod requires 'id' field".into()))?;
            let mut mod_info = ModInfo::new(id);
            if let Ok(name) = info.get::<_, String>("name") {
                mod_info.name = name;
            }
            if let Ok(version) = info.get::<_, String>("version") {
                mod_info.version = version;
            }
            if let Ok(author) = info.get::<_, String>("author") {
                mod_info.author = author;
            }
            if let Ok(desc) = info.get::<_, String>("description") {
                mod_info.description = desc;
            }
            if let Ok(priority) = info.get::<_, i32>("priority") {
                mod_info.priority = priority;
            }
            if let Ok(deps) = info.get::<_, LuaTable>("dependencies") {
                let mut dep_list = Vec::new();
                for dep in deps.sequence_values::<String>().flatten() {
                    dep_list.push(dep);
                }
                mod_info.dependencies = dep_list;
            }

            Ok(LuaMod {
                info: mod_info,
                hooks: HashMap::new(),
                config: None,
            })
        })?,
    )?;

    modding.set(
        "newModManager",
        lua.create_function(|_lua, ()| Ok(LuaModManager::new()))?,
    )?;

    /// Modding on this ModManager.
    ///
    /// # Returns
    /// The result.
    luna.set("modding", modding)?;
    Ok(())
}
