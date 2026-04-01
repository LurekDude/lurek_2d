//! Registers the `luna.ai.*` game AI toolkit API.
//!
//! Provides factory functions and UserData wrappers for AI subsystems:
//! AIWorld, Agent, Blackboard, StateMachine, BehaviorTree, SteeringManager,
//! PathGrid, FlowField, QLearner, UtilityAI, GOAPPlanner, InfluenceMap,
//! Squad, and CommandQueue.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::ai::*;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// UserData wrappers
// ---------------------------------------------------------------------------

/// Lua wrapper for an AI world that owns agents and a global blackboard.
#[derive(Clone)]
struct LuaAIWorld {
    inner: Rc<RefCell<AIWorld>>,
}

impl LunaType for LuaAIWorld {
    const TYPE_NAME: &'static str = "AIWorld";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a single AI agent, accessed by name through the owning world.
#[derive(Clone)]
struct LuaAgent {
    world: Rc<RefCell<AIWorld>>,
    name: String,
}

impl LunaType for LuaAgent {
    const TYPE_NAME: &'static str = "Agent";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a typed key-value blackboard.
#[derive(Clone)]
struct LuaBlackboard {
    inner: Rc<RefCell<Blackboard>>,
}

impl LunaType for LuaBlackboard {
    const TYPE_NAME: &'static str = "Blackboard";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a finite state machine.
#[derive(Clone)]
struct LuaStateMachine {
    inner: Rc<RefCell<StateMachine>>,
}

impl LunaType for LuaStateMachine {
    const TYPE_NAME: &'static str = "StateMachine";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a behavior tree.
#[derive(Clone)]
struct LuaBehaviorTree {
    inner: Rc<RefCell<BehaviorTree>>,
}

impl LunaType for LuaBehaviorTree {
    const TYPE_NAME: &'static str = "BehaviorTree";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a single behavior tree node (recursive structure).
#[derive(Clone)]
struct LuaBTNode {
    inner: Rc<RefCell<BTNode>>,
}

impl LunaType for LuaBTNode {
    const TYPE_NAME: &'static str = "BTNode";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a Reynolds-style steering manager.
#[derive(Clone)]
struct LuaSteeringManager {
    inner: Rc<RefCell<SteeringManager>>,
}

impl LunaType for LuaSteeringManager {
    const TYPE_NAME: &'static str = "SteeringManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for an A* navigation grid.
#[derive(Clone)]
struct LuaPathGrid {
    inner: Rc<RefCell<PathGrid>>,
}

impl LunaType for LuaPathGrid {
    const TYPE_NAME: &'static str = "PathGrid";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a BFS flow field.
#[derive(Clone)]
struct LuaFlowField {
    inner: Rc<RefCell<FlowField>>,
}

impl LunaType for LuaFlowField {
    const TYPE_NAME: &'static str = "FlowField";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a tabular Q-learner.
#[derive(Clone)]
struct LuaQLearner {
    inner: Rc<RefCell<QLearner>>,
}

impl LunaType for LuaQLearner {
    const TYPE_NAME: &'static str = "QLearner";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a multi-axis utility scorer.
#[derive(Clone)]
struct LuaUtilityAI {
    inner: Rc<RefCell<UtilityAI>>,
}

impl LunaType for LuaUtilityAI {
    const TYPE_NAME: &'static str = "UtilityAI";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for an A* GOAP planner.
#[derive(Clone)]
struct LuaGOAPPlanner {
    inner: Rc<RefCell<GOAPPlanner>>,
}

impl LunaType for LuaGOAPPlanner {
    const TYPE_NAME: &'static str = "GOAPPlanner";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a multi-layer influence map.
#[derive(Clone)]
struct LuaInfluenceMap {
    inner: Rc<RefCell<InfluenceMap>>,
}

impl LunaType for LuaInfluenceMap {
    const TYPE_NAME: &'static str = "InfluenceMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for a formation-based squad.
#[derive(Clone)]
struct LuaSquad {
    inner: Rc<RefCell<Squad>>,
}

impl LunaType for LuaSquad {
    const TYPE_NAME: &'static str = "Squad";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

/// Lua wrapper for an RTS-style command queue.
#[derive(Clone)]
struct LuaCommandQueue {
    inner: Rc<RefCell<CommandQueue>>,
}

impl LunaType for LuaCommandQueue {
    const TYPE_NAME: &'static str = "CommandQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

// ---------------------------------------------------------------------------
// UserData implementations
// ---------------------------------------------------------------------------

impl LuaUserData for LuaAIWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Registers a new agent named `name` in this world and returns its handle.
        ///
        /// # Parameters
        /// - `name` — `string`: Unique identifier for the new agent.
        ///
        /// # Returns
        /// An `Agent` handle ready for further configuration.
        methods.add_method("addAgent", |_, this, name: String| {
            let mut w = this.inner.borrow_mut();
            w.add_agent(&name).map_err(LuaError::RuntimeError)?;
            Ok(LuaAgent {
                world: this.inner.clone(),
                name,
            })
        });

        /// Looks up a registered agent by name.
        ///
        /// # Parameters
        /// - `name` — `string`: Name of the agent to retrieve.
        ///
        /// # Returns
        /// The `Agent` handle, or `nil` if no agent with that name exists.
        methods.add_method("getAgent", |_, this, name: String| {
            let w = this.inner.borrow();
            if w.get_agent_index(&name).is_some() {
                Ok(Some(LuaAgent {
                    world: this.inner.clone(),
                    name,
                }))
            } else {
                Ok(None)
            }
        });

        /// Removes and destroys the given agent from this world.
        ///
        /// # Parameters
        /// - `agent` — `Agent`: Handle of the agent to remove, obtained from `addAgent`.
        methods.add_method("removeAgent", |_, this, agent: LuaAnyUserData| {
            let a = agent.borrow::<LuaAgent>()?;
            let mut w = this.inner.borrow_mut();
            w.remove_agent(&a.name);
            Ok(())
        });

        /// Returns the number of agents currently registered in this world.
        ///
        /// # Returns
        /// `integer` — total agent count.
        methods.add_method("getAgentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count())
        });

        /// Returns a snapshot of the shared world-level blackboard.
        ///
        /// # Returns
        /// A `Blackboard` containing data visible to all agents in this world.
        methods.add_method("getGlobalBlackboard", |_, this, ()| {
            let w = this.inner.borrow();
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(w.global_blackboard().clone())),
            })
        });

