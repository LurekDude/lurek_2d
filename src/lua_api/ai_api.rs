//! `lurek.ai` - Game AI toolkit: worlds, agents, FSM, behavior trees, steering, Q-learning, utility AI, GOAP, squads, and command queues.

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
    DialogueAI,
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
    // Registry for custom-model Lua callbacks; shared with all agents that
    // have been given a `setCustomModel` callback.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaAIWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAgent --
        /// Registers a new named agent and returns its handle.
        /// @param | name | string | Agent name to register in the world.
        /// @return | LAgent | Agent handle for the registered name.
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
        /// Returns the agent handle for the given name, or nil if it does not exist.
        /// @param | name | string | Agent name to look up.
        /// @return | LAgent | Agent handle for the requested name, or nil if it does not exist.
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
        /// @param | agent | LAgent | Agent handle to remove from the world.
        /// @return | nil | No value is returned.
        methods.add_method("removeAgent", |_, this, agent: LuaAnyUserData| {
            let a = agent.borrow::<LuaAgent>()?;
            this.inner.borrow_mut().remove_agent(&a.name);
            Ok(())
        });

        // -- getAgentCount --
        /// Returns the number of registered agents.
        /// @return | integer | Number of agents currently registered in the world.
        methods.add_method("getAgentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count())
        });

        // -- getGlobalBlackboard --
        /// Returns a snapshot of the world-level blackboard.
        /// @return | LAIBlackboard | Copy of the world blackboard at call time.
        methods.add_method("getGlobalBlackboard", |_, this, ()| {
            let w = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(w.global_blackboard().clone())),
            })
        });

        // -- update --
        /// Advances all agents by dt seconds, then invokes any custom-model callbacks.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
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
                        Some(idx) => LuaAIBlackboard {
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
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAIWorld"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches AIWorld or Object.
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
    // Shared reference to the owning `LuaAIWorld`'s callback registry.
    callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the agent's registered name.
        /// @return | string | Registered name of this agent.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));

        // -- setPosition --
        /// Sets the agent's world-space position.
        /// @param | x | number | World-space x coordinate.
        /// @param | y | number | World-space y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].position = (x, y);
            }
            Ok(())
        });

        // -- getPosition --
        /// Returns the agent's current position.
        /// @return | number | Current world-space X coordinate.
        /// @return | number | Current world-space Y coordinate.
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
        /// @param | x | number | Velocity x component.
        /// @param | y | number | Velocity y component.
        /// @return | nil | No value is returned.
        methods.add_method("setVelocity", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].velocity = (x, y);
            }
            Ok(())
        });

        // -- getVelocity --
        /// Returns the agent's current velocity.
        /// @return | number | Current velocity X component.
        /// @return | number | Current velocity Y component.
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
        /// @param | v | number | Maximum movement speed.
        /// @return | nil | No value is returned.
        methods.add_method("setMaxSpeed", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_speed = v;
            }
            Ok(())
        });

        // -- getMaxSpeed --
        /// Returns the maximum speed cap.
        /// @return | number | Maximum movement speed.
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
        /// @param | v | number | Maximum steering force.
        /// @return | nil | No value is returned.
        methods.add_method("setMaxForce", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_force = v;
            }
            Ok(())
        });

        // -- getMaxForce --
        /// Returns the maximum steering force cap.
        /// @return | number | Maximum steering force.
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
        /// @param | p | integer | Scheduling priority value.
        /// @return | nil | No value is returned.
        methods.add_method("setPriority", |_, this, p: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].priority = p;
            }
            Ok(())
        });

        // -- getPriority --
        /// Returns the agent's scheduling priority.
        /// @return | integer | Scheduling priority for this agent.
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
        /// @param | model | string | Decision model name to parse and apply.
        /// @return | nil | No value is returned.
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
        /// @return | string | Name of the current decision model.
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
        /// @param | callback | function | Callback invoked during world updates with agent, blackboard, and dt.
        /// @return | nil | No value is returned.
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
        /// @param | tag | string | Tag to add to this agent.
        /// @return | nil | No value is returned.
        methods.add_method("addTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.insert(tag);
            }
            Ok(())
        });

        // -- removeTag --
        /// Removes a tag from this agent.
        /// @param | tag | string | Tag to remove from this agent.
        /// @return | nil | No value is returned.
        methods.add_method("removeTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.remove(&tag);
            }
            Ok(())
        });

        // -- hasTag --
        /// Returns true if the agent has the given tag.
        /// @param | tag | string | Tag to check on this agent.
        /// @return | boolean | True if the agent currently has the tag.
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
        /// @return | LAIBlackboard | Copy of the agent blackboard at call time.
        methods.add_method("getBlackboard", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(LuaAIBlackboard {
                    inner: Rc::new(RefCell::new(w.agents[idx].blackboard.clone())),
                })
            } else {
                Ok(LuaAIBlackboard {
                    inner: Rc::new(RefCell::new(Blackboard::new())),
                })
            }
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAgent"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches Agent or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Agent" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAIBlackboard UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Blackboard`].
#[derive(Clone)]
struct LuaAIBlackboard {
    inner: Rc<RefCell<Blackboard>>,
}

impl LuaUserData for LuaAIBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setNumber --
        /// Stores a number under the given key.
        /// @param | key | string | Blackboard entry name.
        /// @param | value | number | Number to store.
        /// @return | nil | No value is returned.
        methods.add_method("setNumber", |_, this, (key, value): (String, f64)| {
            this.inner.borrow_mut().set_number(&key, value);
            Ok(())
        });

        // -- getNumber --
        /// Returns the number for the given key, or default.
        /// @param | key | string | Blackboard entry name.
        /// @param | default | number? | Fallback value when the key is missing.
        /// @return | number | Stored number, or the provided default.
        methods.add_method(
            "getNumber",
            |_, this, (key, default): (String, Option<f64>)| {
                Ok(this.inner.borrow().get_number(&key, default.unwrap_or(0.0)))
            },
        );

        // -- setBool --
        /// Stores a boolean under the given key.
        /// @param | key | string | Blackboard entry name.
        /// @param | value | boolean | Boolean to store.
        /// @return | nil | No value is returned.
        methods.add_method("setBool", |_, this, (key, value): (String, bool)| {
            this.inner.borrow_mut().set_bool(&key, value);
            Ok(())
        });

        // -- getBool --
        /// Returns the boolean for the given key, or default.
        /// @param | key | string | Blackboard entry name.
        /// @param | default | boolean? | Fallback value when the key is missing.
        /// @return | boolean | Stored boolean, or the provided default.
        methods.add_method(
            "getBool",
            |_, this, (key, default): (String, Option<bool>)| {
                Ok(this.inner.borrow().get_bool(&key, default.unwrap_or(false)))
            },
        );

        // -- setString --
        /// Stores a string under the given key.
        /// @param | key | string | Blackboard entry name.
        /// @param | value | string | String to store.
        /// @return | nil | No value is returned.
        methods.add_method("setString", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().set_string(&key, &value);
            Ok(())
        });

        // -- getString --
        /// Returns the string for the given key, or default.
        /// @param | key | string | Blackboard entry name.
        /// @param | default | string? | Fallback value when the key is missing.
        /// @return | string | Stored string, or the provided default.
        methods.add_method(
            "getString",
            |_, this, (key, default): (String, Option<String>)| {
                let def = default.unwrap_or_default();
                Ok(this.inner.borrow().get_string(&key, &def))
            },
        );

        // -- has --
        /// Returns true if a value exists under the key.
        /// @param | key | string | Blackboard entry name.
        /// @return | boolean | True if the key exists.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.inner.borrow().has(&key))
        });

        // -- remove --
        /// Removes the entry at key.
        /// @param | key | string | Blackboard entry name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |_, this, key: String| {
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });

        // -- clear --
        /// Removes all local entries.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- getKeys --
        /// Returns all local keys as a table.
        /// @return | table | Array-style table of local key names.
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
        /// @return | integer | Number of entries stored in this blackboard.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().size()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAIBlackboard"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches AIBlackboard, Blackboard, or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIBlackboard" || name == "Blackboard" || name == "Object")
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
        /// @param | name | string | State name to register.
        /// @param | opts | table | State options table with optional lifecycle callbacks.
        /// @return | nil | No value is returned.
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
        /// @param | from | string | Source state name.
        /// @param | to | string | Destination state name.
        /// @param | guard | function? | Optional guard callback for the transition.
        /// @param | priority | integer? | Optional transition priority.
        /// @return | nil | No value is returned.
        methods.add_method("addTransition", |lua, this, (from, to, guard, priority): (String, String, Option<LuaFunction>, Option<i32>)| {
                let guard_key = guard.map(|f| lua.create_registry_value(f)).transpose()?;
                this.inner.borrow_mut().add_transition_raw(from, to, priority.unwrap_or(0), guard_key);
                Ok(())
            },
        );

        // -- setInitialState --
        /// Sets the FSM's initial state; must be called before the first update.
        /// @param | name | string | State name to set as the initial state.
        /// @return | nil | No value is returned.
        methods.add_method("setInitialState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.initial_state = Some(name.clone());
            if fsm.current_state.is_none() {
                fsm.current_state = Some(name);
            }
            Ok(())
        });

        // -- getCurrentState --
        /// Returns the current state name, or nil if no state is active.
        /// @return | string | Current state name, or nil if no state is active.
        methods.add_method("getCurrentState", |_, this, ()| {
            Ok(this.inner.borrow().current_state().map(|s| s.to_string()))
        });

        // -- forceState --
        /// Forces a transition to the named state.
        /// @param | name | string | State name to force as current.
        /// @return | nil | No value is returned.
        methods.add_method("forceState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.current_state = Some(name);
            fsm.time_in_state = 0.0;
            Ok(())
        });

        // -- getTimeInState --
        /// Returns seconds spent in the current state.
        /// @return | number | Seconds spent in the current state.
        methods.add_method("getTimeInState", |_, this, ()| {
            Ok(this.inner.borrow().time_in_state())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LStateMachine"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches StateMachine or Object.
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
        /// @param | node | LBTNode | Node to install as the tree root.
        /// @return | nil | No value is returned.
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
        /// @return | string | Status returned by the most recent tree tick.
        methods.add_method("getLastStatus", |_, this, ()| {
            Ok(this.inner.borrow().last_status.as_str().to_string())
        });

        // -- getDebugState --
        /// Returns a diagnostic snapshot of this behavior tree.
        /// @return | table | Table with node_count and last_status fields.
        methods.add_method("getDebugState", |lua, this, ()| {
            let dbg = this.inner.borrow().debug_state();
            let t = lua.create_table()?;
            t.set("node_count", dbg.node_count as u32)?;
            t.set("last_status", dbg.last_status)?;
            Ok(t)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LBehaviorTree"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches BehaviorTree or Object.
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
        /// @param | child | LBTNode | Child node to append.
        /// @return | nil | No value is returned.
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
        /// @return | integer | Number of direct child nodes.
        methods.add_method("getChildCount", |_, this, ()| {
            Ok(this.inner.borrow().child_count())
        });

        // -- reset --
        /// Resets all running-child memos and repeater counters.
        /// @return | nil | No value is returned.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        // -- setChild --
        /// Sets the single child of a decorator node.
        /// @param | child | LBTNode | Child node to install on the decorator.
        /// @return | nil | No value is returned.
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
        /// @param | n | integer | Repeat count to apply.
        /// @return | nil | No value is returned.
        methods.add_method("setCount", |_, this, n: u32| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Repeater { count, .. } = &mut *node {
                *count = n;
            }
            Ok(())
        });

        // -- getCount --
        /// Returns the repeat count, or 0 if not a Repeater.
        /// @return | integer | Repeat count, or 0 if this node is not a repeater.
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
        /// @param | policy | string | Success policy name to parse.
        /// @return | nil | No value is returned.
        methods.add_method("setSuccessPolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { success_policy, .. } = &mut *node {
                *success_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        // -- setFailurePolicy --
        /// Sets the failure policy for a Parallel node.
        /// @param | policy | string | Failure policy name to parse.
        /// @return | nil | No value is returned.
        methods.add_method("setFailurePolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { failure_policy, .. } = &mut *node {
                *failure_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });

        // -- getNodeType --
        /// Returns the node type as a string.
        /// @return | string | Node type name.
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
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LBTNode"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches BTNode or Object.
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
    // Registry for custom steering behavior Lua callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaSteeringManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeek --
        /// Adds a Seek behavior toward the target.
        /// @param | tx | number | Target x coordinate.
        /// @param | ty | number | Target y coordinate.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | tx | number | Threat x coordinate.
        /// @param | ty | number | Threat y coordinate.
        /// @param | panicDist | number? | Optional panic distance.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | tx | number | Target x coordinate.
        /// @param | ty | number | Target y coordinate.
        /// @param | slowingRadius | number? | Optional slowing radius.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | radius | number? | Optional wander circle radius.
        /// @param | dist | number? | Optional wander circle distance.
        /// @param | jitter | number? | Optional wander jitter amount.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | targetName | string? | Optional target agent name.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | threatName | string? | Optional threat agent name.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | neighborRadius | number? | Optional neighbor search radius.
        /// @param | sepWeight | number? | Optional separation weight.
        /// @param | alignWeight | number? | Optional alignment weight.
        /// @param | cohWeight | number? | Optional cohesion weight.
        /// @param | weight | number? | Optional overall behavior weight.
        /// @return | nil | No value is returned.
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
        /// @return | integer | Number of active steering behaviors.
        methods.add_method("getBehaviorCount", |_, this, ()| {
            Ok(this.inner.borrow().behaviors.len())
        });

        // -- setCombineMode --
        /// Sets the force combination mode.
        /// @param | mode | string | Combination mode name to parse.
        /// @return | nil | No value is returned.
        methods.add_method("setCombineMode", |_, this, mode: String| {
            this.inner.borrow_mut().set_combine_mode_str(&mode);
            Ok(())
        });

        // -- getCombineMode --
        /// Returns the current combination mode.
        /// @return | string | Current steering combination mode name.
        methods.add_method("getCombineMode", |_, this, ()| {
            Ok(this.inner.borrow().combine_mode.as_str().to_string())
        });

        // -- getLastSteering --
        /// Returns the last computed steering force.
        /// @return | number | Last computed force X component.
        /// @return | number | Last computed force Y component.
        methods.add_method("getLastSteering", |_, this, ()| {
            Ok(this.inner.borrow().last_force())
        });

        // -- calculate --
        /// Computes the combined steering force for the given agent state.
        /// @param | px | number | Agent x position.
        /// @param | py | number | Agent y position.
        /// @param | vx | number | Agent velocity x component.
        /// @param | vy | number | Agent velocity y component.
        /// @param | maxSpeed | number | Agent maximum speed.
        /// @param | maxForce | number | Agent maximum steering force.
        /// @param | dt | number | Delta time in seconds.
        /// @return | number | Combined steering force X component.
        /// @return | number | Combined steering force Y component.
        methods.add_method("calculate", |_, this, (px, py, vx, vy, max_speed, max_force, dt): (f32, f32, f32, f32, f32, f32, f32)| {
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

        // -- setPath --
        /// Sets a world-space waypoint path for path-follow steering.
        /// Compatible with path tables returned by `lurek.pathfind.*:findPath(...)`.
        /// @param | waypoints | table | Array of waypoint tables with numeric `x` and `y` fields.
        /// @param | reachRadius | number? | Optional waypoint-reached radius.
        /// @param | weight | number? | Optional path-follow force weight.
        /// @return | nil | No value is returned.
        methods.add_method(
            "setPath",
            |_, this, (waypoints, reach_radius, weight): (LuaTable, Option<f32>, Option<f32>)| {
                let mut out = Vec::new();
                for entry in waypoints.sequence_values::<LuaTable>() {
                    let pt = entry?;
                    let x: f32 = pt.get("x").map_err(|_| {
                        LuaError::RuntimeError(
                            "lurek.ai.SteeringManager:setPath expected waypoint.x".to_string(),
                        )
                    })?;
                    let y: f32 = pt.get("y").map_err(|_| {
                        LuaError::RuntimeError(
                            "lurek.ai.SteeringManager:setPath expected waypoint.y".to_string(),
                        )
                    })?;
                    out.push((x, y));
                }
                this.inner.borrow_mut().set_path(
                    out,
                    reach_radius.unwrap_or(12.0),
                    weight.unwrap_or(1.0),
                );
                Ok(())
            },
        );

        // -- clearPath --
        /// Clears the currently active waypoint path.
        /// @return | nil | No value is returned.
        methods.add_method("clearPath", |_, this, ()| {
            this.inner.borrow_mut().clear_path();
            Ok(())
        });

        // -- hasPath --
        /// Returns true if there is an unfinished waypoint path.
        /// @return | boolean | True when a path is active.
        methods.add_method("hasPath", |_, this, ()| {
            Ok(this.inner.borrow().has_active_path())
        });

        // -- getPathProgress --
        /// Returns path-follow progress.
        /// @return | integer | Current waypoint index (1-based).
        /// @return | integer | Total waypoints in the active path.
        methods.add_method("getPathProgress", |_, this, ()| {
            let (idx, total) = this.inner.borrow().path_progress();
            Ok((idx + 1, total))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LSteeringManager"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches SteeringManager or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SteeringManager" || name == "Object")
        });

        // -- setSpatialHashCellSize --
        /// Sets the cell size used by the spatial-hash neighborhood search.
        /// @param | size | number | Cell size for neighborhood bucketing.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSpatialHashCellSize", |_, this, size: f32| {
            this.inner.borrow_mut().set_cell_size(size);
            Ok(())
        });

        // -- enableSpatialHash --
        /// Enables or disables spatial-hash bucketing for neighbourhood queries.
        /// @param | enabled | boolean | True to enable spatial-hash bucketing.
        /// @return | nil | No value is returned.
        methods.add_method_mut("enableSpatialHash", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_use_spatial_hash(enabled);
            Ok(())
        });

        // -- addCustomBehavior --
        /// Registers a Lua callback as a custom steering behavior.
        /// @param | callback | function | Callback that returns steering x and y components for an agent and dt.
        /// @param | weight | number? | Optional behavior weight.
        /// @return | nil | No value is returned.
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
        /// @param | agent | LAgent | Agent passed to each custom steering callback.
        /// @param | dt | number | Delta time in seconds.
        /// @return | number | Combined force X component.
        /// @return | number | Combined force Y component.
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
// LuaDialogueAI UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`DialogueAI`].
#[derive(Clone)]
struct LuaDialogueAI {
    inner: Rc<RefCell<DialogueAI>>,
}

impl LuaUserData for LuaDialogueAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setFSMState --
        /// Sets current FSM state used by dialogue gating.
        /// @param | state | string? | FSM state name or nil.
        /// @return | nil | No value is returned.
        methods.add_method("setFSMState", |_, this, state: Option<String>| {
            this.inner.borrow_mut().set_fsm_state(state);
            Ok(())
        });

        // -- setBTStatus --
        /// Sets current BT status used by dialogue gating.
        /// @param | status | string? | BT status string or nil.
        /// @return | nil | No value is returned.
        methods.add_method("setBTStatus", |_, this, status: Option<String>| {
            this.inner.borrow_mut().set_bt_status(status);
            Ok(())
        });

        // -- setUtilityScore --
        /// Sets a utility score key used by topic and branch ranking.
        /// @param | key | string | Utility score key.
        /// @param | score | number | Score value.
        /// @return | nil | No value is returned.
        methods.add_method("setUtilityScore", |_, this, (key, score): (String, f32)| {
            this.inner.borrow_mut().set_utility_score(key, score);
            Ok(())
        });

        // -- clearUtilityScores --
        /// Clears all utility score keys.
        /// @return | nil | No value is returned.
        methods.add_method("clearUtilityScores", |_, this, ()| {
            this.inner.borrow_mut().clear_utility_scores();
            Ok(())
        });

        // -- addTopic --
        /// Adds a dialogue topic with optional FSM/BT/utility gates.
        /// @param | id | string | Topic identifier.
        /// @param | weight | number? | Optional base topic weight.
        /// @param | fsmState | string? | Optional required FSM state.
        /// @param | btStatus | string? | Optional required BT status.
        /// @param | utilityKey | string? | Optional utility score key.
        /// @return | nil | No value is returned.
        methods.add_method(
            "addTopic",
            |_,
             this,
             (id, weight, fsm_state, bt_status, utility_key): (
                String,
                Option<f32>,
                Option<String>,
                Option<String>,
                Option<String>,
            )| {
                this.inner.borrow_mut().add_topic(
                    id,
                    weight.unwrap_or(1.0),
                    fsm_state,
                    bt_status,
                    utility_key,
                );
                Ok(())
            },
        );

        // -- addBranch --
        /// Adds a dialogue branch under a topic.
        /// @param | topicId | string | Parent topic id.
        /// @param | branchId | string | Branch identifier.
        /// @param | weight | number? | Optional base branch weight.
        /// @param | fsmState | string? | Optional required FSM state.
        /// @param | btStatus | string? | Optional required BT status.
        /// @param | utilityKey | string? | Optional utility score key.
        /// @return | boolean | True if branch was added.
        methods.add_method(
            "addBranch",
            |_,
             this,
             (topic_id, branch_id, weight, fsm_state, bt_status, utility_key): (
                String,
                String,
                Option<f32>,
                Option<String>,
                Option<String>,
                Option<String>,
            )| {
                Ok(this.inner.borrow_mut().add_branch(
                    &topic_id,
                    branch_id,
                    weight.unwrap_or(1.0),
                    fsm_state,
                    bt_status,
                    utility_key,
                ))
            },
        );

        // -- selectTopic --
        /// Selects the best topic for current context.
        /// @return | string | Selected topic id or nil.
        methods.add_method("selectTopic", |_, this, ()| {
            Ok(this.inner.borrow().select_topic())
        });

        // -- selectBranch --
        /// Selects the best branch under a topic for current context.
        /// @param | topicId | string | Topic identifier.
        /// @return | string | Selected branch id or nil.
        methods.add_method("selectBranch", |_, this, topic_id: String| {
            Ok(this.inner.borrow().select_branch(&topic_id))
        });

        // -- getTopicCount --
        /// Returns number of registered topics.
        /// @return | integer | Topic count.
        methods.add_method("getTopicCount", |_, this, ()| {
            Ok(this.inner.borrow().topic_count())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LDialogueAI"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches DialogueAI or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "DialogueAI" || name == "Object")
        });
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
        /// @param | state | integer | One-based state index.
        /// @return | integer | One-based selected action index.
        methods.add_method("chooseAction", |_, this, state: usize| {
            Ok(this.inner.borrow().choose_action(state.saturating_sub(1)) + 1)
        });

        // -- bestAction --
        /// Returns the greedy-best action for the state (1-based).
        /// @param | state | integer | One-based state index.
        /// @return | integer | One-based greedy action index.
        methods.add_method("bestAction", |_, this, state: usize| {
            Ok(this.inner.borrow().best_action(state.saturating_sub(1)) + 1)
        });

        // -- learn --
        /// Performs one Bellman Q-learning update (1-based indices).
        /// @param | state | integer | One-based current state index.
        /// @param | action | integer | One-based action index.
        /// @param | reward | number | Reward value for the transition.
        /// @param | nextState | integer | One-based next state index.
        /// @return | nil | No value is returned.
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
        /// @param | state | integer | One-based state index.
        /// @param | action | integer | One-based action index.
        /// @return | number | Q-value for the requested state-action pair.
        methods.add_method("getQValue", |_, this, (state, action): (usize, usize)| {
            Ok(this
                .inner
                .borrow()
                .get_q(state.saturating_sub(1), action.saturating_sub(1)))
        });

        // -- setQValue --
        /// Overwrites the Q-value for a state-action pair (1-based).
        /// @param | state | integer | One-based state index.
        /// @param | action | integer | One-based action index.
        /// @param | value | number | Q-value to store.
        /// @return | nil | No value is returned.
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
        /// @return | nil | No value is returned.
        methods.add_method("endEpisode", |_, this, ()| {
            this.inner.borrow_mut().end_episode();
            Ok(())
        });

        // -- getEpisodeCount --
        /// Returns the number of completed episodes.
        /// @return | integer | Number of completed episodes.
        methods.add_method("getEpisodeCount", |_, this, ()| {
            Ok(this.inner.borrow().episode_count)
        });

        // -- getStateCount --
        /// Returns the number of discrete states.
        /// @return | integer | Number of discrete states.
        methods.add_method("getStateCount", |_, this, ()| {
            Ok(this.inner.borrow().state_count)
        });

        // -- getActionCount --
        /// Returns the number of discrete actions.
        /// @return | integer | Number of discrete actions.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().action_count)
        });

        // -- setLearningRate --
        /// Sets the learning rate alpha.
        /// @param | v | number | Learning rate value.
        /// @return | nil | No value is returned.
        methods.add_method("setLearningRate", |_, this, v: f64| {
            this.inner.borrow_mut().alpha = v;
            Ok(())
        });

        // -- getLearningRate --
        /// Returns the current learning rate.
        /// @return | number | Current learning rate.
        methods.add_method("getLearningRate", |_, this, ()| {
            Ok(this.inner.borrow().alpha)
        });

        // -- setDiscountFactor --
        /// Sets the discount factor gamma.
        /// @param | v | number | Discount factor value.
        /// @return | nil | No value is returned.
        methods.add_method("setDiscountFactor", |_, this, v: f64| {
            this.inner.borrow_mut().gamma = v;
            Ok(())
        });

        // -- getDiscountFactor --
        /// Returns the current discount factor.
        /// @return | number | Current discount factor.
        methods.add_method("getDiscountFactor", |_, this, ()| {
            Ok(this.inner.borrow().gamma)
        });

        // -- setExplorationRate --
        /// Sets the exploration rate epsilon.
        /// @param | v | number | Exploration rate value.
        /// @return | nil | No value is returned.
        methods.add_method("setExplorationRate", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon = v;
            Ok(())
        });

        // -- getExplorationRate --
        /// Returns the current exploration rate.
        /// @return | number | Current exploration rate.
        methods.add_method("getExplorationRate", |_, this, ()| {
            Ok(this.inner.borrow().epsilon)
        });

        // -- setExplorationDecay --
        /// Sets the epsilon decay multiplier.
        /// @param | v | number | Exploration decay multiplier.
        /// @return | nil | No value is returned.
        methods.add_method("setExplorationDecay", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon_decay = v;
            Ok(())
        });

        // -- getExplorationDecay --
        /// Returns the epsilon decay multiplier.
        /// @return | number | Exploration decay multiplier.
        methods.add_method("getExplorationDecay", |_, this, ()| {
            Ok(this.inner.borrow().epsilon_decay)
        });

        // -- serialize --
        /// Serializes the Q-table to a JSON string.
        /// @return | string | JSON representation of the Q-table.
        methods.add_method("serialize", |_, this, ()| {
            Ok(this.inner.borrow().serialize())
        });

        // -- deserialize --
        /// Restores the Q-table from a JSON string.
        /// @param | json | string | JSON representation of a Q-table.
        /// @return | nil | No value is returned.
        methods.add_method("deserialize", |_, this, json: String| {
            this.inner
                .borrow_mut()
                .deserialize(&json)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LQLearner"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches QLearner or Object.
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
    // Registry for custom response-curve Lua callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}

impl LuaUserData for LuaUtilityAI {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAction --
        /// Adds a scored action with optional momentum weight.
        /// @param | name | string | Action name to register.
        /// @param | scorer | function | Lua scorer callback for the action.
        /// @param | weight | number? | Optional momentum bonus.
        /// @return | nil | No value is returned.
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
        /// Evaluates all actions and returns the best action name, or nil if none is chosen.
        /// @return | string | Best action name, or nil if none is chosen.
        methods.add_method("evaluate", |lua, this, ()| {
            match this.inner.borrow_mut().evaluate(lua)? {
                Some(name) => Ok(LuaValue::String(lua.create_string(&name)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- getActionCount --
        /// Returns the number of registered actions.
        /// @return | integer | Number of registered actions.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        // -- getLastAction --
        /// Returns the name of the last chosen action, or nil if none has been chosen.
        /// @return | string | Last chosen action name, or nil if none has been chosen.
        methods.add_method("getLastAction", |_, this, ()| {
            let ai = this.inner.borrow();
            Ok(ai.last_action.map(|i| ai.actions[i].name.clone()))
        });

        // -- addConsideration --
        /// Adds a multi-axis consideration to a named action.
        /// @param | actionName | string | Action name that receives the consideration.
        /// @param | name | string | Consideration name.
        /// @param | scorerFn | function | Lua callback that returns the raw consideration value.
        /// @param | curve | any | Curve name string or custom curve callback.
        /// @param | p1 | number? | Optional first curve parameter.
        /// @param | p2 | number? | Optional second curve parameter.
        /// @param | p3 | number? | Optional third curve parameter.
        /// @param | weight | number? | Optional consideration weight.
        /// @return | nil | No value is returned.
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
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LUtilityAI"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches UtilityAI or Object.
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
        /// @param | name | string | Action name to register.
        /// @param | cost | number? | Optional action cost.
        /// @param | callback | function? | Optional Lua callback for the action.
        /// @return | nil | No value is returned.
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
        /// @param | actionName | string | Action name to modify.
        /// @param | key | string | Precondition key.
        /// @param | value | boolean | Precondition value.
        /// @return | nil | No value is returned.
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
        /// @param | actionName | string | Action name to modify.
        /// @param | key | string | Effect key.
        /// @param | value | boolean | Effect value.
        /// @return | nil | No value is returned.
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
        /// @param | name | string | Goal name to register.
        /// @param | priority | number? | Optional goal priority.
        /// @return | nil | No value is returned.
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
        /// @param | goalName | string | Goal name to modify.
        /// @param | key | string | Goal state key.
        /// @param | value | boolean | Goal state value.
        /// @return | nil | No value is returned.
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
        /// @param | worldState | table | Table of boolean world-state flags.
        /// @param | maxDepth | integer? | Optional maximum search depth.
        /// @return | table | Array-style table of planned action names.
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
        /// @return | integer | Number of registered actions.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });

        // -- getGoalCount --
        /// Returns the number of registered goals.
        /// @return | integer | Number of registered goals.
        methods.add_method("getGoalCount", |_, this, ()| {
            Ok(this.inner.borrow().goals.len())
        });

        // -- getMaxIterations --
        /// Returns the maximum A* planning iterations.
        /// @return | integer | Maximum number of planning iterations.
        methods.add_method("getMaxIterations", |_, this, ()| {
            Ok(this.inner.borrow().get_max_iterations() as u64)
        });

        // -- setMaxIterations --
        /// Sets the maximum A* planning iterations (0 = unlimited).
        /// @param | n | integer | Maximum iteration count, or 0 for unlimited.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMaxIterations", |_, this, n: u64| {
            this.inner.borrow_mut().set_max_iterations(n as usize);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LGOAPPlanner"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches GOAPPlanner or Object.
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
        /// @param | name | string | Layer name to add.
        /// @return | nil | No value is returned.
        methods.add_method("addLayer", |_, this, name: String| {
            this.inner.borrow_mut().add_layer(&name);
            Ok(())
        });

        // -- hasLayer --
        /// Returns true if the named layer exists.
        /// @param | name | string | Layer name to check.
        /// @return | boolean | True if the layer exists.
        methods.add_method("hasLayer", |_, this, name: String| {
            Ok(this.inner.borrow().has_layer(&name))
        });

        // -- setInfluence --
        /// Sets the influence value at a cell (1-based).
        /// @param | layer | string | Layer name to write to.
        /// @param | x | integer | One-based cell x coordinate.
        /// @param | y | integer | One-based cell y coordinate.
        /// @param | value | number | Influence value to store.
        /// @return | nil | No value is returned.
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
        /// @param | layer | string | Layer name to read from.
        /// @param | x | integer | One-based cell x coordinate.
        /// @param | y | integer | One-based cell y coordinate.
        /// @return | number | Influence value at the requested cell.
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
        /// @param | layer | string | Layer name to modify.
        /// @param | wx | number | World-space x center.
        /// @param | wy | number | World-space y center.
        /// @param | radius | number | Stamp radius.
        /// @param | value | number | Influence value to stamp.
        /// @param | falloff | number? | Optional radial falloff factor.
        /// @return | nil | No value is returned.
        methods.add_method("stampInfluence", |_, this, (layer, wx, wy, radius, value, falloff): (String, f32, f32, f32, f32, Option<f32>)| {
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
        /// @param | layer | string | Layer name to propagate.
        /// @param | momentum | number? | Optional momentum factor.
        /// @return | nil | No value is returned.
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
        /// @param | layer | string | Layer name to decay.
        /// @param | factor | number | Decay factor to apply.
        /// @return | nil | No value is returned.
        methods.add_method("decay", |_, this, (layer, factor): (String, f32)| {
            this.inner.borrow_mut().decay(&layer, factor);
            Ok(())
        });

        // -- clearLayer --
        /// Clears all influence in a layer.
        /// @param | layer | string | Layer name to clear.
        /// @return | nil | No value is returned.
        methods.add_method("clearLayer", |_, this, layer: String| {
            this.inner.borrow_mut().clear_layer(&layer);
            Ok(())
        });

        // -- clearAll --
        /// Removes all influence values from every layer in the map.
        /// @return | nil | No value is returned.
        methods.add_method("clearAll", |_, this, ()| {
            this.inner.borrow_mut().clear_all();
            Ok(())
        });

        // -- getMaxPosition --
        /// Returns the world-space position of the maximum value.
        /// @param | layer | string | Layer name to query.
        /// @return | number | World-space X position of the maximum value.
        /// @return | number | World-space Y position of the maximum value.
        methods.add_method("getMaxPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().max_position(&layer))
        });

        // -- getMinPosition --
        /// Returns the world-space position of the minimum value.
        /// @param | layer | string | Layer name to query.
        /// @return | number | World-space X position of the minimum value.
        /// @return | number | World-space Y position of the minimum value.
        methods.add_method("getMinPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().min_position(&layer))
        });

        // -- queryRect --
        /// Returns the summed influence in a world-space rectangle.
        /// @param | layer | string | Layer name to query.
        /// @param | wx | number | World-space rectangle x coordinate.
        /// @param | wy | number | World-space rectangle y coordinate.
        /// @param | ww | number | Rectangle width.
        /// @param | wh | number | Rectangle height.
        /// @return | number | Summed influence within the rectangle.
        methods.add_method(
            "queryRect",
            |_, this, (layer, wx, wy, ww, wh): (String, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().query_rect(&layer, wx, wy, ww, wh))
            },
        );

        // -- blend --
        /// Blends two layers into a destination layer.
        /// @param | layerA | string | First source layer name.
        /// @param | weightA | number | Weight for the first source layer.
        /// @param | layerB | string | Second source layer name.
        /// @param | weightB | number | Weight for the second source layer.
        /// @param | dest | string | Destination layer name.
        /// @return | nil | No value is returned.
        methods.add_method("blend", |_, this, (layer_a, weight_a, layer_b, weight_b, dest): (String, f32, String, f32, String)| {
                this.inner.borrow_mut().blend(&layer_a, weight_a, &layer_b, weight_b, &dest);
                Ok(())
            },
        );

        // -- getWidth --
        /// Returns the influence map width in grid cells.
        /// @return | integer | Influence map width in cells.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));

        // -- getHeight --
        /// Returns the influence map height in grid cells.
        /// @return | integer | Influence map height in cells.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));

        // -- getCellSize --
        /// Returns the cell size in world units.
        /// @return | number | Cell size in world units.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LInfluenceMap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches InfluenceMap or Object.
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
        /// @return | string | Squad name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        // -- addMember --
        /// Adds an agent by name to this squad.
        /// @param | name | string | Agent name to add.
        /// @return | nil | No value is returned.
        methods.add_method("addMember", |_, this, name: String| {
            this.inner.borrow_mut().members.push(name);
            Ok(())
        });

        // -- removeMember --
        /// Removes an agent by name from this squad.
        /// @param | name | string | Agent name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeMember", |_, this, name: String| {
            this.inner.borrow_mut().members.retain(|m| m != &name);
            Ok(())
        });

        // -- getMemberCount --
        /// Returns the number of squad members.
        /// @return | integer | Number of squad members.
        methods.add_method("getMemberCount", |_, this, ()| {
            Ok(this.inner.borrow().members.len())
        });

        // -- getMembers --
        /// Returns the member names as a table.
        /// @return | table | Array-style table of squad member names.
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
        /// @param | name | string | Leader agent name.
        /// @return | nil | No value is returned.
        methods.add_method("setLeader", |_, this, name: String| {
            this.inner.borrow_mut().leader = Some(name);
            Ok(())
        });

        // -- getLeader --
        /// Returns the leader name, or nil if no leader is set.
        /// @return | string | Leader name, or nil if no leader is set.
        methods.add_method("getLeader", |_, this, ()| {
            Ok(this.inner.borrow().leader.clone())
        });

        // -- setFormation --
        /// Sets the formation type and optional spacing.
        /// @param | ftype | string | Formation type name.
        /// @param | spacing | number? | Optional formation spacing.
        /// @return | nil | No value is returned.
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
        /// @return | string | Current formation type name.
        methods.add_method("getFormation", |_, this, ()| {
            Ok(this.inner.borrow().formation.as_str().to_string())
        });

        // -- getFormationSpacing --
        /// Returns the formation spacing in world units.
        /// @return | number | Formation spacing in world units.
        methods.add_method("getFormationSpacing", |_, this, ()| {
            Ok(this.inner.borrow().formation_spacing)
        });

        // -- getFormationPosition --
        /// Computes the world-space position for a member index (1-based).
        /// @param | memberIdx | integer | One-based member index.
        /// @param | leaderX | number | Leader x coordinate.
        /// @param | leaderY | number | Leader y coordinate.
        /// @return | number | World-space X position for the member slot.
        /// @return | number | World-space Y position for the member slot.
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
        /// @return | LAIBlackboard | Copy of the squad blackboard at call time.
        methods.add_method("getBlackboard", |_, this, ()| {
            let sq = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(sq.blackboard.clone())),
            })
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LSquad"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches Squad or Object.
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

// Parses optional command options table into (target_x, target_y, priority, interruptible).
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
        /// @param | kind | string | Command type name.
        /// @param | callback | function | Lua callback for the command.
        /// @param | opts | table? | Optional command options table.
        /// @return | nil | No value is returned.
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
        /// @param | kind | string | Command type name.
        /// @param | callback | function | Lua callback for the command.
        /// @param | opts | table? | Optional command options table.
        /// @return | nil | No value is returned.
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
        /// @param | kind | string | Command type name.
        /// @param | callback | function | Lua callback for the command.
        /// @param | opts | table? | Optional command options table.
        /// @return | nil | No value is returned.
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
        /// @return | boolean | True if the current command was canceled.
        methods.add_method("cancelCurrent", |_, this, ()| {
            Ok(this.inner.borrow_mut().cancel_current())
        });

        // -- clear --
        /// Discards all queued commands.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- getCount --
        /// Returns the number of queued commands.
        /// @return | integer | Number of queued commands.
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.borrow().count()));

        // -- isEmpty --
        /// Returns true if there are no queued commands.
        /// @return | boolean | True if the queue is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.borrow().is_empty()));

        // -- getCurrentType --
        /// Returns the kind of the front command, or nil if the queue is empty.
        /// @return | string | Front command kind, or nil if the queue is empty.
        methods.add_method("getCurrentType", |_, this, ()| {
            Ok(this.inner.borrow().current_type().map(|s| s.to_string()))
        });

        // -- getCurrentTarget --
        /// Returns the target coordinates of the front command.
        /// @return | number | Front command target X coordinate.
        /// @return | number | Front command target Y coordinate.
        methods.add_method("getCurrentTarget", |_, this, ()| {
            Ok(this.inner.borrow().current_target())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LCommandQueue"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches CommandQueue or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "CommandQueue" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -- TraitProfile ------------------------------------------------------------

/// Lua wrapper for [`crate::ai::traits::TraitProfile`].
#[derive(Clone)]
struct LuaTraitProfile {
    inner: Rc<RefCell<TraitProfile>>,
}

impl LuaUserData for LuaTraitProfile {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- set --
        /// Sets the base value of this trait, replacing any previous base.
        /// @param | name | string | Trait name to update.
        /// @param | value | number | Base value to store.
        /// @return | nil | No value is returned.
        methods.add_method_mut("set", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set(&name, value);
            Ok(())
        });

        // -- get --
        /// Returns the current float value of this emotion dimension.
        /// @param | name | string | Trait name to read.
        /// @return | number | Current trait value.
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });

        // -- getBase --
        /// Returns the unmodified base value of this trait before modifiers.
        /// @param | name | string | Trait name to read.
        /// @return | number | Stored base value for the trait.
        methods.add_method("getBase", |_, this, name: String| {
            Ok(this.inner.borrow().get_base(&name))
        });

        // -- addModifier --
        /// Adds a named modifier that adjusts the trait value by a delta.
        /// @param | trait_name | string | Trait name to modify.
        /// @param | delta | number | Modifier delta to apply.
        /// @param | duration | number? | Optional modifier duration in seconds.
        /// @param | source | string | Source label for the modifier.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addModifier",
            |_, this, (trait_name, delta, duration, source): (String, f32, Option<f32>, String)| {
                this.inner
                    .borrow_mut()
                    .add_modifier(&trait_name, delta, duration, &source);
                Ok(())
            },
        );

        // -- removeModifiers --
        /// Removes the specified modifiers.
        /// @param | source | string | Source label of the modifiers to remove.
        /// @return | nil | No value is returned.
        methods.add_method_mut("removeModifiers", |_, this, source: String| {
            this.inner.borrow_mut().remove_modifiers_by_source(&source);
            Ok(())
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- has --
        /// Returns true if a item is present.
        /// @param | name | string | Trait name to check.
        /// @return | boolean | True if the trait exists.
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has(&name))
        });

        // -- traitCount --
        /// Returns the number of tracked traits.
        /// @return | number | Number of tracked traits.
        methods.add_method("traitCount", |_, this, ()| {
            Ok(this.inner.borrow().trait_count() as i64)
        });

        // -- archetype --
        /// Returns the current archetype name, or nil if none is set.
        /// @return | string | Archetype name, or nil if none is set.
        methods.add_method("archetype", |_, this, ()| {
            Ok(this.inner.borrow().archetype().map(|s| s.to_string()))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LTraitProfile"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LTraitProfile or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTraitProfile" || name == "Object")
        });
    }
}

// -- StimulusWorld ------------------------------------------------------------

/// Lua wrapper for [`crate::ai::perception::StimulusWorld`].
#[derive(Clone)]
struct LuaStimulusWorld {
    inner: Rc<RefCell<StimulusWorld>>,
}

impl LuaUserData for LuaStimulusWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addVisual --
        /// Adds a visual stimulus at the specified world position with radius and intensity.
        /// @param | x | number | World-space x position.
        /// @param | y | number | World-space y position.
        /// @param | intensity | number | Stimulus intensity.
        /// @param | radius | number | Stimulus radius.
        /// @param | tag | string? | Optional stimulus tag.
        /// @return | integer | Identifier of the created stimulus.
        methods.add_method_mut(
            "addVisual",
            |_, this, (x, y, intensity, radius, tag): (f32, f32, f32, f32, Option<String>)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_visual(x, y, intensity, radius, tag) as i64)
            },
        );

        // -- addAuditory --
        /// Registers an auditory stimulus at a world-space position.
        /// @param | x | number | World-space x position.
        /// @param | y | number | World-space y position.
        /// @param | intensity | number | Stimulus intensity.
        /// @param | radius | number | Stimulus radius.
        /// @param | decay_rate | number | Per-update decay rate.
        /// @param | tag | string? | Optional stimulus tag.
        /// @return | integer | Identifier of the created stimulus.
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

        // -- remove --
        /// Removes the specified item.
        /// @param | id | integer | Stimulus identifier to remove.
        /// @return | boolean | True if a stimulus was removed.
        methods.add_method_mut("remove", |_, this, id: u64| {
            Ok(this.inner.borrow_mut().remove(id))
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- count --
        /// Returns the number of active stimuli.
        /// @return | integer | Number of active stimuli.
        methods.add_method(
            "count",
            |_, this, ()| Ok(this.inner.borrow().count() as i64),
        );

        // -- clear --
        /// Clears all stimuli from the world.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LStimulusWorld"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LStimulusWorld or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStimulusWorld" || name == "Object")
        });
    }
}

// -- ContextSteering ----------------------------------------------------------

/// Lua wrapper for [`crate::ai::context_steering::ContextSteering`].
#[derive(Clone)]
struct LuaContextSteering {
    inner: Rc<RefCell<ContextSteering>>,
}

impl LuaUserData for LuaContextSteering {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeekTarget --
        /// Adds a world-space target that this agent steers towards.
        /// @param | tx | number | Target x coordinate.
        /// @param | ty | number | Target y coordinate.
        /// @param | weight | number | Target weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addSeekTarget",
            |_, this, (tx, ty, weight): (f32, f32, f32)| {
                this.inner.borrow_mut().add_seek_target(tx, ty, weight);
                Ok(())
            },
        );

        // -- addWander --
        /// Adds a wander behavior with jitter and weight to the context steering evaluator.
        /// @param | jitter | number | Wander jitter amount.
        /// @param | weight | number | Behavior weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addWander", |_, this, (jitter, weight): (f32, f32)| {
            this.inner.borrow_mut().add_wander(jitter, weight);
            Ok(())
        });

        // -- addAvoidPoint --
        /// Adds a world-space point that this agent steers away from.
        /// @param | x | number | Avoid point x coordinate.
        /// @param | y | number | Avoid point y coordinate.
        /// @param | radius | number | Avoidance radius.
        /// @param | weight | number | Behavior weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addAvoidPoint",
            |_, this, (x, y, radius, weight): (f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add_avoid_point(x, y, radius, weight);
                Ok(())
            },
        );

        // -- addAvoidBounds --
        /// Registers a rectangular region this agent must avoid.
        /// @param | min_x | number | Minimum x coordinate.
        /// @param | min_y | number | Minimum y coordinate.
        /// @param | max_x | number | Maximum x coordinate.
        /// @param | max_y | number | Maximum y coordinate.
        /// @param | margin | number | Extra avoidance margin.
        /// @param | weight | number | Behavior weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addAvoidBounds", |_, this, (min_x, min_y, max_x, max_y, margin, weight): (f32, f32, f32, f32, f32, f32)| {
            this.inner.borrow_mut().add_avoid_bounds(min_x, min_y, max_x, max_y, margin, weight);
            Ok(())
        });

        // -- clearBehaviors --
        /// Clears all registered context steering behaviors.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearBehaviors", |_, this, ()| {
            this.inner.borrow_mut().clear_behaviors();
            Ok(())
        });

        // -- evaluate --
        /// Evaluates the steering context and returns the chosen direction.
        /// @param | ax | number | Agent x position.
        /// @param | ay | number | Agent y position.
        /// @param | vx | number | Agent velocity x component.
        /// @param | vy | number | Agent velocity y component.
        /// @return | number | Chosen direction X component.
        /// @return | number | Chosen direction Y component.
        methods.add_method_mut(
            "evaluate",
            |_, this, (ax, ay, vx, vy): (f32, f32, f32, f32)| {
                let (dx, dy) = this.inner.borrow_mut().evaluate(ax, ay, vx, vy);
                Ok((dx, dy))
            },
        );

        // -- chosenMagnitude --
        /// Returns the magnitude of the last chosen steering direction.
        /// @return | number | Magnitude of the chosen steering direction.
        methods.add_method("chosenMagnitude", |_, this, ()| {
            Ok(this.inner.borrow().chosen_magnitude())
        });

        // -- slotCount --
        /// Returns the number of steering slots.
        /// @return | integer | Number of steering slots.
        methods.add_method("slotCount", |_, this, ()| {
            Ok(this.inner.borrow().slot_count() as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LContextSteering"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LContextSteering or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LContextSteering" || name == "Object")
        });
    }
}

// -- NeedSystem ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::needs::NeedSystem`].
#[derive(Clone)]
struct LuaNeedSystem {
    inner: Rc<RefCell<NeedSystem>>,
}

