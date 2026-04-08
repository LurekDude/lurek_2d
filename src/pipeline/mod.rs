//! DAG-based pipeline orchestrator for composing multi-step workflows.
//!
//! Provides `Pipeline`, `PipelineStep`, `PipelineResult`, and `PipelineScheduler`
//! as pure-Rust types. The Lua binding lives in `crate::lua_api::pipeline_api`.
//!
//! Architecture: Tier 2. Depends only on `crate::math` and `crate::engine`.

/// DAG node and edge types; the `Pipeline` container and its `run` / `run_async` entry points.
pub mod dag;
/// `PipelineResult` and `PipelineStatus` returned after pipeline execution.
pub mod result;
/// `PipelineScheduler` — time-based dispatch that triggers pipelines on tick or interval.
pub mod scheduler;
/// `PipelineStep` definition, `StepStatus`, and `ErrorPolicy` for individual pipeline nodes.
pub mod step;

pub use dag::{ErrorMode, Pipeline};
pub use result::{PipelineResult, PipelineStatus};
pub use scheduler::PipelineScheduler;
pub use step::{ErrorPolicy, PipelineStep, StepStatus};
