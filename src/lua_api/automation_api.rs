//! `lurek.automation` - Automated input simulation via timed step scripts.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::automation::{Action, Script, Simulator, Step};

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.automation` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));
    // wait_state holds an optional (predicate_key, timeout, elapsed) triple
    // used by `waitUntil` to gate playback advancement.
    let wait_state: Rc<RefCell<Option<(LuaRegistryKey, f32, f32)>>> = Rc::new(RefCell::new(None));

    // -- load --
    /// Loads a named script from a Lua data table containing a steps array.
    /// @param | name | string | Script name to register.
    /// @param | data | table | Script data table containing a `steps` array.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "load",
        lua.create_function(move |_, (name, data): (String, LuaTable)| {
            let steps_table: LuaTable = data.get::<_, LuaTable>("steps").map_err(|_| {
                LuaError::external("simulator.load: data table must have a 'steps' array")
            })?;
            let steps = Step::vec_from_lua_table(&steps_table)?;
            let description: Option<String> = data
                .get::<_, Option<LuaTable>>("meta")?
                .and_then(|meta| meta.get::<_, Option<String>>("description").ok().flatten());
            let script = match description {
                Some(desc) => Script::with_description(name, desc, steps),
                None => Script::new(name, steps),
            };
            sim.borrow_mut().load(script);
            Ok(())
        })?,
    )?;

    // -- unload --
    /// Removes a loaded script by name, returning true if it existed.
    /// @param | name | string | Script name to remove.
    /// @return | boolean | True when the script existed and was removed.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "unload",
        lua.create_function(move |_, name: String| Ok(sim.borrow_mut().unload(&name)))?,
    )?;

    // -- hasScript --
    /// Returns true if a script with the given name is registered.
    /// @param | name | string | Script name to check.
    /// @return | boolean | True when the script is registered.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "hasScript",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_script(&name)))?,
    )?;

    // -- getScripts --
    /// Returns an array of all registered script names.
    /// @return | table | Array of registered script names.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getScripts",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_scripts()))?,
    )?;

    // -- start --
    /// Starts playback of the named script from the beginning.
    /// @param | name | string | Script name to play.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "start",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut().start(&name).map_err(LuaError::external)
        })?,
    )?;

    // -- stop --
    /// Stops playback and resets the simulator to idle.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "stop",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().stop();
            Ok(())
        })?,
    )?;

    // -- pause --
    /// Pauses playback at the current step position.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "pause",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().pause();
            Ok(())
        })?,
    )?;

    // -- resume --
    /// Resumes playback from a paused position.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "resume",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().resume();
            Ok(())
        })?,
    )?;

    // -- update --
    /// Advances the playback clock by `dt` seconds.
    /// @param | dt | number | Seconds to advance while dispatching due steps.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    let s = state.clone();
    let ws = wait_state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f32| {
            // Handle waitUntil gate - poll predicate before advancing.
            if ws.borrow().is_some() {
                let (resolved, timed_out) = {
                    let state_opt = ws.borrow();
                    if let Some((ref key, timeout, elapsed)) = *state_opt {
                        let new_elapsed = elapsed + dt;
                        let predicate: LuaFunction = lua.registry_value(key)?;
                        let done: bool = predicate.call(())?;
                        (done, new_elapsed >= timeout)
                    } else {
                        (false, false)
                    }
                };
                if resolved || timed_out {
                    *ws.borrow_mut() = None;
                } else {
                    if let Some(ref mut triple) = ws.borrow_mut().as_mut() {
                        triple.2 += dt;
                    }
                    return Ok(());
                }
            }
            sim.borrow_mut().update(dt, &mut s.borrow_mut().event_queue);
            Ok(())
        })?,
    )?;

    // -- isRunning --
    /// Returns true if the simulator is actively playing a script.
    /// @return | boolean | True when a script is currently playing.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_running()))?,
    )?;

    // -- isPaused --
    /// Returns true if playback is currently paused.
    /// @return | boolean | True when playback is paused.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isPaused",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_paused()))?,
    )?;

    // -- isComplete --
    /// Returns true if all steps in the active script have been dispatched.
    /// @return | boolean | True when the active script has finished.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isComplete",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_complete()))?,
    )?;

    // -- isFailed --
    /// Returns true if playback stopped because an assertion failed.
    /// @return | boolean | True when simulator state is failed.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isFailed",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_failed()))?,
    )?;

    // -- getLastError --
    /// Returns the last simulator failure string, or nil if none.
    /// @return | string? | Last assertion or visual assertion error.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getLastError",
        lua.create_function(move |_, ()| Ok(sim.borrow().last_error().map(|s| s.to_string())))?,
    )?;

    // -- setCondition --
    /// Sets a named boolean condition used by `when` and `assert` expressions.
    /// @param | name | string | Condition name.
    /// @param | value | boolean | Condition value.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setCondition",
        lua.create_function(move |_, (name, value): (String, bool)| {
            sim.borrow_mut().set_condition(name, value);
            Ok(())
        })?,
    )?;

    // -- getCondition --
    /// Returns a condition value by name, or nil when unset.
    /// @param | name | string | Condition name.
    /// @return | boolean? | Condition value.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getCondition",
        lua.create_function(move |_, name: String| Ok(sim.borrow().get_condition(&name)))?,
    )?;

    // -- getCurrentStep --
    /// Returns the index of the next step to be dispatched.
    /// @return | integer | Zero-based step index.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getCurrentStep",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_step()))?,
    )?;

    // -- getStepCount --
    /// Returns the total number of steps in the active script.
    /// @return | integer | Total number of steps.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getStepCount",
        lua.create_function(move |_, ()| Ok(sim.borrow().step_count()))?,
    )?;

    // -- getCurrentScript --
    /// Returns the name of the active script.
    /// @return | string | Active script name.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getCurrentScript",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_script().map(|s| s.to_string())))?,
    )?;

    // -- getElapsedTime --
    /// Returns seconds elapsed since playback started.
    /// @return | number | Elapsed playback time in seconds.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getElapsedTime",
        lua.create_function(move |_, ()| Ok(sim.borrow().elapsed_time()))?,
    )?;

    // -- loadFromToml --
    /// Parses a TOML string and registers it as a named script.
    /// @param | name | string | Script name to register.
    /// @param | toml_str | string | TOML string to parse into a script.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "loadFromToml",
        lua.create_function(move |_, (name, toml_str): (String, String)| {
            let script = Script::from_toml(&name, &toml_str)
                .map_err(|e| LuaError::external(format!("loadFromToml: {e}")))?;
            sim.borrow_mut().load(script);
            Ok(())
        })?,
    )?;

    // -- getStepLimit --
    /// Returns the step limit for the named script.
    /// @param | name | string | Script name to inspect.
    /// @return | integer | Step limit value.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getStepLimit",
        lua.create_function(move |_, name: String| {
            Ok(sim.borrow().get_script_step_limit(&name).map(|v| v as u64))
        })?,
    )?;

    // -- setStepLimit --
    /// Sets the step limit for the named script.
    /// @param | name | string | Script name to update.
    /// @param | n | integer | New step limit value.
    /// @return | boolean | True when the script was found and updated.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setStepLimit",
        lua.create_function(move |_, (name, n): (String, u64)| {
            Ok(sim.borrow_mut().set_script_step_limit(&name, n as usize))
        })?,
    )?;

    // -- saveMacro --
    /// Saves a loaded script under a macro name for fast replay.
    /// @param | macro_name | string | Macro name to save.
    /// @param | script_name | string | Existing script name to copy.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "saveMacro",
        lua.create_function(move |_, (macro_name, script_name): (String, String)| {
            let script = sim.borrow().get_script(&script_name).ok_or_else(|| {
                LuaError::external(format!("saveMacro: script '{}' not found", script_name))
            })?;
            sim.borrow_mut().save_macro(macro_name, script);
            Ok(())
        })?,
    )?;

    // -- playMacro --
    /// Loads and starts playback of a previously saved macro.
    /// @param | name | string | Macro name to play.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "playMacro",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut()
                .play_macro(&name)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- hasMacro --
    /// Returns true if a macro with the given name has been saved.
    /// @param | name | string | Macro name to check.
    /// @return | boolean | True when the macro exists.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "hasMacro",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_macro(&name)))?,
    )?;

    // -- listMacros --
    /// Returns an array of all saved macro names.
    /// @return | table | Array of saved macro names.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "listMacros",
        lua.create_function(move |_, ()| Ok(sim.borrow().list_macros()))?,
    )?;

    // -- setPlaybackSpeed --
    /// Sets the playback speed multiplier.
    /// @param | factor | number | Multiplier applied to playback time.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setPlaybackSpeed",
        lua.create_function(move |_, factor: f32| {
            sim.borrow_mut().set_playback_speed(factor);
            Ok(())
        })?,
    )?;

    // -- getPlaybackSpeed --
    /// Returns the current playback speed multiplier (default 1.0).
    /// @return | number | Current playback speed multiplier.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getPlaybackSpeed",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_playback_speed()))?,
    )?;

    // -- setHighlightMode --
    /// Enables or disables the highlight overlay hint.
    /// @param | enable | boolean | True to enable the hint overlay.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setHighlightMode",
        lua.create_function(move |_, enable: bool| {
            sim.borrow_mut().set_highlight_mode(enable);
            Ok(())
        })?,
    )?;

    // -- isHighlightMode --
    /// Returns whether the highlight overlay hint is active.
    /// @return | boolean | True when highlight mode is enabled.
    let sim = simulator.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isHighlightMode",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_highlight_mode()))?,
    )?;

    // -- waitUntil --
    /// Pauses playback advancement until a predicate returns true or a timeout expires.
    /// @param | predicate | function | Callback that must return a boolean.
    /// @param | timeout | number | Maximum seconds to wait before resuming.
    /// @return | nil | No value is returned.
    let ws = wait_state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "waitUntil",
        lua.create_function(move |lua, (predicate, timeout): (LuaFunction, f32)| {
            let key = lua.create_registry_value(predicate)?;
            *ws.borrow_mut() = Some((key, timeout.max(0.0), 0.0));
            Ok(())
        })?,
    )?;

    lurek.set("automation", tbl)?;
    Ok(())
}

impl Step {
    /// Parses a Lua array of step tables into a `Vec<Step>`.
    ///
    /// Each element must have an `"action"` field and optional timing/target fields.
    pub fn vec_from_lua_table(t: &LuaTable) -> LuaResult<Vec<Self>> {
        let len = t.len()? as usize;
        let mut steps = Vec::with_capacity(len);
        for i in 1..=len {
            let entry: LuaTable = t.get(i)?;
            let action_str: String = entry.get::<_, String>("action").map_err(|_| {
                LuaError::external("simulator.load: each step must have an 'action' field")
            })?;
            let action = Action::parse_action(&action_str).ok_or_else(|| {
                LuaError::external(format!(
                    "simulator.load: unknown action '{}' \u{2014} expected one of: keypress, keyrelease, mousemove, mousepress, mouserelease, mousewheel, textinput, wait, repeat, callmacro, assert, visualassert",
                    action_str
                ))
            })?;
            let time: f32 = entry.get::<_, Option<f32>>("time")?.unwrap_or(0.0);
            let mut step = Self::new(time, action);
            step.key = entry.get::<_, Option<String>>("key")?;
            step.scancode = entry.get::<_, Option<String>>("scancode")?;
            step.x = entry.get::<_, Option<f64>>("x")?;
            step.y = entry.get::<_, Option<f64>>("y")?;
            step.dx = entry.get::<_, Option<f64>>("dx")?;
            step.dy = entry.get::<_, Option<f64>>("dy")?;
            step.button = entry.get::<_, Option<u32>>("button")?;
            step.text = entry.get::<_, Option<String>>("text")?;
            step.is_repeat = entry.get::<_, Option<bool>>("isRepeat")?.unwrap_or(false);
            step.clicks = entry.get::<_, Option<u32>>("clicks")?;
            step.repeat = entry.get::<_, Option<u32>>("repeat")?;
            step.repeat_interval = entry.get::<_, Option<f32>>("repeatInterval")?;
            step.macro_name = entry.get::<_, Option<String>>("macro")?;
            step.when = entry.get::<_, Option<String>>("when")?;
            step.assert = entry.get::<_, Option<String>>("assert")?;
            step.baseline = entry.get::<_, Option<String>>("baseline")?;
            step.actual = entry.get::<_, Option<String>>("actual")?;
            step.max_diff = entry.get::<_, Option<u32>>("maxDiff")?;
            steps.push(step);
        }
        Ok(steps)
    }
}
