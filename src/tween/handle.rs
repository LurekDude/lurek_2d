//! Lua UserData handle types for the tween system.
//!
//! # Purpose
//!
//! This module defines the three Lua-facing handle types for `lurek.tween`:
//!
//! - [`LuaTween`] — animates named numeric fields on a Lua table over time.
//! - [`LuaTweenSequence`] — runs a list of tween/delay/callback steps in order.
//! - [`LuaTweenParallel`] — runs a group of tween entries simultaneously.
//!
//! Supporting types [`SequenceStep`] and [`ParallelEntry`] are used internally.
//!
//! # Architecture note
//!
//! All three types implement `mlua::LuaUserData` here — in the domain module —
//! rather than in `src/lua_api/tween_api.rs`. This follows the Thin Wrapper Rule:
//! the Lua API file may only contain `pub fn register()` and immediate-delegation
//! closures; all business logic, state machines, and `impl` blocks live here.
//!
//! These types depend on `mlua` for `LuaRegistryKey` lifetime management and
//! UserData registration. `mlua` is a first-class dependency of the whole crate, so
//! domain modules are permitted to import it directly.

use mlua::prelude::*;

use crate::tween::TweenState;

// ─── LuaTween ───────────────────────────────────────────────────────────────

/// Lua UserData for a single property tween: animates named fields on a target table.
///
/// Each `LuaTween` holds a `TweenState` for timing/easing and a `LuaRegistryKey`
/// pointing to the target Lua table. Start values are **lazily captured** — on the
/// first `tick_with()` call the tween reads the current field values from the table,
/// so the target can be freely modified between tween creation and execution.
///
/// # Fields
/// - `state` — `TweenState`. Timing and easing (pure Rust).
/// - `target_key` — `LuaRegistryKey`. Holds the target Lua table.
/// - `fields` — `Vec<String>`. Names of the table fields to animate.
/// - `end_values` — `Vec<f64>`. Target values corresponding to each field.
/// - `start_values` — `Vec<f64>`. Start values (populated lazily).
/// - `starts_captured` — `bool`. Whether start values have been read from the table.
/// - `active` — `bool`. False when completed or cancelled.
/// - `paused` — `bool`. Suspended but not cancelled.
/// - `owned_by_parent` — `bool`. True when adopted by a sequence or parallel.
/// - `repeat_count` — `i32`. Extra play cycles: 0 = none, -1 = infinite.
/// - `cycles_remaining` — `i32`. Countdown for finite repeats.
/// - `yoyo` — `bool`. Alternate direction on each repeat cycle.
/// - `yoyo_reversed` — `bool`. Current direction flag (false = forward).
/// - `custom_easing_key` — `Option<LuaRegistryKey>`. Overrides built-in easing.
/// - `on_complete` — `Option<LuaRegistryKey>`. Callback fired on successful completion.
/// - `on_update` — `Option<LuaRegistryKey>`. Callback fired every tick with eased `t`.
/// - `on_cancel` — `Option<LuaRegistryKey>`. Callback fired on `cancel()`.
pub struct LuaTween {
    /// Pure-Rust timing and easing state.
    pub state: TweenState,
    /// Registry reference to the Lua table being animated.
    pub target_key: LuaRegistryKey,
    /// Names of the table fields to animate.
    pub fields: Vec<String>,
    /// Target (end) value for each field.
    pub end_values: Vec<f64>,
    /// Start values; populated lazily on the first tick.
    start_values: Vec<f64>,
    /// Whether start values have been captured from the target table.
    starts_captured: bool,
    /// Whether this tween is still running.
    pub active: bool,
    /// Whether this tween is paused (time is frozen).
    pub paused: bool,
    /// True when the tween has been adopted by a sequence or parallel.
    /// The global `update()` skips owned tweens; their parent ticks them instead.
    pub owned_by_parent: bool,
    /// Number of additional play cycles after the first: 0 = play once, -1 = infinite.
    pub repeat_count: i32,
    /// Remaining additional cycles for finite repeats.
    pub(crate) cycles_remaining: i32,
    /// When true, reverse direction on each repeat cycle (ping-pong).
    pub yoyo: bool,
    /// Current yoyo direction: false = forward, true = reversed.
    yoyo_reversed: bool,
    /// Optional Lua easing function (overrides built-in easing).
    custom_easing_key: Option<LuaRegistryKey>,
    /// Fired when the tween finishes all cycles.
    pub on_complete: Option<LuaRegistryKey>,
    /// Fired every tick with the current eased `t` (0..=1).
    pub(crate) on_update: Option<LuaRegistryKey>,
    /// Fired when the tween is cancelled before completion.
    pub on_cancel: Option<LuaRegistryKey>,
}

