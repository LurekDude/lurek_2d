# Lurek2D Engine — System Prompt

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game scripts.
This file is the always-on backbone for AI-assisted development in the Lurek2D repository.

- **CAG load order**: System Prompt → `src/<module>/AGENT.md` (module overview) → `docs/specs/<module>.md` (full technical detail) → Skills (on-demand) → Prompts → Agents
- **Module knowledge two-layer system**: `src/<module>/AGENT.md` is a short overview (purpose, source file list, pointer to spec). `docs/specs/<module>.md` is the full canonical reference (architecture, types, Lua API, examples, cross-module refs). Read the AGENT.md first; load the corresponding spec when you need deep technical detail.
- **Tech baseline**: Rust stable ≥1.78 | LuaJIT vendored via mlua 0.9 (`lua54` feature = non-shipping fallback) | wgpu 22 | winit 0.30 | rapier2d 0.32 | rodio 0.17 | fontdue 0.9
- **Sources of truth**: `docs/architecture/philosophy.md` (binding constraints) · `docs/architecture/engine-architecture.md` (module structure, tier system) · `docs/architecture/test-framework.md` (test suite). Consult all three before implementing any feature.
- **API namespace**: All Lua bindings live under `lurek.*` — never external engine prefixes, never bare globals
- **License**: MIT — no platform SDKs, no monetisation features

## Write Style

- Lead with Lurek2D-specific facts, not generic Rust advice
- One canonical place for each rule; reference, don't duplicate
- When designing an API, ask: "could a Copilot agent use this correctly without a clarifying question?" If no, redesign.

## Design Constraints

Active binding decisions from `docs/architecture/philosophy.md` — do not propose changes without a design-assumption update:

- **A-01** Runtime only — no embedded visual editor or IDE
- **A-02** Desktop only — Windows/Linux/macOS x86_64 + ARM. No mobile, no WASM
- **A-03** 2D graphics only — no 3D scene graph. Raycasting and isometric rendering use 2D draw calls and are acceptable
- **A-04** No distribution platform SDKs (Steam, Epic) in the core binary — Tier 4, out of scope
- **B-01** LuaJIT is the primary runtime; `lua54` Cargo feature is a non-shipping development fallback
- **B-02** wgpu 22 is the only renderer backend (Vulkan / DX12 / Metal) — no OpenGL path
- **B-03** Games must run acceptably on integrated GPUs (Intel UHD, AMD APU) — 60 FPS at 1080p target
- **B-04** Concurrency in Rust threads; LuaJIT VMs cannot share state; use `Channel` for cross-VM comms
- **B-05** TOML is the human-authored config format. JSON for external interop only. No YAML

## Quick Start

**Tool directory policy**: Permanent CLI scripts go in `tools/`. Session-scoped scripts go in `work/{session}/scripts/` — never in `tools/`. See `tools/README.md` for the full index.

**CAG validation** (run after every `.github/` edit):
```powershell
python tools/validate/cag_validate.py                              # Full validation
python tools/validate/cag_validate.py --type agent|skill|prompt    # One family
python tools/validate/cag_validate.py --file <path>                # Single file
```

**Commit quality gate**:
```powershell
cargo test && cargo clippy -- -D warnings
```

## Architecture

Lurek2D uses a strictly layered architecture enforced by Rust's module visibility rules and the import direction rules in `docs/architecture/engine-architecture.md`. No lower tier may import a higher tier; all cross-tier flows go upward only.

**Baseline** — `src/math/` (leaf, no internal deps) provides Vec2, Mat3, Rect, Color, noise, easing, random, transform, bezier, and triangulation. `src/engine/` provides `SharedState`, `EngineError`, `Config`, `App`, `RunState`, and all typed `SlotMap` resource keys.

**Tier 1** (Core subsystems — Baseline imports only, no Tier 1 ↔ Tier 1 cross-imports):
`graphics`, `audio`, `physics`, `input`, `timer`, `filesystem`, `compute`, `data`, `image`, `sound`, `event`, `entity`, `window`, `thread`, `animation`, `camera`, `automation`