impl LuaUserData for LuaNeedSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addNeed --
        /// Registers a new need with the specified name, urgency, and decay rate in the system.
        /// @param | name | string | Need name to register.
        /// @param | decay_rate | number | Per-update decay rate.
        /// @param | urgency_threshold | number | Threshold where the need becomes urgent.
        /// @param | urgency_factor | number | Urgency scaling factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addNeed", |_, this, (name, decay_rate, urgency_threshold, urgency_factor): (String, f32, f32, f32)| {
            this.inner.borrow_mut().add_need(Need::new(&name, decay_rate, urgency_threshold, urgency_factor));
            Ok(())
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- mostUrgent --
        /// Returns the most urgent need name, or nil if no need is urgent.
        /// @return | string | Most urgent need name, or nil if no need is urgent.
        methods.add_method("mostUrgent", |_, this, ()| {
            Ok(this.inner.borrow().most_urgent().map(|s| s.to_string()))
        });

        // -- satisfy --
        /// Satisfies part of a named need.
        /// @param | name | string | Need name to satisfy.
        /// @param | amount | number | Satisfaction amount.
        /// @return | nil | No value is returned.
        methods.add_method_mut("satisfy", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().satisfy(&name, amount);
            Ok(())
        });

        // -- valueOf --
        /// Returns the current value of a named need.
        /// @param | name | string | Need name to read.
        /// @return | number | Current value of the need.
        methods.add_method("valueOf", |_, this, name: String| {
            Ok(this.inner.borrow().value_of(&name))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LNeedSystem"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LNeedSystem or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeedSystem" || name == "Object")
        });
    }
}

