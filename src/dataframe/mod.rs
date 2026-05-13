//! Own tabular data module. Provides column-major frame storage, typed cell values, lazy
//! deferred query pipelines, grouped and window analytics, CSV/JSON/binary serialization,
//! a SQL-like SELECT layer, and rayon-backed vectorized column arithmetic. External callers
//! reach this module through `src/lua_api/dataframe_api.rs`. No graphics or audio logic here.

pub mod frame;
pub mod lazy;
pub mod query;
pub mod rng;
pub mod serial;
pub mod sql;
pub mod vectorized;
pub use frame::{CellValue, ColRef, DataFrame, DataFrameRowIter, Database};
pub use lazy::LazyQuery;
pub use vectorized::{BinaryOp, CmpOp, ColumnStore, ReduceOp, ScalarOp, VecFrame};
