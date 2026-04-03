//! Automation Api implementation for the `lua_api` subsystem.
//!
//! Registers the `luna.simulator.*` namespace for automated input simulation
//! via timed step scripts. Scripts inject synthetic input events into the
//! engine's event queue during playback.
//!
//! ## Exposed Lua API
//!
//! | Function | Purpose |
//! |---|---|
//! | `luna.simulator.load(name, data)` | Load a script from a Lua step table |
//! | `luna.simulator.loadFromToml(name, toml_str)` | Load a script from a TOML string |
//! | `luna.simulator.loadFile(name, path)` | Load a script from a TOML file on disk |
//! | `luna.simulator.unload(name)` | Remove a loaded script by name |
//! | `luna.simulator.hasScript(name)` | Return `true` if a script is registered |
//! | `luna.simulator.getScripts()` | Return an array of all registered script names |
//! | `luna.simulator.start(name)` | Start playback from step zero |
//! | `luna.simulator.stop()` | Stop playback and reset to `Idle` |
//! | `luna.simulator.pause()` | Pause playback at the current position |
//! | `luna.simulator.resume()` | Resume from a paused position |
//! | `luna.simulator.update(dt)` | Advance the clock and dispatch due steps |
//! | `luna.simulator.isRunning()` | Return `true` if actively playing |
//! | `luna.simulator.isPaused()` | Return `true` if paused |
//! | `luna.simulator.isComplete()` | Return `true` if all steps dispatched |
//! | `luna.simulator.getCurrentStep()` | Return the index of the next step |
//! | `luna.simulator.getStepCount()` | Return the total step count |
//! | `luna.simulator.getCurrentScript()` | Return the active script name or `nil` |
//! | `luna.simulator.getElapsedTime()` | Return seconds elapsed since `start` |
//!
//! ## Implementation Pattern
//!
//! A single `Rc<RefCell<Simulator>>` is created at registration time and
//! captured by all closures via Rc clone. The `SharedState` borrow is held
//! only long enough to push events — never across yield points.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::automation::{Action, Script, Simulator, Step};

/// Parse a Lua step-array table into a `Vec<Step>`.
///
/// Each element of `steps_table` must be a Lua table with at least an
/// `"action"` string field. All other fields are optional and mapped to the
/// corresponding `Step` fields:
///
/// | Lua field | Step field | Used by actions |
/// |---|---|---|
/// | `action` | `action` (required) | all |
/// | `time` | `time` | all (default `0.0`) |
/// | `key` | `key` | keypress, keyrelease |
/// | `scancode` | `scancode` | keypress, keyrelease |
/// | `x` | `x` | mousemove, mousepress, mouserelease |
/// | `y` | `y` | mousemove, mousepress, mouserelease |
/// | `dx` | `dx` | mousemove, mousewheel |
/// | `dy` | `dy` | mousemove, mousewheel |
/// | `button` | `button` | mousepress, mouserelease |
/// | `text` | `text` | textinput |
/// | `isRepeat` | `is_repeat` | keypress (default `false`) |
/// | `clicks` | `clicks` | mousepress |
///
/// Returns a descriptive `LuaError` for unknown action names.
fn parse_steps(steps_table: &LuaTable) -> LuaResult<Vec<Step>> {
    let len = steps_table.len()? as usize;
    let mut steps = Vec::with_capacity(len);

    for i in 1..=len {
        let step_table = steps_table.get::<_, LuaTable>(i)?;
        let action_str: String = step_table
            .get::<_, String>("action")
            .map_err(|_| LuaError::external("simulator.load: each step must have an 'action' field"))?;

        let action = Action::parse_action(&action_str).ok_or_else(|| {
            LuaError::external(format!(
                "simulator.load: unknown action '{}' - expected one of: keypress, keyrelease, mousemove, mousepress, mouserelease, mousewheel, textinput, wait",
                action_str
            ))
        })?;

        let time: f32 = step_table.get::<_, Option<f32>>("time")?.unwrap_or(0.0);

        let mut step = Step::new(time, action);
        step.key = step_table.get::<_, Option<String>>("key")?;
        step.scancode = step_table.get::<_, Option<String>>("scancode")?;
        step.x = step_table.get::<_, Option<f64>>("x")?;
        step.y = step_table.get::<_, Option<f64>>("y")?;
        step.dx = step_table.get::<_, Option<f64>>("dx")?;
        step.dy = step_table.get::<_, Option<f64>>("dy")?;
        step.button = step_table.get::<_, Option<u32>>("button")?;
        step.text = step_table.get::<_, Option<String>>("text")?;
        step.is_repeat = step_table.get::<_, Option<bool>>("isRepeat")?.unwrap_or(false);
        step.clicks = step_table.get::<_, Option<u32>>("clicks")?;

        steps.push(step);
    }

    Ok(steps)
}

