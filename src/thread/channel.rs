//! Typed MPMC channel for cross-thread value transfer between the main Lua VM
//! and worker VMs. Owns `ChannelValue`, `OverflowPolicy`, `Channel`, and the
//! Lua conversion helpers. Does not own threading or pool management; those live
//! in `pool` and `worker`. Depends on `mlua` for Lua value conversion.

use crate::log_msg;
use crate::runtime::log_messages::{CH01, CH02, CH03, CH04};
use mlua::prelude::*;
use std::collections::VecDeque;
use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

/// A value type that can be safely sent through a `Channel` between threads.
#[derive(Debug, Clone)]
pub enum ChannelValue {
    /// Lua `nil`.
    Nil,
    /// Lua boolean.
    Bool(bool),
    /// Lua number (integer or float, both stored as `f64`).
    Number(f64),
    /// Lua string.
    String(String),
    /// Lua table serialised as key-value pairs; nested tables are supported.
    Table(Vec<(ChannelValue, ChannelValue)>),
    /// Raw byte string from `lua.create_string` or similar.
    Bytes(Vec<u8>),
}

/// Policy applied when a bounded `Channel` is full and `push` is called.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OverflowPolicy {
    /// Block the caller until space is available.
    Block,
}

/// Thread-safe MPMC queue of `ChannelValue` entries shared via `Arc`.
pub struct Channel {
    /// Optional human-readable name for diagnostics.
    name: Option<String>,
    /// The underlying message queue, protected by a mutex.
    queue: Mutex<VecDeque<ChannelValue>>,
    /// Condvar used to wake blocked senders and receivers.
    condvar: Condvar,
    /// Monotonically increasing push counter used for message IDs.
    push_count: Mutex<u64>,
    /// Maximum number of queued messages; `None` means unbounded.
    capacity: Option<usize>,
    /// What to do when `push` is called on a full bounded channel.
    overflow_policy: OverflowPolicy,
}
impl Channel {
    /// Internal constructor; wraps in `Arc` and initialises empty state.
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
    /// Create an unbounded, unnamed channel.
    pub fn new() -> Arc<Self> {
        log_msg!(debug, CH01);
        Self::create(None, None, OverflowPolicy::Block)
    }

    /// Create a bounded, unnamed channel with a capacity of at least 1.
    pub fn bounded(capacity: usize) -> Arc<Self> {
        let normalized = capacity.max(1);
        Self::create(None, Some(normalized), OverflowPolicy::Block)
    }

    /// Create an unbounded channel with a diagnostic `name`.
    pub fn named(name: String) -> Arc<Self> {
        log_msg!(debug, CH02, "{}", name);
        Self::create(Some(name), None, OverflowPolicy::Block)
    }

    /// Create a bounded channel with a diagnostic `name` and capacity of at least 1.
    pub fn named_bounded(name: String, capacity: usize) -> Arc<Self> {
        let normalized = capacity.max(1);
        Self::create(Some(name), Some(normalized), OverflowPolicy::Block)
    }
    /// Push `value` onto the queue, blocking when the channel is full; return the 1-based push sequence ID.
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
    /// Push `value` without blocking; return `false` immediately when the channel is full.
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
    /// Remove and return the front value without blocking; return `None` when the queue is empty.
    pub fn pop(&self) -> Option<ChannelValue> {
        let mut queue = self.queue.lock().unwrap();
        let out = queue.pop_front();
        if out.is_some() {
            self.condvar.notify_one();
        }
        out
    }
    /// Return a clone of the front value without removing it; return `None` when the queue is empty.
    pub fn peek(&self) -> Option<ChannelValue> {
        let queue = self.queue.lock().unwrap();
        queue.front().cloned()
    }
    /// Block until a value is available or `timeout` seconds elapse; return `None` on timeout.
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
    /// Return the number of values currently in the queue.
    pub fn get_count(&self) -> usize {
        self.queue.lock().unwrap().len()
    }

    /// Drain the queue and wake all blocked senders.
    pub fn clear(&self) {
        let mut queue = self.queue.lock().unwrap();
        let count = queue.len();
        queue.clear();
        log_msg!(debug, CH04, "{}", count);
        self.condvar.notify_all();
    }

    /// Push `value` only when the queue is empty and has capacity; return `true` when pushed.
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
    /// Return the channel's diagnostic name, or `None` for anonymous channels.
    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    /// Return the capacity limit, or `None` for unbounded channels.
    pub fn capacity(&self) -> Option<usize> {
        self.capacity
    }

    /// Return `true` when the channel was created with a capacity limit.
    pub fn is_bounded(&self) -> bool {
        self.capacity.is_some()
    }
}
/// Lua-side handle for a `Channel` shared across thread boundaries via `Arc`.
#[derive(Clone)]
pub struct LuaChannel {
    /// Shared channel instance.
    pub(crate) inner: Arc<Channel>,
}
/// Convert a Lua value to a `ChannelValue`; returns a `RuntimeError` for unsupported types.
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
/// Convert a `ChannelValue` back to a Lua value in the given `lua` context.
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