impl LuaTween {
    /// Creates a `LuaTween` that animates named fields of a Lua table.
    ///
    /// Start values are not read here — they are captured on the first tick so the
    /// caller can set up the table between construction and the first `update()` call.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`. Active Lua VM; used to register the target table.
    /// - `duration` — `f64`. Tween duration in seconds.
    /// - `target` — `LuaTable`. The table whose fields will be animated.
    /// - `fields` — `Vec<String>`. Field names to animate.
    /// - `end_values` — `Vec<f64>`. Corresponding target values.
    /// - `easing_name` — `&str`. Built-in easing name or `"linear"`.
    ///
    /// # Returns
    /// `LuaResult<Self>`.
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
            on_complete: None,
            on_update: None,
            on_cancel: None,
        })
    }

    /// Advances the tween by `dt` seconds, writing interpolated values to the
    /// target table. Returns `true` when the tween is fully complete (all cycles
    /// finished). Callback errors are silently ignored so a bad callback cannot
    /// abort the frame.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`. Active Lua VM.
    /// - `dt` — `f64`. Delta-time in seconds.
    ///
    /// # Returns
    /// `LuaResult<bool>` — `true` if done.
    pub fn tick_with(&mut self, lua: &Lua, dt: f64) -> LuaResult<bool> {
        if !self.active || self.paused {
            return Ok(false);
        }

        // ── Lazy start capture ────────────────────────────────────────────
        if !self.starts_captured {
            let table: LuaTable = lua.registry_value(&self.target_key)?;
            self.start_values.clear();
            for field in &self.fields {
                let v: f64 = table.get(field.as_str()).unwrap_or(0.0);
                self.start_values.push(v);
            }
            self.starts_captured = true;
        }

        // ── Advance time ──────────────────────────────────────────────────
        let cycle_done = self.state.tick(dt);

        // ── Compute eased t (custom easing or built-in) ───────────────────
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

        // ── Direction for yoyo ────────────────────────────────────────────
        let effective_t = if self.yoyo && self.yoyo_reversed {
            1.0 - eased_t
        } else {
            eased_t
        };

        // ── Write interpolated values to target table ─────────────────────
        let table: LuaTable = lua.registry_value(&self.target_key)?;
        for (i, field) in self.fields.iter().enumerate() {
            let start = self.start_values[i];
            let end = self.end_values[i];
            let v = start + (end - start) * effective_t;
            table.set(field.as_str(), v)?;
        }

        // ── on_update callback ────────────────────────────────────────────
        if let Some(key) = &self.on_update {
            if let Ok(f) = lua.registry_value::<LuaFunction>(key) {
                let _ = f.call::<_, ()>(effective_t);
            }
        }

        // ── Handle cycle completion ───────────────────────────────────────
        if cycle_done {
            if self.repeat_count == 0 {
                // No repeat — done
                self.active = false;
                self.fire_on_complete(lua);
                return Ok(true);
            } else {
                // Repeating
                let more = if self.repeat_count == -1 {
                    true // infinite
                } else {
                    self.cycles_remaining -= 1;
                    self.cycles_remaining > 0
                };

                if more {
                    // Reset for next cycle
                    if self.yoyo {
                        self.yoyo_reversed = !self.yoyo_reversed;
                    }
                    self.state.reset();
                    // Re-capture starts for next cycle (handles yoyo properly)
                    self.starts_captured = false;
                } else {
                    // All repeat cycles done
                    self.active = false;
                    self.fire_on_complete(lua);
                    return Ok(true);
                }
            }
        }

        Ok(false)
    }

    /// Fires the `on_complete` callback if one is set, then frees the registry key.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    pub fn fire_on_complete(&mut self, lua: &Lua) {
        if let Some(k) = self.on_complete.take() {
            if let Ok(f) = lua.registry_value::<LuaFunction>(&k) {
                let _ = f.call::<_, ()>(());
            }
            let _ = lua.remove_registry_value(k);
        }
    }
}
// ─── SequenceStep ───────────────────────────────────────────────────────────

/// A single step inside a [`LuaTweenSequence`].
///
/// # Variants
/// - `Tween` — Animates named fields on a target Lua table over a duration.
/// - `Delay` — Waits for a given number of seconds; fires an optional callback on expiry.
/// - `Callback` — Immediately fires a Lua function then proceeds to the next step.
pub enum SequenceStep {
    /// Inline tween step: animates target table fields over `state.duration` seconds.
    Tween {
        /// Timing and easing state for this step.
        state: TweenState,
        /// Registry key for the Lua table whose fields are animated.
        target_key: LuaRegistryKey,
        /// Field names on the target table.
        fields: Vec<String>,
        /// Target (end) values for each field.
        end_values: Vec<f64>,
        /// Start values (captured lazily on first tick).
        start_values: Vec<f64>,
        /// Whether start values have been captured from the table.
        starts_captured: bool,
    },
    /// Wait step: pauses the sequence for `duration` seconds before proceeding.
    Delay {
        /// Total wait duration in seconds.
        duration: f64,
        /// Accumulated elapsed time in seconds.
        elapsed: f64,
        /// Optional Lua function called when this delay expires.
        callback: Option<LuaRegistryKey>,
    },
    /// Immediate callback step: fires a Lua function, then advances with remaining dt.
    Callback(LuaRegistryKey),
}

