//! Thread-safe channel for Lua inter-thread communication.
//!
//! Provides an MPMC (multi-producer, multi-consumer) queue that can be
//! shared between the main game thread and background Lua threads via
//! `Arc<Channel>`. Only primitive Lua values (nil, bool, number, string)
//! can cross thread boundaries.

use std::collections::VecDeque;
use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use mlua::prelude::*;

use crate::log_msg;
use crate::runtime::log_messages::{CH01, CH02, CH03, CH04};

/// Serializable values that can be sent between threads.
///
/// # Variants
/// - `Nil` — Nil variant.
/// - `Bool` — Bool variant.
/// - `Number` — Number variant.
/// - `String` — String variant.
/// - `Table` — Table variant.
/// - `Bytes` — Bytes variant.
///
/// Primitive types, serialized tables, and raw byte blobs can cross thread
/// boundaries. UserData and functions cannot.
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
    /// Serialized Lua table as key-value pairs, suitable for cross-thread transmission.
    Table(Vec<(ChannelValue, ChannelValue)>),
    /// Raw binary data blob.
    Bytes(Vec<u8>),
}

/// Overflow behavior for bounded channels.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OverflowPolicy {
    /// Block producers until space is available (backpressure).
    Block,
}

/// Thread-safe MPMC channel for Lua inter-thread communication.
///
/// Internally uses a `Mutex<VecDeque>` protected queue with a `Condvar`
/// for blocking `demand()` calls. Safe to wrap in `Arc` and share across
/// OS threads.
///
/// # Fields
/// - `name` — `Option<String>`.
/// - `queue` — `Mutex<VecDeque<ChannelValue>>`.
/// - `condvar` — `Condvar`.
/// - `push_count` — `Mutex<u64>`.
/// - `capacity` — `Option<usize>`.
/// - `overflow_policy` — `OverflowPolicy`.
pub struct Channel {
    /// Optional name for globally-registered channels.
    name: Option<String>,
    /// The value queue, protected by a mutex.
    queue: Mutex<VecDeque<ChannelValue>>,
    /// Condition variable for blocking `demand()`.
    condvar: Condvar,
    /// Monotonic push counter for tracking reads.
    push_count: Mutex<u64>,
    /// Optional bounded capacity; `None` means unbounded.
    capacity: Option<usize>,
    /// Overflow behavior once a bounded channel reaches capacity.
    overflow_policy: OverflowPolicy,
}

impl Channel {
    fn create(
        name: Option<String>,
        capacity: Option<usize>,
        overflow_policy: OverflowPolicy,
    ) -> Arc<Self> {
        Arc::new(Self {
            name,
            queue: Mutex::new(VecDeque::new()),
            condvar: Condvar::new(),
            push_count: Mutex::new(0),
            capacity,
            overflow_policy,
        })
    }

