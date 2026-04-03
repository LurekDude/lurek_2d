//! Savegame Api implementation for the `lua_api` subsystem.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for savegame api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::SharedState;
use crate::savegame::SaveManager;

/// Lua wrapper around `SaveManager` that also stores Lua collector/restorer
/// callbacks and migration functions via registry keys.
struct LuaSaveManager {
    manager: SaveManager,
    collectors: HashMap<String, LuaRegistryKey>,
    restorers: HashMap<String, LuaRegistryKey>,
    migrations: HashMap<i32, LuaRegistryKey>,
    summary: String,
}

impl LuaSaveManager {
    fn new() -> Self {
        Self {
            manager: SaveManager::new(),
            collectors: HashMap::new(),
            restorers: HashMap::new(),
            migrations: HashMap::new(),
            summary: String::new(),
        }
    }
}

impl mlua::UserData for LuaSaveManager {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- registration --
        methods.add_method_mut(
            "register",
            |lua, this, (name, collect_fn, restore_fn): (String, LuaFunction, LuaFunction)| {
                // Remove old refs if re-registering
                if let Some(key) = this.collectors.remove(&name) {
                    lua.remove_registry_value(key)?;
                }
                if let Some(key) = this.restorers.remove(&name) {
                    lua.remove_registry_value(key)?;
                }
                this.collectors
                    .insert(name.clone(), lua.create_registry_value(collect_fn)?);
                this.restorers
                    .insert(name.clone(), lua.create_registry_value(restore_fn)?);
                this.manager.register(&name);
                Ok(())
            },
        );

        /// Removes a previously registered save slot by name.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`: Slot name to remove.
        methods.add_method_mut("unregister", |lua, this, name: String| {
            this.manager.unregister(&name);
            if let Some(key) = this.collectors.remove(&name) {
                lua.remove_registry_value(key)?;
            }
            if let Some(key) = this.restorers.remove(&name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- schema --
        /// Sets the schema version stored in the save file. Increment when save format changes.
        /// @param version : integer
        ///
        /// # Parameters
        /// - `version` — `integer`: New schema version number.
        methods.add_method_mut("setSchemaVersion", |_, this, version: i32| {
            this.manager.set_schema_version(version);
            Ok(())
        });

        /// Returns the schema version currently set on this save manager.
        /// @return any
        ///
        /// # Returns
        /// `integer` — schema version.
        methods.add_method("getSchemaVersion", |_, this, ()| {
            Ok(this.manager.schema_version())
        });

        methods.add_method_mut(
            "addMigration",
            |lua, this, (from_ver, func): (i32, LuaFunction)| {
                if let Some(old) = this.migrations.remove(&from_ver) {
                    lua.remove_registry_value(old)?;
                }
                this.migrations
                    .insert(from_ver, lua.create_registry_value(func)?);
                this.manager.add_migration(from_ver);
                Ok(())
            },
        );

        // -- collect (in-memory only) --
        /// Snapshots all registered tables into an in-memory serializable form, ready for disk write.
        /// @return any
        ///
        /// # Returns
        /// `table` — the collected save data.
        methods.add_method("collect", |lua, this, ()| {
            let result = lua.create_table()?;
            for name in this.manager.registered_names() {
                if let Some(key) = this.collectors.get(name) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let val: LuaValue = func.call(())?;
                    result.set(name.as_str(), val)?;
                }
            }
            /// __schema_version on this SaveManager.
            ///
            /// # Returns
            /// The result.
            result.set("__schema_version", this.manager.schema_version())?;
            result.set(
                "__timestamp",
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .map(|d| d.as_secs_f64())
                    .unwrap_or(0.0),
            )?;
            /// __summary on this SaveManager.
            ///
            /// # Returns
            /// The result.
            result.set("__summary", this.summary.as_str())?;
            Ok(result)
        });

        // -- restore (from table, runs restorers + migrations) --
        /// Restores all registered tables from a previously collected save data table.
        ///
        /// # Parameters
        /// - `data` — `table`: Save data table as returned by `collect()`.
        methods.add_method_mut("restore", |lua, this, mut data: LuaTable| {
            // Run migrations if needed
            let saved_ver: i32 = data.get("__schema_version").unwrap_or(0);
            let applicable = this.manager.applicable_migrations(saved_ver);
            for ver in applicable {
                if let Some(key) = this.migrations.get(&ver) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let result: LuaValue = func.call(data.clone())?;
                    if let LuaValue::Table(t) = result {
                        data = t;
                    }
                }
            }
            // Call restorers
            for name in this.manager.registered_names() {
                if let Some(key) = this.restorers.get(name) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let val: LuaValue = data.get(name.as_str())?;
                    func.call::<_, ()>(val)?;
                }
            }
            this.manager.clear_dirty();
            Ok(())
        });

        // -- dirty tracking --
        /// Marks the save as dirty, ensuring it will be written on the next autosave tick.
        methods.add_method_mut("markDirty", |_, this, ()| {
            this.manager.mark_dirty();
            Ok(())
        });

        /// Returns `true` if the save data has been modified since the last write.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isDirty", |_, this, ()| Ok(this.manager.is_dirty()));

        // -- auto-save --
        methods.add_method_mut(
            "enableAutoSave",
            |_, this, (interval, slot): (f64, String)| {
                this.manager.enable_auto_save(interval, slot);
                Ok(())
            },
        );

        /// Disables automatic periodic saving.
        methods.add_method_mut("disableAutoSave", |_, this, ()| {
            this.manager.disable_auto_save();
            Ok(())
        });

        /// Ticks the autosave timer. Must be called from `luna.update(dt)` when autosave is enabled.
        /// @param dt : number
        /// @return any
        ///
        /// # Parameters
        /// - `dt` — `number`: Elapsed seconds since the last frame.
        methods.add_method_mut("update", |_, this, dt: f64| {
            let trigger = this.manager.update(dt);
            Ok(trigger)
        });

        // -- summary --
        /// Sets a human-readable summary string stored alongside the save data (e.g. for save-slot UI).
        /// @param summary : string
        ///
        /// # Parameters
        /// - `summary` — `string`: Display text for this save slot.
        methods.add_method_mut("setSummary", |_, this, summary: String| {
            this.summary = summary;
            Ok(())
        });

        /// Returns the summary string set by `setSummary`, or an empty string if none was set.
        /// @return any
        ///
        /// # Returns
        /// `string` — save slot summary.
        methods.add_method("getSummary", |_, this, ()| Ok(this.summary.clone()));

        // -- reset --
        /// Clears all registered tables back to their initial state and marks the save dirty.
        methods.add_method_mut("reset", |lua, this, ()| {
            for (_, key) in this.collectors.drain() {
                lua.remove_registry_value(key)?;
            }
            for (_, key) in this.restorers.drain() {
                lua.remove_registry_value(key)?;
            }
            for (_, key) in this.migrations.drain() {
                lua.remove_registry_value(key)?;
            }
            this.manager.reset();
            this.summary.clear();
            Ok(())
        });
    }
}

/// Registers `luna.savegame.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
///
/// Provides a slot-based save/load system with collectors, schema versioning,
/// dirty tracking, and auto-save.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let savegame = lua.create_table()?;

    /// New save manager.
    ///
    savegame.set(
        "newSaveManager",
        lua.create_function(|_lua, ()| Ok(LuaSaveManager::new()))?,
    )?;

    /// Savegame on this SaveManager.
    ///
    /// # Returns
    /// The result.
    luna.set("savegame", savegame)?;
    Ok(())
}
