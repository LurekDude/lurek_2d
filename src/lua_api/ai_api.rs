//! `lurek.ai` — Game AI toolkit: worlds, agents, FSM, behavior trees, steering, Q-learning, utility AI, GOAP, squads, and command queues.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::ai::{
    AIWorld, BTNode, BehaviorTree, Blackboard, CommandQueue, DecisionModel, FormationType,
    GOAPAction, GOAPGoal, GOAPPlanner, ParallelPolicy, QLearner, Squad,
    SteeringManager, UAAction, UtilityAI,
};
use crate::pathfind::InfluenceMap;

// -------------------------------------------------------------------------------
// LuaAIWorld UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AIWorld`].
#[derive(Clone)]
struct LuaAIWorld {
    inner: Rc<RefCell<AIWorld>>,
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
            })
        });

        // -- getAgent --
        /// Returns the agent handle for the given name, or nil.
        /// @param name : string
        /// @return Agent?
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
        /// Advances all agents by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "AIWorld" || name == "Object"));

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
}

impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- getName --
        /// Returns the agent's registered name.
        /// @return string
        methods.add_method("getName", |_, this, ()| {
            Ok(this.name.clone())
        });

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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "Agent" || name == "Object"));

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
        methods.add_method("getSize", |_, this, ()| {
            Ok(this.inner.borrow().size())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Blackboard"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "Blackboard" || name == "Object"));

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
            let update_key = on_update.map(|f| lua.create_registry_value(f)).transpose()?;
            let exit_key = on_exit.map(|f| lua.create_registry_value(f)).transpose()?;
            this.inner.borrow_mut().add_state_raw(name, enter_key, update_key, exit_key);
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
        /// Sets the initial state.
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "StateMachine" || name == "Object"));

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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("BehaviorTree"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "BehaviorTree" || name == "Object"));

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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "BTNode" || name == "Object"));

    }
}

// -------------------------------------------------------------------------------
// LuaSteeringManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SteeringManager`].
#[derive(Clone)]
struct LuaSteeringManager {
    inner: Rc<RefCell<SteeringManager>>,
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
                this.inner.borrow_mut().add_seek(tx, ty, weight.unwrap_or(1.0));
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
                this.inner.borrow_mut().add_flee(tx, ty, panic_dist.unwrap_or(200.0), weight.unwrap_or(1.0));
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
                this.inner.borrow_mut().add_arrive(tx, ty, slowing.unwrap_or(50.0), weight.unwrap_or(1.0));
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
            |_, this, (radius, dist, jitter, weight): (Option<f32>, Option<f32>, Option<f32>, Option<f32>)| {
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
                this.inner.borrow_mut().add_pursue(target_name, weight.unwrap_or(1.0));
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
                this.inner.borrow_mut().add_evade(threat_name, weight.unwrap_or(1.0));
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
            |_, this, (neighbor_radius, sep_w, align_w, coh_w, weight): (Option<f32>, Option<f32>, Option<f32>, Option<f32>, Option<f32>)| {
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "SteeringManager" || name == "Object"));

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
            Ok(this.inner.borrow().get_q(
                state.saturating_sub(1),
                action.saturating_sub(1),
            ))
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "QLearner" || name == "Object"));

    }
}

// -------------------------------------------------------------------------------
// LuaUtilityAI UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`UtilityAI`].
#[derive(Clone)]
struct LuaUtilityAI {
    inner: Rc<RefCell<UtilityAI>>,
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("UtilityAI"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "UtilityAI" || name == "Object"));

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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("GOAPPlanner"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "GOAPPlanner" || name == "Object"));

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
                this.inner.borrow_mut().propagate(&layer, momentum.unwrap_or(0.5));
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
        /// Clears all layers.
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
        /// Returns the grid width.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.borrow().width)
        });

        // -- getHeight --
        /// Returns the grid height.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.borrow().height)
        });

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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "InfluenceMap" || name == "Object"));

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
        /// Returns the squad name.
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
                Ok(this.inner.borrow().get_formation_position(
                    member_idx.saturating_sub(1),
                    (leader_x, leader_y),
                ))
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "Squad" || name == "Object"));

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
                this.inner.borrow_mut().enqueue_raw(kind, tx, ty, priority, interruptible, key);
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
                this.inner.borrow_mut().push_front_raw(kind, tx, ty, priority, interruptible, key);
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
                this.inner.borrow_mut().replace_raw(kind, tx, ty, priority, interruptible, key);
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
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.inner.borrow().count())
        });

        // -- isEmpty --
        /// Returns true if there are no queued commands.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| {
            Ok(this.inner.borrow().is_empty())
        });

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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "CommandQueue" || name == "Object"));

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.ai` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── newWorld ─────────────────────────────────────────────────────────────
    /// Creates a new AI world container.
    /// @return AIWorld
    tbl.set(
        "newWorld",
        lua.create_function(|_, ()| {
            Ok(LuaAIWorld {
                inner: Rc::new(RefCell::new(AIWorld::new())),
            })
        })?,
    )?;

    // ── newBlackboard ────────────────────────────────────────────────────────
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

    // ── newStateMachine ──────────────────────────────────────────────────────
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

    // ── newBehaviorTree ──────────────────────────────────────────────────────
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

    // ── newSelector ──────────────────────────────────────────────────────────
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

    // ── newSequence ──────────────────────────────────────────────────────────
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

    // ── newParallel ──────────────────────────────────────────────────────────
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

    // ── newInverter ──────────────────────────────────────────────────────────
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

    // ── newRepeater ──────────────────────────────────────────────────────────
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

    // ── newSucceeder ─────────────────────────────────────────────────────────
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

    // ── newAction ────────────────────────────────────────────────────────────
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

    // ── newCondition ─────────────────────────────────────────────────────────
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

    // ── newSteeringManager ───────────────────────────────────────────────────
    /// Creates a new steering behavior manager.
    /// @return SteeringManager
    tbl.set(
        "newSteeringManager",
        lua.create_function(|_, ()| {
            Ok(LuaSteeringManager {
                inner: Rc::new(RefCell::new(SteeringManager::new())),
            })
        })?,
    )?;

    // ── newQLearner ──────────────────────────────────────────────────────────
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

    // ── newUtilityAI ─────────────────────────────────────────────────────────
    /// Creates a new utility AI evaluator.
    /// @return UtilityAI
    tbl.set(
        "newUtilityAI",
        lua.create_function(|_, ()| {
            Ok(LuaUtilityAI {
                inner: Rc::new(RefCell::new(UtilityAI::new())),
            })
        })?,
    )?;

    // ── newGOAPPlanner ───────────────────────────────────────────────────────
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

    // ── newInfluenceMap ──────────────────────────────────────────────────────
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

    // ── newSquad ─────────────────────────────────────────────────────────────
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

    // ── newCommandQueue ──────────────────────────────────────────────────────
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

    luna.set("ai", tbl)?;
    Ok(())
}
