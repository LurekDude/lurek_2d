use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::ai::*;
use luna2d::lua_api::{create_lua_vm, SharedState};

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Creates a minimal Lua VM for tests that need RegistryKey values.
fn make_lua() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).expect("Failed to create Lua VM")
}

/// Creates a dummy Command with the given kind using a Lua VM registry key.
fn make_command(lua: &mlua::Lua, kind: &str, interruptible: bool) -> Command {
    let cb = lua.create_registry_value(true).unwrap();
    Command {
        kind: kind.to_string(),
        callback: cb,
        target_x: 0.0,
        target_y: 0.0,
        priority: 0,
        interruptible,
    }
}

// ── AIWorld ──────────────────────────────────────────────────────────────────

#[test]
fn test_aiworld_new_empty() {
    let world = AIWorld::new();
    assert_eq!(world.agent_count(), 0);
}

#[test]
fn test_aiworld_add_agent() {
    let mut world = AIWorld::new();
    let idx = world.add_agent("scout").unwrap();
    assert_eq!(idx, 0);
    assert_eq!(world.agent_count(), 1);
    assert_eq!(world.get_agent_index("scout"), Some(0));
}

#[test]
fn test_aiworld_add_agent_duplicate_errors() {
    let mut world = AIWorld::new();
    world.add_agent("scout").unwrap();
    let result = world.add_agent("scout");
    assert!(result.is_err());
}

#[test]
fn test_aiworld_remove_agent() {
    let mut world = AIWorld::new();
    world.add_agent("a").unwrap();
    world.add_agent("b").unwrap();
    assert_eq!(world.agent_count(), 2);
    assert!(world.remove_agent("a"));
    assert_eq!(world.agent_count(), 1);
    assert_eq!(world.get_agent_index("b"), Some(0));
    assert!(!world.remove_agent("nonexistent"));
}

#[test]
fn test_aiworld_agent_count() {
    let mut world = AIWorld::new();
    assert_eq!(world.agent_count(), 0);
    world.add_agent("a").unwrap();
    assert_eq!(world.agent_count(), 1);
    world.add_agent("b").unwrap();
    assert_eq!(world.agent_count(), 2);
    world.remove_agent("a");
    assert_eq!(world.agent_count(), 1);
}

#[test]
fn test_aiworld_global_blackboard() {
    let mut world = AIWorld::new();
    world.global_blackboard_mut().set_number("hp", 100.0);
    assert!((world.global_blackboard().get_number("hp", 0.0) - 100.0).abs() < 1e-5);
}

// ── Agent ────────────────────────────────────────────────────────────────────

#[test]
fn test_agent_new_defaults() {
    let agent = Agent::new("hero");
    assert_eq!(agent.name, "hero");
    assert!((agent.position.0).abs() < 1e-5);
    assert!((agent.position.1).abs() < 1e-5);
    assert!((agent.velocity.0).abs() < 1e-5);
    assert!((agent.velocity.1).abs() < 1e-5);
    assert!((agent.max_speed - 100.0).abs() < 1e-5);
    assert!((agent.max_force - 200.0).abs() < 1e-5);
    assert_eq!(agent.decision_model, DecisionModel::Fsm);
    assert!(agent.tags.is_empty());
    assert!(agent.fsm_index.is_none());
    assert!(agent.bt_index.is_none());
    assert!(agent.steering_index.is_none());
}

#[test]
fn test_agent_position_set_get() {
    let mut agent = Agent::new("unit");
    agent.position = (42.5, -17.3);
    assert!((agent.position.0 - 42.5).abs() < 1e-5);
    assert!((agent.position.1 - (-17.3)).abs() < 1e-5);
}

#[test]
fn test_agent_velocity_set_get() {
    let mut agent = Agent::new("unit");
    agent.velocity = (3.0, -4.0);
    assert!((agent.velocity.0 - 3.0).abs() < 1e-5);
    assert!((agent.velocity.1 - (-4.0)).abs() < 1e-5);
}

#[test]
fn test_agent_decision_model_parse() {
    assert_eq!(DecisionModel::parse_str("fsm"), Some(DecisionModel::Fsm));
    assert_eq!(DecisionModel::parse_str("bt"), Some(DecisionModel::Bt));
    assert_eq!(
        DecisionModel::parse_str("steering"),
        Some(DecisionModel::Steering)
    );
    assert_eq!(
        DecisionModel::parse_str("fsm+steering"),
        Some(DecisionModel::FsmSteering)
    );
    assert_eq!(
        DecisionModel::parse_str("bt+steering"),
        Some(DecisionModel::BtSteering)
    );
    assert_eq!(DecisionModel::parse_str("invalid"), None);
}