**Tier 2** (Engine extensions — Baseline + Tier 1, no Tier 2 ↔ Tier 2 cross-imports):
`particle`, `tilemap`, `scene`, `savegame`, `modding`, `graph`, `pathfinding`, `ai`, `dataframe`, `gui`, `minimap`, `overlay`, `postfx`, `terminal`

**Bridge** — `src/lua_api/` registers the `lurek.*` Lua API. It may import all Rust tiers. Domain modules must **never** import `lua_api`.

**Tier 3 — Lunasome** (`content/library/`) — Pure-Lua standard libraries that consume only the public `lurek.*` API. No Rust engine internals. Includes `battle`, `cardgame`, `combat`, `crafting`, `dialog`, `doll`, `economy`, `inventory`, `item`, `province_map`, `quest`, `stats`.

**Rendering**: `DrawCommand` variants are pushed into a queue during `lurek.render()` and `lurek.render_ui()`. After each callback returns, `GpuRenderer::render_frame()` processes the queue in wgpu render passes. No GPU calls inside Lua closures.

**State**: `Rc<RefCell<SharedState>>` is shared between Lua closures and the engine loop. All resources (textures, fonts, meshes, etc.) live in typed `SlotMap<TypedKey, Resource>` pools — see `src/engine/resource_keys.rs`.

**Boot**: CLI args → `Config::load_from_conf_lua()` (conf.lua via temp Lua VM) → `App::new()` (winit, wgpu, rodio, GameFS) → `create_lua_vm()` (LuaJIT, 35+ API modules) → `main.lua` → `lurek.init()` / `lurek.ready()` → winit event loop.

## CAG Routing

**Load order**: System Prompt → `src/<module>/AGENT.md` (overview) → `docs/specs/<module>.md` (full spec, load when deep detail needed) → relevant skill files → agent

**Skill catalog** — all skills live in `.github/skills/`. Load the relevant `SKILL.md` before working in that domain.
`agent-md` · `analytics` · `asset-pipeline` · `build-system` · `cag-workflow` · `ci-cd-pipeline` · `cross-platform` · `dev-debugging` · `documentation` · `error-handling` · `examples-management` · `game-ai` · `github-workflow` · `gpu-programming` · `logging` · `lua-api-design` · `lua-rust-bridge` · `lua-runtime` · `lua-scripting` · `module-architecture` · `module-audit` · `performance-profiling` · `roadmap-planning` · `rust-coding` · `testing-rust` · `threading` · `tools-cag-validation` · `visual-effects` · `vscode-extension`

**Agent roster** — full definitions in `.github/agents/`:

