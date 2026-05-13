use super::Universe;
use mlua::{Lua, Result as LuaResult, Table, Value as LuaValue};
impl Universe {
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
    pub fn get_sorted_system_indices_all(&self) -> Vec<usize> {
        let count = self.system_priorities.len();
        let mut order: Vec<usize> = (1..=count).collect();
        order.sort_by_key(|&i| self.system_priorities[i - 1]);
        order
    }
    pub fn get_sorted_system_indices_for_phase(&self, phase: &str) -> Vec<usize> {
        let target = if phase.is_empty() { "update" } else { phase };
        let count = self.system_priorities.len();
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
        candidates.sort_by_key(|&i| self.system_priorities[i - 1]);
        self.topo_sort_indices(candidates)
    }
    fn topo_sort_indices(&self, candidates: Vec<usize>) -> Vec<usize> {
        let n = candidates.len();
        if n <= 1 {
            return candidates;
        }
        let pos_of: std::collections::HashMap<usize, usize> = candidates
            .iter()
            .enumerate()
            .map(|(p, &idx)| (idx, p))
            .collect();
        let mut in_degree = vec![0usize; n];
        let mut adj: Vec<Vec<usize>> = vec![Vec::new(); n];
        for (pos_b, &idx_b) in candidates.iter().enumerate() {
            for dep_name in &self.system_deps[idx_b - 1] {
                if let Some((&idx_a, &pos_a)) = pos_of.iter().find(|(&idx, _)| {
                    self.system_names.get(idx - 1).map(|s| s.as_str()) == Some(dep_name.as_str())
                }) {
                    let _ = idx_a;
                    adj[pos_a].push(pos_b);
                    in_degree[pos_b] += 1;
                }
            }
        }
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
        if result.len() < n {
            for &idx in &candidates {
                if !result.contains(&idx) {
                    result.push(idx);
                }
            }
        }
        result
    }
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
                let vi = i - 1;
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
    pub fn get_system_count(&self, lua: &Lua) -> LuaResult<usize> {
        if let Some(ref key) = self.system_store {
            let store: Table = lua.registry_value(key)?;
            Ok(store.raw_len())
        } else {
            Ok(0)
        }
    }
}
