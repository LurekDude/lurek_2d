//! Unit-aware pathfinder with result caching and convenience methods.
//!
//! This module is part of Lurek2D's `pathfinding` subsystem and provides the implementation
//! details for unit pathfinder-related operations and data management.
//! Key types exported from this module: `Waypoint`, `UnitPathfinder`.
//! Primary functions: `new()`, `find_path()`, `find_path_smooth()`, `get_path_length()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::collections::{HashMap, VecDeque};
use std::rc::Rc;

use crate::engine::log_messages::{UP01, UP02, UP03};
use crate::log_msg;
use crate::pathfinding::astar;
use crate::pathfinding::nav_grid::NavGrid;

/// A waypoint along a computed path. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `x` — `u32`.
/// - `y` — `u32`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Waypoint {
    /// Tile x-coordinate (0-based).
    pub x: u32,
    /// Tile y-coordinate (0-based).
    pub y: u32,
}

/// Cache key for path lookups.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct CacheKey {
    x1: u32,
    y1: u32,
    x2: u32,
    y2: u32,
    unit_size: u32,
}

/// A pathfinder that operates on a shared `NavGrid` with optional result caching.
///
/// # Fields
/// - `grid` — `Rc<RefCell<NavGrid>>`.
/// - `cache` — `HashMap<CacheKey`.
/// - `cache_order` — `Vec<CacheKey>`.
/// - `cache_enabled` — `bool`.
/// - `cache_max_size` — `usize`.
pub struct UnitPathfinder {
    /// Shared reference to the navigation grid.
    grid: Rc<RefCell<NavGrid>>,
    /// Cached path results keyed by start/goal/unit_size.
    cache: HashMap<CacheKey, Option<Vec<Waypoint>>>,
    /// LRU ordering of cache keys (most recent at the back).
    cache_order: Vec<CacheKey>,
    /// Whether caching is active.
    cache_enabled: bool,
    /// Maximum number of cached entries before eviction.
    cache_max_size: usize,
}

impl UnitPathfinder {
    /// Create a new pathfinder backed by `grid`.
    ///
    /// # Parameters
    /// - `grid` — `Rc<RefCell<NavGrid>>`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Find a path from `(x1, y1)` to `(x2, y2)` for a `unit_size×unit_size` unit.
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `Option<Vec<Waypoint>>`.
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

    /// Find a path and apply Theta★ line-of-sight smoothing.
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `Option<Vec<Waypoint>>`.
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

    /// Sum of euclidean distances between consecutive waypoints.
    ///
    /// # Parameters
    /// - `path` — `&[Waypoint]`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_path_length(path: &[Waypoint]) -> f32 {
        let mut total = 0.0f32;
        for i in 1..path.len() {
            let dx = path[i].x as f32 - path[i - 1].x as f32;
            let dy = path[i].y as f32 - path[i - 1].y as f32;
            total += (dx * dx + dy * dy).sqrt();
        }
        total
    }

    /// Sum of grid traversal costs along a path.
    ///
    /// # Parameters
    /// - `path` — `&[Waypoint]`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_path_cost(&self, path: &[Waypoint]) -> f32 {
        let grid = self.grid.borrow();
        let mut total = 0.0f32;
        for wp in path {
            total += grid.get_cost(wp.x, wp.y) as f32;
        }
        total
    }

    /// Search with a node expansion limit; returns `(path, complete)`.
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    /// - `max_nodes` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `(Vec<Waypoint>, bool)`.
    ///
    /// If the goal is unreachable within `max_nodes` expansions, the path
    /// leads to the closest expanded node and `complete` is `false`.
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

    /// Find the nearest walkable cell within `max_radius` of `(x, y)` using BFS.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `max_radius` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `Option<(u32, u32)>`.
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

            // Expand cardinal neighbours
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

    /// Quick connectivity check: can `(x2, y2)` be reached from `(x1, y1)`?
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Uses flood fill for an exact answer (no HPA* abstraction).
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

    /// Octile heuristic distance between two points.
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn heuristic_distance(x1: u32, y1: u32, x2: u32, y2: u32) -> f32 {
        let dx = (x1 as f32 - x2 as f32).abs();
        let dy = (y1 as f32 - y2 as f32).abs();
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * std::f32::consts::SQRT_2 + (max - min)
    }

    /// Line-of-sight check between two cells, respecting unit footprint.
    ///
    /// # Parameters
    /// - `x1` — `u32`.
    /// - `y1` — `u32`.
    /// - `x2` — `u32`.
    /// - `y2` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn line_of_sight(&self, x1: u32, y1: u32, x2: u32, y2: u32, unit_size: u32) -> bool {
        let grid = self.grid.borrow();
        astar::line_of_sight(&grid, x1, y1, x2, y2, unit_size)
    }

    /// Enable or disable path caching. Replaces the current cache enabled value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_cache_enabled(&mut self, enabled: bool) {
        self.cache_enabled = enabled;
        if !enabled {
            self.cache.clear();
            self.cache_order.clear();
        }
    }

    /// Returns `true` if caching is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_cache_enabled(&self) -> bool {
        self.cache_enabled
    }

    /// Remove all cached path results. After this call the container is in the same state as immediately after construction.
    pub fn clear_cache(&mut self) {
        self.cache.clear();
        self.cache_order.clear();
    }

    /// Number of entries currently in the cache.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_cache_size(&self) -> usize {
        self.cache.len()
    }

    /// Set the maximum cache size. Evicts oldest entries if over the new limit.
    ///
    /// # Parameters
    /// - `max_size` — `usize`.
    pub fn set_cache_max_size(&mut self, max_size: usize) {
        self.cache_max_size = max_size;
        self.evict();
    }

    /// Insert into cache with LRU eviction.
    fn cache_insert(&mut self, key: CacheKey, value: Option<Vec<Waypoint>>) {
        self.cache.insert(key, value);
        self.cache_order.push(key);
        self.evict();
    }

    /// Evict oldest entries until cache is within `cache_max_size`.
    fn evict(&mut self) {
        while self.cache.len() > self.cache_max_size && !self.cache_order.is_empty() {
            let oldest = self.cache_order.remove(0);
            self.cache.remove(&oldest);
        }
    }
}
