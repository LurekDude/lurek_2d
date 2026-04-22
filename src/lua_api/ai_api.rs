//! `lurek.ai` â€” Game AI toolkit: worlds, agents, FSM, behavior trees, steering, Q-learning, utility AI, GOAP, squads, and command queues.

use super::SharedState;
use crate::lua_api::callback_registry::CallbackRegistry;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::ai::{
    AIDirector,
    AILod,
    AIWorld,
    Activation,
    BTNode,
    Bandit,
    BanditStrategy,
    BehaviorTree,
    Blackboard,
    CommandQueue,
    Consideration,
    ContextSteering,
    DecisionModel,
    Emotion,
    EmotionModel,
    FormationType,
    GOAPAction,
    GOAPGoal,
    GOAPPlanner,
    GeneticAlgorithm,
    HTNDomain,
    HTNMethod,
    HTNPlanner,
    MCTSConfig,
    MCTSEngine,
    Need,
    NeedSystem,
    NeuralNet,
    Neuroevolution,
    ORCAAgent,
    ORCASolver,
    ParallelPolicy,
    QLearner,
    ResponseCurve,
    Squad,
    SteeringManager,
    StimulusWorld,
    StrategyAI,
    // New subsystems
    TraitProfile,
    UAAction,
    UtilityAI,
    WorldState,
};
use crate::pathfind::InfluenceMap;

// -------------------------------------------------------------------------------
// LuaAIWorld UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AIWorld`].
#[derive(Clone)]
struct LuaAIWorld {
    inner: Rc<RefCell<AIWorld>>,
    /// Registry for custom-model Lua callbacks; shared with all agents that
    /// have been given a `setCustomModel` callback.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaAIWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAgent --
        /// Registers a new named agent and returns its handle.
        /// @param name : string
        /// @return Agent
        methods.add_method("addAgent", |_, this, name: String| {
            let mut w = this.inner.borrow_mut();
            w.add_agent(&name).map_err(LuaError::RuntimeError)?;
            Ok(LuaAgent {
                world: this.inner.clone(),
                name,
                callbacks: this.custom_callbacks.clone(),
            })
        });

        // -- getAgent --
        /// Returns the agent handle for the given name, or nil.
        /// @param name : string
        /// @return nil
        /// Agent?
        methods.add_method("getAgent", |_, this, name: String| {
            let w = this.inner.borrow();
            if w.get_agent_index(&name).is_some() {
                Ok(Some(LuaAgent {
                    world: this.inner.clone(),
                    name,
                    callbacks: this.custom_callbacks.clone(),
                }))
            } else {
                Ok(None)
            }
        });

        // -- removeAgent --
        /// Removes an agent by its userdata handle.
        /// @param agent : Agent
        /// @return nil
        methods.add_method("removeAgent", |_, this, agent: LuaAnyUserData| {
            let a = agent.borrow::<LuaAgent>()?;
            this.inner.borrow_mut().remove_agent(&a.name);
            Ok(())
        });

        // -- getAgentCount --
        /// Returns the number of registered agents.
        /// @return integer
        methods.add_method("getAgentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count())
        });

        // -- getGlobalBlackboard --
        /// Returns a snapshot of the world-level blackboard.
        /// @return Blackboard
        methods.add_method("getGlobalBlackboard", |_, this, ()| {
            let w = this.inner.borrow();
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(w.global_blackboard().clone())),
            })
        });

        // -- update --
        /// Advances all agents by dt seconds, then invokes any custom-model callbacks.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |lua, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            // Collect names + callback IDs for all Custom-model agents.
            let custom_agents: Vec<(String, u32)> = {
                let w = this.inner.borrow();
                w.agents
                    .iter()
                    .filter_map(|a| {
                        if let crate::ai::DecisionModel::Custom { callback_id } = a.decision_model {
                            Some((a.name.clone(), callback_id))
                        } else {
                            None
                        }
                    })
                    .collect()
            };
            for (name, callback_id) in custom_agents {
                let lua_agent = LuaAgent {
                    world: this.inner.clone(),
                    name: name.clone(),
                    callbacks: this.custom_callbacks.clone(),
                };
                let lua_bb = {
                    let w = this.inner.borrow();
                    match w.get_agent_index(&name) {
                        Some(idx) => LuaBlackboard {
                            inner: Rc::new(RefCell::new(w.agents[idx].blackboard.clone())),
                        },
                        None => continue,
                    }
                };
                // Look up the Lua function (drops the borrow before calling).
                let func_opt: Option<LuaFunction> = {
                    let cb = this.custom_callbacks.borrow();
                    cb.get(callback_id)
                        .and_then(|key| lua.registry_value(key).ok())
                };
                if let Some(func) = func_opt {
                    if let Err(e) = func.call::<_, ()>((lua_agent, lua_bb, dt)) {
                        eprintln!("[lurek.ai] custom model callback error for '{name}': {e}");
                    }
                }
            }
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("AIWorld"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIWorld" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAgent UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper for an agent accessed by name through the owning world.
#[derive(Clone)]
struct LuaAgent {
    world: Rc<RefCell<AIWorld>>,
    name: String,
    /// Shared reference to the owning `LuaAIWorld`'s callback registry.
    callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the agent's registered name.
        /// @return string
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        // -- setPosition --
        /// Sets the agent's world-space position.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].position = (x, y);
            }
            Ok(())
        });

        // -- getPosition --
        /// Returns the agent's current position.
        /// @return number, number
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].position)
            } else {
                Ok((0.0, 0.0))
            }
        });

        // -- setVelocity --
        /// Sets the agent's velocity vector.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method("setVelocity", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].velocity = (x, y);
            }
            Ok(())
        });

        // -- getVelocity --
        /// Returns the agent's current velocity.
        /// @return number, number
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].velocity)
            } else {
                Ok((0.0, 0.0))
            }
        });

        // -- setMaxSpeed --
        /// Sets the maximum speed cap.
        /// @param v : number
        /// @return nil
        methods.add_method("setMaxSpeed", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_speed = v;
            }
            Ok(())
        });

        // -- getMaxSpeed --
        /// Returns the maximum speed cap.
        /// @return number
        methods.add_method("getMaxSpeed", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_speed)
            } else {
                Ok(100.0)
            }
        });

        // -- setMaxForce --
        /// Sets the maximum steering force cap.
        /// @param v : number
        /// @return nil
        methods.add_method("setMaxForce", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_force = v;
            }
            Ok(())
        });

        // -- getMaxForce --
        /// Returns the maximum steering force cap.
        /// @return number
        methods.add_method("getMaxForce", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_force)
            } else {
                Ok(200.0)
            }
        });

        // -- setPriority --
        /// Sets the scheduling priority (higher = earlier).
        /// @param p : integer
        /// @return nil
        methods.add_method("setPriority", |_, this, p: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].priority = p;
            }
            Ok(())
        });

        // -- getPriority --
        /// Returns the agent's scheduling priority.
        /// @return integer
        methods.add_method("getPriority", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].priority)
            } else {
                Ok(0)
            }
        });

        // -- setDecisionModel --
        /// Sets the active decision model.
        /// @param model : string
        /// @return nil
        methods.add_method("setDecisionModel", |_, this, model: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                if let Some(dm) = DecisionModel::parse_str(&model) {
                    w.agents[idx].decision_model = dm;
                }
            }
            Ok(())
        });

        // -- getDecisionModel --
        /// Returns the name of the current decision model.
        /// @return string
        methods.add_method("getDecisionModel", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].decision_model.as_str().to_string())
            } else {
                Ok("fsm".to_string())
            }
        });

        // -- setCustomModel --
        /// Installs a Lua-driven decision model on this agent.
        /// The callback is invoked by `world:update(dt)` each frame.
        /// @param callback : function(agent, blackboard, dt)
        /// @return nil
        methods.add_method("setCustomModel", |lua, this, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            let callback_id = this.callbacks.borrow_mut().register(key);
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].decision_model = crate::ai::DecisionModel::Custom { callback_id };
            }
            Ok(())
        });

        // -- addTag --
        /// Adds a tag to this agent.
        /// @param tag : string
        /// @return nil
        methods.add_method("addTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.insert(tag);
            }
            Ok(())
        });

        // -- removeTag --
        /// Removes a tag from this agent.
        /// @param tag : string
        /// @return nil
        methods.add_method("removeTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.remove(&tag);
            }
            Ok(())
        });

        // -- hasTag --
        /// Returns true if the agent has the given tag.
        /// @param tag : string
        /// @return boolean
        methods.add_method("hasTag", |_, this, tag: String| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].tags.contains(&tag))
            } else {
                Ok(false)
            }
        });

        // -- getBlackboard --
        /// Returns the agent's local blackboard.
        /// @return Blackboard
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Agent"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Agent" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBlackboard UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Blackboard`].
#[derive(Clone)]
struct LuaBlackboard {
    inner: Rc<RefCell<Blackboard>>,
}

impl LuaUserData for LuaBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setNumber --
        /// Stores a number under the given key.
        /// @param key : string
        /// @param value : number
        /// @return nil
        methods.add_method("setNumber", |_, this, (key, value): (String, f64)| {
            this.inner.borrow_mut().set_number(&key, value);
            Ok(())
        });

        // -- getNumber --
        /// Returns the number for the given key, or default.
        /// @param key : string
        /// @param default : number?
        /// @return number
        methods.add_method(
            "getNumber",
            |_, this, (key, default): (String, Option<f64>)| {
                Ok(this.inner.borrow().get_number(&key, default.unwrap_or(0.0)))
            },
        );

        // -- setBool --
        /// Stores a boolean under the given key.
        /// @param key : string
        /// @param value : boolean
        /// @return nil
        methods.add_method("setBool", |_, this, (key, value): (String, bool)| {
            this.inner.borrow_mut().set_bool(&key, value);
            Ok(())
        });

        // -- getBool --
        /// Returns the boolean for the given key, or default.
        /// @param key : string
        /// @param default : boolean?
        /// @return boolean
        methods.add_method(
            "getBool",
            |_, this, (key, default): (String, Option<bool>)| {
                Ok(this.inner.borrow().get_bool(&key, default.unwrap_or(false)))
            },
        );

        // -- setString --
        /// Stores a string under the given key.
        /// @param key : string
        /// @param value : string
        /// @return nil
        methods.add_method("setString", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().set_string(&key, &value);
            Ok(())
        });

        // -- getString --
        /// Returns the string for the given key, or default.
        /// @param key : string
        /// @param default : string?
        /// @return string
        methods.add_method(
            "getString",
            |_, this, (key, default): (String, Option<String>)| {
                let def = default.unwrap_or_default();
                Ok(this.inner.borrow().get_string(&key, &def))
            },
        );

        // -- has --
        /// Returns true if a value exists under the key.
        /// @param key : string
        /// @return boolean
        methods.add_method("has", |_, this, key: String| {
            Ok(this.inner.borrow().has(&key))
        });

        // -- remove --
        /// Removes the entry at key.
        /// @param key : string
        /// @return nil
        methods.add_method("remove", |_, this, key: String| {
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });

        // -- clear --
        /// Removes all local entries.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- getKeys --
        /// Returns all local keys as a table.
        /// @return table
        methods.add_method("getKeys", |lua, this, ()| {
            let keys = this.inner.borrow().keys();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i as i64 + 1, k.as_str())?;
            }
            Ok(tbl)
        });

        // -- getSize --
        /// Returns the number of local entries.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().size()));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Blackboard"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Blackboard" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaStateMachine UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`StateMachine`].
#[derive(Clone)]
struct LuaStateMachine {
    inner: Rc<RefCell<crate::ai::StateMachine>>,
}

impl LuaUserData for LuaStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addState --
        /// Registers a named state with optional lifecycle callbacks.
        /// @param name : string
        /// @param opts : table
        /// @return nil
        methods.add_method("addState", |lua, this, (name, opts): (String, LuaTable)| {
            let on_enter: Option<LuaFunction> = opts.get("onEnter").ok();
            let on_update: Option<LuaFunction> = opts.get("onUpdate").ok();
            let on_exit: Option<LuaFunction> = opts.get("onExit").ok();
            let enter_key = on_enter.map(|f| lua.create_registry_value(f)).transpose()?;
            let update_key = on_update
                .map(|f| lua.create_registry_value(f))
                .transpose()?;
            let exit_key = on_exit.map(|f| lua.create_registry_value(f)).transpose()?;
            this.inner
                .borrow_mut()
                .add_state_raw(name, enter_key, update_key, exit_key);
            Ok(())
        });

        // -- addTransition --
        /// Adds a guarded transition between states.
        /// @param from : string
        /// @param to : string
        /// @param guard : function?
        /// @param priority : integer?
        /// @return nil
        methods.add_method(
            "addTransition",
            |lua, this, (from, to, guard, priority): (String, String, Option<LuaFunction>, Option<i32>)| {
                let guard_key = guard.map(|f| lua.create_registry_value(f)).transpose()?;
                this.inner.borrow_mut().add_transition_raw(from, to, priority.unwrap_or(0), guard_key);
                Ok(())
            },
        );

        // -- setInitialState --
        /// Sets the FSM's initial state; must be called before the first update.
        /// @param name : string
        /// @return nil
        methods.add_method("setInitialState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.initial_state = Some(name.clone());
            if fsm.current_state.is_none() {
                fsm.current_state = Some(name);
            }
            Ok(())
        });

        // -- getCurrentState --
        /// Returns the current state name, or nil.
        /// @return string?
        methods.add_method("getCurrentState", |_, this, ()| {
            Ok(this.inner.borrow().current_state().map(|s| s.to_string()))
        });

        // -- forceState --
        /// Forces a transition to the named state.
        /// @param name : string
        /// @return nil
        methods.add_method("forceState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.current_state = Some(name);
            fsm.time_in_state = 0.0;
            Ok(())
        });

        // -- getTimeInState --
        /// Returns seconds spent in the current state.
        /// @return number
        methods.add_method("getTimeInState", |_, this, ()| {
            Ok(this.inner.borrow().time_in_state())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("StateMachine"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "StateMachine" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBehaviorTree UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`BehaviorTree`].
#[derive(Clone)]
struct LuaBehaviorTree {
    inner: Rc<RefCell<BehaviorTree>>,
}

impl LuaUserData for LuaBehaviorTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setRoot --
        /// Sets the root node of this behavior tree.
        /// @param node : BTNode
        /// @return nil
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

        // -- getLastStatus --
        /// Returns the status from the last tick.
        /// @return string
        methods.add_method("getLastStatus", |_, this, ()| {
            Ok(this.inner.borrow().last_status.as_str().to_string())
        });

        // -- getDebugState --
        /// Returns a diagnostic snapshot of this behavior tree.
        /// Fields: node_count (integer), last_status (string).
        /// @return table
        methods.add_method("getDebugState", |lua, this, ()| {
            let dbg = this.inner.borrow().debug_state();
            let t = lua.create_table()?;
            t.set("node_count", dbg.node_count as u32)?;
            t.set("last_status", dbg.last_status)?;
            Ok(t)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("BehaviorTree"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BehaviorTree" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBTNode UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`BTNode`].
#[derive(Clone)]
struct LuaBTNode {
    inner: Rc<RefCell<BTNode>>,
}

impl LuaUserData for LuaBTNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addChild --
        /// Adds a child node (Selector, Sequence, or Parallel only).
        /// @param child : BTNode
        /// @return nil
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

        // -- getChildCount --
        /// Returns the number of direct children.
        /// @return integer
        methods.add_method("getChildCount", |_, this, ()| {
            Ok(this.inner.borrow().child_count())
        });

        // -- reset --
        /// Resets all running-child memos and repeater counters.
        /// @return nil
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        // -- setChild --
        /// Sets the single child of a decorator node.
        /// @param child : BTNode
        /// @return nil
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

        // -- setCount --
        /// Sets the repeat count for a Repeater node.
        /// @param n : integer
        /// @return nil
        methods.add_method("setCount", |_, this, n: u32| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Repeater { count, .. } = &mut *node {
                *count = n;
            }
            Ok(())
        });

        // -- getCount --
        /// Returns the repeat count, or 0 if not a Repeater.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| {
            let node = this.inner.borrow();
            if let BTNode::Repeater { count, .. } = &*node {
                Ok(*count)
            } else {
                Ok(0)
            }
        });

        // -- setSuccessPolicy --
        /// Sets the success policy for a Parallel node.
        /// @param policy : string
        /// @return nil
        methods.add_method("setSuccessPolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { success_policy, .. } = &mut *node {
                *success_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        // -- setFailurePolicy --
        /// Sets the failure policy for a Parallel node.
        /// @param policy : string
        /// @return nil
        methods.add_method("setFailurePolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { failure_policy, .. } = &mut *node {
                *failure_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        // -- getNodeType --
        /// Returns the node type as a string.
        /// @return string
        methods.add_method("getNodeType", |_, this, ()| {
            let node = this.inner.borrow();
            let name = match &*node {
                BTNode::Selector { .. } => "selector",
                BTNode::Sequence { .. } => "sequence",
                BTNode::Parallel { .. } => "parallel",
                BTNode::Inverter { .. } => "inverter",
                BTNode::Repeater { .. } => "repeater",
                BTNode::Succeeder { .. } => "succeeder",
                BTNode::Guard { .. } => "guard",
                BTNode::Action { .. } => "action",
                BTNode::Condition { .. } => "condition",
            };
            Ok(name.to_string())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("BTNode"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BTNode" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaSteeringManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SteeringManager`].