// -- AIDirector ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::director::AIDirector`].
#[derive(Clone)]
struct LuaAIDirector {
    inner: Rc<RefCell<AIDirector>>,
}

impl LuaUserData for LuaAIDirector {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- pushEvent --
        /// Pushes a gameplay event with the given intensity to the director for awareness analysis.
        /// @param | intensity | number | Intensity value for the event.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pushEvent", |_, this, intensity: f32| {
            this.inner.borrow_mut().push_event(intensity);
            Ok(())
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- tension --
        /// Returns the current director tension value.
        /// @return | number | Current tension value.
        methods.add_method("tension", |_, this, ()| Ok(this.inner.borrow().tension()));

        // -- phase --
        /// Returns the current pacing phase name.
        /// @return | string | Current pacing phase name.
        methods.add_method("phase", |_, this, ()| {
            Ok(this.inner.borrow().phase_str().to_string())
        });

        // -- spawnRateFactor --
        /// Returns the current spawn rate factor.
        /// @return | number | Current spawn rate factor.
        methods.add_method("spawnRateFactor", |_, this, ()| {
            Ok(this.inner.borrow().spawn_rate_factor())
        });

        // -- lootFactor --
        /// Returns the current loot factor.
        /// @return | number | Current loot factor.
        methods.add_method("lootFactor", |_, this, ()| {
            Ok(this.inner.borrow().loot_factor())
        });

