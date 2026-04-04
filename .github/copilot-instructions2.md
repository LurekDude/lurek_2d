# Luna2D Engine — System Prompt

Luna2D is a 2D game engine written in Rust that loads and executes Lua game scripts.
This file is the always-on backbone for AI-assisted development in the Luna2D repository.

- **CAG load order**: System Prompt → Instructions (auto-load by file glob) → Skills (load on-demand) → Prompts → Agents
- **Tech baseline**: Rust stable ≥1.78 | LuaJIT vendored via mlua 0.9 (Lua 5.4 `lua54` feature = non-shipping fallback) | wgpu 22 | winit 0.30 | rapier2d 0.32 | rodio 0.17 | fontdue 0.9
- **Source of truth**: [`docs/zen-of-luna.md`](../docs/zen-of-luna.md) (first principles) · [`docs/design-assumptions.md`](../docs/design-assumptions.md) (binding constraints) · [`docs/architecture.md`](../docs/architecture.md) (module structure, layer model, dependency graph). Consult all three before implementing any feature or making an architectural decision.
- **API namespace**: All Lua bindings live under `luna.*` — never external engine prefixes, never bare globals
- **Design inspiration**: Similar Lua-based 2D game engines — single exe, loads `main.lua`, callback model (`luna.load/update/draw`). User writes Lua; engine owns GPU, threading, and batching.
- **IDE**: VS Code first-party extension — MCP server, CAG docs, IntelliSense, webview panels, AI-first workflow
- **License**: MIT — no distribution platform SDKs, no monetisation features

## Write Style

- Lead with Luna2D-specific facts, not generic Rust advice
- Code examples must compile against the actual crate APIs in this repo
- Prefer brief, actionable guidance — no boilerplate commentary
- One canonical place for each rule; reference, don't duplicate
- When designing an API, ask: "could a Copilot agent use this correctly without a clarifying question?" If no, redesign.

## Design Constraints

The following are **active, binding decisions** from `docs/design-assumptions.md`. Do not propose changes to these without a design-assumption update.

| ID | Constraint |
|---|---|
| A-01 | Luna2D is a **runtime only** — no embedded visual editor or IDE |
| A-02 | **Desktop only** — Windows/Linux/macOS x86_64 + ARM. Mobile (iOS/Android) and WASM are out of scope |
| A-03 | **2D graphics only** — no 3D scene graph or perspective pipeline. Raycasting columns and isometric projection are acceptable (they use 2D draw calls) |
| A-04 | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core engine binary. Platform integrations are out of scope for the current Baseline / Tier 1 / Tier 2 / Tier 3 Lunasome model |
| B-01 | **LuaJIT** is the primary scripting runtime. Lua 5.4 (`lua54` cargo feature) is a non-shipping development fallback |
| B-02 | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal). No raw OpenGL path |
| B-03 | Games must run acceptably on **integrated GPUs** (Intel UHD, AMD APU) |
| B-04 | Concurrency lives in **Rust threads**. LuaJIT VMs cannot share state; Lua-to-Lua comms use `Channel` objects |
| B-05 | **TOML** is the human-authored config format. JSON is only for external interop. YAML is not used |

## Quick Start

### Build and Run

```powershell
cargo build                           # Debug build (only needed to ship or run the binary)
cargo build --release                 # Release build
cargo run                             # Splash screen (no game)
cargo run -- examples/hello_world     # Run example
cargo run -- path/to/my_game          # Run custom game
```

### Development Loop — Scoped Commands (use during implementation)

**Never run `cargo build` or `cargo test` (full) during development.**
These rebuild the entire engine (~4 min cold), saturate all CPU cores, and block
parallel agents or the user working on other modules.

```powershell
# Type-check only — no compilation, no linking, ~2-5s incremental
cargo check

# Test only the registered Rust binary or Lua dispatcher you are working on
cargo test --test <binary-name> -- --nocapture
cargo test --test lua_tests <dispatcher-name> -- --nocapture

# Lint only the library (no test binaries compiled)
cargo clippy --lib
```

> **Rule**: `cargo check` runs the full borrow-checker and type-checker without producing
> any binary output. It is the correct tool to validate a change during implementation.
> `cargo build` is only needed for packaging or running the game binary — never as a
> pre-test step, because `cargo test` already compiles what it needs automatically.

