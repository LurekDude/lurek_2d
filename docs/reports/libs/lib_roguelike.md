# `library.roguelike`

Lurek2D roguelike library — FOV, energy scheduler, and goal maps.

Pure-Lua runtime queries that turn `lurek.tilemap` into a roguelike:

* `Fov`       — symmetric recursive-shadowcasting field of view.
* `Scheduler` — discrete energy/speed turn scheduler (not Δt-based).
* `GoalMap`   — multi-source Dijkstra distance field with flee inversion.

All three subsystems are independent — pick what you need.

*13 functions, 0 module fields documented.*

See: [`lurek.tilemap`](../lua-api.md#lurektilemap) — attach FOV/GoalMap blockers via `:attachTilemap`, [`lurek.pathfind`](../lua-api.md#lurekpathfinding) — preferred Dijkstra backend; in-Lua fallback used otherwise, [`lurek.math.bresenham`](../lua-api.md#lurekmathbresenham) — line-of-sight helper (re-exported as `M.bresenham`), [`lurek.save`](../lua-api.md#lureksavegame) — scheduler/FOV state collectors

## Functions

### `newFov(opts)`

Construct a new FOV instance. informational; only "shadowcast" is implemented.

**Parameters**

- `opts` *table?* — `{algorithm, range=8, light_walls=true}`. `algorithm` is

**Returns**

- *Fov*

### `setBlocker(fn)`

Set a custom blocker function.

### `attachTilemap(tilemap, layer, blocker_ids)`

Attach to a tilemap and treat the supplied tile ids as blockers on the given layer. `tilemap` is queried via `tilemap:getTile(layer, x, y)` if the method is present; otherwise via the table-indexed `tilemap[layer][y][x]`.

### `compute(ox, oy)`

Recompute visibility from `(ox, oy)`.

### `newScheduler()`

Create an action-cost (energy) scheduler. Each actor has a `speed` value; on each `:next()` call the actor with the highest accumulated energy goes. Internal clock advances by the minimum ticks needed to bring at least one actor's energy >= 100.

**Returns**

- *Scheduler*

### `next()`

Pop the next-to-act actor. Returns the actor and ticks advanced this call.

### `peek()`

Peek at the next actor without consuming a turn.

### `tick(n)`

Take `n` consecutive turns and return the actors in order.

### `newGoalMap(width, height)`

Construct a goal map of the given grid dimensions.

### `gradientAt(x, y)`

Unit step toward the nearest goal cell.

### `flee(x, y, fear)`

Unit step away from goals, scaled by `fear` (default 1.2).

### `bresenham(x0, y0, x1, y1)`

Bresenham line of grid points from (x0,y0) to (x1,y1). Falls back to a Lua implementation if `lurek.math.bresenham` is unavailable.

### `lineOfSight(fov, x0, y0, x1, y1)`

True if `fov` reports an unbroken line from (x0,y0) to (x1,y1) is visible.
