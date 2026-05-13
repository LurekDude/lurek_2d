//! Scope: Automation script playback and event injection runtime.
//! This file defines Simulator state, playback transitions, and event dispatch plumbing.
//! It owns script lifecycle operations, frame-time advancement, and step-to-event mapping.

use std::collections::HashMap;
use std::path::Path;

use crate::event::{Event, EventArg, EventQueue};
use crate::input::{
    EVENT_KEY_PRESSED, EVENT_KEY_RELEASED, EVENT_MOUSE_MOVED, EVENT_MOUSE_PRESSED,
    EVENT_MOUSE_RELEASED, EVENT_TEXT_INPUT, EVENT_WHEEL_MOVED,
};
use crate::timer::accumulate_scaled_micros;

use super::script::MAX_STEPS;
use super::{Action, Script, Step};
use crate::log_msg;
use crate::runtime::log_messages::{AT01_SIM_INIT, AT02_SCRIPT_LOAD};

// ---- Type: StepEventSink ----

/// Event sink abstraction used by automation playback.
///
/// This decouples `Simulator::update_with_sink` from `EventQueue`, enabling
/// deterministic unit tests with simple mock sinks.
pub trait StepEventSink {
    /// Push an event produced by a simulated step.
    fn push_event(&mut self, event: Event);
}

impl StepEventSink for EventQueue {
    fn push_event(&mut self, event: Event) {
        self.push(event);
    }
}

// ---- Type: PlaybackState ----

/// Current playback state of the [`Simulator`].
///
/// Governs whether [`Simulator::update`] advances the elapsed timer and
/// dispatches steps. The state transitions are:
///
/// | From | To | Trigger |
/// |---|---|---|
/// | `Idle` | `Running` | [`Simulator::start`] called with a loaded script name |
/// | `Running` | `Paused` | [`Simulator::pause`] called |
/// | `Paused` | `Running` | [`Simulator::resume`] called |
/// | `Running` | `Complete` | all steps dispatched during [`Simulator::update`] |
/// | Any | `Idle` | [`Simulator::stop`] called, or active script unloaded |
///
/// # Variants
/// - `Idle` - No script selected or playback explicitly stopped.
/// - `Running` - A script is actively playing; `update` advances elapsed time.
/// - `Paused` - Playback suspended; `update` is a no-op until resumed.
/// - `Complete` - All steps in the active script have been dispatched.
#[derive(Debug, Clone, PartialEq)]
enum PlaybackState {
    /// No script selected or playback stopped.
    ///
    /// The elapsed counter and step index are both `0`. This is the initial
    /// state after construction and after [`Simulator::stop`] is called.
    Idle,
    /// A script is actively playing.
    ///
    /// Each call to [`Simulator::update`] advances `elapsed` and dispatches
    /// any steps whose `time <= elapsed`.
    Running,
    /// Playback suspended at the current step index.
    ///
    /// The elapsed counter is frozen. No steps are dispatched until
    /// [`Simulator::resume`] transitions back to `Running`.
    Paused,
    /// All steps in the active script have been dispatched.
    ///
    /// `elapsed` and `next_step_idx` reflect the final position. No further
    /// steps will fire. Callers should check [`Simulator::is_complete`] and
    /// call [`Simulator::stop`] or [`Simulator::start`] as appropriate.
    Complete,
    /// Playback halted because an automation assertion failed.
    Failed,
}

// ---- Type: Simulator ----

