//! `luna.savegame` — Slot-based save/load system with collectors, schema versioning, and auto-save.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::filesystem::vfs::GameFS;
use crate::savegame::{serialize_table, SaveManager, SaveValue};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Extracts a slot name from a save filename (e.g. `"slot_quick.sav"` → `"quick"`)..
fn slot_name_from_filename(filename: &str) -> Option<&str> {
    filename
        .strip_prefix("slot_")
        .and_then(|s| s.strip_suffix(".sav"))
}

/// Evaluates a Lua chunk from save-file content and returns the result table.
fn eval_save_content<'a>(vm: &'a Lua, content: &str) -> LuaResult<LuaTable<'a>> {
    let validated = SaveManager::parse_save_string(content).map_err(LuaError::RuntimeError)?;
    vm.load(validated.as_str()).eval()
}

// -------------------------------------------------------------------------------
// LuaSaveManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`SaveManager`] with per-module callback storage.
pub struct LuaSaveManager {
    manager: SaveManager,
    state: Rc<RefCell<SharedState>>,
    collectors: HashMap<String, LuaRegistryKey>,
    restorers: HashMap<String, LuaRegistryKey>,
    migrations: HashMap<i32, LuaRegistryKey>,
}

impl LuaSaveManager {
    /// Creates a new empty save manager wrapper.
    fn new(state: Rc<RefCell<SharedState>>) -> Self {
        Self {
            manager: SaveManager::new(),
            state,
            collectors: HashMap::new(),
            restorers: HashMap::new(),
            migrations: HashMap::new(),
        }
    }

    /// Removes a registry key from a map entry and frees it from the Lua registry.
    fn remove_key<K: std::hash::Hash + Eq>(
        lua: &Lua,
        map: &mut HashMap<K, LuaRegistryKey>,
        key: &K,
    ) -> LuaResult<()> {
        if let Some(rk) = map.remove(key) {
            lua.remove_registry_value(rk)?;
        }
        Ok(())
    }

