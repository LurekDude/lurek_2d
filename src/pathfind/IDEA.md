# IDEA.md — `pathfind` module

> Migrated from `ideas/features/pathfinding.md` and `ideas/performance/05-ai-pathfinding.md` (Part 2).
> Status checked against `src/pathfind/` and `src/lua_api/pathfind_api.rs`.
> Lua namespace: `lurek.pathfind`.

---

## Features

### ❌ TODO — NavMesh
**Source**: features/pathfinding.md — Feature Gaps #1 (HIGH)

No NavMesh found. Grid pathfinding is excellent for tile-based games. For non-grid games
(car games, freely placed walls, procedural maps) a NavMesh gives smoother paths with
lower memory cost. This is the #1 missing pathfinding feature for non-tile games.

---

## Performance
