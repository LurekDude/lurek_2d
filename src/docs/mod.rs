/// Expose catalog storage and query operations for documentation entries.
pub mod catalog;
/// Expose normalized entry types for parameters, returns, and metadata.
pub mod entry;
/// Expose JSON export builders for completion, hover, and signature payloads.
pub mod export;
/// Expose quality and validation report models for doc coverage analysis.
pub mod report;
/// Re-export shared schema model types used by documentation tooling.
pub mod schema;
/// Re-export the catalog type for callers that aggregate documentation records.
pub use catalog::Catalog;
/// Re-export entry model types shared across docs tooling modules.
pub use entry::{DocEntry, ParamInfo, ReturnInfo};
/// Re-export export functions for writing documentation JSON artifacts.
pub use export::{export_all, export_completions, export_hover, export_signatures};
/// Re-export quality and validation report helpers for documentation checks.
pub use report::{quality_grade, quality_score, QualityReport, ValidationReport};
/// Re-export schema types so callers can validate field contracts consistently.
pub use schema::{FieldRule, FieldType, Schema, SchemaError, SchemaResult};
