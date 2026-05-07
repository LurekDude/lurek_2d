//! Event queue and signal system for polling, dispatching, and subscribing to game events.
//!
//! This module is part of Lurek2D's **Core Runtime** tier and provides two complementary
//! mechanisms for event handling:
//!
//! - [`EventQueue`]: a FIFO queue where the engine pushes OS input, window-state changes,
//!   and custom Lua events each frame. Game code drains it via Lua callbacks or Rust
//!   poll loops. Shared via `Rc<RefCell<EventQueue>>` in `SharedState` (main thread only).
//! - [`Signal`]: a handle-based pub-sub dispatcher for decoupled event notification between
//!   game systems without routing through the central queue. Supports exact-name and
//!   glob-wildcard (`*`, `?`) subscriptions.
//!
//! ## Threading constraint
//! `EventQueue` is `!Send` — only the main thread may push or poll events. Background
//! threads that need to communicate use `lurek.thread.Channel` instead.
//!
//! All public items are documented. Lua bridge: `src/lua_api/event_api.rs`.

/// FIFO event queue and event types.
mod event_queue;
/// Handle-based pub-sub signal dispatcher with wildcard support.
mod signal;

pub use event_queue::{
	event_arg_to_lua_value, event_to_lua_multi, Event, EventArg, EventPriority, EventQueue,
	EventTableKey,
};
pub use signal::Signal;