        /// Advances all agents in the world by `dt` seconds, integrating velocity into position.
        ///
        /// # Parameters
        /// - `dt` — `number`: Elapsed seconds since the last frame.
        methods.add_method("update", |_, this, dt: f32| {
            let mut w = this.inner.borrow_mut();
            for agent in &mut w.agents {
                agent.position.0 += agent.velocity.0 * dt;
                agent.position.1 += agent.velocity.1 * dt;
            }
            Ok(())
        });
    }
}

impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the unique name this agent was registered under.
        ///
        /// # Returns
        /// `string` — agent name.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        /// Teleports the agent to world-space coordinates (`x`, `y`).
        ///
        /// # Parameters
        /// - `x` — `number`: Horizontal world-space position.
        /// - `y` — `number`: Vertical world-space position.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].position = (x, y);
            }
            Ok(())
        });

        /// Returns the agent's current world-space position.
        ///
        /// # Returns
        /// Two numbers `x, y` representing world-space coordinates.
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].position)
            } else {
                Ok((0.0, 0.0))
            }
        });

        /// Sets the agent's velocity vector in world units per second.
        ///
        /// # Parameters
        /// - `x` — `number`: Horizontal component.
        /// - `y` — `number`: Vertical component.
        methods.add_method("setVelocity", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].velocity = (x, y);
            }
            Ok(())
        });

        /// Returns the agent's current velocity vector.
        ///
        /// # Returns
        /// Two numbers `vx, vy` in world units/second.
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].velocity)
            } else {
                Ok((0.0, 0.0))
            }
        });

        /// Sets the maximum movement speed cap in world units/second.
        ///
        /// # Parameters
        /// - `v` — `number`: New speed limit (world units/sec).
        methods.add_method("setMaxSpeed", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_speed = v;
            }
            Ok(())
        });

        /// Returns the maximum movement speed cap in world units/second.
        ///
        /// # Returns
        /// `number` — speed cap.
        methods.add_method("getMaxSpeed", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_speed)
            } else {
                Ok(100.0)
            }
        });

        /// Sets the maximum steering force that can be applied per frame.
        ///
        /// # Parameters
        /// - `v` — `number`: New force cap.
        methods.add_method("setMaxForce", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_force = v;
            }
            Ok(())
        });

        /// Returns the maximum steering force cap.
        ///
        /// # Returns
        /// `number` — force cap.
        methods.add_method("getMaxForce", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_force)
            } else {
                Ok(200.0)
            }
        });

        /// Sets the scheduling priority; higher-priority agents are processed first during `update`.
        ///
        /// # Parameters
        /// - `p` — `integer`: Priority value, higher = earlier processing.
        methods.add_method("setPriority", |_, this, p: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].priority = p;
            }
            Ok(())
        });

        /// Returns the agent's scheduling priority level.
        ///
        /// # Returns
        /// `integer` — priority.
        methods.add_method("getPriority", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].priority)
            } else {
                Ok(0)
            }
        });

        /// Switches the agent's active decision model at runtime. Valid values: `"fsm"`, `"bt"`, `"utility"`, `"goap"`.
        ///
        /// # Parameters
        /// - `model` — `string`: Decision model identifier.
        methods.add_method("setDecisionModel", |_, this, model: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                if let Some(dm) = DecisionModel::parse_str(&model) {
                    w.agents[idx].decision_model = dm;
                }
            }
            Ok(())
        });

        /// Returns the name of the agent's current decision model.
        ///
        /// # Returns
        /// `string` — e.g. `"fsm"`, `"bt"`, `"utility"`, `"goap"`.
        methods.add_method("getDecisionModel", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].decision_model.as_str().to_string())
            } else {
                Ok("fsm".to_string())
            }
        });

        /// Adds a string tag to this agent's tag set (idempotent).
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to add.
        methods.add_method("addTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.insert(tag);
            }
            Ok(())
        });

        /// Removes a string tag from this agent's tag set (no-op if absent).
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to remove.
        methods.add_method("removeTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.remove(&tag);
            }
            Ok(())
        });

        /// Returns `true` if this agent's tag set contains `tag`.
        ///
        /// # Parameters
        /// - `tag` — `string`: Tag to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].tags.contains(&tag))
            } else {
                Ok(false)
            }
        });

        /// Returns this agent's private blackboard for reading or writing typed data.
        ///
        /// # Returns
        /// A `Blackboard` scoped to this agent.
        methods.add_method("getBlackboard", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(LuaBlackboard {
                    inner: Rc::new(RefCell::new(w.agents[idx].blackboard.clone())),
                })
            } else {
                Ok(LuaBlackboard {
                    inner: Rc::new(RefCell::new(Blackboard::new())),
                })
            }
        });
    }
}

impl LuaUserData for LuaBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Stores a floating-point value under `key` on this blackboard.
        ///
        /// # Parameters
        /// - `key` — `string`: Key to write.
        /// - `value` — `number`: Value to store.
        methods.add_method("setNumber", |_, this, (key, value): (String, f64)| {
            this.inner.borrow_mut().set_number(&key, value);
            Ok(())
        });

        methods.add_method(
            "getNumber",
            |_, this, (key, default): (String, Option<f64>)| {
                Ok(this.inner.borrow().get_number(&key, default.unwrap_or(0.0)))
            },
        );

        /// Stores a boolean value under `key` on this blackboard.
        ///
        /// # Parameters
        /// - `key` — `string`: Key to write.
        /// - `value` — `boolean`: Value to store.
        methods.add_method("setBool", |_, this, (key, value): (String, bool)| {
            this.inner.borrow_mut().set_bool(&key, value);
            Ok(())
        });

        methods.add_method(
            "getBool",
            |_, this, (key, default): (String, Option<bool>)| {
                Ok(this.inner.borrow().get_bool(&key, default.unwrap_or(false)))
            },
        );

        /// Stores a string value under `key` on this blackboard.
        ///
        /// # Parameters
        /// - `key` — `string`: Key to write.
        /// - `value` — `string`: Value to store.
        methods.add_method("setString", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().set_string(&key, &value);
            Ok(())
        });

        methods.add_method(
            "getString",
            |_, this, (key, default): (String, Option<String>)| {
                let def = default.unwrap_or_default();
                Ok(this.inner.borrow().get_string(&key, &def))
            },
        );

        /// Returns `true` if a value is stored under `key` in this blackboard.
        ///
        /// # Parameters
        /// - `key` — `string`: Key to check.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.inner.borrow().has(&key))
        });

        /// Deletes the entry at `key` from this blackboard (no-op if absent).
        ///
        /// # Parameters
        /// - `key` — `string`: Key to delete.
        methods.add_method("remove", |_, this, key: String| {
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });

        /// Removes all entries from this blackboard.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Returns the keys.
        ///
        /// # Returns
        /// The current keys.
        methods.add_method("getKeys", |lua, this, ()| {
            let keys = this.inner.borrow().keys();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i as i64 + 1, k.as_str())?;
            }
            Ok(tbl)
        });

        /// Returns the size.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().size()));
    }
}