/// Automated input simulation engine.
///
/// Holds a named registry of [`Script`] objects and plays back the active
/// script by injecting synthetic input events into the provided [`EventQueue`]
/// on each [`Simulator::update`] call.
///
/// ## Thread safety
///
/// `Simulator` is not `Send` or `Sync`. It is owned by the main Lua thread
/// via `Rc<RefCell<Simulator>>` and must not be shared across threads.
///
/// # Fields
/// - `scripts` - `HashMap<String, Script>`.
/// - `active_script` - `Option<String>`.
/// - `elapsed` - `f32`.
/// - `next_step_idx` - `usize`.
/// - `state` - `PlaybackState`.
/// - `highlight_mode` - `bool`. When `true`, a game can render an overlay showing current input positions.
#[derive(Debug)]
/// Automated input simulation engine.
pub struct Simulator {
    /// All loaded scripts indexed by their name.
    ///
    /// Names are taken from [`Script::name`]. Loading a script with an
    /// already-registered name replaces the previous entry.
    scripts: HashMap<String, Script>,
    /// Name of the currently active script, if any.
    ///
    /// `None` in `Idle` state. Set by [`Simulator::start`] and cleared by
    /// [`Simulator::stop`] or when the active script is unloaded.
    active_script: Option<String>,
    /// Seconds elapsed since the most recent [`Simulator::start`] call.
    ///
    /// Advanced by each [`Simulator::update`] call when in `Running` state.
    /// Frozen when `Paused`. Reset to `0.0` by [`Simulator::stop`] and
    /// [`Simulator::start`].
    elapsed_micros: u64,
    dt_carry_micros: f64,
    /// Index of the next step to be dispatched in the active script.
    ///
    /// Steps at indices `0..next_step_idx` have already been dispatched.
    /// Reset to `0` by [`Simulator::stop`] and [`Simulator::start`].
    next_step_idx: usize,
    /// Current playback state.
    ///
    /// Controls whether [`Simulator::update`] advances elapsed time and
    /// dispatches steps. See [`PlaybackState`] for the full transition model.
    state: PlaybackState,
    /// Named macro store - scripts saved for later replay with [`Simulator::play_macro`].
    ///
    /// Macros are stored separately from the main script registry so that calling
    /// [`Simulator::play_macro`] does not permanently pollute the script list beyond
    /// the macro's own entry.
    macros: HashMap<String, Script>,
    /// Playback speed multiplier applied to `dt` on every [`Simulator::update`] call.
    ///
    /// Default is `1.0`. Values below `1.0` slow playback; values above `1.0` speed
    /// it up. Clamped to `[0.0, inf)` by [`Simulator::set_playback_speed`].
    playback_speed: f32,
    /// When `true`, a game-side render pass can draw an overlay showing the current
    /// cursor position and key state for each simulated step.
    ///
    /// The engine does not render this overlay itself; the flag is a hint for the
    /// Lua script that calls `lurek.automation:isHighlightMode()`.
    highlight_mode: bool,
    conditions: HashMap<String, bool>,
    last_error: Option<String>,
}

// ---- Implementation: Simulator ----

impl Simulator {
    /// Create a new `Simulator` with an empty script registry.
    ///
    /// The simulator starts in `Idle` state. No scripts are loaded; call
    /// [`Simulator::load`] to register scripts before [`Simulator::start`].
    ///
    /// # Returns
    /// `Simulator`.
    pub fn new() -> Self {
        log_msg!(debug, AT01_SIM_INIT);
        Self {
            scripts: HashMap::new(),
            active_script: None,
            elapsed_micros: 0,
            dt_carry_micros: 0.0,
            next_step_idx: 0,
            state: PlaybackState::Idle,
            macros: HashMap::new(),
            playback_speed: 1.0,
            highlight_mode: false,
            conditions: HashMap::new(),
            last_error: None,
        }
    }

    /// Load a script into the simulator, replacing any script with the same name.
    ///
    /// The script is indexed by [`Script::name`]. If a script with that name
    /// is already registered it is silently overwritten. The active script,
    /// if running, is unaffected unless the new script replaces it - in that
    /// case the replacement takes effect at the next [`Simulator::update`].
    ///
    /// # Parameters
    /// - `script` - `Script`.
    pub fn load(&mut self, script: Script) {
        log_msg!(debug, AT02_SCRIPT_LOAD, "{}", script.name);
        self.scripts.insert(script.name.clone(), script);
    }

