# Contributing to Lurek2D

Lurek2D is a desktop-only 2D engine written in Rust that runs Lua game scripts. Read [docs/architecture/philosophy.md](docs/architecture/philosophy.md) and [docs/architecture/engine-architecture.md](docs/architecture/engine-architecture.md) before making structural changes.

---

## Setup

**Prerequisites**: Rust stable â‰Ą 1.78, Cargo, Python 3.10+ (for tooling scripts).

```bash
git clone https://github.com/LurekDude/luna_2d.git
cd lurek2d
cargo build                              # debug build â†’ build/debug/lurek2d
cargo run -- content/demos/hello_world  # verify it works
```

Release build:

```bash
cargo build --release                   # â†’ build/release/lurek2d (~10 MB)
```

The build output directory is `build/` (not `target/`) â€” configured via `.cargo/config.toml`.

---

## Quality Gates

Run before every pull request:

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
```

During development, prefer scoped commands to avoid saturating CPU:

```bash
cargo check                             # type-check only (~2â€“5 s incremental)
cargo test --test <module>_tests        # one Rust test suite
cargo test lua_test_<module>            # one Lua test suite
cargo clippy --lib                      # lint library only
```

---

## Contributing to Different Areas

### Engine (Rust source â€” `src/`)

- Read `src/<module>/AGENT.md` before touching a module â€” it lists invariants and patterns.
- No `unsafe` without a `// SAFETY:` comment explaining the invariant.
- Per-frame code must not heap-allocate â€” grow buffers at startup.
- Add `///` doc-comments to every new `pub` item. Verify: `python tools/docs/collect_docs.py --report-missing` must exit 0.
- Use `log::info!` / `log::debug!` / `log::warn!` / `log::error!` â€” never `println!`.
- No `.unwrap()` or `.expect()` in production paths â€” use `?` or return a `LuaError`.
- Regenerate API docs after any `lurek.*` binding change: `python tools/gen_all_docs.py --skip-legacy`.

### Tests (`tests/`)

Lurek2D has two test layers â€” both run **headless** (no window, GPU, or audio device needed):

**Rust tests** (`tests/rust/`):

```bash
cargo test --test <module>_tests -- --nocapture
```

- Name tests `<subject>_<scenario>_<expected>` â€” no `test_` prefix.
- Float comparisons: `assert!((val - expected).abs() < 1e-5)` â€” never `assert_eq!` on floats.
- Bug fixes require a regression test first.

**Lua BDD tests** (`tests/lua/`):

```bash
cargo test lua_test_<category>_<name> -- --nocapture
```

- Use `describe` / `it` / `expect_equal` / `expect_error` from `tests/lua/init.lua`.
- Every file must end with `test_summary()`.
- New `.lua` test file â†’ add a matching `#[test] fn lua_test_<category>_<name>()` in `tests/lua/harness.rs`.
- Lua tests must not call GPU, audio, or window APIs.
- New `lurek.*` functions need at least one Lua test before merge.

### Demos (`content/demos/`)

Demos are playable showcases, organized by genre (`action/`, `arcade/`, `rpg/`, `strategy/`, â€¦).

- Each demo needs: `main.lua`, `conf.lua` (optional), `README.md`, `screen.png`.
- Every demo must have a matching test in `tests/lua/content/demos/test_demo_<name>.lua`.
- Register new demos in `content/demos/README.md`.
- Demos must run with `cargo run -- content/demos/<name>` and exit cleanly.
- Use `library/` modules and `lurek.*` API â€” no engine Rust internals.

### API Examples (`content/examples/`)

Examples are single-file documentation scripts â€” one per `lurek.*` module.

- One script, one module, one concept. Keep it under ~80 lines where possible.
- No external assets unless strictly necessary.
- Must be runnable: `cargo run -- content/examples/<module>.lua`.
- Add a line to `content/examples/README.md` describing what it demonstrates.

### Lua Libraries (`library/`)

Libraries are pure-Lua game-mechanics modules with no Rust internals.

- May only call `lurek.*` public API â€” never `require` engine internals.
- Each library lives in its own subfolder with `init.lua` and a `README.md`.
- Add tests under `tests/lua/library/test_<name>.lua`.
- Keep libraries self-contained â€” minimal cross-library dependencies.

### VS Code Extension (`extensions/vscode/`)

See [`extensions/vscode/README.md`](extensions/vscode/README.md) and [docs/architecture/vscode-architecture.md](docs/architecture/vscode-architecture.md).

- TypeScript source is in `extensions/vscode/src/`.
- The extension reads API data from `docs/` â€” regenerate with `python tools/gen_all_docs.py` after engine API changes.
- Test the extension with `F5` launch in VS Code (Extension Development Host).
- Keep MCP server endpoints in sync with engine API additions.

### CAG Layer (`.github/`)

The `.github/` directory contains agents, skills, prompts, and the system prompt that power AI-assisted development.

- Validate after every edit: `python tools/validate/cag_validate.py`.
- Agent files live in `.github/agents/`, skills in `.github/skills/<name>/SKILL.md`.
- Follow the schema documented in `.github/skills/cag-workflow/SKILL.md`.

---

## Documentation

- Update `docs/specs/<module>.md` and `src/<module>/AGENT.md` when public APIs or behavior change.
- Update `docs/CHANGELOG.md` for every code, API, or tooling change (required for every commit).
- Regenerate generated reference files: `python tools/gen_all_docs.py`.
- Verify doc coverage: `python tools/docs/collect_docs.py --report-missing`.

---

## Pull Requests

- Keep changes focused â€” one logical change per PR.
- Describe user-visible behavior, test coverage, and scope limits in the PR description.
- Stage only files directly changed by the task â€” never `git add .`.
- Commit format: `type(scope): description` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
- Security issues: follow [SECURITY.md](SECURITY.md) â€” do not post exploit details publicly.

