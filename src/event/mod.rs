//! Event queueing and signal subscription primitives used by the runtime.

/// Priority queue and Lua payload conversion support for runtime events.
pub mod event_queue;
/// Name-based and wildcard signal subscription storage.
pub mod signal;
pub use event_queue::{
    event_arg_to_lua_value, event_to_lua_multi, Event, EventArg, EventPriority, EventQueue,
    EventTableKey,
};
pub use signal::Signal;
