//! Lua-visible tween, sequence, and parallel handle types for `lurek.tween`.
//! Owns `LuaTween`, `LuaTweenSequence`, `LuaTweenParallel`, `SequenceStep`,
//! and `ParallelEntry`. Business logic lives here; `TweenEngine` drives the
//! per-frame calls. Depends on mlua registry and `tween::state::TweenState`.

use crate::tween::TweenState;
use mlua::prelude::*;

/// Lua-side handle for a single field-interpolating tween; driven by `TweenEngine`.
pub struct LuaTween {
    /// Easing state tracking progress, duration, and the easing curve.
    pub state: TweenState,
    /// Lua registry key for the table whose fields are being animated.
    pub target_key: LuaRegistryKey,
    /// Names of the table fields being animated, parallel to `end_values`.
    pub fields: Vec<String>,
    /// Target field values at t=1; parallel to `fields`.
    pub end_values: Vec<f64>,
    /// Captured field values at t=0; populated on first tick.
    start_values: Vec<f64>,
    /// True once `start_values` have been read from the target table.
    starts_captured: bool,
    /// False when the tween is finished or cancelled; `TweenEngine` removes it next frame.
    pub active: bool,
    /// True when `update` should skip this tween without advancing it.
    pub paused: bool,
    /// True when owned by a sequence or parallel; prevents double-advancing.
    pub owned_by_parent: bool,
    /// Number of extra repeats; 0 = play once, -1 = infinite, >0 = that many extra cycles.
    pub repeat_count: i32,
    /// Countdown of remaining cycles, set from `repeat_count` on start.
    pub(crate) cycles_remaining: i32,
    /// True if the tween reverses direction on alternate cycles.
    pub yoyo: bool,
    /// True during a reversed yoyo cycle.
    yoyo_reversed: bool,
    /// Registry key for a custom Lua easing function `(t: number) -> number`.
    custom_easing_key: Option<LuaRegistryKey>,
    /// True if `end_values` are offsets from the start rather than absolute targets.
    pub relative: bool,
    /// Coroutine registry keys waiting for this tween to complete.
    pub waiters: Vec<LuaRegistryKey>,
    /// Optional Lua callback invoked once when the tween completes normally.
    pub on_complete: Option<LuaRegistryKey>,
    /// Optional Lua callback invoked each tick with the current eased `t`.
    pub(crate) on_update: Option<LuaRegistryKey>,
    /// Optional Lua callback invoked if the tween is cancelled before completion.
    pub on_cancel: Option<LuaRegistryKey>,
}

impl LuaTween {
    /// Create a new active tween targeting `fields` of `target` over `duration` seconds using `easing_name`.
    pub fn new(
        lua: &Lua,
        duration: f64,
        target: LuaTable,
        fields: Vec<String>,
        end_values: Vec<f64>,
        easing_name: &str,
    ) -> LuaResult<Self> {
        let target_key = lua.create_registry_value(target)?;
        let n = fields.len();
        Ok(Self {
            state: TweenState::new(duration, easing_name),
            target_key,
            fields,
            end_values,
            start_values: Vec::with_capacity(n),
            starts_captured: false,
            active: true,
            paused: false,
            owned_by_parent: false,
            repeat_count: 0,
            cycles_remaining: 0,
            yoyo: false,
            yoyo_reversed: false,
            custom_easing_key: None,
            relative: false,
            waiters: Vec::new(),
            on_complete: None,
            on_update: None,
            on_cancel: None,
        })
    }

