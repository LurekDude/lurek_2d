//! `lurek.save` — Persistent game save/load system with named slots, schema versioning, auto-save, compression, and migration support.

use super::SharedState;
use crate::save::{
    compress_save_content, decompress_save_content, serialize_table, SaveManager, SaveValue,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
fn slot_name_from_filename(filename: &str) -> Option<&str> {
    filename
        .strip_prefix("slot_")
        .and_then(|s| s.strip_suffix(".sav"))
}
fn eval_save_content<'a>(vm: &'a Lua, content: &str) -> LuaResult<LuaTable<'a>> {
    let validated = SaveManager::parse_save_string(content).map_err(LuaError::RuntimeError)?;
    vm.load(validated.as_str()).eval()
}
/// Manages persistent game state: registering data collectors/restorers, serializing to named.
/// slots, handling schema migrations, auto-save timers, compression, and lifecycle hooks.
pub struct LuaSaveManager {
    manager: SaveManager,
    state: Rc<RefCell<SharedState>>,
    collectors: HashMap<String, LuaRegistryKey>,
    restorers: HashMap<String, LuaRegistryKey>,
    migrations: HashMap<i32, LuaRegistryKey>,
    compress: bool,
    before_save: Option<LuaRegistryKey>,
    after_load: Option<LuaRegistryKey>,
}
impl LuaSaveManager {
    /// Creates a new Lua-visible save manager bound to shared engine state.
    pub fn new(state: Rc<RefCell<SharedState>>) -> Self {
        Self {
            manager: SaveManager::new(),
            state,
            collectors: HashMap::new(),
            restorers: HashMap::new(),
            migrations: HashMap::new(),
            compress: false,
            before_save: None,
            after_load: None,
        }
    }
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
    fn restore_from_table<'a>(&mut self, lua: &'a Lua, data: LuaTable<'a>) -> LuaResult<()> {
        let saved_ver: i32 = data.get("__schema_version").unwrap_or(0);
        let data = self.apply_migrations(lua, data, saved_ver)?;
        self.call_restorers(lua, &data)?;
        drop(data);
        self.manager.clear_dirty();
        Ok(())
    }
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
    fn save_to_slot(&mut self, lua: &Lua, slot: &str) -> LuaResult<()> {
        if let Some(ref key) = self.before_save {
            let func = lua.registry_value::<LuaFunction>(key)?;
            func.call::<_, ()>(slot)?;
        }
        let plain = self.serialize_collected(lua)?;
        let content = if self.compress {
            compress_save_content(&plain).map_err(LuaError::RuntimeError)?
        } else {
            plain
        };
        let path = SaveManager::slot_path(slot);
        self.state
            .borrow()
            .fs
            .write_string(&path, &content)
            .map_err(|e| LuaError::RuntimeError(format!("lurek.save:save: {}", e)))?;
        self.manager.clear_dirty();
        Ok(())
    }
    fn load_from_slot(&mut self, lua: &Lua, slot: &str) -> LuaResult<(bool, Option<String>)> {
        let path = SaveManager::slot_path(slot);
        let raw = match self.state.borrow().fs.read_string(&path) {
            Ok(c) => c,
            Err(e) => return Ok((false, Some(format!("lurek.save:load: {}", e)))),
        };
        let content: String = match decompress_save_content(&raw) {
            Ok(s) => s,
            Err(e) => return Ok((false, Some(format!("lurek.save:load: {}", e)))),
        };
        let data: LuaTable = match eval_save_content(lua, &content) {
            Ok(t) => t,
            Err(e) => return Ok((false, Some(format!("lurek.save:load: corrupt save: {}", e)))),
        };
        self.restore_from_table(lua, data)?;
        if let Some(ref key) = self.after_load {
            let func = lua.registry_value::<LuaFunction>(key)?;
            func.call::<_, ()>(slot)?;
        }
        Ok((true, None))
    }
    fn delete_slot(&self, slot: &str) -> LuaResult<()> {
        let path = SaveManager::slot_path(slot);
        self.state
            .borrow()
            .fs
            .remove(&path)
            .map_err(|e| LuaError::RuntimeError(format!("lurek.save:delete: {}", e)))?;
        Ok(())
    }
    fn slot_exists(&self, slot: &str) -> bool {
        let path = SaveManager::slot_path(slot);
        self.state.borrow().fs.exists(&path)
    }
    fn read_slot_meta<'a>(&self, lua: &'a Lua, slot: &str) -> LuaResult<Option<LuaTable<'a>>> {
        let path = SaveManager::slot_path(slot);
        let content = {
            let state_ref = self.state.borrow();
            let game_fs = &state_ref.fs;
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
    fn list_slots<'a>(&self, lua: &'a Lua) -> LuaResult<LuaTable<'a>> {
        let result = lua.create_table()?;
        let entries = match self.state.borrow().fs.list("save") {
            Ok(e) => e,
            Err(_) => return Ok(result),
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
        /// Register a named data section with a collector and restorer function pair.
        /// The collector is called during save to gather the current state; the restorer is called during load to apply saved state.
        /// @param | name | string | Unique section name identifying this chunk of save data (e.g. "player", "inventory").
        /// @param | collectFn | function | Called with no arguments during save; must return the data to persist for this section.
        /// @param | restoreFn | function | Called with the saved value during load; responsible for applying it back to game state.
        /// @return | nil | No return value.
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
        /// Remove a previously registered data section by name, cleaning up its collector and restorer callbacks.
        /// @param | name | string | The section name to unregister.
        /// @return | nil | No value is returned.
        methods.add_method_mut("unregister", |lua, this, name: String| {
            this.manager.unregister(&name);
            Self::remove_key(lua, &mut this.collectors, &name)?;
            Self::remove_key(lua, &mut this.restorers, &name)?;
            Ok(())
        });
        // -- setSchemaVersion --
        /// Set the current schema version number for saves produced by this game build.
        /// When loading an older save, migrations registered via addMigration will run in order.
        /// @param | version | number | Integer schema version (must increase with each breaking data format change).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSchemaVersion", |_, this, version: i32| {
            this.manager.set_schema_version(version);
            Ok(())
        });
        // -- getSchemaVersion --
        /// Return the current schema version number set for this save manager.
        /// @return | number | The active schema version integer.
        methods.add_method("getSchemaVersion", |_, this, ()| {
            Ok(this.manager.schema_version())
        });
        // -- addMigration --
        /// Register a migration function that transforms save data from one schema version to the next.
        /// Migrations run in version order when loading saves older than the current schema version.
        /// @param | fromVersion | number | The schema version this migration upgrades FROM (it produces fromVersion+1).
        /// @param | func | function | Receives the full save data table and must return the transformed table.
        /// @return | nil | No return value.
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
        /// Invoke all registered collectors and return the assembled save-data table without writing to disk.
        /// Useful for preview, debug display, or manual serialization.
        /// @return | table | The full save-data table including __schema_version, __timestamp, and __summary metadata.
        methods.add_method("collect", |lua, this, ()| this.collect_data(lua));
        // -- restore --
        /// Apply a previously collected save-data table back into game state by invoking all registered restorers.
        /// Migrations are applied if the table's __schema_version is older than the current version.
        /// @param | data | table | A save-data table (as produced by collect or loaded from disk).
        /// @return | LuaValue | Returned Lua value.
        methods.add_method_mut("restore", |lua, this, data: LuaTable| {
            this.restore_from_table(lua, data)
        });
        // -- markDirty --
        /// Mark the save state as dirty, indicating unsaved changes exist.
        /// When auto-save is enabled, this flag triggers a write on the next auto-save interval.
        /// @return | nil | No value is returned.
        methods.add_method_mut("markDirty", |_, this, ()| {
            this.manager.mark_dirty();
            Ok(())
        });
        // -- isDirty --
        /// Check whether unsaved changes exist since the last save or load.
        /// @return | boolean | True if game state has been modified and not yet persisted.
        methods.add_method("isDirty", |_, this, ()| Ok(this.manager.is_dirty()));
        // -- enableAutoSave --
        /// Enable periodic auto-saving: when the dirty flag is set, the system writes to the target slot every interval seconds.
        /// @param | interval | number | Time in seconds between auto-save checks (e.g. 30.0 for every 30 seconds).
        /// @param | slot | string | The slot name to auto-save into (e.g. "autosave").
        /// @return | nil | No return value.
        methods.add_method_mut(
            "enableAutoSave",
            |_, this, (interval, slot): (f64, String)| {
                this.manager.enable_auto_save(interval, slot);
                Ok(())
            },
        );
        // -- disableAutoSave --
        /// Disable the periodic auto-save timer. Manual saves via save() still work.
        /// @return | nil | No value is returned.
        methods.add_method_mut("disableAutoSave", |_, this, ()| {
            this.manager.disable_auto_save();
            Ok(())
        });
        // -- update --
        /// Advance the auto-save timer by dt seconds. Call this once per frame from your game loop.
        /// Returns true if an auto-save was triggered this tick (dirty flag was set and interval elapsed).
        /// @param | dt | number | Delta time in seconds since the last frame.
        /// @return | boolean | True if an auto-save was triggered during this update.
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.manager.update(dt)));
        // -- setSummary --
        /// Set a human-readable summary string stored alongside save metadata (e.g. "Level 5 – Forest").
        /// This appears in slot listings so players can identify saves without loading them.
        /// @param | summary | string | Short description of the current game progress.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSummary", |_, this, summary: String| {
            this.manager.set_summary(summary);
            Ok(())
        });
        // -- getSummary --
        /// Get the current summary string that will be embedded in the next save.
        /// @return | string | The summary text, or an empty string if none was set.
        methods.add_method("getSummary", |_, this, ()| {
            Ok(this.manager.summary().to_string())
        });
        // -- reset --
        /// Completely reset the save manager: unregister all sections, clear migrations, hooks, compression, and dirty state.
        /// Use this when returning to a main menu or starting a new game session.
        /// @return | nil | No value is returned.
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
            if let Some(key) = this.before_save.take() {
                lua.remove_registry_value(key)?;
            }
            if let Some(key) = this.after_load.take() {
                lua.remove_registry_value(key)?;
            }
            this.compress = false;
            this.manager.reset();
            Ok(())
        });
        // -- setCompress --
        /// Enable or disable LZ4 compression for save files. Compressed saves are smaller on disk.
        /// but slightly slower to write and read. Decompression is handled transparently on load.
        /// @param | enabled | boolean | True to compress future saves, false to write plain text.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCompress", |_, this, enabled: bool| {
            this.compress = enabled;
            Ok(())
        });
        // -- isCompressed --
        /// Check whether save compression is currently enabled.
        /// @return | boolean | True if future saves will be LZ4-compressed.
        methods.add_method("isCompressed", |_, this, ()| Ok(this.compress));
        // -- onBeforeSave --
        /// Set a hook function called immediately before each save operation begins.
        /// Useful for last-moment state snapshots or UI feedback ("Saving...").
        /// Pass nil to clear a previously registered hook.
        /// @param | func | function? | Callback receiving the slot name as its argument, or nil to clear.
        /// @return | nil | No value is returned.
        methods.add_method_mut("onBeforeSave", |lua, this, func: LuaValue| {
            if let Some(key) = this.before_save.take() {
                lua.remove_registry_value(key)?;
            }
            if let LuaValue::Function(f) = func {
                this.before_save = Some(lua.create_registry_value(f)?);
            }
            Ok(())
        });
        // -- onAfterLoad --
        /// Set a hook function called immediately after a save file is successfully loaded and all restorers have run.
        /// Useful for refreshing derived state, triggering UI updates, or logging.
        /// Pass nil to clear a previously registered hook.
        /// @param | func | function? | Callback receiving the slot name as its argument, or nil to clear.
        /// @return | nil | No value is returned.
        methods.add_method_mut("onAfterLoad", |lua, this, func: LuaValue| {
            if let Some(key) = this.after_load.take() {
                lua.remove_registry_value(key)?;
            }
            if let LuaValue::Function(f) = func {
                this.after_load = Some(lua.create_registry_value(f)?);
            }
            Ok(())
        });
        // -- save --
        /// Persist all registered data sections to the named slot file on disk.
        /// Calls the onBeforeSave hook, collects data, optionally compresses, and writes to save/<slot>.sav.
        /// @param | slot | string | Slot name (e.g. "slot1", "quicksave"). The file is stored as save/slot_<name>.sav.
        /// @return | LuaValue | Returned Lua value.
        methods.add_method_mut("save", |lua, this, slot: String| {
            this.save_to_slot(lua, &slot)
        });
        // -- load --
        /// Load game state from a named slot file. Decompresses if needed, applies migrations, calls restorers, then fires onAfterLoad.
        /// @param | slot | string | Slot name to load (e.g. "slot1").
        /// @return | boolean | True if the load succeeded, false on error.
        /// @return | string | Error message if the load failed, nil on success.
        methods.add_method_mut("load", |lua, this, slot: String| {
            this.load_from_slot(lua, &slot)
        });
        // -- delete --
        /// Permanently delete a save slot file from disk. This action cannot be undone.
        /// @param | slot | string | Slot name to delete (e.g. "slot1").
        /// @return | LuaValue | Returned Lua value.
        methods.add_method("delete", |_, this, slot: String| this.delete_slot(&slot));
        // -- exists --
        /// Check whether a save slot file exists on disk without reading its contents.
        /// @param | slot | string | Slot name to check.
        /// @return | boolean | True if the slot file is present.
        methods.add_method(
            "exists",
            |_, this, slot: String| Ok(this.slot_exists(&slot)),
        );
        // -- getSlots --
        /// List all save slots found on disk with their metadata (version, timestamp, summary).
        /// @return | table | Array of info tables, each with fields: slot, version, timestamp, summary.
        methods.add_method("getSlots", |lua, this, ()| this.list_slots(lua));
        // -- getSlotInfo --
        /// Read metadata for a single save slot without loading its full game state.
        /// Returns nil if the slot does not exist or is corrupted.
        /// @param | slot | string | Slot name to inspect.
        /// @return | table | Info table with fields: slot, version, timestamp, summary — or nil.
        methods.add_method("getSlotInfo", |lua, this, slot: String| {
            match this.read_slot_meta(lua, &slot)? {
                Some(info) => Ok(LuaValue::Table(info)),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- type --
        /// Return the type name string for this userdata object.
        /// @return | string | Always "LSaveManager".
        methods.add_method("type", |_, _, ()| Ok("LSaveManager"));
        // -- typeOf --
        /// Check whether this object matches a given type name. Supports "LSaveManager" and "Object".
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if the object matches the given type name.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSaveManager" || name == "Object")
        });
    }
}
/// Register the `lurek.save` module into the Lua runtime.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newSaveManager --
    /// Create a new SaveManager instance for managing persistent game saves.
    /// @return | LSaveManager | A fresh save manager with no registered sections.
    tbl.set(
        "newSaveManager",
        lua.create_function(move |lua, ()| lua.create_userdata(LuaSaveManager::new(s.clone())))?,
    )?;
    lurek.set("save", tbl)?;
    Ok(())
}
