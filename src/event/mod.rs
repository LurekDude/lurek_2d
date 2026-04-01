//! Event queue for polling system and custom events.
//!
//! Provides an alternative to the callback model where game code can poll events
//! from a FIFO queue. Also contains the `Signal` pub-sub type for handle-based
//! event dispatching.

mod signal;

pub use signal::Signal;

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
#[derive(Debug)]
pub struct EventQueue {
    events: VecDeque<Event>,
}

impl EventQueue {
    /// Create a new empty event queue.
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

    /// Push an event by name and arguments.
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

    /// Clear all events from the queue.
    pub fn clear(&mut self) {
        self.events.clear();
    }

    /// Check if the queue is empty.
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
}

impl Default for EventQueue {
    fn default() -> Self {
        Self::new()
    }
}