#[test]
fn test_agent_decision_model_as_str() {
    assert_eq!(DecisionModel::Fsm.as_str(), "fsm");
    assert_eq!(DecisionModel::Bt.as_str(), "bt");
    assert_eq!(DecisionModel::Steering.as_str(), "steering");
    assert_eq!(DecisionModel::FsmSteering.as_str(), "fsm+steering");
    assert_eq!(DecisionModel::BtSteering.as_str(), "bt+steering");
}

#[test]
fn test_agent_tags() {
    let mut agent = Agent::new("unit");
    assert!(agent.tags.is_empty());
    agent.tags.insert("enemy".to_string());
    agent.tags.insert("flying".to_string());
    assert_eq!(agent.tags.len(), 2);
    assert!(agent.tags.contains("enemy"));
    assert!(agent.tags.contains("flying"));
    assert!(!agent.tags.contains("friendly"));
}

// ── Blackboard ───────────────────────────────────────────────────────────────

#[test]
fn test_blackboard_number() {
    let mut bb = Blackboard::new();
    // Default when key doesn't exist
    assert!((bb.get_number("hp", 50.0) - 50.0).abs() < 1e-5);
    bb.set_number("hp", 100.0);
    assert!((bb.get_number("hp", 0.0) - 100.0).abs() < 1e-5);
    // Overwrite
    bb.set_number("hp", 75.5);
    assert!((bb.get_number("hp", 0.0) - 75.5).abs() < 1e-5);
}

#[test]
fn test_blackboard_bool() {
    let mut bb = Blackboard::new();
    assert!(!bb.get_bool("alive", false));
    assert!(bb.get_bool("alive", true));
    bb.set_bool("alive", true);
    assert!(bb.get_bool("alive", false));
    bb.set_bool("alive", false);
    assert!(!bb.get_bool("alive", true));
}

#[test]
fn test_blackboard_string() {
    let mut bb = Blackboard::new();
    assert_eq!(bb.get_string("name", "default"), "default");
    bb.set_string("name", "Luna");
    assert_eq!(bb.get_string("name", ""), "Luna");
}

#[test]
fn test_blackboard_has_remove() {
    let mut bb = Blackboard::new();
    assert!(!bb.has("key"));
    bb.set_number("key", 1.0);
    assert!(bb.has("key"));
    bb.remove("key");
    assert!(!bb.has("key"));
}

#[test]
fn test_blackboard_clear() {
    let mut bb = Blackboard::new();
    bb.set_number("a", 1.0);
    bb.set_bool("b", true);
    bb.set_string("c", "hello");
    assert_eq!(bb.size(), 3);
    bb.clear();
    assert_eq!(bb.size(), 0);
    assert!(!bb.has("a"));
}

#[test]
fn test_blackboard_parent_chain() {
    let mut parent = Blackboard::new();
    parent.set_number("shared", 42.0);
    parent.set_string("color", "red");

    let mut child = Blackboard::new();
    child.set_parent(parent);

    // Child reads from parent via chain
    assert!((child.get_number("shared", 0.0) - 42.0).abs() < 1e-5);
    assert_eq!(child.get_string("color", ""), "red");

    // Child overrides locally
    child.set_number("shared", 99.0);
    assert!((child.get_number("shared", 0.0) - 99.0).abs() < 1e-5);

    // has() walks the chain
    assert!(child.has("color"));
    assert!(child.has("shared"));

    // remove only removes local; parent key still visible
    child.remove("shared");
    assert!((child.get_number("shared", 0.0) - 42.0).abs() < 1e-5);
}

#[test]
fn test_blackboard_keys_size() {
    let mut bb = Blackboard::new();
    assert_eq!(bb.size(), 0);
    assert!(bb.keys().is_empty());
    bb.set_number("x", 1.0);
    bb.set_number("y", 2.0);
    assert_eq!(bb.size(), 2);
    let keys = bb.keys();
    assert_eq!(keys.len(), 2);
    assert!(keys.contains(&"x".to_string()));
    assert!(keys.contains(&"y".to_string()));
}

// ── StateMachine (FSM) ───────────────────────────────────────────────────────

#[test]
fn test_fsm_new_empty() {
    let fsm = StateMachine::new();
    assert!(fsm.current_state().is_none());
    assert!((fsm.time_in_state()).abs() < 1e-5);
}

#[test]
fn test_fsm_current_state_none() {
    let fsm = StateMachine::new();
    assert!(fsm.current_state().is_none());
}

#[test]
fn test_fsm_time_in_state() {
    let fsm = StateMachine::new();
    // time_in_state starts at 0
    assert!((fsm.time_in_state()).abs() < 1e-5);
}

// ── BehaviorTree ─────────────────────────────────────────────────────────────

#[test]
fn test_bt_new_defaults() {
    let bt = BehaviorTree::new();
    assert!(bt.root.is_none());
    assert_eq!(bt.last_status, BTStatus::Success);
}

