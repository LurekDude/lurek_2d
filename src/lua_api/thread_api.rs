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
pub struct LuaThreadHandle {
    inner: Arc<Mutex<LuaThread>>,
}
impl LuaUserData for LuaThreadHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("type", |_, _, ()| Ok("LThread".to_string()));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LThread" || name == "Thread" || name == "Object")
        });
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
        methods.add_method("wait", |_, this, ()| {
            this.inner.lock().unwrap().wait();
            Ok(())
        });
        methods.add_method("isRunning", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_running())
        });
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
    }
}
#[derive(Clone)]
pub struct LuaThreadPool {
    inner: Arc<Mutex<ThreadPool>>,
}
impl LuaUserData for LuaThreadPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("type", |_, _, ()| Ok("LThreadPool".to_string()));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ThreadPool" || name == "Object")
        });
        methods.add_method("submit", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            this.inner.lock().unwrap().submit(cv);
            Ok(())
        });
        methods.add_method("collect", |lua, this, ()| {
            match this.inner.lock().unwrap().collect() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("size", |_, this, ()| Ok(this.inner.lock().unwrap().size()));
        methods.add_method("join", |_, this, timeout: Option<f64>| {
            let done = if let Some(secs) = timeout {
                this.inner.lock().unwrap().join_with_timeout(secs)
            } else {
                this.inner.lock().unwrap().join();
                true
            };
            Ok(done)
        });
        methods.add_method("getInputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.input.clone(),
            })
        });
        methods.add_method("getOutputChannel", |_, this, ()| {
            let pool = this.inner.lock().unwrap();
            Ok(LuaChannel {
                inner: pool.output.clone(),
            })
        });
    }
}
#[derive(Clone)]
pub struct LuaPromise {
    inner: Arc<Mutex<Promise>>,
}
impl LuaUserData for LuaPromise {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("type", |_, _, ()| Ok("LPromise".to_string()));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Promise" || name == "Object")
        });
        methods.add_method("isDone", |_, this, ()| {
            Ok(this.inner.lock().unwrap().is_done())
        });
        methods.add_method("result", |lua, this, ()| {
            match this.inner.lock().unwrap().result() {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.lock().unwrap().get_error())
        });
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
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
        Arc::new(Mutex::new(HashMap::new()));
    let ch = named_channels.clone();
    tbl.set(
        "newThread",
        lua.create_function(move |_, code: String| {
            Ok(LuaThreadHandle {
                inner: Arc::new(Mutex::new(LuaThread::new(code, ch.clone()))),
            })
        })?,
    )?;
    tbl.set(
        "newChannel",
        lua.create_function(|_, ()| {
            Ok(LuaChannel {
                inner: Channel::new(),
            })
        })?,
    )?;
    tbl.set(
        "newBoundedChannel",
        lua.create_function(|_, capacity: usize| {
            Ok(LuaChannel {
                inner: Channel::bounded(capacity),
            })
        })?,
    )?;
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
    tbl.set(
        "newPool",
        lua.create_function(|_, (size, code): (usize, String)| {
            Ok(LuaThreadPool {
                inner: Arc::new(Mutex::new(ThreadPool::new(size, code))),
            })
        })?,
    )?;
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
        methods.add_method("type", |_, _, ()| Ok("LChannel".to_string()));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LChannel" || name == "Channel" || name == "Object")
        });
        methods.add_method("push", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            let id = this.inner.push(cv);
            Ok(id)
        });
        methods.add_method("pop", |lua, this, ()| match this.inner.pop() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("peek", |lua, this, ()| match this.inner.peek() {
            Some(cv) => channel_value_to_lua(lua, cv),
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("demand", |lua, this, timeout: Option<f64>| {
            match this.inner.demand(timeout) {
                Some(cv) => channel_value_to_lua(lua, cv),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.get_count()));
        methods.add_method("getCapacity", |_, this, ()| Ok(this.inner.capacity()));
        methods.add_method("isBounded", |_, this, ()| Ok(this.inner.is_bounded()));
        methods.add_method("tryPush", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.try_push(cv))
        });
        methods.add_method("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("supply", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.supply(cv))
        });
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
        methods.add_method("popTable", |lua, this, ()| match this.inner.pop() {
            Some(cv @ ChannelValue::Table(_)) => channel_value_to_lua(lua, cv),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("pushBytes", |_, this, data: LuaString| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.push(ChannelValue::Bytes(bytes)))
        });
        methods.add_method("popBytes", |lua, this, ()| match this.inner.pop() {
            Some(ChannelValue::Bytes(b)) => Ok(LuaValue::String(lua.create_string(&b)?)),
            Some(_) => Ok(LuaValue::Nil),
            None => Ok(LuaValue::Nil),
        });
    }
}