### Final Gate — before every `git commit`

Run these **once**, only after all implementation work on a task is complete:

```powershell
cargo test && cargo clippy -- -D warnings
```

### Quality Gates (CI / commit checklist)

```powershell
cargo clippy -- -D warnings           # Lint — must pass with 0 warnings
cargo fmt --check                     # Format check
cargo test                            # All tests must pass
```

### Tool Directory Policy

`tools/` contains **permanent** CLI scripts only. Temporary session scripts go in `work/{session}/scripts/`. See `tools/README.md` for the full index.

- **Permanent** (goes in `tools/`): reusable CLI utilities, doc generators, validators
- **Temporary** (goes in `work/{session}/scripts/`): one-off migration scripts, session helpers
- **Never** create `_*.py` or similar temp files in `tools/`

### CAG Validation (tools/)

```powershell
python tools/cag_validate.py                            # Full CAG validation
python tools/cag_validate.py --type agent               # Validate agents only
python tools/cag_validate.py --type skill               # Validate skills only
python tools/cag_validate.py --type prompt               # Validate prompts only
python tools/cag_validate.py --type instruction          # Validate instructions only
python tools/cag_validate.py --file .github/agents/developer.agent.md  # Single file
```

## CAG Routing

### Load Order

1. **Instructions** — auto-load by `applyTo` glob when matching files are in context
2. **Skills** — load on-demand when the task matches the domain
3. **Prompts** — task-driven playbooks, operator selects
4. **Agents** — specialist roles, routed by task type

### Agent Intent Summary

| Agent | Mission |
|---|---|
| `Manager` | Route tasks, orchestrate multi-agent workflows, own session start |
| `Planner` | Decompose complex tasks, build phased plans, define done-when gates |
| `Research` | Search web/docs/codebase for facts; return cited evidence report |
| `Solver` | Root-cause analysis, alternative evaluation, decision-ready solution report |
| `Developer` | Implement Rust features, fix bugs, write code |
| `Lua-Designer` | Design and evolve the `luna.*` Lua API surface |
| `Renderer` | Graphics pipeline, wgpu GPU rendering, draw commands |
| `Physicist` | Physics engine (rapier2d), collision, bodies, world simulation |
| `Audio-Eng` | Audio system, rodio integration, sound management |
| `Tester` | Write and run tests, coverage, test strategies |
| `Reviewer` | Code review, quality gates, compliance checking |
| `Debugger` | Diagnose runtime issues, trace bugs, profiling |
| `Optimizer` | Performance analysis, hot-path optimization |
| `Architect` | Module structure, dependency graph, API design |
| `Doc-Writer` | Documentation, API reference, tutorials |
| `Security` | Memory safety, input validation, Lua sandboxing |
| `CAG-Architect` | Maintain the CAG layer itself |

## Critical Rules

### Architecture

- **GPU rendering**: wgpu → `wgpu::Surface` → `GpuRenderer::render_frame()` → swapchain present. No CPU pixel buffer. `renderer.rs` contains shared draw types (`DrawCommand`, `BlendMode`, etc.).
- **Draw command queue**: Lua calls push `DrawCommand` variants during `luna.draw()`. Engine processes them after the callback returns. Never render inside a Lua closure.
- **SharedState**: `Rc<RefCell<SharedState>>` shared between Lua closures and the engine loop. Never use raw pointers or `unsafe` for state sharing. Resource pools use `SlotMap` with typed keys.
- **Module direction and four-layer model**: See the full tables in [`docs/architecture.md`](../docs/architecture.md). Short form:
  - **Baseline**: `math` and `engine` are the always-on runtime substrate. `lua_api` is the Lua bridge above the engine layers; it is not a numbered layer.
  - **Tier 1**: core engine subsystems in `src/` build on Baseline only.
  - **Tier 2**: reusable engine extensions in `src/` build on Baseline + Tier 1.
  - **Tier 3**: Lunasome in `library/` is the pure-Lua standard-library layer. It consumes public `luna.*` APIs rather than creating Rust-to-Rust dependencies back into the engine.
  - **Legacy Rust gameplay modules**: gameplay-oriented Rust modules that still live under `src/` are real migration-state code, not the target Tier 3 architecture for new library work.
  - Lower engine layers do not depend on Tier 3, and domain Rust modules never import `lua_api`.
