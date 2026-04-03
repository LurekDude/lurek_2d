//! Registers the `luna.steering.*` steering and spatial AI API.
//!
//! Provides Reynolds-style steering behaviours, influence maps, and squad formation
//! management. These are movement and spatial reasoning systems, distinct from the
//! decision-making AI in `luna.ai`.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::ai::{InfluenceMap, Squad, SteeringManager};
use crate::lua_api::lua_types::LunaType;

// ── SteeringManager ─────────────────────────────────────────────────────────

/// Lua wrapper for a Reynolds-style steering manager.
#[allow(dead_code)]
#[derive(Clone)]
struct LuaSteeringManager {
    inner: Rc<RefCell<SteeringManager>>,
}

impl LunaType for LuaSteeringManager {
    const TYPE_NAME: &'static str = "SteeringManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

// ── InfluenceMap ─────────────────────────────────────────────────────────────

/// Lua wrapper for a 2D influence map for spatial heatmaps.
#[allow(dead_code)]
#[derive(Clone)]
struct LuaInfluenceMap {
    inner: Rc<RefCell<InfluenceMap>>,
}

impl LunaType for LuaInfluenceMap {
    const TYPE_NAME: &'static str = "InfluenceMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

// ── Squad ─────────────────────────────────────────────────────────────────────

/// Lua wrapper for a formation-based squad.
#[allow(dead_code)]
#[derive(Clone)]
struct LuaSquad {
    inner: Rc<RefCell<Squad>>,
}

impl LunaType for LuaSquad {
    const TYPE_NAME: &'static str = "Squad";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Registers the `luna.steering` table on the provided `luna` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let steering = lua.create_table()?;

    // TODO: Implement LuaUserData for SteeringManager, InfluenceMap, Squad
    // and move their factory functions from ai_api.rs here.
    // The types are in crate::ai::{SteeringManager, InfluenceMap, Squad}.
    //
    // Factory functions to move from luna.ai:
    //   luna.ai.newSteeringManager() → luna.steering.newSteeringManager()
    //   luna.ai.newInfluenceMap()    → luna.steering.newInfluenceMap()
    //   luna.ai.newSquad()           → luna.steering.newSquad()

    luna.set("steering", steering)?;
    Ok(())
}