    /// Advance the tween by `dt` seconds, write interpolated values to the target table,
    /// fire `on_update`, handle repeats and yoyo; return true when fully done.
    pub fn tick_with(&mut self, lua: &Lua, dt: f64) -> LuaResult<bool> {
        if !self.active || self.paused {
            return Ok(false);
        }
        if !self.starts_captured {
            let table: LuaTable = lua.registry_value(&self.target_key)?;
            self.start_values.clear();
            for field in &self.fields {
                let v: f64 = table.get(field.as_str()).unwrap_or(0.0);
                self.start_values.push(v);
            }
            self.starts_captured = true;
        }
        let cycle_done = self.state.tick(dt);
        let eased_t: f64 = if let Some(key) = &self.custom_easing_key {
            match lua.registry_value::<LuaFunction>(key) {
                Ok(f) => f
                    .call::<_, f64>(self.state.t_raw() as f64)
                    .unwrap_or(self.state.t_eased()),
                Err(_) => self.state.t_eased(),
            }
        } else {
            self.state.t_eased()
        };
        let effective_t = if self.yoyo && self.yoyo_reversed {
            1.0 - eased_t
        } else {
            eased_t
        };
        let table: LuaTable = lua.registry_value(&self.target_key)?;
        for (i, field) in self.fields.iter().enumerate() {
            let start = self.start_values[i];
            let target = if self.relative {
                start + self.end_values[i]
            } else {
                self.end_values[i]
            };
            let v = start + (target - start) * effective_t;
            table.set(field.as_str(), v)?;
        }
        if let Some(key) = &self.on_update {
            if let Ok(f) = lua.registry_value::<LuaFunction>(key) {
                let _ = f.call::<_, ()>(effective_t);
            }
        }
        if cycle_done {
            if self.repeat_count == 0 {
                self.active = false;
                self.fire_on_complete(lua);
                self.resume_waiters(lua)?;
                return Ok(true);
            } else {
                let more = if self.repeat_count == -1 {
                    true
                } else {
                    self.cycles_remaining -= 1;
                    self.cycles_remaining > 0
                };
                if more {
                    if self.yoyo {
                        self.yoyo_reversed = !self.yoyo_reversed;
                    }
                    self.state.reset();
                    self.starts_captured = false;
                } else {
                    self.active = false;
                    self.fire_on_complete(lua);
                    self.resume_waiters(lua)?;
                    return Ok(true);
                }
            }
        }
        Ok(false)
    }

    /// Consume and call the `on_complete` registry callback if one is set.
    pub fn fire_on_complete(&mut self, lua: &Lua) {
        if let Some(k) = self.on_complete.take() {
            if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                let _ = f.call::<_, ()>(());
            }
            let _ = lua.remove_registry_value(k);
        }
    }

    /// Set whether `end_values` are absolute targets or offsets from start; resets start capture.
    pub fn set_relative(&mut self, enabled: bool) {
        self.relative = enabled;
        self.starts_captured = false;
    }

    /// Push a coroutine registry key to be resumed when this tween completes.
    pub fn add_waiter(&mut self, waiter: LuaRegistryKey) {
        self.waiters.push(waiter);
    }

    /// Resume all registered waiter coroutines and remove their registry entries.
    pub fn resume_waiters(&mut self, lua: &Lua) -> LuaResult<()> {
        let waiters = std::mem::take(&mut self.waiters);
        for key in waiters {
            if let Ok(LuaValue::Thread(thread)) = lua.registry_value::<LuaValue>(&key) {
                let _ = thread.resume::<_, ()>(());
            }
            lua.remove_registry_value(key)?;
        }
        Ok(())
    }

    /// Return the raw (uneased) progress in [0.0, 1.0] as of the last tick.
    pub fn progress(&self) -> f64 {
        self.state.t_raw() as f64
    }

    /// Return elapsed seconds since the tween started.
    pub fn elapsed(&self) -> f64 {
        self.state.elapsed
    }

    /// Return seconds remaining until the tween completes; clamped to >= 0.0.
    pub fn remaining(&self) -> f64 {
        (self.state.duration - self.state.elapsed).max(0.0)
    }
}