impl LuaUserData for LuaStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Registers a new named state in this FSM.
        ///
        /// # Parameters
        /// - `name` — `string`: Unique name for the state.
        methods.add_method("addState", |lua, this, (name, opts): (String, LuaTable)| {
            let on_enter: Option<LuaFunction> = opts.get("onEnter").ok();
            let on_update: Option<LuaFunction> = opts.get("onUpdate").ok();
            let on_exit: Option<LuaFunction> = opts.get("onExit").ok();

            let enter_key = on_enter.map(|f| lua.create_registry_value(f)).transpose()?;
            let update_key = on_update
                .map(|f| lua.create_registry_value(f))
                .transpose()?;
            let exit_key = on_exit.map(|f| lua.create_registry_value(f)).transpose()?;

            let mut fsm = this.inner.borrow_mut();
            fsm.states.insert(
                name,
                StateCallbacks {
                    on_enter: enter_key,
                    on_update: update_key,
                    on_exit: exit_key,
                },
            );
            Ok(())
        });

        methods.add_method(
            "addTransition",
            |lua, this, (from, to, guard, priority): (String, String, Option<LuaFunction>, Option<i32>)| {
                let guard_key = guard
                    .map(|f| lua.create_registry_value(f))
                    .transpose()?;
                let mut fsm = this.inner.borrow_mut();
                fsm.add_transition(Transition {
                    from,
                    to,
                    guard: guard_key,
                    priority: priority.unwrap_or(0),
                });
                Ok(())
            },
        );

        /// Sets the initial state.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("setInitialState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.initial_state = Some(name.clone());
            if fsm.current_state.is_none() {
                fsm.current_state = Some(name);
            }
            Ok(())
        });

        /// Returns the current state.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current current state.
        methods.add_method("getCurrentState", |_, this, ()| {
            Ok(this.inner.borrow().current_state().map(|s| s.to_string()))
        });

        /// Force state on this StateMachine.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("forceState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.current_state = Some(name);
            fsm.time_in_state = 0.0;
            Ok(())
        });

        /// Returns the time in state.
        ///
        /// # Returns
        /// The current time in state.
        methods.add_method("getTimeInState", |_, this, ()| {
            Ok(this.inner.borrow().time_in_state())
        });
    }
}

impl LuaUserData for LuaBehaviorTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Sets the top-level root node of this behavior tree.
        ///
        /// # Parameters
        /// - `node` — `BTNode`: Root `BTNode` returned by one of the node constructors.
        methods.add_method("setRoot", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaBTNode>()?;
            let taken = std::mem::replace(
                &mut *node.inner.borrow_mut(),
                BTNode::Sequence {
                    children: Vec::new(),
                    running_idx: 0,
                },
            );
            this.inner.borrow_mut().root = Some(taken);
            Ok(())
        });

        /// Returns the last status.
        ///
        /// # Returns
        /// The current last status.
        methods.add_method("getLastStatus", |_, this, ()| {
            Ok(this.inner.borrow().last_status.as_str().to_string())
        });
    }
}

impl LuaUserData for LuaBTNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Adds child to the collection.
        ///
        /// # Parameters
        /// - `child_ud` — `userdata`.
        methods.add_method("addChild", |_, this, child_ud: LuaAnyUserData| {
            let child = child_ud.borrow::<LuaBTNode>()?;
            let taken = std::mem::replace(
                &mut *child.inner.borrow_mut(),
                BTNode::Sequence {
                    children: Vec::new(),
                    running_idx: 0,
                },
            );
            let mut node = this.inner.borrow_mut();
            match &mut *node {
                BTNode::Selector { children, .. }
                | BTNode::Sequence { children, .. }
                | BTNode::Parallel { children, .. } => {
                    children.push(taken);
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "addChild is only valid for Selector, Sequence, or Parallel nodes"
                            .to_string(),
                    ));
                }
            }
            Ok(())
        });

        /// Returns the child count.
        ///
        /// # Returns
        /// The current child count.
        methods.add_method("getChildCount", |_, this, ()| {
            let node = this.inner.borrow();
            let count = match &*node {
                BTNode::Selector { children, .. }
                | BTNode::Sequence { children, .. }
                | BTNode::Parallel { children, .. } => children.len(),
                _ => 0,
            };
            Ok(count)
        });

        /// Resets state to initial values.
        ///
        /// # Parameters
        /// - `child_ud` — `userdata`.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        /// Sets the child.
        ///
        /// # Parameters
        /// - `child_ud` — `userdata`.
        methods.add_method("setChild", |_, this, child_ud: LuaAnyUserData| {
            let child = child_ud.borrow::<LuaBTNode>()?;
            let taken = std::mem::replace(
                &mut *child.inner.borrow_mut(),
                BTNode::Sequence {
                    children: Vec::new(),
                    running_idx: 0,
                },
            );
            let mut node = this.inner.borrow_mut();
            match &mut *node {
                BTNode::Inverter { child } => {
                    **child = taken;
                }
                BTNode::Repeater { child, .. } => {
                    **child = taken;
                }
                BTNode::Succeeder { child } => {
                    **child = taken;
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "setChild is only valid for Inverter, Repeater, or Succeeder nodes"
                            .to_string(),
                    ));
                }
            }
            Ok(())
        });

        /// Sets the count.
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("setCount", |_, this, n: u32| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Repeater { count, .. } = &mut *node {
                *count = n;
            }
            Ok(())
        });

        /// Returns the count.
        ///
        /// # Returns
        /// The current count.
        methods.add_method("getCount", |_, this, ()| {
            let node = this.inner.borrow();
            if let BTNode::Repeater { count, .. } = &*node {
                Ok(*count)
            } else {
                Ok(0)
            }
        });

        /// Sets the success policy.
        ///
        /// # Parameters
        /// - `policy` — `string`.
        methods.add_method("setSuccessPolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { success_policy, .. } = &mut *node {
                *success_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        /// Sets the failure policy.
        ///
        /// # Parameters
        /// - `policy` — `string`.
        methods.add_method("setFailurePolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { failure_policy, .. } = &mut *node {
                *failure_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        /// Returns the node type.
        ///
        /// # Returns
        /// The current node type.
        methods.add_method("getNodeType", |_, this, ()| {
            let node = this.inner.borrow();
            let name = match &*node {
                BTNode::Selector { .. } => "selector",
                BTNode::Sequence { .. } => "sequence",
                BTNode::Parallel { .. } => "parallel",
                BTNode::Inverter { .. } => "inverter",
                BTNode::Repeater { .. } => "repeater",
                BTNode::Succeeder { .. } => "succeeder",
                BTNode::Action { .. } => "action",
                BTNode::Condition { .. } => "condition",
            };
            Ok(name.to_string())
        });
    }
}

