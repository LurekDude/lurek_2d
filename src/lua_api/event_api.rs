//! `lurek.event` -- Event queue and signal bindings for quit/restart requests, polling, waiting, immediate and deferred event pushes, priority delivery, optional history capture, and Lua callback signal dispatch.

use super::SharedState;
use crate::event::{event_arg_to_lua_value, event_to_lua_multi, EventArg, EventPriority, Signal};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet, VecDeque};
use std::rc::Rc;
#[derive(Clone)]
/// Lua-side signal object storing subscriptions and Lua callback registry keys.
pub struct LuaSignal {
    /// Core signal subscription index keyed by event name and wildcard pattern.
    inner: Rc<RefCell<Signal>>,
    /// Lua callback registry keys by signal handle.
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    /// Handles removed automatically after the next matching signal emission.
    once_handles: Rc<RefCell<HashSet<u64>>>,
    /// Optional Lua filter callbacks by signal handle.
    filter_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
/// Provides Lua methods for connecting, emitting, filtering, and removing signal callbacks.
impl LuaUserData for LuaSignal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- register --
        /// Registers a callback for an exact signal event name.
        /// @param | name | string | Signal event name.
        /// @param | callback | function | Lua function invoked with emitted signal arguments.
        /// @return | integer | Subscription handle used for removal.
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
        /// Emits a signal event and invokes matching callbacks with the remaining arguments.
        /// @param | name | string | Signal event name to emit.
        /// @param | ... | any | Additional arguments passed to matching callbacks.
        /// @return | nil | No value is returned.
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
        /// Removes a signal callback by subscription handle.
        /// @param | handle | integer | Subscription handle returned by registration.
        /// @return | boolean | True when a callback was removed.
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
        /// Removes all callbacks registered for one exact signal event name.
        /// @param | name | string | Signal event name to clear.
        /// @return | integer | Number of callbacks removed.
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
        /// Removes every callback from this signal object.
        /// @return | integer | Number of callbacks removed.
        methods.add_method("clearAll", |lua, this, ()| {
            let count = this.inner.borrow_mut().clear_all();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(count)
        });
        // -- getCount --
        /// Returns the callback count for one exact signal event name.
        /// @param | name | string | Signal event name.
        /// @return | integer | Number of callbacks registered for the event.
        methods.add_method("getCount", |_, this, name: String| {
            Ok(this.inner.borrow().get_count(&name))
        });
        // -- getTotalCount --
        /// Returns the total callback count across all signal event names.
        /// @return | integer | Total callback count.
        methods.add_method("getTotalCount", |_, this, ()| {
            Ok(this.inner.borrow().get_total_count())
        });
        // -- once --
        /// Registers a callback that is removed after its next matching emission.
        /// @param | name | string | Signal event name.
        /// @param | callback | function | Lua function invoked once with emitted signal arguments.
        /// @return | integer | Subscription handle used for removal before it fires.
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
        /// Registers a callback that runs only when a filter callback returns true.
        /// @param | name | string | Signal event name.
        /// @param | callback | function | Lua function invoked after the filter accepts the signal.
        /// @param | filter | function | Lua predicate called with emitted arguments.
        /// @return | integer | Subscription handle used for removal.
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
        /// Registers a callback for an exact name or wildcard signal pattern.
        /// @param | name | string | Exact signal event name or wildcard pattern.
        /// @param | func | function | Lua function invoked with emitted signal arguments.
        /// @return | integer | Subscription handle used for removal.
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
        /// Returns the Lua-visible type name for this signal handle.
        /// @return | string | The string `LSignal`.
        methods.add_method("type", |_, _, ()| Ok("LSignal"));
        // -- typeOf --
        /// Returns whether this signal handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LSignal`, `Signal`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSignal" || name == "Signal" || name == "Object")
        });
    }
}
#[allow(clippy::type_complexity)]
/// Registers `lurek.event` queue, process-control, deferred, history, and signal helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    /// Parses a Lua string into an event priority value.
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
    let s = state.clone();
    // -- exit --
    /// Requests engine shutdown with an optional process exit code.
    /// @param | code? | integer | Optional exit code, defaulting to 0.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, code: Option<i32>| {
            let mut st = s.borrow_mut();
            st.quit_requested = true;
            st.exit_code = code.unwrap_or(0);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- poll --
    /// Creates a polling function that returns the next queued event each time it is called.
    /// @return | function | Poll function returning event values, or no values when the queue is empty.
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
    let s = state.clone();
    // -- clear --
    /// Clears all pending events from the shared event queue.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            s.borrow_mut().event_queue.clear();
            Ok(())
        })?,
    )?;
    // -- newSignal --
    /// Creates an isolated signal dispatcher for Lua callbacks.
    /// @return | LSignal | New signal handle.
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
    let s = state.clone();
    // -- pump --
    /// Pumps the shared event queue without removing events for Lua.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            s.borrow().event_queue.pump();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- wait --
    /// Waits for the next queued event and returns success, name, and argument table.
    /// @param | timeout? | number | Optional timeout in seconds.
    /// @return | boolean | True when an event was received before timeout.
    /// @return | string | Event name, or an empty string on timeout.
    /// @return | table | Array table of event arguments.
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
    let s = state.clone();
    // -- restart --
    /// Requests a full engine restart cycle from the runtime.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            s.borrow_mut().restart_requested = true;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- quit --
    /// Requests engine shutdown with exit code zero.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.quit_requested = true;
            st.exit_code = 0;
            Ok(())
        })?,
    )?;
    let deferred_queue: Rc<RefCell<Vec<(String, Vec<EventArg>, EventPriority)>>> =
        Rc::new(RefCell::new(Vec::new()));
    let deferred = deferred_queue.clone();
    // -- pushDeferred --
    /// Adds a normal-priority event to the deferred buffer instead of the live queue.
    /// @param | name | string | Event name to enqueue later.
    /// @param | ... | any | Additional event arguments stored with the event.
    /// @return | nil | No value is returned.
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
    let deferred = deferred_queue.clone();
    // -- pushDeferredPriority --
    /// Adds an event with explicit priority to the deferred buffer.
    /// @param | name | string | Event name to enqueue later.
    /// @param | priority | string | Priority string `high` or `normal`.
    /// @param | ... | any | Additional event arguments stored with the event.
    /// @return | nil | No value is returned.
    tbl.set(
        "pushDeferredPriority",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let name: String =
                match iter.next() {
                    Some(LuaValue::String(s)) => s
                        .to_str()
                        .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                        .to_string(),
                    _ => return Err(LuaError::RuntimeError(
                        "event.pushDeferredPriority requires a string event name as first argument"
                            .into(),
                    )),
                };
            let priority = match iter.next() {
                Some(value) => parse_priority(&value)?,
                None => {
                    return Err(LuaError::RuntimeError(
                        "event.pushDeferredPriority requires a priority as second argument".into(),
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
    let deferred = deferred_queue.clone();
    let s = state.clone();
    // -- flushDeferred --
    /// Moves all deferred events into the shared event queue and clears the deferred buffer.
    /// @return | integer | Number of events flushed.
    tbl.set(
        "flushDeferred",
        lua.create_function(move |_, ()| {
            let mut buf = deferred.borrow_mut();
            let count = buf.len() as u32;
            let mut st = s.borrow_mut();
            for (name, args, priority) in buf.drain(..) {
                st.event_queue
                    .push_event_with_priority(&name, args, priority);
            }
            Ok(count)
        })?,
    )?;
    let history_buf: Rc<RefCell<VecDeque<(String, Vec<EventArg>)>>> =
        Rc::new(RefCell::new(VecDeque::new()));
    let history_cap: Rc<RefCell<usize>> = Rc::new(RefCell::new(0));
    let cap = history_cap.clone();
    let hist = history_buf.clone();
    // -- enableHistory --
    /// Enables event push history with a maximum retained capacity.
    /// @param | capacity | integer | Maximum number of pushed events to keep; zero disables retention.
    /// @return | nil | No value is returned.
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
    let hist = history_buf.clone();
    // -- getHistory --
    /// Returns retained pushed event history entries.
    /// @return | table | Array table of entries with `name` and `args` fields.
    tbl.set(
        "getHistory",
        lua.create_function(move |lua, ()| {
            let buf = hist.borrow();
            let out = lua.create_table()?;
            for (i, (name, args)) in buf.iter().enumerate() {
                let entry = lua.create_table()?;
                /// Performs the 'name' operation.
                /// @return | nil | No value is returned.
                entry.set("name", name.clone())?;
                let args_tbl = lua.create_table()?;
                for (j, arg) in args.iter().enumerate() {
                    let v = event_arg_to_lua_value(lua, arg)?;
                    args_tbl.set(j + 1, v)?;
                }
                /// Performs the 'args' operation.
                /// @return | nil | No value is returned.
                entry.set("args", args_tbl)?;
                out.set(i + 1, entry)?;
            }
            Ok(out)
        })?,
    )?;
    let hist_c = history_buf.clone();
    // -- clearHistory --
    /// Clears retained pushed event history.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            hist_c.borrow_mut().clear();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    let hist_p = history_buf.clone();
    let cap_p = history_cap.clone();
    // -- push --
    /// Pushes a normal-priority event into the shared event queue and optional history.
    /// @param | name | string | Event name.
    /// @param | ... | any | Additional event arguments.
    /// @return | nil | No value is returned.
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
    let s = state.clone();
    let hist_p = history_buf.clone();
    let cap_p = history_cap.clone();
    // -- pushPriority --
    /// Pushes an event with explicit priority into the shared event queue and optional history.
    /// @param | name | string | Event name.
    /// @param | priority | string | Priority string `high` or `normal`.
    /// @param | ... | any | Additional event arguments.
    /// @return | nil | No value is returned.
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
                        "event.pushPriority requires a string event name as first argument".into(),
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
            s.borrow_mut().event_queue.push_event_with_priority(
                &name,
                event_args.clone(),
                priority,
            );
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
    /// Performs the 'event' operation.
    /// @return | nil | No value is returned.
    lurek.set("event", tbl)?;
    Ok(())
}
