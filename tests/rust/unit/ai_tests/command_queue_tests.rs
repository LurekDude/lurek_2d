//! Tests for the \$module_name\ AI module.
//! These tests verify type conversions, state transitions, and module invariants.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_queue_is_empty() {
        let q = CommandQueue::new();
        assert!(q.count() == 0);
        assert_eq!(q.count(), 0);
    }

    #[test]
    fn queue_cleared_after_clear() {
        let mut q = CommandQueue::new();
        q.clear();
        assert!(q.count() == 0);
    }
}