#[test]
fn test_bt_status_parse() {
    assert_eq!(BTStatus::parse_str("success"), BTStatus::Success);
    assert_eq!(BTStatus::parse_str("failure"), BTStatus::Failure);
    assert_eq!(BTStatus::parse_str("running"), BTStatus::Running);
    // Unknown defaults to Running
    assert_eq!(BTStatus::parse_str("unknown"), BTStatus::Running);
}

#[test]
fn test_bt_status_as_str() {
    assert_eq!(BTStatus::Success.as_str(), "success");
    assert_eq!(BTStatus::Failure.as_str(), "failure");
    assert_eq!(BTStatus::Running.as_str(), "running");
}

#[test]
fn test_bt_node_selector_count() {
    let node = BTNode::Selector {
        children: vec![
            BTNode::Selector {
                children: vec![],
                running_idx: 0,
            },
            BTNode::Sequence {
                children: vec![],
                running_idx: 0,
            },
            BTNode::Selector {
                children: vec![],
                running_idx: 0,
            },
        ],
        running_idx: 0,
    };
    assert_eq!(node.child_count(), 3);

    // Empty selector
    let empty = BTNode::Selector {
        children: vec![],
        running_idx: 0,
    };
    assert_eq!(empty.child_count(), 0);
}

#[test]
fn test_bt_node_sequence_count() {
    let node = BTNode::Sequence {
        children: vec![
            BTNode::Selector {
                children: vec![],
                running_idx: 0,
            },
            BTNode::Selector {
                children: vec![],
                running_idx: 0,
            },
        ],
        running_idx: 0,
    };
    assert_eq!(node.child_count(), 2);
}

#[test]
fn test_bt_node_decorator_count() {
    let child = BTNode::Selector {
        children: vec![],
        running_idx: 0,
    };
    let inverter = BTNode::Inverter {
        child: Box::new(child),
    };
    assert_eq!(inverter.child_count(), 1);
}

#[test]
fn test_bt_node_reset() {
    let mut node = BTNode::Sequence {
        children: vec![BTNode::Repeater {
            child: Box::new(BTNode::Selector {
                children: vec![],
                running_idx: 0,
            }),
            count: 5,
            done: 3,
        }],
        running_idx: 2,
    };
    node.reset();
    if let BTNode::Sequence {
        running_idx,
        children,
        ..
    } = &node
    {
        assert_eq!(*running_idx, 0);
        if let BTNode::Repeater { done, .. } = &children[0] {
            assert_eq!(*done, 0);
        } else {
            panic!("Expected Repeater");
        }
    } else {
        panic!("Expected Sequence");
    }
}

#[test]
fn test_bt_parallel_policy_parse() {
    assert_eq!(
        ParallelPolicy::parse_str("requireOne"),
        ParallelPolicy::RequireOne
    );
    assert_eq!(
        ParallelPolicy::parse_str("requireAll"),
        ParallelPolicy::RequireAll
    );
    // Unknown defaults to RequireOne
    assert_eq!(
        ParallelPolicy::parse_str("unknown"),
        ParallelPolicy::RequireOne
    );
}

#[test]
fn test_bt_parallel_policy_as_str() {
    assert_eq!(ParallelPolicy::RequireOne.as_str(), "requireOne");
    assert_eq!(ParallelPolicy::RequireAll.as_str(), "requireAll");
}

// ── SteeringManager ─────────────────────────────────────────────────────────

#[test]
fn test_steering_manager_new() {
    let mgr = SteeringManager::new();
    assert!(mgr.behaviors.is_empty());
    assert_eq!(mgr.combine_mode, CombineMode::Weighted);
    assert!((mgr.last_force.0).abs() < 1e-5);
    assert!((mgr.last_force.1).abs() < 1e-5);
}

#[test]
fn test_steering_combine_mode_parse() {
    assert_eq!(CombineMode::parse_str("weighted"), CombineMode::Weighted);
    assert_eq!(CombineMode::parse_str("priority"), CombineMode::Priority);
    // Unknown defaults to Weighted
    assert_eq!(CombineMode::parse_str("invalid"), CombineMode::Weighted);
}

#[test]
fn test_steering_combine_mode_as_str() {
    assert_eq!(CombineMode::Weighted.as_str(), "weighted");
    assert_eq!(CombineMode::Priority.as_str(), "priority");
}

#[test]
fn test_steering_behavior_type_kind() {
    let seek = SteeringBehaviorType::Seek {
        target: (10.0, 20.0),
        base: SteeringBase::default(),
    };
    assert_eq!(seek.kind(), "seek");

    let flee = SteeringBehaviorType::Flee {
        target: (0.0, 0.0),
        panic_dist: 100.0,
        base: SteeringBase::default(),
    };
    assert_eq!(flee.kind(), "flee");

    let arrive = SteeringBehaviorType::Arrive {
        target: (0.0, 0.0),
        slowing_radius: 50.0,
        base: SteeringBase::default(),
    };
    assert_eq!(arrive.kind(), "arrive");

    let wander = SteeringBehaviorType::Wander {
        wander_radius: 10.0,
        wander_distance: 20.0,
        wander_jitter: 1.0,
        wander_angle: 0.0,
        base: SteeringBase::default(),
    };
    assert_eq!(wander.kind(), "wander");
}

