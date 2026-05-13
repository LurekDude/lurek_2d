use super::SharedState;
use crate::log_msg;
use crate::pipeline::{ErrorMode, Pipeline, PipelineScheduler, PipelineStep, StepStatus};
use crate::runtime::log_messages::LA02_PIPELINE_CALLBACK_FAIL;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::time::Instant;
#[derive(Clone)]
pub struct LuaStep {
    pub(crate) inner: Rc<RefCell<PipelineStep>>,
    pub(crate) callback_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) condition_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) on_error_key: Rc<RefCell<Option<LuaRegistryKey>>>,
}
impl LuaStep {
    pub fn new(step: PipelineStep) -> Self {
        Self {
            inner: Rc::new(RefCell::new(step)),
            callback_key: Rc::new(RefCell::new(None)),
            condition_key: Rc::new(RefCell::new(None)),
            on_error_key: Rc::new(RefCell::new(None)),
        }
    }
    pub(crate) fn execute_sync<'lua>(
        &self,
        lua: &'lua Lua,
        ctx: &LuaTable<'lua>,
        abort_on_fail: bool,
    ) -> LuaResult<bool> {
        let name = self.inner.borrow().name.clone();
        let retry_count = self.inner.borrow().retry_count;
        if let Some(key) = self.condition_key.borrow().as_ref() {
            let cond_fn: LuaFunction = lua.registry_value(key)?;
            let should_run: bool = cond_fn.call(ctx.clone())?;
            if !should_run {
                self.inner.borrow_mut().status = StepStatus::Skipped;
                return Ok(true);
            }
        }
        let cb_key_opt = self.callback_key.borrow();
        let cb_key = cb_key_opt.as_ref().ok_or_else(|| {
            LuaError::runtime(format!("step '{}' has no callback registered", name))
        })?;
        let cb: LuaFunction = lua.registry_value(cb_key)?;
        drop(cb_key_opt);
        let max_attempts = retry_count + 1;
        let mut last_error: Option<LuaError> = None;
        let started = Instant::now();
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
                    self.inner.borrow_mut().duration = started.elapsed().as_secs_f32();
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
        let err_msg = last_error
            .as_ref()
            .map(|e| e.to_string())
            .unwrap_or_default();
        {
            let mut inner = self.inner.borrow_mut();
            inner.status = StepStatus::Failed;
            inner.duration = started.elapsed().as_secs_f32();
            inner.error_msg = Some(err_msg.clone());
        }
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
    fn is_async_enabled(&self) -> bool {
        self.inner
            .borrow()
            .metadata
            .get("__pipeline_async")
            .map(|v| v == "true")
            .unwrap_or(false)
    }
    fn set_async_enabled(&self, enabled: bool) {
        self.inner
            .borrow_mut()
            .metadata
            .insert("__pipeline_async".to_string(), enabled.to_string());
    }
}
impl LuaUserData for LuaStep {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });
        methods.add_method("setCallback", |lua, this, cb: LuaFunction| {
            *this.callback_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });
        methods.add_method("setCondition", |lua, this, cond: Option<LuaFunction>| {
            *this.condition_key.borrow_mut() = match cond {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });
        methods.add_method("setDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().delay = seconds;
            Ok(())
        });
        methods.add_method("getDelay", |_, this, ()| Ok(this.inner.borrow().delay));
        methods.add_method("setTimeout", |_, this, seconds: f32| {
            this.inner
                .borrow_mut()
                .metadata
                .insert("timeout".to_string(), seconds.to_string());
            Ok(())
        });
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
        methods.add_method("setRetryCount", |_, this, count: u32| {
            this.inner.borrow_mut().retry_count = count;
            Ok(())
        });
        methods.add_method("getRetryCount", |_, this, ()| {
            Ok(this.inner.borrow().retry_count)
        });
        methods.add_method("setRetryDelay", |_, this, seconds: f32| {
            this.inner.borrow_mut().retry_delay = seconds;
            Ok(())
        });
        methods.add_method("setAsync", |_, this, enabled: bool| {
            this.set_async_enabled(enabled);
            Ok(())
        });
        methods.add_method("isAsync", |_, this, ()| Ok(this.is_async_enabled()));
        methods.add_method("setOptional", |_, this, optional: bool| {
            this.inner.borrow_mut().optional = optional;
            Ok(())
        });
        methods.add_method("isOptional", |_, this, ()| Ok(this.inner.borrow().optional));
        methods.add_method("setOnError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });
        methods.add_method("setData", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().metadata.insert(key, value);
            Ok(())
        });
        methods.add_method("getData", |_, this, key: String| {
            Ok(this.inner.borrow().metadata.get(&key).cloned())
        });
        methods.add_method("setTag", |_, this, tag: String| {
            this.inner.borrow_mut().tag = Some(tag);
            Ok(())
        });
        methods.add_method("getTag", |_, this, ()| Ok(this.inner.borrow().tag.clone()));
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
        methods.add_method("getDependencies", |_, this, ()| {
            Ok(this.inner.borrow().deps.clone())
        });
        methods.add_method("getDependencyCount", |_, this, ()| {
            Ok(this.inner.borrow().deps.len())
        });
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.inner.borrow().status.as_str().to_string())
        });
        methods.add_method("getError", |_, this, ()| {
            Ok(this.inner.borrow().error_msg.clone())
        });
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration)
        });
        methods.add_method("getAttempt", |_, this, ()| Ok(this.inner.borrow().attempt));
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let inner = this.inner.borrow();
            Ok(format!("PipelineStep(\"{}\")", inner.name))
        });
        methods.add_method("type", |_, _, ()| Ok("LPipelineStep"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPipelineStep" || name == "PipelineStep" || name == "Object")
        });
    }
}
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
    pub(crate) on_progress_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) on_event_key: Rc<RefCell<Option<LuaRegistryKey>>>,
    pub(crate) running_threads: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    pub(crate) started_at: Rc<RefCell<HashMap<String, Instant>>>,
}
impl LuaPipeline {
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
            on_event_key: Rc::new(RefCell::new(None)),
            running_threads: Rc::new(RefCell::new(HashMap::new())),
            started_at: Rc::new(RefCell::new(HashMap::new())),
        }
    }
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
            on_event_key: Rc::new(RefCell::new(None)),
            running_threads: Rc::new(RefCell::new(HashMap::new())),
            started_at: Rc::new(RefCell::new(HashMap::new())),
        }
    }
}
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
pub(crate) fn cancel_remaining_steps(wrappers: &HashMap<String, LuaStep>, order: &[String]) {
    for name in order {
        if let Some(w) = wrappers.get(name) {
            if w.inner.borrow().status == StepStatus::Pending {
                w.inner.borrow_mut().status = StepStatus::Cancelled;
            }
        }
    }
}
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
    if let Some(key) = this.on_progress_key.borrow().as_ref() {
        let status_str = format!("{:?}", step_status).to_lowercase();
        let f: LuaFunction = lua.registry_value(key)?;
        if let Err(e) = f.call::<_, LuaValue<'_>>((step_name.to_string(), status_str)) {
            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_progress: {e}");
        }
    }
    let detail: LuaValue = if step_status == StepStatus::Failed {
        LuaValue::String(
            lua.create_string(wrapper.inner.borrow().error_msg.clone().unwrap_or_default())?,
        )
    } else {
        LuaValue::Nil
    };
    fire_pipeline_event(
        lua,
        this,
        "step_finished",
        step_name,
        step_status.as_str(),
        detail,
    )?;
    Ok(())
}
fn fire_pipeline_event<'lua>(
    lua: &'lua Lua,
    this: &LuaPipeline,
    event_name: &str,
    step_name: &str,
    status: &str,
    detail: LuaValue<'lua>,
) -> LuaResult<()> {
    if let Some(key) = this.on_event_key.borrow().as_ref() {
        let f: LuaFunction = lua.registry_value(key)?;
        if let Err(e) = f.call::<_, LuaValue<'_>>((
            event_name.to_string(),
            step_name.to_string(),
            status.to_string(),
            detail,
        )) {
            log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_event: {e}");
        }
    }
    Ok(())
}
fn execute_async_coroutine_step<'lua>(
    lua: &'lua Lua,
    this: &LuaPipeline,
    step_name: &str,
    wrapper: &LuaStep,
    ctx: &LuaTable<'lua>,
) -> LuaResult<bool> {
    let mut first_resume = false;
    let mut thread_key = this.running_threads.borrow_mut().remove(step_name);
    if thread_key.is_none() {
        if let Some(key) = wrapper.condition_key.borrow().as_ref() {
            let cond_fn: LuaFunction = lua.registry_value(key)?;
            let should_run: bool = cond_fn.call(ctx.clone())?;
            if !should_run {
                wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                return Ok(true);
            }
        }
        let name = wrapper.inner.borrow().name.clone();
        let cb_key_opt = wrapper.callback_key.borrow();
        let cb_key = cb_key_opt.as_ref().ok_or_else(|| {
            LuaError::runtime(format!("step '{}' has no callback registered", name))
        })?;
        let cb: LuaFunction = lua.registry_value(cb_key)?;
        drop(cb_key_opt);
        let thread = lua.create_thread(cb)?;
        let key = lua.create_registry_value(thread)?;
        thread_key = Some(key);
        first_resume = true;
        let mut inner = wrapper.inner.borrow_mut();
        inner.attempt = inner.attempt.saturating_add(1);
        inner.status = StepStatus::Running;
        inner.error_msg = None;
        drop(inner);
        this.started_at
            .borrow_mut()
            .insert(step_name.to_string(), Instant::now());
    }
    let Some(reg_key) = thread_key else {
        return Ok(false);
    };
    let thread_val: LuaValue = lua.registry_value(&reg_key)?;
    let thread = match thread_val {
        LuaValue::Thread(t) => t,
        _ => {
            this.running_threads.borrow_mut().remove(step_name);
            lua.remove_registry_value(reg_key)?;
            return Err(LuaError::runtime(format!(
                "step '{}' async state is invalid",
                step_name
            )));
        }
    };
    let resumed = if first_resume {
        thread.resume::<_, LuaValue<'_>>(ctx.clone())
    } else {
        thread.resume::<_, LuaValue<'_>>(())
    };
    match resumed {
        Ok(result) => {
            let coroutine_tbl: LuaTable = lua.globals().get("coroutine")?;
            let status_fn: LuaFunction = coroutine_tbl.get("status")?;
            let coroutine_status: String = status_fn.call(thread.clone())?;
            if coroutine_status != "dead" {
                wrapper.inner.borrow_mut().status = StepStatus::Running;
                this.running_threads
                    .borrow_mut()
                    .insert(step_name.to_string(), reg_key);
                return Ok(false);
            }
            let results: LuaTable = match ctx.get("results") {
                Ok(t) => t,
                Err(_) => lua.create_table()?,
            };
            results.set(step_name.to_string(), result)?;
            ctx.set("results", results)?;
            let mut inner = wrapper.inner.borrow_mut();
            inner.status = StepStatus::Completed;
            if let Some(started) = this.started_at.borrow_mut().remove(step_name) {
                inner.duration = started.elapsed().as_secs_f32();
            }
            drop(inner);
            this.running_threads.borrow_mut().remove(step_name);
            lua.remove_registry_value(reg_key)?;
            Ok(true)
        }
        Err(e) => {
            this.running_threads.borrow_mut().remove(step_name);
            lua.remove_registry_value(reg_key)?;
            let mut inner = wrapper.inner.borrow_mut();
            let max_attempts = inner.retry_count.saturating_add(1);
            if inner.attempt < max_attempts {
                inner.status = StepStatus::Waiting;
                return Ok(false);
            }
            inner.status = StepStatus::Failed;
            inner.error_msg = Some(e.to_string());
            if let Some(started) = this.started_at.borrow_mut().remove(step_name) {
                inner.duration = started.elapsed().as_secs_f32();
            }
            drop(inner);
            if let Some(key) = wrapper.on_error_key.borrow().as_ref() {
                let err_fn: LuaFunction = lua.registry_value(key)?;
                let err = wrapper.inner.borrow().error_msg.clone().unwrap_or_default();
                if let Err(cb_err) = err_fn.call::<_, LuaValue<'_>>((step_name.to_string(), err)) {
                    log_msg!(warn, LA02_PIPELINE_CALLBACK_FAIL, "on_error: {cb_err}");
                }
            }
            Ok(true)
        }
    }
}
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
impl LuaUserData for LuaPipeline {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("removeStep", |_, this, name: String| {
            this.inner.borrow_mut().remove_step(&name);
            this.step_wrappers.borrow_mut().remove(&name);
            Ok(())
        });
        methods.add_method("getStep", |_, this, name: String| {
            Ok(this.step_wrappers.borrow().get(&name).cloned())
        });
        methods.add_method("getSteps", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, wrapper) in this.step_wrappers.borrow().values().enumerate() {
                t.set(i + 1, wrapper.clone())?;
            }
            Ok(t)
        });
        methods.add_method("getStepCount", |_, this, ()| {
            Ok(this.inner.borrow().get_step_count())
        });
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
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            this.step_wrappers.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("validate", |lua, this, ()| {
            let (ok, errs) = this.inner.borrow().validate();
            let t = lua.create_table()?;
            for (i, e) in errs.iter().enumerate() {
                t.set(i + 1, e.clone())?;
            }
            Ok((ok, t))
        });
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
                            fire_step_callbacks(lua, this, step_name, &ctx, &wrapper)?;
                            continue;
                        }
                    }
                    Err(_) => {
                        wrapper.inner.borrow_mut().status = StepStatus::Skipped;
                        fire_step_callbacks(lua, this, step_name, &ctx, &wrapper)?;
                        continue;
                    }
                }
                fire_pipeline_event(
                    lua,
                    this,
                    "step_started",
                    step_name,
                    StepStatus::Running.as_str(),
                    LuaValue::Nil,
                )?;
                let succeeded = wrapper.execute_sync(lua, &ctx, abort_on_fail)?;
                fire_step_callbacks(lua, this, step_name, &ctx, &wrapper)?;
                if !succeeded {
                    cancel_remaining_steps(&this.step_wrappers.borrow(), &order);
                    break;
                }
            }
            finalize_pipeline_result(lua, this, start.elapsed().as_secs_f32())
        });
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
            this.running_threads.borrow_mut().clear();
            this.started_at.borrow_mut().clear();
            let pipeline = this.inner.borrow();
            this.scheduler.borrow_mut().start(&pipeline);
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
            let running_names: Vec<String> =
                this.running_threads.borrow().keys().cloned().collect();
            for step_name in running_names {
                let wrapper = match this.step_wrappers.borrow().get(&step_name).cloned() {
                    Some(w) => w,
                    None => continue,
                };
                let done = execute_async_coroutine_step(lua, this, &step_name, &wrapper, &ctx)?;
                if done {
                    fire_step_callbacks(lua, this, &step_name, &ctx, &wrapper)?;
                    if wrapper.inner.borrow().status == StepStatus::Failed && abort_on_fail {
                        this.step_wrappers.borrow().values().for_each(|w| {
                            let s = w.inner.borrow().status.clone();
                            if s == StepStatus::Pending || s == StepStatus::Waiting {
                                w.inner.borrow_mut().status = StepStatus::Cancelled;
                            }
                        });
                        *this.is_async.borrow_mut() = false;
                        this.scheduler.borrow_mut().reset();
                        return finalize_pipeline_result(
                            lua,
                            this,
                            this.scheduler.borrow().elapsed,
                        )
                        .map(|_| true);
                    }
                }
            }
            let ready_names: Vec<String> = {
                let pipeline = this.inner.borrow();
                this.scheduler.borrow_mut().update(dt, &pipeline)
            };
            for step_name in ready_names {
                let wrapper = match this.step_wrappers.borrow().get(&step_name).cloned() {
                    Some(w) => w,
                    None => continue,
                };
                fire_pipeline_event(
                    lua,
                    this,
                    "step_started",
                    &step_name,
                    StepStatus::Running.as_str(),
                    LuaValue::Nil,
                )?;
                let succeeded = if wrapper.is_async_enabled() {
                    let done = execute_async_coroutine_step(lua, this, &step_name, &wrapper, &ctx)?;
                    if done {
                        fire_step_callbacks(lua, this, &step_name, &ctx, &wrapper)?;
                    }
                    done || wrapper.inner.borrow().status != StepStatus::Failed
                } else {
                    let ok = wrapper.execute_sync(lua, &ctx, abort_on_fail)?;
                    fire_step_callbacks(lua, this, &step_name, &ctx, &wrapper)?;
                    ok
                };
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
                    } else if let Ok(false) = pipeline.are_deps_satisfied(name, &statuses) {
                        w.inner.borrow_mut().status = StepStatus::Skipped;
                        fire_step_callbacks(lua, this, name, &ctx, w)?;
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
        methods.add_method("cancel", |_, this, ()| {
            let wrappers = this.step_wrappers.borrow();
            for w in wrappers.values() {
                let s = w.inner.borrow().status.clone();
                if s == StepStatus::Pending || s == StepStatus::Waiting {
                    w.inner.borrow_mut().status = StepStatus::Cancelled;
                }
            }
            this.running_threads.borrow_mut().clear();
            this.started_at.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            for w in this.step_wrappers.borrow().values() {
                w.inner.borrow_mut().reset();
            }
            *this.context_key.borrow_mut() = None;
            *this.is_async.borrow_mut() = false;
            this.scheduler.borrow_mut().reset();
            this.running_threads.borrow_mut().clear();
            this.started_at.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("isRunning", |_, this, ()| Ok(*this.is_async.borrow()));
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
        methods.add_method("setErrorMode", |_, this, mode: String| {
            let em = ErrorMode::from_str_lua(&mode).map_err(LuaError::runtime)?;
            this.inner.borrow_mut().error_mode = em;
            Ok(())
        });
        methods.add_method("getErrorMode", |_, this, ()| {
            Ok(this.inner.borrow().error_mode.as_str().to_string())
        });
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
        methods.add_method("setOnComplete", |lua, this, cb: Option<LuaFunction>| {
            *this.on_complete_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });
        methods.add_method("setOnStepComplete", |lua, this, cb: Option<LuaFunction>| {
            *this.on_step_complete_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });
        methods.add_method("setOnStepError", |lua, this, cb: Option<LuaFunction>| {
            *this.on_step_error_key.borrow_mut() = match cb {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };
            Ok(())
        });
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });
        methods.add_method("setName", |_, this, name: String| {
            this.inner.borrow_mut().name = name;
            Ok(())
        });
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
                st.set("async", wrapper.is_async_enabled())?;
                if let Some(ref tag) = inner.tag {
                    st.set("tag", tag.clone())?;
                }
                steps_t.set(i, st)?;
                i += 1;
            }
            t.set("steps", steps_t)?;
            Ok(t)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let inner = this.inner.borrow();
            Ok(format!(
                "Pipeline(\"{}\", {} steps)",
                inner.name,
                inner.get_step_count()
            ))
        });
        methods.add_method("type", |_, _, ()| Ok("LPipeline"));
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
        methods.add_method(
            "addBranch",
            |lua,
             this,
             (name, deps_tbl, when_fn, then_fn, else_fn): (
                String,
                LuaTable,
                LuaFunction,
                LuaFunction,
                Option<LuaFunction>,
            )| {
                let dep_names: Vec<String> = deps_tbl
                    .sequence_values::<String>()
                    .collect::<LuaResult<Vec<_>>>()?;
                let guard_name = format!("{}__branch_guard", name);
                let then_name = format!("{}__then", name);
                let else_name = format!("{}__else", name);
                let branch_key = format!("pipeline.branch.{}", name);
                let when_key = lua.create_registry_value(when_fn)?;
                let guard_wrapper = LuaStep::new(PipelineStep::new(guard_name.clone()));
                {
                    let mut inner = guard_wrapper.inner.borrow_mut();
                    inner.deps = dep_names;
                }
                let branch_key_guard = branch_key.clone();
                let when_key_guard = when_key;
                let guard_cb = lua.create_function(move |lua, ctx: LuaTable| {
                    let branch_tbl: LuaTable = match ctx.get("branch") {
                        Ok(t) => t,
                        Err(_) => {
                            let t = lua.create_table()?;
                            ctx.set("branch", t.clone())?;
                            t
                        }
                    };
                    let predicate: LuaFunction = lua.registry_value(&when_key_guard)?;
                    let pass: bool = predicate.call(ctx.clone())?;
                    branch_tbl.set(branch_key_guard.clone(), pass)?;
                    Ok(pass)
                })?;
                *guard_wrapper.callback_key.borrow_mut() =
                    Some(lua.create_registry_value(guard_cb)?);
                let then_wrapper = LuaStep::new(PipelineStep::new(then_name));
                then_wrapper
                    .inner
                    .borrow_mut()
                    .deps
                    .push(guard_name.clone());
                *then_wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(then_fn)?);
                let branch_key_then = branch_key.clone();
                let then_cond = lua.create_function(move |_, ctx: LuaTable| {
                    let branch_tbl: LuaTable = match ctx.get("branch") {
                        Ok(t) => t,
                        Err(_) => return Ok(false),
                    };
                    Ok(branch_tbl
                        .get::<_, bool>(branch_key_then.clone())
                        .unwrap_or(false))
                })?;
                *then_wrapper.condition_key.borrow_mut() =
                    Some(lua.create_registry_value(then_cond)?);
                let else_wrapper = LuaStep::new(PipelineStep::new(else_name));
                else_wrapper
                    .inner
                    .borrow_mut()
                    .deps
                    .push(guard_name.clone());
                let else_cb: LuaFunction = match else_fn {
                    Some(f) => f,
                    None => lua.create_function(|_, _: LuaTable| Ok(LuaValue::Nil))?,
                };
                *else_wrapper.callback_key.borrow_mut() = Some(lua.create_registry_value(else_cb)?);
                let branch_key_else = branch_key;
                let else_cond = lua.create_function(move |_, ctx: LuaTable| {
                    let branch_tbl: LuaTable = match ctx.get("branch") {
                        Ok(t) => t,
                        Err(_) => return Ok(false),
                    };
                    Ok(!branch_tbl
                        .get::<_, bool>(branch_key_else.clone())
                        .unwrap_or(false))
                })?;
                *else_wrapper.condition_key.borrow_mut() =
                    Some(lua.create_registry_value(else_cond)?);
                let mut pipeline = this.inner.borrow_mut();
                pipeline
                    .add_step(guard_wrapper.inner.borrow().clone())
                    .map_err(LuaError::runtime)?;
                pipeline
                    .add_step(then_wrapper.inner.borrow().clone())
                    .map_err(LuaError::runtime)?;
                pipeline
                    .add_step(else_wrapper.inner.borrow().clone())
                    .map_err(LuaError::runtime)?;
                drop(pipeline);
                this.step_wrappers
                    .borrow_mut()
                    .insert(guard_name, guard_wrapper);
                this.step_wrappers
                    .borrow_mut()
                    .insert(format!("{}__then", name), then_wrapper);
                this.step_wrappers
                    .borrow_mut()
                    .insert(format!("{}__else", name), else_wrapper);
                Ok(this.clone())
            },
        );
        methods.add_method("onProgress", |lua, this, cb: LuaFunction| {
            *this.on_progress_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });
        methods.add_method("onEvent", |lua, this, cb: LuaFunction| {
            *this.on_event_key.borrow_mut() = Some(lua.create_registry_value(cb)?);
            Ok(())
        });
        methods.add_method("toAscii", |_, this, ()| {
            Ok(this.inner.borrow().to_ascii_diagram())
        });
        methods.add_method("addSubPipeline", |_, this, (sub_ud, alias, deps_tbl): (mlua::AnyUserData, String, Option<mlua::Table>)| {
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
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPipeline" || name == "Pipeline" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
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
    tbl.set(
        "newPipeline",
        lua.create_function(|_, name: Option<String>| {
            let pipeline = Pipeline::new(name.unwrap_or_else(|| "pipeline".to_string()));
            Ok(LuaPipeline::new(pipeline))
        })?,
    )?;
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
                    if let Ok(async_enabled) = st.get::<_, bool>("async") {
                        step.metadata
                            .insert("__pipeline_async".to_string(), async_enabled.to_string());
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
    lurek.set("pipeline", tbl)?;
    Ok(())
}