        // -- ambientIntensity --
        /// Returns the current ambient intensity value.
        /// @return | number | Current ambient intensity value.
        methods.add_method("ambientIntensity", |_, this, ()| {
            Ok(this.inner.borrow().ambient_intensity())
        });

        // -- setTension --
        /// Sets the global narrative tension level (0-1 scale).
        /// @param | value | number | Tension value to apply.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTension", |_, this, value: f32| {
            this.inner.borrow_mut().set_tension(value);
            Ok(())
        });

        // -- reset --
        /// Resets the director state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAIDirector"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LAIDirector or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIDirector" || name == "Object")
        });
    }
}

// -- HTNDomain ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::htn::HTNDomain`].
#[derive(Clone)]
struct LuaHTNDomain {
    inner: Rc<RefCell<HTNDomain>>,
}

impl LuaUserData for LuaHTNDomain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addPrimitive --
        /// Registers a primitive HTN task with a direct operator function.
        /// @param | name | string | Primitive task name.
        /// @param | preconditions | table | Array-style table of precondition names.
        /// @param | effects | table | Array-style table of effect names.
        /// @param | effects_clear | table | Array-style table of cleared effect names.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addPrimitive", |_, this, (name, preconds, effects, clears): (String, Vec<String>, Vec<String>, Vec<String>)| {
            let p: Vec<&str> = preconds.iter().map(|s| s.as_str()).collect();
            let e: Vec<&str> = effects.iter().map(|s| s.as_str()).collect();
            let c: Vec<&str> = clears.iter().map(|s| s.as_str()).collect();
            this.inner.borrow_mut().add_primitive(&name, p, e, c);
            Ok(())
        });

        // -- addCompound --
        /// Registers a compound HTN task that decomposes into sub-tasks.
        /// @param | compound_name | string | Compound task name.
        /// @param | methods | table | Array-style table of method definitions.
        /// @return | nil | No value is returned.
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

        // -- plan --
        /// Runs planning and returns the resulting action sequence, or nil if no plan is found.
        /// @param | root_task | string | Root task name to plan from.
        /// @param | state | table | Table of world-state values.
        /// @return | table | Array-style table of planned steps, or nil if no plan is found.
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

        // -- taskCount --
        /// Returns the number of registered tasks.
        /// @return | integer | Number of registered tasks.
        methods.add_method("taskCount", |_, this, ()| {
            Ok(this.inner.borrow().task_count() as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LHTNDomain"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LHTNDomain or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHTNDomain" || name == "Object")
        });
    }
}

