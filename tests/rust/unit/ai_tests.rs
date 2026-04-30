//! Smoke tests for the ai module against the current public API.

// ── agent ─────────────────────────────────────────────────────────────────────

mod agent_tests {
    use lurek2d::ai::agent::DecisionModel;

    #[test]
    fn decision_model_parse_round_trip() {
        for &s in &["fsm", "bt", "steering", "fsm+steering", "bt+steering"] {
            let dm = DecisionModel::parse_str(s).unwrap();
            assert_eq!(dm.as_str(), s);
        }
    }
}

// ── bandit ────────────────────────────────────────────────────────────────────

mod bandit_tests {
    use lurek2d::ai::bandit::{Bandit, BanditStrategy};

    #[test]
    fn new_bandit_defaults() {
        let b = Bandit::new(3, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        assert_eq!(b.arm_count(), 3);
        assert_eq!(b.total_pulls, 0);
    }

    #[test]
    fn update_tracks_reward() {
        let mut b = Bandit::new(2, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        b.update(0, 1.0);
        assert_eq!(b.total_pulls, 1);
        assert!(b.arms[0].mean_reward() > 0.0);
    }

    #[test]
    fn best_arm_picks_highest() {
        let mut b = Bandit::new(3, BanditStrategy::EpsilonGreedy { epsilon: 0.1 }, 42);
        b.update(0, 0.5);
        b.update(1, 1.0);
        b.update(2, 0.1);
        assert_eq!(b.best_arm(), 1);
    }
}

// ── behavior_tree ─────────────────────────────────────────────────────────────

mod behavior_tree_tests {
    use lurek2d::ai::behavior_tree::{BTStatus, BehaviorTree, ParallelPolicy};

    #[test]
    fn bt_status_conversions() {
        assert_eq!(BTStatus::Success.as_str(), "success");
        assert_eq!(BTStatus::Failure.as_str(), "failure");
        assert_eq!(BTStatus::Running.as_str(), "running");
    }

    #[test]
    fn parallel_policy_parse() {
        assert_eq!(
            ParallelPolicy::parse_str("requireAll"),
            ParallelPolicy::RequireAll
        );
        assert_eq!(
            ParallelPolicy::parse_str("requireOne"),
            ParallelPolicy::RequireOne
        );
        assert_eq!(
            ParallelPolicy::parse_str("unknown"),
            ParallelPolicy::RequireOne
        );
    }

    #[test]
    fn new_tree_has_no_root() {
        let bt = BehaviorTree::new();
        assert!(bt.root.is_none());
        assert_eq!(bt.debug_state().node_count, 0);
    }
}

// ── director ──────────────────────────────────────────────────────────────────

mod director_tests {
    use lurek2d::ai::director::{AIDirector, DirectorPhase};

    #[test]
    fn starts_in_relief_phase() {
        let d = AIDirector::new();
        assert_eq!(d.phase(), DirectorPhase::Relief);
        assert_eq!(d.tension(), 0.0);
    }

    #[test]
    fn push_event_increases_tension() {
        let mut d = AIDirector::new();
        d.push_event(0.5);
        assert!(d.tension() > 0.0);
        assert_eq!(d.total_events(), 1);
    }
}

// ── emotion ───────────────────────────────────────────────────────────────────

mod emotion_tests {
    use lurek2d::ai::emotion::{Emotion, EmotionModel};

    #[test]
    fn emotion_trigger_and_decay() {
        let mut e = Emotion::new("anger", 0.0, 0.5, 0.1);
        e.trigger(0.8);
        assert!((e.value - 0.8).abs() < 1e-6);
        e.update(1.0);
        assert!((e.value - 0.3).abs() < 1e-6);
    }

    #[test]
    fn emotion_model_dominant() {
        let mut model = EmotionModel::new();
        model.add(Emotion::new("anger", 0.0, 0.5, 0.1));
        model.add(Emotion::new("fear", 0.0, 0.5, 0.1));
        model.trigger("anger", 0.6);
        model.trigger("fear", 0.3);
        assert_eq!(model.dominant(), Some("anger"));
    }
}

// ── fsm ───────────────────────────────────────────────────────────────────────

mod fsm_tests {
    use lurek2d::ai::fsm::StateMachine;

    #[test]
    fn new_fsm_has_no_state() {
        let fsm = StateMachine::new();
        assert!(fsm.current_state().is_none());
    }

    #[test]
    fn add_state_raw_is_callable() {
        let mut fsm = StateMachine::new();
        fsm.add_state_raw("idle".to_string(), None, None, None);
        fsm.set_initial_state("idle".to_string());
        assert!(fsm.current_state().is_none());
    }
}

// ── genetic ───────────────────────────────────────────────────────────────────

mod genetic_tests {
    use lurek2d::ai::genetic::GeneticAlgorithm;

    #[test]
    fn population_initialised() {
        let ga = GeneticAlgorithm::new(10, 5, 42);
        assert_eq!(ga.population.len(), 10);
        assert!(ga.population.iter().all(|g| g.genes.len() == 5));
    }

    #[test]
    fn evolve_step_preserves_size_and_increments_generation() {
        let mut ga = GeneticAlgorithm::new(8, 4, 42);
        for (i, chromosome) in ga.population.iter_mut().enumerate() {
            chromosome.fitness = i as f32;
        }
        ga.evolve();
        assert_eq!(ga.population.len(), 8);
        assert_eq!(ga.generation, 1);
    }
}

// ── goap ──────────────────────────────────────────────────────────────────────

mod goap_tests {
    use lurek2d::ai::goap::GOAPPlanner;

    #[test]
    fn set_max_iterations() {
        let mut planner = GOAPPlanner::new();
        planner.set_max_iterations(500);
        assert_eq!(planner.get_max_iterations(), 500);
    }
}

// ── htn ───────────────────────────────────────────────────────────────────────

mod htn_tests {
    use lurek2d::ai::htn::{HTNDomain, HTNMethod, HTNPlanner, WorldState};

    fn sample_domain() -> HTNDomain {
        let mut domain = HTNDomain::new();
        domain.add_primitive("eat", vec!["hungry"], vec![], vec!["hungry"]);
        domain.add_compound(
            "satisfy_hunger",
            vec![HTNMethod::with_preconditions(
                "use_eat",
                vec!["hungry"],
                vec!["eat"],
            )],
        );
        domain
    }

    #[test]
    fn decompose_compound_task() {
        let domain = sample_domain();
        let mut state = WorldState::new();
        state.insert("hungry".to_string(), 1.0);
        let plan = HTNPlanner::plan(&domain, "satisfy_hunger", &state);
        assert_eq!(plan.unwrap(), vec!["eat"]);
    }
}

// ── lod ───────────────────────────────────────────────────────────────────────

mod lod_tests {
    use lurek2d::ai::lod::AILod;

    #[test]
    fn default_has_three_tiers() {
        let lod = AILod::default();
        assert_eq!(lod.tier_count(), 3);
    }

    #[test]
    fn assign_tiers_batch() {
        let lod = AILod::default();
        let agents = vec![(10.0, 10.0), (500.0, 0.0), (2000.0, 0.0)];
        assert_eq!(lod.assign_tiers(&agents, (0.0, 0.0)), vec![0, 1, 2]);
    }
}

// ── needs ─────────────────────────────────────────────────────────────────────

mod needs_tests {
    use lurek2d::ai::needs::{Need, NeedSystem};

    #[test]
    fn new_need_defaults() {
        let n = Need::new("hunger", 0.1, 0.5, 1.5);
        assert_eq!(n.name, "hunger");
        assert!((n.value - 1.0).abs() < 1e-6);
    }

    #[test]
    fn most_urgent_picks_highest() {
        let mut system = NeedSystem::new();
        let mut hunger = Need::new("hunger", 0.1, 0.5, 1.5);
        hunger.deprive(0.9);
        system.add_need(hunger);
        system.add_need(Need::new("rest", 0.1, 0.5, 1.5));
        assert_eq!(system.most_urgent(), Some("hunger"));
    }
}

// ── neural_net ────────────────────────────────────────────────────────────────

mod neural_net_tests {
    use lurek2d::ai::neural_net::{Activation, NeuralNet};

    #[test]
    fn two_layer_forward() {
        let mut nn = NeuralNet::new();
        nn.add_layer(3, 4, Activation::ReLU);
        nn.add_layer(4, 2, Activation::Sigmoid);
        let out = nn.forward(&[1.0, 0.5, -0.3]);
        assert_eq!(out.len(), 2);
    }

    #[test]
    fn get_set_weights_round_trip() {
        let mut nn = NeuralNet::new();
        nn.add_layer(2, 2, Activation::Sigmoid);
        let weights = nn.get_weights();
        assert!(nn.set_weights(&weights));
        assert_eq!(weights, nn.get_weights());
    }
}

// ── neuroevolution ────────────────────────────────────────────────────────────

mod neuroevolution_tests {
    use lurek2d::ai::neuroevolution::Neuroevolution;

    #[test]
    fn new_pool_creates_population() {
        let ne = Neuroevolution::new(vec![(2, 3, "relu"), (3, 1, "sigmoid")], 10, 42);
        assert_eq!(ne.pop_size(), 10);
    }

    #[test]
    fn evolve_preserves_size() {
        let mut ne = Neuroevolution::new(vec![(2, 1, "sigmoid")], 6, 42);
        for i in 0..6 {
            ne.set_fitness(i, i as f32);
        }
        ne.evolve();
        assert_eq!(ne.pop_size(), 6);
    }
}

// ── orca ──────────────────────────────────────────────────────────────────────

mod orca_tests {
    use lurek2d::ai::orca::{ORCAAgent, ORCASolver};

    #[test]
    fn add_agent_and_compute() {
        let mut solver = ORCASolver::new(2.0);
        solver.add_agent(ORCAAgent {
            position: (0.0, 0.0),
            velocity: (0.0, 0.0),
            preferred_velocity: (1.0, 0.0),
            safe_velocity: (0.0, 0.0),
            radius: 0.5,
            max_speed: 2.0,
        });
        solver.compute(0.016);
        assert_eq!(solver.agent_count(), 1);
        let v = solver.agents[0].safe_velocity;
        assert!((v.0 * v.0 + v.1 * v.1).sqrt() <= 2.0 + 1e-3);
    }
}

// ── perception ────────────────────────────────────────────────────────────────

mod perception_tests {
    use lurek2d::ai::perception::{Sensor, StimulusWorld};

    #[test]
    fn sensor_detects_nearby_visual_stimulus() {
        let sensor = Sensor::new();
        let mut world = StimulusWorld::new();
        world.add_visual(10.0, 0.0, 1.0, 50.0, Some("enemy".into()));
        let detected = sensor.detect((0.0, 0.0), &world);
        assert_eq!(detected.len(), 1);
    }

    #[test]
    fn stimulus_world_remove_reduces_count() {
        let mut world = StimulusWorld::new();
        let id = world.add_visual(1.0, 2.0, 1.0, 50.0, Some("test".into()));
        assert_eq!(world.count(), 1);
        assert!(world.remove(id));
        assert_eq!(world.count(), 0);
    }
}

// ── squad ─────────────────────────────────────────────────────────────────────

mod squad_tests {
    use lurek2d::ai::squad::{FormationType, Squad};

    #[test]
    fn add_remove_member() {
        let mut squad = Squad::new("alpha");
        squad.members.push("1".to_string());
        squad.members.push("2".to_string());
        assert_eq!(squad.members.len(), 2);
        squad.members.retain(|m| m != "1");
        assert_eq!(squad.members.len(), 1);
    }

    #[test]
    fn line_formation_positions() {
        let mut squad = Squad::new("bravo");
        squad.formation = FormationType::Line;
        squad.members.push("0".to_string());
        squad.members.push("1".to_string());
        squad.formation_spacing = 10.0;
        let p0 = squad.get_formation_position(0, (0.0, 0.0));
        let p1 = squad.get_formation_position(1, (0.0, 0.0));
        assert!((p0.0 - p1.0).abs() > 1.0);
    }
}

// ── steering ──────────────────────────────────────────────────────────────────

mod steering_tests {
    use lurek2d::ai::steering::{CombineMode, SteeringManager};

    #[test]
    fn combine_mode_parse() {
        assert_eq!(CombineMode::parse_str("weighted"), CombineMode::Weighted);
        assert_eq!(CombineMode::parse_str("priority"), CombineMode::Priority);
        assert_eq!(CombineMode::parse_str("nope"), CombineMode::Weighted);
    }

    #[test]
    fn calculate_seek_force_is_finite() {
        let mut manager = SteeringManager::new();
        manager.add_seek(10.0, 0.0, 1.0);
        let force = manager.calculate((0.0, 0.0), (0.0, 0.0), 100.0, 10.0, 0.016);
        assert!(force.0.is_finite() && force.1.is_finite());
    }
}

// ── strategy ──────────────────────────────────────────────────────────────────

mod strategy_tests {
    use lurek2d::ai::strategy::{StrategicGoal, StrategyAI};

    #[test]
    fn add_goal_increases_count() {
        let mut strategy = StrategyAI::new(1.0);
        strategy.add_goal(StrategicGoal::new("attack"));
        assert_eq!(strategy.goal_count(), 1);
    }

    #[test]
    fn force_evaluate_picks_best_goal() {
        let mut strategy = StrategyAI::new(1.0);
        strategy.add_goal(StrategicGoal::new("attack"));
        strategy.add_goal(StrategicGoal::new("retreat"));
        let mut scorer = |name: &str| if name == "retreat" { 2.0 } else { 1.0 };
        strategy.force_evaluate(&mut scorer);
        assert_eq!(strategy.active_goal(), Some("retreat"));
    }
}

// ── traits ────────────────────────────────────────────────────────────────────

mod traits_tests {
    use std::collections::HashMap;

    use lurek2d::ai::traits::{TraitArchetypes, TraitProfile};

    #[test]
    fn profile_set_get_clamped() {
        let mut p = TraitProfile::new();
        p.set("aggression", 0.5);
        assert!((p.get("aggression") - 0.5).abs() < 1e-6);
        p.set("aggression", 1.5);
        assert!((p.get("aggression") - 1.0).abs() < 1e-6);
    }

    #[test]
    fn modifier_affects_effective_value() {
        let mut p = TraitProfile::new();
        p.set("caution", 0.3);
        p.add_modifier("caution", 0.4, None, "buff");
        assert!((p.get("caution") - 0.7).abs() < 1e-6);
    }

    #[test]
    fn archetype_creates_profile() {
        let mut arch = TraitArchetypes::new();
        let mut base = HashMap::new();
        base.insert("aggression".to_string(), 0.8);
        arch.register("berserker", base);
        let p = TraitProfile::from_archetype(&arch, "berserker", 0.0).unwrap();
        assert!((p.get("aggression") - 0.8).abs() < 1e-6);
    }
}

// ── utility_ai ────────────────────────────────────────────────────────────────

mod utility_ai_tests {
    use lurek2d::ai::utility_ai::{ResponseCurve, UtilityAI};

    #[test]
    fn response_curve_linear() {
        let c = ResponseCurve::Linear;
        assert!((c.apply(0.5, 2.0, 0.0, 1.0) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn empty_utility_ai_has_no_last_action() {
        let ai = UtilityAI::new();
        assert!(ai.last_action_name().is_none());
        assert!(ai.actions.is_empty());
    }
}

// ── extensibility: DecisionModel::Custom ─────────────────────────────────────

mod decision_model_custom_tests {
    use lurek2d::ai::agent::DecisionModel;

    #[test]
    fn decision_model_custom_as_str() {
        let dm = DecisionModel::Custom { callback_id: 42 };
        assert_eq!(dm.as_str(), "custom");
    }

    #[test]
    fn decision_model_custom_not_parseable_by_string() {
        // "custom" is a runtime-only model set via agent:setCustomModel(fn),
        // not via agent:setDecisionModel("custom").
        assert!(DecisionModel::parse_str("custom").is_none());
    }

    #[test]
    fn decision_model_existing_round_trips_unaffected() {
        for &s in &["fsm", "bt", "steering", "fsm+steering", "bt+steering"] {
            let dm = DecisionModel::parse_str(s).unwrap();
            assert_eq!(dm.as_str(), s);
        }
    }
}

// ── extensibility: ResponseCurve::Custom ─────────────────────────────────────

mod response_curve_custom_tests {
    use lurek2d::ai::utility_ai::ResponseCurve;

    #[test]
    fn response_curve_custom_identity_transform() {
        let rc = ResponseCurve::Custom { callback_id: 0 };
        // apply() returns identity for Custom; real call handled by Lua API layer.
        assert!((rc.apply(0.7, 1.0, 0.0, 0.0) - 0.7).abs() < 1e-10);
        assert!((rc.apply(0.0, 2.0, 1.0, 0.5) - 0.0).abs() < 1e-10);
        assert!((rc.apply(1.0, 5.0, 0.0, 0.0) - 1.0).abs() < 1e-10);
    }

    #[test]
    fn response_curve_custom_not_parsed_from_string() {
        // "custom" is runtime-only; parse_str falls through to Linear default.
        let rc = ResponseCurve::parse_str("custom");
        assert_eq!(rc, ResponseCurve::Linear);
    }
}

// ── extensibility: SteeringBehaviorType::Custom ───────────────────────────────

mod steering_custom_tests {
    use lurek2d::ai::steering::{SteeringBase, SteeringBehaviorType};

    #[test]
    fn steering_custom_kind_is_custom() {
        let b = SteeringBehaviorType::Custom {
            callback_id: 1,
            base: SteeringBase::default(),
        };
        assert_eq!(b.kind(), "custom");
    }

    #[test]
    fn steering_custom_calculate_returns_zero_force() {
        let b = SteeringBehaviorType::Custom {
            callback_id: 0,
            base: SteeringBase::default(),
        };
        // calculate() is a no-op for Custom; Lua layer handles the real call.
        let force = b.calculate((0.0, 0.0), (10.0, 0.0), 100.0, 0.016);
        assert_eq!(force, (0.0, 0.0));
    }

    #[test]
    fn steering_custom_base_weight_accessible() {
        let b = SteeringBehaviorType::Custom {
            callback_id: 7,
            base: SteeringBase { weight: 2.5, enabled: true },
        };
        assert!((b.base().weight - 2.5).abs() < 1e-6);
        assert!(b.base().enabled);
    }
}

// ── extensibility: BTNode::Guard (structural) ─────────────────────────────────

mod bt_node_guard_tests {
    use lurek2d::ai::behavior_tree::{BTNode, BehaviorTree};

    #[test]
    fn bt_node_guard_child_count_is_one() {
        // Guard nodes can't be built in unit tests (RegistryKey not constructable),
        // but we verify child_count for other decorator nodes returns 1.
        let inv = BTNode::Inverter {
            child: Box::new(BTNode::Sequence {
                children: Vec::new(),
                running_idx: 0,
            }),
        };
        assert_eq!(inv.child_count(), 1);
    }

    #[test]
    fn new_behavior_tree_empty_state() {
        let bt = BehaviorTree::new();
        assert!(bt.root.is_none());
        assert_eq!(bt.debug_state().node_count, 0);
    }
}