| Agent | Mission |
|---|---|
| `Manager` | Starts every multi-agent session, creates the work folder, confirms the branch, decomposes requests into agent handoffs with measurable acceptance gates, and tracks overall progress |
| `Planner` | Accepts complex or multi-file tasks from Manager and produces a phased execution plan with sequencing rules, parallelism analysis, and done-when gates before any implementation begins |
| `Research` | Finds accurate, cited information from the web, official docs, or the codebase and returns a structured findings report with source citations — never implementation code |
| `Solver` | Performs structured root-cause analysis when no obvious solution exists, evaluates alternatives against binding constraints, and delivers a decision-ready recommendation with trade-off analysis |
| `Developer` | Implements Rust engine features, fixes bugs, adds new source modules, and maintains non-specialised Rust subsystem code across all tiers |
| `Lua-Designer` | Designs and evolves the `lurek.*` Lua API surface, enforcing naming conventions, parameter patterns, sensible defaults, and API consistency across all binding modules |
| `Renderer` | Owns the wgpu GPU pipeline: device and surface setup, `DrawCommand` queue processing, texture management, WGSL shaders, blend modes, and canvas render-to-texture |
| `Physicist` | Owns the `src/physics/` rapier2d integration: rigid bodies, colliders, shapes, joints, raycasting, collision events, and the `lurek.physics.*` Lua API |
| `Audio-Eng` | Owns the `src/audio/` rodio integration: mixer, audio buses, static and streaming sources, volume/pitch/pan, and the `lurek.audio.*` Lua API |
| `Tester` | Writes and maintains all tests — Rust integration tests in `tests/`, Lua BDD tests in `tests/lua/`, golden snapshot tests, and stress tests |
| `Reviewer` | Reviews code for compliance with conventions, module boundary rules, tier direction, test coverage, and quality gates — reports findings, must not rewrite code |
| `Debugger` | Diagnoses runtime bugs, crashes, and unexpected behaviour using RUST_LOG, borrow traces, and engine error paths — delivers root cause, does not implement fixes |
| `Optimizer` | Profiles frame time, heap allocations, and hot paths; delivers a prioritised optimisation report with measured evidence before Developer implements changes |
| `Architect` | Makes module boundary decisions, assigns tiers to new modules, designs the dependency graph, and enforces the DAG invariant across the codebase |
| `Doc-Writer` | Writes and maintains all documentation in `docs/`, ensures `///` coverage on public items, runs the doc pipeline, and keeps `content/demos/README.md` current |
| `Security` | Audits the Lua sandbox, GameFS path-traversal guards, Lua input validation, and `unsafe` blocks — reports findings to Developer, never implements fixes directly |
| `CAG-Architect` | Maintains the `.github/` CAG layer — agents, skills, prompts, and the system prompt — and always runs `tools/validate/cag_validate.py` after every edit |
| `Configurator` | Authors, validates, and documents `conf.lua` and `conf.toml` templates against the `Config` struct in `src/engine/config.rs` — does not modify engine Rust code |
| `Hacker` | Performs adversarial probing of the `lurek.*` API and sandbox — stale keys, path traversal, double-release, nil spam, resource exhaustion — and feeds findings to Security and Tester |
| `Player` | Reviews demos and API proposals through named user personas; provides subjective fun ratings and friction reports to Lua-Designer and Doc-Writer — never performs correctness checks |

## Critical Rules

### Rust Conventions

Lurek2D-specific rules only — common Rust idioms apply without repetition:

- `unsafe` requires a `// SAFETY:` comment explaining the invariant; never use raw pointers for state sharing
- Per-frame code must not allocate on the heap — grow draw-call buffers at startup, not per frame
- Engine resources live in `SlotMap<TypedKey, Resource>` — see `src/engine/resource_keys.rs` for all key types (`TextureKey`, `FontKey`, `ShaderKey`, `MeshKey`, `CanvasKey`, `SpriteBatchKey`, `ParticleKey`)
- Use `log::info!` / `log::warn!` / `log::error!` / `log::debug!` — never `println!` in engine code
- Convert errors to `LuaError` at the Lua API boundary with `.map_err(LuaError::external)`

### Lua API Conventions

