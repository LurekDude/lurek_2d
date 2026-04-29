# Lurek2D Test Coverage Report

## Summary

| Category | Covered | Total | Coverage |
|----------|---------|-------|----------|
| Rust public functions | 3253 | 4229 | 76.9% |
| Lua API functions | 4364 | 4388 | 99.5% |

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
| html | 24 | 73 | 32.9% |
| i18n | 25 | 30 | 83.3% |
| image | 91 | 149 | 61.1% |
| input | 78 | 92 | 84.8% |
| light | 52 | 89 | 58.4% |
| log | 23 | 25 | 92.0% |
| lua_api | 67 | 86 | 77.9% |
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
| ai | 321 | 322 | 99.7% |
| animation | 63 | 63 | 100.0% |
| audio | 218 | 219 | 99.5% |
| automation | 28 | 28 | 100.0% |
| camera | 49 | 49 | 100.0% |
| compute | 86 | 87 | 98.9% |
| data | 68 | 68 | 100.0% |
| dataframe | 116 | 118 | 98.3% |
| debugbridge | 14 | 14 | 100.0% |
| devtools | 58 | 58 | 100.0% |
| docs | 85 | 85 | 100.0% |
| ecs | 63 | 63 | 100.0% |
| effect | 157 | 158 | 99.4% |
| engine | 10 | 10 | 100.0% |
| event | 26 | 26 | 100.0% |
| filesystem | 60 | 60 | 100.0% |
| globe | 57 | 57 | 100.0% |
| graph | 126 | 126 | 100.0% |
| html | 56 | 59 | 94.9% |
| i18n | 31 | 31 | 100.0% |
| image | 90 | 90 | 100.0% |
| input | 87 | 87 | 100.0% |
| light | 90 | 90 | 100.0% |
| log | 18 | 18 | 100.0% |
| math | 243 | 246 | 98.8% |
| minimap | 76 | 76 | 100.0% |
| mods | 53 | 53 | 100.0% |
| network | 51 | 51 | 100.0% |
| parallax | 44 | 44 | 100.0% |
| particle | 98 | 100 | 98.0% |
| pathfind | 93 | 94 | 98.9% |
| patterns | 170 | 170 | 100.0% |
| physics | 201 | 205 | 98.0% |
| pipeline | 61 | 62 | 98.4% |
| procgen | 18 | 18 | 100.0% |
| raycaster | 58 | 61 | 95.1% |
| render | 196 | 196 | 100.0% |
| save | 28 | 28 | 100.0% |
| scene | 55 | 55 | 100.0% |
| serial | 10 | 10 | 100.0% |
| spine | 34 | 34 | 100.0% |
| sprite | 24 | 24 | 100.0% |
| system | 26 | 26 | 100.0% |
| terminal | 87 | 87 | 100.0% |
| thread | 37 | 37 | 100.0% |
| tilemap | 187 | 188 | 99.5% |
| timer | 49 | 49 | 100.0% |
| tween | 58 | 58 | 100.0% |
| ui | 380 | 380 | 100.0% |
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
- `NeuralLayer::param_count` in `src/ai/neural_net.rs:153`
- `NeuralNet::param_count` in `src/ai/neural_net.rs:219`
- `Neuroevolution::chromosome_to_net` in `src/ai/neuroevolution.rs:82`
- `Neuroevolution::best_network` in `src/ai/neuroevolution.rs:111`
- `Neuroevolution::best_fitness` in `src/ai/neuroevolution.rs:122`
- `StimulusWorld::add_auditory` in `src/ai/perception.rs:237`
- `StimulusWorld::add_custom` in `src/ai/perception.rs:264`
- `StimulusWorld::stimuli` in `src/ai/perception.rs:308`
- ... and 926 more

## Uncovered Lua API Functions (top 50)

- `LInfluenceMap:stampInfluence` (method) in `src/lua_api/ai_api.rs:1837`
- `LBus:setDuckTarget` (method) in `src/lua_api/audio_api.rs:543`
- `LArray:eigenPower` (method) in `src/lua_api/compute_api.rs:841`
- `LDataFrame:withRollingMin` (method) in `src/lua_api/dataframe_api.rs:722`
- `LDataFrame:withRollingMax` (method) in `src/lua_api/dataframe_api.rs:737`
- `LOverlay:triggerShake` (method) in `src/lua_api/effect_api.rs:727`
- `lurek.html.preventDefault` (function) in `src/lua_api/html_api.rs:919`
- `lurek.html.stopPropagation` (function) in `src/lua_api/html_api.rs:928`
- `lurek.html.isDefaultPrevented` (function) in `src/lua_api/html_api.rs:937`
- `LNoiseGenerator:worley3d` (method) in `src/lua_api/math_api.rs:1320`
- `LNoiseGenerator:warpDomain` (method) in `src/lua_api/math_api.rs:1446`
- `LNoiseGenerator:generateMap` (method) in `src/lua_api/math_api.rs:1457`
- `LTrail:setHeadColor` (method) in `src/lua_api/particle_api.rs:1435`
- `LTrail:setTailColor` (method) in `src/lua_api/particle_api.rs:1451`
- `LFlowField:calculateMulti` (method) in `src/lua_api/pathfind_api.rs:601`
- `LWorld:setJointMotorSpeed` (method) in `src/lua_api/physics_api.rs:695`
- `LWorld:setJointLimitsEnabled` (method) in `src/lua_api/physics_api.rs:716`
- `LWorld:setJointLimits` (method) in `src/lua_api/physics_api.rs:732`
- `LWorld:setMouseJointTarget` (method) in `src/lua_api/physics_api.rs:755`
- `LPipeline:addSubPipeline` (method) in `src/lua_api/pipeline_api.rs:1087`
- `LRaycaster:drawDepthMap` (method) in `src/lua_api/raycaster_api.rs:563`
- `LRaycaster:drawLineOfSight` (method) in `src/lua_api/raycaster_api.rs:590`
- `LRaycaster:drawCameraSweep` (method) in `src/lua_api/raycaster_api.rs:608`
- `LChunkMap:getChunksInView` (method) in `src/lua_api/tilemap_api.rs:1208`
