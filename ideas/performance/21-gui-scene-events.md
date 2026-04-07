# GUI, Scene Depth Sort, and Event Dispatch

## Modules Covered
- `src/gui/` — widget tree, layout, hit testing
- `src/scene/depth_sorter.rs` — depth sorting for draw entries
- `src/event/` — signal pub-sub, event queue

---

## GUI Module

### Layout Pass Performance

GUI layout (measure + arrange all widgets) traverses the widget tree once per
frame (or when layout is dirty). For complex menus with 200+ widgets:

**Nested layout walk** (bottom-up measure, top-down arrange):
- Measure pass: O(w) — each widget measures its children first
- Arrange pass: O(w) — positions set top-down

With deeply nested containers (10 levels × 20 children each = 200 widgets),
this is ~400 operations per frame.

**Fix 1: Dirty layout flag** (highest ROI, algorithmic)
```rust
// src/gui/context.rs
pub struct GuiContext {
    layout_dirty: bool,
    cached_layout: HashMap<WidgetId, Rect>,
}

impl GuiContext {
    pub fn get_layout(&mut self) -> &HashMap<WidgetId, Rect> {
        if self.layout_dirty {
            self.relayout();
            self.layout_dirty = false;
        }
        &self.cached_layout
    }
    
    pub fn set_text(&mut self, id: WidgetId, text: String) {
        self.widgets[id].text = text;
        self.layout_dirty = true;  // mark dirty only when content changes
    }
}
```

A static HUD redraws without relayout — 0 layout work per frame. Layout runs
only when widgets change.

**Fix 2: Parallel independent subtree layout**
```rust
// Top-level panels are independent of each other
use rayon::prelude::*;

fn layout_top_panels(panels: &mut [Panel]) {
    panels.par_iter_mut().for_each(|panel| panel.relayout());
}
```

---

### Hit Testing Optimization

Hit testing on click/hover: traverse all widgets, find frontmost match.

**Current**: Linear scan O(w) — check every widget's bounds.

**Optimization**: Spatial acceleration for large widget counts:
```rust
// Build sorted list by depth (front-to-back) once per layout change
// Early exit: first match at cursor is the result
pub fn hit_test(&self, x: f32, y: f32) -> Option<WidgetId> {
    // Already sorted front-to-back (highest depth index first)
    self.sorted_by_depth.iter().find(|&&id| {
        let rect = &self.cached_layout[&id];
        rect.contains(x, y)
    }).copied()
}
```

**SIMD batch hit test**: Test 4 widget AABBs against cursor in parallel:
```rust
// Check 4 AABBs at once: (px >= left) && (px <= right) && (py >= top) && (py <= bottom)
// With f32x4: process 4 left bounds, 4 right bounds, etc.
```

Practical only for 1000+ widget UIs (level editors, debug panels).

---

## Scene Depth Sorting

### Current State

```rust
// src/scene/depth_sorter.rs
pub fn sort(&mut self) {
    self.entries.sort_by(|a, b| a.depth.partial_cmp(&b.depth).unwrap_or(Equal));
}
```

Standard Rust sort is **unstable introsort** — O(n log n) average, well-optimized.
For 1000 draw entries: ~10,000 comparisons ≈ 10–50μs.

### When to Use rayon Parallel Sort

```rust
use rayon::prelude::*;
// Only beneficial for n > 10,000 entries
if self.entries.len() > 10_000 {
    self.entries.par_sort_by(|a, b| a.depth.partial_cmp(&b.depth).unwrap_or(Equal));
}
```

**Realistic scenario**: A tile-based strategy game with 100×100 tile map
where each tile is a draw entry = 10,000 entries. Parallel sort: ~2× speedup.

**Better approach**: If depth values are integers or discretized floats,
use **counting sort / radix sort** — O(n), no comparison:

```rust
// src/scene/depth_sorter.rs — radix sort for integer depths
pub fn sort_radix(&mut self) {
    // Convert float depths to sortable u32 (if in known range)
    // Then 2-pass LSD radix sort: O(n) instead of O(n log n)
    // For 10k entries: ~10× faster than comparison sort
}
```

---

## Event System

### Signal Dispatch

```rust
// src/event/signal.rs
pub fn emit<T>(&self, signal_id: SignalId, value: T) {
    if let Some(handlers) = self.handlers.get(&signal_id) {
        for handler in handlers {
            handler(value);         // O(h) serial dispatch
        }
    }
}
```

Handlers are closures — they capture mutable state making parallel dispatch
unsafe by default.

**Pattern for parallel-safe handlers**: If handlers are read-only (e.g., logging,
analytics, rendering updates that write to separate buffers):

```rust
// src/event/signal.rs — parallel read-only handler dispatch
pub fn emit_par<T: Sync>(&self, signal_id: SignalId, value: &T) {
    use rayon::prelude::*;
    if let Some(handlers) = self.par_handlers.get(&signal_id) {
        handlers.par_iter().for_each(|h| h(value));
    }
}
```

Introduce two handler lists: `serial_handlers` (safe, mutable captures)
and `par_handlers` (read-only, `Sync` captures).

---

### Event Queue Batch Processing

```rust
// src/event/mod.rs — current: process one at a time
pub fn poll(&mut self) -> Option<Event> {
    self.queue.pop_front()
}

// Improved: batch drain for bulk processing (no repeated lock)
pub fn drain_all(&mut self) -> impl Iterator<Item = Event> + '_ {
    self.queue.drain(..)  // or swap with empty queue
}
```

With multiple listeners polling the same queue, switching to a broadcast
channel (clone on drain) avoids duplicate processing.

---

## Combined Summary

| Module | Optimization | Effort | Impact |
|--------|-------------|--------|--------|
| GUI | Dirty layout flag | 2 days | ~0ns for static frames |
| GUI | Parallel top-panel layout | 2 days | 4× for >5 top-level panels |
| GUI | Front-to-back sorted hit test | 1 day | Early exit on first match |
| Scene | Radix sort for integer depths | 3 days | 10× vs comparison sort |
| Scene | Parallel sort (>10k entries) | 1 day | 2× for large depth lists |
| Event | Par handlers list | 2 days | 4× for read-only handlers |
| Event | Batch drain API | 1 day | Reduces polling overhead |
