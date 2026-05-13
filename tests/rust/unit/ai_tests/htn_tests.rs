//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_domain() -> HTNDomain {
        let mut d = HTNDomain::new();
        d.register(HTNTask::Primitive {
            name: "eat".into(),
            preconditions: vec!["hungry".into()],
            effects: vec!["fed".into()],
            effects_clear: vec!["hungry".into()],
        });
        d.register(HTNTask::Compound {
            name: "satisfy_hunger".into(),
            methods: vec![HTNMethod {
                name: "use_eat".into(),
                preconditions: vec!["hungry".into()],
                sub_tasks: vec!["eat".into()],
            }],
        });
        d
    }

    #[test]
    fn decompose_single_primitive() {
        let d = sample_domain();
        let mut state = HashMap::new();
        state.insert("hungry".to_string(), 1.0_f32);
        let plan = HTNPlanner::plan(&d, "eat", &state);
        assert!(plan.is_some());
        assert_eq!(plan.unwrap(), vec!["eat"]);
    }

    #[test]
    fn decompose_compound_task() {
        let d = sample_domain();
        let mut state = HashMap::new();
        state.insert("hungry".to_string(), 1.0_f32);
        let plan = HTNPlanner::plan(&d, "satisfy_hunger", &state);
        assert!(plan.is_some());
        assert_eq!(plan.unwrap(), vec!["eat"]);
    }

    #[test]
    fn precondition_not_met_returns_none() {
        let d = sample_domain();
        let state = HashMap::new(); // hungry not set
        let plan = HTNPlanner::plan(&d, "eat", &state);
        assert!(plan.is_none());
    }
}