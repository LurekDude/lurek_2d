//! INTERNAL ONLY: Rust-only tests for data internals that are not exposed as `lurek.data.*`.

// ── ring_buffer ───────────────────────────────────────────────────────────────

mod ring_buffer_tests {
    use lurek2d::data::RingBuffer;

    #[test]
    fn zero_capacity_clamped_to_one() {
        let rb = RingBuffer::<i32>::new(0);
        assert_eq!(rb.capacity(), 1);
    }

    #[test]
    fn push_returns_true_when_space_available() {
        let mut rb = RingBuffer::new(2);
        assert!(rb.push(1));
        assert!(rb.push(2));
        assert!(!rb.push(3)); // full, overwrites
    }
}

// ── compress ──────────────────────────────────────────────────────────────────
