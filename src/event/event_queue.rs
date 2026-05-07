//! Event types and FIFO event queue.

use std::collections::VecDeque;
use std::sync::{Condvar, Mutex};

/// Queue lane used when enqueuing events.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventPriority {
    /// High-priority lane; drained before normal events.
    High,
    /// Default lane for regular gameplay events.
    Normal,
}

/// Supported Lua table keys for table payload cloning.
#[derive(Debug, Clone)]
pub enum EventTableKey {
    /// String key.
    Str(String),
    /// Numeric key.
    Num(f64),
    /// Boolean key.
    Bool(bool),
}

/// Argument values that can be attached to events.
///
/// # Variants
/// - `Str` — Str variant.
/// - `Num` — Num variant.
/// - `Bool` — Bool variant.
/// - `Nil` — Nil variant.
#[derive(Debug, Clone)]
pub enum EventArg {
    /// String argument.
    Str(String),
    /// Numeric argument.
    Num(f64),
    /// Boolean argument.
    Bool(bool),
    /// Nil / no value.
    Nil,
    /// Shallow-cloned table payload.
    Table(Vec<(EventTableKey, EventArg)>),
}

/// A single event in the event queue.
///
/// # Fields
/// - `name` — `String`.
/// - `args` — `Vec<EventArg>`.
#[derive(Debug, Clone)]
pub struct Event {
    /// Event type name (e.g., "keypressed", "mousepressed", "custom").
    pub name: String,
    /// Event arguments.
    pub args: Vec<EventArg>,
}

/// FIFO event queue for system and custom events.
///
/// # Fields
/// - `events` — `VecDeque<Event>`.
#[derive(Debug)]
pub struct EventQueue {
    high_events: VecDeque<Event>,
    normal_events: VecDeque<Event>,
    wait_epoch: Mutex<u64>,
    wait_condvar: Condvar,
}

