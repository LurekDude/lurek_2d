//! Shared callback registry for Lua extensibility.
//!
//! Provides a type-safe store that maps opaque `u32` IDs to Lua registry keys.
//! Domain modules (`src/ai/`, `src/particle/`, etc.) reference callbacks via
//! lightweight `u32` IDs — no `mlua` coupling in domain code (TST-03 compliant).
//! The Lua API layer (`src/lua_api/`) resolves IDs to actual Lua function calls.

use std::collections::HashMap;

use mlua::prelude::*;

// ── CallbackRegistry ──────────────────────────────────────────────────────────

/// Opaque store mapping `u32` IDs to [`LuaRegistryKey`] values.
///
/// Callers obtain an ID from [`register`][CallbackRegistry::register] and hand
/// that integer to domain code.  When the domain code needs to fire the
/// callback it passes the ID back through the Lua API layer, which calls
/// [`invoke`][CallbackRegistry::invoke].
pub struct CallbackRegistry {
    map: HashMap<u32, LuaRegistryKey>,
    next_id: u32,
}

impl CallbackRegistry {
    /// Creates an empty [`CallbackRegistry`].
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
            next_id: 1,
        }
    }

    /// Stores `key` in the registry and returns a new opaque ID.
    ///
    /// `key` must be a [`LuaRegistryKey`] obtained from `lua.create_registry_value(...)`.
    pub fn register(&mut self, key: LuaRegistryKey) -> u32 {
        let id = self.next_id;
        self.next_id = self.next_id.saturating_add(1);
        self.map.insert(id, key);
        id
    }

    /// Returns a reference to the registry key associated with `id`, or `None`.
    ///
    /// `id` is the opaque callback ID returned by [`register`][CallbackRegistry::register].
    pub fn get(&self, id: u32) -> Option<&LuaRegistryKey> {
        self.map.get(&id)
    }

    /// Removes and returns the registry key associated with `id`, or `None`.
    ///
    /// `id` is the opaque callback ID to remove.
    pub fn remove(&mut self, id: u32) -> Option<LuaRegistryKey> {
        self.map.remove(&id)
    }

    /// Returns `true` if `id` is currently stored in the registry.
    ///
    /// `id` is the opaque callback ID to check.
    pub fn contains(&self, id: u32) -> bool {
        self.map.contains_key(&id)
    }

    /// Removes all entries from the registry.
    pub fn clear(&mut self) {
        self.map.clear();
    }

    /// Returns the number of registered callbacks.
    pub fn len(&self) -> usize {
        self.map.len()
    }

    /// Returns `true` if no callbacks are registered.
    pub fn is_empty(&self) -> bool {
        self.map.is_empty()
    }

    /// Looks up `id`, calls the stored Lua function with `args`, and returns the result.
    ///
    /// Returns a descriptive [`mlua::Error`] if the ID is not found or if the
    /// stored value is not callable. `id` is the opaque callback ID to invoke,
    /// `lua` is the active [`Lua`] VM handle, and `args` are forwarded through
    /// [`mlua::IntoLuaMulti`].
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
