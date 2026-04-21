# `roguelike` — Agent Reference (Lunasome)

| Property       | Value                                                                                                                                   |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 — Lunasome (pure Lua)                                                                                                            |
| **Source**     | `library/roguelike/init.lua`                                                                                                            |
| **Lua Tests**  | `tests/lua/library/test_library_roguelike.lua`                                                                                          |
| **Depends on** | `lurek.tilemap` (optional, via `:attachTilemap`), `lurek.pathfind` (optional Dijkstra backend), `lurek.math.bresenham` (re-exported) |
| **Status**     | full                                                                                                                                    |

## Purpose

Symmetric-shadowcasting FOV, energy-based action scheduler, and Dijkstra
distance-field goal maps — the runtime queries that turn `lurek.tilemap`
into a real roguelike. Each subsystem is independent.

## Public API

### `Fov`
- `M.newFov(opts?)` — `{algorithm="shadowcast", range=8, light_walls=true}`
- `fov:setBlocker(fn)` / `fov:attachTilemap(tilemap, layer?, blocker_ids?)`
- `fov:compute(ox, oy)`
- `fov:isVisible(x, y)` / `fov:isExplored(x, y)` / `fov:resetExplored()`
- `fov:eachVisible(fn)` / `fov:visibleCells()` / `fov:export()`

### `Scheduler` (energy / speed)
- `M.newScheduler()`
- `sch:add(actor, speed)` / `sch:remove(actor)` / `sch:setSpeed(actor, speed)`
- `sch:next() -> actor, ticks_advanced`
- `sch:peek() -> actor, ticks_until`
- `sch:tick(n?) -> {actors}`
- `sch:reset()` / `sch:save()` / `sch:restore(blob)`

### `GoalMap` (Dijkstra distance field)
- `M.newGoalMap(width, height)`
- `goal:setBlocker(fn)` / `goal:attachTilemap(tilemap, layer?, blocker_ids?)`
- `goal:setSources({{x,y,weight}, ...})` / `goal:addSource` / `goal:clearSources`
- `goal:bake()`
- `goal:gradientAt(x, y) -> dx, dy`
- `goal:flee(x, y, fear?) -> dx, dy`
- `goal:distanceAt(x, y)`

### Module helpers
- `M.bresenham(x0, y0, x1, y1)`
- `M.lineOfSight(fov, x0, y0, x1, y1)`

## Dependencies

- **`lurek.tilemap`** — `:attachTilemap` consumes the user's tilemap. The
  binding is duck-typed: any object with `:getTile(layer, x, y)` works, as
  do plain `tilemap[layer][y][x]` Lua tables.
- **`lurek.pathfind`** — `GoalMap:bake` prefers `lurek.pathfind.dijkstra`
  when it exists; otherwise falls back to an in-Lua BFS.
- **`lurek.math.bresenham`** — preferred backend for `M.bresenham`; same
  fallback strategy.

## Status

`full` — recursive shadowcasting FOV, energy scheduler, BFS-fallback Dijkstra
goal map, flee/gradient queries, and Bresenham line all implemented. Heap-based
priority queue for goal map is a future optimisation.

## Examples

See `content/library/roguelike/example.lua` for a small map with a player,
two monsters, and a goal-map-driven hunt loop.

## Notes

- **FOV is symmetric**: `Fov:isVisible(a,b)` ↔ `Fov:isVisible(b,a)` for the
  same origin (within recursive-shadowcasting precision).
- **Scheduler is action-cost based**, not Δt: actors accumulate energy at
  `speed` per tick; the actor with the highest energy >= 100 acts and
  forfeits 100 energy. This is fundamentally different from
  `lurek.timer.Scheduler` (real-time `:every(seconds)`).
- **GoalMap fallback** uses 4-neighbour BFS — fine for square maps up to ~120²
  on LuaJIT. For larger maps, install `lurek.pathfind.dijkstra`.
- Use `Fov:resetExplored()` between levels; `_explored` accumulates across
  recomputes by design.
