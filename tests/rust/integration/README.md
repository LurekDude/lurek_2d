# tests/rust/unit — Rust Unit Tests

One test binary per engine module. Tests are headless — no GPU, audio device, or window.

## Naming

`<module>_tests.rs` — e.g. `physics_tests.rs`, `audio_tests.rs`

## Conventions

- Function naming: `<subject>_<scenario>_<expected>` — no `test_` prefix
- Float comparisons: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats
- All binaries registered in `Cargo.toml` under `[[test]]`

## Registration

Every file here must have a corresponding `[[test]]` entry in `Cargo.toml`.
