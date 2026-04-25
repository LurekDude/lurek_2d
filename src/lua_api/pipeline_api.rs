//! `lurek.pipeline` â€” DAG-based pipeline orchestrator for composing multi-step workflows.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::log_msg;
use crate::pipeline::{ErrorMode, Pipeline, PipelineScheduler, PipelineStep, StepStatus};
use crate::runtime::log_messages::LA02_PIPELINE_CALLBACK_FAIL;

// -------------------------------------------------------------------------------
// LuaStep UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
///
/// # Fields
/// - `inner` â€” `Rc<RefCell<PipelineStep>>`.
/// - `callback_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `condition_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_error_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
///
#[derive(Clone)]
pub struct LuaStep {
    pub(crate) inner: Rc<RefCell<PipelineStep>>,
    pub(crate) callback_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) condition_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) on_error_key: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LuaStep {
    /// Creates a new [`LuaStep`] wrapping the given [`PipelineStep`].
    ///
    /// @param step PipelineStep
    ///
    /// @return Self
    pub fn new(step: PipelineStep) -> Self {
        Self {
            inner: Rc::new(RefCell::new(step)),
            callback_key: Rc::new(RefCell::new(None)),
            condition_key: Rc::new(RefCell::new(None)),
            on_error_key: Rc::new(RefCell::new(None)),
        }
    }

    /// Executes this step's callback synchronously, handling retries and status transitions
    /// @param crate parameter
    ///
    /// @return LuaResult<bool>
    pub(crate) fn execute_sync<'lua>(
        &self,
        lua: &'lua Lua,
        ctx: &LuaTable<'lua>,
        abort_on_fail: bool,
    ) -> LuaResult<bool> {
        let name = self.inner.borrow().name.clone();
        let retry_count = self.inner.borrow().retry_count;

        // Check condition gate
        if let Some(key) = self.condition_key.borrow().as_ref() {
            let cond_fn: LuaFunction = lua.registry_value(key)?;
            let should_run: bool = cond_fn.call(ctx.clone())?;
            if !should_run {
                self.inner.borrow_mut().status = StepStatus::Skipped;
                return Ok(true);
            }
        }

        // Retrieve callback
        let cb_key_opt = self.callback_key.borrow();
        let cb_key = cb_key_opt.as_ref().ok_or_else(|| {
            LuaError::runtime(format!("step '{}' has no callback registered", name))
        })?;
        let cb: LuaFunction = lua.registry_value(cb_key)?;
        drop(cb_key_opt);

        let max_attempts = retry_count + 1;
        let mut last_error: Option<LuaError> = None;

        for attempt in 0..max_attempts {
            self.inner.borrow_mut().attempt = attempt + 1;
            self.inner.borrow_mut().status = StepStatus::Running;

            match cb.call::<_, LuaValue<'_>>(ctx.clone()) {
                Ok(result) => {
                    let results: LuaTable = match ctx.get("results") {
                        Ok(t) => t,
                        Err(_) => lua.create_table()?,
                    };
                    results.set(name.clone(), result)?;
                    ctx.set("results", results)?;

                    self.inner.borrow_mut().status = StepStatus::Completed;
                    self.inner.borrow_mut().error_msg = None;
                    return Ok(true);
                }
                Err(e) => {
                    last_error = Some(e);
                    if attempt + 1 < max_attempts {
                        continue;
                    }
                }
            }
        }

        // All attempts exhausted
        let err_msg = last_error
            .as_ref()
            .map(|e| e.to_string())
            .unwrap_or_default();
        {
            let mut inner = self.inner.borrow_mut();
            inner.status = StepStatus::Failed;
            inner.error_msg = Some(err_msg.clone());
        }

        // Call per-step on_error callback if set
        if let Some(key) = self.on_error_key.borrow().as_ref() {
            let err_fn: LuaFunction = lua.registry_value(key)?;
            if let Err(e) = err_fn.call::<_, LuaValue<'_>>((name.clone(), err_msg)) {
                log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_error: {e}");
            }
        }

        if abort_on_fail {
            Ok(false)
        } else {
            Ok(true)
        }
    }
}

impl LuaUserData for LuaStep {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the unique name of this step
        /// Returns the name.
        ///
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        // -- setCallback --
        /// Stores a Lua function as the execute callback for this step
        /// Sets the callback.
        ///
        /// @param fn function
        /// @return nil
        methods.add_method("setCallback", |lua, this, cb: LuaFunction| {
            *this.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });

