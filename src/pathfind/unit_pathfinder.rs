//! High-level pathfinder for sized game units: A\* with LRU cache, smoothing, partial paths, and reachability.
//! Wraps a shared `NavGrid` behind `Rc<RefCell>` and exposes waypoint-based path results.
//! Does not own Lua bindings; consumed by `src/lua_api/pathfind_api.rs`.

use crate::log_msg;
use crate::pathfind::astar;
use crate::pathfind::nav_grid::NavGrid;
use crate::runtime::log_messages::{UP01, UP02, UP03};
use std::cell::RefCell;
use std::collections::{HashMap, VecDeque};
use std::rc::Rc;
/// Grid cell coordinate returned as a path waypoint.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Waypoint {
    /// Column index.
    pub x: u32,
    /// Row index.
    pub y: u32,
}
/// LRU cache lookup key for a specific unit-size path request.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct CacheKey {
    /// Start column.
    x1: u32,
    /// Start row.
    y1: u32,
    /// Goal column.
    x2: u32,
    /// Goal row.
    y2: u32,
    /// Footprint side length used to compute walkability.
    unit_size: u32,
}
/// Stateful pathfinder for one unit type sharing a grid reference.
pub struct UnitPathfinder {
    /// Shared walkability grid.
    grid: Rc<RefCell<NavGrid>>,
    /// Cached path results keyed by `CacheKey`.
    cache: HashMap<CacheKey, Option<Vec<Waypoint>>>,
    /// Insertion-order key list used for LRU eviction.
    cache_order: Vec<CacheKey>,
    /// Whether path caching is active.
    cache_enabled: bool,
    /// Maximum number of cached entries before eviction.
    cache_max_size: usize,
}
/// All public and private methods for `UnitPathfinder`.
impl UnitPathfinder {
    /// Create a new pathfinder wrapping `grid` with caching enabled and a default max size of 1024.
    pub fn new(grid: Rc<RefCell<NavGrid>>) -> Self {
        log_msg!(debug, UP01);
        Self {
            grid,
            cache: HashMap::new(),
            cache_order: Vec::new(),
            cache_enabled: true,
            cache_max_size: 1024,
        }
    }
    /// Find a path from `(x1, y1)` to `(x2, y2)` for a unit of `unit_size`; return waypoints or `None`.
    pub fn find_path(
        &mut self,
        x1: u32,
        y1: u32,
        x2: u32,
        y2: u32,
        unit_size: u32,
    ) -> Option<Vec<Waypoint>> {
        let key = CacheKey {
            x1,
            y1,
            x2,
            y2,
            unit_size,
        };
        if self.cache_enabled {
            if let Some(cached) = self.cache.get(&key) {
                return cached.clone();
            }
        }
        let result = {
            let grid = self.grid.borrow();
            let (path, _complete) = astar::astar(&grid, (x1, y1), (x2, y2), unit_size, 0);
            path.map(|p| p.into_iter().map(|(x, y)| Waypoint { x, y }).collect())
        };
        if result.is_some() {
            log_msg!(debug, UP02, "({}, {}) -> ({}, {})", x1, y1, x2, y2);
        } else {
            log_msg!(warn, UP03, "({}, {}) -> ({}, {})", x1, y1, x2, y2);
        }
        if self.cache_enabled {
            self.cache_insert(key, result.clone());
        }
        result
    }
    /// Find a path then apply A\* string-pull smoothing; return waypoints or `None`.
    pub fn find_path_smooth(
        &mut self,
        x1: u32,
        y1: u32,
        x2: u32,
        y2: u32,
        unit_size: u32,
    ) -> Option<Vec<Waypoint>> {
        let grid = self.grid.borrow();
        let (path, _complete) = astar::astar(&grid, (x1, y1), (x2, y2), unit_size, 0);
        path.map(|p| {
            let smoothed = astar::smooth_path(&grid, &p, unit_size);
            smoothed
                .into_iter()
                .map(|(x, y)| Waypoint { x, y })
                .collect()
        })
    }
    /// Return the Euclidean length of `path` in cells.
    pub fn get_path_length(path: &[Waypoint]) -> f32 {
        let mut total = 0.0f32;
        for i in 1..path.len() {
            let dx = path[i].x as f32 - path[i - 1].x as f32;
            let dy = path[i].y as f32 - path[i - 1].y as f32;
            total += (dx * dx + dy * dy).sqrt();
        }
        total
    }
    /// Return the sum of `NavGrid` costs for all waypoints in `path`.
    pub fn get_path_cost(&self, path: &[Waypoint]) -> f32 {
        let grid = self.grid.borrow();
        let mut total = 0.0f32;
        for wp in path {
            total += grid.get_cost(wp.x, wp.y) as f32;
        }
        total
    }
    /// Run A\* limited to `max_nodes` expansions; return `(partial_path, reached_goal)`.
    pub fn find_partial_path(
        &self,
        x1: u32,
        y1: u32,
        x2: u32,
        y2: u32,
        max_nodes: u32,
        unit_size: u32,
    ) -> (Vec<Waypoint>, bool) {
        let grid = self.grid.borrow();
        let (path, complete) = astar::astar(&grid, (x1, y1), (x2, y2), unit_size, max_nodes);
        let waypoints = path
            .map(|p| p.into_iter().map(|(x, y)| Waypoint { x, y }).collect())
            .unwrap_or_default();
        (waypoints, complete)
    }
    /// BFS-search for the nearest `unit_size`-walkable cell within `max_radius` steps from `(x, y)`.
    pub fn find_nearest_walkable(
        &self,
        x: u32,
        y: u32,
        max_radius: u32,
        unit_size: u32,
    ) -> Option<(u32, u32)> {
        let grid = self.grid.borrow();
        if grid.is_walkable(x, y, unit_size) {
            return Some((x, y));
        }
        let (w, h) = grid.get_dimensions();
        let mut visited = vec![false; (w * h) as usize];
        let mut queue = VecDeque::new();
        visited[(y * w + x) as usize] = true;
        queue.push_back((x, y, 0u32));
        while let Some((cx, cy, dist)) = queue.pop_front() {
            if dist > max_radius {
                break;
            }
            if grid.is_walkable(cx, cy, unit_size) {
                return Some((cx, cy));
            }
            for (dx, dy) in [(-1i32, 0i32), (1, 0), (0, -1), (0, 1)] {
                let nx = cx as i32 + dx;
                let ny = cy as i32 + dy;
                if nx < 0 || ny < 0 || nx >= w as i32 || ny >= h as i32 {
                    continue;
                }
                let (nxu, nyu) = (nx as u32, ny as u32);
                let idx = (nyu * w + nxu) as usize;
                if !visited[idx] {
                    visited[idx] = true;
                    queue.push_back((nxu, nyu, dist + 1));
                }
            }
        }
        Option::None
    }
    /// Return true when `(x2, y2)` is reachable from `(x1, y1)` via BFS for a unit of `unit_size`.
    pub fn is_reachable(&self, x1: u32, y1: u32, x2: u32, y2: u32, unit_size: u32) -> bool {
        let grid = self.grid.borrow();
        let us = unit_size.max(1);
        if !grid.is_walkable(x1, y1, us) || !grid.is_walkable(x2, y2, us) {
            return false;
        }
        let (w, h) = grid.get_dimensions();
        let mut visited = vec![false; (w * h) as usize];
        let mut queue = VecDeque::new();
        visited[(y1 * w + x1) as usize] = true;
        queue.push_back((x1, y1));
        while let Some((cx, cy)) = queue.pop_front() {
            if cx == x2 && cy == y2 {
                return true;
            }
            for (nx, ny) in grid.neighbors(cx, cy) {
                if grid.is_walkable(nx, ny, us) {
                    let idx = (ny * w + nx) as usize;
                    if !visited[idx] {
                        visited[idx] = true;
                        queue.push_back((nx, ny));
                    }
                }
            }
        }
        false
    }
    /// Return the octile distance heuristic between two cell coordinates.
    pub fn heuristic_distance(x1: u32, y1: u32, x2: u32, y2: u32) -> f32 {
        let dx = (x1 as f32 - x2 as f32).abs();
        let dy = (y1 as f32 - y2 as f32).abs();
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * std::f32::consts::SQRT_2 + (max - min)
    }
    /// Return true when the Bresenham line from `(x1, y1)` to `(x2, y2)` passes only walkable cells for `unit_size`.
    pub fn line_of_sight(&self, x1: u32, y1: u32, x2: u32, y2: u32, unit_size: u32) -> bool {
        let grid = self.grid.borrow();
        astar::line_of_sight(&grid, x1, y1, x2, y2, unit_size)
    }
    /// Enable or disable path caching; clears existing cache when disabled.
    pub fn set_cache_enabled(&mut self, enabled: bool) {
        self.cache_enabled = enabled;
        if !enabled {
            self.cache.clear();
            self.cache_order.clear();
        }
    }
    /// Return true when path caching is currently enabled.
    pub fn is_cache_enabled(&self) -> bool {
        self.cache_enabled
    }
    /// Remove all cached paths.
    pub fn clear_cache(&mut self) {
        self.cache.clear();
        self.cache_order.clear();
    }
    /// Return the current number of cached entries.
    pub fn get_cache_size(&self) -> usize {
        self.cache.len()
    }
    /// Set the maximum cache size and evict old entries if needed.
    pub fn set_cache_max_size(&mut self, max_size: usize) {
        self.cache_max_size = max_size;
        self.evict();
    }
    /// Return a reference to the shared `NavGrid`.
    pub fn nav_grid(&self) -> &std::rc::Rc<std::cell::RefCell<NavGrid>> {
        &self.grid
    }
    /// Insert a path into the cache and trigger LRU eviction if over `cache_max_size`.
    fn cache_insert(&mut self, key: CacheKey, value: Option<Vec<Waypoint>>) {
        self.cache.insert(key, value);
        self.cache_order.push(key);
        self.evict();
    }
    /// Remove the oldest cache entry until the cache is at or below `cache_max_size`.
    fn evict(&mut self) {
        while self.cache.len() > self.cache_max_size && !self.cache_order.is_empty() {
            let oldest = self.cache_order.remove(0);
            self.cache.remove(&oldest);
        }
    }
}