#[derive(Clone)]
struct LuaSteeringManager {
    inner: Rc<RefCell<SteeringManager>>,
    /// Registry for custom steering behavior Lua callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaSteeringManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeek --
        /// Adds a Seek behavior toward the target.
        /// @param tx : number
        /// @param ty : number
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addSeek",
            |_, this, (tx, ty, weight): (f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_seek(tx, ty, weight.unwrap_or(1.0));
                Ok(())
            },
        );

        // -- addFlee --
        /// Adds a Flee behavior away from the target.
        /// @param tx : number
        /// @param ty : number
        /// @param panicDist : number?
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addFlee",
            |_, this, (tx, ty, panic_dist, weight): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner.borrow_mut().add_flee(
                    tx,
                    ty,
                    panic_dist.unwrap_or(200.0),
                    weight.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        // -- addArrive --
        /// Adds an Arrive behavior with deceleration.
        /// @param tx : number
        /// @param ty : number
        /// @param slowingRadius : number?
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addArrive",
            |_, this, (tx, ty, slowing, weight): (f32, f32, Option<f32>, Option<f32>)| {
                this.inner.borrow_mut().add_arrive(
                    tx,
                    ty,
                    slowing.unwrap_or(50.0),
                    weight.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        // -- addWander --
        /// Adds a Wander behavior for random meandering.
        /// @param radius : number?
        /// @param dist : number?
        /// @param jitter : number?
        /// @param weight : number?
        /// @return nil
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
                this.inner.borrow_mut().add_wander(
                    radius.unwrap_or(20.0),
                    dist.unwrap_or(40.0),
                    jitter.unwrap_or(5.0),
                    weight.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        // -- addPursue --
        /// Adds a Pursue behavior targeting a named agent.
        /// @param targetName : string?
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addPursue",
            |_, this, (target_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_pursue(target_name, weight.unwrap_or(1.0));
                Ok(())
            },
        );

        // -- addEvade --
        /// Adds an Evade behavior fleeing from a named agent.
        /// @param threatName : string?
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addEvade",
            |_, this, (threat_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_evade(threat_name, weight.unwrap_or(1.0));
                Ok(())
            },
        );

        // -- addFlock --
        /// Adds a Flock behavior for group movement.
        /// @param neighborRadius : number?
        /// @param sepWeight : number?
        /// @param alignWeight : number?
        /// @param cohWeight : number?
        /// @param weight : number?
        /// @return nil
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
                this.inner.borrow_mut().add_flock(
                    neighbor_radius.unwrap_or(100.0),
                    sep_w.unwrap_or(1.5),
                    align_w.unwrap_or(1.0),
                    coh_w.unwrap_or(1.0),
                    weight.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        // -- getBehaviorCount --
        /// Returns the number of active behaviors.
        /// @return integer
        methods.add_method("getBehaviorCount", |_, this, ()| {
            Ok(this.inner.borrow().behaviors.len())
        });

        // -- setCombineMode --
        /// Sets the force combination mode.
        /// @param mode : string
        /// @return nil
        methods.add_method("setCombineMode", |_, this, mode: String| {
            this.inner.borrow_mut().set_combine_mode_str(&mode);
            Ok(())
        });

        // -- getCombineMode --
        /// Returns the current combination mode.
        /// @return string
        methods.add_method("getCombineMode", |_, this, ()| {
            Ok(this.inner.borrow().combine_mode.as_str().to_string())
        });

        // -- getLastSteering --
        /// Returns the last computed steering force.
        /// @return number, number
        methods.add_method("getLastSteering", |_, this, ()| {
            Ok(this.inner.borrow().last_force())
        });

        // -- calculate --
        /// Computes the combined steering force for the given agent state.
        /// @param px : number
        /// @param py : number
        /// @param vx : number
        /// @param vy : number
        /// @param maxSpeed : number
        /// @param maxForce : number
        /// @param dt : number
        /// @return number, number
        methods.add_method(
            "calculate",
            |_, this, (px, py, vx, vy, max_speed, max_force, dt): (f32, f32, f32, f32, f32, f32, f32)| {
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("SteeringManager"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SteeringManager" || name == "Object")
        });

        // -- setSpatialHashCellSize --
        /// Sets the cell size used by the spatial-hash neighbourhood search.
        /// Smaller cells yield finer buckets; larger cells cover more ground per lookup.
        /// @param size : number
        /// @return nil
        methods.add_method_mut("setSpatialHashCellSize", |_, this, size: f32| {
            this.inner.borrow_mut().set_cell_size(size);
            Ok(())
        });

        // -- enableSpatialHash --
        /// Enables or disables spatial-hash bucketing for neighbourhood queries.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("enableSpatialHash", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_use_spatial_hash(enabled);
            Ok(())
        });

        // -- addCustomBehavior --
        /// Registers a Lua callback as a custom steering behavior.
        /// The callback is invoked by `applyCustomSteering(agent, dt)` each frame.
        /// @param callback : function(agent, dt) -> dx, dy
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addCustomBehavior",
            |lua, this, (func, weight): (LuaFunction, Option<f32>)| {
                let key = lua.create_registry_value(func)?;
                let callback_id = this.custom_callbacks.borrow_mut().register(key);
                this.inner
                    .borrow_mut()
                    .behaviors
                    .push(crate::ai::SteeringBehaviorType::Custom {
                        callback_id,
                        base: crate::ai::SteeringBase {
                            weight: weight.unwrap_or(1.0),
                            enabled: true,
                        },
                    });
                Ok(())
            },
        );

        // -- applyCustomSteering --
        /// Invokes all registered custom steering callbacks and returns the combined force.
        /// Call this each frame after `world:update(dt)` and apply the result to agent velocity.
        /// @param agent : Agent
        /// @param dt : number
        /// @return number, number  (fx, fy)
        methods.add_method(
            "applyCustomSteering",
            |lua, this, (agent_ud, dt): (LuaAnyUserData, f32)| {
                let behaviors: Vec<(u32, f32)> = {
                    let sm = this.inner.borrow();
                    sm.behaviors
                        .iter()
                        .filter_map(|b| {
                            if let crate::ai::SteeringBehaviorType::Custom { callback_id, base } = b
                            {
                                if base.enabled {
                                    Some((*callback_id, base.weight))
                                } else {
                                    None
                                }
                            } else {
                                None
                            }
                        })
                        .collect()
                };
                let mut force = (0.0f32, 0.0f32);
                for (callback_id, weight) in behaviors {
                    let func_opt: Option<LuaFunction> = {
                        let cb = this.custom_callbacks.borrow();
                        cb.get(callback_id)
                            .and_then(|key| lua.registry_value(key).ok())
                    };
                    if let Some(func) = func_opt {
                        match func.call::<_, (f32, f32)>((agent_ud.clone(), dt)) {
                            Ok((fx, fy)) => {
                                force.0 += fx * weight;
                                force.1 += fy * weight;
                            }
                            Err(e) => {
                                eprintln!("[lurek.ai] custom steering callback error: {e}");
                            }
                        }
                    }
                }
                Ok(force)
            },
        );
    }
}

