# Contributing to Lurek2D

Lurek2D is a desktop-only 2D engine written in Rust that runs Lua game scripts. Read [docs/architecture/philosophy.md](docs/architecture/philosophy.md) and [docs/architecture/engine-architecture.md](docs/architecture/engine-architecture.md) before making structural changes.

---

## Setup

**Prerequisites**: Rust stable ≥ 1.78, Cargo, Python 3.10+ (for tooling scripts).

```bash
git clone https://github.com/LurekDude/luna_2d.git
cd luna_2d
python tools/dev/parallel_cargo.py build debug  # debug build → build/debug/lurek2d
python tools/dev/parallel_cargo.py run debug -- content/games/showcase/hello_world  # verify it works
```

Release build:

```bash
python tools/dev/parallel_cargo.py build release  # → build/release/lurek2d (~10 MB)
```

The build output directory is `build/` (not `target/`) — configured via `.cargo/config.toml`.

---

## Quality Gates

Run before every pull request:

```bash
python tools/dev/parallel_cargo.py fmt check
python tools/dev/parallel_cargo.py clippy --deny-warnings
python tools/dev/parallel_cargo.py test rust
```

During development, prefer scoped commands to avoid saturating CPU:

```bash
python tools/dev/parallel_cargo.py check   # type-check only (~2–5 s incremental)
python tools/dev/parallel_cargo.py test target <module>_tests  # one Rust test suite
python tools/dev/parallel_cargo.py test lua                     # Lua test suite
python tools/dev/parallel_cargo.py clippy --deny-warnings       # strict lint
```

---

## Contributing to Different Areas

### Engine (Rust source — `src/`)

- Read `src/<module>/AGENT.md` before touching a module — it lists invariants and patterns.
- No `unsafe` without a `// SAFETY:` comment explaining the invariant.
- Per-frame code must not heap-allocate — grow buffers at startup.
- Add `///` doc-comments to every new `pub` item. Verify: `python tools/docs/collect_docs.py --report-missing` must exit 0.
- Use `log::info!` / `log::debug!` / `log::warn!` / `log::error!` — never `println!`.
- No `.unwrap()` or `.expect()` in production paths — use `?` or return a `LuaError`.
- Regenerate API docs after any `lurek.*` binding change: `python tools/gen_all_docs.py --skip-legacy`.

### Tests (`tests/`)

Lurek2D has two test layers — both run **headless** (no window, GPU, or audio device needed):

**Rust tests** (`tests/rust/`):

```bash
cargo test --test <module>_tests -- --nocapture
```

- Name tests `<subject>_<scenario>_<expected>` — no `test_` prefix.
- Float comparisons: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats.
- Bug fixes require a regression test first.

**Lua BDD tests** (`tests/lua/`):

```bash
cargo test lua_test_<category>_<name> -- --nocapture
```

- Use `describe` / `it` / `expect_equal` / `expect_error` from `tests/lua/init.lua`.
- Every file must end with `test_summary()`.
- New `.lua` test file → add a matching `#[test] fn lua_test_<category>_<name>()` in `tests/lua/harness.rs`.
- Lua tests must not call GPU, audio, or window APIs.
- New `lurek.*` functions need at least one Lua test before merge.

### Demos (`content/games/`)

Demos are playable showcases, organized by genre (`action/`, `arcade/`, `rpg/`, `strategy/`, …).

- Each demo needs: `main.lua`, `conf.lua` (optional), `README.md`, `screen.png`.
- Every demo must have a matching test in `tests/lua/demos/test_demo_<name>.lua`.
- Register new demos in `content/games/README.md`.
- Demos must run with `python tools/dev/parallel_cargo.py run debug -- content/games/<name>` and exit cleanly.
- Use `library/` modules and `lurek.*` API — no engine Rust internals.

### API Examples (`content/examples/`)

Examples are single-file documentation scripts — one per `lurek.*` module.

- One script, one module, one concept. Keep it under ~80 lines where possible.
- No external assets unless strictly necessary.
- Must be runnable: `python tools/dev/parallel_cargo.py run debug -- content/examples/<module>.lua`.
- Add a line to `content/examples/README.md` describing what it demonstrates.

### Lua Libraries (`library/`)

Libraries are pure-Lua game-mechanics modules with no Rust internals.

- May only call `lurek.*` public API — never `require` engine internals.
- Each library lives in its own subfolder with `init.lua` and a `README.md`.
- Add tests under `tests/lua/library/test_<name>.lua`.
- Keep libraries self-contained — minimal cross-library dependencies.

### VS Code Extension (`extensions/vscode/`)

See [`extensions/vscode/README.md`](extensions/vscode/README.md) and [docs/architecture/vscode-architecture.md](docs/architecture/vscode-architecture.md).

- TypeScript source is in `extensions/vscode/src/`.
- The extension reads API data from `docs/` — regenerate with `python tools/gen_all_docs.py` after engine API changes.
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

- Keep changes focused — one logical change per PR.
- Describe user-visible behavior, test coverage, and scope limits in the PR description.
- Stage only files directly changed by the task — never `git add .`.
- Commit format: `type(scope): description` (types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
- Security issues: follow [SECURITY.md](SECURITY.md) — do not post exploit details publicly.

