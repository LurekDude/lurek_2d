# Lurek2D — Rust Integration Tests

All Rust test binaries live here. They are registered explicitly in `Cargo.toml` under `[[test]]` entries and run via `cargo test`.

## Directories

| Directory | Purpose | Cargo.toml name |
|---|---|---|
| `unit/` | Per-module unit tests — one file per `src/<module>` | `<module>_tests` |
| `ext/` | Tier-2 extension module tests | `<module>_tests` |
| `game/` | Full game-loop integration tests | `game_tests` / similar |
| `stress/` | Performance and load tests | `stress_*` |
| `golden/` | Deterministic output golden tests + screenshots | `golden_tests` |
| `security/` | Security / sandboxing tests | `security_tests` |
| `config/` | Engine configuration parsing tests | `config_tests` |
| `fixtures/` | Test asset files shared between Rust tests | *(not a test binary)* |

## Naming Convention

Test function names follow `<subject>_<scenario>_<expected>` — no `test_` prefix.

```rust
#[test]
fn vec2_add_components_sum() { ... }   // ✓

#[test]
fn test_vec2_add() { ... }             // ✗ — avoid test_ prefix
```

## Float Comparisons

Never use `assert_eq!` on `f32` — always use an epsilon comparison:

```rust
assert!((result - expected).abs() < 1e-5, "got {result}, expected {expected}");
```

## Golden Tests (`golden/`)

Golden tests capture deterministic rendered or computed output and compare against
expected files stored in `golden/expected/`.

### Helpers

```rust
// Compare bytes against expected/<category>/<name>.bin
assert_golden(name, bytes: &[u8]);

// Compare text against expected/<category>/<name>.txt
assert_golden_text(name, text: &str);

// Save a PNG visual evidence file to golden/screenshots/<name>.png
save_test_screenshot(name, img: &ImageData);
```

### Baseline mode

On first run, if an expected file does not exist it is created (baseline pass).
On subsequent runs the output must match exactly.

Expected files and screenshots are tracked in git as visual regression evidence.

### Adding a golden test

1. Add a `#[test]` function to `tests/rust/golden/harness.rs`
2. Call `assert_golden_text("category/my_test", &format!("{:?}", my_value))`
3. Run once to create the baseline: `cargo test --test golden_tests my_test`
4. Commit `tests/rust/golden/expected/category/my_test.txt` together with the test

## Registering a New Test File

Add an entry to `Cargo.toml`:

```toml
[[test]]
name = "mymodule_tests"
path = "tests/rust/unit/mymodule_tests.rs"
harness = true
```

Then run: `cargo test --test mymodule_tests`

## Constraints

- Tests must not create windows, start audio playback, or spawn GPU devices
- Tests must not write outside `target/` (exception: golden baselines on first run)
- `cargo test` (no flags) must pass all tests before any commit