impl LuaUserData for LuaSteeringManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method(
            "addSeek",
            |_, this, (tx, ty, weight): (f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Seek {
                        target: (tx, ty),
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addFlee",
            |_, this, (tx, ty, panic_dist, weight): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Flee {
                        target: (tx, ty),
                        panic_dist: panic_dist.unwrap_or(200.0),
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addArrive",
            |_, this, (tx, ty, slowing, weight): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Arrive {
                        target: (tx, ty),
                        slowing_radius: slowing.unwrap_or(50.0),
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addWander",
            |_,
             this,
             (radius, dist, jitter, weight): (
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Wander {
                        wander_radius: radius.unwrap_or(20.0),
                        wander_distance: dist.unwrap_or(40.0),
                        wander_jitter: jitter.unwrap_or(5.0),
                        wander_angle: 0.0,
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addPursue",
            |_, this, (target_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Pursue {
                        target_name,
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addEvade",
            |_, this, (threat_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Evade {
                        threat_name,
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        methods.add_method(
            "addFlock",
            #[allow(clippy::type_complexity)]
            |_,
             this,
             (neighbor_radius, sep_w, align_w, coh_w, weight): (
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(SteeringBehaviorType::Flock {
                        neighbor_radius: neighbor_radius.unwrap_or(100.0),
                        sep_weight: sep_w.unwrap_or(1.5),
                        align_weight: align_w.unwrap_or(1.0),
                        coh_weight: coh_w.unwrap_or(1.0),
                        neighbor_names: Vec::new(),
                        base: SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        /// Returns the behavior count.
        ///
        /// # Parameters
        /// - `mode` — `string`.
        ///
        /// # Returns
        /// The current behavior count.
        methods.add_method("getBehaviorCount", |_, this, ()| {
            Ok(this.inner.borrow().behaviors.len())
        });

        /// Sets the combine mode.
        ///
        /// # Parameters
        /// - `mode` — `string`.
        methods.add_method("setCombineMode", |_, this, mode: String| {
            this.inner.borrow_mut().combine_mode = CombineMode::parse_str(&mode);
            Ok(())
        });

        /// Returns the combine mode.
        ///
        /// # Returns
        /// The current combine mode.
        methods.add_method("getCombineMode", |_, this, ()| {
            Ok(this.inner.borrow().combine_mode.as_str().to_string())
        });

        /// Returns the last steering.
        ///
        /// # Returns
        /// The current last steering.
        methods.add_method("getLastSteering", |_, this, ()| {
            Ok(this.inner.borrow().last_force)
        });

        methods.add_method(
            "calculate",
            |_,
             this,
             (px, py, vx, vy, max_speed, max_force, dt): (f32, f32, f32, f32, f32, f32, f32)| {
                let force = this.inner.borrow_mut().calculate(
                    (px, py),
                    (vx, vy),
                    max_speed,
                    max_force,
                    dt,
                );
                Ok(force)
            },
        );
    }
}

impl LuaUserData for LuaPathGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the width.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        /// Returns the height.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `walkable` — `boolean`.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        /// Returns the cell size.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `walkable` — `boolean`.
        ///
        /// # Returns
        /// The current cell size.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });

        methods.add_method(
            "setWalkable",
            |_, this, (x, y, walkable): (usize, usize, bool)| {
                let lx = x.saturating_sub(1);
                let ly = y.saturating_sub(1);
                this.inner.borrow_mut().set_walkable(lx, ly, walkable);
                Ok(())
            },
        );

        /// Returns `true` if walkable.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isWalkable", |_, this, (x, y): (usize, usize)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            Ok(this.inner.borrow().is_walkable(lx, ly))
        });

        /// Sets the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `cost` — `number`.
        methods.add_method("setCost", |_, this, (x, y, cost): (usize, usize, f32)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            this.inner.borrow_mut().set_cost(lx, ly, cost);
            Ok(())
        });

        /// Returns the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current cost.
        methods.add_method("getCost", |_, this, (x, y): (usize, usize)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            Ok(this.inner.borrow().get_cost(lx, ly))
        });

        methods.add_method(
            "findPath",
            |lua, this, (sx, sy, gx, gy): (usize, usize, usize, usize)| {
                let lsx = sx.saturating_sub(1);
                let lsy = sy.saturating_sub(1);
                let lgx = gx.saturating_sub(1);
                let lgy = gy.saturating_sub(1);
                let grid = this.inner.borrow();
                match grid.find_path(lsx, lsy, lgx, lgy) {
                    Some(path) => {
                        let tbl = lua.create_table()?;
                        for (i, (wx, wy)) in path.iter().enumerate() {
                            let pt = lua.create_table()?;
                            /// X on this PathGrid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("x", *wx)?;
                            /// Y on this PathGrid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("y", *wy)?;
                            tbl.set(i as i64 + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        methods.add_method(
            "findPathSmoothed",
            |lua, this, (sx, sy, gx, gy): (usize, usize, usize, usize)| {
                let lsx = sx.saturating_sub(1);
                let lsy = sy.saturating_sub(1);
                let lgx = gx.saturating_sub(1);
                let lgy = gy.saturating_sub(1);
                let grid = this.inner.borrow();
                match grid.find_path_smoothed(lsx, lsy, lgx, lgy) {
                    Some(path) => {
                        let tbl = lua.create_table()?;
                        for (i, (wx, wy)) in path.iter().enumerate() {
                            let pt = lua.create_table()?;
                            /// X on this PathGrid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("x", *wx)?;
                            /// Y on this PathGrid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("y", *wy)?;
                            tbl.set(i as i64 + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );
    }
}

impl LuaUserData for LuaFlowField {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Sets the goal.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        methods.add_method("setGoal", |_, this, (x, y): (usize, usize)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            this.inner.borrow_mut().set_goal(lx, ly);
            Ok(())
        });

        /// Returns the direction.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current direction.
        methods.add_method("getDirection", |_, this, (x, y): (usize, usize)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            Ok(this.inner.borrow().get_direction(lx, ly))
        });

        /// Returns the distance.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current distance.
        methods.add_method("getDistance", |_, this, (x, y): (usize, usize)| {
            let lx = x.saturating_sub(1);
            let ly = y.saturating_sub(1);
            Ok(this.inner.borrow().get_distance(lx, ly))
        });

        /// Returns the width.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        /// Returns the height.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        /// Returns `true` if goal.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasGoal", |_, this, ()| {
            Ok(this.inner.borrow().goal.is_some())
        });

        /// Returns the goal.
        ///
        /// # Returns
        /// The current goal.
        methods.add_method("getGoal", |_, this, ()| match this.inner.borrow().goal {
            Some((gx, gy)) => Ok((
                LuaValue::Integer((gx + 1) as i64),
                LuaValue::Integer((gy + 1) as i64),
            )),
            None => Ok((LuaValue::Nil, LuaValue::Nil)),
        });
    }
}

impl LuaUserData for LuaQLearner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Choose action on this QLearner.
        ///
        /// # Parameters
        /// - `state` — `integer`.
        methods.add_method("chooseAction", |_, this, state: usize| {
            let s = state.saturating_sub(1);
            Ok(this.inner.borrow().choose_action(s) + 1)
        });

        /// Returns the action with the highest Q-value for `state`.
        ///
        /// # Parameters
        /// - `state` — `string`: State to query.
        ///
        /// # Returns
        /// `string` — best-known action name.
        methods.add_method("bestAction", |_, this, state: usize| {
            let s = state.saturating_sub(1);
            Ok(this.inner.borrow().best_action(s) + 1)
        });

        /// Returns the best action.
        ///
        /// # Parameters
        /// - `state` — `integer`.
        /// - `action` — `integer`.
        /// - `reward` — `number`.
        /// - `next_state` — `integer`.
        ///
        /// # Returns
        /// The current best action.
        methods.add_method("getBestAction", |_, this, state: usize| {
            let s = state.saturating_sub(1);
            Ok(this.inner.borrow().best_action(s) + 1)
        });

        methods.add_method(
            "learn",
            |_, this, (state, action, reward, next_state): (usize, usize, f64, usize)| {
                let s = state.saturating_sub(1);
                let a = action.saturating_sub(1);
                let ns = next_state.saturating_sub(1);
                this.inner.borrow_mut().learn(s, a, reward, ns);
                Ok(())
            },
        );

        /// Returns the q value.
        ///
        /// # Parameters
        /// - `state` — `integer`.
        /// - `action` — `integer`.
        ///
        /// # Returns
        /// The current q value.
        methods.add_method("getQValue", |_, this, (state, action): (usize, usize)| {
            let s = state.saturating_sub(1);
            let a = action.saturating_sub(1);
            Ok(this.inner.borrow().get_q(s, a))
        });

        methods.add_method(
            "setQValue",
            |_, this, (state, action, value): (usize, usize, f64)| {
                let s = state.saturating_sub(1);
                let a = action.saturating_sub(1);
                this.inner.borrow_mut().set_q(s, a, value);
                Ok(())
            },
        );

        /// End episode on this QLearner.
        ///
        /// # Returns
        /// The result.
        methods.add_method("endEpisode", |_, this, ()| {
            this.inner.borrow_mut().end_episode();
            Ok(())
        });

        /// Returns the episode count.
        ///
        /// # Returns
        /// The current episode count.
        methods.add_method("getEpisodeCount", |_, this, ()| {
            Ok(this.inner.borrow().episode_count)
        });

        /// Returns the state count.
        ///
        /// # Returns
        /// The current state count.
        methods.add_method("getStateCount", |_, this, ()| {
            Ok(this.inner.borrow().state_count)
        });

        /// Returns the action count.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().action_count)
        });

        /// Sets the learning rate.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setLearningRate", |_, this, v: f64| {
            this.inner.borrow_mut().alpha = v;
            Ok(())
        });

        /// Returns the learning rate.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current learning rate.
        methods.add_method("getLearningRate", |_, this, ()| {
            Ok(this.inner.borrow().alpha)
        });

        /// Sets the discount factor.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setDiscountFactor", |_, this, v: f64| {
            this.inner.borrow_mut().gamma = v;
            Ok(())
        });

        /// Returns the discount factor.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current discount factor.
        methods.add_method("getDiscountFactor", |_, this, ()| {
            Ok(this.inner.borrow().gamma)
        });

        /// Sets the exploration rate.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setExplorationRate", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon = v;
            Ok(())
        });

        /// Returns the exploration rate.
        ///
        /// # Parameters
        /// - `v` — `number`.
        ///
        /// # Returns
        /// The current exploration rate.
        methods.add_method("getExplorationRate", |_, this, ()| {
            Ok(this.inner.borrow().epsilon)
        });

        /// Sets the exploration decay.
        ///
        /// # Parameters
        /// - `v` — `number`.
        methods.add_method("setExplorationDecay", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon_decay = v;
            Ok(())
        });

        /// Returns the exploration decay.
        ///
        /// # Returns
        /// The current exploration decay.
        methods.add_method("getExplorationDecay", |_, this, ()| {
            Ok(this.inner.borrow().epsilon_decay)
        });

        /// Serializes this object to a string representation.
        ///
        /// # Parameters
        /// - `json` — `string`.
        methods.add_method("serialize", |_, this, ()| {
            Ok(this.inner.borrow().serialize())
        });

        /// Populates this object from a serialized string.
        ///
        /// # Parameters
        /// - `json` — `string`.
        methods.add_method("deserialize", |_, this, json: String| {
            this.inner
                .borrow_mut()
                .deserialize(&json)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });
    }
}

impl LuaUserData for LuaUtilityAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method(
            "addAction",
            |lua, this, (name, scorer_fn, weight): (String, LuaFunction, Option<f64>)| {
                let key = lua.create_registry_value(scorer_fn)?;
                this.inner.borrow_mut().actions.push(UAAction {
                    name,
                    scorer: key,
                    considerations: Vec::new(),
                    momentum_bonus: weight.unwrap_or(1.0),
                });
                Ok(())
            },
        );

        /// Evaluates all conditions and returns a decision.
        ///
        /// # Returns
        /// The result.
        methods.add_method("evaluate", |lua, this, ()| {
            let mut ai = this.inner.borrow_mut();
            if ai.actions.is_empty() {
                return Ok(LuaValue::Nil);
            }
            let mut best_idx = 0;
            let mut best_score = f64::NEG_INFINITY;
            let mut scores = Vec::with_capacity(ai.actions.len());
            for (i, action) in ai.actions.iter().enumerate() {
                let func: LuaFunction = lua.registry_value(&action.scorer)?;
                let score: f64 = func.call(())?;
                let weighted = score * action.momentum_bonus;
                scores.push(weighted);
                if weighted > best_score {
                    best_score = weighted;
                    best_idx = i;
                }
            }
            ai.last_scores = scores;
            ai.last_action = Some(best_idx);
            Ok(LuaValue::String(
                lua.create_string(&ai.actions[best_idx].name)?,
            ))
        });

        /// Returns the action count.
        ///
        /// # Returns
        /// The current action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        /// Returns the last action.
        ///
        /// # Returns
        /// The current last action.
        methods.add_method("getLastAction", |_, this, ()| {
            let ai = this.inner.borrow();
            Ok(ai.last_action.map(|i| ai.actions[i].name.clone()))
        });
    }
}