// -------------------------------------------------------------------------------
// LuaQLearner UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`QLearner`].
#[derive(Clone)]
struct LuaQLearner {
    inner: Rc<RefCell<QLearner>>,
}

impl LuaUserData for LuaQLearner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- chooseAction --
        /// Selects an action using epsilon-greedy policy (1-based).
        /// @param state : integer
        /// @return integer
        methods.add_method("chooseAction", |_, this, state: usize| {
            Ok(this.inner.borrow().choose_action(state.saturating_sub(1)) + 1)
        });

        // -- bestAction --
        /// Returns the greedy-best action for the state (1-based).
        /// @param state : integer
        /// @return integer
        methods.add_method("bestAction", |_, this, state: usize| {
            Ok(this.inner.borrow().best_action(state.saturating_sub(1)) + 1)
        });

        // -- learn --
        /// Performs one Bellman Q-learning update (1-based indices).
        /// @param state : integer
        /// @param action : integer
        /// @param reward : number
        /// @param nextState : integer
        /// @return nil
        methods.add_method(
            "learn",
            |_, this, (state, action, reward, next_state): (usize, usize, f64, usize)| {
                this.inner.borrow_mut().learn(
                    state.saturating_sub(1),
                    action.saturating_sub(1),
                    reward,
                    next_state.saturating_sub(1),
                );
                Ok(())
            },
        );

        // -- getQValue --
        /// Returns the Q-value for a state-action pair (1-based).
        /// @param state : integer
        /// @param action : integer
        /// @return number
        methods.add_method("getQValue", |_, this, (state, action): (usize, usize)| {
            Ok(this
                .inner
                .borrow()
                .get_q(state.saturating_sub(1), action.saturating_sub(1)))
        });

        // -- setQValue --
        /// Overwrites the Q-value for a state-action pair (1-based).
        /// @param state : integer
        /// @param action : integer
        /// @param value : number
        /// @return nil
        methods.add_method(
            "setQValue",
            |_, this, (state, action, value): (usize, usize, f64)| {
                this.inner.borrow_mut().set_q(
                    state.saturating_sub(1),
                    action.saturating_sub(1),
                    value,
                );
                Ok(())
            },
        );

        // -- endEpisode --
        /// Ends the current episode, applying epsilon decay.
        /// @return nil
        methods.add_method("endEpisode", |_, this, ()| {
            this.inner.borrow_mut().end_episode();
            Ok(())
        });

        // -- getEpisodeCount --
        /// Returns the number of completed episodes.
        /// @return integer
        methods.add_method("getEpisodeCount", |_, this, ()| {
            Ok(this.inner.borrow().episode_count)
        });

        // -- getStateCount --
        /// Returns the number of discrete states.
        /// @return integer
        methods.add_method("getStateCount", |_, this, ()| {
            Ok(this.inner.borrow().state_count)
        });

        // -- getActionCount --
        /// Returns the number of discrete actions.
        /// @return integer
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().action_count)
        });

        // -- setLearningRate --
        /// Sets the learning rate alpha.
        /// @param v : number
        /// @return nil
        methods.add_method("setLearningRate", |_, this, v: f64| {
            this.inner.borrow_mut().alpha = v;
            Ok(())
        });

        // -- getLearningRate --
        /// Returns the current learning rate.
        /// @return number
        methods.add_method("getLearningRate", |_, this, ()| {
            Ok(this.inner.borrow().alpha)
        });

        // -- setDiscountFactor --
        /// Sets the discount factor gamma.
        /// @param v : number
        /// @return nil
        methods.add_method("setDiscountFactor", |_, this, v: f64| {
            this.inner.borrow_mut().gamma = v;
            Ok(())
        });

        // -- getDiscountFactor --
        /// Returns the current discount factor.
        /// @return number
        methods.add_method("getDiscountFactor", |_, this, ()| {
            Ok(this.inner.borrow().gamma)
        });

        // -- setExplorationRate --
        /// Sets the exploration rate epsilon.
        /// @param v : number
        /// @return nil
        methods.add_method("setExplorationRate", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon = v;
            Ok(())
        });

        // -- getExplorationRate --
        /// Returns the current exploration rate.
        /// @return number
        methods.add_method("getExplorationRate", |_, this, ()| {
            Ok(this.inner.borrow().epsilon)
        });

        // -- setExplorationDecay --
        /// Sets the epsilon decay multiplier.
        /// @param v : number
        /// @return nil
        methods.add_method("setExplorationDecay", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon_decay = v;
            Ok(())
        });

        // -- getExplorationDecay --
        /// Returns the epsilon decay multiplier.
        /// @return number
        methods.add_method("getExplorationDecay", |_, this, ()| {
            Ok(this.inner.borrow().epsilon_decay)
        });

        // -- serialize --
        /// Serializes the Q-table to a JSON string.
        /// @return string
        methods.add_method("serialize", |_, this, ()| {
            Ok(this.inner.borrow().serialize())
        });

        // -- deserialize --
        /// Restores the Q-table from a JSON string.
        /// @param json : string
        /// @return nil
        methods.add_method("deserialize", |_, this, json: String| {
            this.inner
                .borrow_mut()
                .deserialize(&json)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("QLearner"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "QLearner" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaUtilityAI UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`UtilityAI`].
#[derive(Clone)]
struct LuaUtilityAI {
    inner: Rc<RefCell<UtilityAI>>,
    /// Registry for custom response-curve Lua callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaUtilityAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAction --
        /// Adds a scored action with optional momentum weight.
        /// @param name : string
        /// @param scorer : function
        /// @param weight : number?
        /// @return nil
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

        // -- evaluate --
        /// Evaluates all actions and returns the best action name, or nil.
        /// @return string?
        methods.add_method("evaluate", |lua, this, ()| {
            match this.inner.borrow_mut().evaluate(lua)? {
                Some(name) => Ok(LuaValue::String(lua.create_string(&name)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getActionCount --
        /// Returns the number of registered actions.
        /// @return integer
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        // -- getLastAction --
        /// Returns the name of the last chosen action, or nil.
        /// @return string?
        methods.add_method("getLastAction", |_, this, ()| {
            let ai = this.inner.borrow();
            Ok(ai.last_action.map(|i| ai.actions[i].name.clone()))
        });

        // -- addConsideration --
        /// Adds a multi-axis consideration to a named action.
        /// The curve argument may be a string ("linear", "quadratic", etc.) or a
        /// Lua function `fn(x) -> y` for a fully custom curve.
        /// @param actionName : string
        /// @param name : string
        /// @param scorerFn : function()  -- returns the raw consideration value
        /// @param curve : string | function(x) -> y
        /// @param p1 : number?
        /// @param p2 : number?
        /// @param p3 : number?
        /// @param weight : number?
        /// @return nil
        methods.add_method(
            "addConsideration",
            |lua,
             this,
             (action_name, name, scorer_fn, curve_arg, p1, p2, p3, weight): (
                String,
                String,
                LuaFunction,
                LuaValue,
                Option<f64>,
                Option<f64>,
                Option<f64>,
                Option<f64>,
            )| {
                let scorer_key = lua.create_registry_value(scorer_fn)?;
                match curve_arg {
                    LuaValue::Function(f) => {
                        // Custom Lua curve: register and push a Consideration directly
                        // to avoid losing the Custom variant through parse_str round-trip.
                        let curve_key = lua.create_registry_value(f)?;
                        let callback_id = this.custom_callbacks.borrow_mut().register(curve_key);
                        let curve = ResponseCurve::Custom { callback_id };
                        let mut ua = this.inner.borrow_mut();
                        if let Some(action) = ua.actions.iter_mut().find(|a| a.name == action_name)
                        {
                            action.considerations.push(Consideration {
                                name,
                                callback: scorer_key,
                                curve,
                                p1: p1.unwrap_or(1.0),
                                p2: p2.unwrap_or(0.0),
                                p3: p3.unwrap_or(0.0),
                                weight: weight.unwrap_or(1.0),
                            });
                        }
                    }
                    LuaValue::String(s) => {
                        let curve_str = s.to_str().unwrap_or("linear").to_string();
                        this.inner.borrow_mut().add_consideration(
                            &action_name,
                            name,
                            scorer_key,
                            &curve_str,
                            p1.unwrap_or(1.0),
                            p2.unwrap_or(0.0),
                            p3.unwrap_or(0.0),
                            weight.unwrap_or(1.0),
                        );
                    }
                    _ => {
                        this.inner.borrow_mut().add_consideration(
                            &action_name,
                            name,
                            scorer_key,
                            "linear",
                            p1.unwrap_or(1.0),
                            p2.unwrap_or(0.0),
                            p3.unwrap_or(0.0),
                            weight.unwrap_or(1.0),
                        );
                    }
                }
                Ok(())
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("UtilityAI"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "UtilityAI" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaGOAPPlanner UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`GOAPPlanner`].
#[derive(Clone)]
struct LuaGOAPPlanner {
    inner: Rc<RefCell<GOAPPlanner>>,
}

impl LuaUserData for LuaGOAPPlanner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAction --
        /// Adds a GOAP action with optional cost and callback.
        /// @param name : string
        /// @param cost : number?
        /// @param callback : function?
        /// @return nil
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

        // -- setPrecondition --
        /// Sets a boolean precondition on an action.
        /// @param actionName : string
        /// @param key : string
        /// @param value : boolean
        /// @return nil
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

        // -- setEffect --
        /// Sets a boolean effect on an action.
        /// @param actionName : string
        /// @param key : string
        /// @param value : boolean
        /// @return nil
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

        // -- addGoal --
        /// Adds a planning goal with optional priority.
        /// @param name : string
        /// @param priority : number?
        /// @return nil
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

        // -- setGoalState --
        /// Sets a boolean condition on a goal.
        /// @param goalName : string
        /// @param key : string
        /// @param value : boolean
        /// @return nil
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

        // -- plan --
        /// Runs A* planning and returns an action sequence table.
        /// @param worldState : table
        /// @param maxDepth : integer?
        /// @return table
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

        // -- getActionCount --
        /// Returns the number of registered actions.
        /// @return integer
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        // -- getGoalCount --
        /// Returns the number of registered goals.
        /// @return integer
        methods.add_method("getGoalCount", |_, this, ()| {
            Ok(this.inner.borrow().goals.len())
        });

        // -- getMaxIterations --
        /// Returns the maximum A* planning iterations.
        /// @return integer
        methods.add_method("getMaxIterations", |_, this, ()| {
            Ok(this.inner.borrow().get_max_iterations() as u64)
        });

        // -- setMaxIterations --
        /// Sets the maximum A* planning iterations (0 = unlimited).
        /// @param n : integer
        /// @return nil
        methods.add_method_mut("setMaxIterations", |_, this, n: u64| {
            this.inner.borrow_mut().set_max_iterations(n as usize);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("GOAPPlanner"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GOAPPlanner" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaInfluenceMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`InfluenceMap`].
#[derive(Clone)]
struct LuaInfluenceMap {
    inner: Rc<RefCell<InfluenceMap>>,
}

impl LuaUserData for LuaInfluenceMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds a named influence layer.
        /// @param name : string
        /// @return nil
        methods.add_method("addLayer", |_, this, name: String| {
            this.inner.borrow_mut().add_layer(&name);
            Ok(())
        });

        // -- hasLayer --
        /// Returns true if the named layer exists.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasLayer", |_, this, name: String| {
            Ok(this.inner.borrow().has_layer(&name))
        });

        // -- setInfluence --
        /// Sets the influence value at a cell (1-based).
        /// @param layer : string
        /// @param x : integer
        /// @param y : integer
        /// @param value : number
        /// @return nil
        methods.add_method(
            "setInfluence",
            |_, this, (layer, x, y, value): (String, usize, usize, f32)| {
                this.inner.borrow_mut().set_influence(
                    &layer,
                    x.saturating_sub(1),
                    y.saturating_sub(1),
                    value,
                );
                Ok(())
            },
        );

        // -- getInfluence --
        /// Returns the influence value at a cell (1-based).
        /// @param layer : string
        /// @param x : integer
        /// @param y : integer
        /// @return number
        methods.add_method(
            "getInfluence",
            |_, this, (layer, x, y): (String, usize, usize)| {
                Ok(this.inner.borrow().get_influence(
                    &layer,
                    x.saturating_sub(1),
                    y.saturating_sub(1),
                ))
            },
        );

        // -- stampInfluence --
        /// Stamps influence in a radial area.
        /// @param layer : string
        /// @param wx : number
        /// @param wy : number
        /// @param radius : number
        /// @param value : number
        /// @param falloff : number?
        /// @return nil
        methods.add_method(
            "stampInfluence",
            |_, this, (layer, wx, wy, radius, value, falloff): (String, f32, f32, f32, f32, Option<f32>)| {
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

        // -- propagate --
        /// Propagates influence values with momentum.
        /// @param layer : string
        /// @param momentum : number?
        /// @return nil
        methods.add_method(
            "propagate",
            |_, this, (layer, momentum): (String, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .propagate(&layer, momentum.unwrap_or(0.5));
                Ok(())
            },
        );

        // -- decay --
        /// Multiplies all influences by a decay factor.
        /// @param layer : string
        /// @param factor : number
        /// @return nil
        methods.add_method("decay", |_, this, (layer, factor): (String, f32)| {
            this.inner.borrow_mut().decay(&layer, factor);
            Ok(())
        });

        // -- clearLayer --
        /// Clears all influence in a layer.
        /// @param layer : string
        /// @return nil
        methods.add_method("clearLayer", |_, this, layer: String| {
            this.inner.borrow_mut().clear_layer(&layer);
            Ok(())
        });

        // -- clearAll --
        /// Removes all influence values from every layer in the map.
        /// @return nil
        methods.add_method("clearAll", |_, this, ()| {
            this.inner.borrow_mut().clear_all();
            Ok(())
        });

        // -- getMaxPosition --
        /// Returns the world-space position of the maximum value.
        /// @param layer : string
        /// @return number, number
        methods.add_method("getMaxPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().max_position(&layer))
        });

        // -- getMinPosition --
        /// Returns the world-space position of the minimum value.
        /// @param layer : string
        /// @return number, number
        methods.add_method("getMinPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().min_position(&layer))
        });

        // -- queryRect --
        /// Returns the summed influence in a world-space rectangle.
        /// @param layer : string
        /// @param wx : number
        /// @param wy : number
        /// @param ww : number
        /// @param wh : number
        /// @return number
        methods.add_method(
            "queryRect",
            |_, this, (layer, wx, wy, ww, wh): (String, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().query_rect(&layer, wx, wy, ww, wh))
            },
        );

        // -- blend --
        /// Blends two layers into a destination layer.
        /// @param layerA : string
        /// @param weightA : number
        /// @param layerB : string
        /// @param weightB : number
        /// @param dest : string
        /// @return nil
        methods.add_method(
            "blend",
            |_, this, (layer_a, weight_a, layer_b, weight_b, dest): (String, f32, String, f32, String)| {
                this.inner.borrow_mut().blend(&layer_a, weight_a, &layer_b, weight_b, &dest);
                Ok(())
            },
        );

        // -- getWidth --
        /// Returns the influence map width in grid cells.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));

        // -- getHeight --
        /// Returns the influence map height in grid cells.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        // -- getCellSize --
        /// Returns the cell size in world units.
        /// @return number
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("InfluenceMap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "InfluenceMap" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaSquad UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Squad`].
#[derive(Clone)]
struct LuaSquad {
    inner: Rc<RefCell<Squad>>,
}

impl LuaUserData for LuaSquad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the unique name string assigned to this squad.
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        // -- addMember --
        /// Adds an agent by name to this squad.
        /// @param name : string
        /// @return nil
        methods.add_method("addMember", |_, this, name: String| {
            this.inner.borrow_mut().members.push(name);
            Ok(())
        });

        // -- removeMember --
        /// Removes an agent by name from this squad.
        /// @param name : string
        /// @return nil
        methods.add_method("removeMember", |_, this, name: String| {
            this.inner.borrow_mut().members.retain(|m| m != &name);
            Ok(())
        });

        // -- getMemberCount --
        /// Returns the number of squad members.
        /// @return integer
        methods.add_method("getMemberCount", |_, this, ()| {
            Ok(this.inner.borrow().members.len())
        });

        // -- getMembers --
        /// Returns the member names as a table.
        /// @return table
        methods.add_method("getMembers", |lua, this, ()| {
            let sq = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, m) in sq.members.iter().enumerate() {
                tbl.set(i as i64 + 1, m.as_str())?;
            }
            Ok(tbl)
        });

        // -- setLeader --
        /// Sets the squad leader by name.
        /// @param name : string
        /// @return nil
        methods.add_method("setLeader", |_, this, name: String| {
            this.inner.borrow_mut().leader = Some(name);
            Ok(())
        });

        // -- getLeader --
        /// Returns the leader name, or nil.
        /// @return string?
        methods.add_method("getLeader", |_, this, ()| {
            Ok(this.inner.borrow().leader.clone())
        });

        // -- setFormation --
        /// Sets the formation type and optional spacing.
        /// @param ftype : string
        /// @param spacing : number?
        /// @return nil
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

        // -- getFormation --
        /// Returns the current formation type name.
        /// @return string
        methods.add_method("getFormation", |_, this, ()| {
            Ok(this.inner.borrow().formation.as_str().to_string())
        });

        // -- getFormationSpacing --
        /// Returns the formation spacing in world units.
        /// @return number
        methods.add_method("getFormationSpacing", |_, this, ()| {
            Ok(this.inner.borrow().formation_spacing)
        });

        // -- getFormationPosition --
        /// Computes the world-space position for a member index (1-based).
        /// @param memberIdx : integer
        /// @param leaderX : number
        /// @param leaderY : number
        /// @return number, number
        methods.add_method(
            "getFormationPosition",
            |_, this, (member_idx, leader_x, leader_y): (usize, f32, f32)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_formation_position(member_idx.saturating_sub(1), (leader_x, leader_y)))
            },
        );

        // -- getBlackboard --
        /// Returns the squad's shared blackboard.
        /// @return Blackboard
        methods.add_method("getBlackboard", |_, this, ()| {
            let sq = this.inner.borrow();
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(sq.blackboard.clone())),
            })
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Squad"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Squad" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaCommandQueue UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`CommandQueue`].
#[derive(Clone)]
struct LuaCommandQueue {
    inner: Rc<RefCell<CommandQueue>>,
}

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

impl LuaUserData for LuaCommandQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- enqueue --
        /// Appends a command to the back of the queue.
        /// @param kind : string
        /// @param callback : function
        /// @param opts : table?
        /// @return nil
        methods.add_method(
            "enqueue",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner
                    .borrow_mut()
                    .enqueue_raw(kind, tx, ty, priority, interruptible, key);
                Ok(())
            },
        );

        // -- pushFront --
        /// Inserts a command at the front, interrupting the current one.
        /// @param kind : string
        /// @param callback : function
        /// @param opts : table?
        /// @return nil
        methods.add_method(
            "pushFront",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner
                    .borrow_mut()
                    .push_front_raw(kind, tx, ty, priority, interruptible, key);
                Ok(())
            },
        );

        // -- replace --
        /// Clears the queue and enqueues one new command.
        /// @param kind : string
        /// @param callback : function
        /// @param opts : table?
        /// @return nil
        methods.add_method(
            "replace",
            |lua, this, (kind, callback, opts): (String, LuaFunction, Option<LuaTable>)| {
                let key = lua.create_registry_value(callback)?;
                let (tx, ty, priority, interruptible) = parse_command_opts(&opts)?;
                this.inner
                    .borrow_mut()
                    .replace_raw(kind, tx, ty, priority, interruptible, key);
                Ok(())
            },
        );

        // -- cancelCurrent --
        /// Cancels the front command if it is interruptible.
        /// @return boolean
        methods.add_method("cancelCurrent", |_, this, ()| {
            Ok(this.inner.borrow_mut().cancel_current())
        });

        // -- clear --
        /// Discards all queued commands.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- getCount --
        /// Returns the number of queued commands.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.borrow().count()));

        // -- isEmpty --
        /// Returns true if there are no queued commands.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.borrow().is_empty()));

        // -- getCurrentType --
        /// Returns the kind of the front command, or nil.
        /// @return string?
        methods.add_method("getCurrentType", |_, this, ()| {
            Ok(this.inner.borrow().current_type().map(|s| s.to_string()))
        });

        // -- getCurrentTarget --
        /// Returns the target coordinates of the front command.
        /// @return number, number
        methods.add_method("getCurrentTarget", |_, this, ()| {
            Ok(this.inner.borrow().current_target())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("CommandQueue"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "CommandQueue" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// â”€â”€ TraitProfile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::traits::TraitProfile`].
#[derive(Clone)]
struct LuaTraitProfile {
    inner: Rc<RefCell<TraitProfile>>,
}

impl LuaUserData for LuaTraitProfile {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Sets the base value of this trait, replacing any previous base.
        /// @param name : string
        /// @param value : number
        /// @return nil
        methods.add_method_mut("set", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set(&name, value);
            Ok(())
        });

        /// Returns the current float value of this emotion dimension.
        /// @param name : string
        /// @return number
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });

        /// Returns the unmodified base value of this trait before modifiers.
        /// @param name : string
        /// @return number
        methods.add_method("getBase", |_, this, name: String| {
            Ok(this.inner.borrow().get_base(&name))
        });

        /// Adds a named modifier that adjusts the trait value by a delta.
        /// @param trait_name : string
        /// @param delta : number
        /// @param duration : number|nil
        /// @param source : string
        /// @return nil
        methods.add_method_mut(
            "addModifier",
            |_, this, (trait_name, delta, duration, source): (String, f32, Option<f32>, String)| {
                this.inner
                    .borrow_mut()
                    .add_modifier(&trait_name, delta, duration, &source);
                Ok(())
            },
        );

        /// Removes the specified modifiers.
        /// @param source : string
        /// @return nil
        methods.add_method_mut("removeModifiers", |_, this, source: String| {
            this.inner.borrow_mut().remove_modifiers_by_source(&source);
            Ok(())
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns true if a item is present.
        /// @param name : string
        /// @return boolean
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has(&name))
        });

        /// Returns or performs trait count.
        /// @return number
        methods.add_method("traitCount", |_, this, ()| {
            Ok(this.inner.borrow().trait_count() as i64)
        });

        /// Returns or performs archetype.
        /// @return string|nil
        methods.add_method("archetype", |_, this, ()| {
            Ok(this.inner.borrow().archetype().map(|s| s.to_string()))
        });
    }
}

// â”€â”€ StimulusWorld â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::perception::StimulusWorld`].
#[derive(Clone)]
struct LuaStimulusWorld {
    inner: Rc<RefCell<StimulusWorld>>,
}

impl LuaUserData for LuaStimulusWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds a visual stimulus at the specified world position with radius and intensity.
        /// @param x : number
        /// @param y : number
        /// @param intensity : number
        /// @param radius : number
        /// @param tag : string|nil
        /// @return integer
        methods.add_method_mut(
            "addVisual",
            |_, this, (x, y, intensity, radius, tag): (f32, f32, f32, f32, Option<String>)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_visual(x, y, intensity, radius, tag) as i64)
            },
        );

        /// Registers an auditory stimulus at a world-space position.
        /// @param x : number
        /// @param y : number
        /// @param intensity : number
        /// @param radius : number
        /// @param decay_rate : number
        /// @param tag : string|nil
        /// @return integer
        methods.add_method_mut(
            "addAuditory",
            |_,
             this,
             (x, y, intensity, radius, decay_rate, tag): (
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<String>,
            )| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_auditory(x, y, intensity, radius, decay_rate, tag)
                    as i64)
            },
        );

        /// Removes the specified item.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("remove", |_, this, id: u64| {
            Ok(this.inner.borrow_mut().remove(id))
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns or performs count.
        /// @return integer
        methods.add_method(
            "count",
            |_, this, ()| Ok(this.inner.borrow().count() as i64),
        );

        /// Resets or clears the state.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
    }
}

