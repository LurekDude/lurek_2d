//! 2D pathfinding grid with A*, Dijkstra, BFS, and flow field generation.
//!
//! Cells are addressed with 0-based `(x, y)` coordinates. The Lua layer
//! converts to/from 1-based indices.
//!
//! This module is part of Luna2D's `math` subsystem and provides the implementation
//! details for grid-related operations and data management.
//! Key types exported from this module: `Grid`.
//! Primary functions: `new()`, `width()`, `height()`, `set_walkable()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, VecDeque};

/// A node in the A*/Dijkstra priority queue.
#[derive(Debug, Clone)]
struct Node {
    cost: f32,
    x: u32,
    y: u32,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.cost == other.cost
    }
}

impl Eq for Node {}

impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        // Reversed for min-heap behaviour in BinaryHeap (max-heap by default)
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
    }
}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

/// 2D pathfinding grid with per-cell walkability and movement costs.
///
/// Supports A*, Dijkstra, and BFS pathfinding as well as flow field generation.
/// All coordinates are 0-based.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `walkable` — `Vec<bool>`.
/// - `costs` — `Vec<f32>`.
pub struct Grid {
    width: u32,
    height: u32,
    walkable: Vec<bool>,
    costs: Vec<f32>,
}

impl Grid {
    /// Creates a new grid where every cell is walkable with the given movement cost.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// # Parameters
    /// - `width`  — Number of columns.
    /// - `height` — Number of rows.
    /// - `default_cost` — Initial movement cost for every cell.
    pub fn new(width: u32, height: u32, default_cost: f32) -> Self {
        let len = (width as usize) * (height as usize);
        Self {
            width,
            height,
            walkable: vec![true; len],
            costs: vec![default_cost; len],
        }
    }

