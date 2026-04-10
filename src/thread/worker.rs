//! Background Lua thread with independent VM.
//!
//! Each `LuaThread` spawns an OS thread running its own `mlua::Lua` instance.
//! Communication with the main thread happens exclusively through `Channel`
//! objects — no Lua state is shared across threads.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::thread;

use crate::runtime::log_messages::{TH01_WORKER_INIT, TH02_WORKER_START, TH04_WORKER_ERROR};
use crate::log_msg;
use crate::thread::channel::{channel_value_to_lua, Channel, ChannelValue, LuaChannel};

/// Execution state of a background Lua thread.
///
/// # Variants
/// - `Pending` — Pending variant.
/// - `Running` — Running variant.
/// - `Completed` — Completed variant.
/// - `Error` — Error variant.
#[derive(Debug, Clone, PartialEq)]
pub enum ThreadState {
    /// Created but not yet started.
    Pending,
    /// Currently executing Lua code.
    Running,
    /// Finished successfully.
    Completed,
    /// Finished with an error message.
    Error(String),
}

/// A background Lua thread running its own VM.
///
/// Created via `lurek.thread.newThread(code)`. Call `start()` to spawn the
/// OS thread and `wait()` to block until completion. Errors are captured
/// in `ThreadState::Error` and retrievable via `get_error()`.
///
/// # Fields
/// - `code` — `String`.
/// - `state` — `Arc<Mutex<ThreadState>>`.
/// - `handle` — `Option<thread::JoinHandle<()>>`.
/// - `channels` — `Arc<Mutex<HashMap<String`.
pub struct LuaThread {
    /// The Lua source code to execute.
    code: String,
    /// Thread state shared with the spawned OS thread.
    state: Arc<Mutex<ThreadState>>,
    /// Join handle for the OS thread (`None` before start or after wait).
    handle: Option<thread::JoinHandle<()>>,
    /// Named channels available to this thread.
    channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>,
}

impl LuaThread {
    /// Create a new thread that will execute the given Lua code.
    ///
    /// # Parameters
    /// - `code` — `String`.
    /// - `channels` — `Arc<Mutex<HashMap<String, Arc<Channel>>>>`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// The thread is created in `Pending` state and does not start until
    /// `start()` is called.
    pub fn new(code: String, channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>) -> Self {
        log_msg!(debug, TH01_WORKER_INIT);
        Self {
            code,
            state: Arc::new(Mutex::new(ThreadState::Pending)),
            handle: None,
            channels,
        }
    }

    /// Start the thread, spawning a new OS thread with its own Lua VM.
    ///
    /// # Parameters
    /// - `args` — `Vec<ChannelValue>`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    ///
    /// Arguments are serialized as `ChannelValue` and made available
    /// to the Lua code via the `arg` global table.
    ///
    /// Returns an error if the thread is already running.
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

    /// Block until the thread finishes execution.
    ///
    /// If the thread has not been started or has already been waited on,
    /// this is a no-op.
    pub fn wait(&mut self) {
        if let Some(handle) = self.handle.take() {
            let _ = handle.join();
        }
    }

    /// Check whether the thread is currently running.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_running(&self) -> bool {
        *self.state.lock().unwrap() == ThreadState::Running
    }

    /// Get the error message if the thread terminated with an error.
    ///
    /// # Returns
    /// `Option<String>`.
    ///
    /// Returns `None` if the thread is still running, pending, or completed
    /// successfully.
    pub fn get_error(&self) -> Option<String> {
        match &*self.state.lock().unwrap() {
            ThreadState::Error(e) => Some(e.clone()),
            _ => None,
        }
    }
}

/// Register only thread-safe modules in a worker Lua VM.
///
/// Worker threads get:
/// - `lurek.thread.getChannel(name)` — access to named channels
/// - `arg` — table of arguments passed to `thread:start(...)`
///
/// Worker threads do NOT get: `lurek.gfx`, `lurek.audio`, `lurek.window`,
/// `lurek.input`, `lurek.physics`, `lurek.particles`, or any module that
/// touches `SharedState`.
fn register_thread_safe_modules(
    lua: &mlua::Lua,
    channels: &Arc<Mutex<HashMap<String, Arc<Channel>>>>,
    args: &[ChannelValue],
) -> mlua::Result<()> {
    let luna = lua.create_table()?;

    // lurek.thread.getChannel(name)
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
    luna.set("thread", thread_table)?;

    lua.globals().set("lurek", luna)?;

    // Set up arg table from passed arguments
    let arg_table = lua.create_table()?;
    for (i, val) in args.iter().enumerate() {
        let lua_val = channel_value_to_lua(lua, val.clone())?;
        arg_table.set(i + 1, lua_val)?;
    }
    lua.globals().set("arg", arg_table)?;

    Ok(())
}
