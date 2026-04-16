//! Thread infrastructure: inter-thread channel and background Lua worker.
//!
//! This module is part of Lurek2D's `thread` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Lock-free inter-VM message channel for cross-thread Lua communication.
pub mod channel;
/// Sandboxed LuaJIT worker thread that runs a Lua script in isolation.
pub mod worker;
/// Thread pool that queues and executes tasks across multiple worker threads.
pub mod pool;
/// Promise / future sub-module.
pub mod promise;
