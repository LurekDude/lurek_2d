
use crate::log_msg;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, VecDeque};
/// Internal priority-queue node carrying position and accumulated cost.
#[derive(Debug, Clone)]
struct Node {
    /// Accumulated cost used as the heap priority.
    cost: f32,
    /// Grid column.
    x: u32,
    /// Grid row.
    y: u32,
}
/// Equality by cost.
impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.cost == other.cost
    }
}
impl Eq for Node {}

/// Reverse ordering so `BinaryHeap` is a min-heap on cost.
impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
    }
}
/// Delegates to `Ord`.
impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Flat 2-D grid with per-cell walkability flags and movement costs.
pub struct Grid {
    /// Cell columns.
    width: u32,
    /// Cell rows.
    height: u32,
    /// Flat walkability mask; false means the cell is blocked.
    walkable: Vec<bool>,
    /// Per-cell movement cost; default is `default_cost` passed to `new`.
    costs: Vec<f32>,
}
/// Construction and pathfinding methods for `Grid`.
impl Grid {
    /// Create a fully walkable `width × height` grid where every cell starts at `default_cost`.
    pub fn new(width: u32, height: u32, default_cost: f32) -> Self {
        let len = (width as usize) * (height as usize);
        log_msg!(debug, PF01_GRID_INIT, "{}x{}", width, height);
        Self {
            width,
            height,
            walkable: vec![true; len],
            costs: vec![default_cost; len],
        }
    }
    /// Return the grid width in cells.
    pub fn width(&self) -> u32 {
        self.width
    }
    /// Return the grid height in cells.
    pub fn height(&self) -> u32 {
        self.height
    }
    /// Convert `(x, y)` to a flat index; return `None` when out of bounds.
    #[inline]
    fn idx(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y as usize) * (self.width as usize) + (x as usize))
        } else {
            None
        }
    }
    /// Set the walkability of cell `(x, y)`; silently ignores out-of-bounds coordinates.
    pub fn set_walkable(&mut self, x: u32, y: u32, walkable: bool) {
        if let Some(i) = self.idx(x, y) {
            self.walkable[i] = walkable;
        }
    }
    /// Return true when `(x, y)` is in bounds and walkable.
    pub fn is_walkable(&self, x: u32, y: u32) -> bool {
        self.idx(x, y).is_some_and(|i| self.walkable[i])
    }
    /// Set the movement cost for cell `(x, y)`; silently ignores out-of-bounds coordinates.
    pub fn set_cost(&mut self, x: u32, y: u32, cost: f32) {
        if let Some(i) = self.idx(x, y) {
            self.costs[i] = cost;
        }
    }
    /// Return the movement cost at `(x, y)`; returns 1.0 when out of bounds.
    pub fn get_cost(&self, x: u32, y: u32) -> f32 {
        self.idx(x, y).map_or(1.0, |i| self.costs[i])
    }
    /// Return the 4-connected walkable neighbours of `(x, y)`.
    fn neighbors4(&self, x: u32, y: u32) -> Vec<(u32, u32)> {
        let mut out = Vec::with_capacity(4);
        if x > 0 {
            out.push((x - 1, y));
        }
        if y > 0 {
            out.push((x, y - 1));
        }
        if x + 1 < self.width {
            out.push((x + 1, y));
        }
        if y + 1 < self.height {
            out.push((x, y + 1));
        }
        out
    }
    /// Return the 8-connected walkable neighbours of `(x, y)` (no walkability filter, caller checks).
    fn neighbors8(&self, x: u32, y: u32) -> Vec<(u32, u32)> {
        let mut out = Vec::with_capacity(8);
        for dy in [-1i32, 0, 1] {
            for dx in [-1i32, 0, 1] {
                if dx == 0 && dy == 0 {
                    continue;
                }
                let nx = x as i32 + dx;
                let ny = y as i32 + dy;
                if nx >= 0 && ny >= 0 && (nx as u32) < self.width && (ny as u32) < self.height {
                    out.push((nx as u32, ny as u32));
                }
            }
        }
        out
    }
    /// Run A\* from `(sx,sy)` to `(gx,gy)`; use diagonal neighbours when `diagonal` is true.
    pub fn find_path_astar(
        &self,
        sx: u32,
        sy: u32,
        gx: u32,
        gy: u32,
        diagonal: bool,
    ) -> Option<Vec<(u32, u32)>> {
        let len = (self.width as usize) * (self.height as usize);
        let start = self.idx(sx, sy)?;
        let goal = self.idx(gx, gy)?;
        if !self.walkable[start] || !self.walkable[goal] {
            log_msg!(warn, PF03_NO_PATH, "start or goal not walkable");
            return None;
        }
        let heuristic = |x: u32, y: u32| -> f32 {
            let dx = (x as f32 - gx as f32).abs();
            let dy = (y as f32 - gy as f32).abs();
            if diagonal {
                (dx * dx + dy * dy).sqrt()
            } else {
                dx + dy
            }
        };
        let mut g_score = vec![f32::MAX; len];
        let mut came_from: Vec<usize> = (0..len).collect();
        let mut closed = vec![false; len];
        g_score[start] = 0.0;
        let mut open = BinaryHeap::new();
        open.push(Node {
            cost: heuristic(sx, sy),
            x: sx,
            y: sy,
        });
        while let Some(current) = open.pop() {
            let ci = self.idx(current.x, current.y).unwrap();
            if ci == goal {
                return Some(self.reconstruct(came_from, start, goal));
            }
            if closed[ci] {
                continue;
            }
            closed[ci] = true;
            let nbrs = if diagonal {
                self.neighbors8(current.x, current.y)
            } else {
                self.neighbors4(current.x, current.y)
            };
            for (nx, ny) in nbrs {
                let ni = self.idx(nx, ny).unwrap();
                if !self.walkable[ni] || closed[ni] {
                    continue;
                }
                let move_cost = if nx != current.x && ny != current.y {
                    self.costs[ni] * std::f32::consts::SQRT_2
                } else {
                    self.costs[ni]
                };
                let tentative = g_score[ci] + move_cost;
                if tentative < g_score[ni] {
                    g_score[ni] = tentative;
                    came_from[ni] = ci;
                    open.push(Node {
                        cost: tentative + heuristic(nx, ny),
                        x: nx,
                        y: ny,
                    });
                }
            }
        }
        None
    }
    /// Run Dijkstra from `(sx,sy)` to `(gx,gy)`; respects movement costs, no heuristic.
    pub fn find_path_dijkstra(
        &self,
        sx: u32,
        sy: u32,
        gx: u32,
        gy: u32,
        diagonal: bool,
    ) -> Option<Vec<(u32, u32)>> {
        let len = (self.width as usize) * (self.height as usize);
        let start = self.idx(sx, sy)?;
        let goal = self.idx(gx, gy)?;
        if !self.walkable[start] || !self.walkable[goal] {
            return None;
        }
        let mut dist = vec![f32::MAX; len];
        let mut came_from: Vec<usize> = (0..len).collect();
        let mut closed = vec![false; len];
        dist[start] = 0.0;
        let mut open = BinaryHeap::new();
        open.push(Node {
            cost: 0.0,
            x: sx,
            y: sy,
        });
        while let Some(current) = open.pop() {
            let ci = self.idx(current.x, current.y).unwrap();
            if ci == goal {
                return Some(self.reconstruct(came_from, start, goal));
            }
            if closed[ci] {
                continue;
            }
            closed[ci] = true;
            let nbrs = if diagonal {
                self.neighbors8(current.x, current.y)
            } else {
                self.neighbors4(current.x, current.y)
            };
            for (nx, ny) in nbrs {
                let ni = self.idx(nx, ny).unwrap();
                if !self.walkable[ni] || closed[ni] {
                    continue;
                }
                let move_cost = if nx != current.x && ny != current.y {
                    self.costs[ni] * std::f32::consts::SQRT_2
                } else {
                    self.costs[ni]
                };
                let tentative = dist[ci] + move_cost;
                if tentative < dist[ni] {
                    dist[ni] = tentative;
                    came_from[ni] = ci;
                    open.push(Node {
                        cost: tentative,
                        x: nx,
                        y: ny,
                    });
                }
            }
        }
        None
    }
    /// Run BFS (unweighted) from `(sx,sy)` to `(gx,gy)`; ignores movement costs.
    pub fn find_path_bfs(
        &self,
        sx: u32,
        sy: u32,
        gx: u32,
        gy: u32,
        diagonal: bool,
    ) -> Option<Vec<(u32, u32)>> {
        let len = (self.width as usize) * (self.height as usize);
        let start = self.idx(sx, sy)?;
        let goal = self.idx(gx, gy)?;
        if !self.walkable[start] || !self.walkable[goal] {
            return None;
        }
        let mut visited = vec![false; len];
        let mut came_from: Vec<usize> = (0..len).collect();
        visited[start] = true;
        let mut queue = VecDeque::new();
        queue.push_back((sx, sy));
        while let Some((cx, cy)) = queue.pop_front() {
            let ci = self.idx(cx, cy).unwrap();
            if ci == goal {
                return Some(self.reconstruct(came_from, start, goal));
            }
            let nbrs = if diagonal {
                self.neighbors8(cx, cy)
            } else {
                self.neighbors4(cx, cy)
            };
            for (nx, ny) in nbrs {
                let ni = self.idx(nx, ny).unwrap();
                if !self.walkable[ni] || visited[ni] {
                    continue;
                }
                visited[ni] = true;
                came_from[ni] = ci;
                queue.push_back((nx, ny));
            }
        }
        None
    }
    /// Walk `came_from` back from `goal` to `start` and return the ordered path.
    fn reconstruct(&self, came_from: Vec<usize>, start: usize, goal: usize) -> Vec<(u32, u32)> {
        let mut path = Vec::new();
        let mut cur = goal;
        while cur != start {
            let x = (cur % self.width as usize) as u32;
            let y = (cur / self.width as usize) as u32;
            path.push((x, y));
            cur = came_from[cur];
        }
        let sx = (start % self.width as usize) as u32;
        let sy = (start / self.width as usize) as u32;
        path.push((sx, sy));
        path.reverse();
        path
    }
    /// Build a 4-directional Dijkstra flow field toward `(gx, gy)`; returns one `(dx,dy)` per cell.
    pub fn build_flow_field(&self, gx: u32, gy: u32) -> Vec<(f32, f32)> {
        let len = (self.width as usize) * (self.height as usize);
        let goal = match self.idx(gx, gy) {
            Some(i) => i,
            None => return vec![(0.0, 0.0); len],
        };
        let mut dist = vec![f32::MAX; len];
        dist[goal] = 0.0;
        let mut open = BinaryHeap::new();
        open.push(Node {
            cost: 0.0,
            x: gx,
            y: gy,
        });
        let mut closed = vec![false; len];
        while let Some(current) = open.pop() {
            let ci = self.idx(current.x, current.y).unwrap();
            if closed[ci] {
                continue;
            }
            closed[ci] = true;
            for (nx, ny) in self.neighbors4(current.x, current.y) {
                let ni = self.idx(nx, ny).unwrap();
                if !self.walkable[ni] || closed[ni] {
                    continue;
                }
                let tentative = dist[ci] + self.costs[ni];
                if tentative < dist[ni] {
                    dist[ni] = tentative;
                    open.push(Node {
                        cost: tentative,
                        x: nx,
                        y: ny,
                    });
                }
            }
        }
        let mut field = vec![(0.0f32, 0.0f32); len];
        for y in 0..self.height {
            for x in 0..self.width {
                let ci = self.idx(x, y).unwrap();
                if dist[ci] >= f32::MAX || ci == goal {
                    continue;
                }
                let mut best_dist = dist[ci];
                let mut best = (0.0f32, 0.0f32);
                for (nx, ny) in self.neighbors4(x, y) {
                    let ni = self.idx(nx, ny).unwrap();
                    if dist[ni] < best_dist {
                        best_dist = dist[ni];
                        best = (nx as f32 - x as f32, ny as f32 - y as f32);
                    }
                }
                field[ci] = best;
            }
        }
        field
    }
}
