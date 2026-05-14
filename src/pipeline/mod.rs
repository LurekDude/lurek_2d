//! Step-DAG pipeline system used by `lurek.pipeline` Lua bindings.
//! Owns pipeline definition (`dag`), individual step types (`step`), time-based
//! scheduling (`scheduler`), and result aggregation (`result`). Does not own
//! execution callbacks or Lua bindings — those live in `src/lua_api/pipeline_api.rs`.

/// DAG, `Pipeline` struct, and `ErrorMode` for dependency-ordered step execution.
pub mod dag;
/// `PipelineResult` and `PipelineStatus` produced after a run completes or aborts.
pub mod result;
/// Frame-driven delay-timer scheduler that reports steps ready to execute each tick.
pub mod scheduler;
/// `PipelineStep`, `StepStatus`, and `ErrorPolicy` defining individual work units.
pub mod step;

pub use dag::{ErrorMode, Pipeline};
pub use result::{PipelineResult, PipelineStatus};
pub use scheduler::PipelineScheduler;
pub use step::{ErrorPolicy, PipelineStep, StepStatus};
