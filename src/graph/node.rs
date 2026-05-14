use std::collections::{HashMap, HashSet, VecDeque};
use std::str::FromStr;
/// Overflow behavior applied when a node reaches capacity.
#[derive(Debug, Clone, PartialEq)]
pub enum OverflowPolicy {
    /// Reject new items.
    Reject,
    /// Destroy new items.
    Destroy,
    /// Queue new items.
    Queue,
}
impl OverflowPolicy {
    /// Return the lowercase policy string.
    pub fn to_str(&self) -> &str {
        match self {
            Self::Reject => "reject",
            Self::Destroy => "destroy",
            Self::Queue => "queue",
        }
    }
}
/// Parse overflow policy values from strings.
impl FromStr for OverflowPolicy {
    type Err = String;
    /// Parse an overflow policy or return an error on unknown input.
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "reject" => Ok(Self::Reject),
            "destroy" => Ok(Self::Destroy),
            "queue" => Ok(Self::Queue),
            _ => Err(format!("unknown overflow policy: '{s}'")),
        }
    }
}
/// Flow behavior used by graph simulation.
#[derive(Debug, Clone, PartialEq)]
pub enum FlowMode {
    /// Node does not push or pull automatically.
    Passive,
    /// Node pushes items outward.
    Push,
    /// Node pulls items inward.
    Pull,
    /// Node both pushes and pulls.
    Both,
}
impl FlowMode {
    /// Return the lowercase flow mode string.
    pub fn to_str(&self) -> &str {
        match self {
            Self::Passive => "passive",
            Self::Push => "push",
            Self::Pull => "pull",
            Self::Both => "both",
        }
    }
}
/// Parse flow mode values from strings.
impl FromStr for FlowMode {
    type Err = String;
    /// Parse a flow mode or return an error on unknown input.
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
/// Item conversion rule stored on a node.
#[derive(Debug, Clone)]
pub struct ConversionRule {
    /// Input item type name.
    pub in_type: String,
    /// Output item type name.
    pub out_type: String,
    /// Number of input items consumed.
    pub in_count: u32,
    /// Number of output items produced.
    pub out_count: u32,
}
/// Available item supply stored on a node.
#[derive(Debug, Clone)]
pub struct Supply {
    /// Item type name.
    pub item_type: String,
    /// Quantity available for use.
    pub quantity: i32,
}
/// Requested item demand stored on a node.
#[derive(Debug, Clone)]
pub struct Demand {
    /// Item type name.
    pub item_type: String,
    /// Requested quantity.
    pub quantity: i32,
    /// Demand priority where larger values sort earlier.
    pub priority: i32,
}
/// Graph node with inventory, flow settings, and local processing state.
pub struct Node {
    /// Stable node identifier.
    pub id: u64,
    /// Node type name.
    pub node_type: String,
    /// Maximum item capacity, or negative for unlimited.
    pub capacity: i32,
    /// Flag that enables the node in simulation.
    pub active: bool,
    /// Overflow behavior when capacity is exceeded.
    pub overflow_policy: OverflowPolicy,
    /// Automatic push and pull mode.
    pub flow_mode: FlowMode,
    /// Push rate used by simulation.
    pub push_rate: f64,
    /// Pull rate used by simulation.
    pub pull_rate: f64,
    /// Optional item filter used for push behavior.
    pub push_filter: Option<String>,
    /// Optional item filter used for pull behavior.
    pub pull_filter: Option<String>,
    /// Processing time in seconds.
    pub process_time: f64,
    /// Flag that enables the queue.
    pub queue_enabled: bool,
    /// Queue capacity, or negative for unlimited.
    pub queue_capacity: i32,
    /// Pending queued item ids.
    pub queue: VecDeque<u64>,
    /// Item ids currently held on the node.
    pub items: Vec<u64>,
    /// Conversion rules keyed by input item type.
    pub conversions: HashMap<String, ConversionRule>,
    /// Current demands stored on the node.
    pub demands: Vec<Demand>,
    /// Current supplies stored on the node.
    pub supplies: Vec<Supply>,
    /// Arbitrary node tags.
    pub tags: HashSet<String>,
    /// Accumulated push timer state.
    pub(crate) push_timer: f64,
    /// Accumulated pull timer state.
    pub(crate) pull_timer: f64,
    /// Accumulated process timer state.
    pub(crate) process_accumulator: f64,
}
impl Node {
    /// Create a node with default flow settings and the supplied id, type, and capacity.
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
    /// Return the node type string.
    pub fn get_type(&self) -> &str {
        &self.node_type
    }
    /// Set the node type string.
    pub fn set_type(&mut self, t: &str) {
        self.node_type = t.to_string();
    }
    /// Return the node capacity.
    pub fn get_capacity(&self) -> i32 {
        self.capacity
    }
    /// Set the node capacity.
    pub fn set_capacity(&mut self, c: i32) {
        self.capacity = c;
    }
    /// Return true when the node is at or above capacity.
    pub fn is_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items.len() >= self.capacity as usize
        }
    }
    /// Return the number of items currently held on the node.
    pub fn item_count(&self) -> usize {
        self.items.len()
    }
    /// Add a tag to the node.
    pub fn add_tag(&mut self, tag: &str) {
        self.tags.insert(tag.to_string());
    }
    /// Remove a tag and return true when it existed.
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        self.tags.remove(tag)
    }
    /// Return true when the node has the supplied tag.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.contains(tag)
    }
    /// Remove all tags from the node.
    pub fn clear_tags(&mut self) {
        self.tags.clear();
    }
    /// Return all tags sorted in ascending order.
    pub fn get_tags(&self) -> Vec<String> {
        let mut v: Vec<String> = self.tags.iter().cloned().collect();
        v.sort();
        v
    }
    /// Add a supply record for an item type.
    pub fn add_supply(&mut self, item_type: &str, quantity: i32) {
        self.supplies.push(Supply {
            item_type: item_type.to_string(),
            quantity,
        });
    }
    /// Remove all supplies for an item type and return true when any were removed.
    pub fn remove_supply(&mut self, item_type: &str) -> bool {
        let before = self.supplies.len();
        self.supplies.retain(|s| s.item_type != item_type);
        self.supplies.len() < before
    }
    /// Remove all supply records.
    pub fn clear_supplies(&mut self) {
        self.supplies.clear();
    }
    /// Return the first supply record for an item type.
    pub fn get_supply(&self, item_type: &str) -> Option<&Supply> {
        self.supplies.iter().find(|s| s.item_type == item_type)
    }
    /// Sum all supply quantities for an item type.
    pub fn get_available_supply(&self, item_type: &str) -> i32 {
        self.supplies
            .iter()
            .filter(|s| s.item_type == item_type)
            .map(|s| s.quantity)
            .sum()
    }
    /// Add a demand record for an item type.
    pub fn add_demand(&mut self, item_type: &str, quantity: i32, priority: i32) {
        self.demands.push(Demand {
            item_type: item_type.to_string(),
            quantity,
            priority,
        });
    }
    /// Remove all demands for an item type and return true when any were removed.
    pub fn remove_demand(&mut self, item_type: &str) -> bool {
        let before = self.demands.len();
        self.demands.retain(|d| d.item_type != item_type);
        self.demands.len() < before
    }
    /// Remove all demand records.
    pub fn clear_demands(&mut self) {
        self.demands.clear();
    }
    /// Return the first demand record for an item type.
    pub fn get_demand(&self, item_type: &str) -> Option<&Demand> {
        self.demands.iter().find(|d| d.item_type == item_type)
    }
    /// Set or replace a conversion rule keyed by its input type.
    pub fn set_conversion(&mut self, rule: ConversionRule) {
        self.conversions.insert(rule.in_type.clone(), rule);
    }
    /// Remove a conversion rule and return true when it existed.
    pub fn clear_conversion(&mut self, in_type: &str) -> bool {
        self.conversions.remove(in_type).is_some()
    }
    /// Remove all conversion rules.
    pub fn clear_all_conversions(&mut self) {
        self.conversions.clear();
    }
    /// Enqueue an item id and return false when the queue is full.
    pub fn enqueue(&mut self, item_id: u64) -> bool {
        if self.queue_capacity >= 0 && self.queue.len() >= self.queue_capacity as usize {
            return false;
        }
        self.queue.push_back(item_id);
        true
    }
    /// Dequeue the oldest queued item id when one exists.
    pub fn dequeue(&mut self) -> Option<u64> {
        self.queue.pop_front()
    }
}