    /// Remove a loaded script by name.
    ///
    /// Returns `true` if the script was found and removed, `false` if no
    /// script with that name was loaded. If the removed script is currently
    /// active, [`Simulator::stop`] is called automatically, resetting
    /// playback to `Idle`.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn unload(&mut self, name: &str) -> bool {
        // If the active script is being unloaded, stop playback.
        if self.active_script.as_deref() == Some(name) {
            self.stop();
        }
        self.scripts.remove(name).is_some()
    }

    /// Return `true` if a script with the given name is registered.
    ///
    /// Does not distinguish between whether the script is currently active
    /// or idle. Use [`Simulator::current_script`] to identify the active one.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_script(&self, name: &str) -> bool {
        self.scripts.contains_key(name)
    }

    /// Return the names of all loaded scripts.
    ///
    /// Returns an unordered snapshot of the script registry keys. The
    /// order is not guaranteed to match insertion order. Returns an empty
    /// `Vec` when no scripts are loaded.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_scripts(&self) -> Vec<String> {
        self.scripts.keys().cloned().collect()
    }

    /// Start playback of the named script from the beginning.
    ///
    /// Resets `elapsed` to `0.0` and `next_step_idx` to `0`, then
    /// transitions to `Running`. Calling `start` while already running or
    /// paused restarts the same or a different script from scratch. Returns
    /// `Err` if the script name is not registered.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn start(&mut self, name: &str) -> Result<(), String> {
        if !self.scripts.contains_key(name) {
            return Err(format!("simulator.start: script '{}' is not loaded", name));
        }
        self.active_script = Some(name.to_string());
        self.elapsed_micros = 0;
        self.dt_carry_micros = 0.0;
        self.next_step_idx = 0;
        self.state = PlaybackState::Running;
        self.last_error = None;
        Ok(())
    }

    /// Stop playback and reset the simulator to `Idle`.
    ///
    /// Clears `active_script` to `None`, resets `elapsed` to `0.0`, and
    /// resets `next_step_idx` to `0`. The loaded script registry is not
    /// modified; scripts remain available for a subsequent [`Simulator::start`]
    /// call.
    pub fn stop(&mut self) {
        self.active_script = None;
        self.elapsed_micros = 0;
        self.dt_carry_micros = 0.0;
        self.next_step_idx = 0;
        self.state = PlaybackState::Idle;
    }

    /// Pause playback, freezing `elapsed` and the step index.
    ///
    /// Transitions from `Running` to `Paused`. Has no effect if the
    /// simulator is already paused, idle, or complete.
    pub fn pause(&mut self) {
        if self.state == PlaybackState::Running {
            self.state = PlaybackState::Paused;
        }
    }

    /// Resume paused playback from the current position.
    ///
    /// Transitions from `Paused` to `Running`. Has no effect if the
    /// simulator is idle, already running, or complete.
    pub fn resume(&mut self) {
        if self.state == PlaybackState::Paused {
            self.state = PlaybackState::Running;
        }
    }

    /// Return `true` if the simulator is in the `Running` state.
    ///
    /// Returns `false` when paused, idle, or complete. Use this to gate
    /// code that should only execute while a simulation is actively running.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_running(&self) -> bool {
        self.state == PlaybackState::Running
    }

    /// Return `true` if the simulator is in the `Paused` state.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self) -> bool {
        self.state == PlaybackState::Paused
    }

    /// Return `true` if all steps in the active script have been dispatched.
    ///
    /// Once `true`, no further steps will fire. Callers should call
    /// [`Simulator::stop`] to return to `Idle`, or [`Simulator::start`] to
    /// restart the same or a different script.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_complete(&self) -> bool {
        self.state == PlaybackState::Complete
    }

    /// Return `true` if playback stopped due to a failed assertion.
    pub fn is_failed(&self) -> bool {
        self.state == PlaybackState::Failed
    }

    /// Return the most recent automation failure string.
    pub fn last_error(&self) -> Option<&str> {
        self.last_error.as_deref()
    }

    /// Return the index of the next step to be dispatched.
    ///
    /// Steps at indices `0..current_step()` have already been dispatched.
    /// Returns `0` when idle or when the script has not yet advanced.
    ///
    /// # Returns
    /// `usize`.
    pub fn current_step(&self) -> usize {
        self.next_step_idx
    }

    /// Return the total number of steps in the active script.
    ///
    /// Returns `0` when no script is active or if the active script's entry
    /// has been removed from the registry. The value only changes if the
    /// active script is replaced via [`Simulator::load`].
    ///
    /// # Returns
    /// `usize`.
    pub fn step_count(&self) -> usize {
        self.active_script
            .as_ref()
            .and_then(|name| self.scripts.get(name))
            .map_or(0, |s| s.step_count())
    }

    /// Return the name of the currently active script.
    ///
    /// Returns `None` when the simulator is idle. The name matches the
    /// [`Script::name`] that was passed to the most recent successful
    /// [`Simulator::start`] call.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn current_script(&self) -> Option<&str> {
        self.active_script.as_deref()
    }

    /// Return the seconds elapsed since playback started.
    ///
    /// Returns `0.0` when idle. Frozen at the pause point when paused.
    /// Continues to increase until the script completes or `stop` is called.
    ///
    /// # Returns
    /// `f32`.
    pub fn elapsed_time(&self) -> f32 {
        self.elapsed_micros as f32 / 1_000_000.0
    }

    /// Set a named boolean condition used by `when` and `assert` step fields.
    pub fn set_condition(&mut self, name: String, value: bool) {
        self.conditions.insert(name, value);
    }

    /// Return a named condition value.
    pub fn get_condition(&self, name: &str) -> Option<bool> {
        self.conditions.get(name).copied()
    }

    /// Return a clone of the named script from the registry, if it is loaded.
    ///
    /// Used by [`Simulator::save_macro`] to snapshot an already-loaded script.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `Option<Script>`.
    pub fn get_script(&self, name: &str) -> Option<Script> {
        self.scripts.get(name).cloned()
    }

    /// Return the step limit for the named script.
    ///
    /// Returns `None` if no script with that name is registered.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn get_script_step_limit(&self, name: &str) -> Option<usize> {
        self.scripts.get(name).map(|s| s.get_step_limit())
    }

    /// Set the step limit for the named script (clamped to `1..=MAX_STEPS`).
    ///
    /// Returns `false` if no script with that name is registered.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    /// - `limit` - `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_script_step_limit(&mut self, name: &str, limit: usize) -> bool {
        if let Some(script) = self.scripts.get_mut(name) {
            script.set_step_limit(limit);
            true
        } else {
            false
        }
    }

    /// Save a [`Script`] under a named macro key for later replay.
    ///
    /// The macro is stored separately from the main script registry. Calling
    /// [`Simulator::play_macro`] will clone the saved script into the registry and
    /// start playback.
    ///
    /// # Parameters
    /// - `name` - `String`. The macro identifier.
    /// - `script` - `Script`. The script to save.
    pub fn save_macro(&mut self, name: String, script: Script) {
        self.macros.insert(name, script);
    }

    /// Play a saved macro by loading it into the script registry and starting playback.
    ///
    /// Returns `Err` if no macro with `name` exists.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn play_macro(&mut self, name: &str) -> Result<(), String> {
        let macro_script = self
            .macros
            .get(name)
            .ok_or_else(|| format!("simulator.playMacro: macro '{}' not found", name))?
            .clone();
        let script_name = macro_script.name.clone();
        self.load(macro_script);
        self.start(&script_name)
    }

    /// Return `true` if a macro with the given name has been saved.
    ///
    /// # Parameters
    /// - `name` - `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_macro(&self, name: &str) -> bool {
        self.macros.contains_key(name)
    }

    /// Return the names of all saved macros.
    ///
    /// Returns an unordered snapshot of macro names. Returns an empty `Vec` when
    /// no macros have been saved.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn list_macros(&self) -> Vec<String> {
        self.macros.keys().cloned().collect()
    }

    /// Set the playback speed multiplier applied to `dt` on each [`Simulator::update`].
    ///
    /// Values below `1.0` slow playback; values above `1.0` speed it up.
    /// Clamped to `[0.0, inf)` - negative values are treated as `0.0` (frozen).
    ///
    /// # Parameters
    /// - `factor` - `f32`.
    pub fn set_playback_speed(&mut self, factor: f32) {
        self.playback_speed = factor.max(0.0);
    }

    /// Return the current playback speed multiplier.
    ///
    /// Default is `1.0`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_playback_speed(&self) -> f32 {
        self.playback_speed
    }

    /// Enable or disable the visual highlight overlay hint.
    ///
    /// When `true`, a game-side render pass is expected to draw a highlight
    /// showing the current simulated cursor/key position.  The engine does
    /// not render this overlay; the flag is a hint exposed via
    /// `lurek.automation:isHighlightMode()`.
    ///
    /// # Parameters
    /// - `enable` - `bool`.
    pub fn set_highlight_mode(&mut self, enable: bool) {
        self.highlight_mode = enable;
    }

    /// Return whether the highlight overlay hint is active.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_highlight_mode(&self) -> bool {
        self.highlight_mode
    }

    /// Advance the playback clock by `dt` seconds and dispatch all due steps.
    ///
    /// Adds `dt` to `elapsed` and dispatches every step whose `time <=
    /// elapsed` that has not yet fired. Each dispatched step fires at most
    /// once. When the last step is dispatched, the simulator transitions to
    /// `Complete`. Multiple steps may fire in a single `update` call if
    /// `dt` spans several step times.
    ///
    /// Is a no-op when `state != Running`.
    ///
    /// # Parameters
    /// - `dt` - `f32`. Seconds since the previous frame.
    /// - `event_queue` - `&mut EventQueue`.
    pub fn update(&mut self, dt: f32, event_queue: &mut EventQueue) {
        self.update_with_sink(dt, event_queue);
    }

    /// Advance playback and dispatch due steps into a generic event sink.
    pub fn update_with_sink<S: StepEventSink>(&mut self, dt: f32, event_sink: &mut S) {
        if self.state != PlaybackState::Running {
            return;
        }

        accumulate_scaled_micros(
            &mut self.elapsed_micros,
            &mut self.dt_carry_micros,
            dt,
            self.playback_speed,
        );

        let script_name = match &self.active_script {
            Some(name) => name.clone(),
            None => return,
        };

        // Dispatch all steps whose time has been reached.
        while let Some(step) = self
            .scripts
            .get(&script_name)
            .and_then(|s| s.steps.get(self.next_step_idx))
            .cloned()
        {
            if step_time_micros(&step) > self.elapsed_micros {
                break;
            }

            if let Err(err) = self.execute_step(&script_name, &step, event_sink) {
                self.last_error = Some(err);
                self.state = PlaybackState::Failed;
                break;
            }

            self.next_step_idx += 1;
        }

        if self.state == PlaybackState::Failed {
            return;
        }

        let step_count = self
            .scripts
            .get(&script_name)
            .map(|s| s.steps.len())
            .unwrap_or(0);

        // Check if all steps have been dispatched.
        if self.next_step_idx >= step_count {
            self.state = PlaybackState::Complete;
        }
    }

    fn execute_step<S: StepEventSink>(
        &mut self,
        script_name: &str,
        step: &Step,
        event_sink: &mut S,
    ) -> Result<(), String> {
        if let Some(expr) = step.when.as_deref() {
            if !evaluate_condition_expr(expr, &self.conditions)? {
                return Ok(());
            }
        }

        if let Some(expr) = step.assert.as_deref() {
            if !evaluate_condition_expr(expr, &self.conditions)? {
                return Err(format!(
                    "simulator.assert: expression '{}' is false at step {}",
                    expr, self.next_step_idx
                ));
            }
        }

        match step.action {
            Action::CallMacro => self.expand_macro_step(script_name, step),
            Action::Assert => {
                let expr = step
                    .assert
                    .as_deref()
                    .or(step.when.as_deref())
                    .ok_or_else(|| "simulator.assert: missing 'assert' expression".to_string())?;
                if evaluate_condition_expr(expr, &self.conditions)? {
                    Ok(())
                } else {
                    Err(format!(
                        "simulator.assert action: expression '{}' is false at step {}",
                        expr, self.next_step_idx
                    ))
                }
            }
            Action::VisualAssert => self.run_visual_assert(step),
            Action::Repeat | Action::Wait => Ok(()),
            _ => {
                Self::dispatch_step(step, event_sink);
                Ok(())
            }
        }
    }

    fn expand_macro_step(&mut self, script_name: &str, step: &Step) -> Result<(), String> {
        let macro_name = step
            .macro_name
            .as_deref()
            .ok_or_else(|| "simulator.callMacro: missing step.macro".to_string())?;
        let macro_script = self
            .macros
            .get(macro_name)
            .cloned()
            .ok_or_else(|| format!("simulator.callMacro: macro '{}' not found", macro_name))?;

        let active = self.scripts.get_mut(script_name).ok_or_else(|| {
            format!(
                "simulator.callMacro: active script '{}' not found",
                script_name
            )
        })?;

        let base_time = step.time.max(0.0);
        let mut injected = Vec::with_capacity(macro_script.steps.len());
        for mut nested in macro_script.steps {
            nested.time = base_time + nested.time.max(0.0);
            injected.push(nested);
        }

        let insert_at = self.next_step_idx.saturating_add(1);
        active.steps.splice(insert_at..insert_at, injected);
        if active.steps.len() > MAX_STEPS {
            active.steps.truncate(MAX_STEPS);
        }
        Ok(())
    }

    fn run_visual_assert(&self, step: &Step) -> Result<(), String> {
        let baseline = step
            .baseline
            .as_deref()
            .ok_or_else(|| "simulator.visualAssert: missing 'baseline'".to_string())?;
        let actual = step
            .actual
            .as_deref()
            .ok_or_else(|| "simulator.visualAssert: missing 'actual'".to_string())?;
        let max_diff = step.max_diff.unwrap_or(0);
        let diff = diff_images(Path::new(baseline), Path::new(actual))?;
        if diff > max_diff {
            Err(format!(
                "simulator.visualAssert: diff {} exceeds maxDiff {} for '{}' vs '{}'",
                diff, max_diff, actual, baseline
            ))
        } else {
            Ok(())
        }
    }

    /// Translate a [`Step`] into a synthetic [`Event`] and push it into the queue.
    ///
    /// Each `Action` variant maps to a specific event name and argument list:
    /// - `KeyPress` ->’ `"keypressed"` with `(key, scancode, is_repeat)`
    /// - `KeyRelease` ->’ `"keyreleased"` with `(key, scancode)`
    /// - `MouseMove` ->’ `"mousemoved"` with `(x, y, dx, dy)`
    /// - `MousePress` ->’ `"mousepressed"` with `(x, y, button, false, clicks)`
    /// - `MouseRelease` ->’ `"mousereleased"` with `(x, y, button)`
    /// - `MouseWheel` ->’ `"wheelmoved"` with `(dx, dy)`
    /// - `TextInput` ->’ `"textinput"` with `(text)`
    /// - `Wait` ->’ no event pushed (pure delay)
    fn dispatch_step<S: StepEventSink>(step: &Step, event_queue: &mut S) {
        match step.action {
            Action::KeyPress => {
                let key = step.key.as_deref().unwrap_or("unknown");
                let scancode = step.effective_scancode().unwrap_or(key);
                event_queue.push_event(Event {
                    name: EVENT_KEY_PRESSED.to_string(),
                    args: vec![
                        EventArg::Str(key.to_string()),
                        EventArg::Str(scancode.to_string()),
                        EventArg::Bool(step.is_repeat),
                    ],
                });
            }
            Action::KeyRelease => {
                let key = step.key.as_deref().unwrap_or("unknown");
                let scancode = step.effective_scancode().unwrap_or(key);
                event_queue.push_event(Event {
                    name: EVENT_KEY_RELEASED.to_string(),
                    args: vec![
                        EventArg::Str(key.to_string()),
                        EventArg::Str(scancode.to_string()),
                    ],
                });
            }
            Action::MouseMove => {
                let x = step.x.unwrap_or(0.0);
                let y = step.y.unwrap_or(0.0);
                let dx = step.dx.unwrap_or(0.0);
                let dy = step.dy.unwrap_or(0.0);
                event_queue.push_event(Event {
                    name: EVENT_MOUSE_MOVED.to_string(),
                    args: vec![
                        EventArg::Num(x),
                        EventArg::Num(y),
                        EventArg::Num(dx),
                        EventArg::Num(dy),
                    ],
                });
            }
            Action::MousePress => {
                let x = step.x.unwrap_or(0.0);
                let y = step.y.unwrap_or(0.0);
                let button = step.button.unwrap_or(1) as f64;
                let clicks = step.clicks.unwrap_or(1) as f64;
                event_queue.push_event(Event {
                    name: EVENT_MOUSE_PRESSED.to_string(),
                    args: vec![
                        EventArg::Num(x),
                        EventArg::Num(y),
                        EventArg::Num(button),
                        EventArg::Bool(false),
                        EventArg::Num(clicks),
                    ],
                });
            }
            Action::MouseRelease => {
                let x = step.x.unwrap_or(0.0);
                let y = step.y.unwrap_or(0.0);
                let button = step.button.unwrap_or(1) as f64;
                event_queue.push_event(Event {
                    name: EVENT_MOUSE_RELEASED.to_string(),
                    args: vec![EventArg::Num(x), EventArg::Num(y), EventArg::Num(button)],
                });
            }
            Action::MouseWheel => {
                let x = step.x.unwrap_or(0.0);
                let y = step.y.unwrap_or(0.0);
                event_queue.push_event(Event {
                    name: EVENT_WHEEL_MOVED.to_string(),
                    args: vec![EventArg::Num(x), EventArg::Num(y)],
                });
            }
            Action::TextInput => {
                let text = step.text.as_deref().unwrap_or("");
                event_queue.push_event(Event {
                    name: EVENT_TEXT_INPUT.to_string(),
                    args: vec![EventArg::Str(text.to_string())],
                });
            }
            Action::Wait
            | Action::Repeat
            | Action::CallMacro
            | Action::Assert
            | Action::VisualAssert => {
                // No-op - just a timed delay.
            }
        }
    }
}

