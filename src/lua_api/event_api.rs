//! `lurek.signal` - Event queue polling and pub-sub signal dispatch.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet, VecDeque};
use std::rc::Rc;

use crate::event::{event_arg_to_lua_value, event_to_lua_multi, EventArg, EventPriority, Signal};

// ---------------------------------------------------------------------------
// LuaSignal UserData
// ---------------------------------------------------------------------------

/// Lua-side wrapper around a [`Signal`] with registry-stored callbacks.
#[derive(Clone)]
pub struct LuaSignal {
    inner: Rc<RefCell<Signal>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    /// Handles that auto-remove after their first fire.
    once_handles: Rc<RefCell<HashSet<u64>>>,
    /// Optional filter predicate stored per-handle; skips callback if it returns false.
    filter_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LuaUserData for LuaSignal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- register --
        /// Registers a Lua callback function for the named event and returns a numeric handle ID.
        /// @param | name | string | The event name to subscribe to (case-sensitive)
        /// @param | callback | function | The Lua function to invoke when the event fires
        /// @return | integer | A unique handle ID for this subscription
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
        /// Fires all callbacks registered for the named event, passing any extra arguments to each callback function.
        /// @param | name | string | The event name to emit (case-sensitive)
        /// @return | nil | No return value.
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
            let mut to_remove: Vec<u64> = Vec::new();
            {
                let callbacks = this.callbacks.borrow();
                let filter_fns = this.filter_fns.borrow();
                let once_handles = this.once_handles.borrow();
                for handle in &handles {
                    // Evaluate filter predicate if present.
                    if let Some(fkey) = filter_fns.get(handle) {
                        let filter_fn: LuaFunction = lua.registry_value(fkey)?;
                        let pass: bool = filter_fn
                            .call::<_, bool>(LuaMultiValue::from_vec(extra_args.clone()))
                            .unwrap_or(false);
                        if !pass {
                            continue;
                        }
                    }
                    if let Some(key) = callbacks.get(handle) {
                        let func: LuaFunction = lua.registry_value(key)?;
                        func.call::<_, ()>(LuaMultiValue::from_vec(extra_args.clone()))?;
                    }
                    if once_handles.contains(handle) {
                        to_remove.push(*handle);
                    }
                }
            }
            // Fire wildcard callbacks.
            let wildcard_handles = this.inner.borrow().get_wildcard_handles(&name);
            {
                let callbacks = this.callbacks.borrow();
                for handle in &wildcard_handles {
                    if let Some(key) = callbacks.get(handle) {
                        if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                            let _ = func.call::<_, ()>(LuaMultiValue::from_vec(extra_args.clone()));
                        }
                    }
                }
            }
            // Auto-remove once handles after emit.
            for handle in to_remove {
                this.inner.borrow_mut().remove(handle);
                if let Some(key) = this.callbacks.borrow_mut().remove(&handle) {
                    lua.remove_registry_value(key)?;
                }
                this.once_handles.borrow_mut().remove(&handle);
                if let Some(fkey) = this.filter_fns.borrow_mut().remove(&handle) {
                    lua.remove_registry_value(fkey)?;
                }
            }
            Ok(())
        });

        // -- remove --
        /// Removes a previously registered subscription identified by its numeric handle.
        /// @param | handle | integer | The subscription handle returned by `register` or `once`
        /// @return | boolean | True if the subscription existed and was removed
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
        /// Removes every callback registered for the specified event name and releases their Lua registry entries.
        /// @param | name | string | The event name whose callbacks should be cleared
        /// @return | integer | The number of callbacks that were removed
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
        /// Removes every callback across all event names in this Signal instance, effectively resetting it to an empty state.
        /// @return | integer | The total number of callbacks that were removed
        methods.add_method("clearAll", |lua, this, ()| {
            let count = this.inner.borrow_mut().clear_all();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(count)
        });

        // -- getCount --
        /// Returns the number of callbacks currently registered for the specified event name.
        /// @param | name | string | The event name to query
        /// @return | integer | The number of active callbacks for this event
        methods.add_method("getCount", |_, this, name: String| {
            Ok(this.inner.borrow().get_count(&name))
        });

        // -- getTotalCount --
        /// Returns the total number of callbacks registered across all event names in this Signal instance.
        /// @return | integer | The total number of active callbacks
        methods.add_method("getTotalCount", |_, this, ()| {
            Ok(this.inner.borrow().get_total_count())
        });

        // -- once --
        /// Registers a one-shot callback that fires at most once for the named event and then automatically removes itself.
        /// @param | name | string | The event name to subscribe to (case-sensitive)
        /// @param | callback | function | The Lua function to invoke exactly once
        /// @return | integer | A unique handle ID for this one-shot subscription
        methods.add_method(
            "once",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let key = lua.create_registry_value(callback)?;
                let handle = this.inner.borrow_mut().subscribe(&name);
                this.callbacks.borrow_mut().insert(handle, key);
                this.once_handles.borrow_mut().insert(handle);
                Ok(handle)
            },
        );

        // -- registerWithFilter --
        /// Registers a callback with an associated filter predicate function.
        /// @param | name | string | The event name to subscribe to (case-sensitive)
        /// @param | callback | function | The Lua function to invoke when the filter passes
        /// @param | filter | function | A predicate function that receives emit args and returns boolean
        /// @return | integer | A unique handle ID for this filtered subscription
        methods.add_method(
            "registerWithFilter",
            |lua, this, (name, callback, filter): (String, LuaFunction, LuaFunction)| {
                let cb_key = lua.create_registry_value(callback)?;
                let filter_key = lua.create_registry_value(filter)?;
                let handle = this.inner.borrow_mut().subscribe(&name);
                this.callbacks.borrow_mut().insert(handle, cb_key);
                this.filter_fns.borrow_mut().insert(handle, filter_key);
                Ok(handle)
            },
        );

        // -- connect --
        /// Subscribes to an event name or wildcard glob pattern and returns a handle.
        /// @param | name | string | An event name or wildcard pattern (e.g. "player.*")
        /// @param | func | function | The Lua function to invoke when a matching event fires
        /// @return | integer | A unique handle ID for this subscription
        methods.add_method(
            "connect",
            |lua, this, (name, func): (String, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                let handle = if Signal::is_wildcard(&name) {
                    this.inner.borrow_mut().subscribe_wildcard(&name)
                } else {
                    this.inner.borrow_mut().subscribe(&name)
                };
                this.callbacks.borrow_mut().insert(handle, key);
                Ok(handle)
            },
        );

        // -- type --
        /// Returns the string type name of this userdata object.
        /// @return | string | The type name (e.g. "LScheduler", "LCamera", "LSignal")
        methods.add_method("type", |_, _, ()| Ok("LSignal"));

        // -- typeOf --
        /// Returns true if the given type name matches this object's type or any parent type.
        /// @param | name | string | type name to test
        /// @return | boolean | True if the object matches the requested type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSignal" || name == "Signal" || name == "Object")
        });
    }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `lurek.signal` API table with the Lua VM.
