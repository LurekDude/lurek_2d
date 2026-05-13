//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn profile_set_get_clamped() {
        let mut p = TraitProfile::new();
        p.set("aggression", 0.5);
        assert!((p.get("aggression") - 0.5).abs() < 1e-6);
        p.set("aggression", 1.5);
        assert!((p.get("aggression") - 1.0).abs() < 1e-6);
    }

    #[test]
    fn modifier_affects_effective_value() {
        let mut p = TraitProfile::new();
        p.set("caution", 0.3);
        p.add_modifier("caution", 0.4, None, "buff");
        assert!((p.get("caution") - 0.7).abs() < 1e-6);
    }

    #[test]
    fn expired_modifier_ignored() {
        let mut p = TraitProfile::new();
        p.set("loyalty", 0.5);
        p.add_modifier("loyalty", 0.3, Some(1.0), "temp");
        p.update(2.0);
        assert!((p.get("loyalty") - 0.5).abs() < 1e-6);
    }

    #[test]
    fn unknown_trait_returns_zero() {
        let p = TraitProfile::new();
        assert_eq!(p.get("nonexistent"), 0.0);
    }

    #[test]
    fn archetype_creates_profile() {
        let mut arch = TraitArchetypes::new();
        let mut base = HashMap::new();
        base.insert("aggression".to_string(), 0.8);
        arch.register("berserker", base);
        let p = TraitProfile::from_archetype(&arch, "berserker", 0.0).unwrap();
        assert!((p.get("aggression") - 0.8).abs() < 1e-6);
    }
}