// â”€â”€ ContextSteering â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::context_steering::ContextSteering`].
#[derive(Clone)]
struct LuaContextSteering {
    inner: Rc<RefCell<ContextSteering>>,
}

impl LuaUserData for LuaContextSteering {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds a world-space target that this agent steers towards.
        /// @param tx : number
        /// @param ty : number
        /// @param weight : number
        /// @return nil
        methods.add_method_mut(
            "addSeekTarget",
            |_, this, (tx, ty, weight): (f32, f32, f32)| {
                this.inner.borrow_mut().add_seek_target(tx, ty, weight);
                Ok(())
            },
        );

        /// Adds a wander behavior with jitter and weight to the context steering evaluator.
        /// @param jitter : number
        /// @param weight : number
        /// @return nil
        methods.add_method_mut("addWander", |_, this, (jitter, weight): (f32, f32)| {
            this.inner.borrow_mut().add_wander(jitter, weight);
            Ok(())
        });

        /// Adds a world-space point that this agent steers away from.
        /// @param x : number
        /// @param y : number
        /// @param radius : number
        /// @param weight : number
        /// @return nil
        methods.add_method_mut(
            "addAvoidPoint",
            |_, this, (x, y, radius, weight): (f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add_avoid_point(x, y, radius, weight);
                Ok(())
            },
        );