- All bindings under `lurek.*` — never external prefixes or bare globals
- Every API file signature: `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- Clone `Rc` before moving into closures: `let state = state.clone();` then `move |...| { let s = state.borrow(); ... }`
- Sensible defaults — never require a parameter a beginner would always pass the same value
- All callbacks (`lurek.init`, `lurek.ready`, `lurek.process`, `lurek.process_physics`, `lurek.process_late`, `lurek.render`, `lurek.render_ui`, and all event callbacks) are optional — blank `main.lua` is valid
- Lua API is synchronous from the script's perspective — async work in Rust threads via `Channel`
- Validate inputs at the Lua boundary — return descriptive `LuaError`, never panic
- Full callback reference: `docs/architecture/engine-architecture.md` § Callback Contract

**MANDATORY — Thin Wrapper Rule**: `src/lua_api/<module>_api.rs` owns ALL Lua-facing registration. This includes: `pub fn register()`, Lua wrapper structs (`Lua<X>`), `impl LuaUserData` blocks, and all `add_method` / `add_method_mut` calls. Domain modules (`src/<module>/`) contain ONLY pure-Rust business logic, algorithms, and data types — they must never contain `impl LuaUserData` or any mlua import. Violating this rule is a blocking code review defect. **`impl LuaUserData` in a domain module is always wrong — move it to `src/lua_api/<module>_api.rs`.**

### Testing Framework

Lurek2D has a two-layer test system. Both layers run **headless** — no window, GPU, or audio device required.

**Rust tests** (`tests/rust/unit/`, `tests/rust/stress/`, `tests/rust/golden/`, `tests/rust/config/`, `tests/rust/security/`, `tests/rust/ext/`): naming `<subject>_<scenario>_<expected>`, no `test_` prefix. Float comparisons must use `assert!((val - expected).abs() < 1e-5)`, never `assert_eq!` on floats. All test binaries must be registered in `Cargo.toml`. **`tests/rust/game/` is retired** — game systems are now Lua libraries tested in `tests/lua/content/library/`.

**Lua BDD tests** (`tests/lua/`): `tests/lua/harness.rs` dispatches one `#[test]` function per `.lua` file. `tests/lua/init.lua` provides `describe`/`it`/`expect_equal`/`expect_near`/`expect_error` etc. Every Lua test file must end with `test_summary()`. New `.lua` file → add corresponding `#[test] fn lua_test_<category>_<name>()` entry to `tests/lua/harness.rs`.

**Lua test categories**: `unit/` (one per engine module), `content/library/` (one per `content/library/` Lunasome module), `integration/` (tests between ≥2 modules — both namespaces must appear), `stress/` (throughput/allocation from Lua), `security/` (sandbox, nil spam, path traversal), `golden/` (deterministic output), `config/` (config loading), `content/demos/` (one per demo in `content/demos/`).

**Examples vs Demos**: `content/examples/` are documentation — no tests required. `content/demos/` are functional showcases — every demo must have a test in `tests/lua/content/demos/test_demo_<name>.lua`.

**VM helpers**: `create_test_vm()` returns a full Lua VM with BDD framework loaded. `make_vm()` returns `(Rc<RefCell<SharedState>>, Lua)` for stateful Rust-side tests.

**Constraints**: Lua tests must not call GPU, audio, or window APIs. New `lurek.*` functions require at least one Lua test before merge. Bug fixes require a regression test first.

### Docstrings

Every `pub` Rust item needs `///`. Every module (`mod.rs`, `lib.rs`) needs `//!`. Format: one-sentence summary, optional detail paragraph. Verify: `python tools/docs/collect_docs.py --report-missing` (exits 1 if any missing).

**Lua API files** (`src/lua_api/`) use inline `@param name : type` and `@return type` annotations — **never** `# Parameters` / `# Returns` rustdoc sections. Gold standard: `src/lua_api/timer_api.rs`.

### Work Sessions (Mandatory)

Every session that produces artifacts must:
1. Confirm branch: `git rev-parse --abbrev-ref HEAD` → write to `work/branch.txt`
2. Create `work/{session-name}/` with 8 subfolders: `scripts/` `handovers/` `reports/` `data/` `content/demos/` `other/` `temp/` `logs/`
3. Create `logs/agent_log.jsonl` — append one JSONL entry per completed phase, never overwrite
4. Route to `Planner` before any work if the task spans 3+ agents or 5+ files

Log entry format: `{"timestamp":"ISO8601","agent":"Name","session":"...","phase":"...","skills_used":[],"tools_used":[],"commands_run":[],"result":"PASS|FAIL|PARTIAL","findings":[],"handover_to":"..."}`

Completed session folders move to `work/archive/` — never delete.

### Changelog (docs/CHANGELOG.md) — MANDATORY FOR ALL AGENTS

`docs/CHANGELOG.md` is the canonical version history. **Every agent** must update it in the same commit as any code, API, or tooling change. This is not optional.

**Versioning scheme — `MAJOR.MINOR.PATCH`**

