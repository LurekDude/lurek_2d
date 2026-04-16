//! `lurek.signal` — Event queue polling and pub-sub signal dispatching.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet, VecDeque};
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
    /// Handles that auto-remove after their first fire.
    once_handles: Rc<RefCell<HashSet<u64>>>,
    /// Optional filter predicate stored per-handle; skips callback if it returns false.
    filter_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
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
        /// Filter predicates (from `registerWithFilter`) are evaluated first; callbacks
        /// registered with `once` are automatically removed after firing.
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

        // -- once --
        /// Registers a one-shot callback that fires at most once then auto-removes itself.
        /// @param name : string
        /// @param callback : function
        /// @return integer
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
        /// Registers a callback with a filter predicate. The callback only fires if the
        /// filter function returns true when called with the same arguments as emit.
        /// @param name : string
        /// @param callback : function
        /// @param filter : function
        /// @return integer
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
        /// Subscribes to an event name or wildcard pattern. When the pattern contains
        /// `*` or `?`, uses glob matching against all emitted event names. Otherwise
        /// behaves identically to `register`. Returns a numeric handle for later removal.
        ///
        /// @param name : string   event name or glob pattern (e.g. "damage.*")
        /// @param func : function callback invoked with (...) args from emit
        /// @return nil
        /// integer        handle for later `remove`
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
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
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

    // -- poll --
    /// Returns an iterator function that pops events from the queue.
    /// @return function
    let s = state.clone();
    tbl.set(
        "poll",
        lua.create_function(move |lua, ()| {
            let s2 = s.clone();
            lua.create_function(
                move |lua, ()| match s2.borrow_mut().event_queue.poll() {
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
                once_handles: Rc::new(RefCell::new(HashSet::new())),
                filter_fns: Rc::new(RefCell::new(HashMap::new())),
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

    // Deferred event queue — events pushed via pushDeferred are batched and
    // only dispatched to the main queue when flushDeferred is called.
    let deferred_queue: Rc<RefCell<Vec<(String, Vec<EventArg>)>>> =
        Rc::new(RefCell::new(Vec::new()));

    // -- pushDeferred --
    /// Pushes a named event to the deferred buffer; it will not reach the main queue
    /// until `flushDeferred()` is called.
    /// @param name : string
    /// @return nil
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
            deferred.borrow_mut().push((name, event_args));
            Ok(())
        })?,
    )?;

    // -- flushDeferred --
    /// Moves all buffered deferred events into the main event queue and clears the buffer.
    /// integer  number of events flushed
    let deferred = deferred_queue.clone();
    let s = state.clone();
    /// @return table|nil
    tbl.set(
        "flushDeferred",
        lua.create_function(move |_, ()| {
            let mut buf = deferred.borrow_mut();
            let count = buf.len() as u32;
            let mut st = s.borrow_mut();
            for (name, args) in buf.drain(..) {
                st.event_queue.push_event(&name, args);
            }
            Ok(count)
        })?,
    )?;

    // History ring-buffer — stores the last N emitted events when history is enabled.
    let history_buf: Rc<RefCell<VecDeque<(String, Vec<EventArg>)>>> =
        Rc::new(RefCell::new(VecDeque::new()));
    let history_cap: Rc<RefCell<usize>> = Rc::new(RefCell::new(0));

    // -- enableHistory --
    /// Enables event history recording, keeping the last `capacity` pushed events.
    /// Pass 0 to disable.
    /// @param capacity : integer
    /// @return nil
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
    /// Returns an array of recent events as `{name, args}` tables.
    /// @return table
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
                    let v = match arg {
                        EventArg::Nil => LuaValue::Nil,
                        EventArg::Bool(b) => LuaValue::Boolean(*b),
                        EventArg::Int(n) => LuaValue::Integer(*n),
                        EventArg::Float(f) => LuaValue::Number(*f),
                        EventArg::String(s) => lua.create_string(s)?.into(),
                    };
                    args_tbl.set(j + 1, v)?;
                }
                entry.set("args", args_tbl)?;
                out.set(i + 1, entry)?;
            }
            Ok(out)
        })?,
    )?;

    // -- clearHistory --
    /// Clears all recorded event history.
    /// @return nil
    let hist_c = history_buf.clone();
    tbl.set(
        "clearHistory",
        lua.create_function(move |_, ()| {
            hist_c.borrow_mut().clear();
            Ok(())
        })?,
    )?;

    // -- push --
    /// Pushes a custom event onto the event queue. When history is enabled via
    /// `enableHistory`, the event is also appended to the history ring.
    /// @param name : string
    /// @return nil
    let s = state.clone();
    let hist_p = history_buf;
    let cap_p = history_cap;
    /// Adds an event item to the end of the event queue for processing.
    ///
    /// @param args : MultiValue
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
            s.borrow_mut().event_queue.push_event(&name, event_args.clone());
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

    luna.set("signal", tbl)?;
    Ok(())
}
