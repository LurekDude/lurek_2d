//! Public types and helpers for the callback_registry module.

use mlua::prelude::*;
use std::collections::HashMap;
/// Defines the public callback registry data type used by this module.
pub struct CallbackRegistry {
    map: HashMap<u32, LuaRegistryKey>,
    next_id: u32,
}
impl CallbackRegistry {
    /// Creates a new value. This function is part of the public API.
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
            next_id: 1,
        }
    }
    /// Register. This function is part of the public API.
    pub fn register(&mut self, key: LuaRegistryKey) -> u32 {
        let id = self.next_id;
        self.next_id = self.next_id.saturating_add(1);
        self.map.insert(id, key);
        id
    }
    /// Returns a value. This function is part of the public API.
    pub fn get(&self, id: u32) -> Option<&LuaRegistryKey> {
        self.map.get(&id)
    }
    /// Removes or clears stored state.
    pub fn remove(&mut self, id: u32) -> Option<LuaRegistryKey> {
        self.map.remove(&id)
    }
    /// Contains. This function is part of the public API.
    pub fn contains(&self, id: u32) -> bool {
        self.map.contains_key(&id)
    }
    /// Removes or clears stored state.
    pub fn clear(&mut self) {
        self.map.clear();
    }
    /// Len. This function is part of the public API.
    pub fn len(&self) -> usize {
        self.map.len()
    }
    /// Returns true if empty. This function is part of the public API.
    pub fn is_empty(&self) -> bool {
        self.map.is_empty()
    }
    /// Invoke. This function is part of the public API.
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
