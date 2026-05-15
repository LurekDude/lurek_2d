//! - Aggregate documentation infrastructure: catalog, entry models, export, reporting, and schema.
//! - Re-export primary types so callers can import from the top-level docs module.
//! - Support the doc generation pipeline and IDE tooling data flow.

/// Expose source-derived Lua binding snapshots and drift reports.
pub mod bindings;
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
/// Re-export source-derived binding snapshot and validation types for docs tooling.
pub use bindings::{
	default_binding_code_snapshot_path, default_binding_docstring_snapshot_path,
	default_binding_validation_report_path, export_binding_snapshot, export_binding_validation,
	extract_binding_snapshot_from_code, extract_binding_snapshot_from_docstrings,
	validate_binding_snapshots, validate_current_binding_docstrings, BindingCountMismatch,
	BindingEntry, BindingIndexedBoolMismatch, BindingIndexedStringMismatch, BindingParam,
	BindingParameterOrderMismatch, BindingReturn, BindingSnapshot, BindingValidationReport,
};
/// Re-export entry model types shared across docs tooling modules.
pub use entry::{DocEntry, ParamInfo, ReturnInfo};
/// Re-export export functions for writing documentation JSON artifacts.
pub use export::{export_all, export_completions, export_hover, export_signatures};
/// Re-export quality and validation report helpers for documentation checks.
pub use report::{quality_grade, quality_score, QualityReport, ValidationReport};
/// Re-export schema types so callers can validate field contracts consistently.
pub use schema::{FieldRule, FieldType, Schema, SchemaError, SchemaResult};
