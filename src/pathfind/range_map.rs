//! Dijkstra-based movement range map: reachable cells within a travel budget from an origin.
//! Supports 4-directional and 8-directional expansion with per-cell cost.
//! Does not own Lua bindings; consumed by `src/lua_api/pathfind_api.rs`.

use std::cmp::Ordering;
use std::collections::BinaryHeap;
/// Precomputed movement-cost distances from an origin cell within a budget.
pub struct RangeMap {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// Per-cell travel cost from origin; `None` means unreachable within budget.
    costs: Vec<Option<f32>>,
}
/// Construction and query methods for `RangeMap`.
impl RangeMap {
    /// Build a range map from a flat `costs`/`blocked` grid expanding from `(origin_x, origin_y)` within `budget`.
    #[allow(clippy::too_many_arguments)]
    pub fn from_grid(
        width: u32,
        height: u32,
        costs: &[f32],
        blocked: &[bool],
        origin_x: u32,
        origin_y: u32,
        budget: f32,
        diagonal: bool,
    ) -> Self {
        let n = (width * height) as usize;
        let mut dist: Vec<Option<f32>> = vec![None; n];
        let idx = |x: u32, y: u32| (y * width + x) as usize;
        if origin_x >= width || origin_y >= height {
            return Self {
                width,
                height,
                costs: dist,
            };
        }
        let origin_idx = idx(origin_x, origin_y);
        if origin_idx < n && blocked.get(origin_idx).copied().unwrap_or(true) {
            return Self {
                width,
                height,
                costs: dist,
            };
        }
        dist[origin_idx] = Some(0.0);
        let mut heap: BinaryHeap<DNode> = BinaryHeap::new();
        heap.push(DNode {
            x: origin_x,
            y: origin_y,
            cost: 0.0,
        });
        let dirs: &[(i32, i32)] = if diagonal {
            &[
                (1, 0),
                (-1, 0),
                (0, 1),
                (0, -1),
                (1, 1),
                (1, -1),
                (-1, 1),
                (-1, -1),
            ]
        } else {
            &[(1, 0), (-1, 0), (0, 1), (0, -1)]
        };
        while let Some(DNode { x, y, cost }) = heap.pop() {
            let cur_idx = idx(x, y);
            if cost > dist[cur_idx].unwrap_or(f32::MAX) {
                continue;
            }
            for &(dx, dy) in dirs {
                let nx = x as i32 + dx;
                let ny = y as i32 + dy;
                if nx < 0 || ny < 0 || nx >= width as i32 || ny >= height as i32 {
                    continue;
                }
                let nx = nx as u32;
                let ny = ny as u32;
                let ni = idx(nx, ny);
                if blocked.get(ni).copied().unwrap_or(true) {
                    continue;
                }
                let cell_cost = costs.get(ni).copied().unwrap_or(0.0);
                if cell_cost <= 0.0 {
                    continue;
                }
                let move_cost = if dx != 0 && dy != 0 {
                    cell_cost * std::f32::consts::SQRT_2
                } else {
                    cell_cost
                };
                let new_cost = cost + move_cost;
                if new_cost <= budget && new_cost < dist[ni].unwrap_or(f32::MAX) {
                    dist[ni] = Some(new_cost);
                    heap.push(DNode {
                        x: nx,
                        y: ny,
                        cost: new_cost,
                    });
                }
            }
        }
        Self {
            width,
            height,
            costs: dist,
        }
    }
    /// Return true when `(x, y)` was reached within the budget.
    pub fn reachable(&self, x: u32, y: u32) -> bool {
        self.cost_to(x, y).is_some()
    }
    /// Return travel cost from origin to `(x, y)`, or `None` when unreachable or out-of-bounds.
    pub fn cost_to(&self, x: u32, y: u32) -> Option<f32> {
        if x >= self.width || y >= self.height {
            return None;
        }
        self.costs[(y * self.width + x) as usize]
    }
    /// Return all `(x, y)` cells reachable within the budget.
    pub fn reachable_cells(&self) -> Vec<(u32, u32)> {
        self.costs
            .iter()
            .enumerate()
            .filter_map(|(i, c)| {
                c.map(|_| {
                    let x = (i as u32) % self.width;
                    let y = (i as u32) / self.width;
                    (x, y)
                })
            })
            .collect()
    }
    /// Return all reachable cells as `(x, y, travel_cost)` triples.
    pub fn reachable_cells_with_cost(&self) -> Vec<(u32, u32, f32)> {
        self.costs
            .iter()
            .enumerate()
            .filter_map(|(i, c)| {
                c.map(|cost| {
                    let x = (i as u32) % self.width;
                    let y = (i as u32) / self.width;
                    (x, y, cost)
                })
            })
            .collect()
    }
}
/// Internal Dijkstra heap node.
#[derive(Clone)]
struct DNode {
    /// Cell x coordinate.
    x: u32,
    /// Cell y coordinate.
    y: u32,
    /// Accumulated travel cost to reach this node.
    cost: f32,
}
/// Equality by cost.
impl PartialEq for DNode {
    fn eq(&self, other: &Self) -> bool {
        self.cost == other.cost
    }
}
impl Eq for DNode {}

/// Delegates to `Ord`.
impl PartialOrd for DNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Reverse ordering so `BinaryHeap` is a min-heap.
impl Ord for DNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
    }
}
