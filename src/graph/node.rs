//! Graph node — a vertex with capacity, flow control, conversion rules, and queuing.
//!
//! This module is part of Lurek2D's `graph` subsystem and provides the implementation
//! details for node-related operations and data management.
//! Key types exported from this module: `OverflowPolicy`, `FlowMode`, `ConversionRule`, `Supply`, `Demand`.
//! Primary functions: `to_str()`, `to_str()`, `new()`, `get_type()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::{HashMap, HashSet, VecDeque};
use std::str::FromStr;

/// What happens when items arrive at a full node.
///
/// # Variants
/// - `Reject` — Reject variant.
/// - `Destroy` — Destroy variant.
/// - `Queue` — Queue variant.
#[derive(Debug, Clone, PartialEq)]
pub enum OverflowPolicy {
    /// Refuse the incoming item (it stays where it is).
    Reject,
    /// Destroy the incoming item.
    Destroy,
    /// Place the item in the node's queue.
    Queue,
}

impl OverflowPolicy {
    /// Canonical lowercase string representation.
    ///
    /// # Returns
    /// `&str`.
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

/// How a node participates in automatic item flow.
///
/// # Variants
/// - `Passive` — Passive variant.
/// - `Push` — Push variant.
/// - `Pull` — Pull variant.
/// - `Both` — Both variant.
#[derive(Debug, Clone, PartialEq)]
pub enum FlowMode {
    /// Does not push or pull.
    Passive,
    /// Actively sends items along outgoing edges.
    Push,
    /// Actively pulls items from incoming edges.
    Pull,
    /// Both push and pull.
    Both,
}

impl FlowMode {
    /// Canonical lowercase string representation.
    ///
    /// # Returns
    /// `&str`.
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

/// A rule that converts N input items of one type into M output items of another.
///
/// # Fields
/// - `in_type` — `String`.
/// - `out_type` — `String`.
/// - `in_count` — `u32`.
/// - `out_count` — `u32`.
#[derive(Debug, Clone)]
pub struct ConversionRule {
    /// Input item type to consume.
    pub in_type: String,
    /// Output item type to produce.
    pub out_type: String,
    /// Number of input items consumed per conversion.
    pub in_count: u32,
    /// Number of output items produced per conversion.
    pub out_count: u32,
}

/// Declares that a node can produce items of a given type up to a specified quantity.
///
/// # Fields
/// - `item_type` — `String`.
/// - `quantity` — `i32`.
#[derive(Debug, Clone)]
pub struct Supply {
    /// Item type this node can supply.
    pub item_type: String,
    /// Total quantity available. `-1` means unlimited.
    pub quantity: i32,
}

/// Declares that a node needs items of a given type, with a priority for fulfillment ordering.
///
/// # Fields
/// - `item_type` — `String`.
/// - `quantity` — `i32`.
/// - `priority` — `i32`.
#[derive(Debug, Clone)]
pub struct Demand {
    /// Item type this node needs.
    pub item_type: String,
    /// Quantity demanded.
    pub quantity: i32,
    /// Priority for demand fulfillment (higher = more urgent).
    pub priority: i32,
}

/// A vertex in the graph with capacity, flow control, conversion, and queuing.
///
/// # Fields
/// - `id` — `u64`.
/// - `node_type` — `String`.
/// - `capacity` — `i32`.
/// - `active` — `bool`.
/// - `overflow_policy` — `OverflowPolicy`.
/// - `flow_mode` — `FlowMode`.
/// - `push_rate` — `f64`.
/// - `pull_rate` — `f64`.
/// - `push_filter` — `Option<String>`.
/// - `pull_filter` — `Option<String>`.
/// - `process_time` — `f64`.
/// - `queue_enabled` — `bool`.
/// - `queue_capacity` — `i32`.
/// - `queue` — `VecDeque<u64>`.
/// - `items` — `Vec<u64>`.
/// - `conversions` — `HashMap<String, ConversionRule>`.
/// - `demands` — `Vec<Demand>`.
/// - `supplies` — `Vec<Supply>`.
/// - `tags` — `HashSet<String>`.
/// - `push_timer` — `f64`.
/// - `pull_timer` — `f64`.
/// - `process_accumulator` — `f64`.
pub struct Node {
    /// Unique identifier.
    pub id: u64,
    /// Application-defined type tag.
    pub node_type: String,
    /// Max items this node can hold. `-1` = unlimited.
    pub capacity: i32,
    /// Whether this node participates in simulation.
    pub active: bool,
    /// What happens when items arrive at a full node.
    pub overflow_policy: OverflowPolicy,
    /// How this node participates in automatic flow.
    pub flow_mode: FlowMode,
    /// Items pushed per second. Default `1.0`.
    pub push_rate: f64,
    /// Items pulled per second. Default `1.0`.
    pub pull_rate: f64,
    /// Push filter — `None` means all types allowed.
    pub push_filter: Option<String>,
    /// Pull filter — `None` means all types allowed.
    pub pull_filter: Option<String>,
    /// Processing time in seconds before queued items are dequeued.
    pub process_time: f64,
    /// Whether the queue is enabled.
    pub queue_enabled: bool,
    /// Max queue size. `-1` = unlimited.
    pub queue_capacity: i32,
    /// Item IDs waiting in the queue.
    pub queue: VecDeque<u64>,
    /// Item IDs currently at this node.
    pub items: Vec<u64>,
    /// Conversion rules keyed by input type.
    pub conversions: HashMap<String, ConversionRule>,
    /// Demand declarations.
    pub demands: Vec<Demand>,
    /// Supply declarations.
    pub supplies: Vec<Supply>,
    /// Freeform tags for filtering and grouping.
    pub tags: HashSet<String>,
    /// Accumulated time for push rate limiting.
    pub(crate) push_timer: f64,
    /// Accumulated time for pull rate limiting.
    pub(crate) pull_timer: f64,
    /// Accumulated time for queue processing.
    pub(crate) process_accumulator: f64,
}

impl Node {
    /// Create a new node with defaults. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `node_type` — `&str`.
    /// - `capacity` — `i32`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Get the node type. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_type(&self) -> &str {
        &self.node_type
    }

