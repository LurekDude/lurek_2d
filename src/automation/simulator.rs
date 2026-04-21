//! Playback engine for the automation simulation module.
//!
//! This module provides the [`Simulator`] struct and the private
//! [`PlaybackState`] enum that drives it. The [`Simulator`] holds a named
//! collection of [`Script`] objects and plays back the active script by
//! injecting synthetic input events into the engine's [`EventQueue`] on each
//! [`Simulator::update`] call.
//!
//! ## Playback lifecycle
//!
//! 1. Load one or more scripts with [`Simulator::load`].
//! 2. Call [`Simulator::start`] to select a script and begin playback.
//! 3. Call [`Simulator::update`] once per frame, passing the delta time.
//! 4. The simulator advances its internal elapsed counter and dispatches all
//!    steps whose `time <= elapsed`. Each step fires at most once.
//! 5. When all steps are dispatched the state transitions to `Complete`.
//!
//! Playback can be paused and resumed at any point. Stopping resets the
//! elapsed counter and step index back to zero.

use std::collections::HashMap;

use crate::event::{Event, EventArg, EventQueue};

use super::{Action, Script, Step};
use crate::log_msg;
use crate::runtime::log_messages::{AT01_SIM_INIT, AT02_SCRIPT_LOAD};

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
/// - `Idle` â€” No script selected or playback explicitly stopped.
/// - `Running` â€” A script is actively playing; `update` advances elapsed time.
/// - `Paused` â€” Playback suspended; `update` is a no-op until resumed.
/// - `Complete` â€” All steps in the active script have been dispatched.
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
}

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
/// - `scripts` â€” `HashMap<String, Script>`.
/// - `active_script` â€” `Option<String>`.
/// - `elapsed` â€” `f32`.
/// - `next_step_idx` â€” `usize`.
/// - `state` â€” `PlaybackState`.
/// - `highlight_mode` â€” `bool`. When `true`, a game can render an overlay showing current input positions.
#[derive(Debug)]
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
    elapsed: f32,
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
    /// Named macro store â€” scripts saved for later replay with [`Simulator::play_macro`].
    ///
    /// Macros are stored separately from the main script registry so that calling
    /// [`Simulator::play_macro`] does not permanently pollute the script list beyond
    /// the macro's own entry.
    macros: HashMap<String, Script>,
    /// Playback speed multiplier applied to `dt` on every [`Simulator::update`] call.
    ///
    /// Default is `1.0`. Values below `1.0` slow playback; values above `1.0` speed
    /// it up. Clamped to `[0.0, âˆž)` by [`Simulator::set_playback_speed`].
    playback_speed: f32,
    /// When `true`, a game-side render pass can draw an overlay showing the current
    /// cursor position and key state for each simulated step.
    ///
    /// The engine does not render this overlay itself; the flag is a hint for the
    /// Lua script that calls `lurek.automation:isHighlightMode()`.
    highlight_mode: bool,
}

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
            elapsed: 0.0,
            next_step_idx: 0,
            state: PlaybackState::Idle,
            macros: HashMap::new(),
            playback_speed: 1.0,
            highlight_mode: false,
        }
    }

    /// Load a script into the simulator, replacing any script with the same name.
    ///
    /// The script is indexed by [`Script::name`]. If a script with that name
    /// is already registered it is silently overwritten. The active script,
    /// if running, is unaffected unless the new script replaces it â€” in that
    /// case the replacement takes effect at the next [`Simulator::update`].
    ///
    /// # Parameters
    /// - `script` â€” `Script`.
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
    /// - `name` â€” `&str`.
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
    /// - `name` â€” `&str`.
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
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn start(&mut self, name: &str) -> Result<(), String> {
        if !self.scripts.contains_key(name) {
            return Err(format!("simulator.start: script '{}' is not loaded", name));
        }
        self.active_script = Some(name.to_string());
        self.elapsed = 0.0;
        self.next_step_idx = 0;
        self.state = PlaybackState::Running;
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
        self.elapsed = 0.0;
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
        self.elapsed
    }

    /// Return a clone of the named script from the registry, if it is loaded.
    ///
    /// Used by [`Simulator::save_macro`] to snapshot an already-loaded script.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
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
    /// - `name` â€” `&str`.
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
    /// - `name` â€” `&str`.
    /// - `limit` â€” `usize`.
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
    /// - `name` â€” `String`. The macro identifier.
    /// - `script` â€” `Script`. The script to save.
    pub fn save_macro(&mut self, name: String, script: Script) {
        self.macros.insert(name, script);
    }

    /// Play a saved macro by loading it into the script registry and starting playback.
    ///
    /// Returns `Err` if no macro with `name` exists.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
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
    /// - `name` â€” `&str`.
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
    /// Clamped to `[0.0, âˆž)` â€” negative values are treated as `0.0` (frozen).
    ///
    /// # Parameters
    /// - `factor` â€” `f32`.
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
    /// - `enable` â€” `bool`.
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
    /// - `dt` â€” `f32`. Seconds since the previous frame.
    /// - `event_queue` â€” `&mut EventQueue`.
    pub fn update(&mut self, dt: f32, event_queue: &mut EventQueue) {
        if self.state != PlaybackState::Running {
            return;
        }

        self.elapsed += dt * self.playback_speed;

        let script_name = match &self.active_script {
            Some(name) => name.clone(),
            None => return,
        };

        let script = match self.scripts.get(&script_name) {
            Some(s) => s,
            None => return,
        };

        // Dispatch all steps whose time has been reached.
        while self.next_step_idx < script.steps.len() {
            let step = &script.steps[self.next_step_idx];
            if step.time > self.elapsed {
                break;
            }
            Self::dispatch_step(step, event_queue);
            self.next_step_idx += 1;
        }

        // Check if all steps have been dispatched.
        if self.next_step_idx >= script.steps.len() {
            self.state = PlaybackState::Complete;
        }
    }

    /// Translate a [`Step`] into a synthetic [`Event`] and push it into the queue.
    ///
    /// Each `Action` variant maps to a specific event name and argument list:
    /// - `KeyPress` â†’ `"keypressed"` with `(key, scancode, is_repeat)`
    /// - `KeyRelease` â†’ `"keyreleased"` with `(key, scancode)`
    /// - `MouseMove` â†’ `"mousemoved"` with `(x, y, dx, dy)`
    /// - `MousePress` â†’ `"mousepressed"` with `(x, y, button, false, clicks)`
    /// - `MouseRelease` â†’ `"mousereleased"` with `(x, y, button)`
    /// - `MouseWheel` â†’ `"wheelmoved"` with `(dx, dy)`
    /// - `TextInput` â†’ `"textinput"` with `(text)`
    /// - `Wait` â†’ no event pushed (pure delay)
    fn dispatch_step(step: &Step, event_queue: &mut EventQueue) {
        match step.action {
            Action::KeyPress => {
                let key = step.key.as_deref().unwrap_or("unknown");
                let scancode = step.effective_scancode().unwrap_or(key);
                event_queue.push(Event {
                    name: "keypressed".to_string(),
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
                event_queue.push(Event {
                    name: "keyreleased".to_string(),
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
                event_queue.push(Event {
                    name: "mousemoved".to_string(),
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
                event_queue.push(Event {
                    name: "mousepressed".to_string(),
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
                event_queue.push(Event {
                    name: "mousereleased".to_string(),
                    args: vec![EventArg::Num(x), EventArg::Num(y), EventArg::Num(button)],
                });
            }
            Action::MouseWheel => {
                let x = step.x.unwrap_or(0.0);
                let y = step.y.unwrap_or(0.0);
                event_queue.push(Event {
                    name: "wheelmoved".to_string(),
                    args: vec![EventArg::Num(x), EventArg::Num(y)],
                });
            }
            Action::TextInput => {
                let text = step.text.as_deref().unwrap_or("");
                event_queue.push(Event {
                    name: "textinput".to_string(),
                    args: vec![EventArg::Str(text.to_string())],
                });
            }
            Action::Wait => {
                // No-op â€” just a timed delay.
            }
        }
    }
}

impl Default for Simulator {
    fn default() -> Self {
        Self::new()
    }
}

// Tests migrated to tests/rust/unit/automation_tests.rs
