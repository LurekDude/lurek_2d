//! - Automation simulator: drives script playback by advancing time and dispatching events.
//! - Manages a registry of named scripts and macros with load/unload lifecycle.
//! - Evaluates condition expressions (&&, ||, !, parentheses) against named boolean flags.
//! - Supports pause, resume, speed control, and visual highlight mode for debug tools.
//! - CallMacro steps inline macro scripts at the current playback position.
//! - VisualAssert steps compare baseline and actual images with pixel-diff tolerance.
//! - Assert steps halt playback when condition expressions evaluate to false.
//! - StepEventSink trait decouples event dispatch from EventQueue for testing.

use super::script::MAX_STEPS;
use super::{Action, Script, Step};
use crate::event::{Event, EventArg, EventQueue};
use crate::input::{
    EVENT_KEY_PRESSED, EVENT_KEY_RELEASED, EVENT_MOUSE_MOVED, EVENT_MOUSE_PRESSED,
    EVENT_MOUSE_RELEASED, EVENT_TEXT_INPUT, EVENT_WHEEL_MOVED,
};
use crate::log_msg;
use crate::runtime::log_messages::{AT01_SIM_INIT, AT02_SCRIPT_LOAD};
use crate::timer::accumulate_scaled_micros;
use std::collections::HashMap;
use std::path::Path;
/// Sink for events produced by the simulator during step dispatch.
pub trait StepEventSink {
    /// Push one `Event` into the sink for later processing by the engine event loop.
    fn push_event(&mut self, event: Event);
}
/// `StepEventSink` implementation that routes simulator events into the engine `EventQueue`.
impl StepEventSink for EventQueue {
    /// Forward the event into the underlying `EventQueue`.
    fn push_event(&mut self, event: Event) {
        self.push(event);
    }
}
#[derive(Debug, Clone, PartialEq)]
/// Internal playback lifecycle state for the active script.
enum PlaybackState {
    /// No script is active; simulator is waiting for `start()`.
    Idle,
    /// Script is active and advancing time each `update()` call.
    Running,
    /// Script is suspended; time does not advance until `resume()` is called.
    Paused,
    /// All steps have been dispatched successfully.
    Complete,
    /// A step assertion or macro error halted the script; `last_error` holds the reason.
    Failed,
}
#[derive(Debug)]
/// Drives automation script playback by advancing time and dispatching `Step` events.
pub struct Simulator {
    /// Registry of loaded scripts keyed by their `Script::name`.
    scripts: HashMap<String, Script>,
    /// Name of the currently playing script, or `None` when idle.
    active_script: Option<String>,
    /// Total elapsed playback time in microseconds, scaled by `playback_speed`.
    elapsed_micros: u64,
    /// Sub-microsecond carry used by `accumulate_scaled_micros` to avoid drift.
    dt_carry_micros: f64,
    /// Index of the next step to evaluate in the active script.
    next_step_idx: usize,
    /// Current playback lifecycle state.
    state: PlaybackState,
    /// Named macro library inlined by `CallMacro` steps during playback.
    macros: HashMap<String, Script>,
    /// Time-scale factor applied during `update()`; 1.0 = real-time, 0.0 = paused.
    playback_speed: f32,
    /// When true, enables visual highlighting of dispatched steps in debug tools.
    highlight_mode: bool,
    /// Named boolean flags evaluated by `when` and `assert` condition expressions.
    conditions: HashMap<String, bool>,
    /// Error message from the most recent failure, set when state transitions to `Failed`.
    last_error: Option<String>,
}
impl Simulator {
    /// Create a new idle `Simulator` with no scripts, macros, or conditions loaded.
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
    /// Register a `Script` by name; replaces any existing script with the same name.
    pub fn load(&mut self, script: Script) {
        log_msg!(debug, AT02_SCRIPT_LOAD, "{}", script.name);
        self.scripts.insert(script.name.clone(), script);
    }
    /// Remove the named script; stop playback if it is currently active. Return `true` if the script existed.
    pub fn unload(&mut self, name: &str) -> bool {
        if self.active_script.as_deref() == Some(name) {
            self.stop();
        }
        self.scripts.remove(name).is_some()
    }
    /// Return `true` if a script with `name` is registered.
    pub fn has_script(&self, name: &str) -> bool {
        self.scripts.contains_key(name)
    }
    /// Return the names of all currently loaded scripts.
    pub fn get_scripts(&self) -> Vec<String> {
        self.scripts.keys().cloned().collect()
    }
    /// Begin playback of the named script from the start; error if the script is not loaded.
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
    /// Halt playback and reset all playback state to idle.
    pub fn stop(&mut self) {
        self.active_script = None;
        self.elapsed_micros = 0;
        self.dt_carry_micros = 0.0;
        self.next_step_idx = 0;
        self.state = PlaybackState::Idle;
    }
    /// Suspend playback; time stops advancing until `resume()` is called.
    pub fn pause(&mut self) {
        if self.state == PlaybackState::Running {
            self.state = PlaybackState::Paused;
        }
    }
    /// Resume a paused script; no-op if not in `Paused` state.
    pub fn resume(&mut self) {
        if self.state == PlaybackState::Paused {
            self.state = PlaybackState::Running;
        }
    }
    /// Return `true` when the script is actively advancing time.
    pub fn is_running(&self) -> bool {
        self.state == PlaybackState::Running
    }
    /// Return `true` when the script is suspended.
    pub fn is_paused(&self) -> bool {
        self.state == PlaybackState::Paused
    }
    /// Return `true` when all steps have been dispatched without error.
    pub fn is_complete(&self) -> bool {
        self.state == PlaybackState::Complete
    }
    /// Return `true` when playback halted due to an assertion or macro error.
    pub fn is_failed(&self) -> bool {
        self.state == PlaybackState::Failed
    }
    /// Return the error message from the most recent failure, or `None` if no failure.
    pub fn last_error(&self) -> Option<&str> {
        self.last_error.as_deref()
    }
    /// Return the index of the next step that will be evaluated on the next `update()`.
    pub fn current_step(&self) -> usize {
        self.next_step_idx
    }
    /// Return the total step count of the active script, or 0 when none is active.
    pub fn step_count(&self) -> usize {
        self.active_script
            .as_ref()
            .and_then(|name| self.scripts.get(name))
            .map_or(0, |s| s.step_count())
    }
    /// Return the name of the currently active script, or `None` when idle.
    pub fn current_script(&self) -> Option<&str> {
        self.active_script.as_deref()
    }
    /// Return elapsed playback time in seconds (scaled by `playback_speed`).
    pub fn elapsed_time(&self) -> f32 {
        self.elapsed_micros as f32 / 1_000_000.0
    }
    /// Set a named boolean condition used by `when` and `assert` step expressions.
    pub fn set_condition(&mut self, name: String, value: bool) {
        self.conditions.insert(name, value);
    }
    /// Return the current value of a named condition, or `None` if not set.
    pub fn get_condition(&self, name: &str) -> Option<bool> {
        self.conditions.get(name).copied()
    }
    /// Return a clone of the registered script with `name`, or `None` if not loaded.
    pub fn get_script(&self, name: &str) -> Option<Script> {
        self.scripts.get(name).cloned()
    }
    /// Return the step limit of the named script, or `None` if the script is not loaded.
    pub fn get_script_step_limit(&self, name: &str) -> Option<usize> {
        self.scripts.get(name).map(|s| s.get_step_limit())
    }
    /// Apply a new step limit to the named script; return `true` if the script exists.
    pub fn set_script_step_limit(&mut self, name: &str, limit: usize) -> bool {
        if let Some(script) = self.scripts.get_mut(name) {
            script.set_step_limit(limit);
            true
        } else {
            false
        }
    }
    /// Register a named macro `Script` that can be inlined by `CallMacro` steps.
    pub fn save_macro(&mut self, name: String, script: Script) {
        self.macros.insert(name, script);
    }
    /// Load the named macro as a regular script and start it immediately.
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
    /// Return `true` if a macro named `name` is registered.
    pub fn has_macro(&self, name: &str) -> bool {
        self.macros.contains_key(name)
    }
    /// Return the names of all registered macros.
    pub fn list_macros(&self) -> Vec<String> {
        self.macros.keys().cloned().collect()
    }
    /// Set the playback speed multiplier; clamped to >= 0.0.
    pub fn set_playback_speed(&mut self, factor: f32) {
        self.playback_speed = factor.max(0.0);
    }
    /// Return the current playback speed multiplier.
    pub fn get_playback_speed(&self) -> f32 {
        self.playback_speed
    }
    /// Enable or disable visual step-highlight mode used by debug tooling.
    pub fn set_highlight_mode(&mut self, enable: bool) {
        self.highlight_mode = enable;
    }
    /// Return `true` when visual step-highlight mode is active.
    pub fn is_highlight_mode(&self) -> bool {
        self.highlight_mode
    }
    /// Advance the simulator by `dt` seconds and dispatch due steps into `event_queue`.
    pub fn update(&mut self, dt: f32, event_queue: &mut EventQueue) {
        self.update_with_sink(dt, event_queue);
    }
    /// Advance the simulator by `dt` seconds and dispatch due steps into the provided sink.
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
        if self.next_step_idx >= step_count {
            self.state = PlaybackState::Complete;
        }
    }
    /// Evaluate one step: check conditions, run asserts, and dispatch or inline macro.
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
    /// Inline the macro named by `step.macro_name` into the active script at the current position.
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
    /// Load and compare `step.baseline` vs `step.actual` images; error if pixel diff exceeds `step.max_diff`.
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
    /// Convert a step into engine events and push them into the provided sink.
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
            | Action::VisualAssert => {}
        }
    }
}
/// Convert step time (seconds) to microseconds for comparison with `elapsed_micros`.
fn step_time_micros(step: &Step) -> u64 {
    (step.time.max(0.0) as f64 * 1_000_000.0).round() as u64
}
/// Evaluate a boolean condition expression string (&&, ||, !, parentheses, named flags).
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
/// Recursive-descent parser for condition expressions evaluated against a named-flag table.
struct ConditionParser<'a> {
    /// Source expression string being parsed.
    src: &'a str,
    /// Current byte offset into `src`.
    idx: usize,
}
impl<'a> ConditionParser<'a> {
    /// Create a parser positioned at the start of `src`.
    fn new(src: &'a str) -> Self {
        Self { src, idx: 0 }
    }
    /// Return `true` when the parser has consumed the entire source string.
    fn is_eof(&self) -> bool {
        self.idx >= self.src.len()
    }
    /// Advance `idx` past any leading whitespace characters.
    fn skip_ws(&mut self) {
        while let Some(ch) = self.peek_char() {
            if ch.is_whitespace() {
                self.idx += ch.len_utf8();
            } else {
                break;
            }
        }
    }
    /// Return the next character without advancing, or `None` at end of input.
    fn peek_char(&self) -> Option<char> {
        self.src[self.idx..].chars().next()
    }
    /// Try to consume the exact `token` string; return `true` if it matched and was consumed.
    fn eat(&mut self, token: &str) -> bool {
        self.skip_ws();
        if self.src[self.idx..].starts_with(token) {
            self.idx += token.len();
            true
        } else {
            false
        }
    }
    /// Parse a full boolean expression (entry point delegates to `parse_or`).
    fn parse_expr(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        self.parse_or(conditions)
    }
    /// Parse one or more `||`-separated operands and return their OR.
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
    /// Parse one or more `&&`-separated operands and return their AND.
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
    /// Parse a `!`-negated sub-expression, or delegate to `parse_primary`.
    fn parse_not(&mut self, conditions: &HashMap<String, bool>) -> Result<bool, String> {
        if self.eat("!") {
            Ok(!self.parse_not(conditions)?)
        } else {
            self.parse_primary(conditions)
        }
    }
    /// Parse a parenthesised sub-expression, `true`/`false` literal, or named condition lookup.
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
    /// Consume an identifier token (alphanumeric, `_`, `.`, `-`) and return it, or `None`.
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
/// Load and compare two RGBA images and return total per-channel absolute pixel diff.
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
/// Provides the Default behavior contract for Simulator.
impl Default for Simulator {
    /// Create default simulator state.
    fn default() -> Self {
        Self::new()
    }
}