impl LuaUserData for LuaGOAPPlanner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method(
            "addAction",
            |lua, this, (name, cost, callback): (String, Option<f64>, Option<LuaFunction>)| {
                let cb_key = callback.map(|f| lua.create_registry_value(f)).transpose()?;
                this.inner.borrow_mut().actions.push(GOAPAction {
                    name,
                    cost: cost.unwrap_or(1.0),
                    callback: cb_key,
                    preconditions: HashMap::new(),
                    effects: HashMap::new(),
                });
                Ok(())
            },
        );

        methods.add_method(
            "setPrecondition",
            |_, this, (action_name, key, value): (String, String, bool)| {
                let mut planner = this.inner.borrow_mut();
                if let Some(action) = planner.actions.iter_mut().find(|a| a.name == action_name) {
                    action.preconditions.insert(key, value);
                }
                Ok(())
            },
        );

        methods.add_method(
            "setEffect",
            |_, this, (action_name, key, value): (String, String, bool)| {
                let mut planner = this.inner.borrow_mut();
                if let Some(action) = planner.actions.iter_mut().find(|a| a.name == action_name) {
                    action.effects.insert(key, value);
                }
                Ok(())
            },
        );

        methods.add_method(
            "addGoal",
            |_, this, (name, priority): (String, Option<f64>)| {
                this.inner.borrow_mut().goals.push(GOAPGoal {
                    name,
                    priority: priority.unwrap_or(1.0),
                    state: HashMap::new(),
                });
                Ok(())
            },
        );

        methods.add_method(
            "setGoalState",
            |_, this, (goal_name, key, value): (String, String, bool)| {
                let mut planner = this.inner.borrow_mut();
                if let Some(goal) = planner.goals.iter_mut().find(|g| g.name == goal_name) {
                    goal.state.insert(key, value);
                }
                Ok(())
            },
        );

        methods.add_method(
            "plan",
            |lua, this, (world_state_tbl, max_depth): (LuaTable, Option<usize>)| {
                let mut world_state = HashMap::new();
                for pair in world_state_tbl.pairs::<String, bool>() {
                    let (k, v) = pair?;
                    world_state.insert(k, v);
                }
                let planner = this.inner.borrow();
                let plan = planner.plan(&world_state, max_depth.unwrap_or(10));
                let tbl = lua.create_table()?;
                for (i, name) in plan.iter().enumerate() {
                    tbl.set(i as i64 + 1, name.as_str())?;
                }
                Ok(tbl)
            },
        );

        /// Returns the action count.
        ///
        /// # Returns
        /// The current action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        /// Returns the goal count.
        ///
        /// # Returns
        /// The current goal count.
        methods.add_method("getGoalCount", |_, this, ()| {
            Ok(this.inner.borrow().goals.len())
        });
    }
}

