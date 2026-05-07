//! `lurek.thread` - Background threads and inter-thread channel communication.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

use crate::thread::channel::{
    channel_value_to_lua, lua_to_channel_value, Channel, ChannelValue, LuaChannel,
};
use crate::thread::pool::ThreadPool;
use crate::thread::promise::Promise;
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
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LThread".to_string()));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LThread" || name == "Thread" || name == "Object")
        });

        // -- start --
        /// Launches the background thread, passing optional varargs.
        /// @param | ... | any | Values passed to the worker thread.
        /// @return | nil | No value is returned.
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
        /// @return | nil | No value is returned.
        methods.add_method("wait", |_, this, ()| {
            this.inner.lock().unwrap().wait();
            Ok(())
        });

        // -- isRunning --
        /// Returns whether the thread is currently executing.
        /// @return | boolean | True when the thread is running.
        methods.add_method("isRunning", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_running())
        });

        // -- getError --
        /// Returns the error message if the thread failed.
        /// @return | string | Error message string.
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
    }
}

// -------------------------------------------------------------------------------
// LuaThreadPool UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`ThreadPool`].
#[derive(Clone)]
pub struct LuaThreadPool {
    inner: Arc<Mutex<ThreadPool>>,
}

impl LuaUserData for LuaThreadPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LThreadPool".to_string()));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ThreadPool" || name == "Object")
        });

        // -- submit --
        /// Submits a value to the pool's input channel for processing by a worker.
        /// @param | value | any | Value to send to a worker.
        /// @return | nil | No value is returned.
        methods.add_method("submit", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            this.inner.lock().unwrap().submit(cv);
            Ok(())
        });

        // -- collect --
        /// Retrieves the next result from the pool's output channel.
        /// @return | table | Next result value.
        methods.add_method("collect", |lua, this, ()| {
            match this.inner.lock().unwrap().collect() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- size --
        /// Returns the number of workers in this pool.
        /// @return | integer | Worker count.
        methods.add_method("size", |_, this, ()| Ok(this.inner.lock().unwrap().size()));

        // -- join --
        /// Blocks until all workers in the pool have finished execution.
        /// @return | nil | No value is returned.
        methods.add_method("join", |_, this, ()| {
            this.inner.lock().unwrap().join();
            Ok(())
        });

        // -- getInputChannel --
        /// Returns the shared input channel.
        /// @return | LChannel | Shared input channel handle.
        methods.add_method("getInputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.input.clone(),
            })
        });

        // -- getOutputChannel --
        /// Returns the shared output channel.
        /// @return | LChannel | Shared output channel handle.
        methods.add_method("getOutputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.output.clone(),
            })
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPromise UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a one-shot [`Promise`].
#[derive(Clone)]
pub struct LuaPromise {
    inner: Arc<Mutex<Promise>>,
}

