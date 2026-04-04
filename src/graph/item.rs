//! Graph item — a typed entity that flows through the network.

/// Where a `GraphItem` currently resides.
#[derive(Debug, Clone, PartialEq)]
pub enum ItemPosition {
    /// Sitting at a node.
    AtNode(u64),
    /// Travelling along an edge with a progress fraction in `[0, 1]`.
    InTransit {
        /// Edge the item is on.
        edge_id: u64,
        /// Travel progress `0.0` (just departed) to `1.0` (arrived).
        progress: f64,
    },
    /// Not placed anywhere yet.
    Unplaced,
}

/// A typed entity that flows through the graph network.
#[derive(Debug, Clone)]
pub struct GraphItem {
    /// Unique identifier.
    pub id: u64,
    /// Application-defined type tag (e.g. `"wood"`, `"gold"`).
    pub item_type: String,
    /// Time in seconds before the item decays. `-1.0` means no decay.
    pub decay_time: f64,
    /// Seconds of life remaining (decremented by simulation).
    pub remaining_life: f64,
    /// Whether the item is still alive.
    pub alive: bool,
    /// Priority for flow and delivery ordering.
    pub priority: i32,
    /// Current position in the graph.
    pub position: ItemPosition,
}

impl GraphItem {
    /// Create a new item with the given type and decay time.
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

    /// Mark the item as dead.
    pub fn kill(&mut self) {
        self.alive = false;
    }

    /// Whether the item is still alive.
    pub fn is_alive(&self) -> bool {
        self.alive
    }

    /// Get the item type.
    pub fn get_type(&self) -> &str {
        &self.item_type
    }

    /// Set the item type.
    pub fn set_type(&mut self, item_type: &str) {
        self.item_type = item_type.to_string();
    }

    /// Get the decay time (`-1.0` = no decay).
    pub fn get_decay_time(&self) -> f64 {
        self.decay_time
    }

    /// Set the decay time. Also resets remaining life if positive.
    pub fn set_decay_time(&mut self, t: f64) {
        self.decay_time = t;
        if t > 0.0 {
            self.remaining_life = t;
        }
    }

    /// Get remaining life in seconds.
    pub fn get_remaining_life(&self) -> f64 {
        self.remaining_life
    }

    /// Set remaining life in seconds.
    pub fn set_remaining_life(&mut self, t: f64) {
        self.remaining_life = t;
    }

    /// Get the priority value.
    pub fn get_priority(&self) -> i32 {
        self.priority
    }

    /// Set the priority value.
    pub fn set_priority(&mut self, p: i32) {
        self.priority = p;
    }

    /// Get the current position.
    pub fn get_position(&self) -> &ItemPosition {
        &self.position
    }

    /// Set the current position.
    pub fn set_position(&mut self, pos: ItemPosition) {
        self.position = pos;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_item_defaults() {
        let item = GraphItem::new(1, "wood", 10.0);
        assert_eq!(item.id, 1);
        assert_eq!(item.get_type(), "wood");
        assert!((item.get_decay_time() - 10.0).abs() < 1e-9);
        assert!((item.get_remaining_life() - 10.0).abs() < 1e-9);
        assert!(item.is_alive());
        assert_eq!(item.get_priority(), 0);
        assert_eq!(*item.get_position(), ItemPosition::Unplaced);
    }

    #[test]
    fn kill_item() {
        let mut item = GraphItem::new(2, "gold", -1.0);
        assert!(item.is_alive());
        item.kill();
        assert!(!item.is_alive());
    }

    #[test]
    fn set_type_and_priority() {
        let mut item = GraphItem::new(3, "stone", 5.0);
        item.set_type("iron");
        assert_eq!(item.get_type(), "iron");
        item.set_priority(10);
        assert_eq!(item.get_priority(), 10);
    }

    #[test]
    fn set_position() {
        let mut item = GraphItem::new(4, "x", -1.0);
        item.set_position(ItemPosition::AtNode(42));
        assert_eq!(*item.get_position(), ItemPosition::AtNode(42));
        item.set_position(ItemPosition::InTransit {
            edge_id: 7,
            progress: 0.5,
        });
        assert_eq!(
            *item.get_position(),
            ItemPosition::InTransit {
                edge_id: 7,
                progress: 0.5
            }
        );
    }

    #[test]
    fn no_decay() {
        let item = GraphItem::new(5, "eternal", -1.0);
        assert!((item.get_decay_time() - (-1.0)).abs() < 1e-9);
        assert!((item.get_remaining_life() - (-1.0)).abs() < 1e-9);
    }
}
