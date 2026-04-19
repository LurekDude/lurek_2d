---
name: testing-rust
description: "Load this skill when writing or organizing tests for the Lurek2D engine. It owns test patterns, float comparison strategies, test naming, and integration test architecture for both Rust and Lua BDD tests. Skip it for writing production code."
---
# testing-rust

## Mission

# Testing — Lurek2D Engine

## When To Load

- Writing new tests in `tests/` or `tests/lua/`
- Adding a Lua test registration entry to `tests/lua/harness.rs`
- Reviewing or improving test coverage for a module
- Fixing test failures or flaky tests
- Organizing or auditing test structure
- Running quality gates before a commit

## When To Skip

- Fixing production bugs found by tests → route to Developer
- Performance benchmarking → `performance-profiling` skill
- CI/CD pipeline setup → `ci-cd-pipeline` skill
- Lua API design → `lua-api-design` skill
---

## Domain Knowledge

### Owns
- Rust integration test patterns (`tests/<module>_tests.rs`)
- Lua BDD test patterns and framework API (`tests/lua/*/test_*.lua`)
- Harness registration (`tests/lua/harness.rs`)
- Float comparison strategy (Rust and Lua)
- Test naming conventions
- Coverage tools

### 1. Test Architecture Overview
Lurek2D has a **two-layer test system** that runs entirely via `cargo test`:

| Layer | Location | Runner |
|---|---|---|
| Rust integration | `tests/<module>_tests.rs` | Cargo auto-discovery |
| Rust stress | `tests/rust/stress/<name>_tests.rs` | `[[test]]` in `Cargo.toml` |
| Rust golden | `tests/rust/golden/harness.rs` | Cargo auto-discovery |
| Lua BDD (unit) | `tests/lua/unit/test_<module>.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (integration) | `tests/lua/integration/test_<a>_<b>.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (stress) | `tests/lua/stress/test_<name>_stress.lua` | `tests/lua/harness.rs` via `cargo test` |
| Lua BDD (validation) | `tests/lua/validation/test_<name>.lua` | `tests/lua/harness.rs` via `cargo test` |

> See [snippets/1-test-architecture-overview.txt](snippets/1-test-architecture-overview.txt) for the example.

---

### 2. Adding a New Rust Integration Test File
**Step 1 — Create the file** at `tests/<module>_tests.rs`. Cargo discovers all `tests/*.rs` automatically; no Cargo.toml entry needed.

**Step 2 — Skeleton:**
> See [examples/2-adding-a-new-rust-integration.rs](examples/2-adding-a-new-rust-integration.rs) for the example.

**Step 3 — Run:**
> See [snippets/2-adding-a-new-rust-integration-2.ps1](snippets/2-adding-a-new-rust-integration-2.ps1) for the example.

