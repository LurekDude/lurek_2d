use crate::log_msg;
use crate::pathfind::astar;
use crate::pathfind::nav_grid::NavGrid;
use crate::runtime::log_messages::{UP01, UP02, UP03};
use std::cell::RefCell;
use std::collections::{HashMap, VecDeque};
use std::rc::Rc;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Waypoint {
    pub x: u32,
    pub y: u32,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct CacheKey {
    x1: u32,
    y1: u32,
    x2: u32,
    y2: u32,
    unit_size: u32,
}
pub struct UnitPathfinder {
    grid: Rc<RefCell<NavGrid>>,
    cache: HashMap<CacheKey, Option<Vec<Waypoint>>>,
    cache_order: Vec<CacheKey>,
    cache_enabled: bool,
    cache_max_size: usize,
}
impl UnitPathfinder {
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
    pub fn get_path_length(path: &[Waypoint]) -> f32 {
        let mut total = 0.0f32;
        for i in 1..path.len() {
            let dx = path[i].x as f32 - path[i - 1].x as f32;
            let dy = path[i].y as f32 - path[i - 1].y as f32;
            total += (dx * dx + dy * dy).sqrt();
        }
        total
    }
    pub fn get_path_cost(&self, path: &[Waypoint]) -> f32 {
        let grid = self.grid.borrow();
        let mut total = 0.0f32;
        for wp in path {
            total += grid.get_cost(wp.x, wp.y) as f32;
        }
        total
    }
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
    pub fn heuristic_distance(x1: u32, y1: u32, x2: u32, y2: u32) -> f32 {
        let dx = (x1 as f32 - x2 as f32).abs();
        let dy = (y1 as f32 - y2 as f32).abs();
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * std::f32::consts::SQRT_2 + (max - min)
    }
    pub fn line_of_sight(&self, x1: u32, y1: u32, x2: u32, y2: u32, unit_size: u32) -> bool {
        let grid = self.grid.borrow();
        astar::line_of_sight(&grid, x1, y1, x2, y2, unit_size)
    }
    pub fn set_cache_enabled(&mut self, enabled: bool) {
        self.cache_enabled = enabled;
        if !enabled {
            self.cache.clear();
            self.cache_order.clear();
        }
    }
    pub fn is_cache_enabled(&self) -> bool {
        self.cache_enabled
    }
    pub fn clear_cache(&mut self) {
        self.cache.clear();
        self.cache_order.clear();
    }
    pub fn get_cache_size(&self) -> usize {
        self.cache.len()
    }
    pub fn set_cache_max_size(&mut self, max_size: usize) {
        self.cache_max_size = max_size;
        self.evict();
    }
    pub fn nav_grid(&self) -> &std::rc::Rc<std::cell::RefCell<NavGrid>> {
        &self.grid
    }
    fn cache_insert(&mut self, key: CacheKey, value: Option<Vec<Waypoint>>) {
        self.cache.insert(key, value);
        self.cache_order.push(key);
        self.evict();
    }
    fn evict(&mut self) {
        while self.cache.len() > self.cache_max_size && !self.cache_order.is_empty() {
            let oldest = self.cache_order.remove(0);
            self.cache.remove(&oldest);
        }
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use crate::pathfind::nav_grid::NavGrid;
    use std::cell::RefCell;
    use std::rc::Rc;
    fn open_grid(w: u32, h: u32) -> Rc<RefCell<NavGrid>> {
        Rc::new(RefCell::new(NavGrid::new(w, h)))
    }
    #[test]
    fn find_path_trivial() {
        let g = open_grid(5, 5);
        let mut up = UnitPathfinder::new(g);
        let path = up.find_path(0, 0, 4, 4, 1);
        assert!(path.is_some());
    }
    #[test]
    fn cache_hit_returns_same_path() {
        let g = open_grid(5, 5);
        let mut up = UnitPathfinder::new(g);
        let p1 = up.find_path(0, 0, 4, 4, 1).unwrap();
        let p2 = up.find_path(0, 0, 4, 4, 1).unwrap();
        assert_eq!(p1, p2);
    }
    #[test]
    fn path_through_blocked_returns_none() {
        let g_inner = NavGrid::new(3, 1);
        let g = Rc::new(RefCell::new(g_inner));
        g.borrow_mut().set_blocked(1, 0, true);
        let mut up = UnitPathfinder::new(g);
        assert!(up.find_path(0, 0, 2, 0, 1).is_none());
    }
}
