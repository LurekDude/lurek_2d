//! Own query-time transformation sub-modules that extend `DataFrame` with filtering, grouping,
//! analytics, and window operations. Each sub-module adds methods via a separate `impl DataFrame`
//! block so they can be read and tested in isolation. No SQL parsing lives here; that is in
//! `../sql.rs`. No serialization lives here; that is in `../serial.rs`.
//! Business logic stays inside these files; bindings live in `src/lua_api/dataframe_api.rs`.

/// Statistical and distribution-oriented query helpers.
pub mod analytics;
/// Row filtering, sorting, joins, and sampling helpers.
pub mod filter;
/// Grouped aggregation, pivoting, and correlation helpers.
pub mod grouping;
/// Rolling and ranking window computations.
pub mod window;
pub use analytics::percentile;
