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
        methods.add_method_mut("unregister", |lua, this, name: String| {
            this.manager.unregister(&name);
            Self::remove_key(lua, &mut this.collectors, &name)?;
            Self::remove_key(lua, &mut this.restorers, &name)?;
            Ok(())
        });
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
                Self::remove_key(lua, &mut this.migrations, &from_ver)?;
                this.migrations
                    .insert(from_ver, lua.create_registry_value(func)?);
                this.manager.add_migration(from_ver);
                Ok(())
            },
        );
        methods.add_method("collect", |lua, this, ()| this.collect_data(lua));
        methods.add_method_mut("restore", |lua, this, data: LuaTable| {
            this.restore_from_table(lua, data)
        });
        methods.add_method_mut("markDirty", |_, this, ()| {
            this.manager.mark_dirty();
            Ok(())
        });
        methods.add_method("isDirty", |_, this, ()| Ok(this.manager.is_dirty()));
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
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.manager.update(dt)));
        methods.add_method_mut("setSummary", |_, this, summary: String| {
            this.manager.set_summary(summary);
            Ok(())
        });
        methods.add_method("getSummary", |_, this, ()| {
            Ok(this.manager.summary().to_string())
        });
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
        methods.add_method_mut("setCompress", |_, this, enabled: bool| {
            this.compress = enabled;
            Ok(())
        });
        methods.add_method("isCompressed", |_, this, ()| Ok(this.compress));
        methods.add_method_mut("onBeforeSave", |lua, this, func: LuaValue| {
            if let Some(key) = this.before_save.take() {
                lua.remove_registry_value(key)?;
            }
            if let LuaValue::Function(f) = func {
                this.before_save = Some(lua.create_registry_value(f)?);
            }
            Ok(())
        });
        methods.add_method_mut("onAfterLoad", |lua, this, func: LuaValue| {
            if let Some(key) = this.after_load.take() {
                lua.remove_registry_value(key)?;
            }
            if let LuaValue::Function(f) = func {
                this.after_load = Some(lua.create_registry_value(f)?);
            }
            Ok(())
        });
        methods.add_method_mut("save", |lua, this, slot: String| {
            this.save_to_slot(lua, &slot)
        });
        methods.add_method_mut("load", |lua, this, slot: String| {
            this.load_from_slot(lua, &slot)
        });
        methods.add_method("delete", |_, this, slot: String| this.delete_slot(&slot));
        methods.add_method(
            "exists",
            |_, this, slot: String| Ok(this.slot_exists(&slot)),
        );
        methods.add_method("getSlots", |lua, this, ()| this.list_slots(lua));
        methods.add_method("getSlotInfo", |lua, this, slot: String| {
            match this.read_slot_meta(lua, &slot)? {
                Some(info) => Ok(LuaValue::Table(info)),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("type", |_, _, ()| Ok("LSaveManager"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSaveManager" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "newSaveManager",
        lua.create_function(move |lua, ()| lua.create_userdata(LuaSaveManager::new(s.clone())))?,
    )?;
    lurek.set("save", tbl)?;
    Ok(())
}