        // -- setCondition --
        /// Stores a Lua function (or nil) as the run-condition for this step
        /// Sets the condition.
        ///
        /// @param fn function?
        /// @return nil
        methods.add_method("setCondition", |lua, this, cond: Option<LuaFunction>| {
            *this.condition_key.borrow_mut() = match cond {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // -- setDelay --
        /// Sets the delay in seconds to wait after dependencies finish
        /// Sets the delay.
        ///
        /// @param seconds number
        /// @return nil
        methods.add_method("setDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().delay = seconds;
            Ok(())
        });

        // -- getDelay --
        /// Returns the configured delay in seconds
        /// Returns the delay.
        ///
        /// @return number
        methods.add_method("getDelay", |_, this, ()| Ok(this.inner.borrow().delay));

        // -- setTimeout --
        /// Stores a timeout in seconds in the step's metadata
        /// Sets the timeout.
        ///
        /// @param seconds number
        /// @return nil
        methods.add_method("setTimeout", |_, this, seconds: f32| {
            this.inner
                .borrow_mut()
                .metadata
                .insert("timeout".to_string(), seconds.to_string());
            Ok(())
        });

        // -- getTimeout --
        /// Returns the timeout stored in metadata, or 0.0 if unset
        /// Returns the timeout.
        ///
        /// @return number
        methods.add_method("getTimeout", |_, this, ()| {
            let v = this
                .inner
                .borrow()
                .metadata
                .get("timeout")
                .and_then(|s| s.parse::<f32>().ok())
                .unwrap_or(0.0);
            Ok(v)
        });

        // -- setRetryCount --
        /// Sets the maximum number of retry attempts on failure
        /// Sets the retry count.
        ///
        /// @param count integer
        /// @return nil
        methods.add_method("setRetryCount", |_, this, count: u32| {
            this.inner.borrow_mut().retry_count = count;
            Ok(())
        });

        // -- getRetryCount --
        /// Returns the configured retry count
        /// Returns the retry count.
        ///
        /// @return integer
        methods.add_method("getRetryCount", |_, this, ()| {
            Ok(this.inner.borrow().retry_count)
        });

        // -- setRetryDelay --
        /// Sets the delay in seconds between retry attempts
        /// Sets the retry delay.
        ///
        /// @param seconds number
        /// @return nil
        methods.add_method("setRetryDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().retry_delay = seconds;
            Ok(())
        });

        // -- setOptional --
        /// Marks whether this step is optional (downstream steps continue on failure)
        /// Sets the optional.
        ///
        /// @param optional boolean
        /// @return nil
        methods.add_method("setOptional", |_, this, optional: bool| {
            this.inner.borrow_mut().optional = optional;
            Ok(())
        });

        // -- isOptional --
        /// Returns whether this step is marked as optional
        /// Returns true if optional.
        ///
        /// @return boolean
        methods.add_method("isOptional", |_, this, ()| Ok(this.inner.borrow().optional));

        // -- setOnError --
        /// Stores a Lua function (or nil) to call if this step fails
        /// Sets the on error.
        ///
        /// @param fn function?
        /// @return nil
        methods.add_method("setOnError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // -- setData --
        /// Stores an arbitrary string value under the given key in step metadata
        /// Sets the data.
        ///
        /// @param key string
        /// @param value string
        /// @return nil
        methods.add_method("setData", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().metadata.insert(key, value);
            Ok(())
        });

        // -- getData --
        /// Retrieves a metadata value by key, returning nil if not found
        /// Returns the data.
        ///
        /// @param key string
        /// @return string?
        methods.add_method("getData", |_, this, key: String| {
            Ok(this.inner.borrow().metadata.get(&key).cloned())
        });

        // -- setTag --
        /// Sets the tag on this step for grouping and filtering
        /// Sets the tag.
        ///
        /// @param tag string
        /// @return nil
        methods.add_method("setTag", |_, this, tag: String| {
            this.inner.borrow_mut().tag = Some(tag);
            Ok(())
        });

        // -- getTag --
        /// Returns the tag on this step, or nil if unset
        /// Returns the tag.
        ///
        /// @return string?
        methods.add_method("getTag", |_, this, ()| Ok(this.inner.borrow().tag.clone()));

        // -- dependsOn --
        /// Adds a dependency on another step by name or PipelineStep. Returns self for chaining
        /// Depends on.
        ///
        /// @param dep string | Step
        /// @return Step
        methods.add_method("dependsOn", |_, this, dep: LuaValue| {
            let dep_name = match dep {
                LuaValue::String(s) => s.to_str()?.to_owned(),
                LuaValue::UserData(ud) => ud.borrow::<LuaStep>()?.inner.borrow().name.clone(),
                _ => {
                    return Err(LuaError::runtime(
                        "dependsOn: expected string or PipelineStep",
                    ))
                }
            };
            this.inner.borrow_mut().deps.push(dep_name);
            Ok(this.clone())
        });

        // -- getDependencies --
        /// Returns the list of dependency step names
        /// Returns the dependencies.
        ///
        /// @return table
        methods.add_method("getDependencies", |_, this, ()| {
            Ok(this.inner.borrow().deps.clone())
        });

        // -- getDependencyCount --
        /// Returns the number of declared dependencies
        /// Returns the dependency count.
        ///
        /// @return integer
        methods.add_method("getDependencyCount", |_, this, ()| {
            Ok(this.inner.borrow().deps.len())
        });

        // -- getStatus --
        /// Returns the current execution status as a string
        /// Returns the status.
        ///
        /// @return string
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.inner.borrow().status.as_str().to_string())
        });

        // -- getError --
        /// Returns the error message from the last failed attempt, or nil
        /// Returns the error.
        ///
        /// @return string?
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.borrow().error_msg.clone())
        });

        // -- getDuration --
        /// Returns total seconds spent executing this step
        /// Returns the duration.
        ///
        /// @return number
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration)
        });

        // -- getAttempt --
        /// Returns the number of execution attempts so far
        /// Returns the attempt.
        ///
        /// @return integer
        methods.add_method("getAttempt", |_, this, ()| Ok(this.inner.borrow().attempt));

        // -- __tostring --
        /// Returns a human-readable string for debugging
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let inner = this.inner.borrow();
            Ok(format!("PipelineStep(\"{}\")", inner.name))
        });

        // -- type --
        /// Returns the type name "PipelineStep"
        /// Type.
        ///
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LPipelineStep"));
        // -- typeOf --
        /// Returns true when the given name matches "PipelineStep" or a parent type
        /// Type of.
        ///
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "PipelineStep" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaPipeline UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Pipeline`] DAG with scheduler and Lua callback registry.
/// # Fields
/// - `inner` â€” `Rc<RefCell<Pipeline>>`.
/// - `scheduler` â€” `Rc<RefCell<PipelineScheduler>>`.
/// - `step_wrappers` â€” `Rc<RefCell<HashMap<String, LuaStep>>>`.
/// - `on_complete_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_step_complete_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_step_error_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `context_key` â€” `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `is_async` â€” `Rc<RefCell<bool>>`.
///
#[derive(Clone)]
pub struct LuaPipeline {
    pub(crate) inner: Rc<RefCell<Pipeline>>,
    pub(crate) scheduler: Rc<RefCell<PipelineScheduler>>,
    pub(crate) step_wrappers: Rc<RefCell<HashMap<String, LuaStep>>>,
    pub(crate) on_complete_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) on_step_complete_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) on_step_error_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) context_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) is_async: Rc<RefCell<bool>>,
    /// Registry key for the optional progress callback `fn(step_name, status)`.
    pub(crate) on_progress_key: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LuaPipeline {
    /// Creates a new [`LuaPipeline`] wrapping the given [`Pipeline`].
    ///
    /// @param pipeline Pipeline
    ///
    /// @return Self
    pub fn new(pipeline: Pipeline) -> Self {
        Self {
            inner: Rc::new(RefCell::new(pipeline)),
            scheduler: Rc::new(RefCell::new(PipelineScheduler::new())),
            step_wrappers: Rc::new(RefCell::new(HashMap::new())),
            on_complete_key: Rc::new(RefCell::new(None)),
            on_step_complete_key: Rc::new(RefCell::new(None)),
            on_step_error_key: Rc::new(RefCell::new(None)),
            context_key: Rc::new(RefCell::new(None)),
            is_async: Rc::new(RefCell::new(false)),
            on_progress_key: Rc::new(RefCell::new(None)),
        }
    }

    /// Creates a [`LuaPipeline`] from pre-built pipeline and wrapper maps (used by deserialisers).
    /// @param pipeline_rc Rc<RefCell<Pipeline>>
    /// @param wrappers_rc Rc<RefCell<HashMap<String, LuaStep>>>
    ///
    /// @return Self
    pub fn from_parts(
        pipeline_rc: Rc<RefCell<Pipeline>>,
        wrappers_rc: Rc<RefCell<HashMap<String, LuaStep>>>,
    ) -> Self {
        Self {
            inner: pipeline_rc,
            scheduler: Rc::new(RefCell::new(PipelineScheduler::new())),
            step_wrappers: wrappers_rc,
            on_complete_key: Rc::new(RefCell::new(None)),
            on_step_complete_key: Rc::new(RefCell::new(None)),
            on_step_error_key: Rc::new(RefCell::new(None)),
            context_key: Rc::new(RefCell::new(None)),
            is_async: Rc::new(RefCell::new(false)),
            on_progress_key: Rc::new(RefCell::new(None)),
        }
    }
}

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Converts a `PipelineResult` to a Lua result table for the `run` return value.
/// @param crate parameter
///
/// LuaResult<LuaTable<'lua>>
///
pub(crate) fn pipeline_result_to_lua<'lua>(
    lua: &'lua Lua,
    result: &crate::pipeline::PipelineResult,
) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    let completed = lua.create_table()?;
    for (i, name) in result.completed.iter().enumerate() {
        completed.set(i + 1, name.clone())?;
    }
    let failed = lua.create_table()?;
    for (i, name) in result.failed.iter().enumerate() {
        failed.set(i + 1, name.clone())?;
    }
    let skipped = lua.create_table()?;
    for (i, name) in result.skipped.iter().enumerate() {
        skipped.set(i + 1, name.clone())?;
    }
    let cancelled = lua.create_table()?;
    for (i, name) in result.cancelled.iter().enumerate() {
        cancelled.set(i + 1, name.clone())?;
    }
    let errors = lua.create_table()?;
    for (i, (name, msg)) in result.errors.iter().enumerate() {
        let entry = lua.create_table()?;
        entry.set(1, name.clone())?;
        entry.set(2, msg.clone())?;
        errors.set(i + 1, entry)?;
    }
    t.set("success", result.is_success())?;
    t.set("completed", completed)?;
    t.set("failed", failed)?;
    t.set("skipped", skipped)?;
    t.set("cancelled", cancelled)?;
    t.set("totalDuration", result.total_duration)?;
    t.set("errors", errors)?;
    Ok(t)
}

/// Cancels all steps in `order` that are still pending.
///
/// @param crate parameter
///
pub(crate) fn cancel_remaining_steps(wrappers: &HashMap<String, LuaStep>, order: &[String]) {
    for name in order {
        if let Some(w) = wrappers.get(name) {
            if w.inner.borrow().status == StepStatus::Pending {
                w.inner.borrow_mut().status = StepStatus::Cancelled;
            }
        }
    }
}

/// Fires the per-step pipeline callbacks based on the step's terminal status.
///
/// @param crate parameter
///
pub(crate) fn fire_step_callbacks<'lua>(
    lua: &'lua Lua,
    this: &LuaPipeline,
    step_name: &str,
    ctx: &LuaTable<'lua>,
    wrapper: &LuaStep,
) -> LuaResult<()> {
    let step_status = wrapper.inner.borrow().status.clone();
    if step_status == StepStatus::Completed {
        if let Some(key) = this.on_step_complete_key.borrow().as_ref() {
            let f: LuaFunction = lua.registry_value(key)?;
            if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.to_string(), ctx.clone())) {
                log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_complete: {e}");
            }
        }
    } else if step_status == StepStatus::Failed {
        if let Some(key) = this.on_step_error_key.borrow().as_ref() {
            let f: LuaFunction = lua.registry_value(key)?;
            let err = wrapper.inner.borrow().error_msg.clone().unwrap_or_default();
            if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.to_string(), err)) {
                log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_error: {e}");
            }
        }
    }
    // Always fire the on_progress callback regardless of step outcome.
    if let Some(key) = this.on_progress_key.borrow().as_ref() {
        let status_str = format!("{:?}", step_status).to_lowercase();
        let f: LuaFunction = lua.registry_value(key)?;
        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.to_string(), status_str)) {
            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_progress: {e}");
        }
    }
    Ok(())
}

/// Finalises a pipeline run: collects the `PipelineResult`, converts it to a Lua table,
///
/// @param crate parameter
///
/// LuaResult<LuaTable<'lua>>
///
pub(crate) fn finalize_pipeline_result<'lua>(
    lua: &'lua Lua,
    this: &LuaPipeline,
    elapsed: f32,
) -> LuaResult<LuaTable<'lua>> {
    let step_statuses: HashMap<String, (StepStatus, Option<String>)> = this
        .step_wrappers
        .borrow()
        .iter()
        .map(|(k, v)| {
            let inner = v.inner.borrow();
            (k.clone(), (inner.status.clone(), inner.error_msg.clone()))
        })
        .collect();
    let result = this.inner.borrow().collect_result(&step_statuses, elapsed);
    let result_tbl = pipeline_result_to_lua(lua, &result)?;
    if let Some(key) = this.on_complete_key.borrow().as_ref() {
        let f: LuaFunction = lua.registry_value(key)?;
        if let Err(e) = f.call::<_, LuaValue<'_>>(result_tbl.clone()) {
            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_complete: {e}");
        }
    }
    Ok(result_tbl)
}

// -------------------------------------------------------------------------------
// LuaPipeline impl LuaUserData
// -------------------------------------------------------------------------------

impl LuaUserData for LuaPipeline {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addStep --
        /// Adds a step to the pipeline. Returns self for chaining.
        /// @param step Step
        /// @return Pipeline
        methods.add_method("addStep", |_, this, step_ud: LuaAnyUserData| {
            let step = step_ud.borrow::<LuaStep>()?.clone();
            let step_def = step.inner.borrow().clone();
            this.inner
                .borrow_mut()
                .add_step(step_def)
                .map_err(LuaError::runtime)?;
            let name = step.inner.borrow().name.clone();
            this.step_wrappers.borrow_mut().insert(name, step);
            Ok(this.clone())
        });

        // -- removeStep --
        /// Removes a step from the pipeline by name.
        /// @param name string
        /// @return nil
        methods.add_method("removeStep", |_, this, name: String| {
            this.inner.borrow_mut().remove_step(&name);
            this.step_wrappers.borrow_mut().remove(&name);
            Ok(())
        });

        // -- getStep --
        /// Returns the LuaStep wrapper for the named step, or nil.
        /// @param name string
        /// @return Step?
        methods.add_method("getStep", |_, this, name: String| {
            Ok(this.step_wrappers.borrow().get(&name).cloned())
        });

        // -- getSteps --
        /// Returns a Lua array of all step wrappers in the pipeline.
        /// @return table
        methods.add_method("getSteps", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, wrapper) in this.step_wrappers.borrow().values().enumerate() {
                t.set(i + 1, wrapper.clone())?;
            }
            Ok(t)
        });

        // -- getStepCount --
        /// Returns the total number of steps.
        /// @return integer
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });

        // -- getStepsByTag --
        /// Returns a Lua array of all steps whose tag matches the given string.
        /// @param tag string
        /// @return table
        methods.add_method("getStepsByTag", |lua, this, tag: String| {
            let t = lua.create_table()?;
            let mut i = 1usize;
            for wrapper in this.step_wrappers.borrow().values() {
                if wrapper.inner.borrow().tag.as_deref() == Some(&tag) {
                    t.set(i, wrapper.clone())?;
                    i += 1;
                }
            }
            Ok(t)
        });

        // -- clear --
        /// Clears all steps from the pipeline.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.step_wrappers.borrow_mut().clear();
            Ok(())
        });

        // -- validate --
        /// Validates the pipeline DAG. Returns (ok, error_array).
        /// boolean, table
        /// @return nil
        methods.add_method("validate", |lua, this, ()| {
            let (ok, errs) = this.inner.borrow().validate();
            let t = lua.create_table()?;
            for (i, e) in errs.iter().enumerate() {
                t.set(i + 1, e.clone())?;
            }
            Ok((ok, t))
        });

        // -- getExecutionOrder --
        /// Returns the topological execution order as an array of step names.
        /// table?, string?
        /// @return nil
        methods.add_method("getExecutionOrder", |lua, this, ()| {
            match this.inner.borrow().get_execution_order() {
                Ok(order) => {
                    let t = lua.create_table()?;
                    for (i, n) in order.iter().enumerate() {
                        t.set(i + 1, n.clone())?;
                    }
                    Ok((Some(t), None::<String>))
                }
                Err(e) => Ok((None, Some(e))),
            }
        });

        // -- getParallelGroups --
        /// Returns parallel execution groups as a nested array of step name arrays.
        /// table?, string?
        /// @return nil
        methods.add_method("getParallelGroups", |lua, this, ()| {
            match this.inner.borrow().get_parallel_groups() {
                Ok(groups) => {
                    let outer = lua.create_table()?;
                    for (i, group) in groups.iter().enumerate() {
                        let inner_t = lua.create_table()?;
                        for (j, n) in group.iter().enumerate() {
                            inner_t.set(j + 1, n.clone())?;
                        }
                        outer.set(i + 1, inner_t)?;
                    }
                    Ok((Some(outer), None::<String>))
                }
                Err(e) => Ok((None, Some(e))),
            }
        });

        // -- run --
        /// Executes the pipeline synchronously in topological order.
        /// @param context table?
        /// @return table
        methods.add_method("run", |lua, this, context: Option<LuaTable>| {
            let order = this
                .inner
                .borrow()
                .get_execution_order()
                .map_err(LuaError::runtime)?;
            this.inner.borrow_mut().reset();
            for w in this.step_wrappers.borrow().values() {
                w.inner.borrow_mut().reset();
            }
            let ctx = context.unwrap_or(lua.create_table()?);
            ctx.set("results", lua.create_table()?)?;
            let abort_on_fail = this.inner.borrow().error_mode == ErrorMode::Abort;
            let start = std::time::Instant::now();
            'steps: for step_name in &order {
                let wrapper = match this.step_wrappers.borrow().get(step_name).cloned() {
                    Some(w) => w,
                    None => continue,
                };
                let statuses: HashMap<String, StepStatus> = this
                    .step_wrappers
                    .borrow()
                    .iter()
                    .map(|(k, v)| (k.clone(), v.inner.borrow().status.clone()))
                    .collect();
                match this.inner.borrow().are_deps_satisfied(step_name, &statuses) {
                    Ok(true) => {}
                    Ok(false) => {
                        if abort_on_fail {
                            cancel_remaining_steps(&this.step_wrappers.borrow(), &order);
                            break 'steps;
                        } else {
                            wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                            continue;
                        }
                    }
                    Err(_) => {
                        wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                        continue;
                    }
                }
                let succeeded = wrapper.execute_sync(lua, &ctx, abort_on_fail)?;
                fire_step_callbacks(lua, this, step_name, &ctx, &wrapper)?;
                if !succeeded {
                    cancel_remaining_steps(&this.step_wrappers.borrow(), &order);
                    break;
                }
            }
            finalize_pipeline_result(lua, this, start.elapsed().as_secs_f32())
        });

        // -- runAsync --
        /// Starts an async pipeline run. Steps are executed one-per-frame via update(dt).
        /// @param context table?
        /// @return nil
        methods.add_method("runAsync", |lua, this, context: Option<LuaTable>| {
            this.inner.borrow_mut().reset();
            for wrapper in this.step_wrappers.borrow().values() {
                wrapper.inner.borrow_mut().reset();
            }

            let ctx = match context {
                Some(c) => c,
                None => lua.create_table()?,
            };
            let results_table = lua.create_table()?;
            ctx.set("results", results_table)?;

            *this.context_key.borrow_mut() = Some(lua.create_registry_value(ctx)?);
            *this.is_async.borrow_mut() = true;

            let pipeline = this.inner.borrow();
            this.scheduler.borrow_mut().start(&pipeline);

            // Mark zero-dep steps as Waiting
            let wrappers = this.step_wrappers.borrow();
            for (name, wrapper) in wrappers.iter() {
                let has_deps = !pipeline
                    .get_step(name)
                    .map(|s| s.deps.is_empty())
                    .unwrap_or(true);
                if !has_deps {
                    wrapper.inner.borrow_mut().status = StepStatus::Waiting;
                    this.scheduler
                        .borrow_mut()
                        .mark_step_waiting(name, &pipeline);
                }
            }

            Ok(())
        });

        // -- update --
        /// Advances the async pipeline by one tick. Returns true when all steps are done.
        /// @param dt number
        /// @return boolean
        methods.add_method("update", |lua, this, dt: f32| {
            if !*this.is_async.borrow() {
                return Ok(false);
            }
            let ctx: LuaTable = {
                let key_opt = this.context_key.borrow();
                match key_opt.as_ref() {
                    Some(k) => lua.registry_value(k)?,
                    None => return Ok(false),
                }
            };
            let abort_on_fail = this.inner.borrow().error_mode == ErrorMode::Abort;
            let ready_names: Vec<String> = {
                let pipeline = this.inner.borrow();
                this.scheduler.borrow_mut().update(dt, &pipeline)
            };
            for step_name in ready_names {
                let wrapper = match this.step_wrappers.borrow().get(&step_name).cloned() {
                    Some(w) => w,
                    None => continue,
                };
                let succeeded = wrapper.execute_sync(lua, &ctx, abort_on_fail)?;
                fire_step_callbacks(lua, this, &step_name, &ctx, &wrapper)?;
                if !succeeded {
                    this.step_wrappers.borrow().values().for_each(|w| {
                        let s = w.inner.borrow().status.clone();
                        if s == StepStatus::Pending || s == StepStatus::Waiting {
                            w.inner.borrow_mut().status = StepStatus::Cancelled;
                        }
                    });
                    *this.is_async.borrow_mut() = false;
                    this.scheduler.borrow_mut().reset();
                    return finalize_pipeline_result(lua, this, this.scheduler.borrow().elapsed)
                        .map(|_| true);
                }
                let statuses: HashMap<String, StepStatus> = this
                    .step_wrappers
                    .borrow()
                    .iter()
                    .map(|(k, v)| (k.clone(), v.inner.borrow().status.clone()))
                    .collect();
                for (name, w) in this.step_wrappers.borrow().iter() {
                    if w.inner.borrow().status != StepStatus::Pending {
                        continue;
                    }
                    let pipeline = this.inner.borrow();
                    if let Ok(true) = pipeline.are_deps_satisfied(name, &statuses) {
                        w.inner.borrow_mut().status = StepStatus::Waiting;
                        this.scheduler
                            .borrow_mut()
                            .mark_step_waiting(name, &pipeline);
                    }
                }
            }
            let all_done = this.step_wrappers.borrow().values().all(|w| {
                matches!(
                    w.inner.borrow().status,
                    StepStatus::Completed
                        | StepStatus::Failed
                        | StepStatus::Skipped
                        | StepStatus::Cancelled
                )
            });
            if all_done {
                *this.is_async.borrow_mut() = false;
                this.scheduler.borrow_mut().reset();
                finalize_pipeline_result(lua, this, this.scheduler.borrow().elapsed).map(|_| true)
            } else {
                Ok(false)
            }
        });

        // -- cancel --
        /// Cancels all pending and waiting steps.
        /// @return nil
        methods.add_method("cancel", |_, this, ()| {
            let wrappers = this.step_wrappers.borrow();
            for w in wrappers.values() {
                let s = w.inner.borrow().status.clone();
                if s == StepStatus::Pending || s == StepStatus::Waiting {
                    w.inner.borrow_mut().status = StepStatus::Cancelled;
                }
            }
            Ok(())
        });

        // -- reset --
        /// Resets all step states and clears the async context.
        /// @return nil
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            for w in this.step_wrappers.borrow().values() {
                w.inner.borrow_mut().reset();
            }
            *this.context_key.borrow_mut() = None;
            *this.is_async.borrow_mut() = false;
            this.scheduler.borrow_mut().reset();
            Ok(())
        });

        // -- isRunning --
        /// Returns true if the pipeline is currently running asynchronously.
        /// @return boolean
        methods.add_method("isRunning", |_, this, ()| Ok(*this.is_async.borrow()));

        // -- isComplete --
        /// Returns true if all steps have reached a terminal state.
        /// @return boolean
        methods.add_method("isComplete", |_, this, ()| {
            let wrappers = this.step_wrappers.borrow();
            let all_done = wrappers.values().all(|w| {
                matches!(
                    w.inner.borrow().status,
                    StepStatus::Completed
                        | StepStatus::Failed
                        | StepStatus::Skipped
                        | StepStatus::Cancelled
                )
            });
            Ok(all_done)
        });

        // -- setErrorMode --
        /// Sets the pipeline error mode: "abort" or "continue".
        /// @param mode string
        /// @return nil
        methods.add_method("setErrorMode", |_, this, mode: String| {
            let em = ErrorMode::from_str_lua(&mode).map_err(LuaError::runtime)?;
            this.inner.borrow_mut().error_mode = em;
            Ok(())
        });

        // -- getErrorMode --
        /// Returns the current error mode as a string.
        /// @return string
        methods.add_method("getErrorMode", |_, this, ()| {
            Ok(this.inner.borrow().error_mode.as_str().to_string())
        });

        // -- getResult --
        /// Returns the current result table built from step states, or nil.
        /// @return table?
        methods.add_method("getResult", |lua, this, ()| {
            if this.step_wrappers.borrow().is_empty() {
                return Ok(None);
            }
            let elapsed = this.scheduler.borrow().elapsed;
            let step_statuses: HashMap<String, (StepStatus, Option<String>)> = this
                .step_wrappers
                .borrow()
                .iter()
                .map(|(k, v)| {
                    let i = v.inner.borrow();
                    (k.clone(), (i.status.clone(), i.error_msg.clone()))
                })
                .collect();
            let result = this.inner.borrow().collect_result(&step_statuses, elapsed);
            Ok(Some(pipeline_result_to_lua(lua, &result)?))
        });

        // -- getContext --
        /// Returns the stored async context table, or nil.
        /// @return table?
        methods.add_method("getContext", |lua, this, ()| {
            let key_opt = this.context_key.borrow();
            match key_opt.as_ref() {
                Some(k) => {
                    let t: LuaTable = lua.registry_value(k)?;
                    Ok(Some(t))
                }
                None => Ok(None),
            }
        });

        // -- setOnComplete --
        /// Sets the callback to invoke when the pipeline completes.
        /// @param fn function?
        /// @return nil
        methods.add_method("setOnComplete", |lua, this, cb: Option<LuaFunction>| {
            *this.on_complete_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // -- setOnStepComplete --
        /// Sets the callback to invoke each time a step completes successfully.
        /// @param fn function?
        /// @return nil
        methods.add_method("setOnStepComplete", |lua, this, cb: Option<LuaFunction>| {
            *this.on_step_complete_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // -- setOnStepError --
        /// Sets the callback to invoke each time a step fails.
        /// @param fn function?
        /// @return nil
        methods.add_method("setOnStepError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_step_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // -- getName --
        /// Returns the pipeline's name.
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        // -- setName --
        /// Sets the pipeline's name.
        /// @param name string
        /// @return nil
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().name = name;
            Ok(())
        });

        // -- toTable --
        /// Serialises the pipeline definition to a Lua table (no callbacks).
        /// @return table
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            let pipeline = this.inner.borrow();
            t.set("name", pipeline.name.clone())?;
            t.set("errorMode", pipeline.error_mode.as_str())?;

            let steps_t = lua.create_table()?;
            let wrappers = this.step_wrappers.borrow();
            let mut i = 1usize;
            for (name, wrapper) in wrappers.iter() {
                let st = lua.create_table()?;
                let inner = wrapper.inner.borrow();
                st.set("name", name.clone())?;
                let deps_t = lua.create_table()?;
                for (j, d) in inner.deps.iter().enumerate() {
                    deps_t.set(j + 1, d.clone())?;
                }
                st.set("deps", deps_t)?;
                st.set("delay", inner.delay)?;
                st.set("optional", inner.optional)?;
                st.set("retryCount", inner.retry_count)?;
                st.set("retryDelay", inner.retry_delay)?;
                if let Some(ref tag) = inner.tag {
                    st.set("tag", tag.clone())?;
                }
                steps_t.set(i, st)?;
                i += 1;
            }
            t.set("steps", steps_t)?;
            Ok(t)
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let inner = this.inner.borrow();
            Ok(format!(
                "Pipeline(\"{}\", {} steps)",
                inner.name,
                inner.get_step_count()
            ))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LPipeline"));

        // -- addConditional --
        /// Adds a step with a runtime condition guard: the step is skipped when `when_fn()` returns false.
        ///
        /// This is a convenience wrapper equivalent to `addStep` + `:setCondition` chained.
        /// @param name string
        /// @param deps table -- array of dependency step names
        /// @param fn function -- step body
        /// @param when_fn function -- returns bool; false skips the step
        /// @return Pipeline
        methods.add_method(
            "addConditional",
            |lua,
             this,
             (name, deps_tbl, cb, cond): (String, LuaTable, LuaFunction, LuaFunction)| {
                let dep_names: Vec<String> = deps_tbl
                    .sequence_values::<String>()
                    .collect::<LuaResult<Vec<_>>>()?;
                let mut step = PipelineStep::new(name.clone());
                step.deps = dep_names;
                let wrapper = LuaStep::new(step.clone());
                *wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
                *wrapper.condition_key.borrow_mut() = Some(lua.create_registry_value(cond)?);
                this.inner
                    .borrow_mut()
                    .add_step(step)
                    .map_err(LuaError::runtime)?;
                this.step_wrappers.borrow_mut().insert(name, wrapper);
                Ok(this.clone())
            },
        );

        // -- onProgress --
        /// Registers a callback invoked after every step with `(step_name, status)`.
        ///
        /// `status` is a lowercase string: `"completed"`, `"failed"`, or `"skipped"`.
        /// @param fn function
        /// @return nil
        methods.add_method("onProgress", |lua, this, cb: LuaFunction| {
            *this.on_progress_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });

        // -- toAscii --
        /// Returns a multi-line ASCII string visualising the pipeline DAG.
        ///
        /// Each level shows steps that can run in parallel, with their dependencies.
        /// @return string
        methods.add_method("toAscii", |_, this, ()| {
            Ok(this.inner.borrow().to_ascii_diagram())
        });

        // -- addSubPipeline --
        /// Inlines all steps from `sub_pipeline` into this pipeline, prefixing
        /// their names with `alias/`.  Entry-point steps in the sub-pipeline
        /// (those with no sub-pipeline-internal dependencies) are made to depend
        /// on every step name listed in `outer_deps`.
        ///
        /// This lets you compose large init or loading sequences from reusable
        /// named sub-pipelines without manually cross-wiring every boundary step.
        ///
        /// # Usage
        /// ```lua
        /// -- Build a sub-pipeline for audio loading.
        /// local audio_pl = lurek.pipeline.new("audio")
        /// audio_pl:addStep("init_mixer")
        /// audio_pl:addStep("load_tracks", { deps = {"init_mixer"} })
        ///
        /// -- Inline into a main pipeline, running after "boot".
        /// main_pl:addSubPipeline(audio_pl, "audio", { "boot" })
        /// -- Results in steps named "audio/init_mixer" (dep: "boot")
        /// --   and "audio/load_tracks" (dep: "audio/init_mixer")
        /// ```
        /// @param sub_pipeline Pipeline
        /// @param alias string
        /// @param outer_deps table?  â€” Array of step names in this pipeline to depend on.
        /// @return nil
        methods.add_method(
            "addSubPipeline",
            |_, this, (sub_ud, alias, deps_tbl): (mlua::AnyUserData, String, Option<mlua::Table>)| {
                let sub_ref = sub_ud.borrow::<LuaPipeline>().map_err(mlua::Error::external)?;
                let sub_clone = sub_ref.inner.borrow().clone();
                let outer_deps: Vec<String> = if let Some(tbl) = deps_tbl {
                    tbl.pairs::<mlua::Value, String>()
                        .filter_map(|r| r.ok().map(|(_, v)| v))
                        .collect()
                } else {
                    Vec::new()
                };
                this.inner
                    .borrow_mut()
                    .add_sub_pipeline(sub_clone, &alias, outer_deps)
                    .map_err(mlua::Error::external)?;
                Ok(())
            },
        );

        // -- typeOf --
        /// Returns the type identifier string of this pipeline stage object.
        ///
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Pipeline" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.pipeline` API table with the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newStep --
    /// Creates a new pipeline step with the given name and optional callback.
    /// @param name string
    /// @param fn function?
    /// @return Step
    tbl.set(
        "newStep",
        lua.create_function(|lua, (name, callback): (String, Option<LuaFunction>)| {
            let step = PipelineStep::new(name);
            let wrapper = LuaStep::new(step);
            if let Some(cb) = callback {
                *wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            }
            Ok(wrapper)
        })?,
    )?;

    // -- newPipeline --
    /// Creates a new empty pipeline with the given name (defaults to "pipeline").
    /// @param name string?
    /// @return Pipeline
    tbl.set(
        "newPipeline",
        lua.create_function(|_, name: Option<String>| {
            let pipeline = Pipeline::new(name.unwrap_or_else(|| "pipeline".to_string()));
            Ok(LuaPipeline::new(pipeline))
        })?,
    )?;

    // -- fromTable --
    /// Deserialises a pipeline from a definition table.
    /// @param def table
    /// @return Pipeline
    tbl.set(
        "fromTable",
        lua.create_function(|lua, def: LuaTable| {
            let name: Option<String> = def.get("name")?;
            let error_mode_str: Option<String> = def.get("errorMode")?;

            let mut pipeline = Pipeline::new(name.unwrap_or_else(|| "pipeline".to_string()));
            if let Some(ref mode) = error_mode_str {
                pipeline.error_mode = match mode.as_str() {
                    "continue" => ErrorMode::Continue,
                    _ => ErrorMode::Abort,
                };
            }

            let pipeline_rc = Rc::new(RefCell::new(pipeline));
            let wrappers_rc: Rc<RefCell<HashMap<String, LuaStep>>> =
                Rc::new(RefCell::new(HashMap::new()));

            if let Ok(steps_t) = def.get::<_, LuaTable<'_>>("steps") {
                for pair in steps_t.sequence_values::<LuaTable<'_>>() {
                    let st: LuaTable = pair?;
                    let sname: String = st.get("name")?;
                    let mut step = PipelineStep::new(sname.clone());

                    if let Ok(deps_t) = st.get::<_, LuaTable<'_>>("deps") {
                        for dep_v in deps_t.sequence_values::<String>() {
                            step.deps.push(dep_v?);
                        }
                    }
                    if let Ok(delay) = st.get::<_, f32>("delay") {
                        step.delay = delay;
                    }
                    if let Ok(optional) = st.get::<_, bool>("optional") {
                        step.optional = optional;
                    }
                    if let Ok(rc) = st.get::<_, u32>("retryCount") {
                        step.retry_count = rc;
                    }
                    if let Ok(rd) = st.get::<_, f32>("retryDelay") {
                        step.retry_delay = rd;
                    }
                    if let Ok(tag) = st.get::<_, String>("tag") {
                        step.tag = Some(tag);
                    }

                    let wrapper = LuaStep::new(step.clone());

                    if let Ok(cb) = st.get::<_, LuaFunction<'_>>("fn") {
                        *wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
                    }

                    pipeline_rc
                        .borrow_mut()
                        .add_step(step)
                        .map_err(LuaError::runtime)?;
                    wrappers_rc.borrow_mut().insert(sname, wrapper);
                }
            }

            Ok(LuaPipeline::from_parts(pipeline_rc, wrappers_rc))
        })?,
    )?;

    /// Namespace containing the pipeline API module.
    /// Provides pipeline task scheduling and sequencing workflows.
    lurek.set("pipeline", tbl)?;
    Ok(())
}