// -- MCTSEngine ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::mcts::MCTSEngine`].
#[derive(Clone)]
struct LuaMCTSEngine {
    inner: Rc<RefCell<MCTSEngine>>,
}

impl LuaUserData for LuaMCTSEngine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- search --
        /// Uses Lua closures for game logic. All closures receive/return integer states.
        /// @param | root_state | integer | Root state value for the search.
        /// @param | get_actions | function | Callback that returns available actions for a state.
        /// @param | apply_action | function | Callback that returns the next state for a state and action.
        /// @param | evaluate | function | Callback that returns a score for a state.
        /// @return | integer | Selected action, or nil if no action is found.
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

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LMCTSEngine"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LMCTSEngine or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMCTSEngine" || name == "Object")
        });
    }
}

// -- EmotionModel -------------------------------------------------------------

/// Lua wrapper for [`crate::ai::emotion::EmotionModel`].
#[derive(Clone)]
struct LuaEmotionModel {
    inner: Rc<RefCell<EmotionModel>>,
}

impl LuaUserData for LuaEmotionModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds an emotion category with the given name and initial intensity to the model.
        /// @param | name | string | Emotion name to register.
        /// @param | resting_level | number | Resting value for the emotion.
        /// @param | decay_rate | number | Per-update decay rate.
        /// @param | min_visible | number | Minimum visible threshold.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "add",
            |_, this, (name, rest, decay, min_vis): (String, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add(Emotion::new(&name, rest, decay, min_vis));
                Ok(())
            },
        );

        // -- trigger --
        /// Triggers a named emotion by the given amount.
        /// @param | name | string | Emotion name to trigger.
        /// @param | amount | number | Amount to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("trigger", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().trigger(&name, amount);
            Ok(())
        });

        // -- get --
        /// Returns the current float value of this emotion dimension.
        /// @param | name | string | Emotion name to read.
        /// @return | number | Current emotion value.
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });

        // -- dominant --
        /// Returns the dominant emotion name, or nil if there is none.
        /// @return | string | Dominant emotion name, or nil if there is none.
        methods.add_method("dominant", |_, this, ()| {
            Ok(this.inner.borrow().dominant().map(|s| s.to_string()))
        });

        // -- isActive --
        /// Returns `true` if the emotion dimension is currently active and above threshold.
        /// @param | name | string | Emotion name to check.
        /// @return | boolean | True if the emotion is active.
        methods.add_method("isActive", |_, this, name: String| {
            Ok(this.inner.borrow().is_active(&name))
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- reset --
        /// Resets the emotion model state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LEmotionModel"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LEmotionModel or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LEmotionModel" || name == "Object")
        });
    }
}