        /// Registers a rectangular region this agent must avoid.
        /// @param min_x : number
        /// @param min_y : number
        /// @param max_x : number
        /// @param max_y : number
        /// @param margin : number
        /// @param weight : number
        /// @return nil
        methods.add_method_mut("addAvoidBounds", |_, this, (min_x, min_y, max_x, max_y, margin, weight): (f32, f32, f32, f32, f32, f32)| {
            this.inner.borrow_mut().add_avoid_bounds(min_x, min_y, max_x, max_y, margin, weight);
            Ok(())
        });

        /// Resets or clears the behaviors.
        /// @return nil
        methods.add_method_mut("clearBehaviors", |_, this, ()| {
            this.inner.borrow_mut().clear_behaviors();
            Ok(())
        });

        /// Evaluates and returns the computed result.
        /// @param ax : number
        /// @param ay : number
        /// @param vx : number
        /// @param vy : number
        /// @return number, number
        methods.add_method_mut(
            "evaluate",
            |_, this, (ax, ay, vx, vy): (f32, f32, f32, f32)| {
                let (dx, dy) = this.inner.borrow_mut().evaluate(ax, ay, vx, vy);
                Ok((dx, dy))
            },
        );

        /// Returns or performs chosen magnitude.
        /// @return number
        methods.add_method("chosenMagnitude", |_, this, ()| {
            Ok(this.inner.borrow().chosen_magnitude())
        });

        /// Returns or performs slot count.
        /// @return integer
        methods.add_method("slotCount", |_, this, ()| {
            Ok(this.inner.borrow().slot_count() as i64)
        });
    }
}

// â”€â”€ NeedSystem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::needs::NeedSystem`].
#[derive(Clone)]
struct LuaNeedSystem {
    inner: Rc<RefCell<NeedSystem>>,
}

impl LuaUserData for LuaNeedSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Registers a new need with the specified name, urgency, and decay rate in the system.
        /// @param name : string
        /// @param decay_rate : number
        /// @param urgency_threshold : number
        /// @param urgency_factor : number
        /// @return nil
        methods.add_method_mut("addNeed", |_, this, (name, decay_rate, urgency_threshold, urgency_factor): (String, f32, f32, f32)| {
            this.inner.borrow_mut().add_need(Need::new(&name, decay_rate, urgency_threshold, urgency_factor));
            Ok(())
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns or performs most urgent.
        /// @return string|nil
        methods.add_method("mostUrgent", |_, this, ()| {
            Ok(this.inner.borrow().most_urgent().map(|s| s.to_string()))
        });

        /// Returns or performs satisfy.
        /// @param name : string
        /// @param amount : number
        /// @return nil
        methods.add_method_mut("satisfy", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().satisfy(&name, amount);
            Ok(())
        });

        /// Returns or performs value of.
        /// @param name : string
        /// @return number
        methods.add_method("valueOf", |_, this, name: String| {
            Ok(this.inner.borrow().value_of(&name))
        });
    }
}

