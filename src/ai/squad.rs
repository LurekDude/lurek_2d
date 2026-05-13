//! Scope: squad grouping, membership, and formation offset helpers.
//! This file defines squad-level metadata and geometric utilities for multi-agent coordinated movement.
//! It owns local formation layout calculations consumed by steering and tactical behavior layers.
use crate::ai::blackboard::Blackboard;

/// Formation shapes for squad positioning.
#[derive(Debug, Clone, PartialEq)]
pub enum FormationType {
    /// No formation — all members occupy the leader's position.
    None,
    /// Horizontal line centered on the leader. Members spread left/right.
    Line,
    /// V-shaped wedge with alternating left/right rows behind the leader.
    Wedge,
    /// Equal-angle circular distribution around the leader.
    Circle,
    /// Vertical column trailing directly behind the leader.
    Column,
}

impl FormationType {
    /// Parses a Lua string into a `FormationType`. Unrecognised strings default to `None`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "line" => Self::Line,
            "wedge" => Self::Wedge,
            "circle" => Self::Circle,
            "column" => Self::Column,
            _ => Self::None,
        }
    }

    /// Returns the canonical lowercase Lua string for this formation type.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Line => "line",
            Self::Wedge => "wedge",
            Self::Circle => "circle",
            Self::Column => "column",
        }
    }
}

/// A named group of agents with formation positioning and shared state.
pub struct Squad {
    /// Human-readable squad identifier.
    pub name: String,
    /// Agent names belonging to this squad (insertion order).
    pub members: Vec<String>,
    /// Name of the designated leader, if any.
    pub leader: Option<String>,
    /// Current formation shape.
    pub formation: FormationType,
    /// World-unit distance between adjacent formation slots.
    pub formation_spacing: f32,
    /// Shared key-value store accessible to all squad members.
    pub blackboard: Blackboard,
}

impl Squad {
    /// Creates a new squad with no members, no leader, and default formation spacing of 30 world units.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            members: Vec::new(),
            leader: None,
            formation: FormationType::None,
            formation_spacing: 30.0,
            blackboard: Blackboard::new(),
        }
    }

    /// Computes the ideal world-space position for the member at `member_idx` within the current formation, relative to `leader_pos`.
    pub fn get_formation_position(&self, member_idx: usize, leader_pos: (f32, f32)) -> (f32, f32) {
        let spacing = self.formation_spacing;
        match self.formation {
            FormationType::None => leader_pos,
            FormationType::Line => {
                let offset =
                    (member_idx as f32 - (self.members.len() as f32 - 1.0) / 2.0) * spacing;
                (leader_pos.0 + offset, leader_pos.1)
            }
            FormationType::Column => {
                let offset = member_idx as f32 * spacing;
                (leader_pos.0, leader_pos.1 + offset)
            }
            FormationType::Wedge => {
                if member_idx == 0 {
                    return leader_pos;
                }
                let row = member_idx.div_ceil(2);
                let side = if member_idx % 2 == 1 { -1.0f32 } else { 1.0 };
                (
                    leader_pos.0 + side * row as f32 * spacing,
                    leader_pos.1 + row as f32 * spacing,
                )
            }
            FormationType::Circle => {
                if self.members.is_empty() {
                    return leader_pos;
                }
                let angle =
                    2.0 * std::f32::consts::PI * member_idx as f32 / self.members.len() as f32;
                let radius = spacing;
                (
                    leader_pos.0 + angle.cos() * radius,
                    leader_pos.1 + angle.sin() * radius,
                )
            }
        }
    }
}

