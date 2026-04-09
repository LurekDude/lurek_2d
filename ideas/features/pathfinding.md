# pathfinding — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/pathfinding.md`
**Files**: NavGrid, A*, HPA*, Flow Fields

## Purpose

Grid-based pathfinding: A* search, hierarchical A* (HPA*), flow field computation on navigability grids.

## Current Feature Summary

- `NavGrid`: 2D grid with per-cell walk cost and blocked status
- A* pathfinding: optimal shortest path with diagonal support
- HPA*: hierarchical chunked pathfinding for large grids (faster long-distance paths)
- Flow fields: Dijkstra-based flow computation for crowd movement (all-to-one)
- Dynamic cost updates: modify grid costs at runtime
- Path smoothing: basic string-pulling to reduce jagged paths
- Neighbor modes: 4-connected (cardinal) or 8-connected (diagonal)
- Multiple pathfinding instances: separate grids for different agent sizes

## Feature Gaps

1. **No NavMesh**: Only grid-based. Mesh-based navigation handles arbitrary geometry, is more memory-efficient for open spaces, and produces smoother paths. This is the #1 missing pathfinding feature for non-grid games.
2. **No dynamic obstacle avoidance**: Can update grid costs but no real-time local avoidance around moving obstacles. Need separate avoidance layer.
3. **No Theta*/any-angle**: A* produces grid-aligned paths. Theta* and related algorithms produce straight-line paths that cross cells diagonally at any angle.
4. **No path queries**: Can't ask "is position reachable from position?" without computing a full path.
5. **No bidirectional search**: Only forward A*. Bidirectional search can be faster for long paths.
6. **No Jump Point Search (JPS)**: Optimization of A* for uniform-cost grids — dramatically faster.
7. **No funnel algorithm**: HPA* needs funnel post-processing for clean diagonal paths through portal sequences.

## Structural Issues

- **Overlap with graph module**: Graph module has directed graphs with pathfinding potential (shortest path via BFS/DFS). Pathfinding has NavGrid. Both do graph traversal but for different use cases. Consider merging graph traversal into pathfinding or clearly documenting the split.
- **No tilemap integration**: Tilemap has grid data, pathfinding has NavGrid. Converting between them is manual. Should be seamless.
- **No AI integration**: AI steering needs pathfinding results but there's no direct bridge.

## Suggestions

1. **Add tilemap → NavGrid bridge**: `lurek.pathfinding.fromTilemap(tilemap, walkableCallback)` — auto-generate NavGrid from tilemap.
2. **Add JPS**: Jump Point Search for uniform grids — much faster than A* with no quality loss.
3. **Add reachability query**: `navGrid:isReachable(x1, y1, x2, y2)` — boolean check without full path.
4. **Add Theta* or any-angle**: `navGrid:findPathSmooth(x1, y1, x2, y2)` — produce any-angle paths.
5. **Add NavMesh** (future): For non-grid games. This is a large feature but high value.
6. **Bridge with AI steering**: `steeringAgent:followPath(path)` — steering module consumes pathfinding output directly.

## Competitor Comparison

| Feature | Lurek2D | Engine A | Engine B | Engine D |
|---|---|---|---|---|
| Grid pathfinding | ✅ | ❌ (libs) | ❌ | ❌ |
| A* | ✅ | ❌ | ❌ | ❌ |
| HPA* | ✅ | ❌ | ❌ | ❌ |
| Flow fields | ✅ | ❌ | ❌ | ❌ |
| NavMesh | ❌ | ❌ | ❌ | ✅ (navmesh crate) |
| JPS | ❌ | ❌ | ❌ | ❌ |
| Dynamic costs | ✅ | N/A | N/A | N/A |

Lurek2D has the strongest built-in pathfinding of any 2D Lua engine. HPA* and flow fields are rare features.

## Priority

**MEDIUM** — Tilemap bridge and JPS are the most impactful. NavMesh is a longer-term project.
