//! `lurek.simulator` — Automated input simulation via timed step scripts.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::automation::{Script, Simulator, Step};


// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.simulator` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`. The Lua VM.
/// - `luna` — `&LuaTable`. The top-level `luna` table to register into.
/// - `state` — `Rc<RefCell<SharedState>>`. Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));

    // -- load --
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

    // -- unload --
    /// Removes a loaded script by name, returning true if it existed.
    /// @param name : string
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "unload",
        lua.create_function(move |_, name: String| Ok(sim.borrow_mut().unload(&name)))?,
    )?;

    // -- hasScript --
    /// Returns true if a script with the given name is registered.
    /// @param name : string
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "hasScript",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_script(&name)))?,
    )?;

    // -- getScripts --
    /// Returns an array of all registered script names.
    /// @return table
    let sim = simulator.clone();
    tbl.set(
        "getScripts",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_scripts()))?,
    )?;

    // -- start --
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

    // -- stop --
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

    // -- pause --
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

    // -- resume --
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

    // -- update --
    /// Advances the playback clock by dt seconds, dispatching due steps.
    /// @param dt : number
    /// @return nil
    let sim = simulator.clone();
    let s = state.clone();
    tbl.set(
        "update",
        lua.create_function(move |_, dt: f32| {
            sim.borrow_mut()
                .update(dt, &mut s.borrow_mut().event_queue);
            Ok(())
        })?,
    )?;

    // -- isRunning --
    /// Returns true if the simulator is actively playing a script.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_running()))?,
    )?;

    // -- isPaused --
    /// Returns true if playback is currently paused.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_paused()))?,
    )?;

    // -- isComplete --
    /// Returns true if all steps in the active script have been dispatched.
    /// @return boolean
    let sim = simulator.clone();
    tbl.set(
        "isComplete",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_complete()))?,
    )?;

    // -- getCurrentStep --
    /// Returns the index of the next step to be dispatched.
    /// @return integer
    let sim = simulator.clone();
    tbl.set(
        "getCurrentStep",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_step()))?,
    )?;

    // -- getStepCount --
    /// Returns the total number of steps in the active script.
    /// @return integer
    let sim = simulator.clone();
    tbl.set(
        "getStepCount",
        lua.create_function(move |_, ()| Ok(sim.borrow().step_count()))?,
    )?;

    // -- getCurrentScript --
    /// Returns the name of the active script, or nil if idle.
    /// @return string?
    let sim = simulator.clone();
    tbl.set(
        "getCurrentScript",
        lua.create_function(move |_, ()| {
            Ok(sim.borrow().current_script().map(|s| s.to_string()))
        })?,
    )?;

    // -- getElapsedTime --
    /// Returns seconds elapsed since playback started.
    /// @return number
    let sim = simulator.clone();
    tbl.set(
        "getElapsedTime",
        lua.create_function(move |_, ()| Ok(sim.borrow().elapsed_time()))?,
    )?;

    // -- loadFromToml --
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

    luna.set("simulator", tbl)?;
    Ok(())
}
