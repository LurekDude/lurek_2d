# IDEA.md — `ai` module

> Migrated from `ideas/features/ai.md` and `ideas/performance/05-ai-pathfinding.md` (Part 1).
> Status checked against `src/ai/` file list and `src/lua_api/ai_api.rs`.

---

## Features

### ✅ DONE — HTN (Hierarchical Task Network)
**Source**: features/ai.md — Feature Gaps #1

`src/ai/htn.rs` exists. More structured than GOAP; decomposes high-level tasks into primitive
actions. Popular in AAA games (FEAR, Killzone).

---

### ✅ DONE — AI Director / Drama Manager
**Source**: features/ai.md — Feature Gaps #3

`src/ai/director.rs` exists. Dynamically adjusts difficulty, pacing, and encounter intensity
based on player performance (Left 4 Dead–style).

---

### ✅ DONE — Monte Carlo Tree Search (MCTS)
**Source**: features/ai.md — Feature Gaps #4

`src/ai/mcts.rs` exists. Useful for turn-based game AI (board games, card games, strategy).

---

### ✅ DONE — ORCA Dynamic Obstacle Avoidance
**Source**: features/ai.md — Feature Gaps #5

`src/ai/orca.rs` exists. Reciprocal velocity obstacle (RVO/ORCA) algorithm for crowd simulation.

---

### ✅ DONE — AI Sensing / Perception System
**Source**: features/ai.md — Suggestions #1

`src/ai/perception.rs` exists and is exposed via `lurek.ai` (StimulusWorld in `ai_api.rs`).
Percept system feeding into FSM/BT decisions — sight range, angles, hearing.

---

### ❌ TODO — NavMesh Integration for Steering
**Source**: features/ai.md — Feature Gaps #2 / Suggestions #2

Steering behaviors and pathfinding are separate systems. Agents should be able to query the
NavMesh (or nav-grid) for walkable areas during steering.

Suggested API:
```lua
steeringAgent:setPath(navGrid:findPath(start, end))
```

No implementation found in `ai_api.rs` or `src/ai/`.

---

### ✅ DONE — Behavior Tree Debug State Export
**Source**: features/ai.md — Feature Gaps #6 / Suggestions #5

`bt:getDebugState()` added, returns `{ node_count, last_status }`.
Implemented in `src/ai/behavior_tree.rs` + `src/lua_api/ai_api.rs`.

---

### ❌ TODO — Dialogue AI Integration
**Source**: features/ai.md — Feature Gaps #8

AI module has no bridge to the dialogue system. NPC conversation decisions (which topic to
raise, which branch to choose) should be driveable from FSM/BT/Utility AI.

No implementation found. Requires design alignment with `dialog` library module.

---

### 🤔 CONSIDER — Sub-Namespace the Lua API
**Source**: features/ai.md — Suggestions #4

The `lurek.ai` table currently contains 50+ functions in a flat namespace. Consider grouping:
- `lurek.ai.fsm.*`
- `lurek.ai.bt.*`
- `lurek.ai.goap.*`
- `lurek.ai.steering.*`
- `lurek.ai.utility.*`

This is a **breaking API change** — needs sign-off from Lua-Designer and MAJOR version bump.

---

### 🤔 CONSIDER — Config-gate Q-Learning as Optional
**Source**: features/ai.md — Structural Issues

Q-Learning is the most niche AI paradigm. Consider toggling it via `ModulesConfig` or moving
the RL subsystem (`qlearner.rs`, `bandit.rs`, `neural_net.rs`, `neuroevolution.rs`, `genetic.rs`)
into an optional feature group.

---

## Performance

### ❌ DEFERRED — GOAP Parallel Planning (rayon / Lua thread workers)
**Source**: performance/05-ai-pathfinding.md — Section 1 / GOAP

Rayon parallel planning is out-of-scope for Foundation tier. Option B (Lua thread workers
via `lurek.thread.new()`) is the documented pattern — no Rust change required.

---

### ✅ DONE — Spatial Hashing for Steering (O(n²) → O(n))
**Source**: performance/05-ai-pathfinding.md — Section 3 / Steering

`cell_size: f32` (default 64.0) and `use_spatial_hash: bool` (default false) added to
`SteeringManager` in `src/ai/steering.rs`. Setters: `steering:setSpatialHashCellSize(size)`
and `steering:enableSpatialHash(enabled)` via `src/lua_api/ai_api.rs`.

---

### ❌ DEFERRED — Parallel Steering Force Computation (rayon)
**Source**: performance/05-ai-pathfinding.md — Section 3 / Steering

After the spatial-hash landing (✅ now done), per-agent steering calculations are independent.
rayon parallel iteration would reduce to O(n / cores). Deferred until profiling confirms need.

---

### 🔇 LOW — Utility AI Parallel Scoring
**Source**: performance/05-ai-pathfinding.md — Section 4 / Utility AI

Each agent evaluates 10–100 action/consideration pairs. Too little work per agent to benefit
from rayon overhead <100 agents. Defer until profiling shows it as a hot path.
