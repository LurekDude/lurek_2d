//! INTERNAL ONLY: Rust-only tests for graph node storage and parsing.
//!
//! Public graph behavior reachable through `lurek.graph.*` is covered in Lua tests.
//! These Rust-only checks keep local node invariants and parsing behavior covered.

use lurek2d::graph::{ConversionRule, FlowMode, Node, OverflowPolicy};
use std::str::FromStr;

#[test]
fn test_new_node_defaults_factory() {
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
fn test_unlimited_capacity_never_full_negative_capacity() {
    let n = Node::new(1, "sink", -1);
    assert!(!n.is_full());
}

#[test]
fn test_is_full_when_capacity_reached() {
    let mut n = Node::new(1, "bin", 2);
    n.items.push(100);
    assert!(!n.is_full());
    n.items.push(101);
    assert!(n.is_full());
}

#[test]
fn test_tags_crud_updates_sorted_snapshot() {
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
fn test_supply_demand_crud_updates_values() {
    let mut n = Node::new(1, "mine", -1);
    n.add_supply("ore", 100);
    assert_eq!(n.get_available_supply("ore"), 100);
    assert_eq!(n.get_available_supply("gold"), 0);
    n.add_demand("food", 10, 5);
    assert!(n.get_demand("food").is_some());
    assert_eq!(n.get_demand("food").expect("food demand should exist").priority, 5);
    n.remove_supply("ore");
    assert_eq!(n.get_available_supply("ore"), 0);
    n.remove_demand("food");
    assert!(n.get_demand("food").is_none());
}

#[test]
fn test_conversion_rule_crud_tracks_by_input_type() {
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
fn test_queue_operations_respect_queue_capacity() {
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
fn test_overflow_policy_parse_rejects_unknown_value() {
    assert_eq!(
        OverflowPolicy::from_str("reject").expect("reject should parse"),
        OverflowPolicy::Reject
    );
    assert_eq!(
        OverflowPolicy::from_str("destroy").expect("destroy should parse"),
        OverflowPolicy::Destroy
    );
    assert_eq!(
        OverflowPolicy::from_str("queue").expect("queue should parse"),
        OverflowPolicy::Queue
    );
    assert!(OverflowPolicy::from_str("bad").is_err());
    assert_eq!(OverflowPolicy::Reject.to_str(), "reject");
}

#[test]
fn test_flow_mode_parse_rejects_unknown_value() {
    assert_eq!(
        FlowMode::from_str("passive").expect("passive should parse"),
        FlowMode::Passive
    );
    assert_eq!(FlowMode::from_str("push").expect("push should parse"), FlowMode::Push);
    assert_eq!(FlowMode::from_str("pull").expect("pull should parse"), FlowMode::Pull);
    assert_eq!(FlowMode::from_str("both").expect("both should parse"), FlowMode::Both);
    assert!(FlowMode::from_str("bad").is_err());
    assert_eq!(FlowMode::Both.to_str(), "both");
}
