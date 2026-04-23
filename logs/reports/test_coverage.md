# Lurek2D Test Coverage Report

## Summary

| Category | Covered | Total | Coverage |
|----------|---------|-------|----------|
| Rust public functions | 3228 | 4155 | 77.7% |
| Lua API functions | 3704 | 3704 | 100.0% |

## Rust Coverage by Module

| Module | Covered | Total | Coverage |
|--------|---------|-------|----------|
| ai | 209 | 290 | 72.1% |
| animation | 63 | 70 | 90.0% |
| app | 13 | 19 | 68.4% |
| audio | 167 | 210 | 79.5% |
| automation | 30 | 38 | 78.9% |
| camera | 78 | 85 | 91.8% |
| compute | 86 | 109 | 78.9% |
| data | 63 | 73 | 86.3% |
| dataframe | 80 | 119 | 67.2% |
| debugbridge | 8 | 9 | 88.9% |
| devtools | 34 | 34 | 100.0% |
| docs | 31 | 32 | 96.9% |
| ecs | 47 | 78 | 60.3% |
| effect | 71 | 91 | 78.0% |
| event | 15 | 22 | 68.2% |
| filesystem | 64 | 73 | 87.7% |
| globe | 94 | 117 | 80.3% |
| graph | 98 | 120 | 81.7% |
| i18n | 25 | 30 | 83.3% |
| image | 91 | 149 | 61.1% |
| input | 78 | 92 | 84.8% |
| light | 52 | 89 | 58.4% |
| log | 23 | 25 | 92.0% |
| lua_api | 66 | 85 | 77.6% |
| math | 218 | 241 | 90.5% |
| minimap | 81 | 82 | 98.8% |
| mods | 17 | 20 | 85.0% |
| network | 36 | 66 | 54.5% |
| parallax | 9 | 12 | 75.0% |
| particle | 41 | 59 | 69.5% |
| pathfind | 96 | 145 | 66.2% |
| patterns | 152 | 161 | 94.4% |
| physics | 100 | 163 | 61.3% |
| pipeline | 27 | 29 | 93.1% |
| procgen | 56 | 59 | 94.9% |
| raycaster | 63 | 75 | 84.0% |
| render | 42 | 59 | 71.2% |
| root | 0 | 1 | 0.0% |
| runtime | 16 | 30 | 53.3% |
| save | 39 | 41 | 95.1% |
| scene | 40 | 52 | 76.9% |
| serial | 12 | 14 | 85.7% |
| spine | 42 | 46 | 91.3% |
| sprite | 35 | 40 | 87.5% |
| terminal | 50 | 99 | 50.5% |
| thread | 24 | 26 | 92.3% |
| tilemap | 209 | 255 | 82.0% |
| timer | 34 | 37 | 91.9% |
| tween | 26 | 31 | 83.9% |
| ui | 142 | 217 | 65.4% |
| window | 35 | 36 | 97.2% |

## Lua API Coverage by Module

| Module | Covered | Total | Coverage |
|--------|---------|-------|----------|
| ai | 242 | 242 | 100.0% |
| animation | 46 | 46 | 100.0% |
| audio | 212 | 212 | 100.0% |
| automation | 28 | 28 | 100.0% |
| camera | 36 | 36 | 100.0% |
| compute | 71 | 71 | 100.0% |
| data | 57 | 57 | 100.0% |
| dataframe | 88 | 88 | 100.0% |
| debugbridge | 14 | 14 | 100.0% |
| devtools | 48 | 48 | 100.0% |
| docs | 75 | 75 | 100.0% |
| ecs | 47 | 47 | 100.0% |
| effect | 145 | 145 | 100.0% |
| engine | 10 | 10 | 100.0% |
| event | 22 | 22 | 100.0% |
| filesystem | 54 | 54 | 100.0% |
| globe | 44 | 44 | 100.0% |
| graph | 111 | 111 | 100.0% |
| i18n | 31 | 31 | 100.0% |
| image | 68 | 68 | 100.0% |
| input | 80 | 80 | 100.0% |
| light | 83 | 83 | 100.0% |
| log | 18 | 18 | 100.0% |
| math | 204 | 204 | 100.0% |
| minimap | 56 | 56 | 100.0% |
| mods | 46 | 46 | 100.0% |
| network | 38 | 38 | 100.0% |
| parallax | 43 | 43 | 100.0% |
| particle | 89 | 89 | 100.0% |
| pathfind | 65 | 65 | 100.0% |
| patterns | 170 | 170 | 100.0% |
| physics | 151 | 151 | 100.0% |
| pipeline | 60 | 60 | 100.0% |
| procgen | 29 | 29 | 100.0% |
| raycaster | 42 | 42 | 100.0% |
| render | 183 | 183 | 100.0% |
| save | 22 | 22 | 100.0% |
| scene | 53 | 53 | 100.0% |
| serial | 10 | 10 | 100.0% |
| spine | 20 | 20 | 100.0% |
| sprite | 18 | 18 | 100.0% |
| system | 26 | 26 | 100.0% |
| terminal | 82 | 82 | 100.0% |
| thread | 37 | 37 | 100.0% |
| tilemap | 138 | 138 | 100.0% |
| timer | 43 | 43 | 100.0% |
| tween | 35 | 35 | 100.0% |
| ui | 364 | 364 | 100.0% |
| window | 50 | 50 | 100.0% |

