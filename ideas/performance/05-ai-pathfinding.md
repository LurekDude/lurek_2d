# AI & Pathfinding — Threading Opportunities

## Part 1: AI Module (src/ai/)

### Subsystem Overview

| Subsystem | File | CPU Model | Threading Today |
|-----------|------|-----------|-----------------|
| FSM | `fsm.rs` | O(transitions) per tick | Single-threaded |
| Behavior Tree | `behavior_tree.rs` | O(nodes) per tick | Single-threaded |
| Steering | `steering.rs` | O(neighbors) per agent | Single-threaded |
| GOAP | `goap.rs` | O(actions^depth) per plan | Single-threaded |
| Q-Learning | `qlearner.rs` | O(1) per update | Single-threaded |
| Influence Map | `influence_map.rs` | O(w × h × 9) per propagate | Single-threaded |
| Utility AI | `utility.rs` | O(actions × considerations) | Single-threaded |
| Squads | `squad.rs` | O(members) per update | Single-threaded |

### CPU-Intensive Operations (Ranked)

#### 1. GOAP Planning — A★ over action space

`src/ai/goap.rs` (line ~150+):
```rust
// A★ search with binary heap
// Each node = (state, cost, actions_taken)
// Expands all applicable actions at each state
// Heuristic: count of unsatisfied goals
```

**Cost**: O(branching_factor^max_depth) worst case
- 10 actions, depth 5 = up to 100,000 node expansions
- With `max_depth` limit (default ~10), practical cost is bounded

**Parallelization Opportunity**: ✅ HIGH
- Multiple agents plan independently → embarrassingly parallel
- Each agent's GOAP search has no shared mutable state

```rust
// Parallel multi-agent planning
use rayon::prelude::*;

let plans: Vec<Option<Plan>> = agents
    .par_iter()
    .map(|agent| {
        goap_planner.plan(&agent.world_state, &agent.goals, max_depth)
    })
    .collect();
```

**Alternative**: Use Lua worker threads via `lurek.thread.new()`:
```lua
-- Game-script level parallelism
for _, unit in ipairs(units) do
    unit.plan_thread = lurek.thread.new(function(state, goals)
        return goap.plan(state, goals, 10)
    end, unit.world_state, unit.goals)
end

-- Poll results in update
for _, unit in ipairs(units) do
    if unit.plan_thread:isDone() then
        unit.plan = unit.plan_thread:getResult()
    end
end
```

#### 2. Influence Map Propagation

`src/ai/influence_map.rs` (line ~180+):
```rust
// 3×3 neighborhood averaging (diffusion)
for y in 0..height {
    for x in 0..width {
        let mut sum = 0.0;
        let mut count = 0;
        for dy in -1..=1 {
            for dx in -1..=1 {
                // accumulate neighbors
            }
        }
        new_map[y][x] = sum / count as f32;
    }
}
```

**Cost**: O(width × height × 9) per propagation step
- 100×100 map = 90,000 operations
- 500×500 map = 2.25M operations

**Parallelization Opportunity**: ✅ HIGH
- Row-parallel: each row's output depends only on current row ±1
- Double-buffer pattern (read from old, write to new)

```rust
(0..height).into_par_iter().for_each(|y| {
    for x in 0..width {
        // Read from old_map, write to new_map
        new_map[y * width + x] = average_neighborhood(&old_map, x, y);
    }
});
std::mem::swap(&mut self.old_map, &mut self.new_map);
```

**GPU Compute Alternative**: Influence maps are essentially image processing
(blur/diffusion). A compute shader would handle 1000×1000 maps trivially.

#### 3. Steering — Flock Behavior

`src/ai/steering.rs` (line ~280+):
```rust
// For each agent, iterate ALL other agents for neighbor detection
for other in agents {
    let dist = (agent.pos - other.pos).length();
    if dist < neighbor_radius {
        // accumulate separation, alignment, cohesion
    }
}
```

**Cost**: O(n²) for n agents (brute-force neighbor search)
- 100 agents = 10,000 distance checks
- 500 agents = 250,000 distance checks

**Parallelization Opportunity**: ✅ MEDIUM
- Per-agent steering calculation is independent
- BUT: shared read access to all agent positions needed

```rust
let forces: Vec<Vec2> = agents
    .par_iter()
    .map(|agent| {
        compute_steering_force(agent, &all_positions, radius)
    })
    .collect();
```

**Better Optimization**: Spatial hashing reduces neighbor lookup from O(n²) to O(n):
```rust
struct SpatialHash {
    cells: HashMap<(i32, i32), Vec<usize>>,
    cell_size: f32,
}

fn query_neighbors(&self, pos: Vec2, radius: f32) -> Vec<usize> {
    // Only check cells within radius
    let min_cell = pos_to_cell(pos - radius);
    let max_cell = pos_to_cell(pos + radius);
    // ... iterate cells in range
}
```

This can be **combined** with rayon for O(n/cores) per frame.

#### 4. Utility AI — Multi-Agent Scoring

`src/ai/utility.rs`:
```rust
// For each action, evaluate all considerations
// Score = product of consideration curves
for action in &self.actions {
    let mut score = 1.0;
    for consideration in &action.considerations {
        score *= consideration.evaluate(context);
    }
}
```

