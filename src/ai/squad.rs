//! Multi-agent formation groups with offset computation.
//!
//! A [`Squad`] groups named agents under an optional leader and computes
//! world-space formation positions relative to the leader's current location.
//! Five formation shapes are supported: `Line`, `Wedge`, `Circle`, `Column`,
//! and `None` (no formation — all members collapse to the leader's position).
//!
//! Squads also carry a shared [`Blackboard`] for intra-group communication.
//! The leader's blackboard and the squad blackboard are independent — link
//! them via parent-chain if you need automatic fact propagation.

use crate::ai::blackboard::Blackboard;

/// Formation shapes for squad positioning.
///
/// Each variant determines how member offsets are computed relative to the
/// leader's position and the configurable `formation_spacing`.
///
/// Serialized to/from Lua as lowercase strings (`"line"`, `"wedge"`, etc.).
///
/// # Variants
/// - `None` — No formation.
/// - `Line` — Line variant.
/// - `Wedge` — Wedge variant.
/// - `Circle` — Circle variant.
/// - `Column` — Column variant.
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
    /// Parses a Lua string into a `FormationType`. Unrecognised strings
    /// default to `FormationType::None`.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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
    ///
    /// # Returns
    /// `&'static str`.
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
///
/// The squad tracks agent names (not owned `Agent` structs — those live in
/// [`AIWorld`](crate::ai::world::AIWorld)). Call
/// [`get_formation_position`](Self::get_formation_position) to compute
/// the ideal world-space position for each member given the leader's
/// current coordinates.
///
/// # Fields
/// - `name` — `String`.
/// - `members` — `Vec<String>`.
/// - `leader` — `Option<String>`.
/// - `formation` — `FormationType`.
/// - `formation_spacing` — `f32`.
/// - `blackboard` — `Blackboard`.
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
    /// Creates a new squad with no members, no leader, no formation,
    /// and a default spacing of 30 world units.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Computes the ideal world-space position for the member at `member_idx`
    /// given the leader's current position.
    ///
    /// The returned coordinates depend on the active [`FormationType`]:
    /// - **None**: returns `leader_pos` unchanged.
    /// - **Line**: horizontal spread centered on the leader.
    /// - **Wedge**: alternating left/right V behind the leader.
    /// - **Circle**: equal-angle arc around the leader.
    /// - **Column**: vertical stack behind the leader.
    ///
    /// # Parameters
    /// - `member_idx` — `usize`.
    /// - `leader_pos` — `(f32, f32)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
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
