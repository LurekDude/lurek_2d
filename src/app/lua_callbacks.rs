//! Scope: Lua callback invocation helpers for the app loop.
//! This file defines checked and unchecked callback wrappers with optional timeout control.
//! It owns consistent missing-callback handling and timeout enforcement at callback boundaries.

use std::time::{Duration, Instant};

use mlua::prelude::*;
use mlua::HookTriggers;

// ---- Helper Functions: Lua Callback Invocation ----

/// Calls a named `lurek.*` callback and logs any runtime error.
pub fn call_lua_callback<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    args: A,
) {
    if let Err(e) = call_lua_callback_checked(lua, name, args) {
        log::error!("lurek.{}(): {}", name, e);
    }
}

/// Calls a named `lurek.*` callback and returns any Lua error to the caller.
pub fn call_lua_callback_checked<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    args: A,
) -> Result<(), mlua::Error> {
    call_lua_callback_checked_with_timeout(lua, name, args, None)
}

/// Calls a Lua callback with an optional hard timeout and logs any error.
pub fn call_lua_callback_with_timeout<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    args: A,
    timeout_ms: Option<f32>,
) {
    if let Err(e) = call_lua_callback_checked_with_timeout(lua, name, args, timeout_ms) {
        log::error!("lurek.{}(): {}", name, e);
    }
}

/// Calls a Lua callback and returns any Lua error.
///
/// Missing callbacks are treated as `Ok(())`.
pub fn call_lua_callback_checked_with_timeout<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    args: A,
    timeout_ms: Option<f32>,
) -> Result<(), mlua::Error> {
    if let Ok(lurek) = lua.globals().get::<_, LuaTable>("lurek") {
        if let Ok(func) = lurek.get::<_, LuaFunction>(name) {
            if let Some(ms) = timeout_ms.filter(|ms| *ms > 0.0) {
                return call_with_timeout(lua, name, func, args, ms);
            }
            func.call::<_, ()>(args)?;
        }
    }
    Ok(())
}

fn call_with_timeout<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    func: LuaFunction<'a>,
    args: A,
    timeout_ms: f32,
) -> Result<(), mlua::Error> {
    let timeout = Duration::from_secs_f64((timeout_ms as f64 / 1000.0).max(0.000_001));
    let deadline = Instant::now() + timeout;
    let callback_name = name.to_string();

    lua.set_hook(
        HookTriggers {
            on_calls: false,
            on_returns: false,
            every_line: false,
            every_nth_instruction: Some(20_000),
        },
        move |_, _| {
            if Instant::now() >= deadline {
                return Err(mlua::Error::RuntimeError(format!(
                    "lurek.{}() exceeded callback timeout ({:.2} ms)",
                    callback_name, timeout_ms
                )));
            }
            Ok(())
        },
    );

    let result = func.call::<_, ()>(args);
    lua.remove_hook();
    result
}