#[allow(clippy::type_complexity)]
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    fn parse_priority(value: &LuaValue) -> LuaResult<EventPriority> {
        match value {
            LuaValue::String(s) => {
                let name = s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_ascii_lowercase();
                match name.as_str() {
                    "high" => Ok(EventPriority::High),
                    "normal" => Ok(EventPriority::Normal),
                    _ => Err(LuaError::RuntimeError(
                        "event priority must be 'high' or 'normal'".into(),
                    )),
                }
            }
            _ => Err(LuaError::RuntimeError(
                "event priority must be a string ('high' or 'normal')".into(),
            )),
        }
    }

    // -- exit --
    /// Pushes an exit event onto the engine event queue, requesting a graceful shutdown at the end of the current frame.
    /// @param | code | integer? | Optional OS exit code (default 0)
    /// @return | nil | No return value.
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

    // -- poll --
    /// Returns an iterator function that pops events one at a time from the engine event queue.
    /// @return | function | An iterator function that yields (name, ...) tuples
    let s = state.clone();
    tbl.set(
        "poll",
        lua.create_function(move |lua, ()| {
            let s2 = s.clone();
            lua.create_function(move |lua, ()| match s2.borrow_mut().event_queue.poll() {
                Some(event) => event_to_lua_multi(lua, &event),
                None => Ok(LuaMultiValue::new()),
            })
        })?,
    )?;

    // -- clear --
    /// Discards every pending event in the engine event queue without processing them.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "clear",
        lua.create_function(move |_, ()| {
            s.borrow_mut().event_queue.clear();
            Ok(())
        })?,
    )?;

    // -- newSignal --
    /// Creates and returns a new independent Signal pub-sub dispatcher.
    /// @return | LSignal | A new empty Signal instance
    tbl.set(
        "newSignal",
        lua.create_function(|_, ()| {
            Ok(LuaSignal {
                inner: Rc::new(RefCell::new(Signal::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
                once_handles: Rc::new(RefCell::new(HashSet::new())),
                filter_fns: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    // -- pump --
    /// Synchronises OS-level windowing events into the engine event queue.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "pump",
        lua.create_function(move |_, ()| {
            s.borrow().event_queue.pump();
            Ok(())
        })?,
    )?;

    // -- wait --
    /// Blocks the current thread until the next engine event arrives or the optional timeout elapses.
    /// @param | timeout | number? | Maximum seconds to wait (nil = wait indefinitely)
    /// @return | boolean | True when an event was received before the timeout elapsed.
    /// @return | string | Name of the received event.
    /// @return | table | Payload array for the received event.
    let s = state.clone();
    tbl.set(
        "wait",
        lua.create_function(move |lua, timeout: Option<f64>| {
            let timeout_ms = timeout.map(|t| (t * 1000.0) as u64);
            match s.borrow_mut().event_queue.wait(timeout_ms) {
                Some(event) => {
                    let args_tbl = lua.create_table()?;
                    for (index, arg) in event.args.iter().enumerate() {
                        let value = event_arg_to_lua_value(lua, arg)?;
                        args_tbl.set(index + 1, value)?;
                    }
                    Ok(LuaMultiValue::from_vec(vec![
                        LuaValue::Boolean(true),
                        LuaValue::String(lua.create_string(&event.name)?),
                        LuaValue::Table(args_tbl),
                    ]))
                }
                None => {
                    let args_tbl = lua.create_table()?;
                    Ok(LuaMultiValue::from_vec(vec![
                        LuaValue::Boolean(false),
                        LuaValue::String(lua.create_string("")?),
                        LuaValue::Table(args_tbl),
                    ]))
                }
            }
        })?,
    )?;

    // -- restart --
    /// Requests that the engine perform a full restart at the beginning of the next frame.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "restart",
        lua.create_function(move |_, ()| {
            s.borrow_mut().restart_requested = true;
            Ok(())
        })?,
    )?;

    // -- quit --
    /// Alias for `exit()` - requests the engine to stop gracefully at the end of the current frame with exit code 0.
    /// @return | nil | No return value.
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

    // Deferred event queue " events pushed via pushDeferred are batched and
    // only dispatched to the main queue when flushDeferred is called.
    let deferred_queue: Rc<RefCell<Vec<(String, Vec<EventArg>, EventPriority)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // -- pushDeferred --
    /// Pushes a named event into the deferred buffer instead of the main queue.
    /// @param | name | string | The event name to defer
    /// @return | nil | No return value.
    let deferred = deferred_queue.clone();
    tbl.set(
        "pushDeferred",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "event.pushDeferred requires a string event name as first argument".into(),
                    ))
                }
            };
            let mut event_args = Vec::new();
            for val in iter {
                event_args.push(EventArg::from_lua_val(&val)?);
            }
            deferred
                .borrow_mut()
                .push((name, event_args, EventPriority::Normal));
            Ok(())
        })?,
    )?;

    // -- pushDeferredPriority --
    /// Pushes a named event into the deferred buffer with explicit queue priority.
    /// @param | name | string | The event name to defer
    /// @param | priority | string | Queue lane: "high" or "normal"
    /// @return | nil | No return value.
    let deferred = deferred_queue.clone();
    tbl.set(
        "pushDeferredPriority",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "event.pushDeferredPriority requires a string event name as first argument"
                            .into(),
                    ))
                }
            };
            let priority = match iter.next() {
                Some(value) => parse_priority(&value)?,
                None => {
                    return Err(LuaError::RuntimeError(
                        "event.pushDeferredPriority requires a priority as second argument"
                            .into(),
                    ))
                }
            };

            let mut event_args = Vec::new();
            for val in iter {
                event_args.push(EventArg::from_lua_val(&val)?);
            }
            deferred.borrow_mut().push((name, event_args, priority));
            Ok(())
        })?,
    )?;

    // -- flushDeferred --
    /// Moves all events from the deferred buffer into the main engine event queue and clears the buffer.
    /// @return | integer | The number of deferred events moved to the main queue
    let deferred = deferred_queue.clone();
    let s = state.clone();
    tbl.set(
        "flushDeferred",
        lua.create_function(move |_, ()| {
            let mut buf = deferred.borrow_mut();
            let count = buf.len() as u32;
            let mut st = s.borrow_mut();
            for (name, args, priority) in buf.drain(..) {
                st.event_queue.push_event_with_priority(&name, args, priority);
            }
            Ok(count)
        })?,
    )?;

    // History ring-buffer " stores the last N emitted events when history is enabled.
    let history_buf: Rc<RefCell<VecDeque<(String, Vec<EventArg>)>>> =
        Rc::new(RefCell::new(VecDeque::new()));
    let history_cap: Rc<RefCell<usize>> = Rc::new(RefCell::new(0));

    // -- enableHistory --
    /// Enables event history recording, keeping a ring buffer of the last `capacity` events pushed via `push()`.
    /// @param | capacity | integer | Maximum number of events to retain (0 to disable)
    /// @return | nil | No return value.
    let cap = history_cap.clone();
    let hist = history_buf.clone();
    tbl.set(
        "enableHistory",
        lua.create_function(move |_, capacity: usize| {
            *cap.borrow_mut() = capacity;
            let mut buf = hist.borrow_mut();
            while buf.len() > capacity {
                buf.pop_front();
            }
            Ok(())
        })?,
    )?;

    // -- getHistory --
    /// Returns an array of recently pushed events as tables.
    /// @return | table | Array of {name: string, args: table} event records
    let hist = history_buf.clone();
    tbl.set(
        "getHistory",
        lua.create_function(move |lua, ()| {
            let buf = hist.borrow();
            let out = lua.create_table()?;
            for (i, (name, args)) in buf.iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("name", name.clone())?;
                let args_tbl = lua.create_table()?;
                for (j, arg) in args.iter().enumerate() {
                    let v = event_arg_to_lua_value(lua, arg)?;
                    args_tbl.set(j + 1, v)?;
                }
                entry.set("args", args_tbl)?;
                out.set(i + 1, entry)?;
            }
            Ok(out)
        })?,
    )?;

    // -- clearHistory --
    /// Clears all recorded event history entries from the ring buffer.
    /// @return | nil | No return value.
    let hist_c = history_buf.clone();
    tbl.set(
        "clearHistory",
        lua.create_function(move |_, ()| {
            hist_c.borrow_mut().clear();
            Ok(())
        })?,
    )?;

    // -- push --
    /// Pushes a custom named event onto the main engine event queue with optional payload arguments.
    /// @param | name | string | The event name to push (case-sensitive)
    /// @return | nil | No return value.
    let s = state.clone();
    let hist_p = history_buf.clone();
    let cap_p = history_cap.clone();
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
            s.borrow_mut()
                .event_queue
                .push_event(&name, event_args.clone());
            let cap_val = *cap_p.borrow();
            if cap_val > 0 {
                let mut buf = hist_p.borrow_mut();
                buf.push_back((name, event_args));
                while buf.len() > cap_val {
                    buf.pop_front();
                }
            }
            Ok(())
        })?,
    )?;

    // -- pushPriority --
    /// Pushes a custom named event onto a selected queue lane.
    /// @param | name | string | The event name to push (case-sensitive)
    /// @param | priority | string | Queue lane: "high" or "normal"
    /// @return | nil | No return value.
    let s = state.clone();
    let hist_p = history_buf.clone();
    let cap_p = history_cap.clone();
    tbl.set(
        "pushPriority",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String = match iter.next() {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "event.pushPriority requires a string event name as first argument"
                            .into(),
                    ))
                }
            };
            let priority = match iter.next() {
                Some(value) => parse_priority(&value)?,
                None => {
                    return Err(LuaError::RuntimeError(
                        "event.pushPriority requires a priority as second argument".into(),
                    ))
                }
            };

            let mut event_args = Vec::new();
            for val in iter {
                event_args.push(EventArg::from_lua_val(&val)?);
            }

            s.borrow_mut()
                .event_queue
                .push_event_with_priority(&name, event_args.clone(), priority);

            let cap_val = *cap_p.borrow();
            if cap_val > 0 {
                let mut buf = hist_p.borrow_mut();
                buf.push_back((name, event_args));
                while buf.len() > cap_val {
                    buf.pop_front();
                }
            }
            Ok(())
        })?,
    )?;

    lurek.set("event", tbl)?;
    Ok(())
}
