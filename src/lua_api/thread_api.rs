//! `lurek.thread` — Background threads and inter-thread channel communication.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

use crate::thread::channel::{channel_value_to_lua, lua_to_channel_value, Channel, LuaChannel};
use crate::thread::worker::LuaThread;

// -------------------------------------------------------------------------------
// LuaThreadHandle UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a background [`LuaThread`].
#[derive(Clone)]
pub struct LuaThreadHandle {
    inner: Arc<Mutex<LuaThread>>,
}

impl LuaUserData for LuaThreadHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Thread".to_string()));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Thread" || name == "Object")
        });

        // -- start --
        /// Launches the background thread, passing optional arguments via varargs.
        /// @param args : MultiValue
        /// @return nil
        methods.add_method("start", |_, this, args: LuaMultiValue| {
            let channel_args: Vec<_> = args
                .into_iter()
                .map(lua_to_channel_value)
                .collect::<LuaResult<Vec<_>>>()?;
            this.inner
                .lock()
                .unwrap()
                .start(channel_args)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });

        // -- wait --
        /// Blocks the calling thread until the background thread finishes.
        /// @return nil
        methods.add_method("wait", |_, this, ()| {
            this.inner.lock().unwrap().wait();
            Ok(())
        });

        // -- isRunning --
        /// Returns whether the thread is currently executing.
        /// @return boolean
        methods.add_method("isRunning", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_running())
        });

        // -- getError --
        /// Returns the error message if the thread failed, or nil.
        /// @return string?
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.thread` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
        Arc::new(Mutex::new(HashMap::new()));

    // -- newThread --
    /// Creates a new background thread from a Lua code string.
    /// @param code : string
    /// @return Thread
    let ch = named_channels.clone();
    tbl.set(
        "newThread",
        lua.create_function(move |_, code: String| {
            Ok(LuaThreadHandle {
                inner: Arc::new(Mutex::new(LuaThread::new(code, ch.clone()))),
            })
        })?,
    )?;

    // -- newChannel --
    /// Creates an unnamed thread-safe channel for inter-thread communication.
    /// @return Channel
    tbl.set(
        "newChannel",
        lua.create_function(|_, ()| Ok(LuaChannel { inner: Channel::new() }))?,
    )?;

    // -- getChannel --
    /// Gets or creates a named global channel shared across threads.
    /// @param name : string
    /// @return Channel
    let ch = named_channels.clone();
    tbl.set(
        "getChannel",
        lua.create_function(move |_, name: String| {
            let mut channels = ch.lock().unwrap();
            let channel = channels
                .entry(name.clone())
                .or_insert_with(|| Channel::named(name))
                .clone();
            Ok(LuaChannel { inner: channel })
        })?,
    )?;

    luna.set("thread", tbl)?;
    Ok(())
}

/// A synchronized message queue for cross-VM communication.
impl LuaUserData for LuaChannel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the type of the object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Channel".to_string()));
        /// Checks if the object is of the specified type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok("Channel" == name || ["Object"].contains(&name.as_str()))
        });

        /// Pushes a value to the channel.
        /// @param value : any
        /// @return integer
        methods.add_method("push", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            let id = this.inner.push(cv);
            Ok(id)
        });

        /// Retrieves and removes a value from the channel.
        /// @return string|number|boolean|table|nil
        methods.add_method("pop", |lua, this, ()| match this.inner.pop() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });

        /// Retrieves the value from the channel without removing it.
        /// @return string|number|boolean|table|nil
        methods.add_method("peek", |lua, this, ()| match this.inner.peek() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });

        /// Blocks until a value is available or the timeout expires, then removes and returns it.
        /// @param timeout : number?
        /// @return string|number|boolean|table|nil
        methods.add_method("demand", |lua, this, timeout: Option<f64>| {
            match this.inner.demand(timeout) {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });

        /// Returns the number of items in the channel.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.get_count()));

        /// Clears all items from the channel.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        /// Blocks until the channel has space, then adds the value.
        /// @param value : any
        /// @return nil
        methods.add_method("supply", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.supply(cv))
        });
    }
}
