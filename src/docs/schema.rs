//! Re-export shared documentation schema contracts from the companion crate.
//! Keep this file as a thin boundary so internal modules use one import path.
//! Do not define schema logic or validators in this module.
//! Depend on lurek_schema as the single source of typed schema definitions.

/// Re-export schema model types and helpers consumed by docs modules.
pub use lurek_schema::*;
