use super::SharedState;
use crate::event::{Event, EventArg, Signal};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// Signal UserData wrapper
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`Signal`] with registry-stored callbacks.
#[derive(Clone)]
struct LuaSignal {
    /// The underlying signal dispatcher.
    inner: Rc<RefCell<Signal>>,
    /// Maps handle IDs to their Lua registry key for the callback function.
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LunaType for LuaSignal {
    const TYPE_NAME: &'static str = "Signal";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Signal", "Object"];
}

impl LuaUserData for LuaSignal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Registers a callback for the named event.
        ///
        /// Returns a unique handle ID for later removal.
        methods.add_method(
            "register",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let key = lua.create_registry_value(callback)?;
                let handle = this.inner.borrow_mut().subscribe(&name);
                this.callbacks.borrow_mut().insert(handle, key);
                Ok(handle)
            },
        );

        /// Emits the named event, calling all registered callbacks in order.
        ///
        /// Extra arguments are forwarded to each callback.
        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "Signal:emit() requires a string event name as first argument".to_string(),
                    ))
                }
            };
            let extra_args: Vec<LuaValue> = iter.collect();

            // Copy handles to allow safe removal during emit
            let handles = this.inner.borrow().get_handles(&name);
            let callbacks = this.callbacks.borrow();
            for handle in handles {
                if let Some(key) = callbacks.get(&handle) {
                    let func: LuaFunction = lua.registry_value(key)?;
                    let call_args = LuaMultiValue::from_vec(extra_args.clone());
                    func.call::<_, ()>(call_args)?;
                }
            }
            Ok(())
        });

        /// Removes a subscription by handle ID.
        ///
        /// Returns `true` if the handle existed.
        methods.add_method("remove", |lua, this, handle: u64| {
            let removed = this.inner.borrow_mut().remove(handle);
            if removed {
                if let Some(key) = this.callbacks.borrow_mut().remove(&handle) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(removed)
        });

        /// Removes all callbacks for the named event.
        ///
        /// Returns the count of removed subscriptions.
        methods.add_method("clear", |lua, this, name: String| {
            // Get handles before clearing so we can remove registry keys
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

        /// Removes all callbacks across all events.
        ///
        /// Returns the total count of removed subscriptions.
        methods.add_method("clearAll", |lua, this, ()| {
            let count = this.inner.borrow_mut().clear_all();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(count)
        });

        /// Returns the callback count for the named event.
        methods.add_method("getCount", |_, this, name: String| {
            Ok(this.inner.borrow().get_count(&name))
        });

        /// Returns the total callback count across all events.
        methods.add_method("getTotalCount", |_, this, ()| {
            Ok(this.inner.borrow().get_total_count())
        });
    }
}

/// Registers `luna.event.quit()` and related engine lifecycle functions into the Lua VM.
///
/// # Parameters
/// - `lua` — The active Lua VM instance.
/// - `luna` — The `luna` global table to attach functions to.
/// - `state` — Shared engine state accessed by the registered closures.
///
/// # Returns
/// `LuaResult<()>` — Ok if all functions were registered successfully; Lua error otherwise.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let event = lua.create_table()?;

    // luna.event.quit(code?)
    /// Pushes a quit event onto the event queue, requesting the engine to stop.
    ///
    /// # Parameters
    /// - `exitcode` — Optional integer exit code (default 0).
    let s = state.clone();
    event.set(
        "quit",
        lua.create_function(move |_, code: Option<i32>| {
            let mut st = s.borrow_mut();
            st.quit_requested = true;
            st.exit_code = code.unwrap_or(0);
            Ok(())
        })?,
    )?;

    // luna.event.push(name, ...)
    /// Pushes a custom event onto the event queue.
    let s = state.clone();
    event.set(
        "push",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "event.push requires a string event name as first argument".to_string(),
                    ))
                }
            };
            let mut event_args = Vec::new();
            for val in iter {
                let arg = match val {
                    LuaValue::String(s) => EventArg::Str(
                        s.to_str()
                            .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                            .to_string(),
                    ),
                    LuaValue::Integer(n) => EventArg::Num(n as f64),
                    LuaValue::Number(n) => EventArg::Num(n),
                    LuaValue::Boolean(b) => EventArg::Bool(b),
                    _ => EventArg::Nil,
                };
                event_args.push(arg);
            }
            let mut st = s.borrow_mut();
            st.event_queue.push(Event {
                name,
                args: event_args,
            });
            Ok(())
        })?,
    )?;

    // luna.event.poll() — returns an iterator function
    /// Polls and returns the next event from the queue, or nil if empty.
    let s = state.clone();
    event.set(
        "poll",
        lua.create_function(move |lua, ()| {
            let state_ref = s.clone();
            lua.create_function(move |lua, ()| {
                let mut st = state_ref.borrow_mut();
                match st.event_queue.poll() {
                    Some(event) => {
                        let mut values = Vec::new();
                        values.push(LuaValue::String(lua.create_string(&event.name)?));
                        for arg in &event.args {
                            let val = match arg {
                                EventArg::Str(s) => LuaValue::String(lua.create_string(s)?),
                                EventArg::Num(n) => LuaValue::Number(*n),
                                EventArg::Bool(b) => LuaValue::Boolean(*b),
                                EventArg::Nil => LuaValue::Nil,
                            };
                            values.push(val);
                        }
                        Ok(LuaMultiValue::from_vec(values))
                    }
                    None => Ok(LuaMultiValue::new()),
                }
            })
        })?,
    )?;

    // luna.event.clear()
    /// Discards all pending events in the queue.
    let s = state.clone();
    event.set(
        "clear",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.event_queue.clear();
            Ok(())
        })?,
    )?;

    /// Event.
    // luna.event.newSignal() -> Signal
    /// Creates a new pub-sub Signal dispatcher.
    event.set(
        "newSignal",
        lua.create_function(|_, ()| {
            Ok(LuaSignal {
                inner: Rc::new(RefCell::new(Signal::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    luna.set("event", event)?;
    Ok(())
}