#[test]
fn test_steering_base_default() {
    let base = SteeringBase::default();
    assert!((base.weight - 1.0).abs() < 1e-5);
    assert!(base.enabled);
}

#[test]
fn test_steering_seek_force() {
    let seek = SteeringBehaviorType::Seek {
        target: (100.0, 0.0),
        base: SteeringBase::default(),
    };
    let force = seek.calculate((0.0, 0.0), (0.0, 0.0), 100.0, 0.016);
    // Seek from origin toward (100,0) => desired velocity is (100,0), force = desired - vel = (100, 0)
    assert!(force.0 > 0.0);
    assert!((force.1).abs() < 1e-5);
}

#[test]
fn test_steering_disabled_returns_zero() {
    let seek = SteeringBehaviorType::Seek {
        target: (100.0, 0.0),
        base: SteeringBase {
            weight: 1.0,
            enabled: false,
        },
    };
    let force = seek.calculate((0.0, 0.0), (0.0, 0.0), 100.0, 0.016);
    assert!((force.0).abs() < 1e-5);
    assert!((force.1).abs() < 1e-5);
}

#[test]
fn test_steering_manager_calculate_weighted() {
    let mut mgr = SteeringManager::new();
    mgr.behaviors.push(SteeringBehaviorType::Seek {
        target: (100.0, 0.0),
        base: SteeringBase {
            weight: 1.0,
            enabled: true,
        },
    });
    let force = mgr.calculate((0.0, 0.0), (0.0, 0.0), 100.0, 200.0, 0.016);
    assert!(force.0 > 0.0);
}

// ── PathGrid ─────────────────────────────────────────────────────────────────

#[test]
fn test_pathgrid_new() {
    let grid = PathGrid::new(10, 8, 32.0);
    assert_eq!(grid.width, 10);
    assert_eq!(grid.height, 8);
    assert!((grid.cell_size - 32.0).abs() < 1e-5);
}

#[test]
fn test_pathgrid_walkable() {
    let mut grid = PathGrid::new(5, 5, 16.0);
    // All cells start walkable
    assert!(grid.is_walkable(0, 0));
    assert!(grid.is_walkable(4, 4));
    grid.set_walkable(2, 3, false);
    assert!(!grid.is_walkable(2, 3));
    assert!(grid.is_walkable(2, 2));
    // Out of bounds returns false
    assert!(!grid.is_walkable(5, 5));
}

#[test]
fn test_pathgrid_cost() {
    let mut grid = PathGrid::new(5, 5, 16.0);
    // Default cost is 1.0
    assert!((grid.get_cost(0, 0) - 1.0).abs() < 1e-5);
    grid.set_cost(1, 1, 3.0);
    assert!((grid.get_cost(1, 1) - 3.0).abs() < 1e-5);
    // Out of bounds returns INFINITY
    assert!(grid.get_cost(10, 10).is_infinite());
}

#[test]
fn test_pathgrid_find_path_simple() {
    let grid = PathGrid::new(5, 5, 16.0);
    let path = grid.find_path(0, 0, 4, 0);
    assert!(path.is_some());
    let waypoints = path.unwrap();
    assert!(!waypoints.is_empty());
    // First waypoint should be near start, last near goal
    let first = waypoints.first().unwrap();
    let last = waypoints.last().unwrap();
    assert!((first.0 - 8.0).abs() < 1e-5); // (0 + 0.5) * 16 = 8
    assert!((last.0 - 72.0).abs() < 1e-5); // (4 + 0.5) * 16 = 72
}

#[test]
fn test_pathgrid_find_path_blocked() {
    let mut grid = PathGrid::new(5, 1, 16.0);
    // Block the only row between start and goal
    grid.set_walkable(2, 0, false);
    let path = grid.find_path(0, 0, 4, 0);
    assert!(path.is_none());
}

#[test]
fn test_pathgrid_find_path_start_blocked() {
    let mut grid = PathGrid::new(5, 5, 16.0);
    grid.set_walkable(0, 0, false);
    let path = grid.find_path(0, 0, 4, 4);
    assert!(path.is_none());
}

#[test]
fn test_pathgrid_find_path_goal_blocked() {
    let mut grid = PathGrid::new(5, 5, 16.0);
    grid.set_walkable(4, 4, false);
    let path = grid.find_path(0, 0, 4, 4);
    assert!(path.is_none());
}