| Segment | Increment when… |
|---|---|
| **MAJOR** | Breaking API changes — Lua scripts or engine config must be ported |
| **MINOR** | New backwards-compatible features — new `lurek.*` APIs, new modules, new defaults |
| **PATCH** | Bug fixes, internal refactors, doc/tooling changes that do not affect the public API |

Format for a new entry:
```markdown
## [X.Y.Z] — YYYY-MM-DD
### Added / Changed / Fixed / Removed
- Describe the change in one line.
```

- Current version lives in `Cargo.toml` → `[package] version`.
- When bumping MAJOR or MINOR: also update `Cargo.toml` version and any `!define APP_VERSION` in `tools/dist/installer.nsi` + `$Version` in `tools/dist/dist.ps1`.
- PATCH fixes: update CHANGELOG only (Cargo.toml version is optional unless publishing).

### Git Rules

- Never `git add .` — stage only files directly changed by the current task
- Commit format: `type(scope): description` — types: `feat` `fix` `refactor` `test` `docs` `chore`
- One logical change per commit — one accepted phase = one commit
- Confirm branch before committing: `git rev-parse --abbrev-ref HEAD`
- **Update `docs/CHANGELOG.md` before every commit** — add or extend the entry for the current version

### CLI Tools (tools/)

All permanent tools live in `tools/` organised by category. See `tools/README.md` for the full index. Each subfolder has its own `README.md`.

| Subfolder | Contains |
|---|---|
| `tools/docs/` | Documentation generators (`collect_docs.py`, `gen_all_docs.py`, `gen_docs_lua.py`, `gen_docs_rusta.py`, `gen_docs_rust.py` …) |
| `tools/audit/` | Quality auditing & coverage analytics (`audit_module.py`, `doc_coverage.py`, `test_coverage.py` …) |
| `tools/fix/` | Code fixers & docstring improvers (`add_lua_docstrings.py`, `fix_docstrings.py` …) |
| `tools/validate/` | Schema & structure validators (`cag_validate.py`, `validate_lua_api.py` …) |
| `tools/assets/` | Artwork source files — edit directly; all assets are maintained manually |
| `tools/dist/` | Build, package & install (`dist.ps1`, `dist.sh`, `install.ps1`, `install.sh` …) |
| `tools/github/` | GitHub automation (`ideas_to_github_issues.py` …) |

Key invocations:
- **CAG**: `python tools/validate/cag_validate.py [--type agent|skill|prompt] [--file <path>]`
- **Docs**: `python tools/gen_all_docs.py` · `python tools/docs/collect_docs.py [--report-missing|--suggest]`
- **Coverage**: `python tools/audit/doc_coverage.py` · `python tools/audit/test_coverage.py [--suggest]`
- **Audit**: `python tools/audit/audit_module.py <name>` · `python tools/audit/module_audit.py`
- **Lua API**: `python tools/docs/gen_lua_api_skeleton.py [--all|--module <name>|--list]`
- **API refs**: `docs/API/lua-api.md` (Lua) · `docs/API/rust-api.md` (Rust) · run `gen_all_docs.py` to regenerate
- **API refs**: `docs/API/lua-api.md` (Lua) · `docs/API/rust-api.md` (Rust) · run `gen_all_docs.py` to regenerate
- **Assets**: All artwork in `assets/` is maintained manually. Do not run Python generators.
- **Distribution**: `powershell tools/dist/dist.ps1` / `bash tools/dist/dist.sh`

### Logging

| Level | Use for |
|---|---|
| `error!` | Unrecoverable — aborts the frame or session |
| `warn!` | Recoverable — degraded behaviour expected |
| `info!` | Lifecycle events: startup, shutdown, script load |
| `debug!` | Per-frame detail — disabled in release builds |

Control: `RUST_LOG=lurek2d=debug cargo run -- content/demos/hello_world`. Never use `println!` in engine code.

### Test Diagnostics