impl EventQueue {
    /// Create a new empty event queue. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            high_events: VecDeque::new(),
            normal_events: VecDeque::new(),
            wait_epoch: Mutex::new(0),
            wait_condvar: Condvar::new(),
        }
    }

    /// Push an event onto the queue.
    ///
    /// # Parameters
    /// - `event` — `Event`.
    pub fn push(&mut self, event: Event) {
        self.push_with_priority(event, EventPriority::Normal);
    }

    /// Push an event onto the queue with explicit lane selection.
    ///
    /// # Parameters
    /// - `event` — `Event`.
    /// - `priority` — `EventPriority`.
    pub fn push_with_priority(&mut self, event: Event, priority: EventPriority) {
        match priority {
            EventPriority::High => self.high_events.push_back(event),
            EventPriority::Normal => self.normal_events.push_back(event),
        }
        self.notify_waiters();
    }

    /// Push an event by name and arguments. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `args` — `Vec<EventArg>`.
    pub fn push_event(&mut self, name: &str, args: Vec<EventArg>) {
        self.push_event_with_priority(name, args, EventPriority::Normal);
    }

    /// Push an event by name and arguments to an explicit priority lane.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `args` — `Vec<EventArg>`.
    /// - `priority` — `EventPriority`.
    pub fn push_event_with_priority(
        &mut self,
        name: &str,
        args: Vec<EventArg>,
        priority: EventPriority,
    ) {
        self.push_with_priority(
            Event {
                name: name.to_string(),
                args,
            },
            priority,
        );
    }

    /// Poll the next event from the queue.
    ///
    /// # Returns
    /// `Option<Event>`.
    pub fn poll(&mut self) -> Option<Event> {
        self.high_events
            .pop_front()
            .or_else(|| self.normal_events.pop_front())
    }

    /// Clear all events from the queue. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.high_events.clear();
        self.normal_events.clear();
    }

    /// Check if the queue is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.high_events.is_empty() && self.normal_events.is_empty()
    }

    /// Get the number of events in the queue.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.high_events.len() + self.normal_events.len()
    }

    /// Drains pending OS-level events into the queue (no-op in Lurek2D; documents as a sync point).
    ///
    /// Lurek2D uses a push model — OS events are already in the queue when callbacks fire.
    /// This function exists for API parity and does nothing.
    ///
    /// # Returns
    /// `()`.
    pub fn pump(&self) {
        // Lurek2D uses a push model; OS events are already in queue when this is called.
    }

    /// Blocks until an event is available or `timeout_ms` milliseconds elapse.
    ///
    /// If the queue already contains an event it is returned immediately without sleeping.
    /// With a `Some(0)` timeout the queue is polled once and the function returns.
    ///
    /// # Parameters
    /// - `timeout_ms` — `Option<u64>`. Max wait time in milliseconds; `None` = wait indefinitely (returns only when an event arrives).
    ///
    /// # Returns
    /// `Option<Event>`.
    pub fn wait(&mut self, timeout_ms: Option<u64>) -> Option<Event> {
        if let Some(evt) = self.poll() {
            return Some(evt);
        }

        let mut seen_epoch = {
            let epoch_guard = match self.wait_epoch.lock() {
                Ok(guard) => guard,
                Err(poisoned) => poisoned.into_inner(),
            };
            *epoch_guard
        };

        match timeout_ms {
            Some(ms) => {
                if ms == 0 {
                    return None;
                }

                let deadline = std::time::Instant::now() + std::time::Duration::from_millis(ms);
                while std::time::Instant::now() < deadline {
                    let remaining = deadline.saturating_duration_since(std::time::Instant::now());
                    if self.wait_for_epoch_change(&mut seen_epoch, Some(remaining)) {
                        if let Some(evt) = self.poll() {
                            return Some(evt);
                        }
                    } else {
                        return self.poll();
                    }
                }
                None
            }
            None => loop {
                if self.wait_for_epoch_change(&mut seen_epoch, None) {
                    if let Some(evt) = self.poll() {
                        return Some(evt);
                    }
                }
            },
        }
    }

    fn wait_for_epoch_change(
        &self,
        seen_epoch: &mut u64,
        timeout: Option<std::time::Duration>,
    ) -> bool {
        let guard = match self.wait_epoch.lock() {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };

        if *guard != *seen_epoch {
            *seen_epoch = *guard;
            return true;
        }

        match timeout {
            Some(duration) => {
                let result = self
                    .wait_condvar
                    .wait_timeout_while(guard, duration, |epoch| *epoch == *seen_epoch);
                let (guard, timeout_result) = match result {
                    Ok(pair) => pair,
                    Err(poisoned) => poisoned.into_inner(),
                };
                if *guard != *seen_epoch {
                    *seen_epoch = *guard;
                    true
                } else {
                    !timeout_result.timed_out()
                }
            }
            None => {
                let result = self
                    .wait_condvar
                    .wait_while(guard, |epoch| *epoch == *seen_epoch);
                let guard = match result {
                    Ok(guard) => guard,
                    Err(poisoned) => poisoned.into_inner(),
                };
                *seen_epoch = *guard;
                true
            }
        }
    }

    fn notify_waiters(&self) {
        let mut epoch_guard = match self.wait_epoch.lock() {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };
        *epoch_guard = epoch_guard.wrapping_add(1);
        self.wait_condvar.notify_all();
    }
}

impl Default for EventQueue {
    fn default() -> Self {
        Self::new()
    }
}

// -------------------------------------------------------------------------------
// Lua conversion helpers  (available when mlua is compiled in)
// -------------------------------------------------------------------------------

use mlua::prelude::*;

