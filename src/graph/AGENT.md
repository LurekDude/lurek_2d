# graph - Agent Reference

## Module Info

- Module: graph
- Group: Foundations
- Spec: docs/specs/graph.md
- Lua API: src/lua_api/graph_api.rs
- Rust tests: tests/rust/unit/graph_tests.rs plus inline graph module tests
- Lua tests: tests/lua/unit/test_graph.lua and related graph stress and golden suites

## Module Purpose

The graph module owns directed node-edge-item networks plus the algorithms needed to simulate flow through them. It combines CRUD-style graph storage with routing, connected-component and cycle analysis, item transit, conversion rules, queueing, and supply-demand fulfillment.

This module exists for systems whose logic is relational rather than spatial, such as logistics networks, production chains, dependency graphs, or abstract game-economy flows. It is intentionally not a renderer or a world-space pathfinding system. The small render helper is only for debug visualization, and the legacy graph.rs and traversal.rs files are older on-disk copies rather than the active public surface declared by mod.rs.

## Files

- mod.rs: Declares the active graph submodules and re-exports the public graph, node, edge, item, and event types.
- core.rs: Defines Graph and GraphStats plus node, edge, and item management operations.
- node.rs: Defines Node and the flow, overflow, conversion, supply, and demand types that give nodes gameplay meaning.
- edge.rs: Defines Edge, the directed connection with capacity, travel timing, cooldowns, weights, and item-type filters.
- item.rs: Defines GraphItem and ItemPosition for typed items that rest on nodes or travel across edges.
- pathfinding.rs: Adds Dijkstra-based shortest-path, reachability, and neighbor queries.
- algorithms.rs: Adds connected-component, cycle-detection, and topological-sort helpers.
- simulation.rs: Implements the main tick pipeline and emits GraphEvent values for transit, decay, conversion, queue, and routing activity.
- supply_demand.rs: Matches demand declarations to supplies and routes created items through the graph.
- render.rs: Generates debug render commands for visualizing graph state without making graph a rendering subsystem.
- graph.rs: Older duplicate graph container file kept on disk but not declared by mod.rs.
- traversal.rs: Older duplicate pathfinding file kept on disk but not declared by mod.rs.

## Key Types

- Graph: Central directed graph container that owns nodes, edges, items, and most module behavior through impl blocks.
- GraphStats: Read-only state summary for graph size, activity, demand, supply, and queued items.
- Node: Rich vertex type with capacity, flow mode, overflow policy, queueing, conversion rules, supplies, demands, and tags.
- Edge: Directed connection that controls routing cost, travel time, cooldown, capacity, and allowed item types.
- GraphItem: Typed entity that moves through the graph with lifetime, priority, and current position state.
- ItemPosition: Enum describing whether an item is at a node, in transit on an edge, or unplaced.
- FlowMode: Enum describing whether a node passively holds items or actively pushes and or pulls them.
- OverflowPolicy: Enum describing how full nodes reject, destroy, or queue incoming items.
- GraphEvent: Event enum emitted by simulation and demand processing for Lua callback dispatch.
- PathResult: Shortest-path result containing ordered node IDs, edge IDs, and total path cost.