- **Physics backend**: rapier2d 0.32 provides rigid-body simulation with circles, rectangles, sensors, raycasting, joints, and collision event recording via `src/physics/`.

### Module Dependency Graph

```
Tier 3 Lunasome (`library/`, pure Lua)
  ↑ consumes public `luna.*`
lua_api (bridge layer — not a numbered tier)
  ↑ imports engine modules and exposes Lua bindings
Tier 2 engine extensions (`src/`)
  ↑ import Baseline + Tier 1
Tier 1 core engine subsystems (`src/`)
  ↑ import Baseline only
Baseline (`math`, `engine`)
```

- Baseline is always available; `math` remains the leaf and `engine` provides shared runtime types such as `SharedState`, `EngineError`, `Config`, and `App`
- Tier 1 engine modules depend only on Baseline — no Tier 1 ↔ Tier 1 cross-imports
- Tier 2 engine modules may import Baseline + Tier 1 — no Tier 2 ↔ Tier 2 cross-imports
- `lua_api` is the bridge that imports engine layers and exposes `luna.*`; domain Rust modules never import it
- Tier 3 Lunasome consumes the public Lua API only; lower engine layers do not depend on Tier 3
- Gameplay-oriented Rust modules that remain under `src/` are migration-state code, not the active Tier 3 layer

### Boot Sequence

1. Parse CLI args → game directory path
2. `Config::load_from_conf_lua(game_dir)` — temporary Lua VM executes `conf.lua`
3. `App::new(config)` — windowing (winit), GPU init (wgpu), audio (rodio), filesystem (GameFS)
4. `create_lua_vm()` — LuaJIT VM, `luna` global table, 35+ API modules registered
5. Load and execute `main.lua` → call `luna.load()`
6. Enter `winit` event loop → `luna.update(dt)` / `luna.draw()` each frame

### Rust Conventions

- **No `unsafe`** unless absolutely necessary and documented with a `// SAFETY:` comment
- **Error handling**: `thiserror` derive for `EngineError` enum; `LuaResult<T>` for Lua-callable functions
- **Visibility**: `pub` for cross-module types; `pub(crate)` when possible
- **Constructors**: prefer `impl Into<T>` for flexible parameter types
- **Imports**: absolute paths (`crate::module::Type`), not relative
- **Formatting**: `cargo fmt` before every commit; `cargo clippy` with 0 warnings
- **Logging**: use `log::info!` / `log::warn!` / `log::error!` / `log::debug!` — never `println!` in engine code
- **Allocations**: per-frame code must not allocate on the heap; grow draw-call buffers at startup
- **SlotMap keys**: resources are stored in `SlotMap<TypedKey, Resource>` — see `TextureKey`, `FontKey`, `ShaderKey`, `MeshKey`, `CanvasKey`, `SpriteBatchKey`, `ParticleKey`
- **Error propagation**: use `?` throughout internal code; convert to `LuaError` at the Lua API boundary with `.map_err(LuaError::external)`

### Lua API Conventions

