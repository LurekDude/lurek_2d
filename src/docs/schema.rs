//! - Re-export schema validation types from the lurek_schema crate.
//! - Provide field rules, type definitions, and error types to docs modules.
//! - Keep schema source of truth external; this file is an access bridge.

/// Re-export schema model types and helpers consumed by docs modules.
pub use lurek_schema::*;