    /// Returns the grid width in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Returns the grid height in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Converts 2D coordinates to a flat index, returning `None` if out of bounds.
    #[inline]
    fn idx(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y as usize) * (self.width as usize) + (x as usize))
        } else {
            None
        }
    }

    /// Sets whether the cell at `(x, y)` is walkable.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `walkable` — `bool`.
    pub fn set_walkable(&mut self, x: u32, y: u32, walkable: bool) {
        if let Some(i) = self.idx(x, y) {
            self.walkable[i] = walkable;
        }
    }

    /// Returns whether the cell at `(x, y)` is walkable.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_walkable(&self, x: u32, y: u32) -> bool {
        self.idx(x, y).is_some_and(|i| self.walkable[i])
    }

    /// Sets the movement cost of the cell at `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `cost` — `f32`.
    pub fn set_cost(&mut self, x: u32, y: u32, cost: f32) {
        if let Some(i) = self.idx(x, y) {
            self.costs[i] = cost;
        }
    }

    /// Returns the movement cost of the cell at `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_cost(&self, x: u32, y: u32) -> f32 {
        self.idx(x, y).map_or(1.0, |i| self.costs[i])
    }

    // ── Neighbour helpers ──────────────────────────────────────────────

    /// Returns 4-directional neighbours (no diagonals).
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

    /// Returns 8-directional neighbours (including diagonals).
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

    // ── A* ─────────────────────────────────────────────────────────────

    /// Finds a path from `(sx, sy)` to `(gx, gy)` using A*.
    ///
    /// # Parameters
    /// - `sx` — `u32`.
    /// - `sy` — `u32`.
    /// - `gx` — `u32`.
    /// - `gy` — `u32`.
    /// - `diagonal` — `bool`.
    ///
    /// # Returns
    /// `Option<Vec<(u32, u32)>>`.
    ///
    /// When `diagonal` is `true`, 8-directional movement is allowed and the
    /// heuristic uses Euclidean distance; otherwise 4-directional movement with
    /// Manhattan distance.
    ///
    /// Returns `None` if no path exists.
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

    /// Finds a path from `(sx, sy)` to `(gx, gy)` using Dijkstra's algorithm.
    ///
    /// # Parameters
    /// - `sx` — `u32`.
    /// - `sy` — `u32`.
    /// - `gx` — `u32`.
    /// - `gy` — `u32`.
    /// - `diagonal` — `bool`.
    ///
    /// # Returns
    /// `Option<Vec<(u32, u32)>>`.
    ///
    /// Equivalent to A* with heuristic = 0. Respects cell costs.
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

    /// Finds a shortest-hop path from `(sx, sy)` to `(gx, gy)` using BFS.
    ///
    /// # Parameters
    /// - `sx` — `u32`.
    /// - `sy` — `u32`.
    /// - `gx` — `u32`.
    /// - `gy` — `u32`.
    /// - `diagonal` — `bool`.
    ///
    /// # Returns
    /// `Option<Vec<(u32, u32)>>`.
    ///
    /// Ignores cell costs — every walkable step has equal weight.
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

    /// Reconstruct a path from `came_from` links.
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

    // ── Flow field ─────────────────────────────────────────────────────

    /// Builds a flow field pointing toward `(gx, gy)`.
    ///
    /// # Parameters
    /// - `gx` — `u32`.
    /// - `gy` — `u32`.
    ///
    /// # Returns
    /// `Vec<(f32, f32)>`.
    ///
    /// Returns a flat `width * height` vector of `(dx, dy)` direction pairs.
    /// Unreachable or wall cells get `(0.0, 0.0)`.
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

        // Dijkstra from goal
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

        // Build direction vectors
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn open_grid_finds_path() {
        let grid = Grid::new(5, 5, 1.0);
        let path = grid.find_path_astar(0, 0, 4, 4, false).unwrap();
        assert_eq!(*path.first().unwrap(), (0, 0));
        assert_eq!(*path.last().unwrap(), (4, 4));
        // Manhattan path length for 4+4 steps = 9 nodes
        assert_eq!(path.len(), 9);
    }

    #[test]
    fn blocked_path_returns_none() {
        let mut grid = Grid::new(5, 1, 1.0);
        grid.set_walkable(2, 0, false);
        assert!(grid.find_path_astar(0, 0, 4, 0, false).is_none());
    }

    #[test]
    fn wall_grid_routes_around() {
        let mut grid = Grid::new(5, 5, 1.0);
        // Wall across column 2 except (2,4)
        for y in 0..4 {
            grid.set_walkable(2, y, false);
        }
        let path = grid.find_path_astar(0, 0, 4, 0, false).unwrap();
        assert_eq!(*path.first().unwrap(), (0, 0));
        assert_eq!(*path.last().unwrap(), (4, 0));
        // Path must go through (2,4)
        assert!(path.contains(&(2, 4)));
    }

    #[test]
    fn astar_and_dijkstra_same_simple() {
        let grid = Grid::new(5, 5, 1.0);
        let pa = grid.find_path_astar(0, 0, 4, 4, false).unwrap();
        let pd = grid.find_path_dijkstra(0, 0, 4, 4, false).unwrap();
        // Both should find a path of equal length
        assert_eq!(pa.len(), pd.len());
        assert_eq!(*pa.first().unwrap(), *pd.first().unwrap());
        assert_eq!(*pa.last().unwrap(), *pd.last().unwrap());
    }

    #[test]
    fn bfs_finds_shortest_hop() {
        let grid = Grid::new(3, 3, 1.0);
        let path = grid.find_path_bfs(0, 0, 2, 2, false).unwrap();
        // Manhattan shortest = 5 nodes
        assert_eq!(path.len(), 5);
    }

    #[test]
    fn flow_field_directions() {
        let grid = Grid::new(3, 3, 1.0);
        let field = grid.build_flow_field(2, 2);
        // Cell (1,2) should point right toward (2,2)
        let idx = 2 * 3 + 1; // y=2, x=1
        assert!((field[idx].0 - 1.0).abs() < 1e-5);
        assert!((field[idx].1 - 0.0).abs() < 1e-5);
        // Goal cell (2,2) should be (0,0)
        let gi = 2 * 3 + 2;
        assert!((field[gi].0).abs() < 1e-5);
        assert!((field[gi].1).abs() < 1e-5);
    }

    #[test]
    fn walkability_and_cost() {
        let mut grid = Grid::new(3, 3, 1.0);
        assert!(grid.is_walkable(1, 1));
        grid.set_walkable(1, 1, false);
        assert!(!grid.is_walkable(1, 1));
        grid.set_cost(0, 0, 5.0);
        assert!((grid.get_cost(0, 0) - 5.0).abs() < 1e-5);
    }
}