impl EventArg {
    /// Converts a [`LuaValue`] to an [`EventArg`] for event queue storage.
    ///
    /// Strings, integers, numbers, and booleans are each mapped to their
    /// corresponding variant; any other type maps to [`EventArg::Nil`].
    ///
    /// # Parameters
    /// - `val` — `&LuaValue`. The Lua value to convert.
    ///
    /// # Returns
    /// `LuaResult<EventArg>`.
    pub fn from_lua_val(val: &LuaValue) -> LuaResult<Self> {
        match val {
            LuaValue::String(s) => Ok(EventArg::Str(
                s.to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
            )),
            LuaValue::Integer(n) => Ok(EventArg::Num(*n as f64)),
            LuaValue::Number(n) => Ok(EventArg::Num(*n)),
            LuaValue::Boolean(b) => Ok(EventArg::Bool(*b)),
            LuaValue::Table(tbl) => Self::from_lua_table_shallow(tbl),
            _ => Ok(EventArg::Nil),
        }
    }

    fn from_lua_table_shallow(table: &LuaTable) -> LuaResult<Self> {
        let mut out = Vec::new();
        for pair in table.clone().pairs::<LuaValue, LuaValue>() {
            let (key, value) = pair?;
            if let Some(converted_key) = Self::table_key_from_lua(&key)? {
                out.push((converted_key, Self::table_value_from_lua_shallow(&value)?));
            }
        }
        Ok(EventArg::Table(out))
    }

    fn table_key_from_lua(value: &LuaValue) -> LuaResult<Option<EventTableKey>> {
        match value {
            LuaValue::String(s) => Ok(Some(EventTableKey::Str(
                s.to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
            ))),
            LuaValue::Integer(n) => Ok(Some(EventTableKey::Num(*n as f64))),
            LuaValue::Number(n) => Ok(Some(EventTableKey::Num(*n))),
            LuaValue::Boolean(b) => Ok(Some(EventTableKey::Bool(*b))),
            _ => Ok(None),
        }
    }

    fn table_value_from_lua_shallow(value: &LuaValue) -> LuaResult<EventArg> {
        match value {
            LuaValue::String(_) | LuaValue::Integer(_) | LuaValue::Number(_) | LuaValue::Boolean(_) => {
                Self::from_lua_val(value)
            }
            LuaValue::Table(_) => Ok(EventArg::Nil),
            _ => Ok(EventArg::Nil),
        }
    }
}

/// Convert an [`EventArg`] value into a Lua value.
pub fn event_arg_to_lua_value<'lua>(lua: &'lua Lua, arg: &EventArg) -> LuaResult<LuaValue<'lua>> {
    match arg {
        EventArg::Str(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        EventArg::Num(n) => Ok(LuaValue::Number(*n)),
        EventArg::Bool(b) => Ok(LuaValue::Boolean(*b)),
        EventArg::Nil => Ok(LuaValue::Nil),
        EventArg::Table(entries) => {
            let table = lua.create_table()?;
            for (key, value) in entries {
                let lua_key = match key {
                    EventTableKey::Str(s) => LuaValue::String(lua.create_string(s)?),
                    EventTableKey::Num(n) => LuaValue::Number(*n),
                    EventTableKey::Bool(b) => LuaValue::Boolean(*b),
                };
                let lua_value = event_arg_to_lua_value(lua, value)?;
                table.set(lua_key, lua_value)?;
            }
            Ok(LuaValue::Table(table))
        }
    }
}

/// Converts an [`Event`] into a Lua multi-value (name followed by args).
///
/// The first value is the event name as a Lua string; subsequent values
/// are each [`EventArg`] converted to its Lua equivalent.
///
/// # Parameters
/// - `lua` — `&Lua`. The Lua VM.
/// - `event` — `&Event`. The event to convert.
///
/// # Returns
/// `LuaResult<LuaMultiValue>`.
pub fn event_to_lua_multi<'lua>(lua: &'lua Lua, event: &Event) -> LuaResult<LuaMultiValue<'lua>> {
    let mut values = Vec::with_capacity(1 + event.args.len());
    values.push(LuaValue::String(lua.create_string(&event.name)?));
    for arg in &event.args {
        values.push(event_arg_to_lua_value(lua, arg)?);
    }
    Ok(LuaMultiValue::from_vec(values))
}
