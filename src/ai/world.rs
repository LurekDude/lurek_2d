//! AI world container and subsystem orchestration update path.
use std::collections::HashMap;

use crate::ai::agent::Agent;
use crate::ai::blackboard::Blackboard;

/// Top-level AI container that owns agents and provides global shared state.
pub struct AIWorld {
    /// Agents stored in insertion order.
    pub(crate) agents: Vec<Agent>,
    /// Name-index mapping for O(1) lookup.
    pub(crate) name_index: HashMap<String, usize>,
    /// Global blackboard shared by all agents.
    pub(crate) global_blackboard: Blackboard,
}

impl AIWorld {
    /// Create a new empty AIWorld.
    pub fn new() -> Self {
        Self {
            agents: Vec::new(),
            name_index: HashMap::new(),
            global_blackboard: Blackboard::new(),
        }
    }

    /// Add a new agent with the given name. Returns the agent's index.
    pub fn add_agent(&mut self, name: &str) -> Result<usize, String> {
        if self.name_index.contains_key(name) {
            return Err(format!("Agent '{}' already exists", name));
        }
        let idx = self.agents.len();
        let mut agent = Agent::new(name);
        // Wire parent blackboard to global
        agent.blackboard.set_parent(self.global_blackboard.clone());
        self.agents.push(agent);
        self.name_index.insert(name.to_string(), idx);
        Ok(idx)
    }

    /// Remove an agent by name. Rebuilds the name-index map.
    pub fn remove_agent(&mut self, name: &str) -> bool {
        if let Some(&idx) = self.name_index.get(name) {
            self.agents.remove(idx);
            // Rebuild index map
            self.name_index.clear();
            for (i, agent) in self.agents.iter().enumerate() {
                self.name_index.insert(agent.name.clone(), i);
            }
            true
        } else {
            false
        }
    }

    /// Return the index of an agent by name.
    pub fn get_agent_index(&self, name: &str) -> Option<usize> {
        self.name_index.get(name).copied()
    }

    /// Return the number of agents.
    pub fn agent_count(&self) -> usize {
        self.agents.len()
    }

    /// Return a reference to the global blackboard.
    pub fn global_blackboard(&self) -> &Blackboard {
        &self.global_blackboard
    }

    /// Return a mutable reference to the global blackboard.
    pub fn global_blackboard_mut(&mut self) -> &mut Blackboard {
        &mut self.global_blackboard
    }

    /// Advances all agents by `dt` seconds, integrating velocity into position.
    pub fn update(&mut self, dt: f32) {
        for agent in &mut self.agents {
            agent.position.0 += agent.velocity.0 * dt;
            agent.position.1 += agent.velocity.1 * dt;
        }
    }
}

impl Default for AIWorld {
    fn default() -> Self {
        Self::new()
    }
}