    /// Collects data from all registered collectors into a Lua table with metadata.
    fn collect_data<'a>(&self, lua: &'a Lua) -> LuaResult<LuaTable<'a>> {
        let result = lua.create_table()?;
        for name in self.manager.registered_names() {
            if let Some(key) = self.collectors.get(name) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                let val: LuaValue = func.call(())?;
                result.set(name.as_str(), val)?;
            }
        }
        result.set("__schema_version", self.manager.schema_version())?;
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs_f64())
            .unwrap_or(0.0);
        result.set("__timestamp", timestamp)?;
        result.set("__summary", self.manager.summary())?;
        Ok(result)
    }

    /// Runs applicable migrations on a loaded data table.
    fn apply_migrations<'a>(
        &self,
        lua: &'a Lua,
        mut data: LuaTable<'a>,
        saved_ver: i32,
    ) -> LuaResult<LuaTable<'a>> {
        for ver in self.manager.applicable_migrations(saved_ver) {
            if let Some(key) = self.migrations.get(&ver) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                let result: LuaValue = func.call(data.clone())?;
                if let LuaValue::Table(t) = result {
                    data = t;
                }
            }
        }
        Ok(data)
    }

    /// Calls all registered restorer callbacks with data from the given table.
    fn call_restorers(&self, lua: &Lua, data: &LuaTable) -> LuaResult<()> {
        for name in self.manager.registered_names() {
            if let Some(key) = self.restorers.get(name) {
                let func = lua.registry_value::<LuaFunction>(key)?;
                let val: LuaValue = data.get(name.as_str())?;
                func.call::<_, ()>(val)?;
            }
        }
        Ok(())
    }

    /// Restores data from a Lua table, applying migrations and calling restorers.
    fn restore_from_table<'a>(
        &mut self,
        lua: &'a Lua,
        data: LuaTable<'a>,
    ) -> LuaResult<()> {
        let saved_ver: i32 = data.get("__schema_version").unwrap_or(0);
        let data = self.apply_migrations(lua, data, saved_ver)?;
        self.call_restorers(lua, &data)?;
        drop(data);
        self.manager.clear_dirty();
        Ok(())
    }

    /// Serializes collected data to a Lua-loadable `return { ... }` string.
    fn serialize_collected(&self, lua: &Lua) -> LuaResult<String> {
        let data_table = self.collect_data(lua)?;
        let mut data_map = HashMap::new();
        for pair in data_table.pairs::<String, LuaValue>() {
            let (k, v) = pair?;
            data_map.insert(k, SaveValue::from_lua(&v)?);
        }
        let body = serialize_table(&data_map, 0).map_err(LuaError::RuntimeError)?;
        Ok(format!("return {}\n", body))
    }

    /// Saves collected data to a slot file.
    fn save_to_slot(&mut self, lua: &Lua, slot: &str) -> LuaResult<()> {
        let content = self.serialize_collected(lua)?;
        let path = SaveManager::slot_path(slot);
        let game_dir = self.state.borrow().game_dir.clone();
        GameFS::new(game_dir)
            .write_string(&path, &content)
            .map_err(|e| LuaError::RuntimeError(format!("luna.savegame:save: {}", e)))?;
        self.manager.clear_dirty();
        Ok(())
    }

    /// Loads data from a slot file, applies migrations, and restores.
    fn load_from_slot(&mut self, lua: &Lua, slot: &str) -> LuaResult<(bool, Option<String>)> {
        let path = SaveManager::slot_path(slot);
        let content = {
            let game_dir = self.state.borrow().game_dir.clone();
            match GameFS::new(game_dir).read_string(&path) {
                Ok(c) => c,
                Err(e) => return Ok((false, Some(format!("luna.savegame:load: {}", e)))),
            }
        };
        let data: LuaTable = match eval_save_content(lua, &content) {
            Ok(t) => t,
            Err(e) => {
                return Ok((
                    false,
                    Some(format!("luna.savegame:load: corrupt save: {}", e)),
                ))
            }
        };
        self.restore_from_table(lua, data)?;
        Ok((true, None))
    }

    /// Deletes a slot file.
    fn delete_slot(&self, slot: &str) -> LuaResult<()> {
        let path = SaveManager::slot_path(slot);
        let game_dir = self.state.borrow().game_dir.clone();
        GameFS::new(game_dir)
            .remove(&path)
            .map_err(|e| LuaError::RuntimeError(format!("luna.savegame:delete: {}", e)))?;
        Ok(())
    }

    /// Checks whether a slot file exists.
    fn slot_exists(&self, slot: &str) -> bool {
        let path = SaveManager::slot_path(slot);
        let game_dir = self.state.borrow().game_dir.clone();
        GameFS::new(game_dir).exists(&path)
    }

    /// Reads metadata from a slot file without full restore.
    fn read_slot_meta<'a>(
        &self,
        lua: &'a Lua,
        slot: &str,
    ) -> LuaResult<Option<LuaTable<'a>>> {
        let path = SaveManager::slot_path(slot);
        let content = {
            let game_dir = self.state.borrow().game_dir.clone();
            let game_fs = GameFS::new(game_dir);
            if !game_fs.exists(&path) {
                return Ok(None);
            }
            match game_fs.read_string(&path) {
                Ok(c) => c,
                Err(_) => return Ok(None),
            }
        };
        match eval_save_content(lua, &content) {
            Ok(data) => {
                let info = lua.create_table()?;
                info.set("slot", slot)?;
                let ver: i32 = data.get("__schema_version").unwrap_or(0);
                let ts: f64 = data.get("__timestamp").unwrap_or(0.0);
                let summary: String = data.get("__summary").unwrap_or_default();
                info.set("version", ver)?;
                info.set("timestamp", ts)?;
                info.set("summary", summary)?;
                Ok(Some(info))
            }
            Err(_) => Ok(None),
        }
    }

    /// Lists all save slots with metadata.
    fn list_slots<'a>(&self, lua: &'a Lua) -> LuaResult<LuaTable<'a>> {
        let result = lua.create_table()?;
        let entries = {
            let game_dir = self.state.borrow().game_dir.clone();
            match GameFS::new(game_dir).list("save") {
                Ok(e) => e,
                Err(_) => return Ok(result),
            }
        };
        let mut idx = 1;
        for entry in &entries {
            if let Some(slot_name) = slot_name_from_filename(entry) {
                if let Some(info) = self.read_slot_meta(lua, slot_name)? {
                    result.set(idx, info)?;
                    idx += 1;
                }
            }
        }
        Ok(result)
    }
}

