use crate::tween::TweenState;
use mlua::prelude::*;
pub struct LuaTween {
    pub state: TweenState,
    pub target_key: LuaRegistryKey,
    pub fields: Vec<String>,
    pub end_values: Vec<f64>,
    start_values: Vec<f64>,
    starts_captured: bool,
    pub active: bool,
    pub paused: bool,
    pub owned_by_parent: bool,
    pub repeat_count: i32,
    pub(crate) cycles_remaining: i32,
    pub yoyo: bool,
    yoyo_reversed: bool,
    custom_easing_key: Option<LuaRegistryKey>,
    pub relative: bool,
    pub waiters: Vec<LuaRegistryKey>,
    pub on_complete: Option<LuaRegistryKey>,
    pub(crate) on_update: Option<LuaRegistryKey>,
    pub on_cancel: Option<LuaRegistryKey>,
}
impl LuaTween {
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
    pub fn fire_on_complete(&mut self, lua: &Lua) {
        if let Some(k) = self.on_complete.take() {
            if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                let _ = f.call::<_, ()>(());
            }
            let _ = lua.remove_registry_value(k);
        }
    }
    pub fn set_relative(&mut self, enabled: bool) {
        self.relative = enabled;
        self.starts_captured = false;
    }
    pub fn add_waiter(&mut self, waiter: LuaRegistryKey) {
        self.waiters.push(waiter);
    }
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
    pub fn progress(&self) -> f64 {
        self.state.t_raw() as f64
    }
    pub fn elapsed(&self) -> f64 {
        self.state.elapsed
    }
    pub fn remaining(&self) -> f64 {
        (self.state.duration - self.state.elapsed).max(0.0)
    }
}
pub enum SequenceStep {
    Tween {
        state: TweenState,
        target_key: LuaRegistryKey,
        fields: Vec<String>,
        end_values: Vec<f64>,
        start_values: Vec<f64>,
        starts_captured: bool,
    },
    Delay {
        duration: f64,
        elapsed: f64,
        callback: Option<LuaRegistryKey>,
    },
    Callback(LuaRegistryKey),
}
pub struct LuaTweenSequence {
    pub steps: Vec<SequenceStep>,
    current: usize,
    pub active: bool,
    pub(crate) on_complete: Option<LuaRegistryKey>,
    pub waiters: Vec<LuaRegistryKey>,
}
impl LuaTweenSequence {
    pub fn new() -> Self {
        Self {
            steps: Vec::new(),
            current: 0,
            active: false,
            on_complete: None,
            waiters: Vec::new(),
        }
    }
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
    pub fn add_waiter(&mut self, waiter: LuaRegistryKey) {
        self.waiters.push(waiter);
    }
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
impl Default for LuaTweenSequence {
    fn default() -> Self {
        Self::new()
    }
}
pub struct ParallelEntry {
    pub state: TweenState,
    pub target_key: LuaRegistryKey,
    pub fields: Vec<String>,
    pub end_values: Vec<f64>,
    pub start_values: Vec<f64>,
    pub starts_captured: bool,
    pub done: bool,
}
pub struct LuaTweenParallel {
    pub entries: Vec<ParallelEntry>,
    pub active: bool,
    pub(crate) on_complete: Option<LuaRegistryKey>,
}
impl LuaTweenParallel {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            active: false,
            on_complete: None,
        }
    }
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
impl Default for LuaTweenParallel {
    fn default() -> Self {
        Self::new()
    }
}
