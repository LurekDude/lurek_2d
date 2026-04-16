//! `lurek.simulator` — Automated input simulation via timed step scripts.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::automation::{Action, Script, Simulator, Step};


// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.simulator` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));
    // wait_state holds an optional (predicate_key, timeout, elapsed) triple
    // used by `waitUntil` to gate playback advancement.
    let wait_state: Rc<RefCell<Option<(LuaRegistryKey, f32, f32)>>> =
        Rc::new(RefCell::new(None));

    // ── load ─────────────────────────────────────────────────────────────────
    /// Loads a named script from a Lua data table containing a steps array.
    /// @param name : string
    /// @param data : table
    /// @return nil
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

    // ── unload ───────────────────────────────────────────────────────────────
    /// Removes a loaded script by name, returning true if it existed.
    /// @param name : string
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "unload",
        lua.create_function(move |_, name: String| Ok(sim.borrow_mut().unload(&name)))?,
    )?;

    // ── hasScript ────────────────────────────────────────────────────────────
    /// Returns true if a script with the given name is registered.
    /// @param name : string
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "hasScript",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_script(&name)))?,
    )?;

    // ── getScripts ───────────────────────────────────────────────────────────
    /// Returns an array of all registered script names.
    /// @return table
    let sim = simulator.clone();
    tbl.set(
        "getScripts",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_scripts()))?,
    )?;

    // ── start ────────────────────────────────────────────────────────────────
    /// Starts playback of the named script from the beginning.
    /// @param name : string
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "start",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut().start(&name).map_err(LuaError::external)
        })?,
    )?;

    // ── stop ─────────────────────────────────────────────────────────────────
    /// Stops playback and resets the simulator to idle.
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "stop",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().stop();
            Ok(())
        })?,
    )?;

    // ── pause ────────────────────────────────────────────────────────────────
    /// Pauses playback at the current step position.
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "pause",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().pause();
            Ok(())
        })?,
    )?;

    // ── resume ───────────────────────────────────────────────────────────────
    /// Resumes playback from a paused position.
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "resume",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().resume();
            Ok(())
        })?,
    )?;

    // ── update ───────────────────────────────────────────────────────────────
    /// Advances the playback clock by `dt` seconds, dispatching due steps.
    /// If `waitUntil` is active the predicate is polled before forwarding `dt`;
    /// until the predicate returns `true` or the timeout expires the simulator
    /// clock is frozen.
    /// @param dt : number
    /// @return nil
    let sim = simulator.clone();
    let s = state.clone();
    let ws = wait_state.clone();
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f32| {
            // Handle waitUntil gate — poll predicate before advancing.
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
            sim.borrow_mut()
                .update(dt, &mut s.borrow_mut().event_queue);
            Ok(())
        })?,
    )?;

    // ── isRunning ────────────────────────────────────────────────────────────
    /// Returns true if the simulator is actively playing a script.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_running()))?,
    )?;

    // ── isPaused ─────────────────────────────────────────────────────────────
    /// Returns true if playback is currently paused.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_paused()))?,
    )?;

    // ── isComplete ───────────────────────────────────────────────────────────
    /// Returns true if all steps in the active script have been dispatched.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isComplete",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_complete()))?,
    )?;

    // ── getCurrentStep ───────────────────────────────────────────────────────
    /// Returns the index of the next step to be dispatched.
    /// @return integer
    let sim = simulator.clone();
    tbl.set(
        "getCurrentStep",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_step()))?,
    )?;

    // ── getStepCount ─────────────────────────────────────────────────────────
    /// Returns the total number of steps in the active script.
    /// @return integer
    let sim = simulator.clone();
    tbl.set(
        "getStepCount",
        lua.create_function(move |_, ()| Ok(sim.borrow().step_count()))?,
    )?;

    // ── getCurrentScript ─────────────────────────────────────────────────────
    /// Returns the name of the active script, or nil if idle.
    /// @return string?
    let sim = simulator.clone();
    tbl.set(
        "getCurrentScript",
        lua.create_function(move |_, ()| {
            Ok(sim.borrow().current_script().map(|s| s.to_string()))
        })?,
    )?;

    // ── getElapsedTime ───────────────────────────────────────────────────────
    /// Returns seconds elapsed since playback started.
    /// @return number
    let sim = simulator.clone();
    tbl.set(
        "getElapsedTime",
        lua.create_function(move |_, ()| Ok(sim.borrow().elapsed_time()))?,
    )?;

    // ── loadFromToml ─────────────────────────────────────────────────────────
    /// Parses a TOML string and registers it as a named script.
    /// @param name : string
    /// @param toml_str : string
    /// @return nil
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

    // ── getStepLimit ─────────────────────────────────────────────────────────
    /// Returns the step limit for the named script, or nil if not found.
    /// @param name : string
    /// @return integer?
    let sim = simulator.clone();
    tbl.set(
        "getStepLimit",
        lua.create_function(move |_, name: String| {
            Ok(sim.borrow().get_script_step_limit(&name).map(|v| v as u64))
        })?,
    )?;

    // ── setStepLimit ─────────────────────────────────────────────────────────
    /// Sets the step limit for the named script (clamped to 1..MAX_STEPS).
    /// Returns true if the script was found, false otherwise.
    /// @param name : string
    /// @param n : integer
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "setStepLimit",
        lua.create_function(move |_, (name, n): (String, u64)| {
            Ok(sim.borrow_mut().set_script_step_limit(&name, n as usize))
        })?,
    )?;

    // ── saveMacro ─────────────────────────────────────────────────────────────────────────
    /// Saves a currently-loaded script under a macro name for fast replay.
    /// The script must already be loaded via `load` or `loadFromToml`.
    /// @param macro_name : string
    /// @param script_name : string
    /// @return nil
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

    // ── playMacro ─────────────────────────────────────────────────────────────────────────
    /// Loads and starts playback of a previously saved macro.
    /// Errors if the macro name has not been saved.
    /// @param name : string
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "playMacro",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut().play_macro(&name).map_err(LuaError::external)
        })?,
    )?;

    // ── hasMacro ──────────────────────────────────────────────────────────────────────────
    /// Returns true if a macro with the given name has been saved.
    /// @param name : string
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "hasMacro",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_macro(&name)))?,
    )?;

    // ── listMacros ───────────────────────────────────────────────────────────────────────
    /// Returns an array of all saved macro names.
    /// @return table
    let sim = simulator.clone();
    tbl.set(
        "listMacros",
        lua.create_function(move |_, ()| Ok(sim.borrow().list_macros()))?,
    )?;

    // ── setPlaybackSpeed ───────────────────────────────────────────────────────────────
    /// Sets the dt multiplier for script playback (0.5 = half speed, 2.0 = double).
    /// Negative values are clamped to 0 (frozen clock).
    /// @param factor : number
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "setPlaybackSpeed",
        lua.create_function(move |_, factor: f32| {
            sim.borrow_mut().set_playback_speed(factor);
            Ok(())
        })?,
    )?;

    // ── getPlaybackSpeed ───────────────────────────────────────────────────────────────
    /// Returns the current playback speed multiplier (default 1.0).
    /// @return number
    let sim = simulator.clone();
    tbl.set(
        "getPlaybackSpeed",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_playback_speed()))?,
    )?;

    // ── setHighlightMode ──────────────────────────────────────────────────────────────
    /// Enables or disables the highlight overlay hint.
    /// When true, a game render pass can visualise the current simulated cursor/key
    /// position by calling `lurek.simulator:isHighlightMode()`.
    /// @param enable : boolean
    /// @return nil
    let sim = simulator.clone();
    tbl.set(
        "setHighlightMode",
        lua.create_function(move |_, enable: bool| {
            sim.borrow_mut().set_highlight_mode(enable);
            Ok(())
        })?,
    )?;

    // ── isHighlightMode ───────────────────────────────────────────────────────────────
    /// Returns whether the highlight overlay hint is active.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isHighlightMode",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_highlight_mode()))?,
    )?;

    // ── waitUntil ───────────────────────────────────────────────────────────────────────
    /// Pauses playback advancement until predicate() returns true or timeout seconds elapse.
    /// While waiting, `update` does not forward elapsed time to the simulator.
    /// @param predicate : function -- must return boolean
    /// @param timeout : number -- maximum seconds to wait before auto-resuming
    /// @return nil
    let ws = wait_state.clone();
    tbl.set(
        "waitUntil",
        lua.create_function(move |lua, (predicate, timeout): (LuaFunction, f32)| {
            let key = lua.create_registry_value(predicate)?;
            *ws.borrow_mut() = Some((key, timeout.max(0.0), 0.0));
            Ok(())
        })?,
    )?;

    luna.set("simulator", tbl)?;
    Ok(())
}

impl Step {
/// vec_from_lua_table.
///
/// @param t : &LuaTable
///
/// LuaResult<Vec<Self>>
///
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
                    "simulator.load: unknown action '{}' \u{2014} expected one of: keypress, keyrelease, mousemove, mousepress, mouserelease, mousewheel, textinput, wait",
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
            steps.push(step);
        }
        Ok(steps)
    }
}
