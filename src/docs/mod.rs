//! API documentation catalog, quality reporting, and schema validation for Luna2D.
//!
//! This module provides a structured way to describe, store, and validate
//! documentation for the `luna.*` Lua API surface.  Tools and tests can
//! populate a [`Catalog`] at runtime and use [`QualityReport`] to surface
//! incomplete or missing entries.
//!
//! The [`schema`] sub-module provides a lightweight runtime data-validation
//! system for game config, save-data, and mod manifest validation.
//!
//! # Sub-modules
//! | Module | Purpose |
//! |---|---|
//! | [`entry`] | [`DocEntry`], [`ParamInfo`], [`ReturnInfo`] data types |
//! | [`catalog`] | In-memory [`Catalog`] with search and filter helpers |
//! | [`report`] | [`quality_score`], [`quality_grade`], [`ValidationReport`], [`QualityReport`] |
//! | [`schema`] | [`Schema`], [`FieldRule`], [`SchemaResult`] for game-data validation |

pub mod catalog;
pub mod entry;
pub mod export;
pub mod report;
pub mod schema;

pub use catalog::Catalog;
pub use entry::{DocEntry, ParamInfo, ReturnInfo};
pub use export::{export_all, export_completions, export_hover, export_signatures};
pub use report::{quality_grade, quality_score, QualityReport, ValidationReport};
pub use schema::{FieldRule, FieldType, Schema, SchemaError, SchemaResult};