// â”€â”€ AIDirector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::director::AIDirector`].
#[derive(Clone)]
struct LuaAIDirector {
    inner: Rc<RefCell<AIDirector>>,
}

impl LuaUserData for LuaAIDirector {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Pushes a gameplay event with the given intensity to the director for awareness analysis.
        /// @param intensity : number
        /// @return nil
        methods.add_method_mut("pushEvent", |_, this, intensity: f32| {
            this.inner.borrow_mut().push_event(intensity);
            Ok(())
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Returns or performs tension.
        /// @return number
        methods.add_method("tension", |_, this, ()| Ok(this.inner.borrow().tension()));

        /// Returns or performs phase.
        /// @return string
        methods.add_method("phase", |_, this, ()| {
            Ok(this.inner.borrow().phase_str().to_string())
        });

        /// Returns or performs spawn rate factor.
        /// @return number
        methods.add_method("spawnRateFactor", |_, this, ()| {
            Ok(this.inner.borrow().spawn_rate_factor())
        });

        /// Returns or performs loot factor.
        /// @return number
        methods.add_method("lootFactor", |_, this, ()| {
            Ok(this.inner.borrow().loot_factor())
        });

        /// Returns or performs ambient intensity.
        /// @return number
        methods.add_method("ambientIntensity", |_, this, ()| {
            Ok(this.inner.borrow().ambient_intensity())
        });

        /// Sets the global narrative tension level (0â€“1 scale).
        /// @param value : number
        /// @return nil
        methods.add_method_mut("setTension", |_, this, value: f32| {
            this.inner.borrow_mut().set_tension(value);
            Ok(())
        });

        /// Resets or clears the state.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
    }
}

// â”€â”€ HTNDomain â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::htn::HTNDomain`].
#[derive(Clone)]
struct LuaHTNDomain {
    inner: Rc<RefCell<HTNDomain>>,
}

impl LuaUserData for LuaHTNDomain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Registers a primitive HTN task with a direct operator function.
        /// @param name : string
        /// @param preconditions : table
        /// @param effects : table
        /// @param effects_clear : table
        /// @return nil
        methods.add_method_mut("addPrimitive", |_, this, (name, preconds, effects, clears): (String, Vec<String>, Vec<String>, Vec<String>)| {
            let p: Vec<&str> = preconds.iter().map(|s| s.as_str()).collect();
            let e: Vec<&str> = effects.iter().map(|s| s.as_str()).collect();
            let c: Vec<&str> = clears.iter().map(|s| s.as_str()).collect();
            this.inner.borrow_mut().add_primitive(&name, p, e, c);
            Ok(())
        });

        /// Registers a compound HTN task that decomposes into sub-tasks.
        /// @param compound_name : string
        /// @param methods : table  -- array of {preconditions=[], sub_tasks=[]}
        /// @return nil
        methods.add_method_mut(
            "addCompound",
            |lua, this, (comp_name, methods_table): (String, LuaTable)| {
                let mut htn_methods: Vec<HTNMethod> = Vec::new();
                for i in 1..=methods_table.raw_len() {
                    let m: LuaTable = methods_table.raw_get(i)?;
                    let preconds: Vec<String> = m
                        .raw_get::<_, Vec<String>>("preconditions")
                        .unwrap_or_default();
                    let sub_tasks: Vec<String> =
                        m.raw_get::<_, Vec<String>>("sub_tasks").unwrap_or_default();
                    let mname: String = m
                        .raw_get::<_, String>("name")
                        .unwrap_or_else(|_| format!("method_{i}"));
                    let p: Vec<&str> = preconds.iter().map(|s| s.as_str()).collect();
                    let s: Vec<&str> = sub_tasks.iter().map(|s| s.as_str()).collect();
                    htn_methods.push(HTNMethod::with_preconditions(&mname, p, s));
                }
                this.inner
                    .borrow_mut()
                    .add_compound(&comp_name, htn_methods);
                let _ = lua; // suppress warning
                Ok(())
            },
        );

        /// Runs planning and returns the resulting action sequence.
        /// @param root_task : string
        /// @param state : table
        /// @return table|nil
        methods.add_method(
            "plan",
            |lua, this, (root_task, state_table): (String, LuaTable)| {
                let mut state: WorldState = std::collections::HashMap::new();
                for pair in state_table.pairs::<String, f32>() {
                    let (k, v) = pair?;
                    state.insert(k, v);
                }
                let result = HTNPlanner::plan(&this.inner.borrow(), &root_task, &state);
                match result {
                    None => Ok(LuaValue::Nil),
                    Some(plan) => {
                        let t = lua.create_table()?;
                        for (i, step) in plan.into_iter().enumerate() {
                            t.raw_set(i + 1, step)?;
                        }
                        Ok(LuaValue::Table(t))
                    }
                }
            },
        );

        /// Returns or performs task count.
        /// @return integer
        methods.add_method("taskCount", |_, this, ()| {
            Ok(this.inner.borrow().task_count() as i64)
        });
    }
}

// â”€â”€ MCTSEngine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::mcts::MCTSEngine`].
#[derive(Clone)]
struct LuaMCTSEngine {
    inner: Rc<RefCell<MCTSEngine>>,
}

impl LuaUserData for LuaMCTSEngine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Uses Lua closures for game logic. All closures receive/return integer states.
        /// @param root_state : integer
        /// @param get_actions : function(state) -> table
        /// @param apply_action : function(state, action) -> integer
        /// @param evaluate : function(state) -> number
        /// @return integer|nil
        methods.add_method_mut(
            "search",
            |_,
             this,
             (root_state, get_actions_fn, apply_fn, eval_fn): (
                i64,
                LuaFunction,
                LuaFunction,
                LuaFunction,
            )| {
                let mut engine = this.inner.borrow_mut();
                let mut get_actions = |s: &i64| -> Vec<i32> {
                    get_actions_fn.call::<_, Vec<i32>>(*s).unwrap_or_default()
                };
                let mut apply_action = |s: &i64, action: i32| -> i64 {
                    apply_fn.call::<_, i64>((*s, action)).unwrap_or(*s)
                };
                let mut evaluate = |s: &i64| -> f32 { eval_fn.call::<_, f32>(*s).unwrap_or(0.0) };
                let result = engine.search(
                    root_state,
                    &mut get_actions,
                    &mut apply_action,
                    &mut evaluate,
                );
                Ok(result.map(|a| a as i64))
            },
        );
    }
}

// â”€â”€ EmotionModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::emotion::EmotionModel`].
#[derive(Clone)]
struct LuaEmotionModel {
    inner: Rc<RefCell<EmotionModel>>,
}

impl LuaUserData for LuaEmotionModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds an emotion category with the given name and initial intensity to the model.
        /// @param name : string
        /// @param resting_level : number
        /// @param decay_rate : number
        /// @param min_visible : number
        /// @return nil
        methods.add_method_mut(
            "add",
            |_, this, (name, rest, decay, min_vis): (String, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add(Emotion::new(&name, rest, decay, min_vis));
                Ok(())
            },
        );

        /// Returns or performs trigger.
        /// @param name : string
        /// @param amount : number
        /// @return nil
        methods.add_method_mut("trigger", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().trigger(&name, amount);
            Ok(())
        });

        /// Returns the current float value of this emotion dimension.
        /// @param name : string
        /// @return number
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });

        /// Returns or performs dominant.
        /// @return string|nil
        methods.add_method("dominant", |_, this, ()| {
            Ok(this.inner.borrow().dominant().map(|s| s.to_string()))
        });

        /// Returns `true` if the emotion dimension is currently active and above threshold.
        /// @param name : string
        /// @return boolean
        methods.add_method("isActive", |_, this, name: String| {
            Ok(this.inner.borrow().is_active(&name))
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        /// Resets or clears the state.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
    }
}

// â”€â”€ ORCASolver â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::orca::ORCASolver`].
#[derive(Clone)]
struct LuaORCASolver {
    inner: Rc<RefCell<ORCASolver>>,
}

impl LuaUserData for LuaORCASolver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds an ORCA agent at the given position with radius and max speed to the solver.
        /// @param x : number
        /// @param y : number
        /// @param radius : number
        /// @param max_speed : number
        /// @return integer
        methods.add_method_mut(
            "addAgent",
            |_, this, (x, y, radius, max_speed): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_agent(ORCAAgent::new(x, y, radius, max_speed)) as i64)
            },
        );

        /// Sets the preferred velocity.
        /// @param index : integer
        /// @param pvx : number
        /// @param pvy : number
        /// @return nil
        methods.add_method_mut(
            "setPreferredVelocity",
            |_, this, (idx, pvx, pvy): (usize, f32, f32)| {
                if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                    a.preferred_velocity = (pvx, pvy);
                }
                Ok(())
            },
        );

        /// Sets the agent's current world-space position for ORCA velocity computation.
        /// @param index : integer
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method_mut("setPosition", |_, this, (idx, x, y): (usize, f32, f32)| {
            if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                a.position = (x, y);
            }
            Ok(())
        });

        /// Computes and returns the result.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("compute", |_, this, dt: f32| {
            this.inner.borrow_mut().compute(dt);
            Ok(())
        });

        /// Returns the safe velocity.
        /// @param index : integer
        /// @return number, number
        methods.add_method("getSafeVelocity", |_, this, idx: usize| {
            let solver = this.inner.borrow();
            let v = solver
                .agents
                .get(idx)
                .map(|a| a.safe_velocity)
                .unwrap_or((0.0, 0.0));
            Ok((v.0, v.1))
        });

        /// Returns or performs agent count.
        /// @return integer
        methods.add_method("agentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count() as i64)
        });
    }
}

// â”€â”€ NeuralNet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::neural_net::NeuralNet`].
#[derive(Clone)]
struct LuaNeuralNet {
    inner: Rc<RefCell<NeuralNet>>,
}

