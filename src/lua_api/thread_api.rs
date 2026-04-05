//! `luna.thread` Lua API bindings.
//!
//! Auto-generated skeleton from `src/thread/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaChannel ────────────────────────────────────────────────────────────

pub struct LuaChannel(/* TODO: add key + state fields */);


impl LuaChannel {
    /// Push a value to the back of the channel. Returns the push ID.
    ///
    /// @param value : ChannelValue
    /// @return integer
    pub fn push(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Pop a value from the front of the channel (non-blocking).
    ///
    ///
    /// @return ChannelValue?
    pub fn pop(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Peek at the front value without removing it.
    ///
    ///
    /// @return ChannelValue?
    pub fn peek(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Wait for a value, blocking the calling thread.
    ///
    /// @param timeout : number?
    /// @return ChannelValue?
    pub fn demand(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of values currently in the channel.
    ///
    ///
    /// @return integer
    pub fn get_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Push a value only if the channel is currently empty.
    ///
    /// @param value : ChannelValue
    /// @return boolean
    pub fn supply(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the channel name, if it is a named channel.
    ///
    ///
    /// @return Option<
    pub fn name(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaChannel {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("push", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("pop", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("peek", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("demand", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("supply", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("name", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaLuaThread ────────────────────────────────────────────────────────────

pub struct LuaLuaThread(/* TODO: add key + state fields */);


impl LuaLuaThread {
    /// Check whether the thread is currently running.
    ///
    ///
    /// @return boolean
    pub fn is_running(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the error message if the thread terminated with an error.
    ///
    ///
    /// @return string?
    pub fn get_error(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaLuaThread {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isRunning", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getError", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.thread.* functions ──────────────────────────────────────────

/// Create a named channel. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param name : string
/// @return Arc<Self>
pub fn named(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a Lua value into a `ChannelValue` for cross-thread transfer.
///
/// @param value : any
/// @return LuaResult<ChannelValue>
pub fn lua_to_channel_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a `ChannelValue` back into a Lua value.
///
/// @param lua : Lua
/// @param value : ChannelValue
/// @return LuaResult<LuaValue<
pub fn channel_value_to_lua(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Start the thread, spawning a new OS thread with its own Lua VM.
///
/// @param args : table
/// @return Result<()
pub fn start(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.thread` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("named", lua.create_function(named)?)?;
    tbl.set("luaToChannelValue", lua.create_function(lua_to_channel_value)?)?;
    tbl.set("channelValueToLua", lua.create_function(channel_value_to_lua)?)?;
    tbl.set("start", lua.create_function(start)?)?;
    luna.set("thread", tbl)?;
    Ok(())
}
