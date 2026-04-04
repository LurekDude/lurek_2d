//! DAG-based pipeline orchestrator for composing multi-step workflows.
//!
//! Provides `Pipeline`, `PipelineStep`, `PipelineResult`, and `PipelineScheduler`
//! as pure-Rust types. The Lua binding lives in `crate::lua_api::pipeline_api`.
//!
//! Architecture: Tier 2. Depends only on `crate::math` and `crate::engine`.
//! Does not import `mlua` or any other Tier-2 crate module.

pub mod dag;
pub mod result;
pub mod scheduler;
pub mod step;

pub use dag::{ErrorMode, Pipeline};
pub use result::{PipelineResult, PipelineStatus};
pub use scheduler::PipelineScheduler;
pub use step::{ErrorPolicy, PipelineStep, StepStatus};