#[test]
fn test_pathgrid_find_path_same_cell() {
    let grid = PathGrid::new(5, 5, 16.0);
    let path = grid.find_path(2, 2, 2, 2);
    assert!(path.is_some());
    let waypoints = path.unwrap();
    assert_eq!(waypoints.len(), 1);
}

#[test]
fn test_pathgrid_out_of_bounds() {
    let grid = PathGrid::new(5, 5, 16.0);
    let path = grid.find_path(0, 0, 10, 10);
    assert!(path.is_none());
}

// ── FlowField ────────────────────────────────────────────────────────────────

#[test]
fn test_flowfield_new() {
    let walkable = vec![true; 25];
    let ff = FlowField::new(5, 5, walkable);
    assert_eq!(ff.width, 5);
    assert_eq!(ff.height, 5);
    assert!(ff.goal.is_none());
}

#[test]
fn test_flowfield_set_goal_compute() {
    let walkable = vec![true; 25];
    let mut ff = FlowField::new(5, 5, walkable);
    ff.set_goal(4, 4);
    assert_eq!(ff.goal, Some((4, 4)));
    // Cell (0,0) should have a direction toward (4,4)
    let dir = ff.get_direction(0, 0);
    // Direction should be roughly positive in both axes
    assert!(dir.0 > 0.0 || dir.1 > 0.0);
}

#[test]
fn test_flowfield_get_distance() {
    let walkable = vec![true; 25];
    let mut ff = FlowField::new(5, 5, walkable);
    ff.set_goal(0, 0);
    // Goal cell has distance 0
    assert!((ff.get_distance(0, 0)).abs() < 1e-5);
    // Adjacent cell has distance ~1.0
    assert!((ff.get_distance(1, 0) - 1.0).abs() < 1e-5);
    // Diagonal cell has distance ~1.414
    assert!((ff.get_distance(1, 1) - 1.414).abs() < 0.01);
    // Out of bounds returns INFINITY
    assert!(ff.get_distance(10, 10).is_infinite());
}

#[test]
fn test_flowfield_unreachable_cell() {
    let mut walkable = vec![true; 9]; // 3x3
    walkable[1] = false; // block (1,0)
    walkable[3] = false; // block (0,1)
    walkable[4] = false; // block (1,1)
                         // Cell (0,0) is isolated from (2,2) since diagonal is also blocked
    let mut ff = FlowField::new(3, 3, walkable);
    ff.set_goal(2, 2);
    // (0,0) should be unreachable
    assert!(ff.get_distance(0, 0).is_infinite());
}

// ── QLearner ─────────────────────────────────────────────────────────────────

#[test]
fn test_qlearner_new() {
    let ql = QLearner::new(4, 3);
    assert!((ql.get_q(0, 0)).abs() < 1e-10);
    assert!((ql.get_q(3, 2)).abs() < 1e-10);
    // Out of bounds returns 0
    assert!((ql.get_q(10, 10)).abs() < 1e-10);
}

#[test]
fn test_qlearner_learn_updates_q() {
    let mut ql = QLearner::new(3, 2);
    // Q starts at 0, learn with reward 10
    ql.learn(0, 0, 10.0, 1);
    // Q(0,0) should have been updated: 0 + 0.1 * (10 + 0.9*0 - 0) = 1.0
    assert!((ql.get_q(0, 0) - 1.0).abs() < 1e-10);

    // Second learn step
    ql.learn(0, 0, 10.0, 1);
    // Q(0,0) = 1.0 + 0.1 * (10 + 0.9*0 - 1.0) = 1.0 + 0.9 = 1.9
    assert!((ql.get_q(0, 0) - 1.9).abs() < 1e-10);
}

#[test]
fn test_qlearner_best_action() {
    let mut ql = QLearner::new(2, 3);
    ql.set_q(0, 0, 1.0);
    ql.set_q(0, 1, 5.0);
    ql.set_q(0, 2, 3.0);
    assert_eq!(ql.best_action(0), 1);

    // Out of bounds returns 0
    assert_eq!(ql.best_action(99), 0);
}

#[test]
fn test_qlearner_serialize_deserialize() {
    let mut ql = QLearner::new(2, 3);
    ql.set_q(0, 0, 1.5);
    ql.set_q(0, 1, 2.5);
    ql.set_q(0, 2, 3.5);
    ql.set_q(1, 0, 4.0);
    ql.set_q(1, 1, 5.0);
    ql.set_q(1, 2, 6.0);

    let json = ql.serialize();

    let mut ql2 = QLearner::new(2, 3);
    ql2.deserialize(&json).unwrap();

    assert!((ql2.get_q(0, 0) - 1.5).abs() < 1e-10);
    assert!((ql2.get_q(0, 2) - 3.5).abs() < 1e-10);
    assert!((ql2.get_q(1, 2) - 6.0).abs() < 1e-10);
}

