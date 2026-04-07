# Cardgame, Item Loot Tables — Weighted Random Optimization

## Modules Covered
- `src/cardgame/` — card pools, deck building, stacks
- `src/item/` — item definitions, loot tables, weighted pools

---

## The Core Problem: O(n) Weighted Random Selection

Both `cardgame/pool.rs` and `item/pool.rs` use the same algorithm:

```rust
// Current: O(n) per draw
let total: u64 = pool.iter().map(|e| e.weight as u64).sum();
let mut rng_val = rng.gen_range(0..total);
for entry in &pool {
    if rng_val < entry.weight as u64 { return &entry.item; }
    rng_val -= entry.weight as u64;
}
```

For a pool of 500 cards: **500 operations per draw**. A gacha system drawing
10 cards per second performs **5,000 weight accumulations per second**.

---

## Fix 1: Precomputed Cumulative Weight Array (O(log n) per draw)

Build the CDF once at pool creation, then binary-search on each draw:

```rust
// src/item/pool.rs
pub struct WeightedPool<T> {
    entries: Vec<T>,
    cumulative: Vec<u64>,   // precomputed prefix sum
    total: u64,
}

impl<T> WeightedPool<T> {
    pub fn build(entries: Vec<(T, u32)>) -> Self {
        let mut cumulative = Vec::with_capacity(entries.len());
        let mut running = 0u64;
        for (_, w) in &entries {
            running += *w as u64;
            cumulative.push(running);
        }
        let total = running;
        Self { entries: entries.into_iter().map(|(e,_)| e).collect(), cumulative, total }
    }

    pub fn draw(&self, rng_val: u64) -> &T {
        let val = rng_val % self.total;
        // Binary search instead of linear scan
        let idx = self.cumulative.partition_point(|&c| c <= val);
        &self.entries[idx]
    }
}
```

**Performance**: Draw goes from O(n) → **O(log n)**.
For 500-entry pool: 500 ops → **9 ops per draw** (56× speedup).

---

## Fix 2: Parallel Prefix Sum for Large Pools

If loot tables are rebuilt at runtime (e.g., player buffs modify item rarities),
the O(n) prefix sum construction can be parallelized with rayon:

```rust
// src/item/pool.rs — parallel prefix sum setup
use rayon::prelude::*;

fn build_cumulative(weights: &[u32]) -> Vec<u64> {
    if weights.len() < 10_000 {
        // Serial: overhead not worth it for small pools
        weights.iter().scan(0u64, |acc, &w| { *acc += w as u64; Some(*acc) }).collect()
    } else {
        // Parallel up-sweep/down-sweep prefix sum
        // Use rayon's prefix scan (no built-in yet, but achievable with segments)
        // Divide into P segments, compute segment sums in parallel, add offsets
        todo!("parallel prefix sum")
    }
}
```

---

## cardgame/ — Deck Shuffling

**Current**: Fisher-Yates shuffle is inherently sequential (O(n) single-threaded).

**Alternative for large decks (500+ cards)**:
- Sort-based shuffle: assign each card a random `f32` key, then
  `par_sort_unstable_by` to sort by key — O(n log n) but parallelized
- Faster in practice for very large decks where rayon overhead is justified

```rust
// src/cardgame/stack.rs
pub fn shuffle_parallel(deck: &mut Vec<CardId>) {
    if deck.len() < 1000 {
        // Use standard Fisher-Yates for small decks
        fisher_yates_shuffle(deck);
    } else {
        use rayon::prelude::*;
        let mut keyed: Vec<(f32, CardId)> = deck.par_iter()
            .map(|&c| (rand::random::<f32>(), c))
            .collect();
        keyed.par_sort_unstable_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
        *deck = keyed.into_iter().map(|(_, c)| c).collect();
    }
}
```

---

## SIMD: Cumulative Weight Vectorization

For rebuilding large loot tables with SIMD prefix sum (using `std::simd`):

```rust
// Sequential prefix sum
let mut acc = 0u64;
for (i, w) in weights.iter().enumerate() {
    acc += *w as u64;
    cumulative[i] = acc;
}

// Potential SIMD: process 4 weights at once (partial vectorization)
// Full SIMD prefix sum requires warp-style prefix algorithms
// Worth implementing only for pools 10k+ entries
```

---

## Priority

| Fix | LOC | Speedup | Modules Affected |
|-----|-----|---------|-----------------|
| Precomputed prefix sum | ~30 | 56× per draw | `item/pool.rs`, `cardgame/pool.rs` |
| Parallel deck shuffle | ~15 | 4× for 1k+ decks | `cardgame/stack.rs` |
| Parallel pool rebuild | ~50 | 4× for 10k+ pools | Both |
