# Economy & Stats — Resource Simulation Parallelism

## Modules Covered
- `src/economy/` — resource flow, decay, interest, conversions
- `src/stats/` — character attributes, buffs, modifier accumulation

---

## Economy Module

### Current State

```rust
// Approximate src/economy/manager.rs
pub fn tick(&mut self, dt: f32) {
    // Serial: each resource ticked one at a time
    for resource in self.resources.values_mut() {
        resource.apply_decay(dt);
        resource.apply_interest(dt);
        resource.apply_modifiers(dt);
        resource.enforce_capacity();
    }
    // Serial: each conversion rule checked
    for rule in &self.conversions {
        self.try_convert(rule);
    }
}
```

With 30 resources and 50 modifiers each: **1,500 modifier applications per tick**.
With 20 conversion rules each checking 2–3 resource conditions: **40–60 checks**.

---

### Opportunity 1: Parallel Resource Ticks

Resource ticks are **independent per resource** — no cross-resource reads
during the tick phase (conversions are handled separately):

```rust
// src/economy/manager.rs
use rayon::prelude::*;

pub fn tick_parallel(&mut self, dt: f32) {
    // SAFE: resources are independent during tick
    self.resources.par_iter_mut().for_each(|(_, resource)| {
        resource.apply_decay(dt);
        resource.apply_interest(dt);
        resource.apply_modifiers(dt);
        resource.enforce_capacity();
    });
    
    // Serial: conversions may read/write multiple resources
    for rule in &self.conversions {
        self.try_convert(rule);
    }
}
```

**Threshold**: Worth it for >10 resources (typical: 15–40 in a city-builder).
**Speedup**: 4× on quad-core.

---

### Opportunity 2: SIMD Resource Value Array

If resource values are stored as a contiguous `f32` array (SoA layout),
batch-apply decay with SIMD:

```rust
// src/economy/manager.rs — SoA layout
pub struct EconomyManager {
    resource_values:  Vec<f32>,     // current value per resource
    resource_max:     Vec<f32>,     // capacity per resource  
    decay_rates:      Vec<f32>,     // per-resource decay
    interest_rates:   Vec<f32>,     // per-resource interest
    resource_names:   Vec<String>,  // for lookup
}

impl EconomyManager {
    pub fn tick_simd(&mut self, dt: f32) {
        let dt4 = [dt; 4];  // or f32x4
        // Apply decay: value *= (1.0 - decay * dt)  — batch 4 at once
        for i in (0..self.resource_values.len()).step_by(4) {
            let end = (i + 4).min(self.resource_values.len());
            for j in i..end {
                self.resource_values[j] *= 1.0 - self.decay_rates[j] * dt;
                self.resource_values[j] += self.resource_values[j] * self.interest_rates[j] * dt;
                self.resource_values[j] = self.resource_values[j].min(self.resource_max[j]);
            }
        }
    }
}
```

With `std::simd`:
```rust
use std::simd::f32x4;
let dt4 = f32x4::splat(dt);
let vals = f32x4::from_slice(&self.resource_values[i..]);
let decay = f32x4::from_slice(&self.decay_rates[i..]);
let result = vals * (f32x4::splat(1.0) - decay * dt4);
result.copy_to_slice(&mut self.resource_values[i..]);
```

---

### Opportunity 3: Conversion Rule Dependency Graph

Conversion rules that share no resources can be evaluated in parallel:
```
Rule A: wood + stone → castle (reads/writes wood, stone, castle)
Rule B: gold + cloth → coin   (reads/writes gold, cloth, coin)
Rule C: grain + water → beer  (reads/writes grain, water, beer)
```
Rules A, B, C are independent → process in parallel.

```rust
// Build conflict sets at load time
let conflict_graph = build_conversion_conflicts(&self.conversions);
let independent_groups = topological_groups(&conflict_graph);

// Process each group in parallel
for group in &independent_groups {
    group.par_iter().for_each(|rule_id| {
        // Apply conversion (can't conflict with others in same group)
    });
}
```

