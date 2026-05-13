use crate::log_msg;
use crate::runtime::log_messages::{TH01_WORKER_INIT, TH02_WORKER_START, TH04_WORKER_ERROR};
use crate::thread::channel::{channel_value_to_lua, Channel, ChannelValue, LuaChannel};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};
#[derive(Debug, Clone, PartialEq)]
pub enum ThreadState {
    Pending,
    Running,
    Completed,
    Error(String),
}
pub struct LuaThread {
    code: String,
    state: Arc<Mutex<ThreadState>>,
    handle: Option<thread::JoinHandle<()>>,
    channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>,
}
impl LuaThread {
    pub fn new(code: String, channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>) -> Self {
        log_msg!(debug, TH01_WORKER_INIT);
        Self {
            code,
            state: Arc::new(Mutex::new(ThreadState::Pending)),
            handle: None,
            channels,
        }
    }
    pub fn start(&mut self, args: Vec<ChannelValue>) -> Result<(), String> {
        if *self.state.lock().unwrap() == ThreadState::Running {
            log_msg!(error, TH04_WORKER_ERROR, "already running");
            return Err("Thread is already running".into());
        }
        let code = self.code.clone();
        let state = self.state.clone();
        let channels = self.channels.clone();
        *state.lock().unwrap() = ThreadState::Running;
        log_msg!(info, TH02_WORKER_START);
        let handle = thread::spawn(move || {
            let lua = mlua::Lua::new();
            if let Err(e) = register_thread_safe_modules(&lua, &channels, &args) {
                *state.lock().unwrap() = ThreadState::Error(e.to_string());
                return;
            }
            match lua.load(&code).exec() {
                Ok(()) => {
                    *state.lock().unwrap() = ThreadState::Completed;
                }
                Err(e) => {
                    *state.lock().unwrap() = ThreadState::Error(e.to_string());
                }
            }
        });
        self.handle = Some(handle);
        Ok(())
    }
    pub fn wait(&mut self) {
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }
    pub fn wait_timeout(&mut self, timeout_secs: f64) -> bool {
        if self.handle.is_none() {
            return true;
        }
        let timeout = Duration::from_secs_f64(timeout_secs.max(0.0));
        let deadline = Instant::now() + timeout;
        loop {
            let finished = self
                .handle
                .as_ref()
                .map(|h| h.is_finished())
                .unwrap_or(true);
            if finished {
                if let Some(handle) = self.handle.take() {
                    let _ = handle.join();
                }
                return true;
            }
            if Instant::now() >= deadline {
                return false;
            }
            thread::sleep(Duration::from_millis(1));
        }
    }
    pub fn is_running(&self) -> bool {
        *self.state.lock().unwrap() == ThreadState::Running
    }
    pub fn get_error(&self) -> Option<String> {
        match &*self.state.lock().unwrap() {
            ThreadState::Error(e) => Some(e.clone()),
            _ => None,
        }
    }
}
pub fn worker_capabilities() -> &'static [&'static str] {
    &[
        "lurek.thread.getChannel",
        "lurek.fs.read",
        "arg",
        "package.path",
    ]
}
fn register_thread_safe_modules(
    lua: &mlua::Lua,
    channels: &Arc<Mutex<HashMap<String, Arc<Channel>>>>,
    args: &[ChannelValue],
) -> mlua::Result<()> {
    let lurek = lua.create_table()?;
    let thread_table = lua.create_table()?;
    let channels_clone = channels.clone();
    thread_table.set(
        "getChannel",
        lua.create_function(move |_, name: String| {
            let channels = channels_clone.lock().unwrap();
            match channels.get(&name) {
                Some(ch) => Ok(LuaChannel { inner: ch.clone() }),
                None => Err(mlua::Error::RuntimeError(format!(
                    "Channel '{}' not found",
                    name
                ))),
            }
        })?,
    )?;
    lurek.set("thread", thread_table)?;
    let fs_table = lua.create_table()?;
    fs_table.set(
        "read",
        lua.create_function(|lua_ctx, path: String| {
            if path.contains("..") {
                return Err(mlua::Error::RuntimeError(
                    "lurek.filesystem.read: path traversal not allowed".to_string(),
                ));
            }
            match std::fs::read_to_string(&path) {
                Ok(content) => Ok(mlua::Value::String(lua_ctx.create_string(&content)?)),
                Err(e) => Err(mlua::Error::RuntimeError(format!("fs.read: {}", e))),
            }
        })?,
    )?;
    lurek.set("fs", fs_table)?;
    lua.globals().set("lurek", lurek)?;
    if let Ok(package) = lua.globals().get::<_, mlua::Table>("package") {
        let current: String = package.get("path").unwrap_or_default();
        let new_path = if current.is_empty() {
            "./?.lua;./?/init.lua".to_string()
        } else {
            format!("{}:./?.lua:./?.lua/init.lua", current)
        };
        let _ = package.set("path", new_path);
    }
    let arg_table = lua.create_table()?;
    for (i, val) in args.iter().enumerate() {
        let lua_val = channel_value_to_lua(lua, val.clone())?;
        arg_table.set(i + 1, lua_val)?;
    }
    lua.globals().set("arg", arg_table)?;
    Ok(())
}
