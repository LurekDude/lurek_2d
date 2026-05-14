//! Bidirectional A\* search: runs forward and backward queues simultaneously and joins at the
//! first cell that both frontiers have closed. Faster than one-way A\* on long, open corridors.
//! Does not own grid construction; consumed by `src/lua_api/pathfind_api.rs`.

use crate::log_msg;
use crate::pathfind::nav_grid::{DiagonalMode, NavGrid};
use crate::runtime::log_messages::{BI01, BI02, BI03};
use std::cmp::Ordering;
use std::collections::BinaryHeap;
const SQRT2: f32 = std::f32::consts::SQRT_2;
/// Priority-queue node used by both forward and backward open sets.
#[derive(Debug, Clone)]
struct BNode {
    /// Combined cost estimate f = g + h.
    f: f32,
    /// Actual cost from the originating end to this node.
    g: f32,
    /// Grid column.
    x: u32,
    /// Grid row.
    y: u32,
}
/// Equality by f-cost for heap deduplication.
impl PartialEq for BNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
impl Eq for BNode {}

/// Reverse ordering so `BinaryHeap` is a min-heap on f-cost.
impl Ord for BNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
/// Delegates to `Ord`.
impl PartialOrd for BNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Return octile distance (diagonal allowed) or Manhattan distance.
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
/// Return walkable neighbours of `(x, y)` respecting `unit_size` and the grid diagonal mode.
fn neighbours(grid: &NavGrid, x: u32, y: u32, unit_size: u32) -> Vec<(u32, u32)> {
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
/// Walk `came_from` back from `end_coord` to `anchor_idx` and return the ordered sub-path.
fn reconstruct_half(
    came_from: &[u32],
    w: u32,
    anchor_idx: usize,
    end_coord: (u32, u32),
) -> Vec<(u32, u32)> {
    let mut path = Vec::new();
    let mut cur = (end_coord.1 * w + end_coord.0) as usize;
    loop {
        let x = (cur as u32) % w;
        let y = (cur as u32) / w;
        path.push((x, y));
        if cur == anchor_idx {
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
/// Run bidirectional A\* on `grid`; return `(path, reached_goal)`. Falls back to a partial
/// forward path when `max_nodes` is exhausted before the frontiers meet.
pub fn bidirectional_astar(
    grid: &NavGrid,
    start: (u32, u32),
    goal: (u32, u32),
    unit_size: u32,
    max_nodes: u32,
) -> (Option<Vec<(u32, u32)>>, bool) {
    let (w, h) = grid.get_dimensions();
    let _ = h;
    let size = (w * grid.get_height()) as usize;
    let us = unit_size.max(1);
    if !grid.is_walkable(start.0, start.1, us) || !grid.is_walkable(goal.0, goal.1, us) {
        log_msg!(
            warn,
            BI01,
            "({},{}) -> ({},{})",
            start.0,
            start.1,
            goal.0,
            goal.1
        );
        return (None, false);
    }
    if start == goal {
        log_msg!(debug, BI02, "({},{})", start.0, start.1);
        return (Some(vec![start]), true);
    }
    let allows_diag = grid.get_diagonal_mode() != DiagonalMode::None;
    let start_idx = (start.1 * w + start.0) as usize;
    let goal_idx = (goal.1 * w + goal.0) as usize;
    let mut fwd_g = vec![f32::INFINITY; size];
    let mut fwd_came = vec![u32::MAX; size];
    let mut fwd_closed = vec![false; size];
    let mut bwd_g = vec![f32::INFINITY; size];
    let mut bwd_came = vec![u32::MAX; size];
    let mut bwd_closed = vec![false; size];
    fwd_g[start_idx] = 0.0;
    bwd_g[goal_idx] = 0.0;
    let mut fwd_open: BinaryHeap<BNode> = BinaryHeap::new();
    let mut bwd_open: BinaryHeap<BNode> = BinaryHeap::new();
    fwd_open.push(BNode {
        f: heuristic(start.0, start.1, goal.0, goal.1, allows_diag),
        g: 0.0,
        x: start.0,
        y: start.1,
    });
    bwd_open.push(BNode {
        f: heuristic(goal.0, goal.1, start.0, start.1, allows_diag),
        g: 0.0,
        x: goal.0,
        y: goal.1,
    });
    let mut expanded: u32 = 0;
    loop {
        if fwd_open.is_empty() && bwd_open.is_empty() {
            break;
        }
        let fwd_f = fwd_open.peek().map_or(f32::INFINITY, |n| n.f);
        let bwd_f = bwd_open.peek().map_or(f32::INFINITY, |n| n.f);
        let expand_fwd = !fwd_open.is_empty() && (bwd_open.is_empty() || fwd_f <= bwd_f);
        if expand_fwd {
            let cur = match fwd_open.pop() {
                Some(n) => n,
                None => break,
            };
            let cur_idx = (cur.y * w + cur.x) as usize;
            if fwd_closed[cur_idx] {
                continue;
            }
            fwd_closed[cur_idx] = true;
            expanded += 1;
            if bwd_closed[cur_idx] {
                let meet = (cur.x, cur.y);
                log_msg!(debug, BI03, "({},{})", meet.0, meet.1);
                let fwd_path = reconstruct_half(&fwd_came, w, start_idx, meet);
                let bwd_path = reconstruct_half(&bwd_came, w, goal_idx, meet);
                let mut path = fwd_path;
                let tail: Vec<(u32, u32)> = bwd_path.into_iter().rev().skip(1).collect();
                path.extend(tail);
                return (Some(path), true);
            }
            if max_nodes > 0 && expanded >= max_nodes {
                let partial = reconstruct_half(&fwd_came, w, start_idx, (cur.x, cur.y));
                return (Some(partial), false);
            }
            for (nx, ny) in neighbours(grid, cur.x, cur.y, us) {
                let n_idx = (ny * w + nx) as usize;
                if fwd_closed[n_idx] {
                    continue;
                }
                let is_diag = nx != cur.x && ny != cur.y;
                let step = (if is_diag { SQRT2 } else { 1.0 }) * grid.get_cost(nx, ny) as f32;
                let tg = cur.g + step;
                if tg < fwd_g[n_idx] {
                    fwd_g[n_idx] = tg;
                    fwd_came[n_idx] = cur_idx as u32;
                    fwd_open.push(BNode {
                        f: tg + heuristic(nx, ny, goal.0, goal.1, allows_diag),
                        g: tg,
                        x: nx,
                        y: ny,
                    });
                }
            }
        } else {
            let cur = match bwd_open.pop() {
                Some(n) => n,
                None => break,
            };
            let cur_idx = (cur.y * w + cur.x) as usize;
            if bwd_closed[cur_idx] {
                continue;
            }
            bwd_closed[cur_idx] = true;
            expanded += 1;
            if fwd_closed[cur_idx] {
                let meet = (cur.x, cur.y);
                log_msg!(debug, BI03, "({},{})", meet.0, meet.1);
                let fwd_path = reconstruct_half(&fwd_came, w, start_idx, meet);
                let bwd_path = reconstruct_half(&bwd_came, w, goal_idx, meet);
                let mut path = fwd_path;
                let tail: Vec<(u32, u32)> = bwd_path.into_iter().rev().skip(1).collect();
                path.extend(tail);
                return (Some(path), true);
            }
            if max_nodes > 0 && expanded >= max_nodes {
                return (None, false);
            }
            for (nx, ny) in neighbours(grid, cur.x, cur.y, us) {
                let n_idx = (ny * w + nx) as usize;
                if bwd_closed[n_idx] {
                    continue;
                }
                let is_diag = nx != cur.x && ny != cur.y;
                let step = (if is_diag { SQRT2 } else { 1.0 }) * grid.get_cost(nx, ny) as f32;
                let tg = cur.g + step;
                if tg < bwd_g[n_idx] {
                    bwd_g[n_idx] = tg;
                    bwd_came[n_idx] = cur_idx as u32;
                    bwd_open.push(BNode {
                        f: tg + heuristic(nx, ny, start.0, start.1, allows_diag),
                        g: tg,
                        x: nx,
                        y: ny,
                    });
                }
            }
        }
    }
    (None, false)
}