## Uncovered Rust Functions (top 50)

- `CommandQueue::push_front` in `src/ai/command_queue.rs:112`
- `CommandQueue::cancel_current` in `src/ai/command_queue.rs:129`
- `CommandQueue::current_type` in `src/ai/command_queue.rs:166`
- `CommandQueue::current_target` in `src/ai/command_queue.rs:174`
- `CommandQueue::enqueue_raw` in `src/ai/command_queue.rs:195`
- `CommandQueue::push_front_raw` in `src/ai/command_queue.rs:216`
- `CommandQueue::replace_raw` in `src/ai/command_queue.rs:237`
- `ContextSteering::add_interest` in `src/ai/context_steering.rs:188`
- `ContextSteering::add_danger` in `src/ai/context_steering.rs:202`
- `ContextSteering::add_wander` in `src/ai/context_steering.rs:226`
- `ContextSteering::add_avoid_point` in `src/ai/context_steering.rs:237`
- `ContextSteering::add_avoid_bounds` in `src/ai/context_steering.rs:250`
- `ContextSteering::chosen_magnitude` in `src/ai/context_steering.rs:354`
- `ContextSteering::interest_map` in `src/ai/context_steering.rs:360`
- `ContextSteering::danger_map` in `src/ai/context_steering.rs:366`
- `AIDirector::with_config` in `src/ai/director.rs:165`
- `AIDirector::phase_str` in `src/ai/director.rs:196`
- `AIDirector::spawn_rate_factor` in `src/ai/director.rs:278`
- `AIDirector::loot_factor` in `src/ai/director.rs:292`
- `AIDirector::ambient_intensity` in `src/ai/director.rs:306`
- `AIDirector::set_tension` in `src/ai/director.rs:319`
- `EmotionModel::active_names` in `src/ai/emotion.rs:223`
- `StateMachine::time_in_state` in `src/ai/fsm.rs:159`
- `StateMachine::add_transition_raw` in `src/ai/fsm.rs:194`
- `GOAPPlanner::plan_for_goal_idx` in `src/ai/goap.rs:199`
- `GOAPPlanner::add_action` in `src/ai/goap.rs:297`
- `GOAPPlanner::add_precondition` in `src/ai/goap.rs:313`
- `GOAPPlanner::set_goal_state` in `src/ai/goap.rs:350`
- `HTNTask::is_primitive` in `src/ai/htn.rs:90`
- `HTNTask::preconditions_met` in `src/ai/htn.rs:102`
- `HTNTask::apply_effects` in `src/ai/htn.rs:116`
- `HTNMethod::is_applicable` in `src/ai/htn.rs:188`
- `HTNDomain::task_count` in `src/ai/htn.rs:269`
- `AILod::tier_for` in `src/ai/lod.rs:128`
- `AILod::should_update` in `src/ai/lod.rs:167`
- `Need::is_urgent` in `src/ai/needs.rs:85`
- `Need::urgency_score` in `src/ai/needs.rs:94`
- `NeedAdvertisement::is_available` in `src/ai/needs.rs:185`
- `NeedAdvertisement::use_it` in `src/ai/needs.rs:191`
- `NeedSystem::need_names` in `src/ai/needs.rs:318`
- `NeedSystem::value_of` in `src/ai/needs.rs:329`
- `NeedSystem::best_advertisement` in `src/ai/needs.rs:344`
- `NeuralLayer::param_count` in `src/ai/neural_net.rs:152`
- `NeuralNet::param_count` in `src/ai/neural_net.rs:217`
- `Neuroevolution::chromosome_to_net` in `src/ai/neuroevolution.rs:82`
- `Neuroevolution::best_network` in `src/ai/neuroevolution.rs:111`
- `Neuroevolution::best_fitness` in `src/ai/neuroevolution.rs:122`
- `StimulusWorld::add_auditory` in `src/ai/perception.rs:236`
- `StimulusWorld::add_custom` in `src/ai/perception.rs:262`
- `StimulusWorld::stimuli` in `src/ai/perception.rs:306`
- ... and 877 more