impl LuaUserData for LuaNeuralNet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds a neural network layer with inputs, outputs, and an activation function.
        /// @param inputs : integer
        /// @param outputs : integer
        /// @param activation : string
        /// @return nil
        methods.add_method_mut(
            "addLayer",
            |_, this, (inputs, outputs, activation): (usize, usize, String)| {
                let act = Activation::from_str(&activation);
                this.inner.borrow_mut().add_layer(inputs, outputs, act);
                Ok(())
            },
        );

        /// Returns or performs forward.
        /// @param input : table
        /// @return table
        methods.add_method("forward", |lua, this, input: Vec<f32>| {
            let out = this.inner.borrow().forward(&input);
            let t = lua.create_table()?;
            for (i, v) in out.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });

        /// Overwrites all connection weights with values from a flat table.
        /// @param weights : table
        /// @return boolean
        methods.add_method_mut("setWeights", |_, this, weights: Vec<f32>| {
            Ok(this.inner.borrow_mut().set_weights(&weights))
        });

        /// Returns a flat table of all connection weight values in the network.
        /// @return table
        methods.add_method("getWeights", |lua, this, ()| {
            let w = this.inner.borrow().get_weights();
            let t = lua.create_table()?;
            for (i, v) in w.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });

        /// Returns or performs param count.
        /// @return integer
        methods.add_method("paramCount", |_, this, ()| {
            Ok(this.inner.borrow().param_count() as i64)
        });

        /// Returns or performs layer count.
        /// @return integer
        methods.add_method("layerCount", |_, this, ()| {
            Ok(this.inner.borrow().layer_count() as i64)
        });
    }
}

// â”€â”€ GeneticAlgorithm â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::genetic::GeneticAlgorithm`].
#[derive(Clone)]
struct LuaGeneticAlgorithm {
    inner: Rc<RefCell<GeneticAlgorithm>>,
}

impl LuaUserData for LuaGeneticAlgorithm {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Runs one generation of the evolutionary algorithm.
        /// @return nil
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });

        /// Returns or performs generation.
        /// @return integer
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });

        /// Returns or performs pop size.
        /// @return integer
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });

        /// Sets the fitness score used by the genetic algorithm selection step.
        /// @param index : integer
        /// @param fitness : number
        /// @return nil
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            if let Some(c) = this.inner.borrow_mut().population.get_mut(idx) {
                c.fitness = fitness;
            }
            Ok(())
        });

        /// Returns the chromosome as an ordered table of gene values.
        /// @param index : integer
        /// @return table
        methods.add_method("getGenes", |lua, this, idx: usize| {
            let ga = this.inner.borrow();
            let t = lua.create_table()?;
            if let Some(c) = ga.population.get(idx) {
                for (i, &g) in c.genes.iter().enumerate() {
                    t.raw_set(i + 1, g)?;
                }
            }
            Ok(t)
        });

        /// Returns or performs best genes.
        /// @return table
        methods.add_method("bestGenes", |lua, this, ()| {
            let ga = this.inner.borrow();
            let t = lua.create_table()?;
            if let Some(best) = ga.best() {
                for (i, &g) in best.genes.iter().enumerate() {
                    t.raw_set(i + 1, g)?;
                }
            }
            Ok(t)
        });
    }
}

// â”€â”€ Bandit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::bandit::Bandit`].
#[derive(Clone)]
struct LuaBandit {
    inner: Rc<RefCell<Bandit>>,
}

impl LuaUserData for LuaBandit {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns or performs select.
        /// @return integer
        methods.add_method_mut("select", |_, this, ()| {
            Ok(this.inner.borrow_mut().select() as i64)
        });

        /// Advances the simulation by one time step.
        /// @param index : integer
        /// @param reward : number
        /// @return nil
        methods.add_method_mut("update", |_, this, (idx, reward): (usize, f64)| {
            this.inner.borrow_mut().update(idx, reward);
            Ok(())
        });

        /// Returns or performs best arm.
        /// @return integer
        methods.add_method("bestArm", |_, this, ()| {
            Ok(this.inner.borrow().best_arm() as i64)
        });

        /// Resets or clears the state.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        /// Returns or performs arm count.
        /// @return integer
        methods.add_method("armCount", |_, this, ()| {
            Ok(this.inner.borrow().arm_count() as i64)
        });

        /// Returns or performs total pulls.
        /// @return integer
        methods.add_method("totalPulls", |_, this, ()| {
            Ok(this.inner.borrow().total_pulls as i64)
        });
    }
}

// â”€â”€ Neuroevolution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::neuroevolution::Neuroevolution`].
#[derive(Clone)]
struct LuaNeuroevolution {
    inner: Rc<RefCell<Neuroevolution>>,
}

impl LuaUserData for LuaNeuroevolution {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Runs one generation of the evolutionary algorithm.
        /// @return nil
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });

        /// Sets the fitness score used by the genetic algorithm selection step.
        /// @param index : integer
        /// @param fitness : number
        /// @return nil
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            this.inner.borrow_mut().set_fitness(idx, fitness);
            Ok(())
        });

        /// Returns or performs chromosome to net.
        /// @param index : integer
        /// @return nil
        /// LuaNeuralNet|nil
        methods.add_method("chromosomeToNet", |_, this, idx: usize| {
            let net = this.inner.borrow().chromosome_to_net(idx);
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });

        /// Returns or performs best network.
        /// LuaNeuralNet|nil
        /// @return nil
        methods.add_method("bestNetwork", |_, this, ()| {
            let net = this.inner.borrow().best_network();
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });

        /// Returns or performs best fitness.
        /// @return number
        methods.add_method("bestFitness", |_, this, ()| {
            Ok(this.inner.borrow().best_fitness())
        });

        /// Returns or performs pop size.
        /// @return integer
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });

        /// Returns or performs generation.
        /// @return integer
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });
    }
}

// â”€â”€ StrategyAI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::strategy::StrategyAI`].
#[derive(Clone)]
struct LuaStrategyAI {
    inner: Rc<RefCell<StrategyAI>>,
}

impl LuaUserData for LuaStrategyAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds a strategic goal with priority score to the planner for future evaluation.
        /// @param name : string
        /// @return nil
        methods.add_method_mut("addGoal", |_, this, name: String| {
            this.inner.borrow_mut().add_goal_named(&name);
            Ok(())
        });

        /// Adds a string tag to the strategy AI instance for goal filtering and categorization.
        /// @param tag : string
        /// @return nil
        methods.add_method_mut("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(&tag);
            Ok(())
        });

        /// Removes the specified tag.
        /// @param tag : string
        /// @return nil
        methods.add_method_mut("removeTag", |_, this, tag: String| {
            this.inner.borrow_mut().remove_tag(&tag);
            Ok(())
        });

        /// Advances the simulation by one time step.
        /// @param dt : number
        /// @param scorer : function(goal_name) -> number
        /// @return nil
        methods.add_method_mut("update", |_, this, (dt, scorer_fn): (f32, LuaFunction)| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().update(dt, &mut scorer);
            Ok(())
        });

        /// Returns or performs force evaluate.
        /// @param scorer : function(goal_name) -> number
        /// @return nil
        methods.add_method_mut("forceEvaluate", |_, this, scorer_fn: LuaFunction| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().force_evaluate(&mut scorer);
            Ok(())
        });

        /// Returns or performs active goal.
        /// @return string|nil
        methods.add_method("activeGoal", |_, this, ()| {
            Ok(this.inner.borrow().active_goal().map(|s| s.to_string()))
        });

        /// Returns or performs time until next.
        /// @return number
        methods.add_method("timeUntilNext", |_, this, ()| {
            Ok(this.inner.borrow().time_until_next())
        });
    }
}

// â”€â”€ AILod â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Lua wrapper for [`crate::ai::lod::AILod`].
#[derive(Clone)]
struct LuaAILod {
    inner: Rc<RefCell<AILod>>,
}

impl LuaUserData for LuaAILod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns or performs tier for.
        /// @param agent_x : number
        /// @param agent_y : number
        /// @param ref_x : number
        /// @param ref_y : number
        /// @return integer
        methods.add_method(
            "tierFor",
            |_, this, (ax, ay, rx, ry): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().tier_for((ax, ay), (rx, ry)) as i64)
            },
        );

        /// Returns or performs should update.
        /// @param tier : integer
        /// @param frame_number : integer
        /// @return boolean
        methods.add_method("shouldUpdate", |_, this, (tier, frame): (usize, u64)| {
            Ok(this.inner.borrow().should_update(tier, frame))
        });

        /// Returns or performs tier count.
        /// @return integer
        methods.add_method("tierCount", |_, this, ()| {
            Ok(this.inner.borrow().tier_count() as i64)
        });

        /// Returns or performs tier name.
        /// @param tier : integer
        /// @return string
        methods.add_method("tierName", |_, this, tier: usize| {
            Ok(this.inner.borrow().tier(tier).map(|t| t.name.clone()))
        });
    }
}

// -------------------------------------------------------------------------------