---

## Stats Module

### Current State

```rust
// Approximate src/stats/sheet.rs
pub fn get(&self, name: &str) -> f64 {
    let base = self.attributes.get(name).copied().unwrap_or(0.0);
    // Loop all buffs, accumulate
    let (additive, multiplicative) = self.buffs.iter()
        .filter(|b| b.attribute == name)  // O(b) string compare per buff
        .fold((0.0f64, 1.0f64), |(add, mul), b| {
            (add + b.additive, mul * b.multiplicative)
        });
    (base + additive) * multiplicative
}
```

For a character querying `attack` with 30 active buffs: 30 string comparisons
plus 30 fold operations. Called for every stat on every damage calculation.

---

### Fix 1: Pre-Computed Effective Stats Cache

Cache computed stats, invalidate on buff change:

```rust
pub struct StatSheet {
    base:      HashMap<String, f64>,
    buffs:     Vec<Buff>,
    cache:     HashMap<String, f64>,  // cached effective values
    dirty:     bool,                   // invalidation flag
}

impl StatSheet {
    pub fn get(&mut self, name: &str) -> f64 {
        if self.dirty { self.recompute_all(); }
        *self.cache.get(name).unwrap_or(&0.0)
    }

    fn recompute_all(&mut self) {
        // Called once when buffs change, not on every get()
        self.cache.clear();
        for (attr, &base) in &self.base {
            let (add, mul) = self.buffs.iter()
                .filter(|b| &b.attribute == attr)
                .fold((0.0, 1.0), |(a, m), b| (a + b.additive, m * b.multiplicative));
            self.cache.insert(attr.clone(), (base + add) * mul);
        }
        self.dirty = false;
    }
}
```

**Result**: `get()` is O(1) — no buff accumulation at query time.
`recompute_all()` is O(attrs × buffs) but called **once per buff change**
instead of once per query.

---

### Fix 2: Parallel Multi-Character Stat Recompute

In an RPG with 50 characters, recomputing all stats after a boss uses AOE:

```rust
pub fn recompute_all_characters(characters: &mut Vec<Character>) {
    use rayon::prelude::*;
    characters.par_iter_mut().for_each(|c| {
        if c.stats.dirty { c.stats.recompute_all(); }
    });
}
```

**Speedup**: 4× for 50 characters. Each character's stats are independent.

---

### Fix 3: SIMD Buff Accumulation

```rust
// If buff values stored as SoA: Vec<f64> for additive, Vec<f64> for multiplicative
fn accumulate_buffs_simd(additive: &[f64], multiplicative: &[f64]) -> (f64, f64) {
    // Sum all additive values, multiply all multiplicative values
    use std::simd::{f64x4, num::SimdFloat};
    let add_sum = additive.chunks_exact(4)
        .map(f64x4::from_slice)
        .fold(f64x4::splat(0.0), |acc, v| acc + v)
        .reduce_sum();
    
    let mul_product = multiplicative.chunks_exact(4)
        .map(f64x4::from_slice)
        .fold(f64x4::splat(1.0), |acc, v| acc * v)
        .reduce_product();
    
    (add_sum, mul_product)
}
```

---

## Combined Summary

| Module | Fix | Effort | Speedup | When |
|--------|-----|--------|---------|------|
| Economy tick | rayon par_iter_mut | 1 day | 4× | >10 resources |
| Economy values | SIMD f32x4 batch decay | 2 days | 2–4× | >8 resources |
| Economy conversions | Parallel independent groups | 3 days | 2× | >10 rules |
| Stats get() | Cache + dirty flag | 1 day | 100× per query | Always |
| Stats recompute | rayon par_iter (multi-char) | 1 day | 4× | >10 characters |
| Stats accumulate | SIMD f64x4 sum | 2 days | 2–4× | >16 buffs |
