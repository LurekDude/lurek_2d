# graph — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/graph.md`
**Files**: Directed graphs, flow simulation

## Purpose

General-purpose directed graph data structure with traversal algorithms and flow simulation. Nodes store custom data, edges have weights.

## Current Feature Summary

- `DirectedGraph`: adjacency list with typed node/edge data
- Node operations: add, remove, get data, list neighbors
- Edge operations: add weighted edges, remove, query
- Traversal: BFS, DFS
- Topological sort (for DAGs)
- Cycle detection
- Connected components
- Flow simulation: pipe network with sources/sinks, flow propagation
- Shortest path: Dijkstra
- Graph metrics: degree, density

## Feature Gaps

1. **No A* on graph**: Only Dijkstra for shortest path. A* with heuristic would be faster for spatial graphs.
2. **No minimum spanning tree**: Kruskal/Prim — useful for procedural map connections.
3. **No graph visualization**: No built-in way to visualize the graph structure (even as debug draw).
4. **No serialization**: Can't save/load graphs.
5. **No subgraph extraction**: Can't extract a portion of the graph.
6. **No bipartite matching**: Useful for assignment problems in game systems.

## Structural Issues

- **Overlap with pathfinding**: Both modules do graph traversal. Pathfinding is grid-specific, graph is general. But Dijkstra exists in both conceptually. Consider:
  - Merge graph algorithms INTO pathfinding as a general graph backend
  - Or make graph a utility used BY pathfinding internally
- **Flow simulation is niche**: Pipe network flow is a very specific mechanic (Factorio-like). Not sure this belongs in a general graph module. Could be a library/ Tier 3 module.
- **Is this needed?**: How many 2D games need a general directed graph? Tech trees, skill trees, faction relationships could use it. But most games implement these as simple Lua tables.

## Suggestions

1. **Consider merging with pathfinding**: Make pathfinding the "spatial algorithms" module that includes both grid and graph pathfinding.
2. **Move flow simulation to Tier 3**: `library/flow/` — pure Lua flow network simulation using `lurek.graph` as the substrate. Removes niche gameplay from core engine.
3. **Add graph serialization**: `graph:serialize()` → JSON-compatible table for save/load.
4. **Add minimum spanning tree**: `graph:mst()` — Prim's or Kruskal's. Useful for procedural map connections.
5. **Add A* on graph**: `graph:findPath(start, goal, heuristic)` — A* with custom heuristic function.

## Competitor Comparison

No competitor 2D Lua engine has a built-in graph module. This is unique to Lurek2D. However, graph algorithms are easily implemented in Lua — the value of a Rust implementation is pure performance.

| Feature | Lurek2D | Engine A | Engine B | Engine D |
|---|---|---|---|---|
| Graph data structure | ✅ | ❌ | ❌ | ❌ |
| BFS/DFS | ✅ | ❌ | ❌ | ❌ |
| Shortest path | ✅ (Dijkstra) | ❌ | ❌ | ❌ |
| Flow simulation | ✅ | ❌ | ❌ | ❌ |
| Topo sort | ✅ | ❌ | ❌ | ❌ |

## Priority

**LOW** — Module is functional but niche. Merge consideration with pathfinding is the main architectural question. Flow simulation should move to Tier 3.
