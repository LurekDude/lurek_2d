use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::SharedState;
use crate::filesystem::vfs::GameFS;
use crate::savegame::SaveManager;

/// Lua wrapper around `SaveManager` that also stores Lua collector/restorer
/// callbacks and migration functions via registry keys.
struct LuaSaveManager {
    manager: SaveManager,
    state: Rc<RefCell<SharedState>>,
    collectors: HashMap<String, LuaRegistryKey>,
    restorers: HashMap<String, LuaRegistryKey>,
    migrations: HashMap<i32, LuaRegistryKey>,
    summary: String,
}

impl LuaSaveManager {
    fn new(state: Rc<RefCell<SharedState>>) -> Self {
        Self {
            manager: SaveManager::new(),
            state,
            collectors: HashMap::new(),
            restorers: HashMap::new(),
            migrations: HashMap::new(),
            summary: String::new(),
        }
    }

    /// Build the save file path for a given slot name.
    fn slot_path(slot: &str) -> String {
        format!("save/slot_{}.sav", slot)
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
        methods.add_method_mut("setSchemaVersion", |_, this, version: i32| {
            this.manager.set_schema_version(version);
            Ok(())
        });

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
        methods.add_method("collect", |lua, this, ()| {
            let result = lua.create_table()?;
            for name in this.manager.registered_names() {
                if let Some(key) = this.collectors.get(name) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let val: LuaValue = func.call(())?;
                    result.set(name.as_str(), val)?;
                }
            }
            result.set("__schema_version", this.manager.schema_version())?;
            result.set(
                "__timestamp",
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .map(|d| d.as_secs_f64())
                    .unwrap_or(0.0),
            )?;
            result.set("__summary", this.summary.as_str())?;
            Ok(result)
        });

        // -- restore (from table, runs restorers + migrations) --
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
        methods.add_method_mut("markDirty", |_, this, ()| {
            this.manager.mark_dirty();
            Ok(())
        });

        methods.add_method("isDirty", |_, this, ()| Ok(this.manager.is_dirty()));

        // -- auto-save --
        methods.add_method_mut(
            "enableAutoSave",
            |_, this, (interval, slot): (f64, String)| {
                this.manager.enable_auto_save(interval, slot);
                Ok(())
            },
        );

        methods.add_method_mut("disableAutoSave", |_, this, ()| {
            this.manager.disable_auto_save();
            Ok(())
        });

        methods.add_method_mut("update", |_, this, dt: f64| {
            let trigger = this.manager.update(dt);
            Ok(trigger)
        });

        // -- summary --
        methods.add_method_mut("setSummary", |_, this, summary: String| {
            this.summary = summary;
            Ok(())
        });

        methods.add_method("getSummary", |_, this, ()| Ok(this.summary.clone()));

        // -- reset --
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

        // ── Slot-based File I/O ───────────────────────────────────────────

        // save(slot) — collect all data, serialize to Lua, write to save/slot_{name}.sav
        methods.add_method_mut("save", |lua, this, slot: String| {
            // Collect data from all registered collectors
            let data = lua.create_table()?;
            for name in this.manager.registered_names() {
                if let Some(key) = this.collectors.get(name) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let val: LuaValue = func.call(())?;
                    data.set(name.as_str(), val)?;
                }
            }
            data.set("__schema_version", this.manager.schema_version())?;
            let timestamp = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_secs_f64())
                .unwrap_or(0.0);
            data.set("__timestamp", timestamp)?;
            data.set("__summary", this.summary.as_str())?;

