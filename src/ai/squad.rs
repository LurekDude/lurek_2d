//! Multi-agent formation group with offset computation.

use crate::ai::blackboard::Blackboard;

/// Formation shapes for squad positioning.
///
/// # Variants
/// - `None` — None variant.
/// - `Line` — Line variant.
/// - `Wedge` — Wedge variant.
/// - `Circle` — Circle variant.
/// - `Column` — Column variant.
#[derive(Debug, Clone, PartialEq)]
pub enum FormationType {
    /// No formation — agents stay put.
    None,
    /// Horizontal line from leader position.
    Line,
    /// Alternating row V-shape.
    Wedge,
    /// Equal angle distribution around leader.
    Circle,
    /// Vertical column behind leader.
    Column,
}

impl FormationType {
    /// Parses from Lua string.
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

    /// Returns the Lua string representation.
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

/// Multi-agent formation group.
///
/// # Fields
/// - `name` — `String`.
/// - `members` — `Vec<String>`.
/// - `leader` — `Option<String>`.
/// - `formation` — `FormationType`.
/// - `formation_spacing` — `f32`.
/// - `blackboard` — `Blackboard`.
///
/// Computes formation offset positions relative to the leader's position.
pub struct Squad {
    /// Squad name.
    pub name: String,
    /// Agent names in the squad.
    pub members: Vec<String>,
    /// Name of the leader agent.
    pub leader: Option<String>,
    /// Active formation type.
    pub formation: FormationType,
    /// Spacing between formation positions.
    pub formation_spacing: f32,
    /// Squad-shared blackboard.
    pub blackboard: Blackboard,
}

impl Squad {
    /// Creates a new squad with the given name.
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

    /// Computes the ideal world-space position for a member at the given index.
    ///
    /// # Parameters
    /// - `member_idx` — `usize`.
    /// - `leader_pos` — `(f32, f32)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    /// `leader_pos` is the leader's current position.
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