fn step_time_micros(step: &Step) -> u64 {
    (step.time.max(0.0) as f64 * 1_000_000.0).round() as u64
}

fn evaluate_condition_expr(expr: &str, conditions: &HashMap<String, bool>) -> Result<bool, String> {
    let mut parser = ConditionParser::new(expr);
    let value = parser.parse_expr(conditions)?;
    parser.skip_ws();
    if parser.is_eof() {
        Ok(value)
    } else {
        Err(format!(
            "simulator.condition: trailing input in expression '{}' at byte {}",
            expr, parser.idx
        ))
    }
}

struct ConditionParser<'a> {
    src: &'a str,
    idx: usize,
}

impl<'a> ConditionParser<'a> {
    fn new(src: &'a str) -> Self {
        Self { src, idx: 0 }
    }

    fn is_eof(&self) -> bool {
        self.idx >= self.src.len()
    }

    fn skip_ws(&mut self) {
        while let Some(ch) = self.peek_char() {
            if ch.is_whitespace() {
                self.idx += ch.len_utf8();
            } else {
                break;
            }
        }
    }

    fn peek_char(&self) -> Option<char> {
        self.src[self.idx..].chars().next()
    }

    fn eat(&mut self, token: &str) -> bool {
        self.skip_ws();
        if self.src[self.idx..].starts_with(token) {
            self.idx += token.len();
            true
        } else {
            false
        }
    }

