//! `luna.signal` — Event queue polling and pub-sub signal dispatching.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::event::{event_to_lua_multi, EventArg, Signal};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
// LuaSignal UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
#[derive(Clone)]
pub struct LuaSignal {
    inner: Rc<RefCell<Signal>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LuaUserData for LuaSignal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- register --
        /// Registers a callback for the named event and returns its handle ID.
        /// @param name : string
        /// @param callback : function
        /// @return integer
        methods.add_method(
            "register",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let key = lua.create_registry_value(callback)?;
                let handle = this.inner.borrow_mut().subscribe(&name);
                this.callbacks.borrow_mut().insert(handle, key);
                Ok(handle)
            },
        );

        // -- emit --
        /// Emits the named event, calling all registered callbacks with extra arguments.
        /// @param name : string
        /// @return nil
        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "Signal:emit() requires a string event name as first argument".into(),
                    ))
                }
            };
            let extra_args: Vec<LuaValue> = iter.collect();
            let handles = this.inner.borrow().get_handles(&name);
            let callbacks = this.callbacks.borrow();
            for handle in handles {
                if let Some(key) = callbacks.get(&handle) {
                    let func: LuaFunction = lua.registry_value(key)?;
                    func.call::<_, ()>(LuaMultiValue::from_vec(extra_args.clone()))?;
                }
            }
            Ok(())
        });

        // -- remove --
        /// Removes a subscription by handle ID.
        /// @param handle : integer
        /// @return boolean
        methods.add_method("remove", |lua, this, handle: u64| {
            let removed = this.inner.borrow_mut().remove(handle);
            if removed {
                if let Some(key) = this.callbacks.borrow_mut().remove(&handle) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(removed)
        });

        // -- clear --
        /// Removes all callbacks for the named event.
        /// @param name : string
        /// @return integer
        methods.add_method("clear", |lua, this, name: String| {
            let handles = this.inner.borrow().get_handles(&name);
            let count = this.inner.borrow_mut().clear(&name);
            let mut cbs = this.callbacks.borrow_mut();
            for handle in handles {
                if let Some(key) = cbs.remove(&handle) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(count)
        });

        // -- clearAll --
        /// Removes all callbacks across all events.
        /// @return integer
        methods.add_method("clearAll", |lua, this, ()| {
            let count = this.inner.borrow_mut().clear_all();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(count)
        });

        // -- getCount --
        /// Returns the callback count for the named event.
        /// @param name : string
        /// @return integer
        methods.add_method("getCount", |_, this, name: String| {
            Ok(this.inner.borrow().get_count(&name))
        });

        // -- getTotalCount --
        /// Returns the total callback count across all events.
        /// @return integer
        methods.add_method("getTotalCount", |_, this, ()| {
            Ok(this.inner.borrow().get_total_count())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Signal"));

        // -- typeOf --
        /// Returns true if the given type name matches this object's type or any parent type.
        /// @param name : string  type name to test
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Signal" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.signal` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- exit --
    /// Pushes an exit event, requesting the engine to stop.
    /// @param code : integer?
    /// @return nil
    let s = state.clone();
    tbl.set(
        "exit",
        lua.create_function(move |_, code: Option<i32>| {
            let mut st = s.borrow_mut();
            st.quit_requested = true;
            st.exit_code = code.unwrap_or(0);
            Ok(())
        })?,
    )?;

    // -- push --
    /// Pushes a custom event onto the event queue.
    /// @param name : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "push",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "event.push requires a string event name as first argument".into(),
                    ))
                }
            };
            let mut event_args = Vec::new();
            for val in iter {
                event_args.push(EventArg::from_lua_val(&val)?);
            }
            s.borrow_mut().event_queue.push_event(&name, event_args);
            Ok(())
        })?,
    )?;

    // -- poll --
    /// Returns an iterator function that pops events from the queue.
    /// @return function
    let s = state.clone();
    tbl.set(
        "poll",
        lua.create_function(move |lua, ()| {
            let state_ref = s.clone();
            lua.create_function(
                move |lua, ()| match state_ref.borrow_mut().event_queue.poll() {
                    Some(event) => event_to_lua_multi(lua, &event),
                    None => Ok(LuaMultiValue::new()),
                },
            )
        })?,
    )?;

    // -- clear --
    /// Discards all pending events in the queue.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "clear",
        lua.create_function(move |_, ()| {
            s.borrow_mut().event_queue.clear();
            Ok(())
        })?,
    )?;

    // -- newSignal --
    /// Creates a new pub-sub Signal dispatcher.
    /// @return Signal
    tbl.set(
        "newSignal",
        lua.create_function(|_, ()| {
            Ok(LuaSignal {
                inner: Rc::new(RefCell::new(Signal::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    // -- pump --
    /// Syncs OS-level events into the queue (no-op in Lurek2D push model).
    /// @return nil
    let s = state.clone();
    tbl.set(
        "pump",
        lua.create_function(move |_, ()| {
            s.borrow().event_queue.pump();
            Ok(())
        })?,
    )?;

    // -- wait --
    /// Blocks until the next event arrives or the optional timeout elapses.
    /// @param timeout : number?
    /// @return string?
    let s = state.clone();
    tbl.set(
        "wait",
        lua.create_function(move |lua, timeout: Option<f64>| {
            let timeout_ms = timeout.map(|t| (t * 1000.0) as u64);
            match s.borrow_mut().event_queue.wait(timeout_ms) {
                Some(event) => event_to_lua_multi(lua, &event),
                None => Ok(LuaMultiValue::new()),
            }
        })?,
    )?;

    // -- restart --
    /// Requests that the engine restart at the beginning of the next frame.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "restart",
        lua.create_function(move |_, ()| {
            s.borrow_mut().restart_requested = true;
            Ok(())
        })?,
    )?;

    // -- quit --
    /// Alias for `exit()` — requests the engine to stop at the end of the current frame.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "quit",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.quit_requested = true;
            st.exit_code = 0;
            Ok(())
        })?,
    )?;

    luna.set("signal", tbl)?;
    Ok(())
}
