//! Background threading infrastructure for Lua game scripts.
//!
//! This module is part of Lurek2D's **Core Runtime** tier and provides the primitives
//! for running CPU-intensive Lua work off the main thread. Because LuaJIT VMs cannot
//! share state across OS threads (design constraint **B-04**), each background thread
//! runs an isolated VM communicating through [`Channel`] objects.
//!
//! ## Subsystem inventory
//! - [`channel`] — [`Channel`]: thread-safe MPMC queue for `ChannelValue` (nil, bool,
//!   number, string, serialized table, bytes). Supports blocking `demand()` with timeout.
//! - [`worker`] — [`LuaThread`]: spawns an OS thread with its own `mlua::Lua` VM,
//!   captures errors in `ThreadState::Error`, exposes `wait()` and `get_error()`.
//! - [`pool`] — [`ThreadPool`]: manages N persistent workers sharing input/output channels.
//! - [`promise`] — [`Promise`]: one-shot background computation returning a single result
//!   via a dedicated `__promise_result` channel.
//!
//! ## Threading constraint
//! Worker VMs get a sandboxed subset of the `lurek.*` API — no graphics, audio, window,
//! input, or physics modules. Only `lurek.thread.getChannel`, `lurek.filesystem.read` (read-only,
//! no `..` traversal), and the `arg` global table are available.
//!
//! All public items are documented. Lua bridge: `src/lua_api/thread_api.rs`.

/// Lock-free inter-VM message channel for cross-thread Lua communication.
pub mod channel;
/// Thread pool that queues and executes tasks across multiple worker threads.
pub mod pool;
/// Promise / future for one-shot background computation.
pub mod promise;
/// Sandboxed LuaJIT worker thread that runs a Lua script in isolation.
pub mod worker;