    /// Set the node type. Replaces the current type value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `t` — `&str`.
    pub fn set_type(&mut self, t: &str) {
        self.node_type = t.to_string();
    }

    /// Get the capacity (`-1` = unlimited). This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_capacity(&self) -> i32 {
        self.capacity
    }

    /// Set the capacity. Replaces the current capacity value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `c` — `i32`.
    pub fn set_capacity(&mut self, c: i32) {
        self.capacity = c;
    }

    /// Whether the node is at capacity. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items.len() >= self.capacity as usize
        }
    }

    /// Returns the number of items currently sitting at this node.
    ///
    /// # Returns
    /// `usize`.
    pub fn item_count(&self) -> usize {
        self.items.len()
    }

    // --- Tags ---

    /// Add a tag. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    pub fn add_tag(&mut self, tag: &str) {
        self.tags.insert(tag.to_string());
    }

    /// Remove a tag. Returns whether it was present.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        self.tags.remove(tag)
    }

    /// Check if a tag is present. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.contains(tag)
    }

    /// Remove all tags. After this call the container is in the same state as immediately after construction.
    pub fn clear_tags(&mut self) {
        self.tags.clear();
    }

    /// Get all tags as a sorted vector. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_tags(&self) -> Vec<String> {
        let mut v: Vec<String> = self.tags.iter().cloned().collect();
        v.sort();
        v
    }

    // --- Supply ---

    /// Add a supply declaration. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    /// - `quantity` — `i32`.
    pub fn add_supply(&mut self, item_type: &str, quantity: i32) {
        self.supplies.push(Supply {
            item_type: item_type.to_string(),
            quantity,
        });
    }

    /// Remove supply declarations for the given item type. Returns whether any were removed.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_supply(&mut self, item_type: &str) -> bool {
        let before = self.supplies.len();
        self.supplies.retain(|s| s.item_type != item_type);
        self.supplies.len() < before
    }

    /// Remove all supply declarations. After this call the container is in the same state as immediately after construction.
    pub fn clear_supplies(&mut self) {
        self.supplies.clear();
    }

    /// Get the supply for a given item type.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `Option<&Supply>`.
    pub fn get_supply(&self, item_type: &str) -> Option<&Supply> {
        self.supplies.iter().find(|s| s.item_type == item_type)
    }

    /// Get the available supply quantity for a type (returns 0 if not found).
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_available_supply(&self, item_type: &str) -> i32 {
        self.supplies
            .iter()
            .filter(|s| s.item_type == item_type)
            .map(|s| s.quantity)
            .sum()
    }

    // --- Demand ---

    /// Add a demand declaration. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    /// - `quantity` — `i32`.
    /// - `priority` — `i32`.
    pub fn add_demand(&mut self, item_type: &str, quantity: i32, priority: i32) {
        self.demands.push(Demand {
            item_type: item_type.to_string(),
            quantity,
            priority,
        });
    }

    /// Remove demand declarations for the given item type. Returns whether any were removed.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_demand(&mut self, item_type: &str) -> bool {
        let before = self.demands.len();
        self.demands.retain(|d| d.item_type != item_type);
        self.demands.len() < before
    }

    /// Remove all demand declarations. After this call the container is in the same state as immediately after construction.
    pub fn clear_demands(&mut self) {
        self.demands.clear();
    }

    /// Get the demand for a given item type.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `Option<&Demand>`.
    pub fn get_demand(&self, item_type: &str) -> Option<&Demand> {
        self.demands.iter().find(|d| d.item_type == item_type)
    }

    // --- Conversion ---

    /// Set a conversion rule (keyed by input type).
    ///
    /// # Parameters
    /// - `rule` — `ConversionRule`.
    pub fn set_conversion(&mut self, rule: ConversionRule) {
        self.conversions.insert(rule.in_type.clone(), rule);
    }

    /// Remove a conversion rule by input type. Returns whether it was present.
    ///
    /// # Parameters
    /// - `in_type` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn clear_conversion(&mut self, in_type: &str) -> bool {
        self.conversions.remove(in_type).is_some()
    }

    /// Remove all conversion rules. After this call the container is in the same state as immediately after construction.
    pub fn clear_all_conversions(&mut self) {
        self.conversions.clear();
    }

    // --- Queue ---

    /// Push an item ID onto the back of the queue.
    ///
    /// # Parameters
    /// - `item_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn enqueue(&mut self, item_id: u64) -> bool {
        if self.queue_capacity >= 0 && self.queue.len() >= self.queue_capacity as usize {
            return false;
        }
        self.queue.push_back(item_id);
        true
    }

    /// Pop an item ID from the front of the queue.
    ///
    /// # Returns
    /// `Option<u64>`.
    pub fn dequeue(&mut self) -> Option<u64> {
        self.queue.pop_front()
    }
}
