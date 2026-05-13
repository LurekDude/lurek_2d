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
#[derive(Clone)]
struct LuaAIWorld {
    inner: Rc<RefCell<AIWorld>>,
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaAIWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addAgent", |_, this, name: String| {
            let mut w = this.inner.borrow_mut();
            w.add_agent(&name).map_err(LuaError::RuntimeError)?;
            Ok(LuaAgent {
                world: this.inner.clone(),
                name,
                callbacks: this.custom_callbacks.clone(),
            })
        });
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
        methods.add_method("removeAgent", |_, this, agent: LuaAnyUserData| {
            let a = agent.borrow::<LuaAgent>()?;
            this.inner.borrow_mut().remove_agent(&a.name);
            Ok(())
        });
        methods.add_method("getAgentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count())
        });
        methods.add_method("getGlobalBlackboard", |_, this, ()| {
            let w = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(w.global_blackboard().clone())),
            })
        });
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
        methods.add_method("type", |_, _, ()| Ok("LAIWorld"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIWorld" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaAgent {
    world: Rc<RefCell<AIWorld>>,
    name: String,
    callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaAgent {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getName", |_, this, ()| Ok(this.name.clone()));
        methods.add_method("setPosition", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].position = (x, y);
            }
            Ok(())
        });
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].position)
            } else {
                Ok((0.0, 0.0))
            }
        });
        methods.add_method("setVelocity", |_, this, (x, y): (f32, f32)| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].velocity = (x, y);
            }
            Ok(())
        });
        methods.add_method("getVelocity", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].velocity)
            } else {
                Ok((0.0, 0.0))
            }
        });
        methods.add_method("setMaxSpeed", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_speed = v;
            }
            Ok(())
        });
        methods.add_method("getMaxSpeed", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_speed)
            } else {
                Ok(100.0)
            }
        });
        methods.add_method("setMaxForce", |_, this, v: f32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].max_force = v;
            }
            Ok(())
        });
        methods.add_method("getMaxForce", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].max_force)
            } else {
                Ok(200.0)
            }
        });
        methods.add_method("setPriority", |_, this, p: i32| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].priority = p;
            }
            Ok(())
        });
        methods.add_method("getPriority", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].priority)
            } else {
                Ok(0)
            }
        });
        methods.add_method("setDecisionModel", |_, this, model: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                if let Some(dm) = DecisionModel::parse_str(&model) {
                    w.agents[idx].decision_model = dm;
                }
            }
            Ok(())
        });
        methods.add_method("getDecisionModel", |_, this, ()| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].decision_model.as_str().to_string())
            } else {
                Ok("fsm".to_string())
            }
        });
        methods.add_method("setCustomModel", |lua, this, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            let callback_id = this.callbacks.borrow_mut().register(key);
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].decision_model = crate::ai::DecisionModel::Custom { callback_id };
            }
            Ok(())
        });
        methods.add_method("addTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.insert(tag);
            }
            Ok(())
        });
        methods.add_method("removeTag", |_, this, tag: String| {
            let mut w = this.world.borrow_mut();
            if let Some(idx) = w.get_agent_index(&this.name) {
                w.agents[idx].tags.remove(&tag);
            }
            Ok(())
        });
        methods.add_method("hasTag", |_, this, tag: String| {
            let w = this.world.borrow();
            if let Some(idx) = w.get_agent_index(&this.name) {
                Ok(w.agents[idx].tags.contains(&tag))
            } else {
                Ok(false)
            }
        });
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
        methods.add_method("type", |_, _, ()| Ok("LAgent"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Agent" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaAIBlackboard {
    inner: Rc<RefCell<Blackboard>>,
}
impl LuaUserData for LuaAIBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("has", |_, this, key: String| {
            Ok(this.inner.borrow().has(&key))
        });
        methods.add_method("remove", |_, this, key: String| {
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("getKeys", |lua, this, ()| {
            let keys = this.inner.borrow().keys();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i as i64 + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().size()));
        methods.add_method("type", |_, _, ()| Ok("LAIBlackboard"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "AIBlackboard" || name == "Blackboard" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaStateMachine {
    inner: Rc<RefCell<crate::ai::StateMachine>>,
}
impl LuaUserData for LuaStateMachine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("addTransition", |lua, this, (from, to, guard, priority): (String, String, Option<LuaFunction>, Option<i32>)| {
                let guard_key = guard.map(|f| lua.create_registry_value(f)).transpose()?;
                this.inner.borrow_mut().add_transition_raw(from, to, priority.unwrap_or(0), guard_key);
                Ok(())
            },
        );
        methods.add_method("setInitialState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.initial_state = Some(name.clone());
            if fsm.current_state.is_none() {
                fsm.current_state = Some(name);
            }
            Ok(())
        });
        methods.add_method("getCurrentState", |_, this, ()| {
            Ok(this.inner.borrow().current_state().map(|s| s.to_string()))
        });
        methods.add_method("forceState", |_, this, name: String| {
            let mut fsm = this.inner.borrow_mut();
            fsm.current_state = Some(name);
            fsm.time_in_state = 0.0;
            Ok(())
        });
        methods.add_method("getTimeInState", |_, this, ()| {
            Ok(this.inner.borrow().time_in_state())
        });
        methods.add_method("type", |_, _, ()| Ok("LStateMachine"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "StateMachine" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaBehaviorTree {
    inner: Rc<RefCell<BehaviorTree>>,
}
impl LuaUserData for LuaBehaviorTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getLastStatus", |_, this, ()| {
            Ok(this.inner.borrow().last_status.as_str().to_string())
        });
        methods.add_method("getDebugState", |lua, this, ()| {
            let dbg = this.inner.borrow().debug_state();
            let t = lua.create_table()?;
            t.set("node_count", dbg.node_count as u32)?;
            t.set("last_status", dbg.last_status)?;
            Ok(t)
        });
        methods.add_method("type", |_, _, ()| Ok("LBehaviorTree"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BehaviorTree" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaBTNode {
    inner: Rc<RefCell<BTNode>>,
}
impl LuaUserData for LuaBTNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getChildCount", |_, this, ()| {
            Ok(this.inner.borrow().child_count())
        });
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
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
        methods.add_method("setCount", |_, this, n: u32| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Repeater { count, .. } = &mut *node {
                *count = n;
            }
            Ok(())
        });
        methods.add_method("getCount", |_, this, ()| {
            let node = this.inner.borrow();
            if let BTNode::Repeater { count, .. } = &*node {
                Ok(*count)
            } else {
                Ok(0)
            }
        });
        methods.add_method("setSuccessPolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { success_policy, .. } = &mut *node {
                *success_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });
        methods.add_method("setFailurePolicy", |_, this, policy: String| {
            let mut node = this.inner.borrow_mut();
            if let BTNode::Parallel { failure_policy, .. } = &mut *node {
                *failure_policy = ParallelPolicy::parse_str(&policy);
            }
            Ok(())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LBTNode"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BTNode" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaSteeringManager {
    inner: Rc<RefCell<SteeringManager>>,
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaSteeringManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "addSeek",
            |_, this, (tx, ty, weight): (f32, f32, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_seek(tx, ty, weight.unwrap_or(1.0));
                Ok(())
            },
        );
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
        methods.add_method(
            "addPursue",
            |_, this, (target_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_pursue(target_name, weight.unwrap_or(1.0));
                Ok(())
            },
        );
        methods.add_method(
            "addEvade",
            |_, this, (threat_name, weight): (Option<String>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .add_evade(threat_name, weight.unwrap_or(1.0));
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
        methods.add_method("getBehaviorCount", |_, this, ()| {
            Ok(this.inner.borrow().behaviors.len())
        });
        methods.add_method("setCombineMode", |_, this, mode: String| {
            this.inner.borrow_mut().set_combine_mode_str(&mode);
            Ok(())
        });
        methods.add_method("getCombineMode", |_, this, ()| {
            Ok(this.inner.borrow().combine_mode.as_str().to_string())
        });
        methods.add_method("getLastSteering", |_, this, ()| {
            Ok(this.inner.borrow().last_force())
        });
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
        methods.add_method("clearPath", |_, this, ()| {
            this.inner.borrow_mut().clear_path();
            Ok(())
        });
        methods.add_method("hasPath", |_, this, ()| {
            Ok(this.inner.borrow().has_active_path())
        });
        methods.add_method("getPathProgress", |_, this, ()| {
            let (idx, total) = this.inner.borrow().path_progress();
            Ok((idx + 1, total))
        });
        methods.add_method("type", |_, _, ()| Ok("LSteeringManager"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SteeringManager" || name == "Object")
        });
        methods.add_method_mut("setSpatialHashCellSize", |_, this, size: f32| {
            this.inner.borrow_mut().set_cell_size(size);
            Ok(())
        });
        methods.add_method_mut("enableSpatialHash", |_, this, enabled: bool| {
            this.inner.borrow_mut().set_use_spatial_hash(enabled);
            Ok(())
        });
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
#[derive(Clone)]
struct LuaDialogueAI {
    inner: Rc<RefCell<DialogueAI>>,
}
impl LuaUserData for LuaDialogueAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("setFSMState", |_, this, state: Option<String>| {
            this.inner.borrow_mut().set_fsm_state(state);
            Ok(())
        });
        methods.add_method("setBTStatus", |_, this, status: Option<String>| {
            this.inner.borrow_mut().set_bt_status(status);
            Ok(())
        });
        methods.add_method("setUtilityScore", |_, this, (key, score): (String, f32)| {
            this.inner.borrow_mut().set_utility_score(key, score);
            Ok(())
        });
        methods.add_method("clearUtilityScores", |_, this, ()| {
            this.inner.borrow_mut().clear_utility_scores();
            Ok(())
        });
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
        methods.add_method("selectTopic", |_, this, ()| {
            Ok(this.inner.borrow().select_topic())
        });
        methods.add_method("selectBranch", |_, this, topic_id: String| {
            Ok(this.inner.borrow().select_branch(&topic_id))
        });
        methods.add_method("getTopicCount", |_, this, ()| {
            Ok(this.inner.borrow().topic_count())
        });
        methods.add_method("type", |_, _, ()| Ok("LDialogueAI"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "DialogueAI" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaQLearner {
    inner: Rc<RefCell<QLearner>>,
}
impl LuaUserData for LuaQLearner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("chooseAction", |_, this, state: usize| {
            Ok(this.inner.borrow().choose_action(state.saturating_sub(1)) + 1)
        });
        methods.add_method("bestAction", |_, this, state: usize| {
            Ok(this.inner.borrow().best_action(state.saturating_sub(1)) + 1)
        });
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
        methods.add_method("getQValue", |_, this, (state, action): (usize, usize)| {
            Ok(this
                .inner
                .borrow()
                .get_q(state.saturating_sub(1), action.saturating_sub(1)))
        });
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
        methods.add_method("endEpisode", |_, this, ()| {
            this.inner.borrow_mut().end_episode();
            Ok(())
        });
        methods.add_method("getEpisodeCount", |_, this, ()| {
            Ok(this.inner.borrow().episode_count)
        });
        methods.add_method("getStateCount", |_, this, ()| {
            Ok(this.inner.borrow().state_count)
        });
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().action_count)
        });
        methods.add_method("setLearningRate", |_, this, v: f64| {
            this.inner.borrow_mut().alpha = v;
            Ok(())
        });
        methods.add_method("getLearningRate", |_, this, ()| {
            Ok(this.inner.borrow().alpha)
        });
        methods.add_method("setDiscountFactor", |_, this, v: f64| {
            this.inner.borrow_mut().gamma = v;
            Ok(())
        });
        methods.add_method("getDiscountFactor", |_, this, ()| {
            Ok(this.inner.borrow().gamma)
        });
        methods.add_method("setExplorationRate", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon = v;
            Ok(())
        });
        methods.add_method("getExplorationRate", |_, this, ()| {
            Ok(this.inner.borrow().epsilon)
        });
        methods.add_method("setExplorationDecay", |_, this, v: f64| {
            this.inner.borrow_mut().epsilon_decay = v;
            Ok(())
        });
        methods.add_method("getExplorationDecay", |_, this, ()| {
            Ok(this.inner.borrow().epsilon_decay)
        });
        methods.add_method("serialize", |_, this, ()| {
            Ok(this.inner.borrow().serialize())
        });
        methods.add_method("deserialize", |_, this, json: String| {
            this.inner
                .borrow_mut()
                .deserialize(&json)
                .map_err(LuaError::RuntimeError)?;
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LQLearner"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "QLearner" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaUtilityAI {
    inner: Rc<RefCell<UtilityAI>>,
    custom_callbacks: Rc<RefCell<CallbackRegistry>>,
}
impl LuaUserData for LuaUtilityAI {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("evaluate", |lua, this, ()| {
            match this.inner.borrow_mut().evaluate(lua)? {
                Some(name) => Ok(LuaValue::String(lua.create_string(&name)?)),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });
        methods.add_method("getLastAction", |_, this, ()| {
            let ai = this.inner.borrow();
            Ok(ai.last_action.map(|i| ai.actions[i].name.clone()))
        });
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
        methods.add_method("type", |_, _, ()| Ok("LUtilityAI"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "UtilityAI" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaGOAPPlanner {
    inner: Rc<RefCell<GOAPPlanner>>,
}
impl LuaUserData for LuaGOAPPlanner {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("getActionCount", |_, this, ()| {
            Ok(this.inner.borrow().actions.len())
        });
        methods.add_method("getGoalCount", |_, this, ()| {
            Ok(this.inner.borrow().goals.len())
        });
        methods.add_method("getMaxIterations", |_, this, ()| {
            Ok(this.inner.borrow().get_max_iterations() as u64)
        });
        methods.add_method_mut("setMaxIterations", |_, this, n: u64| {
            this.inner.borrow_mut().set_max_iterations(n as usize);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LGOAPPlanner"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GOAPPlanner" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaInfluenceMap {
    inner: Rc<RefCell<InfluenceMap>>,
}
impl LuaUserData for LuaInfluenceMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addLayer", |_, this, name: String| {
            this.inner.borrow_mut().add_layer(&name);
            Ok(())
        });
        methods.add_method("hasLayer", |_, this, name: String| {
            Ok(this.inner.borrow().has_layer(&name))
        });
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
        methods.add_method(
            "propagate",
            |_, this, (layer, momentum): (String, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .propagate(&layer, momentum.unwrap_or(0.5));
                Ok(())
            },
        );
        methods.add_method("decay", |_, this, (layer, factor): (String, f32)| {
            this.inner.borrow_mut().decay(&layer, factor);
            Ok(())
        });
        methods.add_method("clearLayer", |_, this, layer: String| {
            this.inner.borrow_mut().clear_layer(&layer);
            Ok(())
        });
        methods.add_method("clearAll", |_, this, ()| {
            this.inner.borrow_mut().clear_all();
            Ok(())
        });
        methods.add_method("getMaxPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().max_position(&layer))
        });
        methods.add_method("getMinPosition", |_, this, layer: String| {
            Ok(this.inner.borrow().min_position(&layer))
        });
        methods.add_method(
            "queryRect",
            |_, this, (layer, wx, wy, ww, wh): (String, f32, f32, f32, f32)| {
                Ok(this.inner.borrow().query_rect(&layer, wx, wy, ww, wh))
            },
        );
        methods.add_method("blend", |_, this, (layer_a, weight_a, layer_b, weight_b, dest): (String, f32, String, f32, String)| {
                this.inner.borrow_mut().blend(&layer_a, weight_a, &layer_b, weight_b, &dest);
                Ok(())
            },
        );
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height));
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size)
        });
        methods.add_method("type", |_, _, ()| Ok("LInfluenceMap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "InfluenceMap" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaSquad {
    inner: Rc<RefCell<Squad>>,
}
impl LuaUserData for LuaSquad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });
        methods.add_method("addMember", |_, this, name: String| {
            this.inner.borrow_mut().members.push(name);
            Ok(())
        });
        methods.add_method("removeMember", |_, this, name: String| {
            this.inner.borrow_mut().members.retain(|m| m != &name);
            Ok(())
        });
        methods.add_method("getMemberCount", |_, this, ()| {
            Ok(this.inner.borrow().members.len())
        });
        methods.add_method("getMembers", |lua, this, ()| {
            let sq = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, m) in sq.members.iter().enumerate() {
                tbl.set(i as i64 + 1, m.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("setLeader", |_, this, name: String| {
            this.inner.borrow_mut().leader = Some(name);
            Ok(())
        });
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
        methods.add_method("getFormation", |_, this, ()| {
            Ok(this.inner.borrow().formation.as_str().to_string())
        });
        methods.add_method("getFormationSpacing", |_, this, ()| {
            Ok(this.inner.borrow().formation_spacing)
        });
        methods.add_method(
            "getFormationPosition",
            |_, this, (member_idx, leader_x, leader_y): (usize, f32, f32)| {
                Ok(this
                    .inner
                    .borrow()
                    .get_formation_position(member_idx.saturating_sub(1), (leader_x, leader_y)))
            },
        );
        methods.add_method("getBlackboard", |_, this, ()| {
            let sq = this.inner.borrow();
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(sq.blackboard.clone())),
            })
        });
        methods.add_method("type", |_, _, ()| Ok("LSquad"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Squad" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaCommandQueue {
    inner: Rc<RefCell<CommandQueue>>,
}
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
        methods.add_method("cancelCurrent", |_, this, ()| {
            Ok(this.inner.borrow_mut().cancel_current())
        });
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("getCount", |_, this, ()| Ok(this.inner.borrow().count()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.borrow().is_empty()));
        methods.add_method("getCurrentType", |_, this, ()| {
            Ok(this.inner.borrow().current_type().map(|s| s.to_string()))
        });
        methods.add_method("getCurrentTarget", |_, this, ()| {
            Ok(this.inner.borrow().current_target())
        });
        methods.add_method("type", |_, _, ()| Ok("LCommandQueue"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "CommandQueue" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaTraitProfile {
    inner: Rc<RefCell<TraitProfile>>,
}
impl LuaUserData for LuaTraitProfile {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("set", |_, this, (name, value): (String, f32)| {
            this.inner.borrow_mut().set(&name, value);
            Ok(())
        });
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });
        methods.add_method("getBase", |_, this, name: String| {
            Ok(this.inner.borrow().get_base(&name))
        });
        methods.add_method_mut(
            "addModifier",
            |_, this, (trait_name, delta, duration, source): (String, f32, Option<f32>, String)| {
                this.inner
                    .borrow_mut()
                    .add_modifier(&trait_name, delta, duration, &source);
                Ok(())
            },
        );
        methods.add_method_mut("removeModifiers", |_, this, source: String| {
            this.inner.borrow_mut().remove_modifiers_by_source(&source);
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("has", |_, this, name: String| {
            Ok(this.inner.borrow().has(&name))
        });
        methods.add_method("traitCount", |_, this, ()| {
            Ok(this.inner.borrow().trait_count() as i64)
        });
        methods.add_method("archetype", |_, this, ()| {
            Ok(this.inner.borrow().archetype().map(|s| s.to_string()))
        });
        methods.add_method("type", |_, _, ()| Ok("LTraitProfile"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTraitProfile" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaStimulusWorld {
    inner: Rc<RefCell<StimulusWorld>>,
}
impl LuaUserData for LuaStimulusWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "addVisual",
            |_, this, (x, y, intensity, radius, tag): (f32, f32, f32, f32, Option<String>)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_visual(x, y, intensity, radius, tag) as i64)
            },
        );
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
        methods.add_method_mut("remove", |_, this, id: u64| {
            Ok(this.inner.borrow_mut().remove(id))
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method(
            "count",
            |_, this, ()| Ok(this.inner.borrow().count() as i64),
        );
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LStimulusWorld"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStimulusWorld" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaContextSteering {
    inner: Rc<RefCell<ContextSteering>>,
}
impl LuaUserData for LuaContextSteering {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "addSeekTarget",
            |_, this, (tx, ty, weight): (f32, f32, f32)| {
                this.inner.borrow_mut().add_seek_target(tx, ty, weight);
                Ok(())
            },
        );
        methods.add_method_mut("addWander", |_, this, (jitter, weight): (f32, f32)| {
            this.inner.borrow_mut().add_wander(jitter, weight);
            Ok(())
        });
        methods.add_method_mut(
            "addAvoidPoint",
            |_, this, (x, y, radius, weight): (f32, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add_avoid_point(x, y, radius, weight);
                Ok(())
            },
        );
        methods.add_method_mut("addAvoidBounds", |_, this, (min_x, min_y, max_x, max_y, margin, weight): (f32, f32, f32, f32, f32, f32)| {
            this.inner.borrow_mut().add_avoid_bounds(min_x, min_y, max_x, max_y, margin, weight);
            Ok(())
        });
        methods.add_method_mut("clearBehaviors", |_, this, ()| {
            this.inner.borrow_mut().clear_behaviors();
            Ok(())
        });
        methods.add_method_mut(
            "evaluate",
            |_, this, (ax, ay, vx, vy): (f32, f32, f32, f32)| {
                let (dx, dy) = this.inner.borrow_mut().evaluate(ax, ay, vx, vy);
                Ok((dx, dy))
            },
        );
        methods.add_method("chosenMagnitude", |_, this, ()| {
            Ok(this.inner.borrow().chosen_magnitude())
        });
        methods.add_method("slotCount", |_, this, ()| {
            Ok(this.inner.borrow().slot_count() as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LContextSteering"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LContextSteering" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaNeedSystem {
    inner: Rc<RefCell<NeedSystem>>,
}
impl LuaUserData for LuaNeedSystem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addNeed", |_, this, (name, decay_rate, urgency_threshold, urgency_factor): (String, f32, f32, f32)| {
            this.inner.borrow_mut().add_need(Need::new(&name, decay_rate, urgency_threshold, urgency_factor));
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("mostUrgent", |_, this, ()| {
            Ok(this.inner.borrow().most_urgent().map(|s| s.to_string()))
        });
        methods.add_method_mut("satisfy", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().satisfy(&name, amount);
            Ok(())
        });
        methods.add_method("valueOf", |_, this, name: String| {
            Ok(this.inner.borrow().value_of(&name))
        });
        methods.add_method("type", |_, _, ()| Ok("LNeedSystem"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeedSystem" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaAIDirector {
    inner: Rc<RefCell<AIDirector>>,
}
impl LuaUserData for LuaAIDirector {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("pushEvent", |_, this, intensity: f32| {
            this.inner.borrow_mut().push_event(intensity);
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("tension", |_, this, ()| Ok(this.inner.borrow().tension()));
        methods.add_method("phase", |_, this, ()| {
            Ok(this.inner.borrow().phase_str().to_string())
        });
        methods.add_method("spawnRateFactor", |_, this, ()| {
            Ok(this.inner.borrow().spawn_rate_factor())
        });
        methods.add_method("lootFactor", |_, this, ()| {
            Ok(this.inner.borrow().loot_factor())
        });
        methods.add_method("ambientIntensity", |_, this, ()| {
            Ok(this.inner.borrow().ambient_intensity())
        });
        methods.add_method_mut("setTension", |_, this, value: f32| {
            this.inner.borrow_mut().set_tension(value);
            Ok(())
        });
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LAIDirector"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAIDirector" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaHTNDomain {
    inner: Rc<RefCell<HTNDomain>>,
}
impl LuaUserData for LuaHTNDomain {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addPrimitive", |_, this, (name, preconds, effects, clears): (String, Vec<String>, Vec<String>, Vec<String>)| {
            let p: Vec<&str> = preconds.iter().map(|s| s.as_str()).collect();
            let e: Vec<&str> = effects.iter().map(|s| s.as_str()).collect();
            let c: Vec<&str> = clears.iter().map(|s| s.as_str()).collect();
            this.inner.borrow_mut().add_primitive(&name, p, e, c);
            Ok(())
        });
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
        methods.add_method("taskCount", |_, this, ()| {
            Ok(this.inner.borrow().task_count() as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LHTNDomain"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHTNDomain" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaMCTSEngine {
    inner: Rc<RefCell<MCTSEngine>>,
}
impl LuaUserData for LuaMCTSEngine {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method("type", |_, _, ()| Ok("LMCTSEngine"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMCTSEngine" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaEmotionModel {
    inner: Rc<RefCell<EmotionModel>>,
}
impl LuaUserData for LuaEmotionModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "add",
            |_, this, (name, rest, decay, min_vis): (String, f32, f32, f32)| {
                this.inner
                    .borrow_mut()
                    .add(Emotion::new(&name, rest, decay, min_vis));
                Ok(())
            },
        );
        methods.add_method_mut("trigger", |_, this, (name, amount): (String, f32)| {
            this.inner.borrow_mut().trigger(&name, amount);
            Ok(())
        });
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });
        methods.add_method("dominant", |_, this, ()| {
            Ok(this.inner.borrow().dominant().map(|s| s.to_string()))
        });
        methods.add_method("isActive", |_, this, name: String| {
            Ok(this.inner.borrow().is_active(&name))
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LEmotionModel"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LEmotionModel" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaORCASolver {
    inner: Rc<RefCell<ORCASolver>>,
}
impl LuaUserData for LuaORCASolver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "addAgent",
            |_, this, (x, y, radius, max_speed): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .add_agent(ORCAAgent::new(x, y, radius, max_speed)) as i64)
            },
        );
        methods.add_method_mut(
            "setPreferredVelocity",
            |_, this, (idx, pvx, pvy): (usize, f32, f32)| {
                if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                    a.preferred_velocity = (pvx, pvy);
                }
                Ok(())
            },
        );
        methods.add_method_mut("setPosition", |_, this, (idx, x, y): (usize, f32, f32)| {
            if let Some(a) = this.inner.borrow_mut().agents.get_mut(idx) {
                a.position = (x, y);
            }
            Ok(())
        });
        methods.add_method_mut("compute", |_, this, dt: f32| {
            this.inner.borrow_mut().compute(dt);
            Ok(())
        });
        methods.add_method("getSafeVelocity", |_, this, idx: usize| {
            let solver = this.inner.borrow();
            let v = solver
                .agents
                .get(idx)
                .map(|a| a.safe_velocity)
                .unwrap_or((0.0, 0.0));
            Ok((v.0, v.1))
        });
        methods.add_method("agentCount", |_, this, ()| {
            Ok(this.inner.borrow().agent_count() as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LORCASolver"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LORCASolver" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaNeuralNet {
    inner: Rc<RefCell<NeuralNet>>,
}
impl LuaUserData for LuaNeuralNet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "addLayer",
            |_, this, (inputs, outputs, activation): (usize, usize, String)| {
                let act = Activation::from_str(&activation);
                this.inner.borrow_mut().add_layer(inputs, outputs, act);
                Ok(())
            },
        );
        methods.add_method("forward", |lua, this, input: Vec<f32>| {
            let out = this.inner.borrow().forward(&input);
            let t = lua.create_table()?;
            for (i, v) in out.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });
        methods.add_method_mut("setWeights", |_, this, weights: Vec<f32>| {
            Ok(this.inner.borrow_mut().set_weights(&weights))
        });
        methods.add_method("getWeights", |lua, this, ()| {
            let w = this.inner.borrow().get_weights();
            let t = lua.create_table()?;
            for (i, v) in w.into_iter().enumerate() {
                t.raw_set(i + 1, v)?;
            }
            Ok(t)
        });
        methods.add_method("paramCount", |_, this, ()| {
            Ok(this.inner.borrow().param_count() as i64)
        });
        methods.add_method("layerCount", |_, this, ()| {
            Ok(this.inner.borrow().layer_count() as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LNeuralNet"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuralNet" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaGeneticAlgorithm {
    inner: Rc<RefCell<GeneticAlgorithm>>,
}
impl LuaUserData for LuaGeneticAlgorithm {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            if let Some(c) = this.inner.borrow_mut().population.get_mut(idx) {
                c.fitness = fitness;
            }
            Ok(())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LGeneticAlgorithm"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGeneticAlgorithm" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaBandit {
    inner: Rc<RefCell<Bandit>>,
}
impl LuaUserData for LuaBandit {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("select", |_, this, ()| {
            Ok(this.inner.borrow_mut().select() as i64)
        });
        methods.add_method_mut("update", |_, this, (idx, reward): (usize, f64)| {
            this.inner.borrow_mut().update(idx, reward);
            Ok(())
        });
        methods.add_method("bestArm", |_, this, ()| {
            Ok(this.inner.borrow().best_arm() as i64)
        });
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("armCount", |_, this, ()| {
            Ok(this.inner.borrow().arm_count() as i64)
        });
        methods.add_method("totalPulls", |_, this, ()| {
            Ok(this.inner.borrow().total_pulls as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LBandit"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBandit" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaNeuroevolution {
    inner: Rc<RefCell<Neuroevolution>>,
}
impl LuaUserData for LuaNeuroevolution {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("evolve", |_, this, ()| {
            this.inner.borrow_mut().evolve();
            Ok(())
        });
        methods.add_method_mut("setFitness", |_, this, (idx, fitness): (usize, f32)| {
            this.inner.borrow_mut().set_fitness(idx, fitness);
            Ok(())
        });
        methods.add_method("chromosomeToNet", |_, this, idx: usize| {
            let net = this.inner.borrow().chromosome_to_net(idx);
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });
        methods.add_method("bestNetwork", |_, this, ()| {
            let net = this.inner.borrow().best_network();
            Ok(net.map(|n| LuaNeuralNet {
                inner: Rc::new(RefCell::new(n)),
            }))
        });
        methods.add_method("bestFitness", |_, this, ()| {
            Ok(this.inner.borrow().best_fitness())
        });
        methods.add_method("popSize", |_, this, ()| {
            Ok(this.inner.borrow().pop_size() as i64)
        });
        methods.add_method("generation", |_, this, ()| {
            Ok(this.inner.borrow().generation as i64)
        });
        methods.add_method("type", |_, _, ()| Ok("LNeuroevolution"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNeuroevolution" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaStrategyAI {
    inner: Rc<RefCell<StrategyAI>>,
}
impl LuaUserData for LuaStrategyAI {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("addGoal", |_, this, name: String| {
            this.inner.borrow_mut().add_goal_named(&name);
            Ok(())
        });
        methods.add_method_mut("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(&tag);
            Ok(())
        });
        methods.add_method_mut("removeTag", |_, this, tag: String| {
            this.inner.borrow_mut().remove_tag(&tag);
            Ok(())
        });
        methods.add_method_mut("update", |_, this, (dt, scorer_fn): (f32, LuaFunction)| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().update(dt, &mut scorer);
            Ok(())
        });
        methods.add_method_mut("forceEvaluate", |_, this, scorer_fn: LuaFunction| {
            let mut scorer =
                |goal: &str| -> f32 { scorer_fn.call::<_, f32>(goal.to_string()).unwrap_or(0.0) };
            this.inner.borrow_mut().force_evaluate(&mut scorer);
            Ok(())
        });
        methods.add_method("activeGoal", |_, this, ()| {
            Ok(this.inner.borrow().active_goal().map(|s| s.to_string()))
        });
        methods.add_method("timeUntilNext", |_, this, ()| {
            Ok(this.inner.borrow().time_until_next())
        });
        methods.add_method("type", |_, _, ()| Ok("LStrategyAI"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LStrategyAI" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct LuaAILod {
    inner: Rc<RefCell<AILod>>,
}
impl LuaUserData for LuaAILod {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "tierFor",
            |_, this, (ax, ay, rx, ry): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().tier_for((ax, ay), (rx, ry)) as i64)
            },
        );
        methods.add_method("shouldUpdate", |_, this, (tier, frame): (usize, u64)| {
            Ok(this.inner.borrow().should_update(tier, frame))
        });
        methods.add_method("tierCount", |_, this, ()| {
            Ok(this.inner.borrow().tier_count() as i64)
        });
        methods.add_method("tierName", |_, this, tier: usize| {
            Ok(this.inner.borrow().tier(tier).map(|t| t.name.clone()))
        });
        methods.add_method("type", |_, _, ()| Ok("LAILod"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAILod" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newWorld",
        lua.create_function(|_, ()| {
            Ok(LuaAIWorld {
                inner: Rc::new(RefCell::new(AIWorld::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;
    tbl.set(
        "newBlackboard",
        lua.create_function(|_, ()| {
            Ok(LuaAIBlackboard {
                inner: Rc::new(RefCell::new(Blackboard::new())),
            })
        })?,
    )?;
    tbl.set(
        "newStateMachine",
        lua.create_function(|_, ()| {
            Ok(LuaStateMachine {
                inner: Rc::new(RefCell::new(crate::ai::StateMachine::new())),
            })
        })?,
    )?;
    tbl.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                inner: Rc::new(RefCell::new(BehaviorTree::new())),
            })
        })?,
    )?;
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
    tbl.set(
        "newAction",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Action { callback: key })),
            })
        })?,
    )?;
    tbl.set(
        "newCondition",
        lua.create_function(|lua, callback: LuaFunction| {
            let key = lua.create_registry_value(callback)?;
            Ok(LuaBTNode {
                inner: Rc::new(RefCell::new(BTNode::Condition { callback: key })),
            })
        })?,
    )?;
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
    tbl.set(
        "newSteeringManager",
        lua.create_function(|_, ()| {
            Ok(LuaSteeringManager {
                inner: Rc::new(RefCell::new(SteeringManager::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;
    tbl.set(
        "newQLearner",
        lua.create_function(|_, (sc, ac): (usize, usize)| {
            Ok(LuaQLearner {
                inner: Rc::new(RefCell::new(QLearner::new(sc, ac))),
            })
        })?,
    )?;
    tbl.set(
        "newUtilityAI",
        lua.create_function(|_, ()| {
            Ok(LuaUtilityAI {
                inner: Rc::new(RefCell::new(UtilityAI::new())),
                custom_callbacks: Rc::new(RefCell::new(CallbackRegistry::new())),
            })
        })?,
    )?;
    tbl.set(
        "newDialogueAI",
        lua.create_function(|_, ()| {
            Ok(LuaDialogueAI {
                inner: Rc::new(RefCell::new(DialogueAI::new())),
            })
        })?,
    )?;
    tbl.set(
        "newGOAPPlanner",
        lua.create_function(|_, ()| {
            Ok(LuaGOAPPlanner {
                inner: Rc::new(RefCell::new(GOAPPlanner::new())),
            })
        })?,
    )?;
    tbl.set(
        "newInfluenceMap",
        lua.create_function(|_, (w, h, cs): (usize, usize, f32)| {
            Ok(LuaInfluenceMap {
                inner: Rc::new(RefCell::new(InfluenceMap::new(w, h, cs))),
            })
        })?,
    )?;
    tbl.set(
        "newSquad",
        lua.create_function(|_, name: String| {
            Ok(LuaSquad {
                inner: Rc::new(RefCell::new(Squad::new(&name))),
            })
        })?,
    )?;
    tbl.set(
        "newCommandQueue",
        lua.create_function(|_, ()| {
            Ok(LuaCommandQueue {
                inner: Rc::new(RefCell::new(CommandQueue::new())),
            })
        })?,
    )?;
    tbl.set(
        "newTraitProfile",
        lua.create_function(|_, ()| {
            Ok(LuaTraitProfile {
                inner: Rc::new(RefCell::new(TraitProfile::new())),
            })
        })?,
    )?;
    tbl.set(
        "newStimulusWorld",
        lua.create_function(|_, ()| {
            Ok(LuaStimulusWorld {
                inner: Rc::new(RefCell::new(StimulusWorld::new())),
            })
        })?,
    )?;
    tbl.set(
        "newContextSteering",
        lua.create_function(|_, slots: usize| {
            let slots = if slots == 0 { 16 } else { slots };
            Ok(LuaContextSteering {
                inner: Rc::new(RefCell::new(ContextSteering::new(slots))),
            })
        })?,
    )?;
    tbl.set(
        "newNeedSystem",
        lua.create_function(|_, ()| {
            Ok(LuaNeedSystem {
                inner: Rc::new(RefCell::new(NeedSystem::new())),
            })
        })?,
    )?;
    tbl.set(
        "newAIDirector",
        lua.create_function(|_, ()| {
            Ok(LuaAIDirector {
                inner: Rc::new(RefCell::new(AIDirector::new())),
            })
        })?,
    )?;
    tbl.set(
        "newHTNDomain",
        lua.create_function(|_, ()| {
            Ok(LuaHTNDomain {
                inner: Rc::new(RefCell::new(HTNDomain::new())),
            })
        })?,
    )?;
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
    tbl.set(
        "newEmotionModel",
        lua.create_function(|_, ()| {
            Ok(LuaEmotionModel {
                inner: Rc::new(RefCell::new(EmotionModel::new())),
            })
        })?,
    )?;
    tbl.set(
        "newORCASolver",
        lua.create_function(|_, time_horizon: f32| {
            Ok(LuaORCASolver {
                inner: Rc::new(RefCell::new(ORCASolver::new(time_horizon))),
            })
        })?,
    )?;
    tbl.set(
        "newNeuralNet",
        lua.create_function(|_, ()| {
            Ok(LuaNeuralNet {
                inner: Rc::new(RefCell::new(NeuralNet::new())),
            })
        })?,
    )?;
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
    tbl.set(
        "newStrategyAI",
        lua.create_function(|_, update_interval: f32| {
            Ok(LuaStrategyAI {
                inner: Rc::new(RefCell::new(StrategyAI::new(update_interval))),
            })
        })?,
    )?;
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
