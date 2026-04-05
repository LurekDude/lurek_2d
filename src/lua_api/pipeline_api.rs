//! Registers the `luna.pipeline.*` DAG pipeline orchestrator API.
//!
//! Exposes `LuaStep` and `LuaPipeline` UserData types wrapping `crate::pipeline`
//! with Lua callback dispatch for step execution.
//!
//! Primary entry point: `register()`.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::engine::log_messages::LA02_PIPELINE_CALLBACK_FAIL;
#[allow(unused_imports)]
use crate::log_msg;

use crate::pipeline::{
    ErrorMode, Pipeline, PipelineScheduler, PipelineStep, StepStatus,
};

// ---------------------------------------------------------------------------
// LuaStep wrapper
// ---------------------------------------------------------------------------

/// Lua wrapper around a single [`PipelineStep`], plus Lua callback registry keys.
///
/// # Fields
/// - `inner` — `Rc<RefCell<PipelineStep>>`.
/// - `callback_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `condition_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_error_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
#[derive(Clone)]
struct LuaStep {
    /// The underlying pipeline step definition.
    inner: Rc<RefCell<PipelineStep>>,
    /// Registry key for the step's execute callback.
    callback_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Registry key for the optional run-condition callback (returns bool).
    condition_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Registry key for the optional per-step error callback.
    on_error_key: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LunaType for LuaStep {
    const TYPE_NAME: &'static str = "PipelineStep";
    const TYPE_HIERARCHY: &'static [&'static str] = &["PipelineStep", "Object"];
}

impl LuaUserData for LuaStep {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // --- Identity ---

        /// Returns the unique name of this step.
        ///
        /// # Returns
        /// `String`
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        // --- Callback config ---

        /// Stores a Lua function as the execute callback for this step.
        ///
        /// # Parameters
        /// - `fn` — `function`.
        methods.add_method("setCallback", |lua, this, cb: LuaFunction| {
            *this.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });

        /// Stores a Lua function (or nil) as the run-condition for this step.
        ///
        /// # Parameters
        /// - `fn` — `function | nil`.
        methods.add_method("setCondition", |lua, this, cond: Option<LuaFunction>| {
            *this.condition_key.borrow_mut() = match cond {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // --- Timing ---

        /// Sets the delay (in seconds) to wait after dependencies finish.
        ///
        /// # Parameters
        /// - `seconds` — `f32`.
        methods.add_method("setDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().delay = seconds;
            Ok(())
        });

        /// Returns the configured delay in seconds.
        ///
        /// # Returns
        /// `f32`
        methods.add_method("getDelay", |_, this, ()| {
            Ok(this.inner.borrow().delay)
        });

        /// Stores a timeout (in seconds) in the step's metadata.
        ///
        /// # Parameters
        /// - `seconds` — `f32`.
        methods.add_method("setTimeout", |_, this, seconds: f32| {
            this.inner
                .borrow_mut()
                .metadata
                .insert("timeout".to_string(), seconds.to_string());
            Ok(())
        });

        /// Returns the timeout stored in metadata, or 0.0 if unset.
        ///
        /// # Returns
        /// `f32`
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

        // --- Retry ---

        /// Sets the maximum number of retry attempts on failure.
        ///
        /// # Parameters
        /// - `count` — `u32`.
        methods.add_method("setRetryCount", |_, this, count: u32| {
            this.inner.borrow_mut().retry_count = count;
            Ok(())
        });

        /// Returns the configured retry count.
        ///
        /// # Returns
        /// `u32`
        methods.add_method("getRetryCount", |_, this, ()| {
            Ok(this.inner.borrow().retry_count)
        });

        /// Sets the delay (in seconds) between retry attempts.
        ///
        /// # Parameters
        /// - `seconds` — `f32`.
        methods.add_method("setRetryDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().retry_delay = seconds;
            Ok(())
        });

        // --- Optional flag ---

        /// Marks whether this step is optional (downstream steps continue on failure).
        ///
        /// # Parameters
        /// - `optional` — `bool`.
        methods.add_method("setOptional", |_, this, optional: bool| {
            this.inner.borrow_mut().optional = optional;
            Ok(())
        });

        /// Returns whether this step is marked as optional.
        ///
        /// # Returns
        /// `bool`
        methods.add_method("isOptional", |_, this, ()| {
            Ok(this.inner.borrow().optional)
        });

        // --- Per-step error callback ---

        /// Stores a Lua function (or nil) to call if this step fails.
        ///
        /// # Parameters
        /// - `fn` — `function | nil`.
        methods.add_method("setOnError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // --- Metadata ---

        /// Stores an arbitrary string value under the given key in step metadata.
        ///
        /// # Parameters
        /// - `key` — `String`.
        /// - `value` — `String`.
        methods.add_method("setData", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().metadata.insert(key, value);
            Ok(())
        });

        /// Retrieves a metadata value by key, returning nil if not found.
        ///
        /// # Parameters
        /// - `key` — `String`.
        ///
        /// # Returns
        /// `String | nil`
        methods.add_method("getData", |_, this, key: String| {
            Ok(this.inner.borrow().metadata.get(&key).cloned())
        });

        /// Sets the tag on this step for grouping and filtering.
        ///
        /// # Parameters
        /// - `tag` — `String`.
        methods.add_method("setTag", |_, this, tag: String| {
            this.inner.borrow_mut().tag = Some(tag);
            Ok(())
        });

        /// Returns the tag on this step, or nil if unset.
        ///
        /// # Returns
        /// `String | nil`
        methods.add_method("getTag", |_, this, ()| {
            Ok(this.inner.borrow().tag.clone())
        });

        // --- Dependency management ---

        /// Adds a dependency on another step. Returns self for chaining.
        ///
        /// # Parameters
        /// - `dep` — `PipelineStep | String`.
        ///
        /// # Returns
        /// `PipelineStep`
        methods.add_method("dependsOn", |_, this, dep: LuaValue| {
            let dep_name = match dep {
                LuaValue::String(s) => s.to_str()?.to_owned(),
                LuaValue::UserData(ud) => {
                    ud.borrow::<LuaStep>()?.inner.borrow().name.clone()
                }
                _ => {
                    return Err(LuaError::runtime(
                        "dependsOn: expected string or PipelineStep",
                    ))
                }
            };
            this.inner.borrow_mut().deps.push(dep_name);
            Ok(this.clone())
        });

        /// Returns the list of dependency step names.
        ///
        /// # Returns
        /// `table`
        methods.add_method("getDependencies", |_, this, ()| {
            Ok(this.inner.borrow().deps.clone())
        });

        /// Returns the number of declared dependencies.
        ///
        /// # Returns
        /// `usize`
        methods.add_method("getDependencyCount", |_, this, ()| {
            Ok(this.inner.borrow().deps.len())
        });

        // --- Runtime state (read-only) ---

        /// Returns the current execution status as a string.
        ///
        /// # Returns
        /// `String`
        methods.add_method("getStatus", |_, this, ()| {
            let s = match this.inner.borrow().status {
                StepStatus::Pending => "pending",
                StepStatus::Waiting => "waiting",
                StepStatus::Running => "running",
                StepStatus::Completed => "completed",
                StepStatus::Failed => "failed",
                StepStatus::Skipped => "skipped",
                StepStatus::Cancelled => "cancelled",
            };
            Ok(s.to_string())
        });

        /// Returns the error message from the last failed attempt, or nil.
        ///
        /// # Returns
        /// `String | nil`
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.borrow().error_msg.clone())
        });

        /// Returns total seconds spent executing this step.
        ///
        /// # Returns
        /// `f32`
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration)
        });

        /// Returns the number of execution attempts so far.
        ///
        /// # Returns
        /// `u32`
        methods.add_method("getAttempt", |_, this, ()| {
            Ok(this.inner.borrow().attempt)
        });
    }
}

// ---------------------------------------------------------------------------
// LuaPipeline wrapper
// ---------------------------------------------------------------------------

/// Lua wrapper around a [`Pipeline`] DAG plus scheduler and Lua callback registry.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Pipeline>>`.
/// - `scheduler` — `Rc<RefCell<PipelineScheduler>>`.
/// - `step_wrappers` — `Rc<RefCell<HashMap<String, LuaStep>>>`.
/// - `on_complete_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_step_complete_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `on_step_error_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `context_key` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `is_async` — `Rc<RefCell<bool>>`.
#[derive(Clone)]
struct LuaPipeline {
    /// The underlying pipeline DAG and step definitions.
    inner: Rc<RefCell<Pipeline>>,
    /// Delay countdown and running state for async execution.
    scheduler: Rc<RefCell<PipelineScheduler>>,
    /// LuaStep wrappers by step name, used to retrieve callbacks at execution time.
    step_wrappers: Rc<RefCell<HashMap<String, LuaStep>>>,
    /// Registry key for the pipeline's on-complete callback.
    on_complete_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Registry key for the per-step completion callback.
    on_step_complete_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Registry key for the per-step error callback.
    on_step_error_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// Registry key for the shared Lua context table (stored during async run).
    context_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    /// `true` while an async run is in progress.
    is_async: Rc<RefCell<bool>>,
}

