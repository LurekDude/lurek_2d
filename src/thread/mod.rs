//! Thread infrastructure: inter-thread channel and background Lua worker.
//!
//! This module is part of Lurek2D's `thread` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Channel sub-module.
pub mod channel;
/// Worker sub-module.
pub mod worker;
/// Thread pool sub-module.
pub mod pool;
/// Promise / future sub-module.
pub mod promise;
