use std::collections::HashSet;
pub struct Edge {
    pub id: u64,
    pub edge_type: String,
    pub from_node: u64,
    pub to_node: u64,
    pub capacity: i32,
    pub throughput: f64,
    pub travel_time: f64,
    pub weight: f64,
    pub speed_modifier: f64,
    pub cooldown: f64,
    pub cooldown_timer: f64,
    pub bidirectional: bool,
    pub active: bool,
    pub allowed_types: HashSet<String>,
    pub items_in_transit: Vec<u64>,
}
impl Edge {
    pub fn new(id: u64, from: u64, to: u64, edge_type: &str) -> Self {
        Self {
            id,
            edge_type: edge_type.to_string(),
            from_node: from,
            to_node: to,
            capacity: -1,
            throughput: 1.0,
            travel_time: 1.0,
            weight: 1.0,
            speed_modifier: 1.0,
            cooldown: 0.0,
            cooldown_timer: 0.0,
            bidirectional: false,
            active: true,
            allowed_types: HashSet::new(),
            items_in_transit: Vec::new(),
        }
    }
    pub fn get_type(&self) -> &str {
        &self.edge_type
    }
    pub fn set_type(&mut self, t: &str) {
        self.edge_type = t.to_string();
    }
    pub fn is_on_cooldown(&self) -> bool {
        self.cooldown_timer > 0.0
    }
    pub fn is_item_type_allowed(&self, t: &str) -> bool {
        self.allowed_types.is_empty() || self.allowed_types.contains(t)
    }
    pub fn add_allowed_type(&mut self, t: &str) {
        self.allowed_types.insert(t.to_string());
    }
    pub fn remove_allowed_type(&mut self, t: &str) -> bool {
        self.allowed_types.remove(t)
    }
    pub fn clear_allowed_types(&mut self) {
        self.allowed_types.clear();
    }
    pub fn is_transit_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items_in_transit.len() >= self.capacity as usize
        }
    }
}
