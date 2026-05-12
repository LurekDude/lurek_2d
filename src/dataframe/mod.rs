//! In-memory column-major tabular data with query, analytics, and SQL.
//!
//! Provides `DataFrame` for named-column data tables and `Database` for
//! multi-table catalogs. Used by the `lurek.dataframe` Lua module.
//! `VecFrame` adds a typed-column vectorized layer for bulk numeric transforms.

/// Column-major DataFrame and Database types.
pub mod frame;
/// Lazy query pipeline for deferred multi-step evaluation.
pub mod lazy;
/// Filter, sort, group-by, and aggregate query engine.
pub mod query;
/// Shared deterministic pseudo-random generator.
pub mod rng;
/// CSV and JSON serialization/deserialization for DataFrames.
pub mod serial;
/// SQL query parser and executor for in-memory databases.
pub mod sql;
/// Typed columnar storage and vectorized bulk operations.
pub mod vectorized;

pub use frame::{CellValue, ColRef, DataFrame, DataFrameRowIter, Database};
pub use lazy::LazyQuery;
pub use vectorized::{BinaryOp, CmpOp, ColumnStore, ReduceOp, ScalarOp, VecFrame};
