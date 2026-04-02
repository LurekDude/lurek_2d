//! Event bus for province map lifecycle events.
//!
//! Wraps [`crate::event::EventQueue`] and provides typed emit helpers covering
//! the full lifecycle of a province map: loading, adjacency, borders, map
//! modes, position calculation, and interaction events.
//!
//! # Event names
//!
//! | Name | Args | Meaning |
//! |---|---|---|
//! | `map_loaded` | `count` | Province map loaded/created with `count` provinces |
//! | `adjacency_detected` | `edge_count` | Adjacency scan completed |
//! | `adjacency_changed` | `a`, `b` | An edge between provinces `a` and `b` was added or modified |
//! | `adjacency_removed` | `a`, `b` | The edge between provinces `a` and `b` was removed |
//! | `borders_extracted` | `segment_count` | Border segments extracted from adjacency data |
//! | `map_mode_applied` | `name` | A map mode colour pass was applied |
//! | `positions_calculated` | `count` | Center positions calculated for `count` provinces |
//! | `province_selected` | `id`, `x`, `y` | A province was clicked or selected at map coords `(x, y)` |
//! | `province_deselected` | `id` | A previously selected province was deselected |
//! | `province_hovered` | `id`, `x`, `y` | Cursor moved over province `id` at `(x, y)` |
//! | `province_added` | `id` | A new province was inserted into the map |
//! | `province_removed` | `id` | A province was removed from the map |

use crate::event::{Event, EventArg, EventQueue};

/// Event bus for province map events.
///
/// All events carry typed arguments accessible via [`crate::event::EventArg`].
/// Call [`poll`](Self::poll) or [`drain`](Self::drain) each frame to consume
/// queued events.
#[derive(Debug, Default)]
pub struct ProvinceMapEventBus {
    queue: EventQueue,
}

impl ProvinceMapEventBus {
    /// Create an empty event bus.
    pub fn new() -> Self {
        Self::default()
    }

    // ── Loading ────────────────────────────────────────────────────────────────

    /// Emit `"map_loaded"` after a province map has been loaded or created.
    ///
    /// `province_count` is the number of provinces in the map.
    pub fn emit_map_loaded(&mut self, province_count: usize) {
        self.queue.push_event("map_loaded", vec![EventArg::Num(province_count as f64)]);
    }

    /// Emit `"province_added"` when a province is inserted into the map.
    pub fn emit_province_added(&mut self, province_id: u32) {
        self.queue.push_event("province_added", vec![EventArg::Num(province_id as f64)]);
    }

    /// Emit `"province_removed"` when a province is removed from the map.
    pub fn emit_province_removed(&mut self, province_id: u32) {
        self.queue.push_event("province_removed", vec![EventArg::Num(province_id as f64)]);
    }

    // ── Adjacency ─────────────────────────────────────────────────────────────

    /// Emit `"adjacency_detected"` after a full adjacency scan completes.
    ///
    /// `edge_count` is the total number of adjacency edges found.
    pub fn emit_adjacency_detected(&mut self, edge_count: usize) {
        self.queue.push_event("adjacency_detected", vec![EventArg::Num(edge_count as f64)]);
    }

    /// Emit `"adjacency_changed"` when an edge between two provinces is added or modified.
    pub fn emit_adjacency_changed(&mut self, province_a: u32, province_b: u32) {
        self.queue.push_event(
            "adjacency_changed",
            vec![EventArg::Num(province_a as f64), EventArg::Num(province_b as f64)],
        );
    }

    /// Emit `"adjacency_removed"` when the edge between two provinces is removed.
    pub fn emit_adjacency_removed(&mut self, province_a: u32, province_b: u32) {
        self.queue.push_event(
            "adjacency_removed",
            vec![EventArg::Num(province_a as f64), EventArg::Num(province_b as f64)],
        );
    }

    // ── Borders ───────────────────────────────────────────────────────────────

    /// Emit `"borders_extracted"` after border segments are built from adjacency data.
    ///
    /// `segment_count` is the number of border segments produced.
    pub fn emit_borders_extracted(&mut self, segment_count: usize) {
        self.queue.push_event("borders_extracted", vec![EventArg::Num(segment_count as f64)]);
    }

    // ── Map modes & positions ─────────────────────────────────────────────────

    /// Emit `"map_mode_applied"` after a colour pass is applied to the map.
    ///
    /// `mode_name` is the display name of the map mode that was applied.
    pub fn emit_map_mode_applied(&mut self, mode_name: &str) {
        self.queue.push_event("map_mode_applied", vec![EventArg::Str(mode_name.to_string())]);
    }

    /// Emit `"positions_calculated"` after province center positions are computed.
    ///
    /// `province_count` is the number of provinces whose centers were updated.
    pub fn emit_positions_calculated(&mut self, province_count: usize) {
        self.queue.push_event("positions_calculated", vec![EventArg::Num(province_count as f64)]);
    }

    // ── Interaction ───────────────────────────────────────────────────────────

    /// Emit `"province_selected"` when a province is clicked or selected.
    ///
    /// `x` and `y` are map-space coordinates of the selection.
    pub fn emit_province_selected(&mut self, province_id: u32, x: f32, y: f32) {
        self.queue.push_event(
            "province_selected",
            vec![
                EventArg::Num(province_id as f64),
                EventArg::Num(x as f64),
                EventArg::Num(y as f64),
            ],
        );
    }

    /// Emit `"province_deselected"` when a selected province is deselected.
    pub fn emit_province_deselected(&mut self, province_id: u32) {
        self.queue.push_event("province_deselected", vec![EventArg::Num(province_id as f64)]);
    }

    /// Emit `"province_hovered"` when the cursor moves over a province.
    ///
    /// `x` and `y` are map-space cursor coordinates.
    pub fn emit_province_hovered(&mut self, province_id: u32, x: f32, y: f32) {
        self.queue.push_event(
            "province_hovered",
            vec![
                EventArg::Num(province_id as f64),
                EventArg::Num(x as f64),
                EventArg::Num(y as f64),
            ],
        );
    }

    // ── Queue management ──────────────────────────────────────────────────────

    /// Poll the next event from the queue, removing it.
    ///
    /// Returns `None` when the queue is empty.
    pub fn poll(&mut self) -> Option<Event> {
        self.queue.poll()
    }

    /// Returns `true` when there are no pending events.
    pub fn is_empty(&self) -> bool {
        self.queue.is_empty()
    }

    /// Drain all pending events from the queue in FIFO order.
    pub fn drain(&mut self) -> Vec<Event> {
        let mut out = Vec::new();
        while let Some(e) = self.queue.poll() {
            out.push(e);
        }
        out
    }
}