impl LunaType for LuaPipeline {
    const TYPE_NAME: &'static str = "Pipeline";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Pipeline", "Object"];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Checks whether all required (non-optional) dependencies of `step_name` are in a
/// terminal-success state. Returns `Ok(true)` if all are satisfied, `Ok(false)` if
/// any required dep failed/was skipped, `Err` if a dep is still pending/running.
fn deps_satisfied(
    pipeline: &Pipeline,
    step_name: &str,
    wrappers: &HashMap<String, LuaStep>,
) -> Result<bool, String> {
    let step = match pipeline.get_step(step_name) {
        Some(s) => s,
        None => return Err(format!("step '{}' not found", step_name)),
    };

    for dep_name in &step.deps {
        let dep_status = match wrappers.get(dep_name) {
            Some(w) => w.inner.borrow().status.clone(),
            None => {
                // dep not in wrappers means it never ran — treat as not fulfilled
                return Ok(false);
            }
        };
        match dep_status {
            StepStatus::Completed => {} // good
            StepStatus::Skipped | StepStatus::Failed => {
                // check if dep is optional
                let dep_step = pipeline.get_step(dep_name.as_str());
                let is_optional = dep_step.map(|s| s.optional).unwrap_or(false);
                if !is_optional {
                    return Ok(false);
                }
            }
            _ => {
                return Err(format!(
                    "dep '{}' of '{}' is still in state {:?}",
                    dep_name,
                    step_name,
                    dep_status
                ));
            }
        }
    }
    Ok(true)
}

/// Builds the Lua result table from the current state of all step wrappers.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `wrappers` — `&HashMap<String, LuaStep>`.
/// - `total_duration` — `f32`.
///
/// # Returns
/// `LuaResult<LuaTable>`
fn build_result_table<'lua>(
    lua: &'lua Lua,
    wrappers: &HashMap<String, LuaStep>,
    total_duration: f32,
) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    let completed = lua.create_table()?;
    let failed = lua.create_table()?;
    let skipped = lua.create_table()?;
    let cancelled = lua.create_table()?;
    let errors = lua.create_table()?;

    let mut c_i = 1usize;
    let mut f_i = 1usize;
    let mut s_i = 1usize;
    let mut ca_i = 1usize;
    let mut err_i = 1usize;

    for (name, wrapper) in wrappers {
        let inner = wrapper.inner.borrow();
        match inner.status {
            StepStatus::Completed => {
                completed.set(c_i, name.clone())?;
                c_i += 1;
            }
            StepStatus::Failed => {
                failed.set(f_i, name.clone())?;
                f_i += 1;
                let err_entry = lua.create_table()?;
                err_entry.set(1, name.clone())?;
                err_entry.set(2, inner.error_msg.clone().unwrap_or_default())?;
                errors.set(err_i, err_entry)?;
                err_i += 1;
            }
            StepStatus::Skipped => {
                skipped.set(s_i, name.clone())?;
                s_i += 1;
            }
            StepStatus::Cancelled => {
                cancelled.set(ca_i, name.clone())?;
                ca_i += 1;
            }
            _ => {}
        }
    }

    t.set("success", f_i == 1)?; // f_i==1 means nothing was added to failed
    t.set("completed", completed)?;
    t.set("failed", failed)?;
    t.set("skipped", skipped)?;
    t.set("cancelled", cancelled)?;
    t.set("totalDuration", total_duration)?;
    t.set("errors", errors)?;
    Ok(t)
}