/// One step inside a `LuaTweenSequence`; either a field tween, a timed delay, or an instant callback.
pub enum SequenceStep {
    /// Interpolate `fields` on the target table from their current values to `end_values`.
    Tween {
        /// Easing state for this step.
        state: TweenState,
        /// Registry key for the target Lua table.
        target_key: LuaRegistryKey,
        /// Field names to animate.
        fields: Vec<String>,
        /// Target values at t=1.
        end_values: Vec<f64>,
        /// Captured start values at t=0.
        start_values: Vec<f64>,
        /// True once start values have been read.
        starts_captured: bool,
    },
    /// Wait for `duration` seconds; optionally fire `callback` when done.
    Delay {
        /// Total delay in seconds.
        duration: f64,
        /// Seconds elapsed so far in this delay.
        elapsed: f64,
        /// Optional Lua callback to call when the delay expires.
        callback: Option<LuaRegistryKey>,
    },
    /// Fire a Lua callback instantly and advance to the next step.
    Callback(LuaRegistryKey),
}

/// Ordered sequence of tween steps and delays; advanced one step at a time each tick.
pub struct LuaTweenSequence {
    /// Ordered list of steps; each is executed in order.
    pub steps: Vec<SequenceStep>,
    /// Index of the step currently executing.
    current: usize,
    /// False when the sequence has finished or been cancelled.
    pub active: bool,
    /// Optional Lua callback called when all steps complete.
    pub(crate) on_complete: Option<LuaRegistryKey>,
    /// Coroutine registry keys waiting for this sequence to complete.
    pub waiters: Vec<LuaRegistryKey>,
}

impl LuaTweenSequence {
    /// Create an empty, inactive sequence with no steps or callbacks.
    pub fn new() -> Self {
        Self {
            steps: Vec::new(),
            current: 0,
            active: false,
            on_complete: None,
            waiters: Vec::new(),
        }
    }

    /// Advance the sequence by `dt` seconds, consuming as many steps as time allows; return true when all steps are done.
    pub fn tick_with(&mut self, lua: &Lua, dt: f64) -> LuaResult<bool> {
        if !self.active || self.current >= self.steps.len() {
            return Ok(true);
        }
        let mut remaining_dt = dt;
        while remaining_dt > 0.0 && self.current < self.steps.len() {
            let step_done = match &mut self.steps[self.current] {
                SequenceStep::Tween {
                    state,
                    target_key,
                    fields,
                    end_values,
                    start_values,
                    starts_captured,
                } => {
                    if !*starts_captured {
                        let table: LuaTable = lua.registry_value(target_key)?;
                        start_values.clear();
                        for field in fields.iter() {
                            let v: f64 = table.get(field.as_str()).unwrap_or(0.0);
                            start_values.push(v);
                        }
                        *starts_captured = true;
                    }
                    let done = state.tick(remaining_dt);
                    let t = state.t_eased();
                    let table: LuaTable = lua.registry_value(target_key)?;
                    for (i, field) in fields.iter().enumerate() {
                        let start = start_values[i];
                        let end = end_values[i];
                        table.set(field.as_str(), start + (end - start) * t)?;
                    }
                    if done {
                        remaining_dt = (state.elapsed - state.duration).max(0.0);
                    } else {
                        remaining_dt = 0.0;
                    }
                    done
                }
                SequenceStep::Delay {
                    duration,
                    elapsed,
                    callback,
                } => {
                    *elapsed += remaining_dt;
                    let done = *elapsed >= *duration;
                    if done {
                        remaining_dt = (*elapsed - *duration).max(0.0);
                        if let Some(key) = callback.take() {
                            if let Ok(f) = lua.registry_value::<LuaFunction>(&key) {
                                let _ = f.call::<_, ()>(());
                            }
                            lua.remove_registry_value(key)?;
                        }
                    } else {
                        remaining_dt = 0.0;
                    }
                    done
                }
                SequenceStep::Callback(key) => {
                    if let Ok(f) = lua.registry_value::<LuaFunction>(key) {
                        let _ = f.call::<_, ()>(());
                    }
                    remaining_dt = dt;
                    true
                }
            };
            if step_done {
                self.current += 1;
            } else {
                break;
            }
        }
        if self.current >= self.steps.len() {
            self.active = false;
            if let Some(k) = self.on_complete.take() {
                if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                    let _ = f.call::<_, ()>(());
                }
                lua.remove_registry_value(k)?;
            }
            self.resume_waiters(lua)?;
            return Ok(true);
        }
        Ok(false)
    }

    /// Return the fraction [0.0, 1.0] of steps completed; 1.0 when inactive or empty.
    pub fn progress_ratio(&self) -> f64 {
        if self.steps.is_empty() {
            return 1.0;
        }
        let done = if self.active {
            self.current
        } else {
            self.steps.len()
        };
        (done as f64 / self.steps.len() as f64).clamp(0.0, 1.0)
    }

    /// Push a coroutine registry key to be resumed when this sequence completes.
    pub fn add_waiter(&mut self, waiter: LuaRegistryKey) {
        self.waiters.push(waiter);
    }

    /// Resume all registered waiter coroutines and remove their registry entries.
    pub fn resume_waiters(&mut self, lua: &Lua) -> LuaResult<()> {
        let waiters = std::mem::take(&mut self.waiters);
        for key in waiters {
            if let Ok(LuaValue::Thread(thread)) = lua.registry_value::<LuaValue>(&key) {
                let _ = thread.resume::<_, ()>(());
            }
            lua.remove_registry_value(key)?;
        }
        Ok(())
    }
}

