//! System registration, ordering, and dispatch helpers extracted from `universe.rs`.
//!
//! This file owns:
//! - `add_system` / `remove_system` / `get_system_count`
//! - Phase-based and dependency-aware index ordering
//!
//! All methods are `impl Universe` — included via `#[path = "universe_systems.rs"] mod systems;`
//! inside `universe.rs`, which re-exports them through the parent `impl` block.

use mlua::{Lua, Result as LuaResult, Table, Value as LuaValue};

use super::Universe;

impl Universe {
    // === Systems ===

    /// Adds a system (Lua table) to the system list at the given priority (lower = first).
    ///
    /// The optional `phase` string assigns the system to a named execution phase.
    /// An empty string is treated as `"update"`.
    ///
    /// The optional `name` and `after` entries inside `opts` enable dependency-aware ordering:
    /// - `name`  — stable identifier for this system (used by other systems' `after` lists).
    /// - `after` — array of system names this system must run after within its phase.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`
    /// - `system` — `Table`
    /// - `priority` — `i32` base priority (lower = earlier; applied after dependency sort)
    /// - `phase` — `String` phase name (`""` means `"update"`)
    /// - `name` — `String` optional stable system name (empty = anonymous)
    /// - `deps` — `Vec<String>` system names this system must run after
    pub fn add_system(
        &mut self,
        lua: &Lua,
        system: Table,
        priority: i32,
        phase: String,
        name: String,
        deps: Vec<String>,
    ) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        store.set(len + 1, system)?;
        self.system_priorities.push(priority);
        self.system_phases.push(phase);
        self.system_names.push(name);
        self.system_deps.push(deps);
        Ok(())
    }

    /// Returns all 1-based system store indices sorted by ascending priority across all phases.
    /// Used by `emit` which broadcasts to every registered system regardless of phase.
    pub fn get_sorted_system_indices_all(&self) -> Vec<usize> {
        let count = self.system_priorities.len();
        let mut order: Vec<usize> = (1..=count).collect();
        order.sort_by_key(|&i| self.system_priorities[i - 1]);
        order
    }

    /// Returns 1-based system store indices sorted first by dependency order then by priority,
    /// filtered to the given phase.
    ///
    /// Dependency sort:
    /// - A system with `after = ["A", "B"]` is placed after systems named `"A"` and `"B"`.
    /// - Cycles are silently broken by falling back to priority order for the offending systems.
    ///
    /// Backward-compatibility rule:
    /// Systems registered with no explicit phase run in both `"update"` and `"render"` dispatches.
    pub fn get_sorted_system_indices_for_phase(&self, phase: &str) -> Vec<usize> {
        let target = if phase.is_empty() { "update" } else { phase };
        let count = self.system_priorities.len();

        // Collect 1-based indices that belong to this phase.
        let mut candidates: Vec<usize> = (1..=count)
            .filter(|&i| {
                let p = &self.system_phases[i - 1];
                if p.is_empty() {
                    target == "update" || target == "render"
                } else {
                    p == target
                }
            })
            .collect();

        // Sort by base priority first so the dependency topo-sort is stable.
        candidates.sort_by_key(|&i| self.system_priorities[i - 1]);

        // Topological sort by dependencies (Kahn's algorithm, O(n²) — fine for ≤ 256 systems).
        self.topo_sort_indices(candidates)
    }

    /// Kahn-style topological sort for a candidate slice.
    ///
    /// The edge `A → B` ("A must come before B") is established when B's dep list
    /// contains A's name.  Nodes without names or without matching deps are left in
    /// their original (priority-sorted) position.
    fn topo_sort_indices(&self, candidates: Vec<usize>) -> Vec<usize> {
        let n = candidates.len();
        if n <= 1 {
            return candidates;
        }

        // Map from system index to position in candidates slice.
        let pos_of: std::collections::HashMap<usize, usize> = candidates
            .iter()
            .enumerate()
            .map(|(p, &idx)| (idx, p))
            .collect();

        // Build adjacency: for each candidate, count how many of its declared deps
        // also appear in this phase's candidate set.
        let mut in_degree = vec![0usize; n];
        let mut adj: Vec<Vec<usize>> = vec![Vec::new(); n]; // adj[a] → list of b's that must come after a

        for (pos_b, &idx_b) in candidates.iter().enumerate() {
            for dep_name in &self.system_deps[idx_b - 1] {
                // Find the system with this name in the candidate set.
                if let Some((&idx_a, &pos_a)) = pos_of.iter().find(|(&idx, _)| {
                    self.system_names.get(idx - 1).map(|s| s.as_str()) == Some(dep_name.as_str())
                }) {
                    let _ = idx_a; // suppress unused warning
                    adj[pos_a].push(pos_b);
                    in_degree[pos_b] += 1;
                }
            }
        }

        // Kahn: start with zero-in-degree nodes (already priority-sorted by input order).
        let mut queue: std::collections::VecDeque<usize> =
            (0..n).filter(|&p| in_degree[p] == 0).collect();
        let mut result = Vec::with_capacity(n);

        while let Some(p) = queue.pop_front() {
            result.push(candidates[p]);
            for &next in &adj[p] {
                in_degree[next] -= 1;
                if in_degree[next] == 0 {
                    queue.push_back(next);
                }
            }
        }

        // If a cycle existed, some nodes were left out — append them in priority order.
        if result.len() < n {
            for &idx in &candidates {
                if !result.contains(&idx) {
                    result.push(idx);
                }
            }
        }

        result
    }

    /// Removes a system by pointer identity from the system list.
    pub fn remove_system(&mut self, lua: &Lua, system: Table) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        let target_ptr = system.to_pointer();
        for i in 1..=len {
            let s: Table = store.get(i)?;
            if s.to_pointer() == target_ptr {
                for j in i..len {
                    let next: LuaValue = store.get(j + 1)?;
                    store.set(j, next)?;
                }
                store.set(len, LuaValue::Nil)?;
                let vi = i - 1; // 0-based
                if vi < self.system_priorities.len() {
                    self.system_priorities.remove(vi);
                }
                if vi < self.system_phases.len() {
                    self.system_phases.remove(vi);
                }
                if vi < self.system_names.len() {
                    self.system_names.remove(vi);
                }
                if vi < self.system_deps.len() {
                    self.system_deps.remove(vi);
                }
                return Ok(());
            }
        }
        Err(mlua::Error::runtime("System not registered"))
    }

    /// Returns the number of registered systems.
    pub fn get_system_count(&self, lua: &Lua) -> LuaResult<usize> {
        if let Some(ref key) = self.system_store {
            let store: Table = lua.registry_value(key)?;
            Ok(store.raw_len())
        } else {
            Ok(0)
        }
    }
}