/// Registers the `lurek.ai` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // â”€â”€ newWorld â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new AI world container.
    /// @return AIWorld
    tbl.set(
        "newWorld",
        lua.create_function(|_, ()| {
            Ok(LuaAIWorld {
                inner: Rc::new(RefCell::new(AIWorld::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // â”€â”€ newBlackboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new standalone blackboard.
    /// @return Blackboard
    tbl.set(
        "newBlackboard",
        lua.create_function(|_, ()| {
            Ok(LuaBlackboard {
                inner: Rc::new(RefCell::new(Blackboard::new())),
            })
        })?,
    )?;

    // â”€â”€ newStateMachine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new finite state machine.
    /// @return StateMachine
    tbl.set(
        "newStateMachine",
        lua.create_function(|_, ()| {
            Ok(LuaStateMachine {
                inner: Rc::new(RefCell::new(crate::ai::StateMachine::new())),
            })
        })?,
    )?;

    // â”€â”€ newBehaviorTree â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new behavior tree.
    /// @return BehaviorTree
    tbl.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                inner: Rc::new(RefCell::new(BehaviorTree::new())),
            })
        })?,
    )?;

    // â”€â”€ newSelector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT selector node.
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newSequence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT sequence node.
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newParallel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT parallel node with optional policies.
    /// @param successPolicy : string?
    /// @param failurePolicy : string?
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newInverter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT inverter decorator.
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newRepeater â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT repeater decorator.
    /// @param count : integer?
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newSucceeder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT succeeder decorator.
    /// @return BTNode
    tbl.set(
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

    // â”€â”€ newAction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT action leaf with a Lua callback.
    /// @param callback : function
    /// @return BTNode
    tbl.set(
        "newAction",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Action { callback: key })),
            })
        })?,
    )?;

    // â”€â”€ newCondition â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a BT condition leaf with a Lua predicate.
    /// @param callback : function
    /// @return BTNode
    tbl.set(
        "newCondition",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Condition { callback: key })),
            })
        })?,
    )?;

    // ── newGuard ──────────────────────────────────────────────────────────────────
    /// Creates a BT Guard decorator. The predicate is evaluated before each tick;
    /// if it returns false the child is skipped and Failure is returned.
    /// @param predicate : function(agent, blackboard) -> boolean
    /// @param child : BTNode
    /// @return BTNode
    tbl.set(
        "newGuard",
        lua.create_function(
            |lua, (predicate, child_ud): (LuaFunction, LuaAnyUserData)| {
                let key = lua.create_registry_value(predicate)?;
                let child = child_ud.borrow::<LuaBTNode>()?;
                // Take ownership of the child node (leaves a placeholder Sequence behind),
                // matching the same move-out pattern used by setChild/addChild.
                let taken = std::mem::replace(
                    &mut *child.inner.borrow_mut(),
                    BTNode::Sequence {
                        children: Vec::new(),
                        running_idx: 0,
                    },
                );
                Ok(LuaBTNode {
                    inner: Rc::new(RefCell::new(BTNode::Guard {
                        predicate: key,
                        child: Box::new(taken),
                    })),
                })
            },
        )?,
    )?;

    // â”€â”€ newSteeringManager â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new steering behavior manager.
    /// @return SteeringManager
    tbl.set(
        "newSteeringManager",
        lua.create_function(|_, ()| {
            Ok(LuaSteeringManager {
                inner: Rc::new(RefCell::new(SteeringManager::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // â”€â”€ newQLearner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a tabular Q-learner.
    /// @param stateCount : integer
    /// @param actionCount : integer
    /// @return QLearner
    tbl.set(
        "newQLearner",
        lua.create_function(|_, (sc, ac): (usize, usize)| {
            Ok(LuaQLearner {
                inner: Rc::new(RefCell::new(QLearner::new(sc, ac))),
            })
        })?,
    )?;

    // â”€â”€ newUtilityAI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new utility AI evaluator.
    /// @return UtilityAI
    tbl.set(
        "newUtilityAI",
        lua.create_function(|_, ()| {
            Ok(LuaUtilityAI {
                inner: Rc::new(RefCell::new(UtilityAI::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // â”€â”€ newGOAPPlanner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new GOAP planning solver.
    /// @return GOAPPlanner
    tbl.set(
        "newGOAPPlanner",
        lua.create_function(|_, ()| {
            Ok(LuaGOAPPlanner {
                inner: Rc::new(RefCell::new(GOAPPlanner::new())),
            })
        })?,
    )?;

    // â”€â”€ newInfluenceMap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a multi-layer influence map grid.
    /// @param width : integer
    /// @param height : integer
    /// @param cellSize : number
    /// @return InfluenceMap
    tbl.set(
        "newInfluenceMap",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaInfluenceMap {
                inner: Rc::new(RefCell::new(InfluenceMap::new(w, h, cs))),
            })
        })?,
    )?;

    // â”€â”€ newSquad â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a named squad for formation positioning.
    /// @param name : string
    /// @return Squad
    tbl.set(
        "newSquad",
        lua.create_function(|_, name: String| {
            Ok(LuaSquad {
                inner: Rc::new(RefCell::new(Squad::new(&name))),
            })
        })?,
    )?;

    // â”€â”€ newCommandQueue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates an RTS-style command queue.
    /// @return CommandQueue
    tbl.set(
        "newCommandQueue",
        lua.create_function(|_, ()| {
            Ok(LuaCommandQueue {
                inner: Rc::new(RefCell::new(CommandQueue::new())),
            })
        })?,
    )?;

    // â”€â”€ newTraitProfile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new personality trait profile.
    /// @return TraitProfile
    tbl.set(
        "newTraitProfile",
        lua.create_function(|_, ()| {
            Ok(LuaTraitProfile {
                inner: Rc::new(RefCell::new(TraitProfile::new())),
            })
        })?,
    )?;

    // â”€â”€ newStimulusWorld â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new stimulus perception world.
    /// @return StimulusWorld
    tbl.set(
        "newStimulusWorld",
        lua.create_function(|_, ()| {
            Ok(LuaStimulusWorld {
                inner: Rc::new(RefCell::new(StimulusWorld::new())),
            })
        })?,
    )?;

    // â”€â”€ newContextSteering â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new context steering controller.
    /// @param slots : integer
    /// @return ContextSteering
    tbl.set(
        "newContextSteering",
        lua.create_function(|_, slots: usize| {
            let slots = if slots == 0 { 16 } else { slots };
            Ok(LuaContextSteering {
                inner: Rc::new(RefCell::new(ContextSteering::new(slots))),
            })
        })?,
    )?;

    // â”€â”€ newNeedSystem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new motivational need system.
    /// @return NeedSystem
    tbl.set(
        "newNeedSystem",
        lua.create_function(|_, ()| {
            Ok(LuaNeedSystem {
                inner: Rc::new(RefCell::new(NeedSystem::new())),
            })
        })?,
    )?;

    // â”€â”€ newAIDirector â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new AI pacing director with default config.
    /// @return AIDirector
    tbl.set(
        "newAIDirector",
        lua.create_function(|_, ()| {
            Ok(LuaAIDirector {
                inner: Rc::new(RefCell::new(AIDirector::new())),
            })
        })?,
    )?;

    // â”€â”€ newHTNDomain â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new Hierarchical Task Network domain.
    /// @return HTNDomain
    tbl.set(
        "newHTNDomain",
        lua.create_function(|_, ()| {
            Ok(LuaHTNDomain {
                inner: Rc::new(RefCell::new(HTNDomain::new())),
            })
        })?,
    )?;

    // â”€â”€ newMCTSEngine â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new Monte Carlo Tree Search engine.
    /// @param iterations : integer
    /// @param uct_c : number
    /// @param rollout_depth : integer
    /// @param seed : integer
    /// @return MCTSEngine
    tbl.set(
        "newMCTSEngine",
        lua.create_function(|_, (iters, uct_c, depth, seed): (u32, f32, usize, u64)| {
            let cfg = MCTSConfig {
                iterations: iters,
                uct_c,
                rollout_depth: depth,
                seed,
            };
            Ok(LuaMCTSEngine {
                inner: Rc::new(RefCell::new(MCTSEngine::new(cfg))),
            })
        })?,
    )?;

    // â”€â”€ newEmotionModel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new affective emotion model.
    /// @return EmotionModel
    tbl.set(
        "newEmotionModel",
        lua.create_function(|_, ()| {
            Ok(LuaEmotionModel {
                inner: Rc::new(RefCell::new(EmotionModel::new())),
            })
        })?,
    )?;

    // â”€â”€ newORCASolver â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new ORCA crowd avoidance solver.
    /// @param time_horizon : number
    /// @return ORCASolver
    tbl.set(
        "newORCASolver",
        lua.create_function(|_, time_horizon: f32| {
            Ok(LuaORCASolver {
                inner: Rc::new(RefCell::new(ORCASolver::new(time_horizon))),
            })
        })?,
    )?;

    // â”€â”€ newNeuralNet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new feedforward neural network (inference only).
    /// @return NeuralNet
    tbl.set(
        "newNeuralNet",
        lua.create_function(|_, ()| {
            Ok(LuaNeuralNet {
                inner: Rc::new(RefCell::new(NeuralNet::new())),
            })
        })?,
    )?;

    // â”€â”€ newGeneticAlgorithm â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new genetic algorithm.
    /// @param pop_size : integer
    /// @param gene_count : integer
    /// @param seed : integer
    /// @return GeneticAlgorithm
    tbl.set(
        "newGeneticAlgorithm",
        lua.create_function(|_, (pop_size, gene_count, seed): (usize, usize, u64)| {
            Ok(LuaGeneticAlgorithm {
                inner: Rc::new(RefCell::new(GeneticAlgorithm::new(
                    pop_size, gene_count, seed,
                ))),
            })
        })?,
    )?;

    // â”€â”€ newBandit â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new multi-armed bandit.
    /// @param arm_count : integer
    /// @param strategy : string  -- "epsilon_greedy", "ucb1", or "thompson"
    /// @param epsilon : number   -- only used for epsilon_greedy
    /// @param seed : integer
    /// @return Bandit
    tbl.set(
        "newBandit",
        lua.create_function(
            |_, (arm_count, strategy, epsilon, seed): (usize, String, f32, u64)| {
                let strat = match strategy.as_str() {
                    "ucb1" => BanditStrategy::UCB1,
                    "thompson" | "thompson_sampling" => BanditStrategy::ThompsonSampling,
                    _ => BanditStrategy::EpsilonGreedy {
                        epsilon: epsilon.clamp(0.0, 1.0),
                    },
                };
                Ok(LuaBandit {
                    inner: Rc::new(RefCell::new(Bandit::new(arm_count, strat, seed))),
                })
            },
        )?,
    )?;

    // â”€â”€ newNeuroevolution â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a neuroevolution trainer (GA for neural network weights).
    /// @param layer_spec : table  -- array of {inputs, outputs, activation}
    /// @param pop_size : integer
    /// @param seed : integer
    /// @return Neuroevolution
    tbl.set(
        "newNeuroevolution",
        lua.create_function(|_, (layer_spec, pop_size, seed): (LuaTable, usize, u64)| {
            let mut spec: Vec<(usize, usize, &'static str)> = Vec::new();
            for i in 1..=layer_spec.raw_len() {
                let entry: LuaTable = layer_spec.raw_get(i)?;
                let in_size: usize = entry.raw_get("inputs").unwrap_or(1);
                let out_size: usize = entry.raw_get("outputs").unwrap_or(1);
                let act_str: String = entry
                    .raw_get("activation")
                    .unwrap_or_else(|_| "relu".into());
                // Map to &'static str
                let act: &'static str = match act_str.as_str() {
                    "sigmoid" => "sigmoid",
                    "tanh" => "tanh",
                    "linear" => "linear",
                    "softmax" => "softmax",
                    _ => "relu",
                };
                spec.push((in_size, out_size, act));
            }
            Ok(LuaNeuroevolution {
                inner: Rc::new(RefCell::new(Neuroevolution::new(spec, pop_size, seed))),
            })
        })?,
    )?;

    // â”€â”€ newStrategyAI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new throttled strategy AI.
    /// @param update_interval : number  -- seconds between re-evaluations
    /// @return StrategyAI
    tbl.set(
        "newStrategyAI",
        lua.create_function(|_, update_interval: f32| {
            Ok(LuaStrategyAI {
                inner: Rc::new(RefCell::new(StrategyAI::new(update_interval))),
            })
        })?,
    )?;

    // â”€â”€ newAILod â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Creates a new AI LOD controller with default 3-tier config.
    /// @return AILod
    tbl.set(
        "newAILod",
        lua.create_function(|_, ()| {
            Ok(LuaAILod {
                inner: Rc::new(RefCell::new(AILod::default())),
            })
        })?,
    )?;

    /// Provides comprehensive artificial intelligence routines and types.
    lurek.set("ai", tbl)?;
    Ok(())
}
