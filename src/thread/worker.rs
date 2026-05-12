//! Background Lua thread with independent VM.
//!
//! Each [`LuaThread`] spawns an OS thread running its own `mlua::Lua` instance.
//! Communication with the main thread happens exclusively through [`Channel`]
//! objects â€” no Lua state is shared across threads (design constraint **B-04**).
//!
//! ## Worker sandbox
//! Workers receive a minimal `lurek.*` API surface: `lurek.thread.getChannel(name)`,
//! `lurek.filesystem.read(path)` (read-only, no `..` traversal), and the `arg` global table.
//! Graphics, audio, window, input, physics, and any module touching `SharedState`
//! are deliberately excluded.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

use crate::log_msg;
use crate::runtime::log_messages::{TH01_WORKER_INIT, TH02_WORKER_START, TH04_WORKER_ERROR};
use crate::thread::channel::{channel_value_to_lua, Channel, ChannelValue, LuaChannel};

/// Execution state of a background Lua thread.
///
/// # Variants
/// - `Pending` â€” Pending variant.
/// - `Running` â€” Running variant.
/// - `Completed` â€” Completed variant.
/// - `Error` â€” Error variant.
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
/// - `code` â€” `String`.
/// - `state` â€” `Arc<Mutex<ThreadState>>`.
/// - `handle` â€” `Option<thread::JoinHandle<()>>`.
/// - `channels` â€” `Arc<Mutex<HashMap<String`.
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
    /// - `code` â€” `String`.
    /// - `channels` â€” `Arc<Mutex<HashMap<String, Arc<Channel>>>>`.
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
    /// - `args` â€” `Vec<ChannelValue>`.
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
            // Each worker gets a fresh Lua VM â€” no state shared with main thread.
            let lua = mlua::Lua::new();

            // Register the sandboxed subset of lurek.* API (channel access, fs.read, arg table).
            if let Err(e) = register_thread_safe_modules(&lua, &channels, &args) {
                *state.lock().unwrap() = ThreadState::Error(e.to_string());
                return;
            }

            // Execute the user-provided Lua code; capture panics as Error state.
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

    /// Waits up to `timeout_secs` for the worker to finish.
    ///
    /// Returns `true` when the worker finished during the timeout window.
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

/// Returns the worker-safe `lurek.*` capability list available inside worker VMs.
pub fn worker_capabilities() -> &'static [&'static str] {
    &[
        "lurek.thread.getChannel",
        "lurek.fs.read",
        "arg",
        "package.path",
    ]
}

/// Register only thread-safe modules in a worker Lua VM.
///
/// Worker threads get:
/// - `lurek.thread.getChannel(name)` â€” access to named channels
/// - `arg` â€” table of arguments passed to `thread:start(...)`
///
/// Worker threads do NOT get: `lurek.render`, `lurek.audio`, `lurek.window`,
/// `lurek.input`, `lurek.physics`, `lurek.particle`, or any module that
/// touches `SharedState`.
fn register_thread_safe_modules(
    lua: &mlua::Lua,
    channels: &Arc<Mutex<HashMap<String, Arc<Channel>>>>,
    args: &[ChannelValue],
) -> mlua::Result<()> {
    let lurek = lua.create_table()?;

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
    lurek.set("thread", thread_table)?;

    // â”€â”€ lurek.filesystem (read-only, workers only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Workers get a minimal filesystem API limited to reading files.
    // Path traversal via ".." is blocked. Full GameFS sandbox is not available
    // in worker threads; paths are resolved relative to the process working dir.
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

    // â”€â”€ package.path â€” module search path for require() â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // Workers can require Lua modules relative to the process working directory.
    // The game path is not injected here; pass it through channel args if needed.
    if let Ok(package) = lua.globals().get::<_, mlua::Table>("package") {
        let current: String = package.get("path").unwrap_or_default();
        let new_path = if current.is_empty() {
            "./?.lua;./?/init.lua".to_string()
        } else {
            format!("{}:./?.lua:./?.lua/init.lua", current)
        };
        let _ = package.set("path", new_path);
    }

    // Set up arg table from passed arguments
    let arg_table = lua.create_table()?;
    for (i, val) in args.iter().enumerate() {
        let lua_val = channel_value_to_lua(lua, val.clone())?;
        arg_table.set(i + 1, lua_val)?;
    }
    lua.globals().set("arg", arg_table)?;

    Ok(())
}
