//! Container that owns agents and ticks them in descending priority order each frame.

use std::collections::HashMap;

use crate::ai::agent::Agent;
use crate::ai::blackboard::Blackboard;

/// Container that owns agents and ticks them each frame.
///
/// # Fields
/// - `agents` — `Vec<Agent>`.
/// - `name_index` — `HashMap<String, usize>`.
/// - `global_blackboard` — `Blackboard`.
///
/// Agents are stored in insertion order with a name→index HashMap for O(1) lookup.
/// `update(dt)` ticks all agents in descending priority order.
pub struct AIWorld {
    /// Agents stored in insertion order.
    pub(crate) agents: Vec<Agent>,
    /// Name→index mapping for O(1) lookup.
    pub(crate) name_index: HashMap<String, usize>,
    /// Global blackboard shared by all agents.
    pub(crate) global_blackboard: Blackboard,
}

impl AIWorld {
    /// Creates a new empty AIWorld.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            agents: Vec::new(),
            name_index: HashMap::new(),
            global_blackboard: Blackboard::new(),
        }
    }

    /// Adds a new agent with the given name. Returns the agent's index.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Result<usize, String>`.
    /// Errors if the name already exists.
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

    /// Removes an agent by name. Rebuilds the name→index map.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Returns the index of an agent by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn get_agent_index(&self, name: &str) -> Option<usize> {
        self.name_index.get(name).copied()
    }

    /// Returns the number of agents.
    ///
    /// # Returns
    /// `usize`.
    pub fn agent_count(&self) -> usize {
        self.agents.len()
    }

    /// Returns a reference to the global blackboard.
    ///
    /// # Returns
    /// `&Blackboard`.
    pub fn global_blackboard(&self) -> &Blackboard {
        &self.global_blackboard
    }

    /// Returns a mutable reference to the global blackboard.
    ///
    /// # Returns
    /// `&mut Blackboard`.
    pub fn global_blackboard_mut(&mut self) -> &mut Blackboard {
        &mut self.global_blackboard
    }
}

impl Default for AIWorld {
    fn default() -> Self {
        Self::new()
    }
}
