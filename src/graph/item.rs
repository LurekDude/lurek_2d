#[derive(Debug, Clone, PartialEq)]
pub enum ItemPosition {
    AtNode(u64),
    InTransit { edge_id: u64, progress: f64 },
    Unplaced,
}
#[derive(Debug, Clone)]
pub struct GraphItem {
    pub id: u64,
    pub item_type: String,
    pub decay_time: f64,
    pub remaining_life: f64,
    pub alive: bool,
    pub priority: i32,
    pub position: ItemPosition,
}
impl GraphItem {
    pub fn new(id: u64, item_type: &str, decay_time: f64) -> Self {
        Self {
            id,
            item_type: item_type.to_string(),
            decay_time,
            remaining_life: decay_time,
            alive: true,
            priority: 0,
            position: ItemPosition::Unplaced,
        }
    }
    pub fn kill(&mut self) {
        self.alive = false;
    }
    pub fn is_alive(&self) -> bool {
        self.alive
    }
    pub fn get_type(&self) -> &str {
        &self.item_type
    }
    pub fn set_type(&mut self, item_type: &str) {
        self.item_type = item_type.to_string();
    }
    pub fn get_decay_time(&self) -> f64 {
        self.decay_time
    }
    pub fn set_decay_time(&mut self, t: f64) {
        self.decay_time = t;
        if t > 0.0 {
            self.remaining_life = t;
        }
    }
    pub fn get_remaining_life(&self) -> f64 {
        self.remaining_life
    }
    pub fn set_remaining_life(&mut self, t: f64) {
        self.remaining_life = t;
    }
    pub fn get_priority(&self) -> i32 {
        self.priority
    }
    pub fn set_priority(&mut self, p: i32) {
        self.priority = p;
    }
    pub fn get_position(&self) -> &ItemPosition {
        &self.position
    }
    pub fn set_position(&mut self, pos: ItemPosition) {
        self.position = pos;
    }
}
