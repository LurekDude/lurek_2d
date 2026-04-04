# Contributing to Luna2D

Luna2D is a desktop-only 2D engine written in Rust that runs Lua game scripts. Keep changes aligned with [docs/zen-of-luna.md](docs/zen-of-luna.md), [docs/design-assumptions.md](docs/design-assumptions.md), and [docs/architecture.md](docs/architecture.md).

## Setup

```bash
cargo build
cargo run -- examples/hello_world
```

If your work touches the official editor tooling, also review [vscode-extension/README.md](vscode-extension/README.md).

## Quality Gates

Run these before opening a pull request:

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
```

For focused verification while iterating, prefer scoped commands:

```bash
cargo check
cargo test --test lua_tests -- --nocapture
cargo test --test golden_tests -- --nocapture
```

## Tests

- Engine runtime coverage lives in `tests/unit/`, `tests/ext/`, `tests/game/`, `tests/stress/`, `tests/golden/`, and `tests/lua/`. These suites are registered in `Cargo.toml`. `tests/game/` is a historical grouping for Rust modules, not the current Tier 3 architecture layer.
- `tests/config_tests.rs` and `tests/particle_tests.rs` still exist as root-level auto-discovered Rust integration tests. Treat them as engine coverage.
- Library code under `library/` currently gets automated coverage through the Lua harness in `tests/lua/unit/`, including `test_library_dialog.lua` and `test_library_quest.lua`. There is no separate `library/tests/` tree today.
- `examples/` is a manual verification surface, not a separate automated test suite. When an example changes, run the relevant `cargo run -- examples/<name>` flow and record what you verified.
- Add a regression test for bug fixes.
- Add integration coverage for new public APIs, especially `luna.*` bindings.
- Keep Lua tests headless-safe. They should not require a window, GPU, or audio device.

## Documentation

- Update [docs/](docs/) when public APIs, callbacks, commands, or user-visible behavior change.
- Keep [README.md](README.md), [library/README.md](library/README.md), and [vscode-extension/README.md](vscode-extension/README.md) in sync when changes affect onboarding or the official tooling workflow.
- Keep public Rust doc comments current.

## Pull Requests

- Keep changes focused and avoid unrelated cleanup.
- Describe user-visible behavior, test coverage, and any scope limits in the pull request.
- If you need to report a security issue, follow [SECURITY.md](SECURITY.md) instead of posting exploit details publicly.
