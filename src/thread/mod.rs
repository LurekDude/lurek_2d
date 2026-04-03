//! Thread infrastructure: inter-thread channel and background Lua worker.
//!
//! This module is part of Luna2D's `thread` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Channel sub-module.
pub mod channel;
/// Worker sub-module.
pub mod worker;