impl LuaUserData for LuaSaveManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- register --
        /// Registers a named module with collector and restorer callbacks.
        /// @param name : string
        /// @param collector : function
        /// @param restorer : function
        /// @return nil
        methods.add_method_mut(
            "register",
            |lua, this, (name, collect_fn, restore_fn): (String, LuaFunction, LuaFunction)| {
                Self::remove_key(lua, &mut this.collectors, &name)?;
                Self::remove_key(lua, &mut this.restorers, &name)?;
                this.collectors
                    .insert(name.clone(), lua.create_registry_value(collect_fn)?);
                this.restorers
                    .insert(name.clone(), lua.create_registry_value(restore_fn)?);
                this.manager.register(&name);
                Ok(())
            },
        );

        // -- unregister --
        /// Removes a named module and its callbacks.
        /// @param name : string
        /// @return nil
        methods.add_method_mut("unregister", |lua, this, name: String| {
            this.manager.unregister(&name);
            Self::remove_key(lua, &mut this.collectors, &name)?;
            Self::remove_key(lua, &mut this.restorers, &name)?;
            Ok(())
        });

        // -- setSchemaVersion --
        /// Sets the current schema version for new saves.
        /// @param version : integer
        /// @return nil
        methods.add_method_mut("setSchemaVersion", |_, this, version: i32| {
            this.manager.set_schema_version(version);
            Ok(())
        });

        // -- getSchemaVersion --
        /// Returns the current schema version.
        /// @return integer
        methods.add_method("getSchemaVersion", |_, this, ()| {
            Ok(this.manager.schema_version())
        });

        // -- addMigration --
        /// Registers a migration function for upgrading from a schema version.
        /// @param from_version : integer
        /// @param func : function
        /// @return nil
        methods.add_method_mut(
            "addMigration",
            |lua, this, (from_ver, func): (i32, LuaFunction)| {
                Self::remove_key(lua, &mut this.migrations, &from_ver)?;
                this.migrations
                    .insert(from_ver, lua.create_registry_value(func)?);
                this.manager.add_migration(from_ver);
                Ok(())
            },
        );

        // -- collect --
        /// Collects data from all registered collectors into a table with metadata.
        /// @return table
        methods.add_method("collect", |lua, this, ()| {
            this.collect_data(lua)
        });

        // -- restore --
        /// Restores data from a table, applying migrations and calling restorers.
        /// @param data : table
        /// @return nil
        methods.add_method_mut("restore", |lua, this, data: LuaTable| {
            this.restore_from_table(lua, data)
        });

        // -- markDirty --
        /// Marks data as modified since the last save or load.
        /// @return nil
        methods.add_method_mut("markDirty", |_, this, ()| {
            this.manager.mark_dirty();
            Ok(())
        });

        // -- isDirty --
        /// Returns whether data has been modified since the last save or load.
        /// @return boolean
        methods.add_method("isDirty", |_, this, ()| {
            Ok(this.manager.is_dirty())
        });

        // -- enableAutoSave --
        /// Enables auto-save with a given interval and target slot.
        /// @param interval : number
        /// @param slot : string
        /// @return nil
        methods.add_method_mut(
            "enableAutoSave",
            |_, this, (interval, slot): (f64, String)| {
                this.manager.enable_auto_save(interval, slot);
                Ok(())
            },
        );

        // -- disableAutoSave --
        /// Disables auto-save.
        /// @return nil
        methods.add_method_mut("disableAutoSave", |_, this, ()| {
            this.manager.disable_auto_save();
            Ok(())
        });

        // -- update --
        /// Advances the auto-save timer, returning the slot name if a save should trigger.
        /// @param dt : number
        /// @return string?
        methods.add_method_mut("update", |_, this, dt: f64| {
            Ok(this.manager.update(dt))
        });

        // -- setSummary --
        /// Sets the summary string included in save metadata.
        /// @param summary : string
        /// @return nil
        methods.add_method_mut("setSummary", |_, this, summary: String| {
            this.manager.set_summary(summary);
            Ok(())
        });

        // -- getSummary --
        /// Returns the current summary string.
        /// @return string
        methods.add_method("getSummary", |_, this, ()| {
            Ok(this.manager.summary().to_string())
        });

        // -- reset --
        /// Resets all state, removing callbacks and clearing the manager.
        /// @return nil
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
            Ok(())
        });

        // -- save --
        /// Collects data and writes it to a slot file.
        /// @param slot : string
        /// @return nil
        methods.add_method_mut("save", |lua, this, slot: String| {
            this.save_to_slot(lua, &slot)
        });

        // -- load --
        /// Loads data from a slot file, applies migrations, and restores.
        /// @param slot : string
        /// @return boolean, string?
        methods.add_method_mut("load", |lua, this, slot: String| {
            this.load_from_slot(lua, &slot)
        });

        // -- delete --
        /// Deletes a save file for the given slot.
        /// @param slot : string
        /// @return nil
        methods.add_method("delete", |_, this, slot: String| {
            this.delete_slot(&slot)
        });

        // -- exists --
        /// Returns whether a save file exists for the given slot.
        /// @param slot : string
        /// @return boolean
        methods.add_method("exists", |_, this, slot: String| {
            Ok(this.slot_exists(&slot))
        });

        // -- getSlots --
        /// Returns a list of all save slots with metadata.
        /// @return table
        methods.add_method("getSlots", |lua, this, ()| {
            this.list_slots(lua)
        });

        // -- getSlotInfo --
        /// Returns metadata for a single slot, or nil if not found.
        /// @param slot : string
        /// @return table?
        methods.add_method("getSlotInfo", |lua, this, slot: String| {
            match this.read_slot_meta(lua, &slot)? {
                Some(info) => Ok(LuaValue::Table(info)),
                None => Ok(LuaValue::Nil),
            }
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.savegame` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newSaveManager --
    /// Creates a new SaveManager for slot-based save/load operations.
    /// @return SaveManager
    let s = state.clone();
    tbl.set(
        "newSaveManager",
        lua.create_function(move |lua, ()| {
            lua.create_userdata(LuaSaveManager::new(s.clone()))
        })?,
    )?;

    luna.set("savegame", tbl)?;
    Ok(())
}
