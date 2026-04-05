//! `luna.timer` Lua API bindings.
//!
//! Auto-generated skeleton from `src/timer/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaClock ────────────────────────────────────────────────────────────

pub struct LuaClock(/* TODO: add key + state fields */);


impl LuaClock {
    /// Returns the delta time for the most recently completed frame in seconds.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn delta(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total elapsed time since the clock was created, in seconds.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn total(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the rolling frames-per-second measurement.
    ///
    /// Updated once per second. Returns `0.0` during the first second of execution.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn fps(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of frames that have elapsed since the clock was created.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn frame_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the average delta time over the last N frames (up to 60).
    ///
    /// Returns `0.0` if no frames have been ticked yet. Once the buffer is full,
    /// averages over the entire 60-frame window.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn average_delta(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaClock {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("delta", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("total", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("fps", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("frameCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("averageDelta", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaScheduler ────────────────────────────────────────────────────────────

pub struct LuaScheduler(/* TODO: add key + state fields */);


impl LuaScheduler {
    /// Returns `true` if the event with `id` is currently paused.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param id : integer
    /// @return boolean
    pub fn is_paused(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the time remaining until the next fire for event `id`, or `None` if not found.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `number?`.
    ///
    /// @param id : integer
    /// @return number?
    pub fn get_remaining(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the base interval for event `id`, or `None` if not found.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `number?`.
    ///
    /// @param id : integer
    /// @return number?
    pub fn get_interval(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the repeat count remaining for event `id` (-1 = infinite), or `None` if not found.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param id : integer
    /// @return integer?
    pub fn get_repeat_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current global time-scale.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_time_scale(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of active (non-expired) scheduled events.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the IDs of all active events.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn active_ids(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if no events are scheduled.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_empty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaScheduler {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isPaused", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRemaining", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getInterval", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRepeatCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTimeScale", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("count", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("activeIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEmpty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.timer.* functions ──────────────────────────────────────────

/// Advances the clock by one frame, updating delta time, total time, and rolling FPS.
///
/// Call once per frame at the top of the game loop. The rolling FPS is updated
/// every second using a frame-accumulation window.
///
///
/// # Returns
/// `number`.
///
/// @return number
pub fn tick(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Schedule a one-shot callback after `delay` seconds.
///
///
/// # Parameters
/// - `delay` — `number` ...
///
/// # Returns
/// `integer`.
///
/// @param delay : number
/// @return integer
pub fn after(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Schedule a one-shot callback with a `name` for cancel-by-name support.
///
///
/// # Parameters
/// - `name` — `impl Into<String>` ...
/// - `delay` — `number` ...
///
/// # Returns
/// `integer`.
///
/// @param name : impl Into<String>
/// @param delay : number
/// @return integer
pub fn after_named(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Schedule a repeating callback at `interval` seconds.
///
///
/// # Parameters
/// - `interval` — `number` ...
/// - `count` — `integer` ...
///
/// # Returns
/// `integer`.
///
/// @param interval : number
/// @param count : integer
/// @return integer
pub fn every(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Schedule a named repeating callback.
///
///
/// # Parameters
/// - `name` — `impl Into<String>` ...
/// - `interval` — `number` ...
/// - `count` — `integer` ...
///
/// # Returns
/// `integer`.
///
/// @param name : impl Into<String>
/// @param interval : number
/// @param count : integer
/// @return integer
pub fn every_named(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cancel a scheduled event by its ID.
///
///
/// # Parameters
/// - `id` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param id : integer
/// @return boolean
pub fn cancel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cancel a scheduled event by its name.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `integer?`.
///
/// @param name : str
/// @return integer?
pub fn cancel_named(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cancel all scheduled events.
///
///
/// # Returns
/// `integer`.
///
/// @return integer
pub fn cancel_all(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Pause a single event by ID. Its remaining time is frozen until resumed.
///
///
/// # Parameters
/// - `id` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param id : integer
/// @return boolean
pub fn pause(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Resume a previously paused event by ID.
///
///
/// # Parameters
/// - `id` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param id : integer
/// @return boolean
pub fn resume(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Change the interval of a repeating event.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `new_interval` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param id : integer
/// @param new_interval : number
/// @return boolean
pub fn set_interval(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Reset an event's remaining time to its original interval.
///
///
/// # Parameters
/// - `id` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param id : integer
/// @return boolean
pub fn reset_event(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the global time-scale multiplier for this scheduler.
///
///
/// # Parameters
/// - `scale` — `number` ...
///
/// @param scale : number
pub fn set_time_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advance all non-paused timers by `dt * time_scale` seconds.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// # Returns
/// `table`.
///
/// @param dt : number
/// @return table
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.timer` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("tick", lua.create_function(tick)?)?;
    tbl.set("after", lua.create_function(after)?)?;
    tbl.set("afterNamed", lua.create_function(after_named)?)?;
    tbl.set("every", lua.create_function(every)?)?;
    tbl.set("everyNamed", lua.create_function(every_named)?)?;
    tbl.set("cancel", lua.create_function(cancel)?)?;
    tbl.set("cancelNamed", lua.create_function(cancel_named)?)?;
    tbl.set("cancelAll", lua.create_function(cancel_all)?)?;
    tbl.set("pause", lua.create_function(pause)?)?;
    tbl.set("resume", lua.create_function(resume)?)?;
    tbl.set("setInterval", lua.create_function(set_interval)?)?;
    tbl.set("resetEvent", lua.create_function(reset_event)?)?;
    tbl.set("setTimeScale", lua.create_function(set_time_scale)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    luna.set("timer", tbl)?;
    Ok(())
}
