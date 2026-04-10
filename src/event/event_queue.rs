//! Event types and FIFO event queue.

use std::collections::VecDeque;

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
    events: VecDeque<Event>,
}

impl EventQueue {
    /// Create a new empty event queue. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            events: VecDeque::new(),
        }
    }

    /// Push an event onto the queue.
    ///
    /// # Parameters
    /// - `event` — `Event`.
    pub fn push(&mut self, event: Event) {
        self.events.push_back(event);
    }

    /// Push an event by name and arguments. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `args` — `Vec<EventArg>`.
    pub fn push_event(&mut self, name: &str, args: Vec<EventArg>) {
        self.events.push_back(Event {
            name: name.to_string(),
            args,
        });
    }

    /// Poll the next event from the queue.
    ///
    /// # Returns
    /// `Option<Event>`.
    pub fn poll(&mut self) -> Option<Event> {
        self.events.pop_front()
    }

    /// Clear all events from the queue. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.events.clear();
    }

    /// Check if the queue is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.events.is_empty()
    }

    /// Get the number of events in the queue.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.events.len()
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
        // Non-blocking fast path: return immediately if an event is ready.
        if let Some(evt) = self.poll() {
            return Some(evt);
        }
        // Timed path: spin-wait with 1 ms granularity.
        if let Some(ms) = timeout_ms {
            let deadline = std::time::Instant::now() + std::time::Duration::from_millis(ms);
            while std::time::Instant::now() < deadline {
                std::thread::sleep(std::time::Duration::from_millis(1));
                if let Some(evt) = self.poll() {
                    return Some(evt);
                }
            }
            None
        } else {
            // Indefinite wait: keep sleeping until an event arrives.
            loop {
                std::thread::sleep(std::time::Duration::from_millis(1));
                if let Some(evt) = self.poll() {
                    return Some(evt);
                }
            }
        }
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
            _ => Ok(EventArg::Nil),
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
        let val = match arg {
            EventArg::Str(s) => LuaValue::String(lua.create_string(s)?),
            EventArg::Num(n) => LuaValue::Number(*n),
            EventArg::Bool(b) => LuaValue::Boolean(*b),
            EventArg::Nil => LuaValue::Nil,
        };
        values.push(val);
    }
    Ok(LuaMultiValue::from_vec(values))
}

#[cfg(test)]
mod tests {
    use super::{Event, EventArg, EventQueue};

    // ── Push / Len ────────────────────────────────────────────────────────────

    #[test]
    fn new_queue_is_empty() {
        let q = EventQueue::new();
        assert!(q.is_empty());
        assert_eq!(q.len(), 0);
    }

    #[test]
    fn push_event_increments_len() {
        let mut q = EventQueue::new();
        q.push_event("keypressed", vec![EventArg::Str("a".to_string())]);
        assert_eq!(q.len(), 1);
    }

    // ── FIFO order ─────────────────────────────────────────────────────────────

    #[test]
    fn poll_fifo_order_preserved() {
        let mut q = EventQueue::new();
        q.push_event("first", vec![]);
        q.push_event("second", vec![]);
        let e1 = q.poll().unwrap();
        let e2 = q.poll().unwrap();
        assert_eq!(e1.name, "first");
        assert_eq!(e2.name, "second");
    }

    #[test]
    fn poll_empty_returns_none() {
        let mut q = EventQueue::new();
        assert!(q.poll().is_none());
    }

    // ── Clear ─────────────────────────────────────────────────────────────────

    #[test]
    fn clear_empties_queue() {
        let mut q = EventQueue::new();
        q.push_event("a", vec![]);
        q.push_event("b", vec![]);
        q.clear();
        assert!(q.is_empty());
    }

    #[test]
    fn push_direct_and_poll_roundtrip() {
        let mut q = EventQueue::new();
        q.push(Event {
            name: "custom".to_string(),
            args: vec![EventArg::Num(42.0)],
        });
        let evt = q.poll().unwrap();
        assert_eq!(evt.name, "custom");
    }
}
