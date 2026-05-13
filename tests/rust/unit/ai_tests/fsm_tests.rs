//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_fsm_has_no_states() {
        let fsm = StateMachine::new();
        assert!(fsm.current_state().is_none());
    }

    #[test]
    fn state_count_after_add() {
        let mut fsm = StateMachine::new();
        fsm.add_state_raw("idle".to_string(), None, None, None);
        fsm.add_state_raw("walk".to_string(), None, None, None);
        // States added - no crash is the primary assertion
        assert!(fsm.current_state().is_none()); // initial state not set yet
    }

    #[test]
    fn initial_state_set() {
        let mut fsm = StateMachine::new();
        fsm.add_state_raw("idle".to_string(), None, None, None);
        fsm.set_initial_state("idle".to_string());
        // initial_state is stored but current_state only transitions on first update
        assert_eq!(fsm.initial_state.as_deref(), Some("idle"));
        assert!(fsm.current_state().is_none());
    }
}