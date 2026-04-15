# IDEA.md — `procgen` module

> Migrated from `ideas/features/procgen.md`.
> Status checked against `src/procgen/` and `src/lua_api/procgen_api.rs`.
> Lua namespace: `lurek.procgen`.

---

## Features

### ✅ DONE — Cellular Automata (Cave Generation)
**Source**: features/procgen.md — Feature Gaps #7 (see also tilemap duplication)

`lurek.procgen.cellular(w, h, opts)` implemented. Generates binary cave maps.

> ⚠️ **DUPLICATION**: Also implemented inside the `tilemap` module. Keep `procgen` as the
> canonical implementation; `tilemap` should call `lurek.procgen.cellular()`. Remove the
> tilemap copy.

---

### ✅ DONE — Perlin Noise (Tileable)
**Source**: features/procgen.md — Summary

`lurek.procgen.perlin(w, h, sx, sy, ox, oy, px, py, seed)` — tileable and seeded.

---

### ✅ DONE — Poisson-Disk Sampling
**Source**: features/procgen.md — Summary

`lurek.procgen.poissonDisk(w, h, minDist, maxAttempts, seed)` — even point distribution.

---

### ✅ DONE — Voronoi Diagram
**Source**: features/procgen.md — Summary

`lurek.procgen.voronoi(w, h, pts, opts)` — Voronoi tessellation with optional warp.

> ⚠️ **PERFORMANCE**: Brute-force O(cells × seeds). Add warning in docs for >1000 seeds.

---

### ✅ DONE — Flood Fill
**Source**: features/procgen.md — Summary

`lurek.procgen.floodFill(grid, startX, startY, fill, match, w)` — 4-connected region fill.

---

### ✅ DONE — BSP Dungeon Generation
**Source**: features/procgen.md — Feature Gaps #1

`lurek.procgen.bspDungeon(w, h, opts?)` implemented in `procgen_api.rs`. Returns `{map, rooms, connections}`.

---

### ✅ DONE — Room-and-Corridor Dungeon
**Source**: features/procgen.md — Feature Gaps #4 / Suggestions #2

`lurek.procgen.roomsDungeon(w, h, opts?)` implemented in `procgen_api.rs` + `rooms.rs`.

---

### ✅ DONE — Wave Function Collapse (WFC)
**Source**: features/procgen.md — Feature Gaps #2 / Suggestions #3

`lurek.procgen.wfc(width, height, opts)` implemented in `procgen_api.rs` + `wfc.rs`.

---

### ✅ DONE — L-Systems
**Source**: features/procgen.md — Feature Gaps #3 / Suggestions #4

`lurek.procgen.lsystem(axiom, rules, iterations)` implemented in `procgen_api.rs` + `lsystem.rs`.

---

### ✅ DONE — Name Generation
**Source**: features/procgen.md — Feature Gaps #5 / Suggestions #5

`lurek.procgen.nameGen(config)` implemented in `procgen_api.rs` + `namegen.rs`.

---

### ✅ DONE — Room Graph (Topology First)
**Source**: features/procgen.md — Feature Gaps #7 / Suggestions #7

`lurek.procgen.worldGraph(opts)` implemented in `procgen_api.rs` + `graph.rs`.

---

### ✅ DONE — Remove `log_messages` Dependency
**Source**: features/procgen.md — Structural Issues

Fixed: `src/procgen/` no longer imports non-Foundation helpers. Uses `log::debug!` only.
