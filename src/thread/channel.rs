//! Thread-safe channel for Lua inter-thread communication.
//!
//! Provides an MPMC (multi-producer, multi-consumer) queue that can be
//! shared between the main game thread and background Lua threads via
//! `Arc<Channel>`. Only primitive Lua values (nil, bool, number, string)
//! can cross thread boundaries.

use std::collections::VecDeque;
use std::sync::{Arc, Condvar, Mutex};

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};

/// Serializable values that can be sent between threads.
///
/// # Variants
/// - `Nil` — Nil variant.
/// - `Bool` — Bool variant.
/// - `Number` — Number variant.
/// - `String` — String variant.
///
/// Only Lua-native primitive types are supported; UserData, tables, and
/// functions cannot cross thread boundaries.
#[derive(Debug, Clone)]
pub enum ChannelValue {
    /// Lua `nil`.
    Nil,
    /// Lua boolean.
    Bool(bool),
    /// Lua number (always f64).
    Number(f64),
    /// Lua string.
    String(String),
}

/// Thread-safe MPMC channel for Lua inter-thread communication.
///
/// Internally uses a `Mutex<VecDeque>` protected queue with a `Condvar`
/// for blocking `demand()` calls. Safe to wrap in `Arc` and share across
/// OS threads.
pub struct Channel {
    /// Optional name for globally-registered channels.
    name: Option<String>,
    /// The value queue, protected by a mutex.
    queue: Mutex<VecDeque<ChannelValue>>,
    /// Condition variable for blocking `demand()`.
    condvar: Condvar,
    /// Monotonic push counter for tracking reads.
    push_count: Mutex<u64>,
}

impl Channel {
    /// Create an unnamed channel.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            name: None,
            queue: Mutex::new(VecDeque::new()),
            condvar: Condvar::new(),
            push_count: Mutex::new(0),
        })
    }

    /// Create a named channel.
    ///
    /// # Parameters
    /// - `name` — `String`.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn named(name: String) -> Arc<Self> {
        Arc::new(Self {
            name: Some(name),
            queue: Mutex::new(VecDeque::new()),
            condvar: Condvar::new(),
            push_count: Mutex::new(0),
        })
    }

    /// Push a value to the back of the channel. Returns the push ID.
    ///
    /// # Parameters
    /// - `value` — `ChannelValue`.
    ///
    /// # Returns
    /// `u64`.
    pub fn push(&self, value: ChannelValue) -> u64 {
        let mut queue = self.queue.lock().unwrap();
        queue.push_back(value);
        let mut count = self.push_count.lock().unwrap();
        *count += 1;
        let id = *count;
        self.condvar.notify_one();
        id
    }

    /// Pop a value from the front of the channel (non-blocking).
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    ///
    /// Returns `None` if the channel is empty.
    pub fn pop(&self) -> Option<ChannelValue> {
        let mut queue = self.queue.lock().unwrap();
        queue.pop_front()
    }

    /// Peek at the front value without removing it.
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    ///
    /// Returns `None` if the channel is empty.
    pub fn peek(&self) -> Option<ChannelValue> {
        let queue = self.queue.lock().unwrap();
        queue.front().cloned()
    }

    /// Wait for a value, blocking the calling thread.
    ///
    /// # Parameters
    /// - `timeout` — `Option<f64>`.
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    ///
    /// If `timeout` is `Some(seconds)`, returns `None` after the timeout
    /// elapses without a value. If `timeout` is `None`, blocks forever.
    pub fn demand(&self, timeout: Option<f64>) -> Option<ChannelValue> {
        let mut queue = self.queue.lock().unwrap();
        loop {
            if let Some(val) = queue.pop_front() {
                return Some(val);
            }
            match timeout {
                Some(secs) => {
                    let duration = std::time::Duration::from_secs_f64(secs);
                    let (q, result) = self.condvar.wait_timeout(queue, duration).unwrap();
                    queue = q;
                    if result.timed_out() {
                        return queue.pop_front();
                    }
                }
                None => {
                    queue = self.condvar.wait(queue).unwrap();
                }
            }
        }
    }

    /// Get the number of values currently in the channel.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_count(&self) -> usize {
        self.queue.lock().unwrap().len()
    }

    /// Remove all values from the channel.
    pub fn clear(&self) {
        self.queue.lock().unwrap().clear();
    }

    /// Push a value only if the channel is currently empty.
    ///
    /// # Parameters
    /// - `value` — `ChannelValue`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if the value was pushed, `false` if the channel
    /// already contained at least one value.
    pub fn supply(&self, value: ChannelValue) -> bool {
        let mut queue = self.queue.lock().unwrap();
        if queue.is_empty() {
            queue.push_back(value);
            self.condvar.notify_one();
            true
        } else {
            false
        }
    }

    /// Get the channel name, if it is a named channel.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }
}

/// Lua UserData wrapper for a thread-safe channel.
///
/// # Fields
/// - `inner` — `Arc<Channel>`.
///
/// Holds an `Arc<Channel>` so the underlying channel can be shared across
/// threads while each Lua VM holds its own `LuaChannel` handle.
#[derive(Clone)]
pub struct LuaChannel {
    /// The shared channel this handle refers to.
    pub(crate) inner: Arc<Channel>,
}

impl LunaType for LuaChannel {
    const TYPE_NAME: &'static str = "Channel";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaChannel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

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

        methods.add_method("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        methods.add_method("supply", |_, this, value: LuaValue| {
            let cv = lua_to_channel_value(value)?;
            Ok(this.inner.supply(cv))
        });
    }
}

/// Convert a Lua value into a `ChannelValue` for cross-thread transfer.
///
/// # Parameters
/// - `value` — `LuaValue`.
///
/// # Returns
/// `LuaResult<ChannelValue>`.
///
/// Only nil, boolean, number (integer or float), and string are supported.
/// Returns a Lua runtime error for unsupported types.
pub fn lua_to_channel_value(value: LuaValue) -> LuaResult<ChannelValue> {
    match value {
        LuaValue::Nil => Ok(ChannelValue::Nil),
        LuaValue::Boolean(b) => Ok(ChannelValue::Bool(b)),
        LuaValue::Integer(n) => Ok(ChannelValue::Number(n as f64)),
        LuaValue::Number(n) => Ok(ChannelValue::Number(n)),
        LuaValue::String(s) => Ok(ChannelValue::String(s.to_str()?.to_string())),
        _ => Err(LuaError::RuntimeError(
            "Channel can only transfer nil, boolean, number, and string values".into(),
        )),
    }
}

/// Convert a `ChannelValue` back into a Lua value.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `value` — `ChannelValue`.
///
/// # Returns
/// `LuaResult<LuaValue<'_>>`.
pub fn channel_value_to_lua(lua: &Lua, value: ChannelValue) -> LuaResult<LuaValue<'_>> {
    match value {
        ChannelValue::Nil => Ok(LuaValue::Nil),
        ChannelValue::Bool(b) => Ok(LuaValue::Boolean(b)),
        ChannelValue::Number(n) => Ok(LuaValue::Number(n)),
        ChannelValue::String(s) => Ok(LuaValue::String(lua.create_string(&s)?)),
    }
}
