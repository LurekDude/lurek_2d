//! `luna.event` Lua API bindings.
//!
//! Auto-generated skeleton from `src/event/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaEventQueue ────────────────────────────────────────────────────────────

pub struct LuaEventQueue(/* TODO: add key + state fields */);


impl LuaEventQueue {
    /// Check if the queue is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_empty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of events in the queue.
    ///
    ///
    /// @return integer
    pub fn len(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaEventQueue {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isEmpty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("len", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSignal ────────────────────────────────────────────────────────────

pub struct LuaSignal(/* TODO: add key + state fields */);


impl LuaSignal {
    /// Returns the handles registered for the given event name (in registration order).
    ///
    /// Returns an empty slice if no subscriptions exist for the name.
    ///
    /// @param name : str
    /// @return table
    pub fn get_handles(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of subscriptions for the given event name.
    ///
    /// @param name : str
    /// @return integer
    pub fn get_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of subscriptions across all event names.
    ///
    ///
    /// @return integer
    pub fn get_total_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSignal {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getHandles", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTotalCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.event.* functions ──────────────────────────────────────────

/// Push an event onto the queue. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @param event : Event
pub fn push(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Push an event by name and arguments. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param name : str
/// @param args : table
pub fn push_event(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Poll the next event from the queue. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @return Event?
pub fn poll(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Blocks until an event is available or `timeout_ms` milliseconds elapse.
///
/// If the queue already contains an event it is returned immediately without sleeping.
/// With a `Some(0)` timeout the queue is polled once and the function returns.
///
/// @param timeout_ms : integer?
/// @return Event?
pub fn wait(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers a subscription for the given event name.
///
/// Returns a unique handle ID that can be used with [`remove`](Self::remove).
///
/// @param name : str
/// @return integer
pub fn subscribe(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a subscription by its handle ID.
///
/// Returns `true` if the handle existed and was removed.
///
/// @param handle : integer
/// @return boolean
pub fn remove(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes all subscriptions for the given event name.
///
/// Returns the number of subscriptions removed.
///
/// @param name : str
/// @return integer
pub fn clear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes all subscriptions across all event names.
///
/// Returns the total number of subscriptions removed.
///
///
/// @return integer
pub fn clear_all(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.event` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("push", lua.create_function(push)?)?;
    tbl.set("pushEvent", lua.create_function(push_event)?)?;
    tbl.set("poll", lua.create_function(poll)?)?;
    tbl.set("wait", lua.create_function(wait)?)?;
    tbl.set("subscribe", lua.create_function(subscribe)?)?;
    tbl.set("remove", lua.create_function(remove)?)?;
    tbl.set("clear", lua.create_function(clear)?)?;
    tbl.set("clearAll", lua.create_function(clear_all)?)?;
    luna.set("event", tbl)?;
    Ok(())
}
