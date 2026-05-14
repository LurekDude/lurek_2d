
use crate::ai::blackboard::Blackboard;
/// Supported squad formation shapes.
#[derive(Debug, Clone, PartialEq)]
pub enum FormationType {
    /// No formation offset.
    None,
    /// Members spread horizontally around the leader.
    Line,
    /// Members stack vertically behind the leader.
    Wedge,
    /// Members orbit the leader in a circle.
    Circle,
    /// Members stack vertically behind the leader.
    Column,
}
impl FormationType {
    /// Parse a lowercase formation name; unknown strings map to `None`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "line" => Self::Line,
            "wedge" => Self::Wedge,
            "circle" => Self::Circle,
            "column" => Self::Column,
            _ => Self::None,
        }
    }
    /// Return the canonical lowercase formation name.
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
/// Squad membership, formation state, and local blackboard.
pub struct Squad {
    /// Squad name.
    pub name: String,
    /// Member names in formation order.
    pub members: Vec<String>,
    /// Optional leader name.
    pub leader: Option<String>,
    /// Selected formation type.
    pub formation: FormationType,
    /// Distance between adjacent members in pixels.
    pub formation_spacing: f32,
    /// Squad-local blackboard.
    pub blackboard: Blackboard,
}
impl Squad {
    /// Create an empty squad with default spacing.
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
    /// Return the target position for one member relative to a leader position.
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
