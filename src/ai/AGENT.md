# `ai` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.ai`                                            |
| **Source**      | `src/ai/`                                            |
| **Rust Tests** | `tests/rust/unit/ai_tests.rs`                        |
| **Lua Tests**  | `tests/lua/unit/test_ai.lua`                         |
| **Architecture** | —                                                  |

## Purpose

The AI module provides a comprehensive, modular game-intelligence toolkit that Lua scripts can assemble to match the needs of each actor in a scene. Rather than committing to a single AI paradigm it offers five interchangeable decision models — finite state machines for reactive logic, behaviour trees for conditional priority behaviour, steering behaviours for smooth movement, GOAP for goal-oriented NPC planning, utility AI for scored multi-axis action selection, and tabular Q-learning for reinforcement learning — all managed through a central `AIWorld` registry that tracks agents, blackboards, and shared spatial structures.

## Source Files

| File                | Purpose                                                                          |
|---------------------|----------------------------------------------------------------------------------|
| `mod.rs`            | Module declarations, re-exports from `crate::pathfinding` (FlowField, Cell, PathGrid, InfluenceMap) |
| `agent.rs`          | Autonomous agent with kinematic state (position, velocity) and pluggable decision models |
| `behavior_tree.rs`  | Behavior tree with composite (Selector, Sequence, Parallel), decorator (Inverter, Repeater, Succeeder), and leaf (Action, Condition) nodes |
| `blackboard.rs`     | Typed key-value store with optional parent chain for hierarchical lookup         |
| `command_queue.rs`  | RTS-style ordered command queue with enqueue, push-front, replace, and cancel    |
| `fsm.rs`            | Finite state machine with priority-ordered guarded transitions and lifecycle callbacks |
| `goap.rs`           | Goal-Oriented Action Planning using A★ search over boolean world state           |
| `qlearner.rs`       | Tabular epsilon-greedy Q-learner for discrete-state reinforcement learning       |
| `squad.rs`          | Multi-agent formation groups with offset computation (line, wedge, circle, column) |
| `steering.rs`       | Reynolds-style steering behaviors with weighted or priority-based force combination |
| `utility_ai.rs`     | Multi-axis utility scorer with response curves for action selection              |
| `world.rs`          | Top-level AI container that owns agents, maintains name→index lookup, and provides global blackboard |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/ai.md`](../../docs/specs/ai.md)

_Update both this file **and** `docs/specs/ai.md` whenever source files, public types, or Lua bindings change._