| What | Command |
|---|---|
| Type-check only | `cargo check` |
| One Rust test suite | `cargo test --test <module>_tests -- --nocapture` |
| One Lua test | `cargo test lua_test_<category>_<name> -- --nocapture` |
| Debug log in tests | `$env:RUST_LOG="debug"; cargo test --test <module>_tests -- --nocapture` |
| Lint library only | `cargo clippy --lib` |
| Full quality gate | `cargo test && cargo clippy -- -D warnings` |

Use scoped `--test <module>` during development. Full `cargo test` only at commit time.

### Repository Layout

```
src/              Rust source — Baseline, Tier 1, Tier 2, and lua_api bridge
docs/specs/       Full technical specifications for every src/<module>/ (one <module>.md per module)
content/library/          Tier 3 Lunasome — pure-Lua libraries (no Rust engine internals)
content/demos/            Playable Lua game demos — each has main.lua and optional conf.lua
content/examples/         Single-file Lua API usage scripts — one per lurek.* module
tests/            Rust + Lua test suites (rust/unit/, rust/stress/, rust/golden/, rust/config/, rust/security/, rust/ext/, lua/unit/, lua/content/library/, lua/integration/, lua/content/demos/)
docs/             Architecture docs, generated API refs (docs/API/), performance notes
tools/            Permanent CLI scripts only
.github/          CAG layer — agents, skills, prompts, system prompt
extensions/vscode/ First-party VS Code extension (MCP server, IntelliSense, webview panels)
work/             Session folders — current and work/archive/
assets/           Engine assets: splash screen, window icon, embedded fonts
```

### Game Code and Libraries

- **`content/demos/`** — Run any demo with `cargo run -- content/demos/<name>`. Use as reference for complete, idiomatic game structures built on the `lurek.*` API.
- **`content/examples/`** — Focused single-file API usage scripts (e.g. `physics.lua`, `tilemap.lua`). Use when you need to understand a specific `lurek.*` namespace in isolation.
- **`content/library/`** -api.md`** — Compact `lurek.*` API reference generated by `tools/docs/gen_docs_lua.py`. Run `python tools/gen_all_docs.py` to regenerate. Do not hand-edit.
- **`docs/API/rust-api.md`** — Rust public API reference generated by `tools/docs/gen_docs_rust.py`. Run `python tools/gen_all_docs.py` to regenerate. D from library code.
- **`docs/API/lua-api.md`** — Compact `lurek.*` API reference generated by `tools/docs/gen_docs_lua.py`. Run `python tools/gen_all_docs.py` to regenerate. Do not hand-edit.
- **`docs/API/rust-api.md`** — Rust public API reference generated by `tools/docs/gen_docs_rust.py`. Run `python tools/gen_all_docs.py` to regenerate. Do not hand-edit.
- **`docs/specs/`** — One `<module>.md` per engine module. Full architecture, types, Lua API details, and cross-module references. Read alongside `src/<module>/AGENT.md`. See `docs/specs/README.md` for the sync contract.

### Cross-Artifact Sync Contract

Every time you add a feature, fix a bug, or change the API, you **must** update all of the following in the same commit:

| Changed artifact | Files that must also change |
|---|---|-api.md` (run `python tools/gen_all_docs
| Rust source `src/<module>/*.rs` | `src/<module>/AGENT.md` · `docs/specs/<module>.md` |
| Lua binding `src/lua_api/<module>_api.rs` | `docs/specs/<module>.md` · `docs/API/lua-api.md` (run `python tools/gen_all_docs.py`) |
| `lurek.*` API added/renamed/removed | `content/examples/<module>.lua` · any `content/demos/` that use the API · `content/library/` modules that depend on it |
| New module created | New `src/<module>/AGENT.md` (short) · new `docs/specs/<module>.md` (full) · entry in `docs/specs/README.md` |

This list is the canonical sync requirement. Never commit a code change without checking every row.

| Any change at all | `docs/CHANGELOG.md` — add entry under current version |