// -- ORCASolver ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::orca::ORCASolver`].
#[derive(Clone)]
struct LuaORCASolver {
    inner: Rc<RefCell<ORCASolver>>,
}

impl LuaUserData for LuaORCASolver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAgent --
        /// Adds an ORCA agent at the given position with radius and max speed to the solver.
        /// @param | x | number | Agent x position.
        /// @param | y | number | Agent y position.
        /// @param | radius | number | Agent radius.
        /// @param | max_speed | number | Agent maximum speed.
        /// @return | integer | Index of the created ORCA agent.
        methods.add_method_mut(
            "addAgent",
            |_, this, (x, y, radius, max_speed): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_agent(ORCAAgent::new(x, y, radius, max_speed)) as i64)
            },
        );

        // -- setPreferredVelocity --
        /// Sets the preferred velocity.
        /// @param | index | integer | Agent index to update.
        /// @param | pvx | number | Preferred velocity x component.
        /// @param | pvy | number | Preferred velocity y component.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setPreferredVelocity",
            |_, this, (idx, pvx, pvy): (usize, f32, f32)| {
                if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                    a.preferred_velocity = (pvx, pvy);
                }
                Ok(())
            },
        );

        // -- setPosition --
        /// Sets the agent's current world-space position for ORCA velocity computation.
        /// @param | index | integer | Agent index to update.
        /// @param | x | number | Agent x position.
        /// @param | y | number | Agent y position.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPosition", |_, this, (idx, x, y): (usize, f32, f32)| {
            if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                a.position = (x, y);
            }
            Ok(())
        });

        // -- compute --
        /// Computes safe velocities for all registered agents.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("compute", |_, this, dt: f32| {
            this.inner.borrow_mut().compute(dt);
            Ok(())
        });

        // -- getSafeVelocity --
        /// Returns the safe velocity for an agent.
        /// @param | index | integer | Agent index to query.
        /// @return | number | Safe velocity X component.
        /// @return | number | Safe velocity Y component.
        methods.add_method("getSafeVelocity", |_, this, idx: usize| {
            let solver = this.inner.borrow();
            let v = solver
                .agents
                .get(idx)
                .map(|a| a.safe_velocity)
                .unwrap_or((0.0, 0.0));
            Ok((v.0, v.1))
        });

        // -- agentCount --
        /// Returns the number of registered ORCA agents.
        /// @return | integer | Number of registered ORCA agents.
        methods.add_method("agentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count() as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LORCASolver"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LORCASolver or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LORCASolver" || name == "Object")
        });
    }
}

// -- NeuralNet ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::neural_net::NeuralNet`].
#[derive(Clone)]
struct LuaNeuralNet {
    inner: Rc<RefCell<NeuralNet>>,
}

impl LuaUserData for LuaNeuralNet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds a neural network layer with inputs, outputs, and an activation function.
        /// @param | inputs | integer | Number of input units.
        /// @param | outputs | integer | Number of output units.
        /// @param | activation | string | Activation function name.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addLayer",
            |_, this, (inputs, outputs, activation): (usize, usize, String)| {
                let act = Activation::from_str(&activation);
                this.inner.borrow_mut().add_layer(inputs, outputs, act);
                Ok(())
            },
        );

        // -- forward --
        /// Runs a forward pass through the network.
        /// @param | input | table | Array-style table of input values.
        /// @return | table | Array-style table of output values.
        methods.add_method("forward", |lua, this, input: Vec<f32>| {
            let out = this.inner.borrow().forward(&input);
            let t = lua.create_table()?;
            for (i, v) in out.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });

        // -- setWeights --
        /// Overwrites all connection weights with values from a flat table.
        /// @param | weights | table | Flat array of weight values.
        /// @return | boolean | True if the provided weights were applied.
        methods.add_method_mut("setWeights", |_, this, weights: Vec<f32>| {
            Ok(this.inner.borrow_mut().set_weights(&weights))
        });

        // -- getWeights --
        /// Returns a flat table of all connection weight values in the network.
        /// @return | table | Flat array of all network weights.
        methods.add_method("getWeights", |lua, this, ()| {
            let w = this.inner.borrow().get_weights();
            let t = lua.create_table()?;
            for (i, v) in w.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });

        // -- paramCount --
        /// Returns the number of network parameters.
        /// @return | integer | Number of network parameters.
        methods.add_method("paramCount", |_, this, ()| {
            Ok(this.inner.borrow().param_count() as i64)
        });

        // -- layerCount --
        /// Returns the number of network layers.
        /// @return | integer | Number of network layers.
        methods.add_method("layerCount", |_, this, ()| {
            Ok(this.inner.borrow().layer_count() as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LNeuralNet"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LNeuralNet or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuralNet" || name == "Object")
        });
    }
}

// -- GeneticAlgorithm ---------------------------------------------------------

