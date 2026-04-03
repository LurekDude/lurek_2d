//! Registers the `luna.thread` namespace.
//!
//! Provides Lua-level multithreading: create background threads that run
//! independent Lua VMs and communicate via thread-safe channels.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for thread api-related operations and data management.
//! Key types exported from this module: `LuaThreadHandle`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use mlua::prelude::*;

use crate::lua_api::thread_channel::{lua_to_channel_value, Channel, LuaChannel};
use crate::lua_api::thread_worker::LuaThread;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

/// Lua UserData wrapper for a background thread handle.
///
/// # Fields
/// - `inner` — `Arc<Mutex<LuaThread>>`.
///
/// Wraps `Arc<Mutex<LuaThread>>` so multiple Lua references can share
/// access to the same thread state.
#[derive(Clone)]
pub struct LuaThreadHandle {
    /// The shared thread state.
    pub(crate) inner: Arc<Mutex<LuaThread>>,
}

impl LunaType for LuaThreadHandle {
    const TYPE_NAME: &'static str = "Thread";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaThreadHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Launches the background thread, passing optional arguments to the Lua script via `...`.
        /// @param args : MultiValue
        ///
        /// # Parameters
        /// - `...` — `any`: Optional arguments forwarded to the thread script as Lua values.
        methods.add_method("start", |_, this, args: LuaMultiValue| {
            let channel_args: Vec<_> = args
                .into_iter()
                .map(lua_to_channel_value)
                .collect::<LuaResult<Vec<_>>>()?;
            let mut thread = this.inner.lock().unwrap();
            thread.start(channel_args).map_err(LuaError::RuntimeError)?;
            Ok(())
        });

        /// Blocks the calling coroutine until this thread finishes execution.
        methods.add_method("wait", |_, this, ()| {
            let mut thread = this.inner.lock().unwrap();
            thread.wait();
            Ok(())
        });

        /// Returns `true` if the thread is currently executing.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isRunning", |_, this, ()| {
            let thread = this.inner.lock().unwrap();
            Ok(thread.is_running())
        });

        /// Returns the error message if the thread terminated with a Lua error, or `nil` if it completed normally.
        /// @return any
        ///
        /// # Returns
        /// `string` — error message, or `nil`.
        methods.add_method("getError", |_, this, ()| {
            let thread = this.inner.lock().unwrap();
            Ok(thread.get_error())
        });
    }
}

/// Registers all `luna.thread.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
///
/// # Functions registered
/// - `luna.thread.newThread(code)` — create a new background thread
/// - `luna.thread.newChannel()` — create an unnamed channel
/// - `luna.thread.getChannel(name)` — get or create a named global channel
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let thread_table = lua.create_table()?;
    let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
        Arc::new(Mutex::new(HashMap::new()));

    #[allow(unused_doc_comments)]
    /// Create a new background thread from a Lua code string.
    /// The thread gets its own Lua VM and can communicate via channels.
    // luna.thread.newThread(code)
    let channels_for_new = named_channels.clone();
    /// @param code : string
    /// @return any
    thread_table.set(
        "newThread",
        lua.create_function(move |_, code: String| {
            Ok(LuaThreadHandle {
                inner: Arc::new(Mutex::new(LuaThread::new(code, channels_for_new.clone()))),
            })
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Create an unnamed thread-safe channel for inter-thread communication.
    // luna.thread.newChannel()
    /// @return any
    thread_table.set(
        "newChannel",
        lua.create_function(|_, ()| {
            Ok(LuaChannel {
                inner: Channel::new(),
            })
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Get or create a named global channel (singleton, shared across threads).
    // luna.thread.getChannel(name)
    let channels_for_get = named_channels.clone();
    /// @param name : string
    /// @return any
    thread_table.set(
        "getChannel",
        lua.create_function(move |_, name: String| {
            let mut channels = channels_for_get.lock().unwrap();
            let channel = channels
                .entry(name.clone())
                .or_insert_with(|| Channel::named(name))
                .clone();
            Ok(LuaChannel { inner: channel })
        })?,
    )?;

    /// Thread.
    luna.set("thread", thread_table)?;
    Ok(())
}