// ─── LuaTweenSequence ───────────────────────────────────────────────────────

/// Lua UserData for an ordered animation sequence: steps run one after another.
///
/// Each step can be a tween, a wait delay, or an arbitrary Lua callback. Steps are
/// added via `:tween()`, `:delay()`, and `:callback()` (all return `self` for builder
/// chaining). The sequence begins executing when `:start()` is called; the `lurek.tween`
/// engine then ticks it each frame via `update(dt)`.
///
/// # Fields
/// - `steps` — `Vec<SequenceStep>`. Ordered list of animation steps.
/// - `current` — `usize`. Index of the currently executing step.
/// - `active` — `bool`. Whether the sequence is running.
/// - `on_complete` — `Option<LuaRegistryKey>`. Fired when all steps finish.
pub struct LuaTweenSequence {
    /// Ordered list of animation steps.
    pub steps: Vec<SequenceStep>,
    /// Index of the currently executing step (0-based).
    current: usize,
    /// Whether the sequence has been started and is still running.
    pub active: bool,
    /// Fired when all steps complete.
    pub(crate) on_complete: Option<LuaRegistryKey>,
}

impl LuaTweenSequence {
    /// Creates an empty, inactive `LuaTweenSequence`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            steps: Vec::new(),
            current: 0,
            active: false,
            on_complete: None,
        }
    }

    /// Advances the sequence by `dt` seconds. Returns `true` when all steps finish.
    ///
    /// Surplus time from completing one step is forwarded into the next, so a very
    /// large `dt` can advance through multiple short steps in a single call.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `dt` — `f64`. Delta-time in seconds.
    ///
    /// # Returns
    /// `LuaResult<bool>` — `true` when the sequence has finished all steps.
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
                    remaining_dt = dt; // callback is instant
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
            return Ok(true);
        }

        Ok(false)
    }
}

impl Default for LuaTweenSequence {
    /// Creates an empty `LuaTweenSequence`. Delegates to `LuaTweenSequence::new()`.
    fn default() -> Self {
        Self::new()
    }
}
// ─── ParallelEntry ──────────────────────────────────────────────────────────

/// An inline tween entry owned and ticked by a [`LuaTweenParallel`].
///
/// Mirrors the fields of `LuaTween` but without registry tracking, callbacks, or
/// repeat/yoyo support — parallel groups are designed for fire-and-forget batches.
///
/// # Fields
/// - `state` — `TweenState`. Timing and easing.
/// - `target_key` — `LuaRegistryKey`. Registry reference to the target Lua table.
/// - `fields` — `Vec<String>`. Field names to animate.
/// - `end_values` — `Vec<f64>`. Target end-values.
/// - `start_values` — `Vec<f64>`. Start values (captured lazily).
/// - `starts_captured` — `bool`. Whether starts have been captured.
/// - `done` — `bool`. True after this entry's tween completes.
pub struct ParallelEntry {
    /// Timing and easing for this entry.
    pub state: TweenState,
    /// Registry reference to the target Lua table.
    pub target_key: LuaRegistryKey,
    /// Field names on the target table.
    pub fields: Vec<String>,
    /// Target end-values for each field.
    pub end_values: Vec<f64>,
    /// Start values (captured lazily on first tick).
    pub start_values: Vec<f64>,
    /// Whether start values have been captured from the table.
    pub starts_captured: bool,
    /// True when this entry's tween has completed.
    pub done: bool,
}

// ─── LuaTweenParallel ───────────────────────────────────────────────────────

/// Lua UserData for a parallel animation group: all child tweens run simultaneously.
///
/// Child tweens are added via `:add(tween)` (adopts an existing `LuaTween`) or
/// created inline with `:tween()`. Call `:start()` to activate the group and register
/// it with the `lurek.tween` engine. The parallel completes when every child entry
/// finishes; `on_complete` fires at that point.
///
/// # Fields
/// - `entries` — `Vec<ParallelEntry>`. Child tween descriptors (ticked in parallel).
/// - `active` — `bool`. Whether the parallel is running.
/// - `on_complete` — `Option<LuaRegistryKey>`. Fired when all children finish.
pub struct LuaTweenParallel {
    /// Child tween entries ticked simultaneously.
    pub entries: Vec<ParallelEntry>,
    /// Whether the parallel has been started and is running.
    pub active: bool,
    /// Fired when all child tweens complete.
    pub(crate) on_complete: Option<LuaRegistryKey>,
}

impl LuaTweenParallel {
    /// Creates an empty, inactive `LuaTweenParallel`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            active: false,
            on_complete: None,
        }
    }

    /// Advances all child entries by `dt` seconds. Returns `true` when every
    /// entry has completed and fires `on_complete` if set.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `dt` — `f64`. Delta-time in seconds.
    ///
    /// # Returns
    /// `LuaResult<bool>` — `true` when all children are done.
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
    /// Creates an empty `LuaTweenParallel`. Delegates to `LuaTweenParallel::new()`.
    fn default() -> Self {
        Self::new()
    }
}