#[test]
fn test_qlearner_deserialize_dimension_mismatch() {
    let mut ql = QLearner::new(2, 2);
    let result = ql.deserialize("[[1,2,3]]"); // Wrong dimensions
    assert!(result.is_err());
}

#[test]
fn test_qlearner_end_episode_decays_epsilon() {
    let mut ql = QLearner::new(2, 2);
    // After end_episode, epsilon should decay (Q-values don't change so we just verify no panic)
    ql.end_episode();
    // After a second end_episode, verify it still runs
    ql.end_episode();
}

// ── UtilityAI ────────────────────────────────────────────────────────────────

#[test]
fn test_utility_ai_new() {
    let uai = UtilityAI::new();
    assert!(uai.actions.is_empty());
    assert!(uai.last_action.is_none());
    assert!(uai.last_scores.is_empty());
}

#[test]
fn test_response_curve_parse() {
    assert_eq!(ResponseCurve::parse_str("linear"), ResponseCurve::Linear);
    assert_eq!(
        ResponseCurve::parse_str("quadratic"),
        ResponseCurve::Quadratic
    );
    assert_eq!(
        ResponseCurve::parse_str("logistic"),
        ResponseCurve::Logistic
    );
    assert_eq!(ResponseCurve::parse_str("logit"), ResponseCurve::Logit);
    assert_eq!(ResponseCurve::parse_str("step"), ResponseCurve::Step);
    // Unknown defaults to Linear
    assert_eq!(ResponseCurve::parse_str("unknown"), ResponseCurve::Linear);
}

#[test]
fn test_response_curve_apply() {
    // Linear: p1 * input + p2
    let linear = ResponseCurve::Linear;
    assert!((linear.apply(0.5, 2.0, 1.0, 0.0) - 2.0).abs() < 1e-5); // 2*0.5 + 1 = 2

    // Quadratic: p1 * input^2 + p2 * input + p3
    let quad = ResponseCurve::Quadratic;
    assert!((quad.apply(3.0, 1.0, 2.0, 1.0) - 16.0).abs() < 1e-5); // 1*9 + 2*3 + 1 = 16

    // Step: if input >= p1 then p2 else p3
    let step = ResponseCurve::Step;
    assert!((step.apply(0.5, 0.5, 1.0, 0.0) - 1.0).abs() < 1e-5); // 0.5 >= 0.5 → 1.0
    assert!((step.apply(0.3, 0.5, 1.0, 0.0)).abs() < 1e-5); // 0.3 < 0.5 → 0.0

    // Logistic: 1 / (1 + e^(-p1*(input-p2)))
    let logistic = ResponseCurve::Logistic;
    let val = logistic.apply(0.5, 10.0, 0.5, 0.0); // At midpoint → 0.5
    assert!((val - 0.5).abs() < 1e-5);
}

// ── GOAPPlanner ──────────────────────────────────────────────────────────────

#[test]
fn test_goap_new() {
    let planner = GOAPPlanner::new();
    assert!(planner.actions.is_empty());
    assert!(planner.goals.is_empty());
}

#[test]
fn test_goap_plan_simple() {
    let mut planner = GOAPPlanner::new();

    // Action: "chop" => requires has_axe:true, effects: has_wood:true
    let mut chop_pre = HashMap::new();
    chop_pre.insert("has_axe".to_string(), true);
    let mut chop_eff = HashMap::new();
    chop_eff.insert("has_wood".to_string(), true);
    planner.actions.push(GOAPAction {
        name: "chop".to_string(),
        cost: 1.0,
        callback: None,
        preconditions: chop_pre,
        effects: chop_eff,
    });

    // Action: "get_axe" => no preconditions, effects: has_axe:true
    let mut axe_eff = HashMap::new();
    axe_eff.insert("has_axe".to_string(), true);
    planner.actions.push(GOAPAction {
        name: "get_axe".to_string(),
        cost: 1.0,
        callback: None,
        preconditions: HashMap::new(),
        effects: axe_eff,
    });

    // Goal: has_wood:true
    let mut goal_state = HashMap::new();
    goal_state.insert("has_wood".to_string(), true);
    planner.goals.push(GOAPGoal {
        name: "gather_wood".to_string(),
        priority: 1.0,
        state: goal_state,
    });

    // World state: nothing
    let world_state = HashMap::new();
    let plan = planner.plan(&world_state, 10);
    assert!(!plan.is_empty());
    // Plan should include "get_axe" then "chop"
    assert!(plan.contains(&"get_axe".to_string()));
    assert!(plan.contains(&"chop".to_string()));
}