**Naming rules:**
- Function name: `<subject>_<scenario>_<expected>` — e.g., `body_zero_velocity_stays_still`
- No `test_` prefix — redundant; hurts `cargo test` output readability

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/1-test-architecture-overview.txt](snippets/1-test-architecture-overview.txt) — 1. Test Architecture Overview
- [examples/2-adding-a-new-rust-integration.rs](examples/2-adding-a-new-rust-integration.rs) — 2. Adding a New Rust Integration Test File
- [snippets/2-adding-a-new-rust-integration-2.ps1](snippets/2-adding-a-new-rust-integration-2.ps1) — 2. Adding a New Rust Integration Test File
- [examples/3-1-create-the-lua-file.lua](examples/3-1-create-the-lua-file.lua) — 3.1 Create the Lua file
- [examples/3-1-create-the-lua-file-2.lua](examples/3-1-create-the-lua-file-2.lua) — 3.1 Create the Lua file
- [examples/3-1-create-the-lua-file-3.lua](examples/3-1-create-the-lua-file-3.lua) — 3.1 Create the Lua file
- [examples/3-1-create-the-lua-file-4.lua](examples/3-1-create-the-lua-file-4.lua) — 3.1 Create the Lua file
- [examples/3-2-harness-registration.rs](examples/3-2-harness-registration.rs) — 3.2 Harness Registration
- [examples/test-structure.lua](examples/test-structure.lua) — Test structure
- [examples/performance-and-golden-helpers.lua](examples/performance-and-golden-helpers.lua) — Performance and Golden helpers
- [examples/6-test-vm-helpers-rust-side.rs](examples/6-test-vm-helpers-rust-side.rs) — 6. Test VM Helpers (Rust Side)
- [snippets/running-quality-gates.ps1](snippets/running-quality-gates.ps1) — Running quality gates
- [snippets/analytics-tools.ps1](snippets/analytics-tools.ps1) — Analytics tools
- [snippets/adding-missing-docs.ps1](snippets/adding-missing-docs.ps1) — Adding missing docs
- [snippets/rust-golden-tests-byte-level.ps1](snippets/rust-golden-tests-byte-level.ps1) — Rust golden tests (byte-level)
- [examples/lua-golden-tests-compare-only-files.lua](examples/lua-golden-tests-compare-only-files.lua) — Lua golden tests (compare-only files)
- [examples/syntax.lua](examples/syntax.lua) — Syntax
- [examples/syntax-2.lua](examples/syntax-2.lua) — Syntax
- [snippets/syntax-3.ps1](snippets/syntax-3.ps1) — Syntax
- [examples/tier-1-headless-state-readback-preferred.lua](examples/tier-1-headless-state-readback-preferred.lua) — Tier 1 — Headless State Readback (preferred)
- [examples/tier-2-canvas-pixel-readback-headless.lua](examples/tier-2-canvas-pixel-readback-headless.lua) — Tier 2 — Canvas Pixel Readback (headless GPU simulation)
- [examples/tier-3-runtime-smoke-tests-gpu.rs](examples/tier-3-runtime-smoke-tests-gpu.rs) — Tier 3 — Runtime Smoke Tests (GPU required)
- [examples/syntax-4.lua](examples/syntax-4.lua) — Syntax
- [snippets/coverage-scanner.ps1](snippets/coverage-scanner.ps1) — Coverage Scanner
- [examples/canvas-pixel-readback-headless.lua](examples/canvas-pixel-readback-headless.lua) — Canvas Pixel Readback (Headless)
- [examples/file-evidence.lua](examples/file-evidence.lua) — File Evidence
- [examples/runtime-smoke-tests-gpu-required.rs](examples/runtime-smoke-tests-gpu-required.rs) — Runtime Smoke Tests (GPU Required)
- [examples/lua-golden-tests.lua](examples/lua-golden-tests.lua) — Lua Golden Tests
- [examples/stress-test-output-format.lua](examples/stress-test-output-format.lua) — Stress Test Output Format
- [examples/recognized-patterns.lua](examples/recognized-patterns.lua) — Recognized Patterns
- [examples/example-well-named-describe-blocks.lua](examples/example-well-named-describe-blocks.lua) — Example: Well-Named Describe Blocks
- [examples/evidence-tests-file-output-required.lua](examples/evidence-tests-file-output-required.lua) — Evidence Tests — File Output Required
- [examples/golden-tests-compare-only.lua](examples/golden-tests-compare-only.lua) — Golden Tests — Compare Only
- [examples/covers-markers-required.lua](examples/covers-markers-required.lua) — `@covers` Markers — Required
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
- [tools/audit/test_coverage.py](../../../tools/audit/test_coverage.py) — Rust+Lua test-coverage cross-reference report.
- [tools/audit/golden_test.py](../../../tools/audit/golden_test.py) — golden-file diff harness for deterministic outputs.
- [tools/audit/annotate_tests.py](../../../tools/audit/annotate_tests.py) — auto-insert `@tests`/`@covers` markers in Lua tests.
- [tools/audit/unit_test_api_coverage.py](../../../tools/audit/unit_test_api_coverage.py) — unit-level API coverage metrics.
