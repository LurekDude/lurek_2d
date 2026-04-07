# Battle & Combat — Threading and GPU Opportunities

## Modules Covered
- `src/battle/` — turn-based combat engine
- `src/combat/` — vehicle combat, turrets, projectiles

---

## battle/ — Turn-Based Combat Engine

### Key Files
- `src/battle/lifecycle.rs` — turn order, resolution
- `src/battle/combatant.rs` — combatant state, stats
- `src/battle/action.rs` — action execution

### Current Bottleneck

**Turn order sort** (`sort_by()` descending by speed) is called every time
a combatant's speed changes — O(n log n) where n = combatants.

**Combatant lookup by name** uses linear `.find()` — O(n) per lookup. With
30+ combatants and multiple lookups per action, this compounds.

**Damage modifier accumulation**: for each hit, loop all active buffs/debuffs
on the target and sum additive + multiplicative modifiers — O(b × modifiers).

### Threading Opportunity

**Parallel modifier accumulation (rayon)**
```rust
// Before: serial sum
let total = combatant.buffs.iter().map(|b| b.damage_add).sum::<f64>();

// After: parallel sum
use rayon::prelude::*;
let total = combatant.buffs.par_iter().map(|b| b.damage_add).sum::<f64>();
// Threshold: only worth it for 20+ buffs
```

**Multi-agent simulation**: if simulating multiple simultaneous battles
(e.g., background auto-battle for idle game), each `BattleInstance` is
fully independent → wrap in `Arc<Mutex<BattleInstance>>`, step all via
`rayon::scope`.

### SIMD Opportunity

If damage types are stored as parallel arrays (physical, fire, ice, lightning),
batch-accumulate 4 types per SIMD lane for one combatant, or 4 combatants'
single-type damage in parallel.

### Algorithmic Fix (Higher ROI than Parallelism)

Replace linear name lookup with a `HashMap<&str, CombatantId>` index built
once at battle start. This eliminates the O(n) scan entirely — zero threading
needed, pure algorithmic improvement.

---

## combat/ — Vehicle Combat (Projectiles)

### Key Files
- `src/combat/projectile.rs` — projectile state, update
- `src/combat/world.rs` — world state, collision dispatch
- `src/combat/weapon.rs` — turret, fire rates

### Current Bottleneck

**Projectile update loop**: each frame, move all projectiles by
`pos += vel * dt`, then test against all entities for collision.
Without spatial partitioning this is O(p × e) where:
- p = 50–200 projectiles
- e = 20–100 entities

At 200 projectiles × 100 entities = **20,000 collision tests per frame**.

### Threading Opportunity: rayon Parallel Projectile Update

```rust
// src/combat/projectile.rs
use rayon::prelude::*;

pub fn step_all(projectiles: &mut Vec<Projectile>, dt: f32, entities: &[EntityBounds]) {
    let hits: Vec<(usize, usize)> = projectiles
        .par_iter_mut()
        .enumerate()
        .flat_map(|(pi, proj)| {
            proj.pos += proj.vel * dt;
            entities.iter().enumerate()
                .filter(|(_, e)| e.bounds.contains(proj.pos))
                .map(|(ei, _)| (pi, ei))
                .collect::<Vec<_>>()
        })
        .collect();
    // process hits serially after parallel detection
}
```

Expected speedup: 4× on quad-core for 100+ projectiles.

### GPU Opportunity: Compute Shader Projectile Simulation

For 500+ projectiles (e.g., bullet-hell game), a compute shader processes
all position+velocity integration in parallel:

```wgsl
// projectile_sim.wgsl
@group(0) @binding(0) var<storage, read_write> positions: array<vec2<f32>>;
@group(0) @binding(1) var<storage, read> velocities: array<vec2<f32>>;
@group(0) @binding(2) var<uniform> dt: f32;

@compute @workgroup_size(64)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    positions[i] += velocities[i] * dt;
}
```

GPU can process 1M projectiles in ~1ms vs CPU's ~100ms.

### Spatial Hashing (Algorithmic Fix, Higher ROI)

Build a spatial hash grid on entities each frame (O(e)):
```rust
struct SpatialHash { cell_size: f32, cells: HashMap<(i32,i32), Vec<usize>> }
```
Projectile → hash its cell → check only neighboring cells. Reduces
O(p × e) to O(p × k) where k = 4–8 entities in same cell.
This alone provides 10–25× speedup before any threading.
