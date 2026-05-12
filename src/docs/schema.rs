//! Re-export of the standalone `lurek_schema` crate.
//!
//! The validator implementation was extracted so tooling and mod-author workflows
//! can reuse the same schema engine without linking the full runtime.

pub use lurek_schema::*;
