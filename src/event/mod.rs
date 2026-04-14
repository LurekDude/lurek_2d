//! Event queue for polling system and custom events.
//!
//! Provides two complementary mechanisms for event handling:
//! - [`EventQueue`]: a double-buffered FIFO queue where the engine pushes OS and user events
//!   each frame; game code drains it via Lua callbacks or Rust poll loops.
//! - [`Signal`]: a handle-based pub-sub type for decoupled event dispatching between game
//!   systems without routing through the central queue.
//!
//! All public items are documented. Lua bridge: event dispatch is handled by `App` directly.

mod signal;
mod event_queue;

pub use signal::Signal;
pub use event_queue::{Event, EventArg, EventQueue, event_to_lua_multi};