impl LuaUserData for LuaPromise {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LPromise".to_string()));

        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Promise" || name == "Object")
        });

        // -- isDone --
        /// Returns whether the promise has completed.
        /// @return | boolean | True when the promise has a result or an error.
        methods.add_method("isDone", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_done())
        });

        // -- result --
        /// Pops and returns the promise result.
        /// @return | table | Promise result value.
        methods.add_method("result", |lua, this, ()| {
            match this.inner.lock().unwrap().result() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getError --
        /// Returns the worker error string if the promise failed.
        /// @return | string | Error message string.
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.thread` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
        Arc::new(Mutex::new(HashMap::new()));

    // -- newThread --
    /// Creates a new background thread from a Lua code string.
    /// @param | code | string | Worker Lua source code.
    /// @return | LThread | New thread handle.
    let ch = named_channels.clone();
    // Auto-doc: Lua API binding.
    tbl.set("newThread", lua.create_function(move |_, code: String| {
            Ok(LuaThreadHandle {
                inner: Arc::new(Mutex::new(LuaThread::new(code, ch.clone()))),
            })
        })?,
    )?;

    // -- newChannel --
    /// Creates a new unnamed channel for inter-thread communication.
    /// @return | LChannel | New channel handle.
    tbl.set("newChannel", lua.create_function(|_, ()| {
            Ok(LuaChannel {
                inner: Channel::new(),
            })
        })?,
    )?;

    // -- getChannel --
    /// Gets or creates a named global channel shared across threads.
    /// @param | name | string | Channel name.
    /// @return | LChannel | Named channel handle.
    let ch = named_channels.clone();
    // Auto-doc: Lua API binding.
    tbl.set("getChannel", lua.create_function(move |_, name: String| {
            let mut channels = ch.lock().unwrap();
            let channel = channels
                .entry(name.clone())
                .or_insert_with(|| Channel::named(name))
                .clone();
            Ok(LuaChannel { inner: channel })
        })?,
    )?;

    // -- newPool --
    /// Creates a thread pool whose workers all run the same Lua code.
    /// @param | size | integer | Number of worker threads to spawn.
    /// @param | code | string | Worker Lua source code.
    /// @return | LThreadPool | New thread pool handle.
    tbl.set("newPool", lua.create_function(|_, (size, code): (usize, String)| {
            Ok(LuaThreadPool {
                inner: Arc::new(Mutex::new(ThreadPool::new(size, code))),
            })
        })?,
    )?;

    // -- async --
    /// Starts a one-shot background computation and returns a promise.
    /// @param | code | string | Worker Lua source code.
    /// @param | args | table | Argument values passed to the worker.
    /// @return | LPromise | New promise handle.
    tbl.set("async", lua.create_function(|_, (code, args): (String, LuaMultiValue)| {
            let channel_args = args
                .into_iter()
                .map(lua_to_channel_value)
                .collect::<LuaResult<Vec<ChannelValue>>>()?;
            Ok(LuaPromise {
                inner: Arc::new(Mutex::new(Promise::new(code, channel_args))),
            })
        })?,
    )?;

    lurek.set("thread", tbl)?;
    Ok(())
}

/// A synchronized message queue for cross-VM communication.
impl LuaUserData for LuaChannel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LChannel".to_string()));
        // -- typeOf --
        /// Returns whether this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChannel" || name == "Channel" || name == "Object")
        });

        // -- push --
        /// Pushes a value to the channel.
        /// @param | value | any | Value to enqueue.
        /// @return | integer | Message identifier.
        methods.add_method("push", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            let id = this.inner.push(cv);
            Ok(id)
        });

        // -- pop --
        /// Retrieves and removes a value from the channel.
        /// @return | table | Dequeued value.
        methods.add_method("pop", |lua, this, ()| match this.inner.pop() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });

        // -- peek --
        /// Retrieves the next value from the channel without removing it.
        /// @return | table | Next value.
        methods.add_method("peek", |lua, this, ()| match this.inner.peek() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });

        // -- demand --
        /// Waits for a value or until the timeout expires, then removes and returns it.
        /// @param | timeout | number? | Optional timeout in seconds.
        /// @return | table | Dequeued value.
        methods.add_method("demand", |lua, this, timeout: Option<f64>| {
            match this.inner.demand(timeout) {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getCount --
        /// Returns the number of items in the channel.
        /// @return | integer | Number of queued items.
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.get_count()));

        // -- clear --
        /// Clears all items from the channel.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- supply --
        /// Blocks until the channel has space, then adds the value.
        /// @param | value | any | Value to enqueue.
        /// @return | nil | No value is returned.
        methods.add_method("supply", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.supply(cv))
        });

        // -- pushTable --
        /// Serializes a Lua table and pushes it to the channel.
        /// @param | value | table | Lua table to serialize and enqueue.
        /// @return | integer | Message identifier.
        methods.add_method("pushTable", |_, this, value: LuaValue| {
            match &value {
                LuaValue::Table(_) => {}
                _ => {
                    return Err(LuaError::RuntimeError(
                        "pushTable: expected a table value".into(),
                    ))
                }
            }
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.push(cv))
        });

        // -- popTable --
        /// Pops a value from the channel expecting a table.
        /// @return | table | Dequeued table value.
        methods.add_method("popTable", |lua, this, ()| match this.inner.pop() {
            Some(cv @ ChannelValue::Table(_)) => channel_value_to_lua(lua, cv),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });

        // -- pushBytes --
        /// Pushes raw binary data (a Lua string treated as a byte array) to the channel.
        /// @param | data | string | Raw bytes stored in a Lua string.
        /// @return | integer | Message identifier.
        methods.add_method("pushBytes", |_, this, data: LuaString| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.push(ChannelValue::Bytes(bytes)))
        });

        // -- popBytes --
        /// Pops a bytes value from the channel and returns it as a Lua string.
        /// @return | string | Dequeued byte string.
        methods.add_method("popBytes", |lua, this, ()| match this.inner.pop() {
            Some(ChannelValue::Bytes(b)) => Ok(LuaValue::String(lua.create_string(&b)?)),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });
    }
}
