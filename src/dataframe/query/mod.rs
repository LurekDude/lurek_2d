//! Query engine for [`DataFrame`].
//!
//! Split into focused sub-modules:
//!
//! | Sub-module    | Responsibility |
//! |---------------|----------------|
//! | [`filter`]    | Filter, sort, join, aggregation, sampling, nil-handling, batch helpers |
//! | [`window`]    | Rolling window ops and derived columns (rank, pct_change, cumsum) |
//! | [`grouping`]  | Group aggregation, pivot tables, and correlation |
//! | [`analytics`] | Normalisation, outlier detection, mode, entropy, and `percentile` |

pub mod analytics;
pub mod filter;
pub mod grouping;
pub mod window;

pub use analytics::percentile;