- All bindings under `luna.*` namespace — NEVER external engine prefixes or any other prefix
- Every API file uses `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- Closures capture `Rc<RefCell<SharedState>>` — clone the Rc before moving into closure:
  ```rust
  let state = state.clone();
  luna.set("myFunc", lua.create_function(move |_, args: ()| {
      let s = state.borrow();
      // ...
  })?)?;
  ```
- Return `LuaResult<T>` from all Lua-callable functions
- Key names: lowercase strings (`"space"`, `"escape"`, `"a"`, `"left"`)
- API functions must have **sensible defaults** — never require parameters a beginner would always pass the same value
- Every callback (`luna.load`, `luna.update`, `luna.draw`) is optional — an empty `main.lua` is valid
- Lua API is **synchronous from the script's perspective** — async work happens in Rust threads using `Channel`
- Use `lua.to_value()` / `lua.from_value()` for Lua↔Rust table conversions; avoid manual field iteration
- Validate inputs at the Lua boundary — return descriptive `LuaError` messages, never panic

### Callbacks

| Function | When called |
|---|---|
| `luna.load()` | Once after script loads |
| `luna.update(dt)` | Every frame with delta time |
| `luna.draw()` | Every frame for rendering |
| `luna.keypressed(key)` | Key press event |
| `luna.keyreleased(key)` | Key release event |
| `luna.textinput(text)` | Text input event |
| `luna.mousepressed(x, y, btn)` | Mouse press event |
| `luna.mousereleased(x, y, btn)` | Mouse release event |
| `luna.wheelmoved(x, y)` | Mouse wheel event |
| `luna.gamepadpressed(id, btn)` | Gamepad button press |
| `luna.gamepadreleased(id, btn)` | Gamepad button release |
| `luna.gamepadaxis(id, axis, val)` | Gamepad axis movement |
| `luna.joystickadded(id)` | Gamepad connected |
| `luna.joystickremoved(id)` | Gamepad disconnected |
| `luna.touchpressed(id, x, y, dx, dy, pressure)` | Touch start |
| `luna.touchmoved(id, x, y, dx, dy, pressure)` | Touch move |
| `luna.touchreleased(id, x, y, dx, dy, pressure)` | Touch end |
| `luna.focus(has_focus)` | Window focus change |
| `luna.visible(is_visible)` | Window visibility change |
| `luna.resize(w, h)` | Window resize |

### Testing

Luna2D testing is split by responsibility rather than a single generic `tests/*.rs` pattern.

**Engine Rust tests** (registered explicitly in `Cargo.toml`)
- Test binaries live under `tests/unit/`, `tests/ext/`, `tests/game/`, and `tests/stress/`
- Golden coverage is registered through `tests/golden/harness.rs`
- A small number of legacy root-level Rust test files may still exist during migration; keep docs and `Cargo.toml` in sync
- Choose the existing test family that matches the code under test; a new Rust test binary must be added to `Cargo.toml`
- Import from crate root: `use luna2d::module::Type;`
- Float rule: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats

**Lua API and Lunasome tests** (`tests/lua/`)
- Dispatched by `tests/lua/harness.rs` — every committed `.lua` file needs one Rust dispatcher entry there
- Covers both `luna.*` bindings and current `library/` modules such as `test_library_dialog.lua` and `test_library_quest.lua`
- Framework (`tests/lua/init.lua`) provides: `describe` / `it` / `expect_equal` / `expect_near` / `expect_type` / `expect_error` etc.
- Categories live under `unit/`, `integration/`, `stress/`, and `validation/`
- Every Lua test file ends with `test_summary()`
- The harness VM is headless: no GPU, no audio device, no real window — never call rendering paths that require runtime presentation

**Example validation**
- Examples are smoke and acceptance artifacts run with `cargo run -- examples/<name>`
- There is no dedicated `tests/examples/` harness today; do not invent one in guidance or docs

**Rust-side Lua helpers**
- `tests/lua/harness.rs` provides `create_test_vm()` for the shared Lua BDD runner
- Additional `make_vm()` helpers may exist inside individual Rust test binaries when that binary needs local setup; treat them as local helpers, not a universal harness contract

**Adding a new Lua test:**
1. Create the `.lua` file under the appropriate `tests/lua/` category
2. End it with `test_summary()`
3. Add the matching dispatcher entry to `tests/lua/harness.rs`
4. Run: `cargo test lua_test_<name>` or the relevant dispatcher name

**Quality gates:**
- `cargo test` — all registered test binaries and harnesses must exit 0
- `cargo clippy -- -D warnings` — must exit 0
- `python tools/test_coverage.py` — coverage analytics
- `python tools/collect_docs.py --report-missing` — lists undocumented public items (exit 1 if any)

**Constraints:**
- Lua tests MUST NOT require a window, GPU, or audio device
- New `luna.*` API functions require at least one Lua test before merge
- New `library/` modules should get Lua harness coverage rather than made-up Rust-only library test paths
- Stress tests live in `tests/stress/` (Rust) and `tests/lua/stress/` (Lua)
- Golden tests use `tests/golden/harness.rs` with expected files in `tests/golden/expected/` and runtime output in `tests/golden/actual/` (git-ignored)

### File Structure

```
src/          — Rust engine code (Baseline, Tier 1, Tier 2, plus legacy migration-state gameplay modules)
library/      — Lunasome standard-library layer (pure Lua gameplay libraries)
examples/     — Runnable Lua examples and smoke artifacts
tests/        — Registered Rust test binaries + Lua harnesses + golden baselines
docs/         — Architecture, zen, design-assumptions, generated API refs
tools/        — CLI scripts (CAG validation, doc generation, packaging, install)
.github/      — CAG layer (agents, skills, prompts, instructions)
vscode-extension/ — First-party VS Code extension (MCP server, IntelliSense)
work/         — Session work folders (branch.txt, per-session artifact folders)
assets/       — Engine assets (splash, icon, embedded fonts)
```

### Work Sessions (Mandatory)

**Every chat session that produces artifacts MUST follow this protocol:**

```powershell
# 1. Confirm branch
git rev-parse --abbrev-ref HEAD        # write output to work/branch.txt
git status                             # review working tree

# 2. Create session folder (human-readable name, no timestamps)
# e.g., work/renderer-wgpu-port/, work/physics-fix/, work/cag-upgrade/

# 3. Create 8 required subfolders
# scripts/  handovers/  reports/  data/  examples/  other/  temp/  logs/

# 4. Create logs/agent_log.jsonl (append entries per phase, never overwrite)
```

**Session folder layout:**
```
work/{session}/
├── scripts/       ← automation scripts from this session
├── handovers/     ← agent-to-agent Markdown handover docs
├── reports/       ← findings, summaries, run results
├── data/          ← data files produced during analysis
├── examples/      ← example artifacts or reference outputs
├── other/         ← miscellaneous
├── temp/          ← strictly temporary; cleaned per session
└── logs/
    └── agent_log.jsonl   ← one JSONL entry per completed phase
```

**Agent log entry format** (append, never overwrite):
```json
{"timestamp":"ISO8601","agent":"Name","session":"session-name","phase":"what was done","skills_used":[],"instructions_loaded":[],"tools_used":[],"commands_run":[],"result":"PASS|FAIL|PARTIAL","findings":[],"handover_to":"NextAgent"}
```

**Rules:**
- `Manager` always starts the session (creates folder + branch.txt)
- Complex tasks (3+ agents or 5+ files) → route to `Planner` BEFORE any other work
- Completed session folders move to `work/archive/` — never delete

### Git Rules

- **Never `git add .`** — stage only files directly changed by the current task
- **Commit format**: `type(scope): description` — types: `feat` `fix` `refactor` `test` `docs` `chore`
- **One logical change per commit** — one accepted task phase = one commit
- **Phase commit sequence**: quality gate → `git add <files>` → `git commit` → log entry → route forward
- **Before every commit**: `cargo test && cargo clippy -- -D warnings`
- **Confirm branch** before committing: `git rev-parse --abbrev-ref HEAD`

### CLI Tools (tools/)

> **Tool directory policy**: `tools/` contains **permanent** CLI scripts only. Temporary or session-scoped scripts go in `work/{session}/scripts/` — never in `tools/`. See `tools/README.md` for the full policy and a complete tool index.

| Command | Purpose |
|---|---|
| `python tools/gen_all_docs.py` | Run the full documentation pipeline (all formats + coverage) |
| `python tools/cag_validate.py` | Validate all `.github/` CAG files |
| `python tools/cag_validate.py --type agent\|skill\|prompt\|instruction` | Validate one family |
| `python tools/cag_validate.py --file <path>` | Validate a single file |
| `python tools/collect_docs.py` | Generate `docs/API/api_generated.md` from `///` comments |
| `python tools/collect_docs.py --report-missing` | List public items missing `///` docs (exit 1 if any) |
| `python tools/collect_docs.py --suggest` | Print starter `///` lines for undocumented items |
| `python tools/doc_coverage.py` | Docstring coverage analytics → `docs/API/doc_coverage.json` |
| `python tools/doc_coverage.py --report-missing` | List all Rust + Lua API items missing doc comments |
| `python tools/test_coverage.py` | Test coverage analytics → `docs/API/test_coverage.json` |
| `python tools/test_coverage.py --suggest` | Print test stubs for uncovered items |
| `python tools/gen_test_docs.py` | Generate `docs/API/test_docs.md` from coverage metadata |
| `python tools/gen_lua_api.py` | Generate `docs/API/lua_api_reference_generated.md` |
| `python tools/gen_wiki_api.py` | Regenerate `wiki/API-Reference.md` cheatsheet |
| `python tools/gen_splash.py` | Regenerate splash screen asset |
| `python tools/gen_icon.py` | Regenerate window icon asset |
| `powershell tools/dist.ps1` | Build + package release binary (Windows) |
| `bash tools/dist.sh` | Build + package release binary (Linux/macOS) |
| `powershell tools/install.ps1` | Install luna.exe locally (Windows) |
| `bash tools/install.sh` | Install luna2d locally (Linux/macOS) |
| `python tools/module_audit.py` | Audit module structure and coverage |
| `python tools/quality_report.py` | Generate quality report |
| `python tools/integration_coverage.py` | Check integration test coverage |

**Rule**: always use CLI tools instead of ad-hoc grep or manual file walks.

### Logging

Luna2D uses the `log` crate facade (`log::info!`, `log::warn!`, `log::error!`, `log::debug!`) activated via `env_logger`.

| Level | Use for |
|---|---|
| `error!` | Unrecoverable — will abort the frame or the session |
| `warn!` | Recoverable problem — degraded behaviour expected |
| `info!` | Lifecycle events: startup, shutdown, script load |
| `debug!` | Per-frame or per-call detail — disabled in release builds |

**Control at runtime**: `RUST_LOG=luna2d=debug cargo run -- examples/hello_world`
**Test output**: captured by `cargo test -- --nocapture` or `RUST_LOG=debug cargo test`
**Never** use `println!` in engine code — always `log::*`.

### Test Diagnostics

| What you want | Command |
|---|---|
| Type-check only (fastest) | `cargo check` |
| Run one Rust test binary | `cargo test --test <binary-name>` |
| Run one Lua dispatcher | `cargo test --test lua_tests <dispatcher-name>` |
| See stdout from tests | `cargo test --test <binary-name> -- --nocapture` |
| Debug log during tests | `$env:RUST_LOG = "debug"; cargo test --test <binary-name> -- --nocapture` |
| Lint library only | `cargo clippy --lib` |
| Run all tests (final gate only) | `cargo test` |
| Format test output | `cargo test -- --format pretty` |

**Key rule**: Use scoped registered test binaries or Lua dispatcher filters during development. Full `cargo test` only at commit time.
Test output files: none by default. Failures print inline. For structured reports: `cargo test 2>&1 | Tee-Object test_results.txt`.

### Docstrings

**Every public item** (`pub struct`, `pub fn`, `pub enum`, `pub trait`, `pub type`, `const`) must have a `///` doc comment.
**Every module** (`mod.rs`, lib.rs) must have a `//!` module-level doc.
**Structure**: one-sentence summary, then optional detail paragraph. No `# Examples` unless the example is runnable and tested.

Verify coverage: `python tools/collect_docs.py --report-missing` (exit 1 if any missing).
Auto-generate starters: `python tools/collect_docs.py --suggest`.

```rust
/// Applies gravity and resolves AABB collisions for all dynamic bodies.
///
/// Call once per frame with the elapsed time in seconds.
pub fn step(&mut self, dt: f32) { … }
```

### Test-Driven Development

**Rust (red → green → refactor)**:
1. Write a failing test in the appropriate registered Rust test file under `tests/unit/`, `tests/ext/`, `tests/game/`, or `tests/stress/`
2. Run `cargo test --test <binary-name>` — confirm it fails
3. Implement the minimum code to make it pass
4. Refactor, keeping tests green

**Lua (describe → script → `cargo run`)**:
1. Write a `main.lua` that exercises the API call you intend to add
2. Run `cargo run -- examples/<name>` — confirm the error message
3. Implement the Lua binding; re-run to confirm the script works

**Rules**:
- New public Rust API → at least one integration test before merge
- Bug fix → regression test first, then fix
- Float comparisons: `assert!((a - b).abs() < 1e-5)` — never `assert_eq!` on `f32`
- Tests must not create windows, play audio, or write outside `target/`