**Cost**: O(actions × considerations) per agent
- Typically 5–20 actions, 2–5 considerations each = 10–100 evaluations
- With 100 agents: 1,000–10,000 evaluations total

**Parallelization**: ✅ LOW priority — too little work per agent to benefit

---

## Part 2: Pathfinding (src/pathfinding/)

### Current Threading: AsyncPool ✅

The pathfinding system already has a background thread pool:

```
src/pathfinding/async_pool.rs
├── PathThreadPool::new(thread_count) — spawns N worker threads
├── submit(grid, start, goal) — sends PathRequest via mpsc
├── poll() — non-blocking result retrieval
└── cancel(id) — marks request for cancellation
```

**Current Design**:
- Workers block on `Mutex<Receiver<PathRequest>>::recv()`
- Results sent via `Sender<(u64, Option<Vec<(u32,u32)>>)>`
- Cancellation via `Arc<Mutex<Vec<u64>>>` checked before/after compute

### Pathfinding Algorithms

| Algorithm | File | Complexity | Parallelizable? |
|-----------|------|------------|-----------------|
| A★ | `astar.rs` | O(V log V) | Per-query ✅ |
| HPA★ | `hpa.rs` | O(clusters + local A★) | Pre-processing ✅ |
| Flow Field | `flow_field.rs` | O(V) Dijkstra | Per-field ✅ |
| Unit Pathfinder | `unit_pathfinder.rs` | Coordination layer | Depends |

### Opportunity 1: Increase AsyncPool Default Thread Count

Currently the pool size is set at creation. Defaulting to `num_cpus / 2`
would automatically scale with hardware:

```rust
pub fn new_auto() -> Self {
    let threads = (num_cpus::get() / 2).max(1).min(8);
    Self::new(threads)
}
```

### Opportunity 2: HPA★ Pre-Processing on Background Thread

HPA★ builds a hierarchy of clusters and inter-cluster edges. This
preprocessing step is O(clusters × edges) and can be done on a background
thread at map load time:

```rust
pub fn preprocess_async(grid: &NavGrid) -> JoinHandle<HpaGraph> {
    let grid_clone = grid.clone();
    thread::spawn(move || {
        HpaGraph::build(&grid_clone)  // Expensive
    })
}
```

The game can use standard A★ while HPA★ preprocessing completes.

### Opportunity 3: Flow Field Parallelism

Flow fields compute a direction vector for every cell. The Dijkstra
propagation is serial, but the final direction computation (gradient of
cost field) is parallelizable:

```rust
// Parallel direction computation from cost field
(0..height).into_par_iter().for_each(|y| {
    for x in 0..width {
        directions[y * width + x] = compute_gradient(&cost_field, x, y);
    }
});
```

### Opportunity 4: Pathfinding Cache

Many games request the same path repeatedly (e.g., multiple units going to
the same destination). An LRU cache keyed on `(start, goal, grid_hash)`
eliminates redundant A★ computation:

```rust
struct PathCache {
    cache: LruCache<(Pos, Pos, u64), Vec<Pos>>,  // grid_hash for invalidation
}
```

**Impact**: For RTS-style games with 50+ units, cache hit rates of 60–80%
are common, effectively 2–5× throughput improvement with zero threading.

---

## Part 3: Combined AI + Pathfinding Strategy

### Real-Time Strategy Pattern

For RTS games combining AI decisions + pathfinding:

```
Frame N:
  Main Thread:
    ├─ lua.update(dt)
    │   ├─ Poll AI planning results from background
    │   ├─ Poll pathfinding results from AsyncPool
    │   ├─ Submit new AI planning requests
    │   └─ Submit new pathfinding requests
    └─ lua.draw()

  AI Worker Thread(s):
    └─ Process GOAP/UtilityAI planning requests

  Path Worker Thread(s):
    └─ Process A★/FlowField requests (already implemented)

  Influence Map Thread:
    └─ Propagate influence maps each frame (double-buffered)
```

### Thread Budget

On a 4-core CPU (target: integrated GPU laptop from 2018):
- Core 0: Main thread (Lua + rendering)
- Core 1: Physics (if rapier `parallel` enabled, uses rayon)
- Core 2: Pathfinding worker
- Core 3: AI planning worker

On 8-core modern CPU:
- Cores 0–1: Main thread + rendering
- Cores 2–3: Physics (rayon)
- Cores 4–5: Pathfinding workers
- Cores 6–7: AI workers + influence map

---

## Summary

| Opportunity | Module | Effort | Impact | Priority |
|-------------|--------|--------|--------|----------|
| Parallel multi-agent GOAP | AI | Medium | HIGH (multi-unit games) | **P1** |
| Parallel influence map | AI | Low | HIGH (large maps) | **P1** |
| Spatial hash for steering | AI | Medium | HIGH (100+ agents) | **P1** |
| Pathfinding cache (LRU) | Pathfinding | Low | HIGH (many units) | **P1** |
| Auto-scale AsyncPool threads | Pathfinding | Low | Medium | **P2** |
| HPA★ async preprocessing | Pathfinding | Medium | Medium | **P2** |
| Flow field parallel gradient | Pathfinding | Low | Low | **P3** |
| Lua-level thread planning | AI | N/A (game code) | Variable | **P3** |
| Parallel utility AI scoring | AI | Low | Low (small work) | **P4** |
