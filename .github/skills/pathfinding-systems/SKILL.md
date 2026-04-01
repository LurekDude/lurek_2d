---
name: pathfinding-systems
description: "Load this skill when implementing grid pathfinding in Luna2D: A★, HPA★, flow fields, NavGrid setup, or unit-size-aware navigation. Skip it for AI decision-making, physics, or steering behaviors."
---

# Pathfinding Systems — Luna2D Engine

## Load When

- Implementing A★ pathfinding on a grid
- Setting up HPA★ (Hierarchical Pathfinding A★) for large maps
- Building flow fields for crowd movement
- Configuring NavGrid (walkability, diagonal modes, unit sizes)
- Working with async pathfinding (PathThreadPool)
- Implementing UnitPathfinder for multi-unit coordination

## Owns

- `src/pathfinding/` module — all pathfinding algorithms
- `src/lua_api/pathfinding_api.rs` — `luna.pathfinding.*` Lua bindings
- Grid walkability and cost configuration
- Path smoothing and line-of-sight optimization

## Does Not Cover

- AI decision-making (FSM, BT, GOAP) → use `ai-systems` skill
- Steering-based movement → use `ai-systems` skill (steering section)
- Physics collision → use `physics-engine` skill
- Tilemap walkability data → use `tilemap-rendering` skill (provides the data source)

## Live Repository Contracts

- `src/pathfinding/mod.rs` — module root, re-exports
- `src/pathfinding/astar.rs` — `astar()`, `line_of_sight()`, `smooth_path()`
- `src/pathfinding/hpa.rs` — `build_abstract()`, `hpa_star()`, `AbstractGraph`
- `src/pathfinding/flow_field.rs` — `FlowField` (Dijkstra-based crowd navigation)
- `src/pathfinding/nav_grid.rs` — `NavGrid`, `DiagonalMode`, `Cell`
- `src/pathfinding/async_pool.rs` — `PathThreadPool` (background pathfinding)
- `src/pathfinding/unit_pathfinder.rs` — `UnitPathfinder`, `Waypoint`

## Decision Rules

- **NavGrid is the foundation** — all algorithms operate on NavGrid data; configure it first
- **DiagonalMode controls movement** — `None` (4-dir), `AllowDiagonal` (8-dir), `NoDiagonalCut` (8-dir, no corner cutting)
- **A★ for individual paths** — best for single-agent, dynamic obstacle pathfinding
- **HPA★ for large static maps** — precompute `AbstractGraph` once, query many times; rebuild on map changes
- **FlowField for crowds** — compute once from a target, many agents follow the field simultaneously
- **line_of_sight() post-processes paths** — call `smooth_path()` after `astar()` for natural-looking movement
- **Unit sizes affect walkability** — NavGrid supports footprint-based blocking (2x2, 3x3 units)
- **PathThreadPool for non-blocking** — expensive paths run on background threads; poll for completion

## Algorithm Selection Guide

| Scenario | Algorithm | Why |
|---|---|---|
| Single unit, small map (<100x100) | A★ | Fast, simple, handles dynamic obstacles |
| Single unit, large map (>200x200) | HPA★ | Precomputed hierarchy avoids full-grid search |
| Many units, same destination | FlowField | One computation serves all agents |
| Multiple units, pathfinding pressure | PathThreadPool + A★ | Non-blocking, distributes CPU load |
| Large units (vehicles, bosses) | NavGrid with unit sizes | Footprint-aware walkability |
| Path post-processing | smooth_path() + line_of_sight() | Removes zigzag artifacts |

## Best Practices

- Always configure NavGrid diagonal mode before computing paths
- Use `smooth_path()` on A★ results — raw grid paths look unnatural
- Precompute HPA★ abstract graph at level load — not per frame
- FlowField targets should be stable — recompute only when target moves significantly
- Set NavGrid costs for terrain variation (swamp = 3, road = 1) — don't use uniform cost
- PathThreadPool: check completion every frame, don't block waiting for results

## Anti-Patterns

- **Full A★ every frame**: Recomputing paths every frame instead of on-demand — cache and reuse
- **Wrong algorithm scale**: Using A★ on 500x500 grids with 100 agents — use FlowField or HPA★
- **Ignoring unit size**: Large units pathfinding through narrow gaps they can't fit — set unit footprint
- **Blocking pathfinding**: Calling `astar()` synchronously for 50 agents in one frame — use PathThreadPool
- **No path smoothing**: Raw grid paths create unnatural zigzag movement — always smooth
