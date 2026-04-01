---
name: graph-systems
description: "Load this skill when working with Luna2D directed graphs: node/edge CRUD, item flow simulation, supply/demand processing, Dijkstra pathfinding, or graph algorithms. Skip it for grid pathfinding, AI behavior trees, or rendering."
---

# Graph Systems — Luna2D Engine

## Load When

- Building directed graphs with item flow
- Implementing supply/demand resource networks
- Using graph algorithms (components, cycles, topological sort)
- Working with Dijkstra shortest-path on graphs
- Simulating item transit, conversion, or decay
- Using `luna.graph.*` API functions

## Owns

- `src/graph/` module — directed graph with flow simulation
- `src/lua_api/graph_api.rs` — `luna.graph.*` Lua bindings

## Does Not Cover

- Grid pathfinding (A★, HPA★) → use `pathfinding-systems` skill
- AI behavior trees → use `ai-systems` skill
- Physics collision → use `physics-engine` skill

## Live Repository Contracts

- `src/graph/core.rs` — `Graph` struct, node/edge CRUD
- `src/graph/simulation.rs` — tick-based item flow engine
- `src/graph/supply_demand.rs` — Supply, Demand, resource processing
- `src/graph/algorithms.rs` — connected components, topological sort, cycle detection
- `src/graph/traversal.rs` — Dijkstra shortest-path
- `tests/graph_tests.rs` — node/edge CRUD, referential integrity

## Key Types

| Type | Purpose |
|---|---|
| `Graph` | Main container: nodes, edges, items, statistics |
| `Node` | With conversion rules, overflow policy, flow mode |
| `Edge` | With capacity, cooldown, type-filtering |
| `GraphItem` | Typed items flowing through the graph |
| `FlowMode` | Push, Pull, Convert behaviors |
| `ConversionRule` | Input→output type transformation |
| `Supply` | Source node item generation |
| `Demand` | Sink node item consumption |
| `GraphEvent` | Simulation events (flow, decay, transit) |

## Decision Rules

- **Nodes have unique IDs** — generated sequentially; removal cleans up all connected edges
- **Edges are directional** — from source node to target node; capacity limits flow
- **Items flow through edges** — transit time, decay, and type filtering apply
- **ConversionRule transforms items** — one input type → one output type at a node
- **Supply/Demand drives flow** — sources generate items, sinks consume them
- **Tick-based simulation** — call `graph.tick()` each frame to advance flow

## Best Practices

- Remove nodes cleanly — the graph automatically removes connected edges
- Use type-filtering on edges to route different items along different paths
- Set edge capacity to prevent bottlenecks from flooding downstream nodes
- Use Dijkstra for shortest-path queries on weighted graphs
- Check for cycles before relying on topological sort — cycles prevent valid ordering

## Anti-Patterns

- **Orphan edges**: Creating edges before both nodes exist — always create nodes first
- **Unbounded flow**: No edge capacity limits — items accumulate without control
- **Tick skipping**: Not calling `tick()` every frame — flow stalls
- **Ignoring events**: Not processing `GraphEvent`s — missed decay, overflow, transit notifications
