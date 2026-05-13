//! Scope: Query engine sub-modules for filtering, grouping, analytics, and windowing.
//! This file re-exports the public sub-modules and the percentile helper.
//! It owns query implementation organization across filter, grouping, analytics, and window.

pub mod analytics;
pub mod filter;
pub mod grouping;
pub mod window;

pub use analytics::percentile;
