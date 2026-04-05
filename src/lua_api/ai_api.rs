//! `luna.ai` Lua API bindings.
//!
//! Auto-generated skeleton from `src/ai/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaAIWorld ────────────────────────────────────────────────────────────

pub struct LuaAIWorld(/* TODO: add key + state fields */);


impl LuaAIWorld {
    /// Returns the index of an agent by name.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @param name : str
    /// @return integer?
    pub fn get_agent_index(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of agents. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn agent_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaAIWorld {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getAgentIndex", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("agentCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaBTNode ────────────────────────────────────────────────────────────

pub struct LuaBTNode(/* TODO: add key + state fields */);


impl LuaBTNode {
    /// Returns the number of direct children this node has.
    ///
    /// - Composites (Selector, Sequence, Parallel): number of child nodes.
    /// - Decorators (Inverter, Repeater, Succeeder): always 1.
    /// - Leaves (Action, Condition): always 0.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn child_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaBTNode {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("childCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaBlackboard ────────────────────────────────────────────────────────────

pub struct LuaBlackboard(/* TODO: add key + state fields */);


impl LuaBlackboard {
    /// Gets a number value, walking the parent chain. Returns `default` if not found.
    ///
    ///
    /// # Parameters
    /// - `key` — `str` ...
    /// - `default` — `number` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param key : str
    /// @param default : number
    /// @return number
    pub fn get_number(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets a boolean value, walking the parent chain. Returns `default` if not found.
    ///
    ///
    /// # Parameters
    /// - `key` — `str` ...
    /// - `default` — `boolean` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param key : str
    /// @param default : boolean
    /// @return boolean
    pub fn get_bool(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Gets a string value, walking the parent chain. Returns `default` if not found.
    ///
    ///
    /// # Parameters
    /// - `key` — `str` ...
    /// - `default` — `str` ...
    ///
    /// # Returns
    /// `string`.
    ///
    /// @param key : str
    /// @param default : str
    /// @return string
    pub fn get_string(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Checks if a key exists locally or in any ancestor.
    ///
    ///
    /// # Parameters
    /// - `key` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param key : str
    /// @return boolean
    pub fn has(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all local key names. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn keys(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of local entries. Runs in O(1) time.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns a reference to the parent Blackboard, if any.
    ///
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @return Option<
    pub fn parent(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaBlackboard {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getNumber", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getBool", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getString", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("has", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("keys", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("size", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("parent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaCommandQueue ────────────────────────────────────────────────────────────

pub struct LuaCommandQueue(/* TODO: add key + state fields */);


impl LuaCommandQueue {
    /// Returns the number of queued commands.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the queue is empty.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_empty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the type of the front command, if any.
    ///
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @return Option<
    pub fn current_type(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaCommandQueue {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("count", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEmpty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("currentType", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGOAPPlanner ────────────────────────────────────────────────────────────

pub struct LuaGOAPPlanner(/* TODO: add key + state fields */);


impl LuaGOAPPlanner {
    /// Plans a sequence of actions to satisfy the highest-priority goal.
    ///
    ///
    /// # Parameters
    /// - `world_state` — `HashMap<String, bool>` ...
    /// - `max_depth` — `integer` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param world_state : HashMap<String, bool>
    /// @param max_depth : integer
    /// @return table
    pub fn plan(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGOAPPlanner {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("plan", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaQLearner ────────────────────────────────────────────────────────────

pub struct LuaQLearner(/* TODO: add key + state fields */);


impl LuaQLearner {
    /// Selects an action using the epsilon-greedy policy.
    ///
    /// With probability ε, returns a uniformly random action (exploration).
    /// Otherwise, returns the action with the highest Q-value for the
    /// given state (exploitation). Returns 0 if `state` is out of range.
    ///
    ///
    /// # Parameters
    /// - `state` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param state : integer
    /// @return integer
    pub fn choose_action(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the greedy-best action (highest Q-value) for the given state.
    ///
    /// Ties are broken by first-encountered order. Returns 0 if `state`
    /// is out of range.
    ///
    ///
    /// # Parameters
    /// - `state` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param state : integer
    /// @return integer
    pub fn best_action(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the Q-value for a (state, action) pair, or 0.0 if out of range.
    ///
    ///
    /// # Parameters
    /// - `state` — `integer` ...
    /// - `action` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param state : integer
    /// @param action : integer
    /// @return number
    pub fn get_q(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Serializes the Q-table to a JSON string (2D array of state rows).
    ///
    /// Format: `[[q(s0,a0), q(s0,a1), ...], [q(s1,a0), ...], ...]`
    /// Use [`deserialize`](Self::deserialize) to restore from this format.
    ///
    ///
    /// # Returns
    /// `string`.
    ///
    /// @return string
    pub fn serialize(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaQLearner {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("chooseAction", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("bestAction", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getQ", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("serialize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaResponseCurve ────────────────────────────────────────────────────────────

pub struct LuaResponseCurve(/* TODO: add key + state fields */);


impl LuaResponseCurve {
    /// Transforms a raw input value through this response curve using the
    /// given parameters. The interpretation of `p1`, `p2`, and `p3` varies
    /// by curve type (see variant docs).
    ///
    /// Input is not clamped before transformation except for Logit, which
    /// clamps to `[0.001, 0.999]` to avoid division by zero.
    ///
    ///
    /// # Parameters
    /// - `input` — `number` ...
    /// - `p1` — `number` ...
    /// - `p2` — `number` ...
    /// - `p3` — `number` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param input : number
    /// @param p1 : number
    /// @param p2 : number
    /// @param p3 : number
    /// @return number
    pub fn apply(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaResponseCurve {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("apply", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSquad ────────────────────────────────────────────────────────────

pub struct LuaSquad(/* TODO: add key + state fields */);


impl LuaSquad {
    /// Computes the ideal world-space position for the member at `member_idx`
    /// given the leader's current position.
    ///
    /// The returned coordinates depend on the active [`FormationType`]:
    /// - **None**: returns `leader_pos` unchanged.
    /// - **Line**: horizontal spread centered on the leader.
    /// - **Wedge**: alternating left/right V behind the leader.
    /// - **Circle**: equal-angle arc around the leader.
    /// - **Column**: vertical stack behind the leader.
    ///
    ///
    /// # Parameters
    /// - `member_idx` — `integer` ...
    /// - `leader_pos` — `(f32, f32)` ...
    ///
    /// @param member_idx : integer
    /// @param leader_pos : (f32, f32)
    pub fn get_formation_position(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSquad {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getFormationPosition", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaStateMachine ────────────────────────────────────────────────────────────

pub struct LuaStateMachine(/* TODO: add key + state fields */);


impl LuaStateMachine {
    /// Returns the current state name, if any. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @return Option<
    pub fn current_state(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the time spent in the current state in seconds.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn time_in_state(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaStateMachine {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("currentState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("timeInState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.ai.* functions ──────────────────────────────────────────

/// Parses a Lua-side string identifier into the corresponding `DecisionModel`.
///
/// Accepted strings: `"fsm"`, `"bt"`, `"steering"`, `"fsm+steering"`, `"bt+steering"`.
/// Returns `None` for unrecognized input, allowing the Lua binding to emit
/// a descriptive error rather than silently defaulting.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self?`.
///
/// @param s : str
/// @return Self?
pub fn parse_str(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a Lua status string into a `BTStatus`.
///
/// Accepts `"success"` and `"failure"` literally; any other string
/// (including `"running"`) maps to `Running`. This permissive default
/// ensures that a Lua callback returning an unrecognized string keeps
/// the behavior alive rather than silently succeeding or failing.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param s : str
/// @return Self
/// Parses a Lua string (`"requireOne"` or `"requireAll"`) into a policy.
/// Defaults to `RequireOne` for unrecognized strings.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param s : str
/// @return Self
/// Sets a number value in the local store.
///
///
/// # Parameters
/// - `key` — `str` ...
/// - `value` — `number` ...
///
/// @param key : str
/// @param value : number
pub fn set_number(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a boolean value in the local store.
///
///
/// # Parameters
/// - `key` — `str` ...
/// - `value` — `boolean` ...
///
/// @param key : str
/// @param value : boolean
pub fn set_bool(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a string value in the local store.
///
///
/// # Parameters
/// - `key` — `str` ...
/// - `value` — `str` ...
///
/// @param key : str
/// @param value : str
pub fn set_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a key from the local store only.
///
///
/// # Parameters
/// - `key` — `str` ...
///
/// @param key : str
pub fn remove(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the parent Blackboard for hierarchical lookup.
///
///
/// # Parameters
/// - `parent` — `Blackboard` ...
///
/// @param parent : Blackboard
pub fn set_parent(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Appends a command to the back of the queue.
///
///
/// # Parameters
/// - `cmd` — `Command` ...
///
/// @param cmd : Command
pub fn enqueue(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Inserts a command at the front (interrupts current without clearing).
///
///
/// # Parameters
/// - `cmd` — `Command` ...
///
/// @param cmd : Command
pub fn push_front(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clears the queue and enqueues one new command.
///
///
/// # Parameters
/// - `cmd` — `Command` ...
///
/// @param cmd : Command
pub fn replace(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cancels the current (front) command if it's interruptible.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn cancel_current(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Adds a transition and re-sorts by descending priority.
///
///
/// # Parameters
/// - `transition` — `Transition` ...
///
/// @param transition : Transition
pub fn add_transition(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Plans for a specific goal index. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `goal_idx` — `integer` ...
/// - `world_state` — `HashMap<String, bool>` ...
/// - `max_depth` — `integer` ...
///
/// # Returns
/// `table`.
///
/// @param goal_idx : integer
/// @param world_state : HashMap<String, bool>
/// @param max_depth : integer
/// @return table
pub fn plan_for_goal_idx(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Performs one Bellman Q-learning update.
///
/// Updates the Q-value for (`state`, `action`) using the observed
/// `reward` and the estimated value of `next_state`:
///
/// `Q(s,a) ← Q(s,a) + α[r + γ max_a' Q(s',a') - Q(s,a)]`
///
/// Silently no-ops if any index is out of range.
///
///
/// # Parameters
/// - `state` — `integer` ...
/// - `action` — `integer` ...
/// - `reward` — `number` ...
/// - `next_state` — `integer` ...
///
/// @param state : integer
/// @param action : integer
/// @param reward : number
/// @param next_state : integer
pub fn learn(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Overwrites the Q-value for a (state, action) pair. No-ops if out of range.
///
///
/// # Parameters
/// - `state` — `integer` ...
/// - `action` — `integer` ...
/// - `value` — `number` ...
///
/// @param state : integer
/// @param action : integer
/// @param value : number
pub fn set_q(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Restores the Q-table from a JSON string produced by [`serialize`](Self::serialize).
///
/// Returns `Err` if the outer dimensions don't match `state_count` or
/// any row length doesn't match `action_count`.
///
///
/// # Parameters
/// - `json` — `str` ...
///
/// # Returns
/// `Result<()`.
///
/// @param json : str
/// @return Result<()
pub fn deserialize(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses a Lua string into a `FormationType`. Unrecognised strings
/// default to `FormationType::None`.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param s : str
/// @return Self
/// Parses from Lua string. Returns an error if the source data is malformed or missing.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param s : str
/// @return Self
/// Computes the 2D steering force for this behavior given the agent's
/// current kinematic state. The force should be added to the agent's
/// velocity (after weighting and truncation by the SteeringManager).
///
/// For Pursue, Evade, and Flock, this returns `(0.0, 0.0)` because
/// those behaviors need access to other agents' states, which is
/// handled at the AIWorld level.
///
///
/// # Parameters
/// - `agent_pos` — `(f32, f32)` ...
/// - `agent_vel` — `(f32, f32)` ...
/// - `max_speed` — `number` ...
/// - `_dt` — `number` ...
///
/// # Returns
/// `Force`.
///
/// @param agent_pos : (f32, f32)
/// @param agent_vel : (f32, f32)
/// @param max_speed : number
/// @param _dt : number
/// @return Force
pub fn calculate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes the combined steering force for the given agent state.
///
///
/// # Parameters
/// - `agent_pos` — `(f32, f32)` ...
/// - `agent_vel` — `(f32, f32)` ...
/// - `max_speed` — `number` ...
/// - `max_force` — `number` ...
/// - `dt` — `number` ...
///
/// # Returns
/// `Force`.
///
/// @param agent_pos : (f32, f32)
/// @param agent_vel : (f32, f32)
/// @param max_speed : number
/// @param max_force : number
/// @param dt : number
/// @return Force
/// Parses from Lua string. Returns an error if the source data is malformed or missing.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param s : str
/// @return Self
/// Adds a new agent with the given name. Returns the agent's index.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `Result<usize`.
///
/// @param name : str
/// @return Result<usize
pub fn add_agent(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes an agent by name. Rebuilds the name→index map.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param name : str
/// @return boolean
pub fn remove_agent(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.ai` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("setNumber", lua.create_function(set_number)?)?;
    tbl.set("setBool", lua.create_function(set_bool)?)?;
    tbl.set("setString", lua.create_function(set_string)?)?;
    tbl.set("remove", lua.create_function(remove)?)?;
    tbl.set("setParent", lua.create_function(set_parent)?)?;
    tbl.set("enqueue", lua.create_function(enqueue)?)?;
    tbl.set("pushFront", lua.create_function(push_front)?)?;
    tbl.set("replace", lua.create_function(replace)?)?;
    tbl.set("cancelCurrent", lua.create_function(cancel_current)?)?;
    tbl.set("addTransition", lua.create_function(add_transition)?)?;
    tbl.set("planForGoalIdx", lua.create_function(plan_for_goal_idx)?)?;
    tbl.set("learn", lua.create_function(learn)?)?;
    tbl.set("setQ", lua.create_function(set_q)?)?;
    tbl.set("deserialize", lua.create_function(deserialize)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("calculate", lua.create_function(calculate)?)?;
    tbl.set("calculate", lua.create_function(calculate)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("addAgent", lua.create_function(add_agent)?)?;
    tbl.set("removeAgent", lua.create_function(remove_agent)?)?;
    luna.set("ai", tbl)?;
    Ok(())
}