impl LuaUserData for LuaInfluenceMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Adds a named influence layer to this map.
        ///
        /// # Parameters
        /// - `name` — `string`: Layer identifier.
        methods.add_method("addLayer", |_, this, name: String| {
            this.inner.borrow_mut().add_layer(&name);
            Ok(())
        });

        /// Returns `true` if a layer with `name` exists in this map.
        ///
        /// # Parameters
        /// - `name` — `string`: Layer identifier to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasLayer", |_, this, name: String| {
            Ok(this.inner.borrow().has_layer(&name))
        });

        methods.add_method(
            "setInfluence",
            |_, this, (layer, x, y, value): (String, usize, usize, f32)| {
                let lx = x.saturating_sub(1);
                let ly = y.saturating_sub(1);
                this.inner.borrow_mut().set_influence(&layer, lx, ly, value);
                Ok(())
            },
        );

        methods.add_method(
            "getInfluence",
            |_, this, (layer, x, y): (String, usize, usize)| {
                let lx = x.saturating_sub(1);
                let ly = y.saturating_sub(1);
                Ok(this.inner.borrow().get_influence(&layer, lx, ly))
            },
        );

        methods.add_method(
            "stampInfluence",
            |_,
             this,
             (layer, wx, wy, radius, value, falloff): (
                String,
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
            )| {
                this.inner.borrow_mut().stamp_influence(
                    &layer,
                    wx,
                    wy,
                    radius,
                    value,
                    falloff.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        methods.add_method(
            "propagate",
            |_, this, (layer, momentum): (String, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .propagate(&layer, momentum.unwrap_or(0.5));
                Ok(())
            },
        );

        /// Decay on this InfluenceMap.
        ///
        /// # Parameters
        /// - `layer` — `string`.
        /// - `factor` — `number`.
        methods.add_method("decay", |_, this, (layer, factor): (String, f32)| {
            this.inner.borrow_mut().decay(&layer, factor);
            Ok(())
        });

        /// Clear layer on this InfluenceMap.
        ///
        /// # Parameters
        /// - `layer` — `string`.
        methods.add_method("clearLayer", |_, this, layer: String| {
            this.inner.borrow_mut().clear_layer(&layer);
            Ok(())
        });

        /// Clear all on this InfluenceMap.
        ///
        /// # Parameters
        /// - `layer` — `string`.
        methods.add_method("clearAll", |_, this, ()| {
            this.inner.borrow_mut().clear_all();
            Ok(())
        });

        /// Returns the max position.
        ///
        /// # Parameters
        /// - `layer` — `string`.
        ///
        /// # Returns
        /// The current max position.
        methods.add_method("getMaxPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().max_position(&layer))
        });

        /// Returns the min position.
        ///
        /// # Parameters
        /// - `layer` — `string`.
        /// - `wx` — `number`.
        /// - `wy` — `number`.
        /// - `ww` — `number`.
        /// - `wh` — `number`.
        ///
        /// # Returns
        /// The current min position.
        methods.add_method("getMinPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().min_position(&layer))
        });

        methods.add_method(
            "queryRect",
            |_, this, (layer, wx, wy, ww, wh): (String, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().query_rect(&layer, wx, wy, ww, wh))
            },
        );

        methods.add_method(
            "blend",
            |_,
             this,
             (layer_a, weight_a, layer_b, weight_b, dest): (
                String,
                f32,
                String,
                f32,
                String,
            )| {
                this.inner
                    .borrow_mut()
                    .blend(&layer_a, weight_a, &layer_b, weight_b, &dest);
                Ok(())
            },
        );

        /// Returns the width.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        /// Returns the height.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        /// Returns the cell size.
        ///
        /// # Returns
        /// The current cell size.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });
    }
}