#[test]
fn test_goap_plan_already_satisfied() {
    let mut planner = GOAPPlanner::new();
    let mut goal_state = HashMap::new();
    goal_state.insert("done".to_string(), true);
    planner.goals.push(GOAPGoal {
        name: "finish".to_string(),
        priority: 1.0,
        state: goal_state,
    });

    let mut world_state = HashMap::new();
    world_state.insert("done".to_string(), true);
    let plan = planner.plan(&world_state, 10);
    assert!(plan.is_empty()); // Already satisfied
}

#[test]
fn test_goap_plan_no_goals() {
    let planner = GOAPPlanner::new();
    let world_state = HashMap::new();
    let plan = planner.plan(&world_state, 10);
    assert!(plan.is_empty());
}

// ── InfluenceMap ─────────────────────────────────────────────────────────────

#[test]
fn test_influence_map_new() {
    let im = InfluenceMap::new(10, 8, 16.0);
    assert_eq!(im.width, 10);
    assert_eq!(im.height, 8);
    assert!((im.cell_size - 16.0).abs() < 1e-5);
}

#[test]
fn test_influence_map_add_layer() {
    let mut im = InfluenceMap::new(4, 4, 16.0);
    assert!(!im.has_layer("threat"));
    im.add_layer("threat");
    assert!(im.has_layer("threat"));
}

#[test]
fn test_influence_map_set_get() {
    let mut im = InfluenceMap::new(4, 4, 16.0);
    im.add_layer("threat");
    // Default is 0
    assert!((im.get_influence("threat", 0, 0)).abs() < 1e-5);
    im.set_influence("threat", 1, 2, 5.0);
    assert!((im.get_influence("threat", 1, 2) - 5.0).abs() < 1e-5);
    // Nonexistent layer returns 0
    assert!((im.get_influence("missing", 0, 0)).abs() < 1e-5);
    // Out of bounds returns 0
    assert!((im.get_influence("threat", 99, 99)).abs() < 1e-5);
}

#[test]
fn test_influence_map_stamp() {
    let mut im = InfluenceMap::new(10, 10, 10.0);
    im.add_layer("heat");
    // Stamp at center (50, 50) with radius 20, value 10, falloff 1.0
    im.stamp_influence("heat", 50.0, 50.0, 20.0, 10.0, 1.0);
    // Cell at (5, 5) = world center (55, 55) should have some influence
    let center_val = im.get_influence("heat", 5, 5);
    assert!(center_val > 0.0);
    // Cell far away should remain 0
    assert!((im.get_influence("heat", 0, 0)).abs() < 1e-5);
}

#[test]
fn test_influence_map_clear_all() {
    let mut im = InfluenceMap::new(4, 4, 16.0);
    im.add_layer("a");
    im.add_layer("b");
    im.set_influence("a", 0, 0, 5.0);
    im.set_influence("b", 1, 1, 3.0);
    im.clear_all();
    assert!((im.get_influence("a", 0, 0)).abs() < 1e-5);
    assert!((im.get_influence("b", 1, 1)).abs() < 1e-5);
}

#[test]
fn test_influence_map_clear_layer() {
    let mut im = InfluenceMap::new(4, 4, 16.0);
    im.add_layer("a");
    im.add_layer("b");
    im.set_influence("a", 0, 0, 5.0);
    im.set_influence("b", 0, 0, 3.0);
    im.clear_layer("a");
    assert!((im.get_influence("a", 0, 0)).abs() < 1e-5);
    assert!((im.get_influence("b", 0, 0) - 3.0).abs() < 1e-5);
}

#[test]
fn test_influence_map_decay() {
    let mut im = InfluenceMap::new(2, 2, 16.0);
    im.add_layer("threat");
    im.set_influence("threat", 0, 0, 10.0);
    im.decay("threat", 0.5);
    assert!((im.get_influence("threat", 0, 0) - 5.0).abs() < 1e-5);
}

// ── Squad ────────────────────────────────────────────────────────────────────

#[test]
fn test_squad_new() {
    let squad = Squad::new("alpha");
    assert_eq!(squad.name, "alpha");
    assert!(squad.members.is_empty());
    assert!(squad.leader.is_none());
    assert_eq!(squad.formation, FormationType::None);
    assert!((squad.formation_spacing - 30.0).abs() < 1e-5);
}

#[test]
fn test_squad_formation_parse() {
    assert_eq!(FormationType::parse_str("none"), FormationType::None);
    assert_eq!(FormationType::parse_str("line"), FormationType::Line);
    assert_eq!(FormationType::parse_str("wedge"), FormationType::Wedge);
    assert_eq!(FormationType::parse_str("circle"), FormationType::Circle);
    assert_eq!(FormationType::parse_str("column"), FormationType::Column);
    // Unknown defaults to None
    assert_eq!(FormationType::parse_str("unknown"), FormationType::None);
}

