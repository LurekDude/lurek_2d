//! Dijkstra-budget range-of-movement and threat-range maps on arbitrary grids.
//!
//! Computes all cells reachable from an origin within a given movement budget,
//! taking per-cell costs and blocked cells into account.

use std::collections::BinaryHeap;
use std::cmp::Ordering;

/// A precomputed range map: cheapest path costs from a single origin.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
///
/// `None` entries indicate unreachable cells.
pub struct RangeMap {
    /// Grid width.
    pub width: u32,
    /// Grid height.
    pub height: u32,
    costs: Vec<Option<f32>>,
}

impl RangeMap {
    /// Compute range from `(origin_x, origin_y)` within `budget` on a flat cost grid.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `costs` — `&[f32]`.
    /// - `blocked` — `&[bool]`.
    /// - `origin_x` — `u32`.
    /// - `origin_y` — `u32`.
    /// - `budget` — `f32`.
    /// - `diagonal` — `bool`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `costs` is a row-major slice of movement costs per cell; `0.0` or negative means blocked.
    /// `blocked` is a parallel bool slice (`true` = impassable regardless of cost).
    /// `diagonal` allows 8-directional movement when `true`, otherwise 4-directional.
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
            return Self { width, height, costs: dist };
        }

        let origin_idx = idx(origin_x, origin_y);
        if origin_idx < n && blocked.get(origin_idx).copied().unwrap_or(true) {
            return Self { width, height, costs: dist };
        }

        dist[origin_idx] = Some(0.0);
        let mut heap: BinaryHeap<DNode> = BinaryHeap::new();
        heap.push(DNode { x: origin_x, y: origin_y, cost: 0.0 });

        let dirs: &[(i32, i32)] = if diagonal {
            &[(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]
        } else {
            &[(1,0),(-1,0),(0,1),(0,-1)]
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
                // Diagonal moves cost sqrt(2) * cell_cost
                let move_cost = if dx != 0 && dy != 0 { cell_cost * std::f32::consts::SQRT_2 } else { cell_cost };
                let new_cost = cost + move_cost;
                if new_cost <= budget && new_cost < dist[ni].unwrap_or(f32::MAX) {
                    dist[ni] = Some(new_cost);
                    heap.push(DNode { x: nx, y: ny, cost: new_cost });
                }
            }
        }

        Self { width, height, costs: dist }
    }

    /// Returns `true` if the cell at `(x, y)` was reached within the budget.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn reachable(&self, x: u32, y: u32) -> bool {
        self.cost_to(x, y).is_some()
    }

    /// Cheapest path cost to reach `(x, y)`, or `None` if unreachable.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn cost_to(&self, x: u32, y: u32) -> Option<f32> {
        if x >= self.width || y >= self.height {
            return None;
        }
        self.costs[(y * self.width + x) as usize]
    }

    /// All reachable cells as `(x, y)` tuples.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
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

    /// All reachable cells with their movement cost as `(x, y, cost)` tuples.
    ///
    /// # Returns
    /// `Vec<(u32, u32, f32)>`.
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

#[derive(Clone)]
struct DNode {
    x: u32,
    y: u32,
    cost: f32,
}

impl PartialEq for DNode {
    fn eq(&self, other: &Self) -> bool { self.cost == other.cost }
}
impl Eq for DNode {}

impl PartialOrd for DNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

impl Ord for DNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.cost.partial_cmp(&self.cost).unwrap_or(Ordering::Equal)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn origin_always_reachable() {
        let costs = vec![1.0f32; 9];
        let blocked = vec![false; 9];
        let rm = RangeMap::from_grid(3, 3, &costs, &blocked, 1, 1, 10.0, false);
        assert!(rm.reachable(1, 1));
        assert_eq!(rm.cost_to(1, 1), Some(0.0));
    }

    #[test]
    fn budget_limits_reach() {
        let costs = vec![1.0f32; 25];
        let blocked = vec![false; 25];
        let rm = RangeMap::from_grid(5, 5, &costs, &blocked, 0, 0, 2.0, false);
        assert!(rm.reachable(0, 0));
        assert!(rm.reachable(2, 0));
        assert!(!rm.reachable(4, 4));
    }

    #[test]
    fn blocked_origin_empty() {
        let costs = vec![1.0; 4];
        let blocked = vec![true; 4];
        let rm = RangeMap::from_grid(2, 2, &costs, &blocked, 0, 0, 10.0, false);
        assert!(!rm.reachable(0, 0));
    }

    #[test]
    fn diagonal_extends_reach() {
        let costs = vec![1.0f32; 9];
        let blocked = vec![false; 9];
        let rm_4 = RangeMap::from_grid(3, 3, &costs, &blocked, 0, 0, 1.5, false);
        let rm_8 = RangeMap::from_grid(3, 3, &costs, &blocked, 0, 0, 1.5, true);
        let cells_4 = rm_4.reachable_cells().len();
        let cells_8 = rm_8.reachable_cells().len();
        assert!(cells_8 >= cells_4);
    }

    #[test]
    fn reachable_cells_with_cost_includes_origin() {
        let costs = vec![1.0; 4];
        let blocked = vec![false; 4];
        let rm = RangeMap::from_grid(2, 2, &costs, &blocked, 0, 0, 5.0, false);
        let cells = rm.reachable_cells_with_cost();
        assert!(cells.iter().any(|(x, y, c)| *x == 0 && *y == 0 && *c == 0.0));
    }
}