/// Executes a single step synchronously: calls its callback, handles retries, updates status.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `wrapper` — `&LuaStep`.
/// - `ctx` — `&LuaTable`.
/// - `abort_on_fail` — `bool`.
///
/// # Returns
/// `LuaResult<bool>` — `true` if the step succeeded (or was skipped by condition), `false` if it failed and the pipeline should abort.
fn execute_step_sync<'lua>(
    lua: &'lua Lua,
    wrapper: &LuaStep,
    ctx: &LuaTable<'lua>,
    abort_on_fail: bool,
) -> LuaResult<bool> {
    let name = wrapper.inner.borrow().name.clone();
    let retry_count = wrapper.inner.borrow().retry_count;

    // Check condition gate before marking as Running
    if let Some(key) = wrapper.condition_key.borrow().as_ref() {
        let cond_fn: LuaFunction = lua.registry_value(key)?;
        let should_run: bool = cond_fn.call(ctx.clone())?;
        if !should_run {
            wrapper.inner.borrow_mut().status = StepStatus::Skipped;
            return Ok(true);
        }
    }

    // Retrieve callback — required
    let cb_key_opt = wrapper.callback_key.borrow();
    let cb_key = cb_key_opt.as_ref().ok_or_else(|| {
        LuaError::runtime(format!("step '{}' has no callback registered", name))
    })?;
    let cb: LuaFunction = lua.registry_value(cb_key)?;
    drop(cb_key_opt);

    let max_attempts = retry_count + 1;
    let mut last_error: Option<LuaError> = None;

    for attempt in 0..max_attempts {
        wrapper.inner.borrow_mut().attempt = attempt + 1;
        wrapper.inner.borrow_mut().status = StepStatus::Running;

        match cb.call::<_, LuaValue<'_>>(ctx.clone()) {
            Ok(result) => {
                // Store result in ctx.results[step_name]
                let results: LuaTable = match ctx.get("results") {
                    Ok(t) => t,
                    Err(_) => lua.create_table()?,
                };
                results.set(name.clone(), result)?;
                ctx.set("results", results)?;

                wrapper.inner.borrow_mut().status = StepStatus::Completed;
                wrapper.inner.borrow_mut().error_msg = None;
                return Ok(true);
            }
            Err(e) => {
                last_error = Some(e);
                // If more retries remain, continue
                if attempt + 1 < max_attempts {
                    continue;
                }
            }
        }
    }

    // All attempts exhausted — mark failed
    let err_msg = last_error
        .as_ref()
        .map(|e| e.to_string())
        .unwrap_or_default();
    {
        let mut inner = wrapper.inner.borrow_mut();
        inner.status = StepStatus::Failed;
        inner.error_msg = Some(err_msg.clone());
    }

    // Call per-step on_error callback if set
    if let Some(key) = wrapper.on_error_key.borrow().as_ref() {
        let err_fn: LuaFunction = lua.registry_value(key)?;
        if let Err(e) = err_fn.call::<_, LuaValue<'_>>((name.clone(), err_msg)) {
            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_error: {e}");
        }
    }

    if abort_on_fail {
        Ok(false)
    } else {
        Ok(true) // Continue mode: don't abort, step stays Failed
    }
}