    /// Create an unnamed channel. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn new() -> Arc<Self> {
        log_msg!(debug, CH01);
        Self::create(None, None, OverflowPolicy::Block)
    }

    /// Creates a new bounded channel with backpressure.
    ///
    /// When full, `push` blocks until there is free capacity.
    ///
    /// # Parameters
    /// - `capacity` — `usize`.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn bounded(capacity: usize) -> Arc<Self> {
        let normalized = capacity.max(1);
        Self::create(None, Some(normalized), OverflowPolicy::Block)
    }

    /// Creates a named bidirectional channel pair, binding the channel name in the global registry.
    ///
    /// # Parameters
    /// - `name` — `String`.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn named(name: String) -> Arc<Self> {
        log_msg!(debug, CH02, "{}", name);
        Self::create(Some(name), None, OverflowPolicy::Block)
    }

    /// Creates a named bounded channel with backpressure.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `capacity` — `usize`.
    ///
    /// # Returns
    /// `Arc<Self>`.
    pub fn named_bounded(name: String, capacity: usize) -> Arc<Self> {
        let normalized = capacity.max(1);
        Self::create(Some(name), Some(normalized), OverflowPolicy::Block)
    }

    /// Push a value to the back of the channel. Returns the push ID.
    ///
    /// For bounded channels this method applies backpressure and blocks while full.
    ///
    /// # Parameters
    /// - `value` — `ChannelValue`.
    ///
    /// # Returns
    /// `u64`.
    pub fn push(&self, value: ChannelValue) -> u64 {
        let mut queue = self.queue.lock().unwrap();
        let mut pending = Some(value);

        loop {
            let has_capacity = self
                .capacity
                .map(|limit| queue.len() < limit)
                .unwrap_or(true);
            if has_capacity {
                queue.push_back(pending.take().expect("value must exist before push"));
                let mut count = self.push_count.lock().unwrap();
                *count += 1;
                let id = *count;
                log_msg!(trace, CH03, "push_id={}", id);
                self.condvar.notify_one();
                return id;
            }

            match self.overflow_policy {
                OverflowPolicy::Block => {
                    queue = self.condvar.wait(queue).unwrap();
                }
            }
        }
    }

    /// Attempts to push a value without blocking.
    ///
    /// Returns `false` when the channel is currently at bounded capacity.
    pub fn try_push(&self, value: ChannelValue) -> bool {
        let mut queue = self.queue.lock().unwrap();
        let has_capacity = self
            .capacity
            .map(|limit| queue.len() < limit)
            .unwrap_or(true);
        if !has_capacity {
            return false;
        }
        queue.push_back(value);
        let mut count = self.push_count.lock().unwrap();
        *count += 1;
        self.condvar.notify_one();
        true
    }

    /// Pop a value from the front of the channel (non-blocking).
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    ///
    /// Returns `None` if the channel is empty.
    pub fn pop(&self) -> Option<ChannelValue> {
        let mut queue = self.queue.lock().unwrap();
        let out = queue.pop_front();
        if out.is_some() {
            self.condvar.notify_one();
        }
        out
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
        let deadline = timeout
            .filter(|secs| *secs >= 0.0)
            .map(|secs| Instant::now() + Duration::from_secs_f64(secs));

        loop {
            if let Some(val) = queue.pop_front() {
                self.condvar.notify_one();
                return Some(val);
            }

            match deadline {
                Some(end_at) => {
                    let now = Instant::now();
                    if now >= end_at {
                        return None;
                    }
                    let wait_for = end_at.saturating_duration_since(now);
                    let (q, result) = self.condvar.wait_timeout(queue, wait_for).unwrap();
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

    /// Remove all values from the channel. After this call the container is in the same state as immediately after construction.
    pub fn clear(&self) {
        let mut queue = self.queue.lock().unwrap();
        let count = queue.len();
        queue.clear();
        log_msg!(debug, CH04, "{}", count);
        self.condvar.notify_all();
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
        let has_capacity = self
            .capacity
            .map(|limit| queue.len() < limit)
            .unwrap_or(true);
        if queue.is_empty() && has_capacity {
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

    /// Returns configured bounded capacity, or `None` for unbounded channels.
    pub fn capacity(&self) -> Option<usize> {
        self.capacity
    }

    /// Returns `true` when this channel has a bounded capacity.
    pub fn is_bounded(&self) -> bool {
        self.capacity.is_some()
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
/// Convert a Lua value into a `ChannelValue` for cross-thread transfer.
///
/// # Parameters
/// - `value` — `LuaValue`.
///
/// # Returns
/// `LuaResult<ChannelValue>`.
///
/// Supports nil, boolean, number, string, and recursively-serialized tables.
/// Returns a Lua runtime error for unsupported types (UserData, functions, etc.).
pub fn lua_to_channel_value(value: LuaValue) -> LuaResult<ChannelValue> {
    match value {
        LuaValue::Nil => Ok(ChannelValue::Nil),
        LuaValue::Boolean(b) => Ok(ChannelValue::Bool(b)),
        LuaValue::Integer(n) => Ok(ChannelValue::Number(n as f64)),
        LuaValue::Number(n) => Ok(ChannelValue::Number(n)),
        LuaValue::String(s) => Ok(ChannelValue::String(s.to_str()?.to_string())),
        LuaValue::Table(t) => {
            let mut pairs = Vec::new();
            for pair in t.pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                let ck = lua_to_channel_value(k)?;
                let cv = lua_to_channel_value(v)?;
                pairs.push((ck, cv));
            }
            Ok(ChannelValue::Table(pairs))
        }
        _ => Err(LuaError::RuntimeError(
            "Channel can only transfer nil, boolean, number, string, and table values".into(),
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
        ChannelValue::Table(pairs) => {
            let tbl = lua.create_table()?;
            for (k, v) in pairs {
                let lk = channel_value_to_lua(lua, k)?;
                let lv = channel_value_to_lua(lua, v)?;
                tbl.set(lk, lv)?;
            }
            Ok(LuaValue::Table(tbl))
        }
        ChannelValue::Bytes(b) => Ok(LuaValue::String(lua.create_string(&b)?)),
    }
}
