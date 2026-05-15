//! `lurek.automation` -- Automation bindings for loading simulator scripts, controlling playback, inspecting state, saving macros, and waiting on Lua predicates.

use super::SharedState;
use crate::automation::{Action, Script, Simulator, Step};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Registers the `lurek.automation` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));
    let wait_state: Rc<RefCell<Option<(LuaRegistryKey, f32, f32)>>> = Rc::new(RefCell::new(None));
    // -- load --
    /// Loads an automation script from a Lua table of steps and optional metadata.
    /// @param | name | string | Script name used by `start`, macros, and lookup calls.
    /// @param | data | table | Script data table with a `steps` array and optional `meta.description` string.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
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
    /// Unloads a named automation script.
    /// @param | name | string | Script name to remove.
    /// @return | boolean | True when the script existed and was removed.
    let sim = simulator.clone();
    tbl.set(
        "unload",
        lua.create_function(move |_, name: String| Ok(sim.borrow_mut().unload(&name)))?,
    )?;
    // -- hasScript --
    /// Returns whether a script is loaded.
    /// @param | name | string | Script name to check.
    /// @return | boolean | True when the script is loaded.
    let sim = simulator.clone();
    tbl.set(
        "hasScript",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_script(&name)))?,
    )?;
    // -- getScripts --
    /// Returns the names of loaded automation scripts.
    /// @return | table | Array table of script names.
    let sim = simulator.clone();
    tbl.set(
        "getScripts",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_scripts()))?,
    )?;
    // -- start --
    /// Starts playback of a loaded automation script.
    /// @param | name | string | Loaded script name to start.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "start",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut().start(&name).map_err(LuaError::external)
        })?,
    )?;
    // -- stop --
    /// Stops the current automation script.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "stop",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().stop();
            Ok(())
        })?,
    )?;
    // -- pause --
    /// Pauses automation playback. This function is exposed to Lua scripts.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "pause",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().pause();
            Ok(())
        })?,
    )?;
    // -- resume --
    /// Resumes automation playback. This function is exposed to Lua scripts.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "resume",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().resume();
            Ok(())
        })?,
    )?;
    // -- update --
    /// Advances automation playback and dispatches generated input events.
    /// @param | dt | number | Elapsed time in seconds.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    let s = state.clone();
    let ws = wait_state.clone();
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f32| {
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
    /// Returns whether automation playback is running.
    /// @return | boolean | True when a script is running.
    let sim = simulator.clone();
    tbl.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_running()))?,
    )?;
    // -- isPaused --
    /// Returns whether automation playback is paused.
    /// @return | boolean | True when playback is paused.
    let sim = simulator.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_paused()))?,
    )?;
    // -- isComplete --
    /// Returns whether the current automation script completed.
    /// @return | boolean | True when the current script has completed.
    let sim = simulator.clone();
    tbl.set(
        "isComplete",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_complete()))?,
    )?;
    // -- isFailed --
    /// Returns whether the current automation script failed.
    /// @return | boolean | True when the current script has failed.
    let sim = simulator.clone();
    tbl.set(
        "isFailed",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_failed()))?,
    )?;
    // -- getLastError --
    /// Returns the last automation error message when one exists.
    /// @return | LuaValue | Last error string, or nil when no error is stored.
    let sim = simulator.clone();
    tbl.set(
        "getLastError",
        lua.create_function(move |_, ()| Ok(sim.borrow().last_error().map(|s| s.to_string())))?,
    )?;
    // -- setCondition --
    /// Sets a named boolean condition used by automation steps.
    /// @param | name | string | Condition name.
    /// @param | value | boolean | Condition value.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "setCondition",
        lua.create_function(move |_, (name, value): (String, bool)| {
            sim.borrow_mut().set_condition(name, value);
            Ok(())
        })?,
    )?;
    // -- getCondition --
    /// Returns a named automation condition value.
    /// @param | name | string | Condition name.
    /// @return | boolean | Current condition value.
    let sim = simulator.clone();
    tbl.set(
        "getCondition",
        lua.create_function(move |_, name: String| Ok(sim.borrow().get_condition(&name)))?,
    )?;
    // -- getCurrentStep --
    /// Returns the current step index of the active script.
    /// @return | integer | Current step index.
    let sim = simulator.clone();
    tbl.set(
        "getCurrentStep",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_step()))?,
    )?;
    // -- getStepCount --
    /// Returns the number of steps in the active script.
    /// @return | integer | Active script step count.
    let sim = simulator.clone();
    tbl.set(
        "getStepCount",
        lua.create_function(move |_, ()| Ok(sim.borrow().step_count()))?,
    )?;
    // -- getCurrentScript --
    /// Returns the current script name when a script is active.
    /// @return | LuaValue | Current script name, or nil when no script is active.
    let sim = simulator.clone();
    tbl.set(
        "getCurrentScript",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_script().map(|s| s.to_string())))?,
    )?;
    // -- getElapsedTime --
    /// Returns elapsed playback time for the current script.
    /// @return | number | Elapsed time in seconds.
    let sim = simulator.clone();
    tbl.set(
        "getElapsedTime",
        lua.create_function(move |_, ()| Ok(sim.borrow().elapsed_time()))?,
    )?;
    // -- loadFromToml --
    /// Loads an automation script from TOML text.
    /// @param | name | string | Script name used by `start`, macros, and lookup calls.
    /// @param | toml_str | string | TOML automation script contents.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
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
    /// Returns the configured step limit for a loaded script.
    /// @param | name | string | Script name to query.
    /// @return | LuaValue | Step limit as an integer, or nil when no limit is set.
    let sim = simulator.clone();
    tbl.set(
        "getStepLimit",
        lua.create_function(move |_, name: String| {
            Ok(sim.borrow().get_script_step_limit(&name).map(|v| v as u64))
        })?,
    )?;
    // -- setStepLimit --
    /// Sets the maximum step count for a loaded script.
    /// @param | name | string | Script name to update.
    /// @param | n | integer | Maximum step count.
    /// @return | boolean | True when the script exists and the limit was set.
    let sim = simulator.clone();
    tbl.set(
        "setStepLimit",
        lua.create_function(move |_, (name, n): (String, u64)| {
            Ok(sim.borrow_mut().set_script_step_limit(&name, n as usize))
        })?,
    )?;
    // -- saveMacro --
    /// Saves a loaded script as a named macro.
    /// @param | macro_name | string | Macro name to save.
    /// @param | script_name | string | Loaded script name to copy into the macro store.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
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
    /// Starts playback of a saved macro. This function is exposed to Lua scripts.
    /// @param | name | string | Macro name to play.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "playMacro",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut()
                .play_macro(&name)
                .map_err(LuaError::external)
        })?,
    )?;
    // -- hasMacro --
    /// Returns whether a macro is saved. This function is exposed to Lua scripts.
    /// @param | name | string | Macro name to check.
    /// @return | boolean | True when the macro exists.
    let sim = simulator.clone();
    tbl.set(
        "hasMacro",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_macro(&name)))?,
    )?;
    // -- listMacros --
    /// Returns the names of saved macros. This function is exposed to Lua scripts.
    /// @return | table | Array table of macro names.
    let sim = simulator.clone();
    tbl.set(
        "listMacros",
        lua.create_function(move |_, ()| Ok(sim.borrow().list_macros()))?,
    )?;
    // -- setPlaybackSpeed --
    /// Sets automation playback speed multiplier.
    /// @param | factor | number | Playback speed multiplier.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "setPlaybackSpeed",
        lua.create_function(move |_, factor: f32| {
            sim.borrow_mut().set_playback_speed(factor);
            Ok(())
        })?,
    )?;
    // -- getPlaybackSpeed --
    /// Returns automation playback speed multiplier.
    /// @return | number | Current playback speed multiplier.
    let sim = simulator.clone();
    tbl.set(
        "getPlaybackSpeed",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_playback_speed()))?,
    )?;
    // -- setHighlightMode --
    /// Enables or disables automation highlight mode.
    /// @param | enable | boolean | True to enable highlight mode.
    /// @return | nil | No value is returned.
    let sim = simulator.clone();
    tbl.set(
        "setHighlightMode",
        lua.create_function(move |_, enable: bool| {
            sim.borrow_mut().set_highlight_mode(enable);
            Ok(())
        })?,
    )?;
    // -- isHighlightMode --
    /// Returns whether automation highlight mode is enabled.
    /// @return | boolean | True when highlight mode is enabled.
    let sim = simulator.clone();
    tbl.set(
        "isHighlightMode",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_highlight_mode()))?,
    )?;
    // -- waitUntil --
    /// Suspends automation updates until a predicate returns true or a timeout elapses.
    /// @param | predicate | function | Function called each update; true resolves the wait.
    /// @param | timeout | number | Maximum wait duration in seconds.
    /// @return | nil | No value is returned.
    let ws = wait_state.clone();
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
    /// Converts a Lua array of step tables into automation steps.
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
