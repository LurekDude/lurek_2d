//! Integration tests for luna2d::<module>.

use luna2d::<module>::SomeType;

// ── Basic Construction ────────────────────────────────────────────────────────

#[test]
fn new_creates_default_state() {
    let t = SomeType::new();
    assert_eq!(t.count(), 0);
}

// ── Boundary Conditions ───────────────────────────────────────────────────────

#[test]
fn zero_input_returns_identity() {
    let result = SomeType::transform(0.0, 0.0);
    assert!((result - 0.0).abs() < 1e-5);
}
