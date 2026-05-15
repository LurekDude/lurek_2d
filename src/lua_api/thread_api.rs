//! `lurek.thread` - Provides multi-threaded Lua worker VMs with typed channel messaging for parallel game logic execution.

use super::SharedState;
use crate::thread::channel::{
    channel_value_to_lua, lua_to_channel_value, Channel, ChannelValue, LuaChannel,
};
use crate::thread::pool::ThreadPool;
use crate::thread::promise::Promise;
use crate::thread::worker::{worker_capabilities, LuaThread};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::{Arc, Mutex};
#[derive(Clone)]
/// Lua-visible handle wrapping a single background worker VM that executes a Lua code string on a dedicated OS thread.
pub struct LuaThreadHandle {
    inner: Arc<Mutex<LuaThread>>,
}
impl LuaUserData for LuaThreadHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always returns `"LThread"`.
        methods.add_method("type", |_, _, ()| Ok("LThread".to_string()));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against (`"LThread"`, `"Thread"`, or `"Object"`).
        /// @return | boolean | `true` if the name matches one of the accepted type names.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LThread" || name == "Thread" || name == "Object")
        });
        // -- start --
        /// Launches the worker thread, executing the Lua code string supplied at creation time.
        /// @param | ... | any | Zero or more arguments forwarded to the worker as the `arg` table.
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
        /// Blocks the calling thread until the worker thread finishes execution.
        methods.add_method("wait", |_, this, ()| {
            this.inner.lock().unwrap().wait();
            Ok(())
        });
        // -- isRunning --
        /// Checks whether the worker thread is still executing.
        /// @return | boolean | `true` if the thread has been started and has not yet finished.
        methods.add_method("isRunning", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_running())
        });
        // -- getError --
        /// Returns the error message from the worker thread, if it terminated with an error.
        /// @return | string? | The error string, or `nil` if the thread completed successfully or is still running.
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
    }
}
#[derive(Clone)]
/// Lua-visible handle for a fixed-size pool of worker threads that process items from a shared input channel.
pub struct LuaThreadPool {
    inner: Arc<Mutex<ThreadPool>>,
}
impl LuaUserData for LuaThreadPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always returns `"LThreadPool"`.
        methods.add_method("type", |_, _, ()| Ok("LThreadPool".to_string()));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against (`"ThreadPool"` or `"Object"`).
        /// @return | boolean | `true` if the name matches one of the accepted type names.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ThreadPool" || name == "Object")
        });
        // -- submit --
        /// Pushes a value into the pool's input channel for processing by a worker thread.
        /// @param | value | any | The value to enqueue for processing.
        methods.add_method("submit", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            this.inner.lock().unwrap().submit(cv);
            Ok(())
        });
        // -- collect --
        /// Pops and returns the next result from the pool's output channel.
        /// @return | any | The next result value, or `nil` if the output channel is empty.
        methods.add_method("collect", |lua, this, ()| {
            match this.inner.lock().unwrap().collect() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- size --
        /// Returns the number of worker threads in the pool.
        /// @return | number | The pool's worker count.
        methods.add_method("size", |_, this, ()| Ok(this.inner.lock().unwrap().size()));
        // -- join --
        /// Blocks until all workers finish or the optional timeout elapses.
        /// @param | timeout | number? | Maximum seconds to wait. If omitted, waits indefinitely.
        /// @return | boolean | `true` if all workers finished, `false` if the timeout expired.
        methods.add_method("join", |_, this, timeout: Option<f64>| {
            let done = if let Some(secs) = timeout {
                this.inner.lock().unwrap().join_with_timeout(secs)
            } else {
                this.inner.lock().unwrap().join();
                true
            };
            Ok(done)
        });
        // -- getInputChannel --
        /// Returns the pool's shared input channel that feeds work items to worker threads.
        /// @return | LChannel | The input channel.
        methods.add_method("getInputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.input.clone(),
            })
        });
        // -- getOutputChannel --
        /// Returns the pool's shared output channel where worker threads place their results.
        /// @return | LChannel | The output channel.
        methods.add_method("getOutputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.output.clone(),
            })
        });
    }
}
#[derive(Clone)]
/// Lua-visible handle representing an asynchronous computation that will produce a single result value.
pub struct LuaPromise {
    inner: Arc<Mutex<Promise>>,
}
impl LuaUserData for LuaPromise {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always returns `"LPromise"`.
        methods.add_method("type", |_, _, ()| Ok("LPromise".to_string()));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against (`"Promise"` or `"Object"`).
        /// @return | boolean | `true` if the name matches one of the accepted type names.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Promise" || name == "Object")
        });
        // -- isDone --
        /// Checks whether the asynchronous computation has completed.
        /// @return | boolean | `true` if the promise has finished (either successfully or with an error).
        methods.add_method("isDone", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_done())
        });
        // -- result --
        /// Returns the result value of the completed promise.
        /// @return | any | The computed result, or `nil` if the promise is not yet done.
        methods.add_method("result", |lua, this, ()| {
            match this.inner.lock().unwrap().result() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- getError --
        /// Returns the error message from the promise, if it terminated with an error.
        /// @return | string? | The error string, or `nil` if the promise succeeded or is still running.
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
        // -- chain --
        /// Creates a new promise that runs the given code with the parent promise's result as its first argument.
        /// @param | code | string | Lua source code to execute in the chained worker thread.
        /// @param | ... | any | Additional arguments forwarded after the parent result.
        /// @return | LPromise | A new promise representing the chained computation.
        methods.add_method("chain", |_, this, (code, rest): (String, LuaMultiValue)| {
            let parent_result = {
                let guard = this.inner.lock().unwrap();
                if let Some(err) = guard.get_error() {
                    return Err(LuaError::RuntimeError(format!(
                        "Promise:chain failed; parent promise error: {err}"
                    )));
                }
                guard.result().ok_or_else(|| {
                    LuaError::RuntimeError(
                        "Promise:chain requires parent promise result; call after isDone() and before result()".to_string(),
                    )
                })?
            };
            let mut args = Vec::with_capacity(rest.len() + 1);
            args.push(parent_result);
            let mut tail = rest
                .into_iter()
                .map(lua_to_channel_value)
                .collect::<LuaResult<Vec<_>>>()?;
            args.append(&mut tail);
            Ok(LuaPromise {
                inner: Arc::new(Mutex::new(Promise::new(code, args))),
            })
        });
    }
}
/// Registers the `lurek.thread` module table, exposing thread creation, channels, pools, and async primitives to Lua.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
        Arc::new(Mutex::new(HashMap::new()));
    let ch = named_channels.clone();
    // -- newThread --
    /// Creates a new worker thread that will execute the given Lua code string when started.
    /// @param | code | string | Lua source code to run in the worker VM.
    /// @return | LThread | A thread handle that can be started, waited on, and inspected.
    tbl.set(
        "newThread",
        lua.create_function(move |_, code: String| {
            Ok(LuaThreadHandle {
                inner: Arc::new(Mutex::new(LuaThread::new(code, ch.clone()))),
            })
        })?,
    )?;
    // -- newChannel --
    /// Creates a new unbounded channel for sending typed values between threads.
    /// @return | LChannel | A new unbounded channel.
    tbl.set(
        "newChannel",
        lua.create_function(|_, ()| {
            Ok(LuaChannel {
                inner: Channel::new(),
            })
        })?,
    )?;
    // -- newBoundedChannel --
    /// Creates a new bounded channel with a fixed capacity, blocking pushes when full.
    /// @param | capacity | number | Maximum number of items the channel can hold.
    /// @return | LChannel | A new bounded channel.
    tbl.set(
        "newBoundedChannel",
        lua.create_function(|_, capacity: usize| {
            Ok(LuaChannel {
                inner: Channel::bounded(capacity),
            })
        })?,
    )?;
    let ch = named_channels.clone();
    // -- getChannel --
    /// Returns a named shared channel, creating it on first access. Repeated calls with the same name return the same channel.
    /// @param | name | string | Unique name identifying the shared channel.
    /// @return | LChannel | The named channel instance.
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
    // -- newPool --
    /// Creates a fixed-size thread pool where each worker runs the same Lua code and consumes items from a shared input channel.
    /// @param | size | number | Number of worker threads to spawn.
    /// @param | code | string | Lua source code each worker thread will execute.
    /// @return | LThreadPool | A pool handle for submitting work and collecting results.
    tbl.set(
        "newPool",
        lua.create_function(|_, (size, code): (usize, String)| {
            Ok(LuaThreadPool {
                inner: Arc::new(Mutex::new(ThreadPool::new(size, code))),
            })
        })?,
    )?;
    // -- async --
    /// Runs a Lua code string or dumped function asynchronously on a new worker thread, returning a promise for the result.
    /// @param | codeOrFunc | string|function | Lua source code or a dumpable Lua function to execute.
    /// @param | ... | any | Additional arguments forwarded to the worker.
    /// @return | LPromise | A promise that resolves to the worker's return value.
    tbl.set(
        "async",
        lua.create_function(|lua, args: LuaMultiValue| {
            if args.is_empty() {
                return Err(LuaError::RuntimeError(
                    "thread.async expects code string or function as first argument".to_string(),
                ));
            }
            let mut iter = args.into_iter();
            let first = iter.next().ok_or_else(|| {
                LuaError::RuntimeError("thread.async missing first argument".to_string())
            })?;
            let (code, mut channel_args): (String, Vec<ChannelValue>) = match first {
                LuaValue::String(s) => {
                    let code = s.to_str()?.to_string();
                    let tail = iter
                        .map(lua_to_channel_value)
                        .collect::<LuaResult<Vec<ChannelValue>>>()?;
                    (code, tail)
                }
                LuaValue::Function(f) => {
                    let string_tbl: LuaTable = lua.globals().get("string")?;
                    let dump_fn: LuaFunction = string_tbl.get("dump")?;
                    let dumped: LuaString = dump_fn.call(f)?;
                    let wrapper = r#"
                        local loader = loadstring or load
                        local unpack_fn = table.unpack or unpack
                        local fn = assert(loader(arg[1]))
                        local out = fn(unpack_fn(arg, 2))
                        lurek.thread.getChannel("__promise_result"):push(out)
                    "#
                    .to_string();
                    let mut packed = Vec::new();
                    packed.push(ChannelValue::Bytes(dumped.as_bytes().to_vec()));
                    for val in iter {
                        packed.push(lua_to_channel_value(val)?);
                    }
                    (wrapper, packed)
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "thread.async first argument must be string or function".to_string(),
                    ))
                }
            };
            Ok(LuaPromise {
                inner: Arc::new(Mutex::new(Promise::new(
                    code,
                    std::mem::take(&mut channel_args),
                ))),
            })
        })?,
    )?;
    // -- getWorkerCapabilities --
    /// Returns a list of capability names available inside worker VMs (e.g. which `lurek.*` modules are accessible).
    /// @return | table | An integer-indexed table of capability name strings.
    tbl.set(
        "getWorkerCapabilities",
        lua.create_function(|lua, ()| {
            let out = lua.create_table()?;
            for (idx, name) in worker_capabilities().iter().enumerate() {
                out.set((idx + 1) as i64, *name)?;
            }
            Ok(out)
        })?,
    )?;
    lurek.set("thread", tbl)?;
    Ok(())
}
impl LuaUserData for LuaChannel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always returns `"LChannel"`.
        methods.add_method("type", |_, _, ()| Ok("LChannel".to_string()));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against (`"LChannel"`, `"Channel"`, or `"Object"`).
        /// @return | boolean | `true` if the name matches one of the accepted type names.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChannel" || name == "Channel" || name == "Object")
        });
        // -- push --
        /// Pushes a value onto the channel. Blocks on bounded channels if the channel is full.
        /// @param | value | any | The value to send through the channel.
        /// @return | number | The message sequence ID assigned to this push.
        methods.add_method("push", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            let id = this.inner.push(cv);
            Ok(id)
        });
        // -- pop --
        /// Removes and returns the next value from the channel without blocking.
        /// @return | any | The next value, or `nil` if the channel is empty.
        methods.add_method("pop", |lua, this, ()| match this.inner.pop() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });
        // -- peek --
        /// Returns the next value from the channel without removing it.
        /// @return | any | The front value, or `nil` if the channel is empty.
        methods.add_method("peek", |lua, this, ()| match this.inner.peek() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });
        // -- demand --
        /// Blocks until a value is available on the channel or the optional timeout expires.
        /// @param | timeout | number? | Maximum seconds to wait. If omitted, waits indefinitely.
        /// @return | any | The received value, or `nil` if the timeout expired.
        methods.add_method("demand", |lua, this, timeout: Option<f64>| {
            match this.inner.demand(timeout) {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- getCount --
        /// Returns the number of values currently queued in the channel.
        /// @return | number | The current item count.
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.get_count()));
        // -- getCapacity --
        /// Returns the maximum capacity of a bounded channel, or `nil` for unbounded channels.
        /// @return | number? | The capacity limit, or `nil` if unbounded.
        methods.add_method("getCapacity", |_, this, ()| Ok(this.inner.capacity()));
        // -- isBounded --
        /// Checks whether this channel has a fixed capacity limit.
        /// @return | boolean | `true` if the channel is bounded.
        methods.add_method("isBounded", |_, this, ()| Ok(this.inner.is_bounded()));
        // -- tryPush --
        /// Attempts to push a value onto a bounded channel without blocking.
        /// @param | value | any | The value to send.
        /// @return | boolean | `true` if the value was enqueued, `false` if the channel is full.
        methods.add_method("tryPush", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.try_push(cv))
        });
        // -- clear --
        /// Removes all pending values from the channel.
        methods.add_method("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- supply --
        /// Pushes a value and blocks until a consumer pops it (synchronous handoff).
        /// @param | value | any | The value to hand off to a consumer.
        /// @return | boolean | `true` when the value has been consumed.
        methods.add_method("supply", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.supply(cv))
        });
        // -- pushTable --
        /// Pushes a table value onto the channel, raising an error if the value is not a table.
        /// @param | value | table | The table to send through the channel.
        /// @return | number | The message sequence ID assigned to this push.
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
        /// Pops the next value from the channel only if it is a table, discarding non-table values.
        /// @return | table? | The table value, or `nil` if the channel is empty or the front value is not a table.
        methods.add_method("popTable", |lua, this, ()| match this.inner.pop() {
            Some(cv @ ChannelValue::Table(_)) => channel_value_to_lua(lua, cv),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });
        // -- pushBytes --
        /// Pushes raw binary data onto the channel as a byte blob.
        /// @param | data | string | The binary data to send (Lua strings can hold arbitrary bytes).
        /// @return | number | The message sequence ID assigned to this push.
        methods.add_method("pushBytes", |_, this, data: LuaString| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.push(ChannelValue::Bytes(bytes)))
        });
        // -- popBytes --
        /// Pops the next value from the channel only if it is a byte blob, discarding non-bytes values.
        /// @return | string? | The binary data as a Lua string, or `nil` if the channel is empty or the front value is not bytes.
        methods.add_method("popBytes", |lua, this, ()| match this.inner.pop() {
            Some(ChannelValue::Bytes(b)) => Ok(LuaValue::String(lua.create_string(&b)?)),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });
    }
}
