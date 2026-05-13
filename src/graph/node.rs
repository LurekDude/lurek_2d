use std::collections::{HashMap, HashSet, VecDeque};
use std::str::FromStr;
#[derive(Debug, Clone, PartialEq)]
pub enum OverflowPolicy {
    Reject,
    Destroy,
    Queue,
}
impl OverflowPolicy {
    pub fn to_str(&self) -> &str {
        match self {
            Self::Reject => "reject",
            Self::Destroy => "destroy",
            Self::Queue => "queue",
        }
    }
}
impl FromStr for OverflowPolicy {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "reject" => Ok(Self::Reject),
            "destroy" => Ok(Self::Destroy),
            "queue" => Ok(Self::Queue),
            _ => Err(format!("unknown overflow policy: '{s}'")),
        }
    }
}
#[derive(Debug, Clone, PartialEq)]
pub enum FlowMode {
    Passive,
    Push,
    Pull,
    Both,
}
impl FlowMode {
    pub fn to_str(&self) -> &str {
        match self {
            Self::Passive => "passive",
            Self::Push => "push",
            Self::Pull => "pull",
            Self::Both => "both",
        }
    }
}
impl FromStr for FlowMode {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "passive" => Ok(Self::Passive),
            "push" => Ok(Self::Push),
            "pull" => Ok(Self::Pull),
            "both" => Ok(Self::Both),
            _ => Err(format!("unknown flow mode: '{s}'")),
        }
    }
}
#[derive(Debug, Clone)]
pub struct ConversionRule {
    pub in_type: String,
    pub out_type: String,
    pub in_count: u32,
    pub out_count: u32,
}
#[derive(Debug, Clone)]
pub struct Supply {
    pub item_type: String,
    pub quantity: i32,
}
#[derive(Debug, Clone)]
pub struct Demand {
    pub item_type: String,
    pub quantity: i32,
    pub priority: i32,
}
pub struct Node {
    pub id: u64,
    pub node_type: String,
    pub capacity: i32,
    pub active: bool,
    pub overflow_policy: OverflowPolicy,
    pub flow_mode: FlowMode,
    pub push_rate: f64,
    pub pull_rate: f64,
    pub push_filter: Option<String>,
    pub pull_filter: Option<String>,
    pub process_time: f64,
    pub queue_enabled: bool,
    pub queue_capacity: i32,
    pub queue: VecDeque<u64>,
    pub items: Vec<u64>,
    pub conversions: HashMap<String, ConversionRule>,
    pub demands: Vec<Demand>,
    pub supplies: Vec<Supply>,
    pub tags: HashSet<String>,
    pub(crate) push_timer: f64,
    pub(crate) pull_timer: f64,
    pub(crate) process_accumulator: f64,
}
impl Node {
    pub fn new(id: u64, node_type: &str, capacity: i32) -> Self {
        Self {
            id,
            node_type: node_type.to_string(),
            capacity,
            active: true,
            overflow_policy: OverflowPolicy::Reject,
            flow_mode: FlowMode::Passive,
            push_rate: 1.0,
            pull_rate: 1.0,
            push_filter: None,
            pull_filter: None,
            process_time: 0.0,
            queue_enabled: false,
            queue_capacity: -1,
            queue: VecDeque::new(),
            items: Vec::new(),
            conversions: HashMap::new(),
            demands: Vec::new(),
            supplies: Vec::new(),
            tags: HashSet::new(),
            push_timer: 0.0,
            pull_timer: 0.0,
            process_accumulator: 0.0,
        }
    }
    pub fn get_type(&self) -> &str {
        &self.node_type
    }
    pub fn set_type(&mut self, t: &str) {
        self.node_type = t.to_string();
    }
    pub fn get_capacity(&self) -> i32 {
        self.capacity
    }
    pub fn set_capacity(&mut self, c: i32) {
        self.capacity = c;
    }
    pub fn is_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items.len() >= self.capacity as usize
        }
    }
    pub fn item_count(&self) -> usize {
        self.items.len()
    }
    pub fn add_tag(&mut self, tag: &str) {
        self.tags.insert(tag.to_string());
    }
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        self.tags.remove(tag)
    }
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.contains(tag)
    }
    pub fn clear_tags(&mut self) {
        self.tags.clear();
    }
    pub fn get_tags(&self) -> Vec<String> {
        let mut v: Vec<String> = self.tags.iter().cloned().collect();
        v.sort();
        v
    }
    pub fn add_supply(&mut self, item_type: &str, quantity: i32) {
        self.supplies.push(Supply {
            item_type: item_type.to_string(),
            quantity,
        });
    }
    pub fn remove_supply(&mut self, item_type: &str) -> bool {
        let before = self.supplies.len();
        self.supplies.retain(|s| s.item_type != item_type);
        self.supplies.len() < before
    }
    pub fn clear_supplies(&mut self) {
        self.supplies.clear();
    }
    pub fn get_supply(&self, item_type: &str) -> Option<&Supply> {
        self.supplies.iter().find(|s| s.item_type == item_type)
    }
    pub fn get_available_supply(&self, item_type: &str) -> i32 {
        self.supplies
            .iter()
            .filter(|s| s.item_type == item_type)
            .map(|s| s.quantity)
            .sum()
    }
    pub fn add_demand(&mut self, item_type: &str, quantity: i32, priority: i32) {
        self.demands.push(Demand {
            item_type: item_type.to_string(),
            quantity,
            priority,
        });
    }
    pub fn remove_demand(&mut self, item_type: &str) -> bool {
        let before = self.demands.len();
        self.demands.retain(|d| d.item_type != item_type);
        self.demands.len() < before
    }
    pub fn clear_demands(&mut self) {
        self.demands.clear();
    }
    pub fn get_demand(&self, item_type: &str) -> Option<&Demand> {
        self.demands.iter().find(|d| d.item_type == item_type)
    }
    pub fn set_conversion(&mut self, rule: ConversionRule) {
        self.conversions.insert(rule.in_type.clone(), rule);
    }
    pub fn clear_conversion(&mut self, in_type: &str) -> bool {
        self.conversions.remove(in_type).is_some()
    }
    pub fn clear_all_conversions(&mut self) {
        self.conversions.clear();
    }
    pub fn enqueue(&mut self, item_id: u64) -> bool {
        if self.queue_capacity >= 0 && self.queue.len() >= self.queue_capacity as usize {
            return false;
        }
        self.queue.push_back(item_id);
        true
    }
    pub fn dequeue(&mut self) -> Option<u64> {
        self.queue.pop_front()
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn new_node_defaults() {
        let n = Node::new(1, "factory", 10);
        assert_eq!(n.id, 1);
        assert_eq!(n.get_type(), "factory");
        assert_eq!(n.get_capacity(), 10);
        assert!(n.active);
        assert!(!n.is_full());
        assert_eq!(n.item_count(), 0);
        assert_eq!(n.overflow_policy, OverflowPolicy::Reject);
        assert_eq!(n.flow_mode, FlowMode::Passive);
    }
    #[test]
    fn unlimited_capacity_never_full() {
        let n = Node::new(1, "sink", -1);
        assert!(!n.is_full());
    }
    #[test]
    fn is_full_check() {
        let mut n = Node::new(1, "bin", 2);
        n.items.push(100);
        assert!(!n.is_full());
        n.items.push(101);
        assert!(n.is_full());
    }
    #[test]
    fn tags_crud() {
        let mut n = Node::new(1, "t", 5);
        n.add_tag("hot");
        n.add_tag("red");
        assert!(n.has_tag("hot"));
        assert!(!n.has_tag("cold"));
        assert_eq!(n.get_tags(), vec!["hot", "red"]);
        n.remove_tag("hot");
        assert!(!n.has_tag("hot"));
        n.clear_tags();
        assert!(n.get_tags().is_empty());
    }
    #[test]
    fn supply_demand() {
        let mut n = Node::new(1, "mine", -1);
        n.add_supply("ore", 100);
        assert_eq!(n.get_available_supply("ore"), 100);
        assert_eq!(n.get_available_supply("gold"), 0);
        n.add_demand("food", 10, 5);
        assert!(n.get_demand("food").is_some());
        assert_eq!(n.get_demand("food").unwrap().priority, 5);
        n.remove_supply("ore");
        assert_eq!(n.get_available_supply("ore"), 0);
        n.remove_demand("food");
        assert!(n.get_demand("food").is_none());
    }
    #[test]
    fn conversion_rule() {
        let mut n = Node::new(1, "smelter", 5);
        n.set_conversion(ConversionRule {
            in_type: "ore".into(),
            out_type: "ingot".into(),
            in_count: 2,
            out_count: 1,
        });
        assert!(n.conversions.contains_key("ore"));
        n.clear_conversion("ore");
        assert!(!n.conversions.contains_key("ore"));
    }
    #[test]
    fn queue_operations() {
        let mut n = Node::new(1, "q", 5);
        n.queue_capacity = 2;
        assert!(n.enqueue(10));
        assert!(n.enqueue(11));
        assert!(!n.enqueue(12));
        assert_eq!(n.dequeue(), Some(10));
        assert_eq!(n.dequeue(), Some(11));
        assert_eq!(n.dequeue(), None);
    }
    #[test]
    fn overflow_policy_parse() {
        assert_eq!(
            OverflowPolicy::from_str("reject").unwrap(),
            OverflowPolicy::Reject
        );
        assert_eq!(
            OverflowPolicy::from_str("destroy").unwrap(),
            OverflowPolicy::Destroy
        );
        assert_eq!(
            OverflowPolicy::from_str("queue").unwrap(),
            OverflowPolicy::Queue
        );
        assert!(OverflowPolicy::from_str("bad").is_err());
        assert_eq!(OverflowPolicy::Reject.to_str(), "reject");
    }
    #[test]
    fn flow_mode_parse() {
        assert_eq!(FlowMode::from_str("passive").unwrap(), FlowMode::Passive);
        assert_eq!(FlowMode::from_str("push").unwrap(), FlowMode::Push);
        assert_eq!(FlowMode::from_str("pull").unwrap(), FlowMode::Pull);
        assert_eq!(FlowMode::from_str("both").unwrap(), FlowMode::Both);
        assert!(FlowMode::from_str("bad").is_err());
        assert_eq!(FlowMode::Both.to_str(), "both");
    }
}