#[test]
fn test_squad_formation_as_str() {
    assert_eq!(FormationType::None.as_str(), "none");
    assert_eq!(FormationType::Line.as_str(), "line");
    assert_eq!(FormationType::Wedge.as_str(), "wedge");
    assert_eq!(FormationType::Circle.as_str(), "circle");
    assert_eq!(FormationType::Column.as_str(), "column");
}

#[test]
fn test_squad_get_formation_position() {
    let mut squad = Squad::new("bravo");
    squad.members = vec!["a".to_string(), "b".to_string(), "c".to_string()];
    squad.formation_spacing = 20.0;
    let leader_pos = (100.0, 100.0);

    // None formation: all at leader position
    squad.formation = FormationType::None;
    let pos = squad.get_formation_position(1, leader_pos);
    assert!((pos.0 - 100.0).abs() < 1e-5);
    assert!((pos.1 - 100.0).abs() < 1e-5);

    // Column formation: vertical line behind leader
    squad.formation = FormationType::Column;
    let pos0 = squad.get_formation_position(0, leader_pos);
    let pos1 = squad.get_formation_position(1, leader_pos);
    let pos2 = squad.get_formation_position(2, leader_pos);
    assert!((pos0.0 - 100.0).abs() < 1e-5);
    assert!((pos0.1 - 100.0).abs() < 1e-5);
    assert!((pos1.0 - 100.0).abs() < 1e-5);
    assert!((pos1.1 - 120.0).abs() < 1e-5); // 100 + 1*20
    assert!((pos2.0 - 100.0).abs() < 1e-5);
    assert!((pos2.1 - 140.0).abs() < 1e-5); // 100 + 2*20

    // Circle formation: positions around leader at radius=spacing
    squad.formation = FormationType::Circle;
    let pos0 = squad.get_formation_position(0, leader_pos);
    // Member 0: angle=0 → (100+20, 100+0)
    assert!((pos0.0 - 120.0).abs() < 1e-5);
    assert!((pos0.1 - 100.0).abs() < 1e-3);
}

// ── CommandQueue ─────────────────────────────────────────────────────────────

#[test]
fn test_command_queue_new_empty() {
    let cq = CommandQueue::new();
    assert!(cq.is_empty());
    assert_eq!(cq.count(), 0);
    assert!(cq.current_type().is_none());
}

#[test]
fn test_command_queue_enqueue_dequeue() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();
    let cmd1 = make_command(&lua, "move", true);
    let cmd2 = make_command(&lua, "attack", true);
    cq.enqueue(cmd1);
    cq.enqueue(cmd2);
    assert_eq!(cq.count(), 2);
    assert_eq!(cq.current_type(), Some("move"));
    cq.advance();
    assert_eq!(cq.count(), 1);
    assert_eq!(cq.current_type(), Some("attack"));
    cq.advance();
    assert!(cq.is_empty());
}

#[test]
fn test_command_queue_push_front() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();
    let cmd1 = make_command(&lua, "patrol", true);
    let cmd2 = make_command(&lua, "urgent", true);
    cq.enqueue(cmd1);
    cq.push_front(cmd2);
    assert_eq!(cq.current_type(), Some("urgent"));
}

#[test]
fn test_command_queue_cancel_current() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();

    // Interruptible command can be cancelled
    let cmd = make_command(&lua, "move", true);
    cq.enqueue(cmd);
    assert!(cq.cancel_current());
    assert!(cq.is_empty());

    // Non-interruptible command cannot be cancelled
    let cmd = make_command(&lua, "cast", false);
    cq.enqueue(cmd);
    assert!(!cq.cancel_current());
    assert_eq!(cq.count(), 1);
}

#[test]
fn test_command_queue_clear() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();
    cq.enqueue(make_command(&lua, "a", true));
    cq.enqueue(make_command(&lua, "b", true));
    cq.enqueue(make_command(&lua, "c", true));
    assert_eq!(cq.count(), 3);
    cq.clear();
    assert!(cq.is_empty());
    assert_eq!(cq.count(), 0);
}

#[test]
fn test_command_queue_replace() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();
    cq.enqueue(make_command(&lua, "old1", true));
    cq.enqueue(make_command(&lua, "old2", true));
    cq.replace(make_command(&lua, "new", true));
    assert_eq!(cq.count(), 1);
    assert_eq!(cq.current_type(), Some("new"));
}

#[test]
fn test_command_queue_target() {
    let lua = make_lua();
    let mut cq = CommandQueue::new();
    let cb = lua.create_registry_value(true).unwrap();
    let cmd = Command {
        kind: "move".to_string(),
        callback: cb,
        target_x: 42.5,
        target_y: -17.0,
        priority: 0,
        interruptible: true,
    };
    cq.enqueue(cmd);
    let target = cq.current_target();
    assert!((target.0 - 42.5).abs() < 1e-5);
    assert!((target.1 - (-17.0)).abs() < 1e-5);
}
