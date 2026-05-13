use super::SharedState;
use crate::automation::{Action, Script, Simulator, Step};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let simulator = Rc::new(RefCell::new(Simulator::new()));
    let wait_state: Rc<RefCell<Option<(LuaRegistryKey, f32, f32)>>> = Rc::new(RefCell::new(None));
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
    let sim = simulator.clone();
    tbl.set(
        "unload",
        lua.create_function(move |_, name: String| Ok(sim.borrow_mut().unload(&name)))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "hasScript",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_script(&name)))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getScripts",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_scripts()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "start",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut().start(&name).map_err(LuaError::external)
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "stop",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().stop();
            Ok(())
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "pause",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().pause();
            Ok(())
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "resume",
        lua.create_function(move |_, ()| {
            sim.borrow_mut().resume();
            Ok(())
        })?,
    )?;
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
    let sim = simulator.clone();
    tbl.set(
        "isRunning",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_running()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_paused()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "isComplete",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_complete()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "isFailed",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_failed()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getLastError",
        lua.create_function(move |_, ()| Ok(sim.borrow().last_error().map(|s| s.to_string())))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "setCondition",
        lua.create_function(move |_, (name, value): (String, bool)| {
            sim.borrow_mut().set_condition(name, value);
            Ok(())
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getCondition",
        lua.create_function(move |_, name: String| Ok(sim.borrow().get_condition(&name)))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getCurrentStep",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_step()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getStepCount",
        lua.create_function(move |_, ()| Ok(sim.borrow().step_count()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getCurrentScript",
        lua.create_function(move |_, ()| Ok(sim.borrow().current_script().map(|s| s.to_string())))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getElapsedTime",
        lua.create_function(move |_, ()| Ok(sim.borrow().elapsed_time()))?,
    )?;
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
    let sim = simulator.clone();
    tbl.set(
        "getStepLimit",
        lua.create_function(move |_, name: String| {
            Ok(sim.borrow().get_script_step_limit(&name).map(|v| v as u64))
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "setStepLimit",
        lua.create_function(move |_, (name, n): (String, u64)| {
            Ok(sim.borrow_mut().set_script_step_limit(&name, n as usize))
        })?,
    )?;
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
    let sim = simulator.clone();
    tbl.set(
        "playMacro",
        lua.create_function(move |_, name: String| {
            sim.borrow_mut()
                .play_macro(&name)
                .map_err(LuaError::external)
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "hasMacro",
        lua.create_function(move |_, name: String| Ok(sim.borrow().has_macro(&name)))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "listMacros",
        lua.create_function(move |_, ()| Ok(sim.borrow().list_macros()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "setPlaybackSpeed",
        lua.create_function(move |_, factor: f32| {
            sim.borrow_mut().set_playback_speed(factor);
            Ok(())
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "getPlaybackSpeed",
        lua.create_function(move |_, ()| Ok(sim.borrow().get_playback_speed()))?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "setHighlightMode",
        lua.create_function(move |_, enable: bool| {
            sim.borrow_mut().set_highlight_mode(enable);
            Ok(())
        })?,
    )?;
    let sim = simulator.clone();
    tbl.set(
        "isHighlightMode",
        lua.create_function(move |_, ()| Ok(sim.borrow().is_highlight_mode()))?,
    )?;
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