impl LuaUserData for LuaSquad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the name.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        /// Adds an agent identified by `name` to this squad.
        ///
        /// # Parameters
        /// - `name` — `string`: Name of the agent to enlist.
        methods.add_method("addMember", |_, this, name: String| {
            this.inner.borrow_mut().members.push(name);
            Ok(())
        });

        /// Removes the agent identified by `name` from this squad.
        ///
        /// # Parameters
        /// - `name` — `string`: Name of the agent to remove.
        methods.add_method("removeMember", |_, this, name: String| {
            this.inner.borrow_mut().members.retain(|m| m != &name);
            Ok(())
        });

        /// Returns the number of agents currently in this squad.
        ///
        /// # Returns
        /// `integer` — member count.
        methods.add_method("getMemberCount", |_, this, ()| {
            Ok(this.inner.borrow().members.len())
        });

        /// Returns the members.
        ///
        /// # Returns
        /// The current members.
        methods.add_method("getMembers", |lua, this, ()| {
            let sq = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, m) in sq.members.iter().enumerate() {
                tbl.set(i as i64 + 1, m.as_str())?;
            }
            Ok(tbl)
        });

        /// Sets the leader.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("setLeader", |_, this, name: String| {
            this.inner.borrow_mut().leader = Some(name);
            Ok(())
        });

        /// Returns the leader.
        ///
        /// # Parameters
        /// - `ftype` — `string`.
        /// - `spacing` — `number` optional.
        ///
        /// # Returns
        /// The current leader.
        methods.add_method("getLeader", |_, this, ()| {
            Ok(this.inner.borrow().leader.clone())
        });

        methods.add_method(
            "setFormation",
            |_, this, (ftype, spacing): (String, Option<f32>)| {
                let mut sq = this.inner.borrow_mut();
                sq.formation = FormationType::parse_str(&ftype);
                if let Some(s) = spacing {
                    sq.formation_spacing = s;
                }
                Ok(())
            },
        );

        /// Returns the formation.
        ///
        /// # Returns
        /// The current formation.
        methods.add_method("getFormation", |_, this, ()| {
            Ok(this.inner.borrow().formation.as_str().to_string())
        });

        /// Returns the formation spacing.
        ///
        /// # Parameters
        /// - `member_idx` — `integer`.
        /// - `leader_x` — `number`.
        /// - `leader_y` — `number`.
        ///
        /// # Returns
        /// The current formation spacing.
        methods.add_method("getFormationSpacing", |_, this, ()| {
            Ok(this.inner.borrow().formation_spacing)
        });

        methods.add_method(
            "getFormationPosition",
            |_, this, (member_idx, leader_x, leader_y): (usize, f32, f32)| {
                let idx = member_idx.saturating_sub(1);
                Ok(this
                    .inner
                    .borrow()
                    .get_formation_position(idx, (leader_x, leader_y)))
            },
        );

        /// Returns the blackboard.
        ///
        /// # Returns
        /// The current blackboard.
        methods.add_method("getBlackboard", |_, this, ()| {
            let sq = this.inner.borrow();
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(sq.blackboard.clone())),
            })
        });
    }
}

