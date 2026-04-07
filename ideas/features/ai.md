# ai — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/ai.md`
**Files**: 8+ AI systems

## Purpose

Game AI toolkit: multiple AI paradigms including FSM, behavior trees, GOAP, steering behaviors, utility AI, Q-learning, influence maps, squad formations, and shared blackboard.

## Current Feature Summary

- **FSM**: Finite state machines with named states and transitions
- **Behavior Trees**: composite (sequence/selector/parallel), decorators (inverter/repeater/guard/cooldown), action/condition leaves
- **GOAP**: Goal-Oriented Action Planning — goals with priority, actions with preconditions/effects, automatic plan generation
- **Steering Behaviors**: seek, flee, arrive, pursue, evade, wander, separation, alignment, cohesion, obstacle avoidance, path following
- **Utility AI**: scoring-based decision making with weighted curves
- **Q-Learning**: basic reinforcement learning for NPC behavior adaptation
- **Influence Maps**: grid-based value propagation for tactical awareness
- **Squad Formations**: formation patterns (line, wedge, circle) with slot assignment
- **Command Queue**: sequential/parallel command execution with undo
- **Blackboard**: shared key-value store for inter-system data exchange

## Feature Gaps

1. **No HTN (Hierarchical Task Network)**: More structured than GOAP, popular in AAA games (FEAR, Killzone). Decomposes high-level tasks into primitive actions.
2. **No NavMesh integration**: AI steering and pathfinding use separate systems. Steering should be able to query NavMesh for walkable areas.
3. **No AI director/drama manager**: No system to dynamically adjust difficulty, pacing, or encounter intensity based on player performance (Left 4 Dead style).
4. **No Monte Carlo Tree Search**: Useful for turn-based game AI (board games, card games, strategy).
5. **No dynamic obstacle avoidance (ORCA)**: Steering has basic obstacle avoidance but no reciprocal velocity obstacle (RVO/ORCA) for crowd simulation.
6. **No behavior tree visual debugger**: Complex BTs are hard to debug without visualization of active nodes.
7. **No AI sensing**: No built-in sight/hearing/awareness system (raycasts + distance checks) for perception.
8. **No dialogue AI**: AI module doesn't integrate with dialogue system for NPC conversation decisions.

## Structural Issues

- **Very comprehensive**: 8+ AI paradigms in one module is impressive but overwhelming. Most games use 1-2 AI paradigms. Consider if all need to ship in core.
- **AI module size**: With FSM, BT, GOAP, Steering, Utility, QLearning, InfluenceMap, Squad, CommandQueue, Blackboard — this is one of the largest modules. Could benefit from sub-modules.
- **Q-Learning is experimental**: RL in game AI is uncommon. Might confuse users expecting traditional AI.
- **Steering + Pathfinding gap**: Steering behaviors need pathfinding data but there's no direct integration bridge.

## Suggestions

1. **Add AI sensing system**: `luna.ai.newSensor(entity, {sightRange=200, sightAngle=120, hearingRange=100})` — percept system that feeds into FSM/BT decisions. Common need for stealth and action games.
2. **Add steering-pathfinding bridge**: `steeringAgent:setPath(navGrid:findPath(start, end))` — seamless integration.
3. **Add MCTS for turn-based**: `luna.ai.mcts(rootState, simulateFn, maxIterations)` — enables competent AI for card games, board games, strategy.
4. **Sub-modularize**: Group into `luna.ai.fsm.*`, `luna.ai.bt.*`, `luna.ai.goap.*` etc. Current flat namespace with 50+ functions is overwhelming.
5. **Add BT debugger data**: `bt:getDebugState()` → returns tree with active/success/fail per node for visualization.
6. **Consider making Q-Learning optional**: It's the most niche AI paradigm. Config-gate it or move to Tier 3 library.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy | Game AI libs |
|---|---|---|---|---|---|
| FSM | ✅ | ❌ | ❌ | ❌ | ✅ |
| Behavior Trees | ✅ | ❌ | ❌ | ❌ | ✅ |
| GOAP | ✅ | ❌ | ❌ | ❌ | ✅ |
| Steering | ✅ | ❌ | ❌ | ❌ | ✅ |
| Utility AI | ✅ | ❌ | ❌ | ❌ | ✅ |
| RL/Q-Learning | ✅ | ❌ | ❌ | ❌ | ❌ |
| Influence Maps | ✅ | ❌ | ❌ | ❌ | ✅ |
| Formations | ✅ | ❌ | ❌ | ❌ | ❌ |

Luna2D has the most comprehensive built-in AI system of any 2D game engine. This is a major differentiator.

## Priority

**MEDIUM** — AI is already best-in-class. Sensing system and pathfinding bridge are the highest-impact additions. Sub-modularization is important for usability.
