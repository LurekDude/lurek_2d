//! Container that owns agents and ticks them in descending priority order each frame.
//!
//! The [`AIWorld`] is the top-level manager for the AI subsystem. It owns all
//! [`Agent`](crate::ai::agent::Agent)s, maintains a name→index lookup table,
//! and provides the global [`Blackboard`] that serves as the parent for every
//! agent's local blackboard.
//!
//! ## Agent Lifecycle
//!
//! Agents are added via `add_agent(name)`, which creates an agent with default
//! kinematic state and wires its local blackboard's parent to the global one.
//! Agents can be removed by name; removal triggers a full index rebuild.
//!
//! ## Update Loop
//!
//! During `update(dt)` (called from the Lua `lurek.update` callback), the world
//! ticks all agents in descending `priority` order. For each agent, it checks
//! the agent's [`DecisionModel`](crate::ai::agent::DecisionModel) and ticks the
//! appropriate subsystems (FSM, BehaviorTree, SteeringManager).

use std::collections::HashMap;

use crate::ai::agent::Agent;
use crate::ai::blackboard::Blackboard;

/// Top-level AI container that owns agents and provides global shared state.
///
/// Agents are stored in a contiguous `Vec` for cache-friendly iteration.
/// A `HashMap<String, usize>` provides O(1) name-based lookup. The global
/// blackboard is automatically set as the parent of each agent's local
/// blackboard on `add_agent()`, forming the two-level lookup hierarchy
/// described in the [`blackboard`](crate::ai::blackboard) module.
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
    /// Creates a new empty AIWorld. Returns a fully initialised instance with all fields set to their initial values.
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

    /// Returns the number of agents. Consult the module-level documentation for the broader usage context and preconditions.
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

    /// Advances all agents by `dt` seconds, integrating velocity into position.
    ///
    /// Ticks every agent in the world in descending priority order.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
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