    fn parse_expr(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        self.parse_or(conditions)
    }

    fn parse_or(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        let mut lhs = self.parse_and(conditions)?;
        loop {
            if self.eat("||") {
                let rhs = self.parse_and(conditions)?;
                lhs = lhs || rhs;
            } else {
                break;
            }
        }
        Ok(lhs)
    }

    fn parse_and(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        let mut lhs = self.parse_not(conditions)?;
        loop {
            if self.eat("&&") {
                let rhs = self.parse_not(conditions)?;
                lhs = lhs && rhs;
            } else {
                break;
            }
        }
        Ok(lhs)
    }

    fn parse_not(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        if self.eat("!") {
            Ok(!self.parse_not(conditions)?)
        } else {
            self.parse_primary(conditions)
        }
    }

    fn parse_primary(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        self.skip_ws();
        if self.eat("(") {
            let value = self.parse_expr(conditions)?;
            if !self.eat(")") {
                return Err(format!(
                    "simulator.condition: expected ')' in expression '{}'",
                    self.src
                ));
            }
            return Ok(value);
        }

        let ident = self.parse_identifier();
        match ident.as_deref() {
            Some("true") => Ok(true),
            Some("false") => Ok(false),
            Some(name) => Ok(conditions.get(name).copied().unwrap_or(false)),
            None => Err(format!(
                "simulator.condition: expected identifier in expression '{}' at byte {}",
                self.src, self.idx
            )),
        }
    }

