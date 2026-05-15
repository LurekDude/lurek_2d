//! - Priority queue with ordered dispatch and Lua payload conversion for runtime events.
//! - Name-based and wildcard signal subscriptions for decoupled communication.

/// Priority queue and Lua payload conversion support for runtime events.
pub mod event_queue;
/// Name-based and wildcard signal subscription storage.
pub mod signal;
pub use event_queue::{
    event_arg_to_lua_value, event_to_lua_multi, Event, EventArg, EventPriority, EventQueue,
    EventTableKey,
};
pub use signal::Signal;
