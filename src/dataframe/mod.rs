
/// Core table types and base dataframe operations.
pub mod frame;
/// Deferred query builder and lazy execution pipeline.
pub mod lazy;
/// Query-time transforms including filter, grouping, and window ops.
pub mod query;
/// Internal pseudo-random generator for deterministic sampling.
pub mod rng;
/// CSV, JSON, and binary serializers and parsers.
pub mod serial;
/// SQL-like tokenizer, parser, and SELECT executor.
pub mod sql;
/// Columnar vectorized execution helpers and parallel operators.
pub mod vectorized;
pub use frame::{CellValue, ColRef, DataFrame, DataFrameRowIter, Database};
pub use lazy::LazyQuery;
pub use vectorized::{BinaryOp, CmpOp, ColumnStore, ReduceOp, ScalarOp, VecFrame};