/// Lua wrapper for [`crate::ai::genetic::GeneticAlgorithm`].
#[derive(Clone)]
struct LuaGeneticAlgorithm {
    inner: Rc<RefCell<GeneticAlgorithm>>,
}

impl LuaUserData for LuaGeneticAlgorithm {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evolve --
        /// Runs one generation of the evolutionary algorithm.
        /// @return | nil | No value is returned.
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });

        // -- generation --
        /// Returns the current generation number.
        /// @return | integer | Current generation number.
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });

        // -- popSize --
        /// Returns the population size.
        /// @return | integer | Population size.
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });

        // -- setFitness --
        /// Sets the fitness score used by the genetic algorithm selection step.
        /// @param | index | integer | Chromosome index to update.
        /// @param | fitness | number | Fitness score to store.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            if let Some(c) = this.inner.borrow_mut().population.get_mut(idx) {
                c.fitness = fitness;
            }
            Ok(())
        });

        // -- getGenes --
        /// Returns the chromosome as an ordered table of gene values.
        /// @param | index | integer | Chromosome index to read.
        /// @return | table | Array-style table of gene values.
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

        // -- bestGenes --
        /// Returns the genes from the best chromosome.
        /// @return | table | Array-style table of gene values from the best chromosome.
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

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LGeneticAlgorithm"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LGeneticAlgorithm or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGeneticAlgorithm" || name == "Object")
        });
    }
}

// -- Bandit --------------------------------------------------------------------

/// Lua wrapper for [`crate::ai::bandit::Bandit`].
#[derive(Clone)]
struct LuaBandit {
    inner: Rc<RefCell<Bandit>>,
}

impl LuaUserData for LuaBandit {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- select --
        /// Selects an arm index using the current bandit strategy.
        /// @return | integer | Selected arm index.
        methods.add_method_mut("select", |_, this, ()| {
            Ok(this.inner.borrow_mut().select() as i64)
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | index | integer | Arm index to update.
        /// @param | reward | number | Reward observed for the arm.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, (idx, reward): (usize, f64)| {
            this.inner.borrow_mut().update(idx, reward);
            Ok(())
        });

        // -- bestArm --
        /// Returns the best arm index.
        /// @return | integer | Best arm index.
        methods.add_method("bestArm", |_, this, ()| {
            Ok(this.inner.borrow().best_arm() as i64)
        });

        // -- reset --
        /// Resets learned rewards, pull counts, and strategy state so the bandit behaves like a fresh instance.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        // -- armCount --
        /// Returns the number of arms.
        /// @return | integer | Number of bandit arms.
        methods.add_method("armCount", |_, this, ()| {
            Ok(this.inner.borrow().arm_count() as i64)
        });

        // -- totalPulls --
        /// Returns the total number of pulls.
        /// @return | integer | Total number of pulls.
        methods.add_method("totalPulls", |_, this, ()| {
            Ok(this.inner.borrow().total_pulls as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LBandit"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LBandit or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBandit" || name == "Object")
        });
    }
}

// -- Neuroevolution -----------------------------------------------------------

/// Lua wrapper for [`crate::ai::neuroevolution::Neuroevolution`].
#[derive(Clone)]
struct LuaNeuroevolution {
    inner: Rc<RefCell<Neuroevolution>>,
}

impl LuaUserData for LuaNeuroevolution {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evolve --
        /// Runs one generation of the evolutionary algorithm.
        /// @return | nil | No value is returned.
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });

        // -- setFitness --
        /// Sets the fitness score used by the genetic algorithm selection step.
        /// @param | index | integer | Chromosome index to update.
        /// @param | fitness | number | Fitness score to store.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            this.inner.borrow_mut().set_fitness(idx, fitness);
            Ok(())
        });

        // -- chromosomeToNet --
        /// Returns the neural network built from a chromosome, or nil if the index is invalid.
        /// @param | index | integer | Chromosome index to convert.
        /// @return | LNeuralNet | Neural network built from the chromosome, or nil if the index is invalid.
        methods.add_method("chromosomeToNet", |_, this, idx: usize| {
            let net = this.inner.borrow().chromosome_to_net(idx);
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });

        // -- bestNetwork --
        /// Returns the best neural network, or nil if no network is available.
        /// @return | LNeuralNet | Best neural network, or nil if no network is available.
        methods.add_method("bestNetwork", |_, this, ()| {
            let net = this.inner.borrow().best_network();
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });

        // -- bestFitness --
        /// Returns the best fitness score.
        /// @return | number | Best fitness score.
        methods.add_method("bestFitness", |_, this, ()| {
            Ok(this.inner.borrow().best_fitness())
        });

        // -- popSize --
        /// Returns the population size.
        /// @return | integer | Population size.
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });

        // -- generation --
        /// Returns the current generation number.
        /// @return | integer | Current generation number.
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LNeuroevolution"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LNeuroevolution or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuroevolution" || name == "Object")
        });
    }
}

// -- StrategyAI ----------------------------------------------------------------

/// Lua wrapper for [`crate::ai::strategy::StrategyAI`].
#[derive(Clone)]
struct LuaStrategyAI {
    inner: Rc<RefCell<StrategyAI>>,
}

impl LuaUserData for LuaStrategyAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addGoal --
        /// Adds a strategic goal with priority score to the planner for future evaluation.
        /// @param | name | string | Goal name to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addGoal", |_, this, name: String| {
            this.inner.borrow_mut().add_goal_named(&name);
            Ok(())
        });

        // -- addTag --
        /// Adds a string tag to the strategy AI instance for goal filtering and categorization.
        /// @param | tag | string | Tag to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(&tag);
            Ok(())
        });

        // -- removeTag --
        /// Removes the specified tag.
        /// @param | tag | string | Tag to remove.
        /// @return | nil | No value is returned.
        methods.add_method_mut("removeTag", |_, this, tag: String| {
            this.inner.borrow_mut().remove_tag(&tag);
            Ok(())
        });

        // -- update --
        /// Advances the simulation by one time step.
        /// @param | dt | number | Delta time in seconds.
        /// @param | scorer | function | Callback that scores a goal name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, (dt, scorer_fn): (f32, LuaFunction)| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().update(dt, &mut scorer);
            Ok(())
        });

        // -- forceEvaluate --
        /// Forces an immediate strategy evaluation.
        /// @param | scorer | function | Callback that scores a goal name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("forceEvaluate", |_, this, scorer_fn: LuaFunction| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().force_evaluate(&mut scorer);
            Ok(())
        });

        // -- activeGoal --
        /// Returns the active goal name, or nil if no goal is active.
        /// @return | string | Active goal name, or nil if no goal is active.
        methods.add_method("activeGoal", |_, this, ()| {
            Ok(this.inner.borrow().active_goal().map(|s| s.to_string()))
        });

        // -- timeUntilNext --
        /// Returns the time until the next scheduled evaluation.
        /// @return | number | Time until the next scheduled evaluation.
        methods.add_method("timeUntilNext", |_, this, ()| {
            Ok(this.inner.borrow().time_until_next())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LStrategyAI"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LStrategyAI or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStrategyAI" || name == "Object")
        });
    }
}

// -- AILod ---------------------------------------------------------------------

/// Lua wrapper for [`crate::ai::lod::AILod`].
#[derive(Clone)]
struct LuaAILod {
    inner: Rc<RefCell<AILod>>,
}

