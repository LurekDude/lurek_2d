//! `lurek.ai` - Lua bindings for AI worlds, agents, blackboards, behavior trees, steering, planning, learning, and simulation helpers.

use super::SharedState;
use crate::ai::{
    AIDirector, AILod, AIWorld, Activation, BTNode, Bandit, BanditStrategy, BehaviorTree,
    Blackboard, CommandQueue, Consideration, ContextSteering, DecisionModel, DialogueAI, Emotion,
    EmotionModel, FormationType, GOAPAction, GOAPGoal, GOAPPlanner, GeneticAlgorithm, HTNDomain,
    HTNMethod, HTNPlanner, MCTSConfig, MCTSEngine, Need, NeedSystem, NeuralNet, Neuroevolution,
    ORCAAgent, ORCASolver, ParallelPolicy, QLearner, ResponseCurve, Squad, SteeringManager,
    StimulusWorld, StrategyAI, TraitProfile, UAAction, UtilityAI, WorldState,
};
use crate::lua_api::callback_registry::CallbackRegistry;
use crate::pathfind::InfluenceMap;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Lua handle for an AI world that owns named agents, global blackboard data, and custom callback registrations.
#[derive(Clone)]
struct LuaAIWorld {
    /// Shared AI world state used by every world, agent, and blackboard wrapper cloned from this handle.
    inner: Rc<RefCell<AIWorld>>,
    /// Registry of Lua callbacks used by custom agent decision models created through this world.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaAIWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAgent --
        /// Creates a named agent in this world and returns a handle that can edit its movement and decision state.
        /// @param | name | string | Unique agent name used by later lookup, tags, custom callbacks, and squad membership references.
        /// @return | LAgent | Lua handle for the newly inserted agent.
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
        /// Returns the named agent handle when it exists in this world.
        /// @param | name | string | Agent name previously passed to `addAgent`.
        /// @return | LuaValue | Agent handle when found, or nil when the world has no agent with that name.
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
        /// Removes an agent from this world by using an existing agent handle.
        /// @param | agent | LAgent | Agent handle whose stored name identifies the world entry to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeAgent", |_, this, agent: LuaAnyUserData| {
            let a = agent.borrow::<LuaAgent>()?;
            this.inner.borrow_mut().remove_agent(&a.name);
            Ok(())
        });
        // -- getAgentCount --
        /// Returns the number of agents currently stored in this world.
        /// @return | integer | Current agent count.
        methods.add_method("getAgentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count())
        });
        // -- getGlobalBlackboard --
        /// Returns a blackboard snapshot containing the world's shared AI facts.
        /// @return | LAIBlackboard | Blackboard handle initialized from the world's global blackboard values at call time.
        methods.add_method("getGlobalBlackboard", |_, this, ()| {
            let w = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(w.global_blackboard().clone())),
            })
        });
        // -- update --
        /// Advances the world simulation and invokes custom decision callbacks for agents that use a custom model.
        /// @param | dt | number | Elapsed simulation time in seconds for this update step.
        /// @return | nil | No value is returned.
        methods.add_method("update", |lua, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
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
        /// Returns the Lua-visible type name for this AI world handle.
        /// @return | string | The string `LAIWorld`.
        methods.add_method("type", |_, _, ()| Ok("LAIWorld"));
        // -- typeOf --
        /// Returns whether this AI world handle matches a supported type name.
        /// @param | name | string | Type name to compare against `AIWorld` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIWorld" || name == "Object")
        });
    }
}
/// Lua handle for a named agent stored inside an AI world.
#[derive(Clone)]
struct LuaAgent {
    /// Shared world containing the agent entry referenced by `name`.
    world: Rc<RefCell<AIWorld>>,
    /// Stable agent name used to find the current world entry on each method call.
    name: String,
    /// Registry used when this agent installs a Lua callback as its decision model.
    callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns this agent's stable world name.
        /// @return | string | Agent name stored in the handle.
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        // -- setPosition --
        /// Sets this agent's world position when the agent still exists in its world.
        /// @param | x | number | New X position in world units.
        /// @param | y | number | New Y position in world units.
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].position = (x, y);
            }
            Ok(())
        });
        // -- getPosition --
        /// Returns this agent's world position or the origin when the agent has been removed.
        /// @return | number, number | X and Y position in world units.
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].position)
            } else {
                Ok((0.0, 0.0))
            }
        });
        // -- setVelocity --
        /// Sets this agent's velocity vector when the agent still exists in its world.
        /// @param | x | number | New X velocity in world units per second.
        /// @param | y | number | New Y velocity in world units per second.
        /// @return | nil | No value is returned.
        methods.add_method("setVelocity", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].velocity = (x, y);
            }
            Ok(())
        });
        // -- getVelocity --
        /// Returns this agent's velocity vector or zero velocity when the agent has been removed.
        /// @return | number, number | X and Y velocity in world units per second.
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].velocity)
            } else {
                Ok((0.0, 0.0))
            }
        });
        // -- setMaxSpeed --
        /// Sets this agent's maximum movement speed when the agent still exists in its world.
        /// @param | v | number | Maximum speed in world units per second.
        /// @return | nil | No value is returned.
        methods.add_method("setMaxSpeed", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_speed = v;
            }
            Ok(())
        });
        // -- getMaxSpeed --
        /// Returns this agent's maximum movement speed or the default speed for a missing agent.
        /// @return | number | Maximum speed in world units per second.
        methods.add_method("getMaxSpeed", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_speed)
            } else {
                Ok(100.0)
            }
        });
        // -- setMaxForce --
        /// Sets this agent's maximum steering force when the agent still exists in its world.
        /// @param | v | number | Maximum steering force applied during steering calculations.
        /// @return | nil | No value is returned.
        methods.add_method("setMaxForce", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_force = v;
            }
            Ok(())
        });
        // -- getMaxForce --
        /// Returns this agent's maximum steering force or the default force for a missing agent.
        /// @return | number | Maximum steering force value.
        methods.add_method("getMaxForce", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_force)
            } else {
                Ok(200.0)
            }
        });
        // -- setPriority --
        /// Sets this agent's integer priority when the agent still exists in its world.
        /// @param | p | integer | Priority value used by game-side AI scheduling or ordering logic.
        /// @return | nil | No value is returned.
        methods.add_method("setPriority", |_, this, p: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].priority = p;
            }
            Ok(())
        });
        // -- getPriority --
        /// Returns this agent's integer priority or zero when the agent has been removed.
        /// @return | integer | Current priority value.
        methods.add_method("getPriority", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].priority)
            } else {
                Ok(0)
            }
        });
        // -- setDecisionModel --
        /// Sets this agent's built-in decision model from a string name when the name is recognized.
        /// @param | model | string | Decision model name such as `fsm`, `bt`, `utility`, or another engine-supported model string.
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
        /// Returns this agent's decision model name or the default model name for a missing agent.
        /// @return | string | Current decision model name.
        methods.add_method("getDecisionModel", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].decision_model.as_str().to_string())
            } else {
                Ok("fsm".to_string())
            }
        });
        // -- setCustomModel --
        /// Installs a Lua callback as this agent's decision model and stores it in the callback registry.
        /// @param | callback | function | Function called during world updates with `(agent, blackboard, dt)` for this agent.
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
        /// Adds a tag string to this agent when the agent still exists in its world.
        /// @param | tag | string | Tag name to insert into the agent tag set.
        /// @return | nil | No value is returned.
        methods.add_method("addTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.insert(tag);
            }
            Ok(())
        });
        // -- removeTag --
        /// Removes a tag string from this agent when the agent still exists in its world.
        /// @param | tag | string | Tag name to remove from the agent tag set.
        /// @return | nil | No value is returned.
        methods.add_method("removeTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.remove(&tag);
            }
            Ok(())
        });
        // -- hasTag --
        /// Returns whether this agent currently has the given tag.
        /// @param | tag | string | Tag name to check in the agent tag set.
        /// @return | boolean | True when the tag exists on the agent.
        methods.add_method("hasTag", |_, this, tag: String| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].tags.contains(&tag))
            } else {
                Ok(false)
            }
        });
        // -- getBlackboard --
        /// Returns a blackboard snapshot for this agent or an empty blackboard when the agent has been removed.
        /// @return | LAIBlackboard | Blackboard handle initialized from the agent's local blackboard values at call time.
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
        /// Returns the Lua-visible type name for this agent handle.
        /// @return | string | The string `LAgent`.
        methods.add_method("type", |_, _, ()| Ok("LAgent"));
        // -- typeOf --
        /// Returns whether this agent handle matches a supported type name.
        /// @param | name | string | Type name to compare against `Agent` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Agent" || name == "Object")
        });
    }
}
/// Lua handle for a typed AI blackboard storing local key-value facts.
#[derive(Clone)]
struct LuaAIBlackboard {
    /// Shared blackboard values exposed through typed setter and getter methods.
    inner: Rc<RefCell<Blackboard>>,
}
impl LuaUserData for LuaAIBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setNumber --
        /// Stores a numeric fact under the given blackboard key.
        /// @param | key | string | Blackboard key to write.
        /// @param | value | number | Numeric value stored for later numeric reads.
        /// @return | nil | No value is returned.
        methods.add_method("setNumber", |_, this, (key, value): (String, f64)| {
            this.inner.borrow_mut().set_number(&key, value);
            Ok(())
        });
        // -- getNumber --
        /// Returns a numeric blackboard fact or the provided fallback when the key is missing or not numeric.
        /// @param | key | string | Blackboard key to read.
        /// @param | default | number? | Fallback value used when the key has no numeric entry; defaults to zero.
        /// @return | number | Stored numeric value or fallback value.
        methods.add_method(
            "getNumber",
            |_, this, (key, default): (String, Option<f64>)| {
                Ok(this.inner.borrow().get_number(&key, default.unwrap_or(0.0)))
            },
        );
        // -- setBool --
        /// Stores a boolean fact under the given blackboard key.
        /// @param | key | string | Blackboard key to write.
        /// @param | value | boolean | Boolean value stored for later boolean reads.
        /// @return | nil | No value is returned.
        methods.add_method("setBool", |_, this, (key, value): (String, bool)| {
            this.inner.borrow_mut().set_bool(&key, value);
            Ok(())
        });
        // -- getBool --
        /// Returns a boolean blackboard fact or the provided fallback when the key is missing or not boolean.
        /// @param | key | string | Blackboard key to read.
        /// @param | default | boolean? | Fallback value used when the key has no boolean entry; defaults to false.
        /// @return | boolean | Stored boolean value or fallback value.
        methods.add_method(
            "getBool",
            |_, this, (key, default): (String, Option<bool>)| {
                Ok(this.inner.borrow().get_bool(&key, default.unwrap_or(false)))
            },
        );
        // -- setString --
        /// Stores a string fact under the given blackboard key.
        /// @param | key | string | Blackboard key to write.
        /// @param | value | string | String value stored for later string reads.
        /// @return | nil | No value is returned.
        methods.add_method("setString", |_, this, (key, value): (String, String)| {
            this.inner.borrow_mut().set_string(&key, &value);
            Ok(())
        });
        // -- getString --
        /// Returns a string blackboard fact or the provided fallback when the key is missing or not a string.
        /// @param | key | string | Blackboard key to read.
        /// @param | default | string? | Fallback value used when the key has no string entry; defaults to an empty string.
        /// @return | string | Stored string value or fallback value.
        methods.add_method(
            "getString",
            |_, this, (key, default): (String, Option<String>)| {
                let def = default.unwrap_or_default();
                Ok(this.inner.borrow().get_string(&key, &def))
            },
        );
        // -- has --
        /// Returns whether the blackboard contains any entry for the given key.
        /// @param | key | string | Blackboard key to check.
        /// @return | boolean | True when any typed value is stored at the key.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.inner.borrow().has(&key))
        });
        // -- remove --
        /// Removes the given key from the blackboard if it exists.
        /// @param | key | string | Blackboard key to remove.
        /// @return | nil | No value is returned.
        methods.add_method("remove", |_, this, key: String| {
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });
        // -- clear --
        /// Removes every local entry from this blackboard.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        // -- getKeys --
        /// Returns every local blackboard key in an array-style Lua table.
        /// @return | table | Array table containing all stored key names as strings.
        methods.add_method("getKeys", |lua, this, ()| {
            let keys = this.inner.borrow().keys();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i as i64 + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        // -- getSize --
        /// Returns the number of entries currently stored in this blackboard.
        /// @return | integer | Current blackboard entry count.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().size()));
        // -- type --
        /// Returns the Lua-visible type name for this blackboard handle.
        /// @return | string | The string `LAIBlackboard`.
        methods.add_method("type", |_, _, ()| Ok("LAIBlackboard"));
        // -- typeOf --
        /// Returns whether this blackboard handle matches a supported type name.
        /// @param | name | string | Type name to compare against `AIBlackboard`, `Blackboard`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIBlackboard" || name == "Blackboard" || name == "Object")
        });
    }
}
/// Lua handle for a finite state machine with Lua-backed state callbacks and transition guards.
#[derive(Clone)]
struct LuaStateMachine {
    /// Shared state machine containing states, transitions, current state, and timing data.
    inner: Rc<RefCell<crate::ai::StateMachine>>,
}
impl LuaUserData for LuaStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addState --
        /// Adds a state with optional Lua lifecycle callbacks.
        /// @param | name | string | State name used by transitions and direct state changes.
        /// @param | opts | table | Optional table with `onEnter`, `onUpdate`, and `onExit` callback functions.
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
        /// Adds a transition between two states with an optional guard callback and priority.
        /// @param | from | string | Source state name.
        /// @param | to | string | Destination state name.
        /// @param | guard | function? | Optional function that must return true for the transition to run.
        /// @param | priority | integer? | Transition priority used when multiple transitions are available; defaults to zero.
        /// @return | nil | No value is returned.
        methods.add_method("addTransition", |lua, this, (from, to, guard, priority): (String, String, Option<LuaFunction>, Option<i32>)| {
                let guard_key = guard.map(|f| lua.create_registry_value(f)).transpose()?;
                this.inner.borrow_mut().add_transition_raw(from, to, priority.unwrap_or(0), guard_key);
                Ok(())
            },
        );
        // -- setInitialState --
        /// Sets the initial state and also enters it when the machine has no current state yet.
        /// @param | name | string | State name to use as the initial state.
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
        /// Returns the current state name when the state machine has entered a state.
        /// @return | LuaValue | Current state name, or nil before any state is active.
        methods.add_method("getCurrentState", |_, this, ()| {
            Ok(this.inner.borrow().current_state().map(|s| s.to_string()))
        });
        // -- forceState --
        /// Immediately switches the current state and resets the time spent in state.
        /// @param | name | string | State name to set as current without transition checks.
        /// @return | nil | No value is returned.
        methods.add_method("forceState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.current_state = Some(name);
            fsm.time_in_state = 0.0;
            Ok(())
        });
        // -- getTimeInState --
        /// Returns how long the machine has spent in the current state.
        /// @return | number | Elapsed time in seconds since the current state was entered.
        methods.add_method("getTimeInState", |_, this, ()| {
            Ok(this.inner.borrow().time_in_state())
        });
        // -- type --
        /// Returns the Lua-visible type name for this state machine handle.
        /// @return | string | The string `LStateMachine`.
        methods.add_method("type", |_, _, ()| Ok("LStateMachine"));
        // -- typeOf --
        /// Returns whether this state machine handle matches a supported type name.
        /// @param | name | string | Type name to compare against `StateMachine` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "StateMachine" || name == "Object")
        });
    }
}
/// Lua handle for a behavior tree root and its most recent execution status.
#[derive(Clone)]
struct LuaBehaviorTree {
    /// Shared behavior tree that owns the root node and debug status.
    inner: Rc<RefCell<BehaviorTree>>,
}
impl LuaUserData for LuaBehaviorTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setRoot --
        /// Sets the behavior tree root by moving a node handle into the tree.
        /// @param | node | LBTNode | Node handle to consume as the new tree root.
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
        /// Returns the last behavior tree status string recorded by the tree.
        /// @return | string | Last status such as `success`, `failure`, or `running`.
        methods.add_method("getLastStatus", |_, this, ()| {
            Ok(this.inner.borrow().last_status.as_str().to_string())
        });
        // -- getDebugState --
        /// Returns behavior tree debug counters and status in a Lua table.
        /// @return | table | Table containing `node_count` and `last_status` fields.
        methods.add_method("getDebugState", |lua, this, ()| {
            let dbg = this.inner.borrow().debug_state();
            let t = lua.create_table()?;
            t.set("node_count", dbg.node_count as u32)?;
            t.set("last_status", dbg.last_status)?;
            Ok(t)
        });
        // -- type --
        /// Returns the Lua-visible type name for this behavior tree handle.
        /// @return | string | The string `LBehaviorTree`.
        methods.add_method("type", |_, _, ()| Ok("LBehaviorTree"));
        // -- typeOf --
        /// Returns whether this behavior tree handle matches a supported type name.
        /// @param | name | string | Type name to compare against `BehaviorTree` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BehaviorTree" || name == "Object")
        });
    }
}
/// Lua handle for a behavior tree node that can be assembled into composites and decorators.
#[derive(Clone)]
struct LuaBTNode {
    /// Shared node storage moved between handles when nodes are attached to parents.
    inner: Rc<RefCell<BTNode>>,
}
impl LuaUserData for LuaBTNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addChild --
        /// Adds a child node to a composite selector, sequence, or parallel node.
        /// @param | child | LBTNode | Child node handle to move into this composite node.
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
        /// Returns the number of children owned by this behavior tree node.
        /// @return | integer | Child count for composite nodes, or zero for leaf and decorator nodes without child lists.
        methods.add_method("getChildCount", |_, this, ()| {
            Ok(this.inner.borrow().child_count())
        });
        // -- reset --
        /// Resets this behavior tree node's runtime state.
        /// @return | nil | No value is returned.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        // -- setChild --
        /// Sets the single child of a decorator node such as inverter, repeater, or succeeder.
        /// @param | child | LBTNode | Child node handle to move into this decorator node.
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
        /// Sets the repeat count when this node is a repeater.
        /// @param | n | integer | Number of successful child executions before the repeater stops; zero means engine-defined repeat behavior.
        /// @return | nil | No value is returned.
        methods.add_method("setCount", |_, this, n: u32| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Repeater { count, .. } = &mut *node {
                *count = n;
            }
            Ok(())
        });
        // -- getCount --
        /// Returns the repeat count for repeater nodes or zero for other node kinds.
        /// @return | integer | Repeater count value.
        methods.add_method("getCount", |_, this, ()| {
            let node = this.inner.borrow();
            if let BTNode::Repeater { count, .. } = &*node {
                Ok(*count)
            } else {
                Ok(0)
            }
        });
        // -- setSuccessPolicy --
        /// Sets the success policy for a parallel node.
        /// @param | policy | string | Parallel success policy name parsed by the engine.
        /// @return | nil | No value is returned.
        methods.add_method("setSuccessPolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { success_policy, .. } = &mut *node {
                *success_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });
        // -- setFailurePolicy --
        /// Sets the failure policy for a parallel node.
        /// @param | policy | string | Parallel failure policy name parsed by the engine.
        /// @return | nil | No value is returned.
        methods.add_method("setFailurePolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { failure_policy, .. } = &mut *node {
                *failure_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });
        // -- getNodeType --
        /// Returns the behavior tree node kind as a lowercase string.
        /// @return | string | Node kind such as `selector`, `sequence`, `parallel`, `action`, or `condition`.
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
        /// Returns the Lua-visible type name for this behavior tree node handle.
        /// @return | string | The string `LBTNode`.
        methods.add_method("type", |_, _, ()| Ok("LBTNode"));
        // -- typeOf --
        /// Returns whether this behavior tree node handle matches a supported type name.
        /// @param | name | string | Type name to compare against `BTNode` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BTNode" || name == "Object")
        });
    }
}
/// Lua handle for a steering behavior stack that combines movement forces for an agent.
#[derive(Clone)]
struct LuaSteeringManager {
    /// Shared steering manager containing configured steering behaviors and path state.
    inner: Rc<RefCell<SteeringManager>>,
    /// Registry used by custom steering behavior callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaSteeringManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeek --
        /// Adds a seek behavior that pulls the agent toward a target point.
        /// @param | tx | number | Target X position in world units.
        /// @param | ty | number | Target Y position in world units.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds a flee behavior that pushes the agent away from a target point inside a panic distance.
        /// @param | tx | number | Threat X position in world units.
        /// @param | ty | number | Threat Y position in world units.
        /// @param | panic_dist | number? | Distance inside which fleeing is active; defaults to 200.0.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds an arrive behavior that slows the agent as it approaches a target point.
        /// @param | tx | number | Target X position in world units.
        /// @param | ty | number | Target Y position in world units.
        /// @param | slowing | number? | Radius used to reduce speed near the target; defaults to 50.0.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds a wander behavior that produces jittered exploratory movement.
        /// @param | radius | number? | Wander circle radius; defaults to 20.0.
        /// @param | dist | number? | Wander circle distance in front of the agent; defaults to 40.0.
        /// @param | jitter | number? | Random displacement applied per update; defaults to 5.0.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds a pursue behavior that chases another named agent when a target name is supplied.
        /// @param | target_name | string? | Optional name of the agent to pursue.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds an evade behavior that moves away from another named agent when a threat name is supplied.
        /// @param | threat_name | string? | Optional name of the agent to evade.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Adds a flocking behavior with separation, alignment, and cohesion weights.
        /// @param | neighbor_radius | number? | Radius used to find flock neighbors; defaults to 100.0.
        /// @param | sep_w | number? | Separation force weight; defaults to 1.5.
        /// @param | align_w | number? | Alignment force weight; defaults to 1.0.
        /// @param | coh_w | number? | Cohesion force weight; defaults to 1.0.
        /// @param | weight | number? | Behavior weight applied during steering combination; defaults to 1.0.
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
        /// Returns the number of steering behaviors configured on this manager.
        /// @return | integer | Current steering behavior count.
        methods.add_method("getBehaviorCount", |_, this, ()| {
            Ok(this.inner.borrow().behaviors.len())
        });
        // -- setCombineMode --
        /// Sets how steering behavior forces are combined.
        /// @param | mode | string | Combine mode string parsed by the steering manager.
        /// @return | nil | No value is returned.
        methods.add_method("setCombineMode", |_, this, mode: String| {
            this.inner.borrow_mut().set_combine_mode_str(&mode);
            Ok(())
        });
        // -- getCombineMode --
        /// Returns the current steering force combination mode.
        /// @return | string | Combine mode name.
        methods.add_method("getCombineMode", |_, this, ()| {
            Ok(this.inner.borrow().combine_mode.as_str().to_string())
        });
        // -- getLastSteering --
        /// Returns the last steering force calculated by this manager.
        /// @return | number, number | X and Y force values from the previous calculation.
        methods.add_method("getLastSteering", |_, this, ()| {
            Ok(this.inner.borrow().last_force())
        });
        // -- calculate --
        /// Calculates a steering force for the supplied agent movement state.
        /// @param | px | number | Current agent X position.
        /// @param | py | number | Current agent Y position.
        /// @param | vx | number | Current agent X velocity.
        /// @param | vy | number | Current agent Y velocity.
        /// @param | max_speed | number | Maximum allowed speed used by steering constraints.
        /// @param | max_force | number | Maximum allowed steering force.
        /// @param | dt | number | Elapsed time in seconds for this steering step.
        /// @return | number, number | X and Y steering force.
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
        /// Sets a waypoint path behavior from an array of `{x, y}` tables.
        /// @param | waypoints | table | Array of waypoint tables, each containing numeric `x` and `y` fields.
        /// @param | reach_radius | number? | Distance at which a waypoint is considered reached; defaults to 12.0.
        /// @param | weight | number? | Path following behavior weight; defaults to 1.0.
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
        /// Clears the active waypoint path behavior.
        /// @return | nil | No value is returned.
        methods.add_method("clearPath", |_, this, ()| {
            this.inner.borrow_mut().clear_path();
            Ok(())
        });
        // -- hasPath --
        /// Returns whether this manager currently has an active waypoint path.
        /// @return | boolean | True when a path is configured and not complete.
        methods.add_method("hasPath", |_, this, ()| {
            Ok(this.inner.borrow().has_active_path())
        });
        // -- getPathProgress --
        /// Returns the current one-based waypoint index and total waypoint count.
        /// @return | integer, integer | Current waypoint index and total waypoint count.
        methods.add_method("getPathProgress", |_, this, ()| {
            let (idx, total) = this.inner.borrow().path_progress();
            Ok((idx + 1, total))
        });
        // -- type --
        /// Returns the Lua-visible type name for this steering manager handle.
        /// @return | string | The string `LSteeringManager`.
        methods.add_method("type", |_, _, ()| Ok("LSteeringManager"));
        // -- typeOf --
        /// Returns whether this steering manager handle matches a supported type name.
        /// @param | name | string | Type name to compare against `SteeringManager` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SteeringManager" || name == "Object")
        });
        // -- setSpatialHashCellSize --
        /// Sets the cell size used by the steering manager spatial hash.
        /// @param | size | number | Spatial hash cell size in world units.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSpatialHashCellSize", |_, this, size: f32| {
            this.inner.borrow_mut().set_cell_size(size);
            Ok(())
        });
        // -- enableSpatialHash --
        /// Enables or disables spatial hash acceleration for neighbor queries.
        /// @param | enabled | boolean | True to use spatial hashing, false to use direct scans.
        /// @return | nil | No value is returned.
        methods.add_method_mut("enableSpatialHash", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_use_spatial_hash(enabled);
            Ok(())
        });
        // -- addCustomBehavior --
        /// Adds a custom steering behavior backed by a Lua callback.
        /// @param | func | function | Function called as `(agent, dt)` that returns an X and Y steering force.
        /// @param | weight | number? | Custom behavior weight applied to returned forces; defaults to 1.0.
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
        /// Runs enabled custom steering callbacks for an agent and returns the weighted combined force.
        /// @param | agent | LAgent | Agent handle passed through to every custom steering callback.
        /// @param | dt | number | Elapsed time in seconds passed to every custom steering callback.
        /// @return | number, number | Combined custom X and Y steering force.
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
/// Lua handle for topic and branch selection driven by dialogue AI state.
#[derive(Clone)]
struct LuaDialogueAI {
    /// Shared dialogue selector containing topics, branches, and decision context.
    inner: Rc<RefCell<DialogueAI>>,
}
impl LuaUserData for LuaDialogueAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setFSMState --
        /// Sets the finite-state-machine state used as dialogue selection context.
        /// @param | state | string? | Current FSM state name, or nil to clear the FSM context.
        /// @return | nil | No value is returned.
        methods.add_method("setFSMState", |_, this, state: Option<String>| {
            this.inner.borrow_mut().set_fsm_state(state);
            Ok(())
        });
        // -- setBTStatus --
        /// Sets the behavior-tree status used as dialogue selection context.
        /// @param | status | string? | Current behavior tree status, or nil to clear the status context.
        /// @return | nil | No value is returned.
        methods.add_method("setBTStatus", |_, this, status: Option<String>| {
            this.inner.borrow_mut().set_bt_status(status);
            Ok(())
        });
        // -- setUtilityScore --
        /// Stores a utility score used by topics and branches that reference the given key.
        /// @param | key | string | Utility score key.
        /// @param | score | number | Utility score value used during weighted selection.
        /// @return | nil | No value is returned.
        methods.add_method("setUtilityScore", |_, this, (key, score): (String, f32)| {
            this.inner.borrow_mut().set_utility_score(key, score);
            Ok(())
        });
        // -- clearUtilityScores --
        /// Removes every stored utility score from this dialogue selector.
        /// @return | nil | No value is returned.
        methods.add_method("clearUtilityScores", |_, this, ()| {
            this.inner.borrow_mut().clear_utility_scores();
            Ok(())
        });
        // -- addTopic --
        /// Adds a selectable dialogue topic with optional context filters.
        /// @param | id | string | Unique topic identifier.
        /// @param | weight | number? | Base selection weight; defaults to 1.0.
        /// @param | fsm_state | string? | Optional FSM state required for this topic.
        /// @param | bt_status | string? | Optional behavior tree status required for this topic.
        /// @param | utility_key | string? | Optional utility score key multiplied into selection.
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
        /// Adds a selectable branch under an existing dialogue topic.
        /// @param | topic_id | string | Topic identifier that receives the branch.
        /// @param | branch_id | string | Unique branch identifier within the topic.
        /// @param | weight | number? | Base branch weight; defaults to 1.0.
        /// @param | fsm_state | string? | Optional FSM state required for this branch.
        /// @param | bt_status | string? | Optional behavior tree status required for this branch.
        /// @param | utility_key | string? | Optional utility score key multiplied into selection.
        /// @return | boolean | True when the branch was added to an existing topic.
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
        /// Selects the best currently valid topic using weights and context filters.
        /// @return | LuaValue | Selected topic identifier, or nil when no topic is available.
        methods.add_method("selectTopic", |_, this, ()| {
            Ok(this.inner.borrow().select_topic())
        });
        // -- selectBranch --
        /// Selects the best currently valid branch for the given topic.
        /// @param | topic_id | string | Topic identifier whose branches should be considered.
        /// @return | LuaValue | Selected branch identifier, or nil when no branch is available.
        methods.add_method("selectBranch", |_, this, topic_id: String| {
            Ok(this.inner.borrow().select_branch(&topic_id))
        });
        // -- getTopicCount --
        /// Returns the number of topics registered in this dialogue selector.
        /// @return | integer | Current topic count.
        methods.add_method("getTopicCount", |_, this, ()| {
            Ok(this.inner.borrow().topic_count())
        });
        // -- type --
        /// Returns the Lua-visible type name for this dialogue AI handle.
        /// @return | string | The string `LDialogueAI`.
        methods.add_method("type", |_, _, ()| Ok("LDialogueAI"));
        // -- typeOf --
        /// Returns whether this dialogue AI handle matches a supported type name.
        /// @param | name | string | Type name to compare against `DialogueAI` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "DialogueAI" || name == "Object")
        });
    }
}
/// Lua handle for a Q-learning table with configurable exploration and learning parameters.
#[derive(Clone)]
struct LuaQLearner {
    /// Shared Q-learning model containing Q-values, episode counters, and tuning parameters.
    inner: Rc<RefCell<QLearner>>,
}
impl LuaUserData for LuaQLearner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- chooseAction --
        /// Chooses an action for a one-based state index using the learner's exploration policy.
        /// @param | state | integer | One-based state index.
        /// @return | integer | One-based chosen action index.
        methods.add_method("chooseAction", |_, this, state: usize| {
            Ok(this.inner.borrow().choose_action(state.saturating_sub(1)) + 1)
        });
        // -- bestAction --
        /// Returns the highest-valued action for a one-based state index without exploration.
        /// @param | state | integer | One-based state index.
        /// @return | integer | One-based best action index.
        methods.add_method("bestAction", |_, this, state: usize| {
            Ok(this.inner.borrow().best_action(state.saturating_sub(1)) + 1)
        });
        // -- learn --
        /// Applies one Q-learning update from a transition and reward.
        /// @param | state | integer | One-based previous state index.
        /// @param | action | integer | One-based action index taken in the previous state.
        /// @param | reward | number | Reward received for the transition.
        /// @param | next_state | integer | One-based next state index.
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
        /// Returns the stored Q-value for a one-based state and action pair.
        /// @param | state | integer | One-based state index.
        /// @param | action | integer | One-based action index.
        /// @return | number | Current Q-value.
        methods.add_method("getQValue", |_, this, (state, action): (usize, usize)| {
            Ok(this
                .inner
                .borrow()
                .get_q(state.saturating_sub(1), action.saturating_sub(1)))
        });
        // -- setQValue --
        /// Sets the stored Q-value for a one-based state and action pair.
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
        /// Ends the current learning episode and applies episode bookkeeping.
        /// @return | nil | No value is returned.
        methods.add_method("endEpisode", |_, this, ()| {
            this.inner.borrow_mut().end_episode();
            Ok(())
        });
        // -- getEpisodeCount --
        /// Returns how many learning episodes have been completed.
        /// @return | integer | Completed episode count.
        methods.add_method("getEpisodeCount", |_, this, ()| {
            Ok(this.inner.borrow().episode_count)
        });
        // -- getStateCount --
        /// Returns the number of states represented by this learner.
        /// @return | integer | State count.
        methods.add_method("getStateCount", |_, this, ()| {
            Ok(this.inner.borrow().state_count)
        });
        // -- getActionCount --
        /// Returns the number of actions represented by this learner.
        /// @return | integer | Action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().action_count)
        });
        // -- setLearningRate --
        /// Sets the Q-learning alpha learning rate.
        /// @param | v | number | Learning rate used by future updates.
        /// @return | nil | No value is returned.
        methods.add_method("setLearningRate", |_, this, v: f64| {
            this.inner.borrow_mut().alpha = v;
            Ok(())
        });
        // -- getLearningRate --
        /// Returns the Q-learning alpha learning rate.
        /// @return | number | Current learning rate.
        methods.add_method("getLearningRate", |_, this, ()| {
            Ok(this.inner.borrow().alpha)
        });
        // -- setDiscountFactor --
        /// Sets the Q-learning gamma discount factor.
        /// @param | v | number | Discount factor used by future updates.
        /// @return | nil | No value is returned.
        methods.add_method("setDiscountFactor", |_, this, v: f64| {
            this.inner.borrow_mut().gamma = v;
            Ok(())
        });
        // -- getDiscountFactor --
        /// Returns the Q-learning gamma discount factor.
        /// @return | number | Current discount factor.
        methods.add_method("getDiscountFactor", |_, this, ()| {
            Ok(this.inner.borrow().gamma)
        });
        // -- setExplorationRate --
        /// Sets the exploration rate used by action selection.
        /// @param | v | number | Exploration probability for future `chooseAction` calls.
        /// @return | nil | No value is returned.
        methods.add_method("setExplorationRate", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon = v;
            Ok(())
        });
        // -- getExplorationRate --
        /// Returns the exploration rate used by action selection.
        /// @return | number | Current exploration rate.
        methods.add_method("getExplorationRate", |_, this, ()| {
            Ok(this.inner.borrow().epsilon)
        });
        // -- setExplorationDecay --
        /// Sets the exploration decay multiplier applied across episodes.
        /// @param | v | number | Exploration decay multiplier.
        /// @return | nil | No value is returned.
        methods.add_method("setExplorationDecay", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon_decay = v;
            Ok(())
        });
        // -- getExplorationDecay --
        /// Returns the exploration decay multiplier.
        /// @return | number | Current exploration decay multiplier.
        methods.add_method("getExplorationDecay", |_, this, ()| {
            Ok(this.inner.borrow().epsilon_decay)
        });
        // -- serialize --
        /// Serializes the Q-learner state to a JSON string.
        /// @return | string | JSON representation of this learner.
        methods.add_method("serialize", |_, this, ()| {
            Ok(this.inner.borrow().serialize())
        });
        // -- deserialize --
        /// Replaces the Q-learner state from a JSON string.
        /// @param | json | string | JSON data previously produced by `serialize`.
        /// @return | nil | No value is returned.
        methods.add_method("deserialize", |_, this, json: String| {
            this.inner
                .borrow_mut()
                .deserialize(&json)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this Q-learner handle.
        /// @return | string | The string `LQLearner`.
        methods.add_method("type", |_, _, ()| Ok("LQLearner"));
        // -- typeOf --
        /// Returns whether this Q-learner handle matches a supported type name.
        /// @param | name | string | Type name to compare against `QLearner` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "QLearner" || name == "Object")
        });
    }
}
/// Lua handle for utility AI action scoring and consideration curves.
#[derive(Clone)]
struct LuaUtilityAI {
    /// Shared utility AI model containing actions and their scorer callbacks.
    inner: Rc<RefCell<UtilityAI>>,
    /// Registry used for custom response curve callbacks.
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaUtilityAI {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAction --
        /// Adds an action scored by a Lua callback and optional momentum weight.
        /// @param | name | string | Action name returned when this action wins evaluation.
        /// @param | scorer_fn | function | Function called by evaluation to score this action.
        /// @param | weight | number? | Momentum bonus or base weighting value; defaults to 1.0.
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
        /// Evaluates all actions and returns the winning action name when one is available.
        /// @return | LuaValue | Winning action name, or nil when no action can be selected.
        methods.add_method("evaluate", |lua, this, ()| {
            match this.inner.borrow_mut().evaluate(lua)? {
                Some(name) => Ok(LuaValue::String(lua.create_string(&name)?)),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- getActionCount --
        /// Returns the number of actions registered in this utility AI.
        /// @return | integer | Current action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });
        // -- getLastAction --
        /// Returns the last winning action name when evaluation has selected one.
        /// @return | LuaValue | Last action name, or nil before an action has won.
        methods.add_method("getLastAction", |_, this, ()| {
            let ai = this.inner.borrow();
            Ok(ai.last_action.map(|i| ai.actions[i].name.clone()))
        });
        // -- addConsideration --
        /// Adds a consideration scorer and response curve to an existing utility action.
        /// @param | action_name | string | Name of the action that receives the consideration.
        /// @param | name | string | Consideration name used for debugging and documentation.
        /// @param | scorer_fn | function | Function that returns the raw consideration score.
        /// @param | curve_arg | LuaValue | Curve name string, custom curve function, or another value to use the linear fallback.
        /// @param | p1 | number? | First curve parameter; defaults to 1.0.
        /// @param | p2 | number? | Second curve parameter; defaults to 0.0.
        /// @param | p3 | number? | Third curve parameter; defaults to 0.0.
        /// @param | weight | number? | Consideration weight; defaults to 1.0.
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
        /// Returns the Lua-visible type name for this utility AI handle.
        /// @return | string | The string `LUtilityAI`.
        methods.add_method("type", |_, _, ()| Ok("LUtilityAI"));
        // -- typeOf --
        /// Returns whether this utility AI handle matches a supported type name.
        /// @param | name | string | Type name to compare against `UtilityAI` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "UtilityAI" || name == "Object")
        });
    }
}
/// Lua handle for a GOAP planner with boolean preconditions, effects, and goals.
#[derive(Clone)]
struct LuaGOAPPlanner {
    /// Shared GOAP planner containing actions, goals, and iteration limits.
    inner: Rc<RefCell<GOAPPlanner>>,
}
impl LuaUserData for LuaGOAPPlanner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAction --
        /// Adds a GOAP action with optional cost and completion callback.
        /// @param | name | string | Action name emitted in generated plans.
        /// @param | cost | number? | Planning cost for the action; defaults to 1.0.
        /// @param | callback | function? | Optional callback stored with the action for game-side execution.
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
        /// Sets one boolean precondition for an existing GOAP action.
        /// @param | action_name | string | Name of the action to update.
        /// @param | key | string | World-state key required by the action.
        /// @param | value | boolean | Required boolean value for the key.
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
        /// Sets one boolean effect produced by an existing GOAP action.
        /// @param | action_name | string | Name of the action to update.
        /// @param | key | string | World-state key changed by the action.
        /// @param | value | boolean | Boolean value written by the effect.
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
        /// Adds a GOAP goal with an optional priority weight.
        /// @param | name | string | Goal name used for planning and debugging.
        /// @param | priority | number? | Goal priority; defaults to 1.0.
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
        /// Sets one desired world-state key for an existing GOAP goal.
        /// @param | goal_name | string | Name of the goal to update.
        /// @param | key | string | World-state key required by the goal.
        /// @param | value | boolean | Desired boolean value for the key.
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
        /// Builds a plan from the supplied boolean world state and returns action names in execution order.
        /// @param | world_state_tbl | table | Map table from string world-state keys to boolean values.
        /// @param | max_depth | integer? | Maximum search depth; defaults to 10.
        /// @return | table | Array table of action names selected by the planner.
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
        /// Returns the number of GOAP actions registered in this planner.
        /// @return | integer | Current action count.
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });
        // -- getGoalCount --
        /// Returns the number of GOAP goals registered in this planner.
        /// @return | integer | Current goal count.
        methods.add_method("getGoalCount", |_, this, ()| {
            Ok(this.inner.borrow().goals.len())
        });
        // -- getMaxIterations --
        /// Returns the maximum number of planner iterations allowed during search.
        /// @return | integer | Current maximum iteration count.
        methods.add_method("getMaxIterations", |_, this, ()| {
            Ok(this.inner.borrow().get_max_iterations() as u64)
        });
        // -- setMaxIterations --
        /// Sets the maximum number of planner iterations allowed during search.
        /// @param | n | integer | Maximum iteration count.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMaxIterations", |_, this, n: u64| {
            this.inner.borrow_mut().set_max_iterations(n as usize);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this GOAP planner handle.
        /// @return | string | The string `LGOAPPlanner`.
        methods.add_method("type", |_, _, ()| Ok("LGOAPPlanner"));
        // -- typeOf --
        /// Returns whether this GOAP planner handle matches a supported type name.
        /// @param | name | string | Type name to compare against `GOAPPlanner` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GOAPPlanner" || name == "Object")
        });
    }
}
/// Lua handle for a grid-based influence map with named layers.
#[derive(Clone)]
struct LuaInfluenceMap {
    /// Shared influence map storing layer grids and world-cell conversion data.
    inner: Rc<RefCell<InfluenceMap>>,
}
impl LuaUserData for LuaInfluenceMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds an influence layer with the given name if it does not already exist.
        /// @param | name | string | Layer name used by later influence operations.
        /// @return | nil | No value is returned.
        methods.add_method("addLayer", |_, this, name: String| {
            this.inner.borrow_mut().add_layer(&name);
            Ok(())
        });
        // -- hasLayer --
        /// Returns whether an influence layer exists.
        /// @param | name | string | Layer name to check.
        /// @return | boolean | True when the layer exists.
        methods.add_method("hasLayer", |_, this, name: String| {
            Ok(this.inner.borrow().has_layer(&name))
        });
        // -- setInfluence --
        /// Sets one cell value in a named influence layer using one-based cell coordinates.
        /// @param | layer | string | Layer name to modify.
        /// @param | x | integer | One-based cell X coordinate.
        /// @param | y | integer | One-based cell Y coordinate.
        /// @param | value | number | Influence value to store in the cell.
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
        /// Returns one cell value from a named influence layer using one-based cell coordinates.
        /// @param | layer | string | Layer name to read.
        /// @param | x | integer | One-based cell X coordinate.
        /// @param | y | integer | One-based cell Y coordinate.
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
        /// Applies a radial influence stamp to a named layer in world coordinates.
        /// @param | layer | string | Layer name to modify.
        /// @param | wx | number | World X coordinate of the stamp center.
        /// @param | wy | number | World Y coordinate of the stamp center.
        /// @param | radius | number | Stamp radius in world units.
        /// @param | value | number | Influence value applied at the center.
        /// @param | falloff | number? | Falloff exponent or multiplier; defaults to 1.0.
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
        /// Propagates influence values across neighboring cells on a named layer.
        /// @param | layer | string | Layer name to propagate.
        /// @param | momentum | number? | Propagation momentum factor; defaults to 0.5.
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
        /// Multiplies a named layer by a decay factor.
        /// @param | layer | string | Layer name to decay.
        /// @param | factor | number | Decay factor applied to every cell.
        /// @return | nil | No value is returned.
        methods.add_method("decay", |_, this, (layer, factor): (String, f32)| {
            this.inner.borrow_mut().decay(&layer, factor);
            Ok(())
        });
        // -- clearLayer --
        /// Clears every value in a named influence layer.
        /// @param | layer | string | Layer name to clear.
        /// @return | nil | No value is returned.
        methods.add_method("clearLayer", |_, this, layer: String| {
            this.inner.borrow_mut().clear_layer(&layer);
            Ok(())
        });
        // -- clearAll --
        /// Clears every influence value in every layer.
        /// @return | nil | No value is returned.
        methods.add_method("clearAll", |_, this, ()| {
            this.inner.borrow_mut().clear_all();
            Ok(())
        });
        // -- getMaxPosition --
        /// Returns the cell position with the highest value on a named layer.
        /// @param | layer | string | Layer name to scan.
        /// @return | integer, integer | One-based X and Y cell coordinates of the maximum value.
        methods.add_method("getMaxPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().max_position(&layer))
        });
        // -- getMinPosition --
        /// Returns the cell position with the lowest value on a named layer.
        /// @param | layer | string | Layer name to scan.
        /// @return | integer, integer | One-based X and Y cell coordinates of the minimum value.
        methods.add_method("getMinPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().min_position(&layer))
        });
        // -- queryRect --
        /// Returns influence values inside a world-space rectangle on a named layer.
        /// @param | layer | string | Layer name to query.
        /// @param | wx | number | Rectangle X coordinate in world units.
        /// @param | wy | number | Rectangle Y coordinate in world units.
        /// @param | ww | number | Rectangle width in world units.
        /// @param | wh | number | Rectangle height in world units.
        /// @return | table | Array table of influence samples from cells inside the rectangle.
        methods.add_method(
            "queryRect",
            |_, this, (layer, wx, wy, ww, wh): (String, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().query_rect(&layer, wx, wy, ww, wh))
            },
        );
        // -- blend --
        /// Blends two source layers into a destination layer using independent weights.
        /// @param | layer_a | string | First source layer name.
        /// @param | weight_a | number | Weight applied to the first source layer.
        /// @param | layer_b | string | Second source layer name.
        /// @param | weight_b | number | Weight applied to the second source layer.
        /// @param | dest | string | Destination layer name that receives the blended values.
        /// @return | nil | No value is returned.
        methods.add_method("blend", |_, this, (layer_a, weight_a, layer_b, weight_b, dest): (String, f32, String, f32, String)| {
                this.inner.borrow_mut().blend(&layer_a, weight_a, &layer_b, weight_b, &dest);
                Ok(())
            },
        );
        // -- getWidth --
        /// Returns the influence map width in cells.
        /// @return | integer | Cell width of the map.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        // -- getHeight --
        /// Returns the influence map height in cells.
        /// @return | integer | Cell height of the map.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        // -- getCellSize --
        /// Returns the world size represented by each influence map cell.
        /// @return | number | Cell size in world units.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });
        // -- type --
        /// Returns the Lua-visible type name for this influence map handle.
        /// @return | string | The string `LInfluenceMap`.
        methods.add_method("type", |_, _, ()| Ok("LInfluenceMap"));
        // -- typeOf --
        /// Returns whether this influence map handle matches a supported type name.
        /// @param | name | string | Type name to compare against `InfluenceMap` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "InfluenceMap" || name == "Object")
        });
    }
}
/// Lua handle for a named squad with members, leader, formation, and shared blackboard.
#[derive(Clone)]
struct LuaSquad {
    /// Shared squad data exposed to Lua.
    inner: Rc<RefCell<Squad>>,
}
impl LuaUserData for LuaSquad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getName --
        /// Returns the squad name. This method is available to Lua scripts.
        /// @return | string | Squad name supplied at construction.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });
        // -- addMember --
        /// Adds a member name to the squad member list.
        /// @param | name | string | Agent or game object name to append as a squad member.
        /// @return | nil | No value is returned.
        methods.add_method("addMember", |_, this, name: String| {
            this.inner.borrow_mut().members.push(name);
            Ok(())
        });
        // -- removeMember --
        /// Removes every member entry with the given name.
        /// @param | name | string | Member name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeMember", |_, this, name: String| {
            this.inner.borrow_mut().members.retain(|m| m != &name);
            Ok(())
        });
        // -- getMemberCount --
        /// Returns the number of members in this squad.
        /// @return | integer | Current member count.
        methods.add_method("getMemberCount", |_, this, ()| {
            Ok(this.inner.borrow().members.len())
        });
        // -- getMembers --
        /// Returns all squad members in an array-style Lua table.
        /// @return | table | Array table of member names.
        methods.add_method("getMembers", |lua, this, ()| {
            let sq = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, m) in sq.members.iter().enumerate() {
                tbl.set(i as i64 + 1, m.as_str())?;
            }
            Ok(tbl)
        });
        // -- setLeader --
        /// Sets the squad leader name. This method is available to Lua scripts.
        /// @param | name | string | Member or agent name to store as leader.
        /// @return | nil | No value is returned.
        methods.add_method("setLeader", |_, this, name: String| {
            this.inner.borrow_mut().leader = Some(name);
            Ok(())
        });
        // -- getLeader --
        /// Returns the squad leader name when one is assigned.
        /// @return | LuaValue | Leader name, or nil when no leader is assigned.
        methods.add_method("getLeader", |_, this, ()| {
            Ok(this.inner.borrow().leader.clone())
        });
        // -- setFormation --
        /// Sets the squad formation type and optionally updates spacing.
        /// @param | ftype | string | Formation type name parsed by the engine.
        /// @param | spacing | number? | Optional spacing between formation slots.
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
        /// Returns the current squad formation type name.
        /// @return | string | Formation type name.
        methods.add_method("getFormation", |_, this, ()| {
            Ok(this.inner.borrow().formation.as_str().to_string())
        });
        // -- getFormationSpacing --
        /// Returns the spacing used by squad formation positioning.
        /// @return | number | Formation spacing in world units.
        methods.add_method("getFormationSpacing", |_, this, ()| {
            Ok(this.inner.borrow().formation_spacing)
        });
        // -- getFormationPosition --
        /// Returns a member's target formation position relative to the leader position.
        /// @param | member_idx | integer | One-based member index in the squad.
        /// @param | leader_x | number | Leader X position in world units.
        /// @param | leader_y | number | Leader Y position in world units.
        /// @return | number, number | X and Y formation target position.
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
        /// Returns a blackboard snapshot for this squad.
        /// @return | LAIBlackboard | Blackboard handle initialized from the squad blackboard values at call time.
        methods.add_method("getBlackboard", |_, this, ()| {
            let sq = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(sq.blackboard.clone())),
            })
        });
        // -- type --
        /// Returns the Lua-visible type name for this squad handle.
        /// @return | string | The string `LSquad`.
        methods.add_method("type", |_, _, ()| Ok("LSquad"));
        // -- typeOf --
        /// Returns whether this squad handle matches a supported type name.
        /// @param | name | string | Type name to compare against `Squad` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Squad" || name == "Object")
        });
    }
}
/// Lua handle for a command queue that stores ordered callback-backed commands.
#[derive(Clone)]
struct LuaCommandQueue {
    /// Shared command queue state exposed to Lua.
    inner: Rc<RefCell<CommandQueue>>,
}
/// Parses command option tables and returns target coordinates, priority, and interruptibility defaults.
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
        /// Adds a command callback to the back of the queue.
        /// @param | kind | string | Command type label stored for inspection.
        /// @param | callback | function | Callback invoked by command execution logic outside this wrapper.
        /// @param | opts | table? | Optional table with `targetX`, `targetY`, `priority`, and `interruptible` fields.
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
        /// Adds a command callback to the front of the queue.
        /// @param | kind | string | Command type label stored for inspection.
        /// @param | callback | function | Callback invoked by command execution logic outside this wrapper.
        /// @param | opts | table? | Optional table with `targetX`, `targetY`, `priority`, and `interruptible` fields.
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
        /// Replaces the queue contents with one command callback.
        /// @param | kind | string | Command type label stored for inspection.
        /// @param | callback | function | Callback invoked by command execution logic outside this wrapper.
        /// @param | opts | table? | Optional table with `targetX`, `targetY`, `priority`, and `interruptible` fields.
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
        /// Cancels the currently active command when one exists.
        /// @return | boolean | True when a current command was cancelled.
        methods.add_method("cancelCurrent", |_, this, ()| {
            Ok(this.inner.borrow_mut().cancel_current())
        });
        // -- clear --
        /// Removes every queued command. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        // -- getCount --
        /// Returns the number of commands currently queued.
        /// @return | integer | Current queue length.
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.borrow().count()));
        // -- isEmpty --
        /// Returns whether the command queue has no commands.
        /// @return | boolean | True when the queue is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.borrow().is_empty()));
        // -- getCurrentType --
        /// Returns the type label of the current command when one exists.
        /// @return | LuaValue | Current command type label, or nil when no command is active.
        methods.add_method("getCurrentType", |_, this, ()| {
            Ok(this.inner.borrow().current_type().map(|s| s.to_string()))
        });
        // -- getCurrentTarget --
        /// Returns the current command target coordinates.
        /// @return | number, number | Target X and Y coordinates for the current command, or queue defaults.
        methods.add_method("getCurrentTarget", |_, this, ()| {
            Ok(this.inner.borrow().current_target())
        });
        // -- type --
        /// Returns the Lua-visible type name for this command queue handle.
        /// @return | string | The string `LCommandQueue`.
        methods.add_method("type", |_, _, ()| Ok("LCommandQueue"));
        // -- typeOf --
        /// Returns whether this command queue handle matches a supported type name.
        /// @param | name | string | Type name to compare against `CommandQueue` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "CommandQueue" || name == "Object")
        });
    }
}
/// Lua handle for trait values with temporary modifiers and archetype lookup.
#[derive(Clone)]
struct LuaTraitProfile {
    /// Shared trait profile containing base traits and active modifiers.
    inner: Rc<RefCell<TraitProfile>>,
}
impl LuaUserData for LuaTraitProfile {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- set --
        /// Sets the base value for a named trait.
        /// @param | name | string | Trait name to create or update.
        /// @param | value | number | Base trait value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("set", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set(&name, value);
            Ok(())
        });
        // -- get --
        /// Returns the current value of a named trait including active modifiers.
        /// @param | name | string | Trait name to read.
        /// @return | number | Effective trait value.
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });
        // -- getBase --
        /// Returns the base value of a named trait without temporary modifiers.
        /// @param | name | string | Trait name to read.
        /// @return | number | Base trait value.
        methods.add_method("getBase", |_, this, name: String| {
            Ok(this.inner.borrow().get_base(&name))
        });
        // -- addModifier --
        /// Adds a temporary or permanent modifier to a named trait.
        /// @param | trait_name | string | Trait name affected by the modifier.
        /// @param | delta | number | Value added to the trait while the modifier is active.
        /// @param | duration | number? | Modifier lifetime in seconds, or nil for engine-defined permanent duration.
        /// @param | source | string | Source label used to remove related modifiers later.
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
        /// Removes all trait modifiers that match a source label.
        /// @param | source | string | Source label to remove.
        /// @return | nil | No value is returned.
        methods.add_method_mut("removeModifiers", |_, this, source: String| {
            this.inner.borrow_mut().remove_modifiers_by_source(&source);
            Ok(())
        });
        // -- update --
        /// Advances modifier timers and removes expired modifiers.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- has --
        /// Returns whether the profile has a named trait.
        /// @param | name | string | Trait name to check.
        /// @return | boolean | True when the trait exists.
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has(&name))
        });
        // -- traitCount --
        /// Returns the number of traits stored in the profile.
        /// @return | integer | Current trait count.
        methods.add_method("traitCount", |_, this, ()| {
            Ok(this.inner.borrow().trait_count() as i64)
        });
        // -- archetype --
        /// Returns the best matching archetype name when the profile can classify one.
        /// @return | LuaValue | Archetype name, or nil when no archetype matches.
        methods.add_method("archetype", |_, this, ()| {
            Ok(this.inner.borrow().archetype().map(|s| s.to_string()))
        });
        // -- type --
        /// Returns the Lua-visible type name for this trait profile handle.
        /// @return | string | The string `LTraitProfile`.
        methods.add_method("type", |_, _, ()| Ok("LTraitProfile"));
        // -- typeOf --
        /// Returns whether this trait profile handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LTraitProfile` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTraitProfile" || name == "Object")
        });
    }
}
/// Lua handle for sensory stimuli tracked in world space.
#[derive(Clone)]
struct LuaStimulusWorld {
    /// Shared stimulus world containing active visual and auditory stimuli.
    inner: Rc<RefCell<StimulusWorld>>,
}
impl LuaUserData for LuaStimulusWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addVisual --
        /// Adds a visual stimulus and returns its identifier.
        /// @param | x | number | Stimulus X position in world units.
        /// @param | y | number | Stimulus Y position in world units.
        /// @param | intensity | number | Initial stimulus intensity.
        /// @param | radius | number | Stimulus radius in world units.
        /// @param | tag | string? | Optional category tag for game-side filtering.
        /// @return | integer | New stimulus identifier.
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
        /// Adds an auditory stimulus with decay and returns its identifier.
        /// @param | x | number | Stimulus X position in world units.
        /// @param | y | number | Stimulus Y position in world units.
        /// @param | intensity | number | Initial stimulus intensity.
        /// @param | radius | number | Stimulus radius in world units.
        /// @param | decay_rate | number | Intensity decay rate applied during updates.
        /// @param | tag | string? | Optional category tag for game-side filtering.
        /// @return | integer | New stimulus identifier.
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
        /// Removes a stimulus by identifier. This method is available to Lua scripts.
        /// @param | id | integer | Stimulus identifier returned by `addVisual` or `addAuditory`.
        /// @return | boolean | True when a stimulus was removed.
        methods.add_method_mut("remove", |_, this, id: u64| {
            Ok(this.inner.borrow_mut().remove(id))
        });
        // -- update --
        /// Advances stimulus decay and lifetime state.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- count --
        /// Returns the number of active stimuli.
        /// @return | integer | Active stimulus count.
        methods.add_method(
            "count",
            |_, this, ()| Ok(this.inner.borrow().count() as i64),
        );
        // -- clear --
        /// Removes every active stimulus. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this stimulus world handle.
        /// @return | string | The string `LStimulusWorld`.
        methods.add_method("type", |_, _, ()| Ok("LStimulusWorld"));
        // -- typeOf --
        /// Returns whether this stimulus world handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LStimulusWorld` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStimulusWorld" || name == "Object")
        });
    }
}
/// Lua handle for slot-based context steering direction selection.
#[derive(Clone)]
struct LuaContextSteering {
    /// Shared context steering model containing directional slots and behavior weights.
    inner: Rc<RefCell<ContextSteering>>,
}
impl LuaUserData for LuaContextSteering {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeekTarget --
        /// Adds a context steering target attraction.
        /// @param | tx | number | Target X position in world units.
        /// @param | ty | number | Target Y position in world units.
        /// @param | weight | number | Attraction weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "addSeekTarget",
            |_, this, (tx, ty, weight): (f32, f32, f32)| {
                this.inner.borrow_mut().add_seek_target(tx, ty, weight);
                Ok(())
            },
        );
        // -- addWander --
        /// Adds wander noise to context steering.
        /// @param | jitter | number | Random steering jitter strength.
        /// @param | weight | number | Wander behavior weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addWander", |_, this, (jitter, weight): (f32, f32)| {
            this.inner.borrow_mut().add_wander(jitter, weight);
            Ok(())
        });
        // -- addAvoidPoint --
        /// Adds a point avoidance influence to context steering.
        /// @param | x | number | Avoidance point X position.
        /// @param | y | number | Avoidance point Y position.
        /// @param | radius | number | Avoidance radius in world units.
        /// @param | weight | number | Avoidance behavior weight.
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
        /// Adds rectangular bounds avoidance to context steering.
        /// @param | min_x | number | Minimum X bound.
        /// @param | min_y | number | Minimum Y bound.
        /// @param | max_x | number | Maximum X bound.
        /// @param | max_y | number | Maximum Y bound.
        /// @param | margin | number | Distance from bounds where avoidance begins.
        /// @param | weight | number | Avoidance behavior weight.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addAvoidBounds", |_, this, (min_x, min_y, max_x, max_y, margin, weight): (f32, f32, f32, f32, f32, f32)| {
            this.inner.borrow_mut().add_avoid_bounds(min_x, min_y, max_x, max_y, margin, weight);
            Ok(())
        });
        // -- clearBehaviors --
        /// Removes all context steering behaviors.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearBehaviors", |_, this, ()| {
            this.inner.borrow_mut().clear_behaviors();
            Ok(())
        });
        // -- evaluate --
        /// Evaluates context steering and returns the selected movement direction.
        /// @param | ax | number | Agent X position.
        /// @param | ay | number | Agent Y position.
        /// @param | vx | number | Agent X velocity.
        /// @param | vy | number | Agent Y velocity.
        /// @return | number, number | Selected X and Y direction.
        methods.add_method_mut(
            "evaluate",
            |_, this, (ax, ay, vx, vy): (f32, f32, f32, f32)| {
                let (dx, dy) = this.inner.borrow_mut().evaluate(ax, ay, vx, vy);
                Ok((dx, dy))
            },
        );
        // -- chosenMagnitude --
        /// Returns the magnitude of the last selected context steering slot.
        /// @return | number | Last chosen magnitude.
        methods.add_method("chosenMagnitude", |_, this, ()| {
            Ok(this.inner.borrow().chosen_magnitude())
        });
        // -- slotCount --
        /// Returns the number of directional slots used by this context steering model.
        /// @return | integer | Direction slot count.
        methods.add_method("slotCount", |_, this, ()| {
            Ok(this.inner.borrow().slot_count() as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this context steering handle.
        /// @return | string | The string `LContextSteering`.
        methods.add_method("type", |_, _, ()| Ok("LContextSteering"));
        // -- typeOf --
        /// Returns whether this context steering handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LContextSteering` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LContextSteering" || name == "Object")
        });
    }
}
/// Lua handle for decaying needs and urgency selection.
#[derive(Clone)]
struct LuaNeedSystem {
    /// Shared need system containing named need values and urgency settings.
    inner: Rc<RefCell<NeedSystem>>,
}
impl LuaUserData for LuaNeedSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addNeed --
        /// Adds a need with decay and urgency tuning values.
        /// @param | name | string | Need name used by satisfaction and lookup calls.
        /// @param | decay_rate | number | Value decay rate applied during updates.
        /// @param | urgency_threshold | number | Value threshold where the need becomes urgent.
        /// @param | urgency_factor | number | Weight applied to urgent needs.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addNeed", |_, this, (name, decay_rate, urgency_threshold, urgency_factor): (String, f32, f32, f32)| {
            this.inner.borrow_mut().add_need(Need::new(&name, decay_rate, urgency_threshold, urgency_factor));
            Ok(())
        });
        // -- update --
        /// Advances need decay over elapsed time.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- mostUrgent --
        /// Returns the name of the most urgent need when any need is active.
        /// @return | LuaValue | Need name, or nil when no urgent need is available.
        methods.add_method("mostUrgent", |_, this, ()| {
            Ok(this.inner.borrow().most_urgent().map(|s| s.to_string()))
        });
        // -- satisfy --
        /// Reduces or satisfies a named need by the supplied amount.
        /// @param | name | string | Need name to satisfy.
        /// @param | amount | number | Amount applied to the need value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("satisfy", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().satisfy(&name, amount);
            Ok(())
        });
        // -- valueOf --
        /// Returns the current value of a named need.
        /// @param | name | string | Need name to read.
        /// @return | number | Current need value.
        methods.add_method("valueOf", |_, this, name: String| {
            Ok(this.inner.borrow().value_of(&name))
        });
        // -- type --
        /// Returns the Lua-visible type name for this need system handle.
        /// @return | string | The string `LNeedSystem`.
        methods.add_method("type", |_, _, ()| Ok("LNeedSystem"));
        // -- typeOf --
        /// Returns whether this need system handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LNeedSystem` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeedSystem" || name == "Object")
        });
    }
}
/// Lua handle for an AI director that tracks encounter tension and pacing factors.
#[derive(Clone)]
struct LuaAIDirector {
    /// Shared AI director containing tension, phase, and derived pacing values.
    inner: Rc<RefCell<AIDirector>>,
}
impl LuaUserData for LuaAIDirector {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- pushEvent --
        /// Adds an event intensity sample to the director tension model.
        /// @param | intensity | number | Event intensity added to current tension.
        /// @return | nil | No value is returned.
        methods.add_method_mut("pushEvent", |_, this, intensity: f32| {
            this.inner.borrow_mut().push_event(intensity);
            Ok(())
        });
        // -- update --
        /// Advances director tension decay and phase evaluation.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- tension --
        /// Returns the current director tension value.
        /// @return | number | Current tension.
        methods.add_method("tension", |_, this, ()| Ok(this.inner.borrow().tension()));
        // -- phase --
        /// Returns the current director phase name.
        /// @return | string | Current pacing phase.
        methods.add_method("phase", |_, this, ()| {
            Ok(this.inner.borrow().phase_str().to_string())
        });
        // -- spawnRateFactor --
        /// Returns the spawn-rate multiplier derived from current tension and phase.
        /// @return | number | Spawn rate factor.
        methods.add_method("spawnRateFactor", |_, this, ()| {
            Ok(this.inner.borrow().spawn_rate_factor())
        });
        // -- lootFactor --
        /// Returns the loot multiplier derived from current tension and phase.
        /// @return | number | Loot factor.
        methods.add_method("lootFactor", |_, this, ()| {
            Ok(this.inner.borrow().loot_factor())
        });
        // -- ambientIntensity --
        /// Returns the ambient intensity derived from current tension and phase.
        /// @return | number | Ambient intensity factor.
        methods.add_method("ambientIntensity", |_, this, ()| {
            Ok(this.inner.borrow().ambient_intensity())
        });
        // -- setTension --
        /// Directly sets the director tension value.
        /// @param | value | number | New tension value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTension", |_, this, value: f32| {
            this.inner.borrow_mut().set_tension(value);
            Ok(())
        });
        // -- reset --
        /// Resets director tension and phase state to defaults.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this AI director handle.
        /// @return | string | The string `LAIDirector`.
        methods.add_method("type", |_, _, ()| Ok("LAIDirector"));
        // -- typeOf --
        /// Returns whether this AI director handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAIDirector` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIDirector" || name == "Object")
        });
    }
}
/// Lua handle for a hierarchical task network domain.
#[derive(Clone)]
struct LuaHTNDomain {
    /// Shared HTN domain containing primitive and compound task definitions.
    inner: Rc<RefCell<HTNDomain>>,
}
impl LuaUserData for LuaHTNDomain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addPrimitive --
        /// Adds a primitive HTN task with preconditions, effects, and cleared facts.
        /// @param | name | string | Primitive task name.
        /// @param | preconds | table | Array of fact names required before the task can run.
        /// @param | effects | table | Array of fact names added by the task.
        /// @param | clears | table | Array of fact names removed by the task.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addPrimitive", |_, this, (name, preconds, effects, clears): (String, Vec<String>, Vec<String>, Vec<String>)| {
            let p: Vec<&str> = preconds.iter().map(|s| s.as_str()).collect();
            let e: Vec<&str> = effects.iter().map(|s| s.as_str()).collect();
            let c: Vec<&str> = clears.iter().map(|s| s.as_str()).collect();
            this.inner.borrow_mut().add_primitive(&name, p, e, c);
            Ok(())
        });
        // -- addCompound --
        /// Adds a compound HTN task with one or more ordered method definitions.
        /// @param | comp_name | string | Compound task name.
        /// @param | methods_table | table | Array of method tables with `name`, `preconditions`, and `sub_tasks` fields.
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
                let _ = lua;
                Ok(())
            },
        );
        // -- plan --
        /// Plans from a root HTN task and numeric world state facts.
        /// @param | root_task | string | Root task name to decompose.
        /// @param | state_table | table | Map table from fact names to numeric values.
        /// @return | LuaValue | Array table of primitive task names, or nil when no plan is found.
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
        /// Returns the number of tasks defined in this HTN domain.
        /// @return | integer | Current task count.
        methods.add_method("taskCount", |_, this, ()| {
            Ok(this.inner.borrow().task_count() as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this HTN domain handle.
        /// @return | string | The string `LHTNDomain`.
        methods.add_method("type", |_, _, ()| Ok("LHTNDomain"));
        // -- typeOf --
        /// Returns whether this HTN domain handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LHTNDomain` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHTNDomain" || name == "Object")
        });
    }
}
/// Lua handle for Monte Carlo tree search over Lua-defined game states and actions.
#[derive(Clone)]
struct LuaMCTSEngine {
    /// Shared MCTS engine containing search configuration and deterministic state.
    inner: Rc<RefCell<MCTSEngine>>,
}
impl LuaUserData for LuaMCTSEngine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- search --
        /// Runs MCTS from a root state using Lua callbacks for actions, transitions, and evaluation.
        /// @param | root_state | integer | Opaque integer state identifier supplied by game code.
        /// @param | get_actions_fn | function | Function called with a state and returning an array of integer actions.
        /// @param | apply_fn | function | Function called with `(state, action)` and returning the next state integer.
        /// @param | eval_fn | function | Function called with a state and returning a numeric score.
        /// @return | LuaValue | Selected action integer, or nil when search cannot choose an action.
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
        /// Returns the Lua-visible type name for this MCTS engine handle.
        /// @return | string | The string `LMCTSEngine`.
        methods.add_method("type", |_, _, ()| Ok("LMCTSEngine"));
        // -- typeOf --
        /// Returns whether this MCTS engine handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LMCTSEngine` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMCTSEngine" || name == "Object")
        });
    }
}
/// Lua handle for decaying named emotion intensities.
#[derive(Clone)]
struct LuaEmotionModel {
    /// Shared emotion model containing emotion definitions and current intensities.
    inner: Rc<RefCell<EmotionModel>>,
}
impl LuaUserData for LuaEmotionModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds an emotion definition with resting value, decay, and visibility threshold.
        /// @param | name | string | Emotion name.
        /// @param | rest | number | Resting emotion value.
        /// @param | decay | number | Decay rate back toward rest.
        /// @param | min_vis | number | Minimum value considered visible or active.
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
        /// Adds an amount to a named emotion. This method is available to Lua scripts.
        /// @param | name | string | Emotion name to trigger.
        /// @param | amount | number | Amount added to the current emotion value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("trigger", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().trigger(&name, amount);
            Ok(())
        });
        // -- get --
        /// Returns the current value of a named emotion.
        /// @param | name | string | Emotion name to read.
        /// @return | number | Current emotion value.
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });
        // -- dominant --
        /// Returns the strongest active emotion name when one is available.
        /// @return | LuaValue | Dominant emotion name, or nil when no emotion is active.
        methods.add_method("dominant", |_, this, ()| {
            Ok(this.inner.borrow().dominant().map(|s| s.to_string()))
        });
        // -- isActive --
        /// Returns whether a named emotion is currently active.
        /// @param | name | string | Emotion name to check.
        /// @return | boolean | True when the emotion is above its active threshold.
        methods.add_method("isActive", |_, this, name: String| {
            Ok(this.inner.borrow().is_active(&name))
        });
        // -- update --
        /// Advances emotion decay over elapsed time.
        /// @param | dt | number | Elapsed time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- reset --
        /// Resets all emotions toward their default state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this emotion model handle.
        /// @return | string | The string `LEmotionModel`.
        methods.add_method("type", |_, _, ()| Ok("LEmotionModel"));
        // -- typeOf --
        /// Returns whether this emotion model handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LEmotionModel` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LEmotionModel" || name == "Object")
        });
    }
}
/// Lua handle for reciprocal velocity obstacle avoidance agents.
#[derive(Clone)]
struct LuaORCASolver {
    /// Shared ORCA solver containing agent state and time horizon settings.
    inner: Rc<RefCell<ORCASolver>>,
}
impl LuaUserData for LuaORCASolver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addAgent --
        /// Adds an ORCA avoidance agent and returns its zero-based solver index.
        /// @param | x | number | Initial X position.
        /// @param | y | number | Initial Y position.
        /// @param | radius | number | Collision radius.
        /// @param | max_speed | number | Maximum preferred speed.
        /// @return | integer | Zero-based ORCA agent index.
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
        /// Sets the preferred velocity for an ORCA agent by zero-based index.
        /// @param | idx | integer | Zero-based ORCA agent index.
        /// @param | pvx | number | Preferred X velocity.
        /// @param | pvy | number | Preferred Y velocity.
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
        /// Sets the position for an ORCA agent by zero-based index.
        /// @param | idx | integer | Zero-based ORCA agent index.
        /// @param | x | number | New X position.
        /// @param | y | number | New Y position.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPosition", |_, this, (idx, x, y): (usize, f32, f32)| {
            if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                a.position = (x, y);
            }
            Ok(())
        });
        // -- compute --
        /// Computes safe velocities for all ORCA agents.
        /// @param | dt | number | Elapsed time in seconds for the avoidance step.
        /// @return | nil | No value is returned.
        methods.add_method_mut("compute", |_, this, dt: f32| {
            this.inner.borrow_mut().compute(dt);
            Ok(())
        });
        // -- getSafeVelocity --
        /// Returns the computed safe velocity for an ORCA agent.
        /// @param | idx | integer | Zero-based ORCA agent index.
        /// @return | number, number | Safe X and Y velocity, or zero velocity for an invalid index.
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
        /// Returns the number of ORCA agents in this solver.
        /// @return | integer | Current ORCA agent count.
        methods.add_method("agentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count() as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this ORCA solver handle.
        /// @return | string | The string `LORCASolver`.
        methods.add_method("type", |_, _, ()| Ok("LORCASolver"));
        // -- typeOf --
        /// Returns whether this ORCA solver handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LORCASolver` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LORCASolver" || name == "Object")
        });
    }
}
/// Lua handle for a feed-forward neural network.
#[derive(Clone)]
struct LuaNeuralNet {
    /// Shared neural network containing layers and flattened weights.
    inner: Rc<RefCell<NeuralNet>>,
}
impl LuaUserData for LuaNeuralNet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds a neural network layer with an activation function.
        /// @param | inputs | integer | Input count for the layer.
        /// @param | outputs | integer | Output count for the layer.
        /// @param | activation | string | Activation name such as `relu`, `sigmoid`, `tanh`, `linear`, or `softmax`.
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
        /// Runs a forward pass and returns output values.
        /// @param | input | table | Array of numeric input values.
        /// @return | table | Array of numeric output values.
        methods.add_method("forward", |lua, this, input: Vec<f32>| {
            let out = this.inner.borrow().forward(&input);
            let t = lua.create_table()?;
            for (i, v) in out.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });
        // -- setWeights --
        /// Replaces the network weights from a flat numeric array.
        /// @param | weights | table | Flat array of numeric weights in engine layer order.
        /// @return | boolean | True when the supplied weight slice matches the network shape.
        methods.add_method_mut("setWeights", |_, this, weights: Vec<f32>| {
            Ok(this.inner.borrow_mut().set_weights(&weights))
        });
        // -- getWeights --
        /// Returns the network weights as a flat numeric array.
        /// @return | table | Flat array of numeric weights in engine layer order.
        methods.add_method("getWeights", |lua, this, ()| {
            let w = this.inner.borrow().get_weights();
            let t = lua.create_table()?;
            for (i, v) in w.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });
        // -- paramCount --
        /// Returns the total number of trainable parameters.
        /// @return | integer | Parameter count.
        methods.add_method("paramCount", |_, this, ()| {
            Ok(this.inner.borrow().param_count() as i64)
        });
        // -- layerCount --
        /// Returns the number of layers in the network.
        /// @return | integer | Layer count.
        methods.add_method("layerCount", |_, this, ()| {
            Ok(this.inner.borrow().layer_count() as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this neural network handle.
        /// @return | string | The string `LNeuralNet`.
        methods.add_method("type", |_, _, ()| Ok("LNeuralNet"));
        // -- typeOf --
        /// Returns whether this neural network handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LNeuralNet` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuralNet" || name == "Object")
        });
    }
}
/// Lua handle for a floating-point genetic algorithm population.
#[derive(Clone)]
struct LuaGeneticAlgorithm {
    /// Shared genetic algorithm population and generation state.
    inner: Rc<RefCell<GeneticAlgorithm>>,
}
impl LuaUserData for LuaGeneticAlgorithm {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evolve --
        /// Advances the genetic algorithm by one generation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });
        // -- generation --
        /// Returns the current generation index.
        /// @return | integer | Current generation count.
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });
        // -- popSize --
        /// Returns the population size. This method is available to Lua scripts.
        /// @return | integer | Current population size.
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });
        // -- setFitness --
        /// Sets the fitness value for a chromosome by zero-based index.
        /// @param | idx | integer | Zero-based chromosome index.
        /// @param | fitness | number | Fitness value used by the next evolution step.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            if let Some(c) = this.inner.borrow_mut().population.get_mut(idx) {
                c.fitness = fitness;
            }
            Ok(())
        });
        // -- getGenes --
        /// Returns the genes for a chromosome by zero-based index.
        /// @param | idx | integer | Zero-based chromosome index.
        /// @return | table | Array of gene values, or an empty table for an invalid index.
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
        /// Returns the genes for the best chromosome in the population.
        /// @return | table | Array of best gene values, or an empty table when the population has no best chromosome.
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
        /// Returns the Lua-visible type name for this genetic algorithm handle.
        /// @return | string | The string `LGeneticAlgorithm`.
        methods.add_method("type", |_, _, ()| Ok("LGeneticAlgorithm"));
        // -- typeOf --
        /// Returns whether this genetic algorithm handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGeneticAlgorithm` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGeneticAlgorithm" || name == "Object")
        });
    }
}
/// Lua handle for multi-armed bandit action selection.
#[derive(Clone)]
struct LuaBandit {
    /// Shared bandit model containing arm statistics and strategy state.
    inner: Rc<RefCell<Bandit>>,
}
impl LuaUserData for LuaBandit {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- select --
        /// Selects an arm using the configured bandit strategy.
        /// @return | integer | Zero-based selected arm index.
        methods.add_method_mut("select", |_, this, ()| {
            Ok(this.inner.borrow_mut().select() as i64)
        });
        // -- update --
        /// Updates one arm with a received reward.
        /// @param | idx | integer | Zero-based arm index.
        /// @param | reward | number | Reward value assigned to the arm pull.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, (idx, reward): (usize, f64)| {
            this.inner.borrow_mut().update(idx, reward);
            Ok(())
        });
        // -- bestArm --
        /// Returns the arm with the best current estimate.
        /// @return | integer | Zero-based best arm index.
        methods.add_method("bestArm", |_, this, ()| {
            Ok(this.inner.borrow().best_arm() as i64)
        });
        // -- reset --
        /// Resets all bandit arm statistics. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        // -- armCount --
        /// Returns the number of arms in this bandit.
        /// @return | integer | Arm count.
        methods.add_method("armCount", |_, this, ()| {
            Ok(this.inner.borrow().arm_count() as i64)
        });
        // -- totalPulls --
        /// Returns the total number of arm selections recorded by this bandit.
        /// @return | integer | Total pull count.
        methods.add_method("totalPulls", |_, this, ()| {
            Ok(this.inner.borrow().total_pulls as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this bandit handle.
        /// @return | string | The string `LBandit`.
        methods.add_method("type", |_, _, ()| Ok("LBandit"));
        // -- typeOf --
        /// Returns whether this bandit handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LBandit` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBandit" || name == "Object")
        });
    }
}
/// Lua handle for evolving neural network chromosomes.
#[derive(Clone)]
struct LuaNeuroevolution {
    /// Shared neuroevolution population and generation state.
    inner: Rc<RefCell<Neuroevolution>>,
}
impl LuaUserData for LuaNeuroevolution {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evolve --
        /// Advances the neuroevolution population by one generation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });
        // -- setFitness --
        /// Sets the fitness value for a chromosome by zero-based index.
        /// @param | idx | integer | Zero-based chromosome index.
        /// @param | fitness | number | Fitness value used by the next evolution step.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            this.inner.borrow_mut().set_fitness(idx, fitness);
            Ok(())
        });
        // -- chromosomeToNet --
        /// Converts one chromosome into a neural network handle when the index is valid.
        /// @param | idx | integer | Zero-based chromosome index.
        /// @return | LuaValue | Neural network handle, or nil when the chromosome index is invalid.
        methods.add_method("chromosomeToNet", |_, this, idx: usize| {
            let net = this.inner.borrow().chromosome_to_net(idx);
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });
        // -- bestNetwork --
        /// Converts the best chromosome into a neural network handle when one exists.
        /// @return | LuaValue | Neural network handle, or nil when no best chromosome is available.
        methods.add_method("bestNetwork", |_, this, ()| {
            let net = this.inner.borrow().best_network();
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });
        // -- bestFitness --
        /// Returns the best fitness value in the population.
        /// @return | number | Best fitness value.
        methods.add_method("bestFitness", |_, this, ()| {
            Ok(this.inner.borrow().best_fitness())
        });
        // -- popSize --
        /// Returns the population size. This method is available to Lua scripts.
        /// @return | integer | Current population size.
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });
        // -- generation --
        /// Returns the current generation index.
        /// @return | integer | Current generation count.
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });
        // -- type --
        /// Returns the Lua-visible type name for this neuroevolution handle.
        /// @return | string | The string `LNeuroevolution`.
        methods.add_method("type", |_, _, ()| Ok("LNeuroevolution"));
        // -- typeOf --
        /// Returns whether this neuroevolution handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LNeuroevolution` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuroevolution" || name == "Object")
        });
    }
}
/// Lua handle for interval-based strategic goal selection.
#[derive(Clone)]
struct LuaStrategyAI {
    /// Shared strategy AI model containing goals, tags, timing, and active selection.
    inner: Rc<RefCell<StrategyAI>>,
}
impl LuaUserData for LuaStrategyAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addGoal --
        /// Adds a named strategic goal. This method is available to Lua scripts.
        /// @param | name | string | Goal name scored by update callbacks.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addGoal", |_, this, name: String| {
            this.inner.borrow_mut().add_goal_named(&name);
            Ok(())
        });
        // -- addTag --
        /// Adds a context tag to this strategy AI.
        /// @param | tag | string | Tag name to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(&tag);
            Ok(())
        });
        // -- removeTag --
        /// Removes a context tag from this strategy AI.
        /// @param | tag | string | Tag name to remove.
        /// @return | nil | No value is returned.
        methods.add_method_mut("removeTag", |_, this, tag: String| {
            this.inner.borrow_mut().remove_tag(&tag);
            Ok(())
        });
        // -- update --
        /// Advances strategy timing and scores goals when the update interval has elapsed.
        /// @param | dt | number | Elapsed time in seconds.
        /// @param | scorer_fn | function | Function called with a goal name and returning a numeric score.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, (dt, scorer_fn): (f32, LuaFunction)| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().update(dt, &mut scorer);
            Ok(())
        });
        // -- forceEvaluate --
        /// Immediately scores all goals and updates the active goal.
        /// @param | scorer_fn | function | Function called with a goal name and returning a numeric score.
        /// @return | nil | No value is returned.
        methods.add_method_mut("forceEvaluate", |_, this, scorer_fn: LuaFunction| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().force_evaluate(&mut scorer);
            Ok(())
        });
        // -- activeGoal --
        /// Returns the currently active strategic goal when one is selected.
        /// @return | LuaValue | Active goal name, or nil before selection.
        methods.add_method("activeGoal", |_, this, ()| {
            Ok(this.inner.borrow().active_goal().map(|s| s.to_string()))
        });
        // -- timeUntilNext --
        /// Returns time remaining until the next scheduled strategy evaluation.
        /// @return | number | Seconds until the next interval evaluation.
        methods.add_method("timeUntilNext", |_, this, ()| {
            Ok(this.inner.borrow().time_until_next())
        });
        // -- type --
        /// Returns the Lua-visible type name for this strategy AI handle.
        /// @return | string | The string `LStrategyAI`.
        methods.add_method("type", |_, _, ()| Ok("LStrategyAI"));
        // -- typeOf --
        /// Returns whether this strategy AI handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LStrategyAI` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStrategyAI" || name == "Object")
        });
    }
}
/// Lua handle for distance-based AI level-of-detail tier selection.
#[derive(Clone)]
struct LuaAILod {
    /// Shared AI LOD tier table and update cadence rules.
    inner: Rc<RefCell<AILod>>,
}
impl LuaUserData for LuaAILod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- tierFor --
        /// Returns the LOD tier for an agent position relative to a reference position.
        /// @param | ax | number | Agent X position.
        /// @param | ay | number | Agent Y position.
        /// @param | rx | number | Reference X position, usually camera or player position.
        /// @param | ry | number | Reference Y position, usually camera or player position.
        /// @return | integer | Zero-based LOD tier index.
        methods.add_method(
            "tierFor",
            |_, this, (ax, ay, rx, ry): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().tier_for((ax, ay), (rx, ry)) as i64)
            },
        );
        // -- shouldUpdate --
        /// Returns whether a tier should update on a given frame counter.
        /// @param | tier | integer | Zero-based LOD tier index.
        /// @param | frame | integer | Current frame counter.
        /// @return | boolean | True when agents in the tier should update this frame.
        methods.add_method("shouldUpdate", |_, this, (tier, frame): (usize, u64)| {
            Ok(this.inner.borrow().should_update(tier, frame))
        });
        // -- tierCount --
        /// Returns the number of configured AI LOD tiers.
        /// @return | integer | LOD tier count.
        methods.add_method("tierCount", |_, this, ()| {
            Ok(this.inner.borrow().tier_count() as i64)
        });
        // -- tierName --
        /// Returns the name of an AI LOD tier when the index is valid.
        /// @param | tier | integer | Zero-based LOD tier index.
        /// @return | LuaValue | Tier name, or nil when the tier index is invalid.
        methods.add_method("tierName", |_, this, tier: usize| {
            Ok(this.inner.borrow().tier(tier).map(|t| t.name.clone()))
        });
        // -- type --
        /// Returns the Lua-visible type name for this AI LOD handle.
        /// @return | string | The string `LAILod`.
        methods.add_method("type", |_, _, ()| Ok("LAILod"));
        // -- typeOf --
        /// Returns whether this AI LOD handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAILod` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAILod" || name == "Object")
        });
    }
}
/// Registers the `lurek.ai` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newWorld --
    /// Creates an isolated AI world for agents, blackboards, and custom decision callbacks.
    /// @return | LAIWorld | New AI world handle.
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
    /// Creates an empty AI blackboard for typed local facts.
    /// @return | LAIBlackboard | New blackboard handle.
    tbl.set(
        "newBlackboard",
        lua.create_function(|_, ()| {
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(Blackboard::new())),
            })
        })?,
    )?;
    // -- newStateMachine --
    /// Creates an empty finite state machine with Lua-backed states and transitions.
    /// @return | LStateMachine | New state machine handle.
    tbl.set(
        "newStateMachine",
        lua.create_function(|_, ()| {
            Ok(LuaStateMachine {
                inner: Rc::new(RefCell::new(crate::ai::StateMachine::new())),
            })
        })?,
    )?;
    // -- newBehaviorTree --
    /// Creates an empty behavior tree that can receive a root node.
    /// @return | LBehaviorTree | New behavior tree handle.
    tbl.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                inner: Rc::new(RefCell::new(BehaviorTree::new())),
            })
        })?,
    )?;
    // -- newSelector --
    /// Creates a behavior tree selector node with no children.
    /// @return | LBTNode | New selector node handle.
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
    /// Creates a behavior tree sequence node with no children.
    /// @return | LBTNode | New sequence node handle.
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
    /// Creates a behavior tree parallel node with optional success and failure policies.
    /// @param | sp | string? | Success policy name; defaults to the engine's require-one policy.
    /// @param | fp | string? | Failure policy name; defaults to the engine's require-one policy.
    /// @return | LBTNode | New parallel node handle.
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
    /// Creates a behavior tree inverter decorator with an empty sequence child.
    /// @return | LBTNode | New inverter node handle.
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
    /// Creates a behavior tree repeater decorator with an optional repeat count.
    /// @param | count | integer? | Repeat count stored on the node; defaults to zero.
    /// @return | LBTNode | New repeater node handle.
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
    /// Creates a behavior tree succeeder decorator with an empty sequence child.
    /// @return | LBTNode | New succeeder node handle.
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
    /// Creates a behavior tree action leaf backed by a Lua callback.
    /// @param | callback | function | Callback invoked when the action node ticks.
    /// @return | LBTNode | New action node handle.
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
    /// Creates a behavior tree condition leaf backed by a Lua callback.
    /// @param | callback | function | Callback invoked when the condition node ticks.
    /// @return | LBTNode | New condition node handle.
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
    /// Creates a guard decorator that runs a predicate before ticking its child.
    /// @param | predicate | function | Callback that decides whether the child may run.
    /// @param | child | LBTNode | Child node handle consumed by the guard.
    /// @return | LBTNode | New guard node handle.
    tbl.set(
        "newGuard",
        lua.create_function(
            |lua, (predicate, child_ud): (LuaFunction, LuaAnyUserData)| {
                let key = lua.create_registry_value(predicate)?;
                let child = child_ud.borrow::<LuaBTNode>()?;
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
    /// Creates an empty steering manager with support for built-in and custom behaviors.
    /// @return | LSteeringManager | New steering manager handle.
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
    /// Creates a Q-learner with fixed state and action counts.
    /// @param | sc | integer | Number of discrete states.
    /// @param | ac | integer | Number of discrete actions.
    /// @return | LQLearner | New Q-learner handle.
    tbl.set(
        "newQLearner",
        lua.create_function(|_, (sc, ac): (usize, usize)| {
            Ok(LuaQLearner {
                inner: Rc::new(RefCell::new(QLearner::new(sc, ac))),
            })
        })?,
    )?;
    // -- newUtilityAI --
    /// Creates an empty utility AI action scorer.
    /// @return | LUtilityAI | New utility AI handle.
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
    /// Creates an empty dialogue selector for weighted topics and branches.
    /// @return | LDialogueAI | New dialogue AI handle.
    tbl.set(
        "newDialogueAI",
        lua.create_function(|_, ()| {
            Ok(LuaDialogueAI {
                inner: Rc::new(RefCell::new(DialogueAI::new())),
            })
        })?,
    )?;
    // -- newGOAPPlanner --
    /// Creates an empty GOAP planner for boolean world-state planning.
    /// @return | LGOAPPlanner | New GOAP planner handle.
    tbl.set(
        "newGOAPPlanner",
        lua.create_function(|_, ()| {
            Ok(LuaGOAPPlanner {
                inner: Rc::new(RefCell::new(GOAPPlanner::new())),
            })
        })?,
    )?;
    // -- newInfluenceMap --
    /// Creates a grid influence map with the supplied cell dimensions and world cell size.
    /// @param | w | integer | Map width in cells.
    /// @param | h | integer | Map height in cells.
    /// @param | cs | number | World size of one cell.
    /// @return | LInfluenceMap | New influence map handle.
    tbl.set(
        "newInfluenceMap",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaInfluenceMap {
                inner: Rc::new(RefCell::new(InfluenceMap::new(w, h, cs))),
            })
        })?,
    )?;
    // -- newSquad --
    /// Creates an empty named squad. This function is exposed to Lua scripts.
    /// @param | name | string | Squad name stored on the handle.
    /// @return | LSquad | New squad handle.
    tbl.set(
        "newSquad",
        lua.create_function(|_, name: String| {
            Ok(LuaSquad {
                inner: Rc::new(RefCell::new(Squad::new(&name))),
            })
        })?,
    )?;
    // -- newCommandQueue --
    /// Creates an empty command queue for callback-backed AI commands.
    /// @return | LCommandQueue | New command queue handle.
    tbl.set(
        "newCommandQueue",
        lua.create_function(|_, ()| {
            Ok(LuaCommandQueue {
                inner: Rc::new(RefCell::new(CommandQueue::new())),
            })
        })?,
    )?;
    // -- newTraitProfile --
    /// Creates an empty trait profile with modifier support.
    /// @return | LTraitProfile | New trait profile handle.
    tbl.set(
        "newTraitProfile",
        lua.create_function(|_, ()| {
            Ok(LuaTraitProfile {
                inner: Rc::new(RefCell::new(TraitProfile::new())),
            })
        })?,
    )?;
    // -- newStimulusWorld --
    /// Creates an empty stimulus world for visual and auditory stimulus records.
    /// @return | LStimulusWorld | New stimulus world handle.
    tbl.set(
        "newStimulusWorld",
        lua.create_function(|_, ()| {
            Ok(LuaStimulusWorld {
                inner: Rc::new(RefCell::new(StimulusWorld::new())),
            })
        })?,
    )?;
    // -- newContextSteering --
    /// Creates a context steering model with the requested directional slot count.
    /// @param | slots | integer | Directional slot count; zero selects the engine default of 16.
    /// @return | LContextSteering | New context steering handle.
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
    /// Creates an empty need system for decaying named needs.
    /// @return | LNeedSystem | New need system handle.
    tbl.set(
        "newNeedSystem",
        lua.create_function(|_, ()| {
            Ok(LuaNeedSystem {
                inner: Rc::new(RefCell::new(NeedSystem::new())),
            })
        })?,
    )?;
    // -- newAIDirector --
    /// Creates an AI director for tension, phase, and pacing factor calculations.
    /// @return | LAIDirector | New AI director handle.
    tbl.set(
        "newAIDirector",
        lua.create_function(|_, ()| {
            Ok(LuaAIDirector {
                inner: Rc::new(RefCell::new(AIDirector::new())),
            })
        })?,
    )?;
    // -- newHTNDomain --
    /// Creates an empty hierarchical task network domain.
    /// @return | LHTNDomain | New HTN domain handle.
    tbl.set(
        "newHTNDomain",
        lua.create_function(|_, ()| {
            Ok(LuaHTNDomain {
                inner: Rc::new(RefCell::new(HTNDomain::new())),
            })
        })?,
    )?;
    // -- newMCTSEngine --
    /// Creates a Monte Carlo tree search engine with deterministic configuration.
    /// @param | iters | integer | Search iteration count.
    /// @param | uct_c | number | UCT exploration constant.
    /// @param | depth | integer | Rollout depth limit.
    /// @param | seed | integer | Random seed used by the engine.
    /// @return | LMCTSEngine | New MCTS engine handle.
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
    /// Creates an empty emotion model for named decaying emotion values.
    /// @return | LEmotionModel | New emotion model handle.
    tbl.set(
        "newEmotionModel",
        lua.create_function(|_, ()| {
            Ok(LuaEmotionModel {
                inner: Rc::new(RefCell::new(EmotionModel::new())),
            })
        })?,
    )?;
    // -- newORCASolver --
    /// Creates an ORCA avoidance solver with the supplied prediction horizon.
    /// @param | time_horizon | number | Time horizon used when computing collision avoidance velocities.
    /// @return | LORCASolver | New ORCA solver handle.
    tbl.set(
        "newORCASolver",
        lua.create_function(|_, time_horizon: f32| {
            Ok(LuaORCASolver {
                inner: Rc::new(RefCell::new(ORCASolver::new(time_horizon))),
            })
        })?,
    )?;
    // -- newNeuralNet --
    /// Creates an empty feed-forward neural network.
    /// @return | LNeuralNet | New neural network handle.
    tbl.set(
        "newNeuralNet",
        lua.create_function(|_, ()| {
            Ok(LuaNeuralNet {
                inner: Rc::new(RefCell::new(NeuralNet::new())),
            })
        })?,
    )?;
    // -- newGeneticAlgorithm --
    /// Creates a genetic algorithm population with fixed chromosome length.
    /// @param | pop_size | integer | Number of chromosomes in the population.
    /// @param | gene_count | integer | Number of floating-point genes per chromosome.
    /// @param | seed | integer | Random seed used for population initialization and evolution.
    /// @return | LGeneticAlgorithm | New genetic algorithm handle.
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
    /// Creates a multi-armed bandit with a named selection strategy.
    /// @param | arm_count | integer | Number of selectable arms.
    /// @param | strategy | string | Strategy name such as `ucb1`, `thompson`, or an epsilon-greedy fallback.
    /// @param | epsilon | number | Exploration probability used by epsilon-greedy strategy and clamped to `[0, 1]`.
    /// @param | seed | integer | Random seed used by the bandit.
    /// @return | LBandit | New bandit handle.
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
    /// Creates a neuroevolution population from a layer specification table.
    /// @param | layer_spec | table | Array of layer tables with `inputs`, `outputs`, and optional `activation` fields.
    /// @param | pop_size | integer | Number of chromosomes in the population.
    /// @param | seed | integer | Random seed used for population initialization and evolution.
    /// @return | LNeuroevolution | New neuroevolution handle.
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
    /// Creates a strategy AI that reevaluates goals on a fixed interval.
    /// @param | update_interval | number | Seconds between automatic strategy evaluations.
    /// @return | LStrategyAI | New strategy AI handle.
    tbl.set(
        "newStrategyAI",
        lua.create_function(|_, update_interval: f32| {
            Ok(LuaStrategyAI {
                inner: Rc::new(RefCell::new(StrategyAI::new(update_interval))),
            })
        })?,
    )?;
    // -- newAILod --
    /// Creates a default AI level-of-detail tier selector.
    /// @return | LAILod | New AI LOD handle.
    tbl.set(
        "newAILod",
        lua.create_function(|_, ()| {
            Ok(LuaAILod {
                inner: Rc::new(RefCell::new(AILod::default())),
            })
        })?,
    )?;
    lurek.set("ai", tbl)?;
    Ok(())
}