/// Provide `LuaTweenSequence::new()` as the default constructor.
impl Default for LuaTweenSequence {
    fn default() -> Self {
        Self::new()
    }
}

/// One animation lane inside a `LuaTweenParallel` group.
pub struct ParallelEntry {
    /// Easing state for this lane.
    pub state: TweenState,
    /// Registry key for the target Lua table.
    pub target_key: LuaRegistryKey,
    /// Field names to animate in this lane.
    pub fields: Vec<String>,
    /// Target values at t=1 for each field.
    pub end_values: Vec<f64>,
    /// Captured start values at t=0 for each field.
    pub start_values: Vec<f64>,
    /// True once start values have been read from the target table.
    pub starts_captured: bool,
    /// True when this lane has finished animating.
    pub done: bool,
}

/// Group of parallel animation lanes all running simultaneously; completes when every lane is done.
pub struct LuaTweenParallel {
    /// All animation lanes in this group.
    pub entries: Vec<ParallelEntry>,
    /// False when all lanes are done or the group was cancelled.
    pub active: bool,
    /// Optional Lua callback called when all entries complete.
    pub(crate) on_complete: Option<LuaRegistryKey>,
}

impl LuaTweenParallel {
    /// Create an empty, inactive parallel group.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            active: false,
            on_complete: None,
        }
    }

    /// Advance all incomplete lanes by `dt` seconds; return true when every lane is done.
    pub fn tick_with(&mut self, lua: &Lua, dt: f64) -> LuaResult<bool> {
        if !self.active {
            return Ok(true);
        }
        for entry in &mut self.entries {
            if entry.done {
                continue;
            }
            if !entry.starts_captured {
                let table: LuaTable = lua.registry_value(&entry.target_key)?;
                entry.start_values.clear();
                for field in &entry.fields {
                    let v: f64 = table.get(field.as_str()).unwrap_or(0.0);
                    entry.start_values.push(v);
                }
                entry.starts_captured = true;
            }
            let cycle_done = entry.state.tick(dt);
            let t = entry.state.t_eased();
            let table: LuaTable = lua.registry_value(&entry.target_key)?;
            for (i, field) in entry.fields.iter().enumerate() {
                let start = entry.start_values[i];
                let end = entry.end_values[i];
                table.set(field.as_str(), start + (end - start) * t)?;
            }
            if cycle_done {
                entry.done = true;
            }
        }
        let all_done = self.entries.iter().all(|e| e.done);
        if all_done {
            self.active = false;
            if let Some(k) = self.on_complete.take() {
                if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                    let _ = f.call::<_, ()>(());
                }
                lua.remove_registry_value(k)?;
            }
            return Ok(true);
        }
        Ok(false)
    }
}

/// Provide `LuaTweenParallel::new()` as the default constructor.
impl Default for LuaTweenParallel {
    fn default() -> Self {
        Self::new()
    }
}
