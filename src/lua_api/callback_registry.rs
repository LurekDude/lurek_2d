use mlua::prelude::*;
use std::collections::HashMap;
pub struct CallbackRegistry {
    map: HashMap<u32, LuaRegistryKey>,
    next_id: u32,
}
impl CallbackRegistry {
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
            next_id: 1,
        }
    }
    pub fn register(&mut self, key: LuaRegistryKey) -> u32 {
        let id = self.next_id;
        self.next_id = self.next_id.saturating_add(1);
        self.map.insert(id, key);
        id
    }
    pub fn get(&self, id: u32) -> Option<&LuaRegistryKey> {
        self.map.get(&id)
    }
    pub fn remove(&mut self, id: u32) -> Option<LuaRegistryKey> {
        self.map.remove(&id)
    }
    pub fn contains(&self, id: u32) -> bool {
        self.map.contains_key(&id)
    }
    pub fn clear(&mut self) {
        self.map.clear();
    }
    pub fn len(&self) -> usize {
        self.map.len()
    }
    pub fn is_empty(&self) -> bool {
        self.map.is_empty()
    }
    pub fn invoke<'lua, A, R>(&self, id: u32, lua: &'lua Lua, args: A) -> LuaResult<R>
    where
        A: mlua::IntoLuaMulti<'lua>,
        R: mlua::FromLuaMulti<'lua>,
    {
        let key = self.map.get(&id).ok_or_else(|| {
            mlua::Error::RuntimeError(format!(
                "CallbackRegistry: no callback registered with id {id}"
            ))
        })?;
        let func: LuaFunction = lua.registry_value(key)?;
        func.call::<A, R>(args)
    }
}
impl Default for CallbackRegistry {
    fn default() -> Self {
        Self::new()
    }
}
