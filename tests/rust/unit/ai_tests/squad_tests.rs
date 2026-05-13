//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_remove_member() {
        let mut s = Squad::new("alpha");
        s.formation = FormationType::Line;
        s.members.push("1".to_string());
        s.members.push("2".to_string());
        assert_eq!(s.members.len(), 2);
        s.members.retain(|m| m != "1");
        assert_eq!(s.members.len(), 1);
    }

    #[test]
    fn line_formation_positions() {
        let mut s = Squad::new("bravo");
        s.formation = FormationType::Line;
        s.members.push("0".to_string());
        s.members.push("1".to_string());
        s.formation_spacing = 10.0;
        let p0 = s.get_formation_position(0, (0.0, 0.0));
        let p1 = s.get_formation_position(1, (0.0, 0.0));
        // Line formation offsets along X axis, not Y
        assert!(
            (p0.0 - p1.0).abs() > 1.0,
            "different X positions in line formation"
        );
    }

    #[test]
    fn circle_formation_center() {
        let mut s = Squad::new("charlie");
        s.formation = FormationType::Circle;
        s.members.push("0".to_string());
        s.formation_spacing = 20.0;
        let pos = s.get_formation_position(0, (100.0, 100.0));
        let dist = ((pos.0 - 100.0).powi(2) + (pos.1 - 100.0).powi(2)).sqrt();
        assert!((dist - 20.0).abs() < 1e-3);
    }
}