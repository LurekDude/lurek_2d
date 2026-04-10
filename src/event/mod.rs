//! Event queue for polling system and custom events.
//!
//! Provides an alternative to the callback model where game code can poll events
//! from a FIFO queue. Also contains the \Signal\ pub-sub type for handle-based
//! event dispatching.

mod signal;
mod event_queue;

pub use signal::Signal;
pub use event_queue::{Event, EventArg, EventQueue, event_to_lua_multi};