            // Serialize the Lua table to a string
            let serialize_fn = lua.load(
                r#"
                local function serialize(val, depth)
                    if depth > 32 then error("serialization depth limit exceeded") end
                    local t = type(val)
                    if t == "nil" then return "nil"
                    elseif t == "boolean" then return tostring(val)
                    elseif t == "number" then return tostring(val)
                    elseif t == "string" then return string.format("%q", val)
                    elseif t == "table" then
                        local parts = {}
                        for k, v in pairs(val) do
                            local ks
                            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                                ks = k
                            else
                                ks = "[" .. serialize(k, depth + 1) .. "]"
                            end
                            parts[#parts + 1] = ks .. " = " .. serialize(v, depth + 1)
                        end
                        return "{\n" .. table.concat(parts, ",\n") .. "\n}"
                    else
                        error("cannot serialize type: " .. t)
                    end
                end
                return function(tbl) return "return " .. serialize(tbl, 0) .. "\n" end
                "#
            ).eval::<LuaFunction>()?;
            let content: String = serialize_fn.call(data)?;

            // Write to save/slot_{name}.sav
            let path = LuaSaveManager::slot_path(&slot);
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            game_fs.write_string(&path, &content).map_err(|e| {
                LuaError::RuntimeError(format!("luna.savegame:save: {}", e))
            })?;
            this.manager.clear_dirty();
            Ok(())
        });

        // load(slot) → boolean, string? — load save file, restore, run migrations
        methods.add_method_mut("load", |lua, this, slot: String| {
            let path = LuaSaveManager::slot_path(&slot);
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);

            let content = match game_fs.read_string(&path) {
                Ok(c) => c,
                Err(e) => {
                    return Ok((false, Some(format!("luna.savegame:load: {}", e))));
                }
            };
            drop(st);

            // Execute the saved Lua chunk to get the data table
            let data: LuaTable = match lua.load(&content).eval::<LuaTable>() {
                Ok(t) => t,
                Err(e) => {
                    return Ok((false, Some(format!("luna.savegame:load: corrupt save: {}", e))));
                }
            };

            // Run migrations if needed
            let saved_ver: i32 = data.get("__schema_version").unwrap_or(0);
            let applicable = this.manager.applicable_migrations(saved_ver);
            let mut migrated_data = data;
            for ver in applicable {
                if let Some(key) = this.migrations.get(&ver) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let result: LuaValue = func.call(migrated_data.clone())?;
                    if let LuaValue::Table(t) = result {
                        migrated_data = t;
                    }
                }
            }

            // Call restorers
            for name in this.manager.registered_names() {
                if let Some(key) = this.restorers.get(name) {
                    let func = lua.registry_value::<LuaFunction>(key)?;
                    let val: LuaValue = migrated_data.get(name.as_str())?;
                    func.call::<_, ()>(val)?;
                }
            }
            this.manager.clear_dirty();
            Ok((true, None::<String>))
        });

        // delete(slot) — remove the save file
        methods.add_method("delete", |_, this, slot: String| {
            let path = LuaSaveManager::slot_path(&slot);
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            game_fs.remove(&path).map_err(|e| {
                LuaError::RuntimeError(format!("luna.savegame:delete: {}", e))
            })?;
            Ok(())
        });

        // exists(slot) → boolean
        methods.add_method("exists", |_, this, slot: String| {
            let path = LuaSaveManager::slot_path(&slot);
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.exists(&path))
        });

        // getSlots() → table of slot info tables
        methods.add_method("getSlots", |lua, this, ()| {
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            let result = lua.create_table()?;

            let entries = match game_fs.list("save") {
                Ok(e) => e,
                Err(_) => return Ok(result), // save/ dir doesn't exist yet
            };
            drop(st);

            let mut idx = 1;
            for entry in &entries {
                if let Some(slot_name) = entry.strip_prefix("slot_").and_then(|s| s.strip_suffix(".sav")) {
                    let info = lua.create_table()?;
                    info.set("slot", slot_name)?;

                    // Try to read metadata from the file without full restore
                    let path = format!("save/{}", entry);
                    let st2 = this.state.borrow();
                    let game_fs2 = GameFS::new(&st2.game_dir);
                    if let Ok(content) = game_fs2.read_string(&path) {
                        drop(st2);
                        if let Ok(data) = lua.load(&content).eval::<LuaTable>() {
                            let ver: i32 = data.get("__schema_version").unwrap_or(0);
                            let ts: f64 = data.get("__timestamp").unwrap_or(0.0);
                            let summary: String = data.get("__summary").unwrap_or_default();
                            info.set("version", ver)?;
                            info.set("timestamp", ts)?;
                            info.set("summary", summary)?;
                        }
                    } else {
                        drop(st2);
                    }

                    result.set(idx, info)?;
                    idx += 1;
                }
            }
            Ok(result)
        });

        // getSlotInfo(slot) → table|nil — metadata without full restore
        methods.add_method("getSlotInfo", |lua, this, slot: String| {
            let path = LuaSaveManager::slot_path(&slot);
            let st = this.state.borrow();
            let game_fs = GameFS::new(&st.game_dir);

            if !game_fs.exists(&path) {
                return Ok(LuaValue::Nil);
            }

            let content = match game_fs.read_string(&path) {
                Ok(c) => c,
                Err(_) => return Ok(LuaValue::Nil),
            };
            drop(st);

            match lua.load(&content).eval::<LuaTable>() {
                Ok(data) => {
                    let info = lua.create_table()?;
                    info.set("slot", slot)?;
                    let ver: i32 = data.get("__schema_version").unwrap_or(0);
                    let ts: f64 = data.get("__timestamp").unwrap_or(0.0);
                    let summary: String = data.get("__summary").unwrap_or_default();
                    info.set("version", ver)?;
                    info.set("timestamp", ts)?;
                    info.set("summary", summary)?;
                    Ok(LuaValue::Table(info))
                }
                Err(_) => Ok(LuaValue::Nil),
            }
        });
    }
}

/// Registers `luna.savegame.*` functions into the Lua VM.
///
/// Provides a slot-based save/load system with collectors, schema versioning,
/// dirty tracking, and auto-save.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let savegame = lua.create_table()?;

    savegame.set(
        "newSaveManager",
        lua.create_function(move |_lua, ()| Ok(LuaSaveManager::new(state.clone())))?,
    )?;

    luna.set("savegame", savegame)?;
    Ok(())
}
