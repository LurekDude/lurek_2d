# `graph` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.graph`                                         |
| **Source**      | `src/graph/`                                         |
| **Rust Tests** | `tests/rust/unit/graph_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_graph.lua`                      |
| **Architecture** | —                                                  |

## Purpose

The graph module provides a general-purpose directed weighted graph with item flow simulation, Dijkstra pathfinding, and a classical algorithm suite. It is a Tier 2 engine extension that depends only on Baseline (`math`, `engine`) and no Tier 1 modules. Game developers use it whenever their data is naturally relational rather than spatial: dialogue trees where nodes are lines and edges are player choices, quest dependency systems where completing a quest unlocks others, skill trees, resource production pipelines, logistics networks, and dungeon layout validation.

## Source Files

| File               | Purpose                                                                      |
|--------------------|------------------------------------------------------------------------------|
| `mod.rs`           | Module declarations, re-exports of public types                              |
| `algorithms.rs`    | Graph algorithms — connected components (BFS), cycle detection (DFS), topological sort (Kahn's) |
| `core.rs`          | `Graph` struct — node, edge, and item CRUD, stats, edge queries              |
| `edge.rs`          | `Edge` struct — directed connection with capacity, cooldown, type filtering  |
| `item.rs`          | `GraphItem` and `ItemPosition` — typed flowing entities with decay and priority |
| `node.rs`          | `Node`, `OverflowPolicy`, `FlowMode`, `ConversionRule`, `Supply`, `Demand`  |
| `pathfinding.rs`   | `PathResult` and Dijkstra shortest-path, reachability, neighbour queries     |
| `simulation.rs`    | `GraphEvent` enum and 7-phase simulation pipeline (`update`/`step`)          |
| `supply_demand.rs` | Supply/demand matching with priority-ordered fulfillment via pathfinding     |
| `graph.rs`         | Legacy duplicate of `core.rs` — not declared in `mod.rs`, dead code          |
| `traversal.rs`     | Legacy duplicate of `pathfinding.rs` — not declared in `mod.rs`, dead code   |

## Key Types

| Type | Description |
|------|-------------|
| `GraphStats` | Principal type for the `graph` module. |
| `Graph` | Principal type for the `graph` module. |
| `Edge` | Principal type for the `graph` module. |
| `ItemPosition` | Principal type for the `graph` module. |
| `GraphItem` | Principal type for the `graph` module. |
| `OverflowPolicy` | Principal type for the `graph` module. |
| `FlowMode` | Principal type for the `graph` module. |
| `ConversionRule` | Principal type for the `graph` module. |
| `Supply` | Principal type for the `graph` module. |
| `Demand` | Principal type for the `graph` module. |
| `Node` | Principal type for the `graph` module. |
| `PathResult` | Principal type for the `graph` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.graph.newGraph()` | See `docs/specs/graph.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/graph.md`](../../docs/specs/graph.md)

_Update both this file **and** `docs/specs/graph.md` whenever source files, public types, or Lua bindings change._