// ---------------------------------------------------------------------------
// LuaPipeline UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaPipeline {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ----------------------------------------------------------------
        // Step management
        // ----------------------------------------------------------------

        /// Adds a step to the pipeline. Returns self for chaining.
        ///
        /// # Parameters
        /// - `step` — `PipelineStep`.
        ///
        /// # Returns
        /// `Pipeline`
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

        /// Removes a step from the pipeline by name.
        ///
        /// # Parameters
        /// - `name` — `String`.
        methods.add_method("removeStep", |_, this, name: String| {
            this.inner.borrow_mut().remove_step(&name);
            this.step_wrappers.borrow_mut().remove(&name);
            Ok(())
        });

        /// Returns the LuaStep wrapper for the named step, or nil.
        ///
        /// # Parameters
        /// - `name` — `String`.
        ///
        /// # Returns
        /// `PipelineStep | nil`
        methods.add_method("getStep", |_, this, name: String| {
            Ok(this.step_wrappers.borrow().get(&name).cloned())
        });

        /// Returns a Lua array of all step wrappers in the pipeline.
        ///
        /// # Returns
        /// `table`
        methods.add_method("getSteps", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, wrapper) in this.step_wrappers.borrow().values().enumerate() {
                t.set(i + 1, wrapper.clone())?;
            }
            Ok(t)
        });

        /// Returns the total number of steps.
        ///
        /// # Returns
        /// `usize`
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });

        /// Returns a Lua array of all steps whose tag matches the given string.
        ///
        /// # Parameters
        /// - `tag` — `String`.
        ///
        /// # Returns
        /// `table`
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

        /// Clears all steps from the pipeline.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.step_wrappers.borrow_mut().clear();
            Ok(())
        });

        // ----------------------------------------------------------------
        // Validation
        // ----------------------------------------------------------------

        /// Validates the pipeline DAG. Returns `(ok, error_array)`.
        ///
        /// # Returns
        /// `(bool, table)`
        methods.add_method("validate", |lua, this, ()| {
            let (ok, errs) = this.inner.borrow().validate();
            let t = lua.create_table()?;
            for (i, e) in errs.iter().enumerate() {
                t.set(i + 1, e.clone())?;
            }
            Ok((ok, t))
        });

        /// Returns the topological execution order as an array of step names.
        /// Returns `(nil, error_string)` if a cycle is detected.
        ///
        /// # Returns
        /// `table | nil, String`
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

        /// Returns parallel execution groups as a nested array. Returns `(nil, error_string)` on cycle.
        ///
        /// # Returns
        /// `table | nil, String`
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

        // ----------------------------------------------------------------
        // Synchronous execution
        // ----------------------------------------------------------------

        /// Executes the pipeline synchronously in topological order.
        ///
        /// # Parameters
        /// - `context` — `table?`.
        ///
        /// # Returns
        /// `table`
        methods.add_method("run", |lua, this, context: Option<LuaTable>| {
            // Get execution order — fail if cycle
            let order = this
                .inner
                .borrow()
                .get_execution_order()
                .map_err(LuaError::runtime)?;

            // Reset all step states
            this.inner.borrow_mut().reset();
            for wrapper in this.step_wrappers.borrow().values() {
                wrapper.inner.borrow_mut().status = StepStatus::Pending;
                wrapper.inner.borrow_mut().attempt = 0;
                wrapper.inner.borrow_mut().duration = 0.0;
                wrapper.inner.borrow_mut().error_msg = None;
            }

            // Build context table
            let ctx = match context {
                Some(c) => c,
                None => lua.create_table()?,
            };
            let results_table = lua.create_table()?;
            ctx.set("results", results_table)?;

            let abort_on_fail = this.inner.borrow().error_mode == ErrorMode::Abort;

            let start = std::time::Instant::now();

            'steps: for step_name in &order {
                let wrapper = {
                    let wrappers = this.step_wrappers.borrow();
                    wrappers.get(step_name).cloned()
                };
                let wrapper = match wrapper {
                    Some(w) => w,
                    None => {
                        // Step registered in pipeline DAG but no wrapper — skip
                        continue;
                    }
                };

                // Check if any non-optional deps failed/were skipped
                {
                    let pipeline = this.inner.borrow();
                    let wrappers = this.step_wrappers.borrow();
                    match deps_satisfied(&pipeline, step_name, &wrappers) {
                        Ok(true) => {}
                        Ok(false) => {
                            if abort_on_fail {
                                wrapper.inner.borrow_mut().status = StepStatus::Cancelled;
                                // Cancel remaining steps
                                for remaining in &order {
                                    if let Some(w) = wrappers.get(remaining) {
                                        let s = w.inner.borrow().status.clone();
                                        if s == StepStatus::Pending {
                                            w.inner.borrow_mut().status = StepStatus::Cancelled;
                                        }
                                    }
                                }
                                break 'steps;
                            } else {
                                wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                                continue;
                            }
                        }
                        Err(_) => {
                            // Dep still pending — should not happen in topo order, skip
                            wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                            continue;
                        }
                    }
                }

                let succeeded = execute_step_sync(lua, &wrapper, &ctx, abort_on_fail)?;

                // Fire per-step pipeline callbacks
                let step_status = wrapper.inner.borrow().status.clone();
                if step_status == StepStatus::Completed {
                    if let Some(key) = this.on_step_complete_key.borrow().as_ref() {
                        let f: LuaFunction = lua.registry_value(key)?;
                        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.clone(), ctx.clone())) {
                            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_complete: {e}");
                        }
                    }
                } else if step_status == StepStatus::Failed {
                    if let Some(key) = this.on_step_error_key.borrow().as_ref() {
                        let f: LuaFunction = lua.registry_value(key)?;
                        let err = wrapper.inner.borrow().error_msg.clone().unwrap_or_default();
                        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.clone(), err)) {
                            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_error: {e}");
                        }
                    }
                }

                if !succeeded {
                    // Abort: cancel remaining
                    let wrappers = this.step_wrappers.borrow();
                    for remaining in &order {
                        if let Some(w) = wrappers.get(remaining) {
                            let s = w.inner.borrow().status.clone();
                            if s == StepStatus::Pending {
                                w.inner.borrow_mut().status = StepStatus::Cancelled;
                            }
                        }
                    }
                    break;
                }
            }

            let total_duration = start.elapsed().as_secs_f32();
            let result = build_result_table(lua, &this.step_wrappers.borrow(), total_duration)?;

            // Fire on_complete callback
            if let Some(key) = this.on_complete_key.borrow().as_ref() {
                let f: LuaFunction = lua.registry_value(key)?;
                if let Err(e) = f.call::<_, LuaValue<'_>>(result.clone()) {
                    log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_complete: {e}");
                }
            }

            Ok(result)
        });

        // ----------------------------------------------------------------
        // Async execution
        // ----------------------------------------------------------------

        /// Starts an async pipeline run. Steps are executed one-per-frame via `update(dt)`.
        ///
        /// # Parameters
        /// - `context` — `table?`.
        methods.add_method("runAsync", |lua, this, context: Option<LuaTable>| {
            // Reset state
            this.inner.borrow_mut().reset();
            for wrapper in this.step_wrappers.borrow().values() {
                wrapper.inner.borrow_mut().status = StepStatus::Pending;
                wrapper.inner.borrow_mut().attempt = 0;
                wrapper.inner.borrow_mut().duration = 0.0;
                wrapper.inner.borrow_mut().error_msg = None;
            }

            let ctx = match context {
                Some(c) => c,
                None => lua.create_table()?,
            };
            let results_table = lua.create_table()?;
            ctx.set("results", results_table)?;

            // Store context in registry
            *this.context_key.borrow_mut() = Some(lua.create_registry_value(ctx)?);
            *this.is_async.borrow_mut() = true;

            // Start scheduler
            let pipeline = this.inner.borrow();
            this.scheduler.borrow_mut().start(&pipeline);

            // Mark zero-dep steps as Waiting
            let wrappers = this.step_wrappers.borrow();
            for (name, wrapper) in wrappers.iter() {
                let has_deps = !pipeline.get_step(name).map(|s| s.deps.is_empty()).unwrap_or(true);
                if !has_deps {
                    wrapper.inner.borrow_mut().status = StepStatus::Waiting;
                    this.scheduler.borrow_mut().mark_step_waiting(name, &pipeline);
                }
            }

            Ok(())
        });

        /// Advances the async pipeline by one tick. Returns `true` when all steps are done.
        ///
        /// # Parameters
        /// - `dt` — `f32`.
        ///
        /// # Returns
        /// `bool`
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

            // Get steps ready to execute this tick
            let ready_names = {
                let pipeline = this.inner.borrow();
                this.scheduler.borrow_mut().update(dt, &pipeline)
            };

            for step_name in ready_names {
                let wrapper = {
                    let wrappers = this.step_wrappers.borrow();
                    wrappers.get(&step_name).cloned()
                };
                let wrapper = match wrapper {
                    Some(w) => w,
                    None => continue,
                };

                let succeeded = execute_step_sync(lua, &wrapper, &ctx, abort_on_fail)?;

                // Fire per-step callbacks
                let step_status = wrapper.inner.borrow().status.clone();
                if step_status == StepStatus::Completed {
                    if let Some(key) = this.on_step_complete_key.borrow().as_ref() {
                        let f: LuaFunction = lua.registry_value(key)?;
                        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.clone(), ctx.clone())) {
                            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_complete: {e}");
                        }
                    }
                } else if step_status == StepStatus::Failed {
                    if let Some(key) = this.on_step_error_key.borrow().as_ref() {
                        let f: LuaFunction = lua.registry_value(key)?;
                        let err = wrapper.inner.borrow().error_msg.clone().unwrap_or_default();
                        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.clone(), err)) {
                            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_step_error: {e}");
                        }
                    }
                }

                if !succeeded {
                    // Abort: cancel all pending/waiting
                    let wrappers = this.step_wrappers.borrow();
                    for w in wrappers.values() {
                        let s = w.inner.borrow().status.clone();
                        if s == StepStatus::Pending || s == StepStatus::Waiting {
                            w.inner.borrow_mut().status = StepStatus::Cancelled;
                        }
                    }
                    *this.is_async.borrow_mut() = false;
                    this.scheduler.borrow_mut().reset();

                    let result = build_result_table(
                        lua,
                        &this.step_wrappers.borrow(),
                        this.scheduler.borrow().elapsed,
                    )?;
                    if let Some(key) = this.on_complete_key.borrow().as_ref() {
                        let f: LuaFunction = lua.registry_value(key)?;
                        let _: LuaResult<LuaValue> = f.call(result);
                    }
                    return Ok(true);
                }

                // Mark newly-ready dependents as Waiting
                {
                    let pipeline = this.inner.borrow();
                    let wrappers = this.step_wrappers.borrow();
                    for (name, w) in wrappers.iter() {
                        if w.inner.borrow().status != StepStatus::Pending {
                            continue;
                        }
                        // Check if all deps are now satisfied
                        if let Ok(true) = deps_satisfied(&pipeline, name, &wrappers) {
                            w.inner.borrow_mut().status = StepStatus::Waiting;
                            this.scheduler.borrow_mut().mark_step_waiting(name, &pipeline);
                        }
                    }
                }
            }

            // Check if all steps are terminal
            let all_done = {
                let wrappers = this.step_wrappers.borrow();
                wrappers.values().all(|w| {
                    matches!(
                        w.inner.borrow().status,
                        StepStatus::Completed
                            | StepStatus::Failed
                            | StepStatus::Skipped
                            | StepStatus::Cancelled
                    )
                })
            };

            if all_done {
                *this.is_async.borrow_mut() = false;
                this.scheduler.borrow_mut().reset();

                let elapsed = this.scheduler.borrow().elapsed;
                let result =
                    build_result_table(lua, &this.step_wrappers.borrow(), elapsed)?;
                if let Some(key) = this.on_complete_key.borrow().as_ref() {
                    let f: LuaFunction = lua.registry_value(key)?;
                    if let Err(e) = f.call::<_, LuaValue<'_>>(result) {
                        log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_complete: {e}");
                    }
                }
            }

            Ok(all_done)
        });

        /// Cancels all pending and waiting steps.
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

        /// Resets all step states and clears the async context.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            for w in this.step_wrappers.borrow().values() {
                w.inner.borrow_mut().status = StepStatus::Pending;
                w.inner.borrow_mut().attempt = 0;
                w.inner.borrow_mut().duration = 0.0;
                w.inner.borrow_mut().error_msg = None;
            }
            *this.context_key.borrow_mut() = None;
            *this.is_async.borrow_mut() = false;
            this.scheduler.borrow_mut().reset();
            Ok(())
        });

        /// Returns `true` if the pipeline is currently running asynchronously.
        ///
        /// # Returns
        /// `bool`
        methods.add_method("isRunning", |_, this, ()| {
            Ok(*this.is_async.borrow())
        });

        /// Returns `true` if all steps have reached a terminal state.
        ///
        /// # Returns
        /// `bool`
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

        // ----------------------------------------------------------------
        // Error mode
        // ----------------------------------------------------------------

        /// Sets the pipeline error mode: `"abort"` or `"continue"`.
        ///
        /// # Parameters
        /// - `mode` — `String`.
        methods.add_method("setErrorMode", |_, this, mode: String| {
            let em = match mode.as_str() {
                "abort" => ErrorMode::Abort,
                "continue" => ErrorMode::Continue,
                _ => {
                    return Err(LuaError::runtime(format!(
                        "setErrorMode: unknown mode '{}', expected 'abort' or 'continue'",
                        mode
                    )))
                }
            };
            this.inner.borrow_mut().error_mode = em;
            Ok(())
        });

        /// Returns the current error mode as a string (`"abort"` or `"continue"`).
        ///
        /// # Returns
        /// `String`
        methods.add_method("getErrorMode", |_, this, ()| {
            let s = match this.inner.borrow().error_mode {
                ErrorMode::Abort => "abort",
                ErrorMode::Continue => "continue",
            };
            Ok(s.to_string())
        });

        // ----------------------------------------------------------------
        // Context & results
        // ----------------------------------------------------------------

        /// Returns the current result table built from step states, or nil if nothing has run.
        ///
        /// # Returns
        /// `table | nil`
        methods.add_method("getResult", |lua, this, ()| {
            let wrappers = this.step_wrappers.borrow();
            if wrappers.is_empty() {
                return Ok(None);
            }
            let elapsed = this.scheduler.borrow().elapsed;
            let t = build_result_table(lua, &wrappers, elapsed)?;
            Ok(Some(t))
        });

        /// Returns the stored async context table, or nil if not in an async run.
        ///
        /// # Returns
        /// `table | nil`
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

        // ----------------------------------------------------------------
        // Pipeline-level callbacks
        // ----------------------------------------------------------------

        /// Sets the callback to invoke when the pipeline completes.
        ///
        /// # Parameters
        /// - `fn` — `function | nil`.
        methods.add_method("setOnComplete", |lua, this, cb: Option<LuaFunction>| {
            *this.on_complete_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        /// Sets the callback to invoke each time a step completes successfully.
        ///
        /// # Parameters
        /// - `fn` — `function | nil`.
        methods.add_method(
            "setOnStepComplete",
            |lua, this, cb: Option<LuaFunction>| {
                *this.on_step_complete_key.borrow_mut() = match cb {
                    Some(f) => Some(lua.create_registry_value(f)?),
                    None => None,
                };
                Ok(())
            },
        );

        /// Sets the callback to invoke each time a step fails.
        ///
        /// # Parameters
        /// - `fn` — `function | nil`.
        methods.add_method("setOnStepError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_step_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });

        // ----------------------------------------------------------------
        // Name management
        // ----------------------------------------------------------------

        /// Returns the pipeline's name.
        ///
        /// # Returns
        /// `String`
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        /// Sets the pipeline's name.
        ///
        /// # Parameters
        /// - `name` — `String`.
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().name = name;
            Ok(())
        });

        // ----------------------------------------------------------------
        // Serialization
        // ----------------------------------------------------------------

        /// Serialises the pipeline definition to a Lua table (no callbacks).
        ///
        /// # Returns
        /// `table`
        methods.add_method("toTable", |lua, this, ()| {
            let t = lua.create_table()?;
            let pipeline = this.inner.borrow();
            t.set("name", pipeline.name.clone())?;
            let mode = match pipeline.error_mode {
                ErrorMode::Abort => "abort",
                ErrorMode::Continue => "continue",
            };
            t.set("errorMode", mode)?;

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
    }
}

// ---------------------------------------------------------------------------
// Module registration
// ---------------------------------------------------------------------------

/// Registers the `luna.pipeline.*` DAG pipeline orchestrator API on the given `luna` table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let pipeline_table = lua.create_table()?;

    // luna.pipeline.newStep(name, fn?) -> LuaStep
    pipeline_table.set(
        "newStep",
        lua.create_function(|lua, (name, callback): (String, Option<LuaFunction>)| {
            let step = PipelineStep::new(name);
            let wrapper = LuaStep {
                inner: Rc::new(RefCell::new(step)),
                callback_key: Rc::new(RefCell::new(None)),
                condition_key: Rc::new(RefCell::new(None)),
                on_error_key: Rc::new(RefCell::new(None)),
            };
            if let Some(cb) = callback {
                *wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            }
            Ok(wrapper)
        })?,
    )?;

    // luna.pipeline.newPipeline(name?) -> LuaPipeline
    pipeline_table.set(
        "newPipeline",
        lua.create_function(|_, name: Option<String>| {
            let pipeline = Pipeline::new(name.unwrap_or_else(|| "pipeline".to_string()));
            Ok(LuaPipeline {
                inner: Rc::new(RefCell::new(pipeline)),
                scheduler: Rc::new(RefCell::new(PipelineScheduler::new())),
                step_wrappers: Rc::new(RefCell::new(HashMap::new())),
                on_complete_key: Rc::new(RefCell::new(None)),
                on_step_complete_key: Rc::new(RefCell::new(None)),
                on_step_error_key: Rc::new(RefCell::new(None)),
                context_key: Rc::new(RefCell::new(None)),
                is_async: Rc::new(RefCell::new(false)),
            })
        })?,
    )?;

    // luna.pipeline.fromTable(def: table) -> LuaPipeline
    pipeline_table.set(
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

            let step_wrappers: HashMap<String, LuaStep> = HashMap::new();
            let pipeline_rc = Rc::new(RefCell::new(pipeline));
            let wrappers_rc: Rc<RefCell<HashMap<String, LuaStep>>> =
                Rc::new(RefCell::new(step_wrappers));

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

                    let wrapper = LuaStep {
                        inner: Rc::new(RefCell::new(step.clone())),
                        callback_key: Rc::new(RefCell::new(None)),
                        condition_key: Rc::new(RefCell::new(None)),
                        on_error_key: Rc::new(RefCell::new(None)),
                    };

                    // Store optional callback if present
                    if let Ok(cb) = st.get::<_, LuaFunction<'_>>("fn") {
                        *wrapper.callback_key.borrow_mut() =
                            Some(lua.create_registry_value(cb)?);
                    }

                    pipeline_rc
                        .borrow_mut()
                        .add_step(step)
                        .map_err(LuaError::runtime)?;
                    wrappers_rc.borrow_mut().insert(sname, wrapper);
                }
            }

            Ok(LuaPipeline {
                inner: pipeline_rc,
                scheduler: Rc::new(RefCell::new(PipelineScheduler::new())),
                step_wrappers: wrappers_rc,
                on_complete_key: Rc::new(RefCell::new(None)),
                on_step_complete_key: Rc::new(RefCell::new(None)),
                on_step_error_key: Rc::new(RefCell::new(None)),
                context_key: Rc::new(RefCell::new(None)),
                is_async: Rc::new(RefCell::new(false)),
            })
        })?,
    )?;

    luna.set("pipeline", pipeline_table)?;
    Ok(())
}