impl LuaUserData for LuaAILod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tierFor --
        /// Returns the LOD tier for an agent relative to a reference position.
        /// @param | agent_x | number | Agent x position.
        /// @param | agent_y | number | Agent y position.
        /// @param | ref_x | number | Reference x position.
        /// @param | ref_y | number | Reference y position.
        /// @return | integer | LOD tier index.
        methods.add_method(
            "tierFor",
            |_, this, (ax, ay, rx, ry): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().tier_for((ax, ay), (rx, ry)) as i64)
            },
        );

        // -- shouldUpdate --
        /// Returns whether a tier should update on a frame.
        /// @param | tier | integer | LOD tier index.
        /// @param | frame_number | integer | Current frame number.
        /// @return | boolean | True if the tier should update on the frame.
        methods.add_method("shouldUpdate", |_, this, (tier, frame): (usize, u64)| {
            Ok(this.inner.borrow().should_update(tier, frame))
        });

        // -- tierCount --
        /// Returns the number of LOD tiers.
        /// @return | integer | Number of LOD tiers.
        methods.add_method("tierCount", |_, this, ()| {
            Ok(this.inner.borrow().tier_count() as i64)
        });

        // -- tierName --
        /// Returns the name of a tier.
        /// @param | tier | integer | LOD tier index.
        /// @return | string | Tier name, or nil if the tier is missing.
        methods.add_method("tierName", |_, this, tier: usize| {
            Ok(this.inner.borrow().tier(tier).map(|t| t.name.clone()))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Type name for this userdata.
        methods.add_method("type", |_, _, ()| Ok("LAILod"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True if the type matches LAILod or Object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAILod" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------

/// Registers the `lurek.ai` API table with the Lua VM.
/// @param | lua | Lua | Lua state that receives the module.
/// @param | lurek | table | Root `lurek` table.
/// @param | _state | SharedState | Shared engine state handle.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newWorld --
    /// Creates a new AI world container.
    /// @return | LAIWorld | New AI world userdata.
    tbl.set(
        "newWorld",
        lua.create_function(|_, ()| {
            Ok(LuaAIWorld {
                inner: Rc::new(RefCell::new(AIWorld::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // -- newBlackboard --
    /// Creates a new standalone blackboard.
    /// @return | LAIBlackboard | New blackboard userdata.
    tbl.set(
        "newBlackboard",
        lua.create_function(|_, ()| {
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(Blackboard::new())),
            })
        })?,
    )?;

    // -- newStateMachine --
    /// Creates a new finite state machine.
    /// @return | LStateMachine | New state machine userdata.
    tbl.set(
        "newStateMachine",
        lua.create_function(|_, ()| {
            Ok(LuaStateMachine {
                inner: Rc::new(RefCell::new(crate::ai::StateMachine::new())),
            })
        })?,
    )?;

    // -- newBehaviorTree --
    /// Creates a new behavior tree.
    /// @return | LBehaviorTree | New behavior tree userdata.
    tbl.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                inner: Rc::new(RefCell::new(BehaviorTree::new())),
            })
        })?,
    )?;

    // -- newSelector --
    /// Creates a BT selector node.
    /// @return | LBTNode | New selector node userdata.
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

    // -- newSequence --
    /// Creates a BT sequence node.
    /// @return | LBTNode | New sequence node userdata.
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

    // -- newParallel --
    /// Creates a BT parallel node with optional policies.
    /// @param | successPolicy | string? | Optional success policy name.
    /// @param | failurePolicy | string? | Optional failure policy name.
    /// @return | LBTNode | New parallel node userdata.
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

    // -- newInverter --
    /// Creates a BT inverter decorator.
    /// @return | LBTNode | New inverter node userdata.
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

    // -- newRepeater --
    /// Creates a BT repeater decorator.
    /// @param | count | integer? | Optional repeat count.
    /// @return | LBTNode | New repeater node userdata.
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

    // -- newSucceeder --
    /// Creates a BT succeeder decorator.
    /// @return | LBTNode | New succeeder node userdata.
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

    // -- newAction --
    /// Creates a BT action leaf with a Lua callback.
    /// @param | callback | function | Action callback invoked by the node.
    /// @return | LBTNode | New action node userdata.
    tbl.set(
        "newAction",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Action { callback: key })),
            })
        })?,
    )?;

    // -- newCondition --
    /// Creates a BT condition leaf with a Lua predicate.
    /// @param | callback | function | Predicate callback invoked by the node.
    /// @return | LBTNode | New condition node userdata.
    tbl.set(
        "newCondition",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Condition { callback: key })),
            })
        })?,
    )?;

    // -- newGuard --
    /// Creates a BT guard decorator.
    /// @param | predicate | function | Predicate callback invoked with agent and blackboard.
    /// @param | child | LBTNode | Child node guarded by the predicate.
    /// @return | LBTNode | New guard node userdata.
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

    // -- newSteeringManager --
    /// Creates a new steering behavior manager.
    /// @return | LSteeringManager | New steering manager userdata.
    tbl.set(
        "newSteeringManager",
        lua.create_function(|_, ()| {
            Ok(LuaSteeringManager {
                inner: Rc::new(RefCell::new(SteeringManager::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // -- newQLearner --
    /// Creates a tabular Q-learner.
    /// @param | stateCount | integer | Number of discrete states.
    /// @param | actionCount | integer | Number of discrete actions.
    /// @return | LQLearner | New Q-learner userdata.
    tbl.set(
        "newQLearner",
        lua.create_function(|_, (sc, ac): (usize, usize)| {
            Ok(LuaQLearner {
                inner: Rc::new(RefCell::new(QLearner::new(sc, ac))),
            })
        })?,
    )?;

    // -- newUtilityAI --
    /// Creates a new utility AI evaluator.
    /// @return | LUtilityAI | New utility AI userdata.
    tbl.set(
        "newUtilityAI",
        lua.create_function(|_, ()| {
            Ok(LuaUtilityAI {
                inner: Rc::new(RefCell::new(UtilityAI::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;

    // -- newDialogueAI --
    /// Creates a dialogue AI selector that combines FSM/BT/Utility signals.
    /// @return | LDialogueAI | New dialogue AI userdata.
    tbl.set(
        "newDialogueAI",
        lua.create_function(|_, ()| {
            Ok(LuaDialogueAI {
                inner: Rc::new(RefCell::new(DialogueAI::new())),
            })
        })?,
    )?;

    // -- newGOAPPlanner --
    /// Creates a new GOAP planning solver.
    /// @return | LGOAPPlanner | New GOAP planner userdata.
    tbl.set(
        "newGOAPPlanner",
        lua.create_function(|_, ()| {
            Ok(LuaGOAPPlanner {
                inner: Rc::new(RefCell::new(GOAPPlanner::new())),
            })
        })?,
    )?;

    // -- newInfluenceMap --
    /// Creates a multi-layer influence map grid.
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @param | cellSize | number | Cell size in world units.
    /// @return | LInfluenceMap | New influence map userdata.
    tbl.set(
        "newInfluenceMap",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaInfluenceMap {
                inner: Rc::new(RefCell::new(InfluenceMap::new(w, h, cs))),
            })
        })?,
    )?;

    // -- newSquad --
    /// Creates a named squad for formation positioning.
    /// @param | name | string | Squad name.
    /// @return | LSquad | New squad userdata.
    tbl.set(
        "newSquad",
        lua.create_function(|_, name: String| {
            Ok(LuaSquad {
                inner: Rc::new(RefCell::new(Squad::new(&name))),
            })
        })?,
    )?;

    // -- newCommandQueue --
    /// Creates an RTS-style command queue.
    /// @return | LCommandQueue | New command queue userdata.
    tbl.set(
        "newCommandQueue",
        lua.create_function(|_, ()| {
            Ok(LuaCommandQueue {
                inner: Rc::new(RefCell::new(CommandQueue::new())),
            })
        })?,
    )?;

    // -- newTraitProfile --
    /// Creates a new personality trait profile.
    /// @return | LTraitProfile | New trait profile userdata.
    tbl.set(
        "newTraitProfile",
        lua.create_function(|_, ()| {
            Ok(LuaTraitProfile {
                inner: Rc::new(RefCell::new(TraitProfile::new())),
            })
        })?,
    )?;

    // -- newStimulusWorld --
    /// Creates a new stimulus perception world.
    /// @return | LStimulusWorld | New stimulus world userdata.
    tbl.set(
        "newStimulusWorld",
        lua.create_function(|_, ()| {
            Ok(LuaStimulusWorld {
                inner: Rc::new(RefCell::new(StimulusWorld::new())),
            })
        })?,
    )?;

    // -- newContextSteering --
    /// Creates a new context steering controller.
    /// @param | slots | integer | Number of steering slots to create.
    /// @return | LContextSteering | New context steering userdata.
    tbl.set(
        "newContextSteering",
        lua.create_function(|_, slots: usize| {
            let slots = if slots == 0 { 16 } else { slots };
            Ok(LuaContextSteering {
                inner: Rc::new(RefCell::new(ContextSteering::new(slots))),
            })
        })?,
    )?;

    // -- newNeedSystem --
    /// Creates a new motivational need system.
    /// @return | LNeedSystem | New need system userdata.
    tbl.set(
        "newNeedSystem",
        lua.create_function(|_, ()| {
            Ok(LuaNeedSystem {
                inner: Rc::new(RefCell::new(NeedSystem::new())),
            })
        })?,
    )?;

    // -- newAIDirector --
    /// Creates a new AI pacing director with default config.
    /// @return | LAIDirector | New AI director userdata.
    tbl.set(
        "newAIDirector",
        lua.create_function(|_, ()| {
            Ok(LuaAIDirector {
                inner: Rc::new(RefCell::new(AIDirector::new())),
            })
        })?,
    )?;

    // -- newHTNDomain --
    /// Creates a new Hierarchical Task Network domain.
    /// @return | LHTNDomain | New HTN domain userdata.
    tbl.set(
        "newHTNDomain",
        lua.create_function(|_, ()| {
            Ok(LuaHTNDomain {
                inner: Rc::new(RefCell::new(HTNDomain::new())),
            })
        })?,
    )?;

    // -- newMCTSEngine --
    /// Creates a new Monte Carlo Tree Search engine.
    /// @param | iterations | integer | Number of MCTS iterations.
    /// @param | uct_c | number | UCT exploration constant.
    /// @param | rollout_depth | integer | Maximum rollout depth.
    /// @param | seed | integer | Random seed value.
    /// @return | LMCTSEngine | New MCTS engine userdata.
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

    // -- newEmotionModel --
    /// Creates a new affective emotion model.
    /// @return | LEmotionModel | New emotion model userdata.
    tbl.set(
        "newEmotionModel",
        lua.create_function(|_, ()| {
            Ok(LuaEmotionModel {
                inner: Rc::new(RefCell::new(EmotionModel::new())),
            })
        })?,
    )?;

    // -- newORCASolver --
    /// Creates a new ORCA crowd avoidance solver.
    /// @param | time_horizon | number | Time horizon for ORCA avoidance.
    /// @return | LORCASolver | New ORCA solver userdata.
    tbl.set(
        "newORCASolver",
        lua.create_function(|_, time_horizon: f32| {
            Ok(LuaORCASolver {
                inner: Rc::new(RefCell::new(ORCASolver::new(time_horizon))),
            })
        })?,
    )?;

    // -- newNeuralNet --
    /// Creates a new feedforward neural network (inference only).
    /// @return | LNeuralNet | New neural network userdata.
    tbl.set(
        "newNeuralNet",
        lua.create_function(|_, ()| {
            Ok(LuaNeuralNet {
                inner: Rc::new(RefCell::new(NeuralNet::new())),
            })
        })?,
    )?;

    // -- newGeneticAlgorithm --
    /// Creates a new genetic algorithm.
    /// @param | pop_size | integer | Population size.
    /// @param | gene_count | integer | Number of genes per chromosome.
    /// @param | seed | integer | Random seed value.
    /// @return | LGeneticAlgorithm | New genetic algorithm userdata.
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

    // -- newBandit --
    /// Creates a new multi-armed bandit.
    /// @param | arm_count | integer | Number of bandit arms.
    /// @param | strategy | string | Strategy name such as epsilon_greedy, ucb1, or thompson.
    /// @param | epsilon | number | Epsilon value used by epsilon_greedy.
    /// @param | seed | integer | Random seed value.
    /// @return | LBandit | New bandit userdata.
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

    // -- newNeuroevolution --
    /// Creates a neuroevolution trainer (GA for neural network weights).
    /// @param | layer_spec | table | Array-style table of layer definitions.
    /// @param | pop_size | integer | Population size.
    /// @param | seed | integer | Random seed value.
    /// @return | LNeuroevolution | New neuroevolution userdata.
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

    // -- newStrategyAI --
    /// Creates a new throttled strategy AI.
    /// @param | update_interval | number | Seconds between re-evaluations.
    /// @return | LStrategyAI | New strategy AI userdata.
    tbl.set(
        "newStrategyAI",
        lua.create_function(|_, update_interval: f32| {
            Ok(LuaStrategyAI {
                inner: Rc::new(RefCell::new(StrategyAI::new(update_interval))),
            })
        })?,
    )?;

    // -- newAILod --
    /// Creates a new AI LOD controller with default 3-tier config.
    /// @return | LAILod | New AI LOD userdata.
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
