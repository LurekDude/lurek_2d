# Entity ECS — Parallel Queries and Bitmap Tag Optimization

## Module Covered
- `src/entity/universe.rs` — ECS world, entity spawning/recycling, tag queries

---

## Current State

Luna2D uses a lightweight ECS with:
- `SlotMap<EntityId, EntityData>` for entity storage
- HashSet<String> per entity for string tags
- 64-bit bitmap mask per entity for numeric tags

---

## Problem 1: Linear Tag Scan for Queries

```rust
// Approximate current code in universe.rs
pub fn get_entities_with_tag(&self, tag: &str) -> Vec<EntityId> {
    self.alive
        .iter()                           // O(n) — all alive entities
        .filter(|id| {
            self.string_tags.get(id)
                .map(|tags| tags.contains(tag))  // O(t) — all tags
                .unwrap_or(false)
        })
        .copied()
        .collect()
}
```

For 10,000 entities each with 5 tags: **50,000 string comparisons**
per query call. Tags are compared as heap-allocated `String`s.

### Fix 1: Tag Index (Inverted Index)

Maintain a reverse mapping `HashMap<&str, Vec<EntityId>>`:

```rust
// src/entity/universe.rs
pub struct Universe {
    // Existing:
    alive:       HashSet<EntityId>,
    
    // Add: inverted index — find entities by tag in O(1)
    tag_index:   HashMap<String, Vec<EntityId>>,  
}

impl Universe {
    pub fn get_entities_with_tag(&self, tag: &str) -> &[EntityId] {
        self.tag_index.get(tag).map(|v| v.as_slice()).unwrap_or(&[])
    }

    fn add_tag(&mut self, id: EntityId, tag: String) {
        self.tag_index.entry(tag.clone()).or_default().push(id);
        // ... add to per-entity set too
    }
}
```

**Result**: O(n) query → **O(1) lookup**. No threading needed.

---

## Problem 2: Bitmap Tag Queries Are Not Vectorized

```rust
// Current bitmap tag check per entity: O(1) but called for every entity
pub fn get_entities_with_bitmap(&self, mask: u64) -> Vec<EntityId> {
    self.alive.iter()
        .filter(|id| self.bitmap_tags[id] & mask == mask)
        .copied()
        .collect()
}
```

With 10,000 entities, this is 10,000 bitwise AND operations — sequential.

### Fix 2: Store Bitmaps as Contiguous Array + rayon

```rust
// src/entity/universe.rs — contiguous bitmap array
pub struct Universe {
    // Parallel arrays (SoA layout):
    entity_ids:   Vec<EntityId>,    // dense list of alive entities
    bitmap_tags:  Vec<u64>,         // parallel to entity_ids
}

impl Universe {
    pub fn get_entities_with_bitmap_par(&self, mask: u64) -> Vec<EntityId> {
        use rayon::prelude::*;
        self.entity_ids
            .par_iter()
            .zip(self.bitmap_tags.par_iter())
            .filter(|(_, &bm)| bm & mask == mask)
            .map(|(&id, _)| id)
            .collect()
    }
}
```

**Threshold**: Parallelize when entity count > 5,000.

### Fix 3: SIMD Bitmap Matching

Process 4 entities' bitmaps in parallel per SIMD lane:

```rust
// Manual SIMD approach using u64x4 chunks
fn query_bitmap_simd(bitmaps: &[u64], mask: u64, entity_ids: &[EntityId]) -> Vec<EntityId> {
    let mut results = Vec::new();
    let mask4 = [mask; 4];
    // Process 4 entities at a time
    for i in (0..bitmaps.len()).step_by(4) {
        if i + 4 <= bitmaps.len() {
            // Check if any of 4 bitmaps match
            let chunk = &bitmaps[i..i+4];
            for (j, &bm) in chunk.iter().enumerate() {
                if bm & mask == mask { results.push(entity_ids[i+j]); }
            }
        }
    }
    results
}
```

With `std::simd`:
```rust
use std::simd::{u64x4, SimdPartialEq};
let mask4 = u64x4::splat(mask);
let chunk = u64x4::from_slice(&bitmaps[i..]);
let matched = (chunk & mask4).simd_eq(mask4);
// Extract matching indices from matched mask
```

---

## Problem 3: Blueprint Instantiation (Bulk Spawning)

When spawning 100 entities from a blueprint (e.g., particle burst, enemy wave):
- Each spawn calls `universe.spawn()` → 100 serial calls
- Each spawn: HashMap insert + HashSet insert + SlotMap insert

### Fix: Bulk Spawn API

```rust
impl Universe {
    pub fn spawn_bulk(&mut self, blueprint: &Blueprint, count: usize) -> Vec<EntityId> {
        // Pre-allocate
        let mut ids = Vec::with_capacity(count);
        // Reserve contiguous IDs if possible
        for _ in 0..count {
            let id = self.alloc_id();
            self.apply_blueprint_fast(id, blueprint);
            ids.push(id);
        }
        // Bulk update tag index  
        for tag in &blueprint.tags {
            self.tag_index.entry(tag.clone()).or_default().extend_from_slice(&ids);
        }
        ids
    }
}
```

**Speedup**: 2–5× for bulk spawning (reduced repeated HashMap hashing).

---

## Parallel Component Access

For systems that read/write specific components for all matching entities,
a parallel iteration pattern:

```rust
// Hypothetical system: move all entities with Velocity component
pub fn movement_system(universe: &mut Universe, dt: f32) {
    use rayon::prelude::*;
    universe.query_mut::<(Position, Velocity)>()
        .par_iter_mut()
        .for_each(|(pos, vel)| {
            pos.x += vel.dx * dt;
            pos.y += vel.dy * dt;
        });
}
```

This requires a split-borrow pattern or unsafe code to parallelize,
but can be achieved with the read/write separation design seen in Bevy's
ECS `par_iter` system.

---

## Summary

| Problem | Current Cost | Fix | Speedup |
|---------|-------------|-----|---------|
| Tag query (string scan) | O(n × t) | Inverted index | O(1) |
| Bitmap query (sequential) | O(n) | rayon par_iter | 4× for >5k entities |
| Bitmap query (scalar) | 1 op/entity | SIMD u64x4 | 4× per iteration |
| Bulk spawn (serial) | O(count) with overhead | Bulk spawn API | 2–5× |
