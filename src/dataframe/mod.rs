//! In-memory column-major tables.

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