/// Register the `luna.simulator` namespace.
///
/// # Parameters
/// - `lua` \u2014 `&Lua`.
/// - `luna` \u2014 `&LuaTable`.
/// - `state` \u2014 `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let sim_table = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));

    // ── Script Management ─────────────────────────────────────────────

    {
        let sim = simulator.clone();
        sim_table.set(
            "load",
            lua.create_function(move |_lua, (name, data): (String, LuaTable)| {
                let steps_table = data
                    .get::<_, LuaTable>("steps")
                    .map_err(|_| LuaError::external("simulator.load: data table must have a 'steps' array"))?;

                let steps = parse_steps(&steps_table)?;

                let description: Option<String> = data
                    .get::<_, Option<LuaTable>>("meta")?
                    .and_then(|meta| meta.get::<_, Option<String>>("description").ok().flatten());

                let mut script = Script::new(name, steps);
                script.description = description;

                sim.borrow_mut().load(script);
                Ok(())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "unload",
            lua.create_function(move |_lua, name: String| {
                Ok(sim.borrow_mut().unload(&name))
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "hasScript",
            lua.create_function(move |_lua, name: String| {
                Ok(sim.borrow().has_script(&name))
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "getScripts",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().get_scripts())
            })?,
        )?;
    }

    // ── Playback Control ──────────────────────────────────────────────

    {
        let sim = simulator.clone();
        sim_table.set(
            "start",
            lua.create_function(move |_lua, name: String| {
                sim.borrow_mut().start(&name).map_err(LuaError::external)
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "stop",
            lua.create_function(move |_lua, ()| {
                sim.borrow_mut().stop();
                Ok(())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "pause",
            lua.create_function(move |_lua, ()| {
                sim.borrow_mut().pause();
                Ok(())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "resume",
            lua.create_function(move |_lua, ()| {
                sim.borrow_mut().resume();
                Ok(())
            })?,
        )?;
    }

    // ── update(dt) ────────────────────────────────────────────────────

    {
        let sim = simulator.clone();
        let state = state.clone();
        sim_table.set(
            "update",
            lua.create_function(move |_lua, dt: f32| {
                let mut sim = sim.borrow_mut();
                let mut s = state.borrow_mut();
                sim.update(dt, &mut s.event_queue);
                Ok(())
            })?,
        )?;
    }

    // ── Playback State ────────────────────────────────────────────────

    {
        let sim = simulator.clone();
        sim_table.set(
            "isRunning",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().is_running())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "isPaused",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().is_paused())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "isComplete",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().is_complete())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "getCurrentStep",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().current_step())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "getStepCount",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().step_count())
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "getCurrentScript",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().current_script().map(|s| s.to_string()))
            })?,
        )?;
    }

    {
        let sim = simulator.clone();
        sim_table.set(
            "getElapsedTime",
            lua.create_function(move |_lua, ()| {
                Ok(sim.borrow().elapsed_time())
            })?,
        )?;
    }

    // ── Lua-injected TOML helpers ─────────────────────────────────────

    lua.load(
        r#"
        local sim = ...
        function sim.loadFromToml(name, tomlString)
            local data = luna.data.parseToml(tomlString)
            sim.load(name, data)
        end
        function sim.loadFile(path, name)
            local content = luna.filesystem.read(path)
            local data = luna.data.parseToml(content)
            local scriptName = name or (data.meta and data.meta.name) or path
            sim.load(scriptName, data)
        end
        "#,
    )
    .call::<_, ()>(sim_table.clone())?;

    luna.set("simulator", sim_table)?;
    Ok(())
}
