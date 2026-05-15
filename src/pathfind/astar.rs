//! - A\* pathfinding on a `NavGrid` with configurable diagonal modes and unit sizes.
//! - Heuristic selection: octile distance for diagonal movement, Manhattan otherwise.
//! - Early termination via `max_nodes` with partial-path fallback to closest reached cell.
//! - Bresenham line-of-sight checks for walkability validation.
//! - String-pull path smoothing that removes redundant waypoints.

use crate::runtime::log_messages::{AT01,AT02,AT03};

use crate::log_msg;
use crate::pathfind::nav_grid::{DiagonalMode, NavGrid};
use std::cmp::Ordering;
use std::collections::BinaryHeap;
const SQRT2: f32 = std::f32::consts::SQRT_2;

/// Priority-queue node used internally by the A\* open set.
#[derive(Debug, Clone)]
struct AStarNode {
    /// Combined cost estimate f = g + h.
    f: f32,
    /// Actual cost from start to this node.
    g: f32,
    /// Grid column of this node.
    x: u32,
    /// Grid row of this node.
    y: u32,
}
/// Equality by f-cost for heap deduplication.
impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
/// Marker trait required by `Ord`; equality is based on f-cost.
impl Eq for AStarNode {}

/// Reverse ordering so `BinaryHeap` becomes a min-heap on f-cost.
impl Ord for AStarNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
/// Delegates to `Ord` for consistency.
impl PartialOrd for AStarNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Return octile distance when `diagonal` is true, otherwise Manhattan distance.
fn heuristic(x1: u32, y1: u32, x2: u32, y2: u32, diagonal: bool) -> f32 {
    let dx = (x1 as f32 - x2 as f32).abs();
    let dy = (y1 as f32 - y2 as f32).abs();
    if diagonal {
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * SQRT2 + (max - min)
    } else {
        dx + dy
    }
}
/// Run A\* on `grid` from `start` to `goal`; return `(path, reached_goal)`. Returns partial path.
/// to closest node when `max_nodes` is hit or goal is unreachable.
pub fn astar(
    grid: &NavGrid,
    start: (u32, u32),
    goal: (u32, u32),
    unit_size: u32,
    max_nodes: u32,
) -> (Option<Vec<(u32, u32)>>, bool) {
    let (w, h) = grid.get_dimensions();
    let size = (w * h) as usize;
    let us = unit_size.max(1);
    if !grid.is_walkable(start.0, start.1, us) || !grid.is_walkable(goal.0, goal.1, us) {
        log_msg!(
            warn,
            AT01,
            "({},{}) -> ({},{})",
            start.0,
            start.1,
            goal.0,
            goal.1
        );
        return (Option::None, false);
    }
    if start == goal {
        log_msg!(debug, AT02, "({},{})", start.0, start.1);
        return (Some(vec![start]), true);
    }
    let allows_diag = grid.get_diagonal_mode() != DiagonalMode::None;
    let mut g_costs = vec![f32::INFINITY; size];
    let mut came_from: Vec<u32> = vec![u32::MAX; size];
    let mut closed = vec![false; size];
    let start_idx = (start.1 * w + start.0) as usize;
    g_costs[start_idx] = 0.0;
    let mut open = BinaryHeap::new();
    open.push(AStarNode {
        f: heuristic(start.0, start.1, goal.0, goal.1, allows_diag),
        g: 0.0,
        x: start.0,
        y: start.1,
    });
    let mut expanded: u32 = 0;
    let mut best_idx = start_idx;
    let mut best_h = heuristic(start.0, start.1, goal.0, goal.1, allows_diag);
    while let Some(current) = open.pop() {
        let idx = (current.y * w + current.x) as usize;
        if closed[idx] {
            continue;
        }
        closed[idx] = true;
        expanded += 1;
        if (current.x, current.y) == goal {
            log_msg!(debug, AT03, "({},{})", goal.0, goal.1);
            return (
                Some(reconstruct(came_from.as_slice(), w, start, goal)),
                true,
            );
        }
        let h = heuristic(current.x, current.y, goal.0, goal.1, allows_diag);
        if h < best_h {
            best_h = h;
            best_idx = idx;
        }
        if max_nodes > 0 && expanded >= max_nodes {
            let bx = (best_idx as u32) % w;
            let by = (best_idx as u32) / w;
            return (
                Some(reconstruct(came_from.as_slice(), w, start, (bx, by))),
                false,
            );
        }
        for (nx, ny) in neighbors_with_unit(grid, current.x, current.y, us) {
            let n_idx = (ny * w + nx) as usize;
            if closed[n_idx] {
                continue;
            }
            let is_diag = nx != current.x && ny != current.y;
            let step_cost = if is_diag { SQRT2 } else { 1.0 } * grid.get_cost(nx, ny) as f32;
            let tentative_g = current.g + step_cost;
            if tentative_g < g_costs[n_idx] {
                g_costs[n_idx] = tentative_g;
                came_from[n_idx] = idx as u32;
                let f = tentative_g + heuristic(nx, ny, goal.0, goal.1, allows_diag);
                open.push(AStarNode {
                    f,
                    g: tentative_g,
                    x: nx,
                    y: ny,
                });
            }
        }
    }
    if best_idx != start_idx {
        let bx = (best_idx as u32) % w;
        let by = (best_idx as u32) / w;
        (
            Some(reconstruct(came_from.as_slice(), w, start, (bx, by))),
            false,
        )
    } else {
        (Option::None, false)
    }
}
/// Return walkable neighbours of `(x, y)` respecting `unit_size` and the grid's diagonal mode.
fn neighbors_with_unit(grid: &NavGrid, x: u32, y: u32, unit_size: u32) -> Vec<(u32, u32)> {
    let w = grid.get_width();
    let h = grid.get_height();
    let mode = grid.get_diagonal_mode();
    let mut result = Vec::with_capacity(8);
    let can_up = y > 0 && grid.is_walkable(x, y - 1, unit_size);
    let can_down = y + unit_size < h && grid.is_walkable(x, y + 1, unit_size);
    let can_left = x > 0 && grid.is_walkable(x - 1, y, unit_size);
    let can_right = x + unit_size < w && grid.is_walkable(x + 1, y, unit_size);
    if can_up {
        result.push((x, y - 1));
    }
    if can_down {
        result.push((x, y + 1));
    }
    if can_left {
        result.push((x - 1, y));
    }
    if can_right {
        result.push((x + 1, y));
    }
    match mode {
        DiagonalMode::None => {}
        DiagonalMode::Always => {
            if y > 0 && x > 0 && grid.is_walkable(x - 1, y - 1, unit_size) {
                result.push((x - 1, y - 1));
            }
            if y > 0 && x + unit_size < w && grid.is_walkable(x + 1, y - 1, unit_size) {
                result.push((x + 1, y - 1));
            }
            if y + unit_size < h && x > 0 && grid.is_walkable(x - 1, y + 1, unit_size) {
                result.push((x - 1, y + 1));
            }
            if y + unit_size < h && x + unit_size < w && grid.is_walkable(x + 1, y + 1, unit_size) {
                result.push((x + 1, y + 1));
            }
        }
        DiagonalMode::NoCornerCut => {
            if can_up && can_left && grid.is_walkable(x - 1, y - 1, unit_size) {
                result.push((x - 1, y - 1));
            }
            if can_up && can_right && grid.is_walkable(x + 1, y - 1, unit_size) {
                result.push((x + 1, y - 1));
            }
            if can_down && can_left && grid.is_walkable(x - 1, y + 1, unit_size) {
                result.push((x - 1, y + 1));
            }
            if can_down && can_right && grid.is_walkable(x + 1, y + 1, unit_size) {
                result.push((x + 1, y + 1));
            }
        }
    }
    result
}
/// Walk the `came_from` parent table back from `end` to `start` and return the ordered path.
fn reconstruct(came_from: &[u32], w: u32, start: (u32, u32), end: (u32, u32)) -> Vec<(u32, u32)> {
    let mut path = Vec::new();
    let mut cur = (end.1 * w + end.0) as usize;
    let start_idx = (start.1 * w + start.0) as usize;
    loop {
        let x = (cur as u32) % w;
        let y = (cur as u32) / w;
        path.push((x, y));
        if cur == start_idx {
            break;
        }
        let prev = came_from[cur] as usize;
        if prev == u32::MAX as usize || prev == cur {
            break;
        }
        cur = prev;
    }
    path.reverse();
    path
}
/// Return true when a straight Bresenham line from `(x1,y1)` to `(x2,y2)` crosses no blocked cells.
pub fn line_of_sight(grid: &NavGrid, x1: u32, y1: u32, x2: u32, y2: u32, unit_size: u32) -> bool {
    let us = unit_size.max(1);
    let mut sx = x1 as i32;
    let mut sy = y1 as i32;
    let ex = x2 as i32;
    let ey = y2 as i32;
    let dx = (ex - sx).abs();
    let dy = (ey - sy).abs();
    let step_x: i32 = if sx < ex { 1 } else { -1 };
    let step_y: i32 = if sy < ey { 1 } else { -1 };
    let mut err = dx - dy;
    loop {
        if sx < 0 || sy < 0 || !grid.is_walkable(sx as u32, sy as u32, us) {
            return false;
        }
        if sx == ex && sy == ey {
            return true;
        }
        let e2 = 2 * err;
        if e2 > -dy {
            err -= dy;
            sx += step_x;
        }
        if e2 < dx {
            err += dx;
            sy += step_y;
        }
    }
}
/// Apply string-pull smoothing: reduce waypoints by skipping any that have direct line-of-sight.
pub fn smooth_path(grid: &NavGrid, path: &[(u32, u32)], unit_size: u32) -> Vec<(u32, u32)> {
    if path.len() <= 2 {
        return path.to_vec();
    }
    let mut smoothed = Vec::with_capacity(path.len());
    smoothed.push(path[0]);
    let mut anchor = 0;
    while anchor < path.len() - 1 {
        let mut farthest = anchor + 1;
        for i in (anchor + 2)..path.len() {
            if line_of_sight(
                grid,
                path[anchor].0,
                path[anchor].1,
                path[i].0,
                path[i].1,
                unit_size,
            ) {
                farthest = i;
            }
        }
        smoothed.push(path[farthest]);
        anchor = farthest;
    }
    smoothed
}