    fn parse_identifier(&mut self) -> Option<String> {
        self.skip_ws();
        let mut end = self.idx;
        for ch in self.src[self.idx..].chars() {
            if ch.is_ascii_alphanumeric() || matches!(ch, '_' | '.' | '-') {
                end += ch.len_utf8();
            } else {
                break;
            }
        }
        if end == self.idx {
            None
        } else {
            let ident = self.src[self.idx..end].to_string();
            self.idx = end;
            Some(ident)
        }
    }
}

fn diff_images(baseline: &Path, actual: &Path) -> Result<u32, String> {
    let base = ::image::open(baseline)
        .map_err(|e| {
            format!(
                "visualAssert baseline load failed ({}): {}",
                baseline.display(),
                e
            )
        })?
        .to_rgba8();
    let act = ::image::open(actual)
        .map_err(|e| {
            format!(
                "visualAssert actual load failed ({}): {}",
                actual.display(),
                e
            )
        })?
        .to_rgba8();

    let (bw, bh) = base.dimensions();
    let (aw, ah) = act.dimensions();
    let shared_w = bw.min(aw);
    let shared_h = bh.min(ah);
    let mut total = 0u64;

    for y in 0..shared_h {
        for x in 0..shared_w {
            let b = base.get_pixel(x, y).0;
            let a = act.get_pixel(x, y).0;
            for c in 0..4 {
                total += (b[c] as i32 - a[c] as i32).unsigned_abs() as u64;
            }
        }
    }

    let shared_pixels = (shared_w as u64) * (shared_h as u64);
    let base_pixels = (bw as u64) * (bh as u64);
    let act_pixels = (aw as u64) * (ah as u64);
    let unmatched = (base_pixels - shared_pixels) + (act_pixels - shared_pixels);
    total += unmatched * 4 * 255;

    Ok(total.min(u32::MAX as u64) as u32)
}

impl Default for Simulator {
    fn default() -> Self {
        Self::new()
    }
}

// Tests migrated to tests/rust/unit/automation_tests.rs