impl LuaUserData for LuaCommandQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method(
            "enqueue",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner.borrow_mut().enqueue(Command {
                    kind,
                    callback: key,
                    target_x: tx,
                    target_y: ty,
                    priority,
                    interruptible,
                });
                Ok(())
            },
        );

        methods.add_method(
            "pushFront",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner.borrow_mut().push_front(Command {
                    kind,
                    callback: key,
                    target_x: tx,
                    target_y: ty,
                    priority,
                    interruptible,
                });
                Ok(())
            },
        );

        methods.add_method(
            "replace",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner.borrow_mut().replace(Command {
                    kind,
                    callback: key,
                    target_x: tx,
                    target_y: ty,
                    priority,
                    interruptible,
                });
                Ok(())
            },
        );

        /// Cancel current on this CommandQueue.
        ///
        /// # Returns
        /// The result.
        methods.add_method("cancelCurrent", |_, this, ()| {
            Ok(this.inner.borrow_mut().cancel_current())
        });

        /// Discards all queued commands.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Returns the count.
        ///
        /// # Returns
        /// The current count.
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.borrow().count()));

        /// Returns `true` if there are no commands queued.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.borrow().is_empty()));

        /// Returns the current type.
        ///
        /// # Returns
        /// The current current type.
        methods.add_method("getCurrentType", |_, this, ()| {
            Ok(this.inner.borrow().current_type().map(|s| s.to_string()))
        });

        /// Returns the current target.
        ///
        /// # Returns
        /// The current current target.
        methods.add_method("getCurrentTarget", |_, this, ()| {
            Ok(this.inner.borrow().current_target())
        });
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Parses optional command options table into (target_x, target_y, priority, interruptible).
fn parse_command_opts(opts: &Option<LuaTable>) -> LuaResult<(f32, f32, i32, bool)> {
    match opts {
        Some(tbl) => {
            let tx: f32 = tbl.get("targetX").unwrap_or(0.0);
            let ty: f32 = tbl.get("targetY").unwrap_or(0.0);
            let priority: i32 = tbl.get("priority").unwrap_or(0);
            let interruptible: bool = tbl.get("interruptible").unwrap_or(true);
            Ok((tx, ty, priority, interruptible))
        }
        None => Ok((0.0, 0.0, 0, true)),
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.ai.*` game AI toolkit API.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let ai = lua.create_table()?;

    // luna.ai.newWorld()
    // Creates a new AI world container that owns agents and a global blackboard.
    ai.set(
        "newWorld",
        lua.create_function(|_, ()| {
            Ok(LuaAIWorld {
                inner: Rc::new(RefCell::new(AIWorld::new())),
            })
        })?,
    )?;

    // luna.ai.newBlackboard()
    // Creates a new typed key-value blackboard for sharing AI state.
    ai.set(
        "newBlackboard",
        lua.create_function(|_, ()| {
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(Blackboard::new())),
            })
        })?,
    )?;

    // luna.ai.newStateMachine()
    // Creates a new finite state machine with guarded transitions.
    ai.set(
        "newStateMachine",
        lua.create_function(|_, ()| {
            Ok(LuaStateMachine {
                inner: Rc::new(RefCell::new(StateMachine::new())),
            })
        })?,
    )?;

    // luna.ai.newBehaviorTree()
    // Creates a new behavior tree container.
    ai.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                inner: Rc::new(RefCell::new(BehaviorTree::new())),
            })
        })?,
    )?;

    // BT node factories
    // luna.ai.newSelector()
    // Creates a BT selector node (tries children until one succeeds).
    ai.set(
        "newSelector",
        lua.create_function(|_, ()| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Selector {
                    children: Vec::new(),
                    running_idx: 0,
                })),
            })
        })?,
    )?;

    // luna.ai.newSequence()
    // Creates a BT sequence node (runs children until one fails).
    ai.set(
        "newSequence",
        lua.create_function(|_, ()| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Sequence {
                    children: Vec::new(),
                    running_idx: 0,
                })),
            })
        })?,
    )?;

    // luna.ai.newParallel(successPolicy, failurePolicy)
    // Creates a BT parallel node (ticks all children simultaneously).
    ai.set(
        "newParallel",
        lua.create_function(|_, (sp, fp): (Option<String>, Option<String>)| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Parallel {
                    children: Vec::new(),
                    success_policy: sp
                        .map(|s| ParallelPolicy::parse_str(&s))
                        .unwrap_or(ParallelPolicy::RequireOne),
                    failure_policy: fp
                        .map(|s| ParallelPolicy::parse_str(&s))
                        .unwrap_or(ParallelPolicy::RequireOne),
                })),
            })
        })?,
    )?;

    // luna.ai.newInverter()
    // Creates a BT inverter decorator (swaps success/failure).
    ai.set(
        "newInverter",
        lua.create_function(|_, ()| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Inverter {
                    child: Box::new(BTNode::Sequence {
                        children: Vec::new(),
                        running_idx: 0,
                    }),
                })),
            })
        })?,
    )?;

    // luna.ai.newRepeater(count)
    // Creates a BT repeater decorator (repeats child N times, 0=infinite).
    ai.set(
        "newRepeater",
        lua.create_function(|_, count: Option<u32>| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Repeater {
                    child: Box::new(BTNode::Sequence {
                        children: Vec::new(),
                        running_idx: 0,
                    }),
                    count: count.unwrap_or(0),
                    done: 0,
                })),
            })
        })?,
    )?;

    // luna.ai.newSucceeder()
    // Creates a BT succeeder decorator (always returns success).
    ai.set(
        "newSucceeder",
        lua.create_function(|_, ()| {
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Succeeder {
                    child: Box::new(BTNode::Sequence {
                        children: Vec::new(),
                        running_idx: 0,
                    }),
                })),
            })
        })?,
    )?;

    // luna.ai.newAction(callback)
    // Creates a BT action leaf node with a Lua callback.
    ai.set(
        "newAction",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Action { callback: key })),
            })
        })?,
    )?;

    // luna.ai.newCondition(callback)
    // Creates a BT condition leaf node with a Lua predicate.
    ai.set(
        "newCondition",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Condition { callback: key })),
            })
        })?,
    )?;

    // luna.ai.newSteeringManager()
    // Creates a new steering behavior manager for combining movement forces.
    ai.set(
        "newSteeringManager",
        lua.create_function(|_, ()| {
            Ok(LuaSteeringManager {
                inner: Rc::new(RefCell::new(SteeringManager::new())),
            })
        })?,
    )?;

    // luna.ai.newPathGrid(width, height, cellSize)
    // Creates a new A-star pathfinding grid.
    ai.set(
        "newPathGrid",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaPathGrid {
                inner: Rc::new(RefCell::new(PathGrid::new(w, h, cs))),
            })
        })?,
    )?;

    // luna.ai.newFlowField(pathGrid)
    // Creates a BFS flow field from a PathGrid.
    ai.set(
        "newFlowField",
        lua.create_function(|_, grid_ud: LuaAnyUserData| {
            let grid = grid_ud.borrow::<LuaPathGrid>()?;
            let g = grid.inner.borrow();
            let walkable: Vec<bool> = (0..g.width * g.height)
                .map(|i| g.is_walkable(i % g.width, i / g.width))
                .collect();
            Ok(LuaFlowField {
                inner: Rc::new(RefCell::new(FlowField::new(g.width, g.height, walkable))),
            })
        })?,
    )?;

    // luna.ai.newQLearner(stateCount, actionCount)
    // Creates a tabular Q-learning agent.
    ai.set(
        "newQLearner",
        lua.create_function(|_, (sc, ac): (usize, usize)| {
            Ok(LuaQLearner {
                inner: Rc::new(RefCell::new(QLearner::new(sc, ac))),
            })
        })?,
    )?;

    // luna.ai.newUtilityAI()
    // Creates a new utility AI evaluator with response-curve-scored actions.
    ai.set(
        "newUtilityAI",
        lua.create_function(|_, ()| {
            Ok(LuaUtilityAI {
                inner: Rc::new(RefCell::new(UtilityAI::new())),
            })
        })?,
    )?;

    // luna.ai.newGOAPPlanner()
    // Creates a new goal-oriented action planning solver.
    ai.set(
        "newGOAPPlanner",
        lua.create_function(|_, ()| {
            Ok(LuaGOAPPlanner {
                inner: Rc::new(RefCell::new(GOAPPlanner::new())),
            })
        })?,
    )?;

    // luna.ai.newInfluenceMap(width, height, cellSize)
    // Creates a multi-layer influence map grid.
    ai.set(
        "newInfluenceMap",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaInfluenceMap {
                inner: Rc::new(RefCell::new(InfluenceMap::new(w, h, cs))),
            })
        })?,
    )?;

    // luna.ai.newSquad(name)
    // Creates a named squad for group formation positioning.
    ai.set(
        "newSquad",
        lua.create_function(|_, name: String| {
            Ok(LuaSquad {
                inner: Rc::new(RefCell::new(Squad::new(&name))),
            })
        })?,
    )?;

    // luna.ai.newCommandQueue()
    // Creates an RTS-style command queue for sequencing agent orders.
    ai.set(
        "newCommandQueue",
        lua.create_function(|_, ()| {
            Ok(LuaCommandQueue {
                inner: Rc::new(RefCell::new(CommandQueue::new())),
            })
        })?,
    )?;

    /// Ai on this CommandQueue.
    ///
    /// # Returns
    /// The result.
    luna.set("ai", ai)?;
    Ok(())
}
