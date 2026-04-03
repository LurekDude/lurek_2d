# Luna2D Engine — System Prompt

Luna2D is a 2D game engine written in Rust that loads and executes Lua game scripts.
This file is the always-on backbone for AI-assisted development in the Luna2D repository.

- **CAG load order**: System Prompt → Instructions (auto-load by file glob) → Skills (load on-demand) → Prompts → Agents
- **Tech baseline**: Rust stable ≥1.78 | LuaJIT vendored via mlua 0.9 (Lua 5.4 `lua54` feature = non-shipping fallback) | wgpu 22 | winit 0.30 | rapier2d 0.32 | rodio 0.17 | fontdue 0.9
- **Source of truth**: [`docs/zen-of-luna.md`](../docs/zen-of-luna.md) (first principles) · [`docs/design-assumptions.md`](../docs/design-assumptions.md) (binding constraints) · [`docs/architecture.md`](../docs/architecture.md) (module structure, tier system, dependency graph). Consult all three before implementing any feature or making an architectural decision.
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
| A-04 | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core engine binary. Platform integrations are Tier 4 — out of scope for Tier 1–3 modules |
| B-01 | **LuaJIT** is the primary scripting runtime. Lua 5.4 (`lua54` cargo feature) is a non-shipping development fallback |
| B-02 | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal). No raw OpenGL path |
| B-03 | Games must run acceptably on **integrated GPUs** (Intel UHD, AMD APU) |
| B-04 | Concurrency lives in **Rust threads**. LuaJIT VMs cannot share state; Lua-to-Lua comms use `Channel` objects |
| B-05 | **TOML** is the human-authored config format. JSON is only for external interop. YAML is not used |

## Quick Start

### Build and Run

```powershell
cargo build                           # Debug build
cargo build --release                 # Release build
cargo run                             # Splash screen (no game)
cargo run -- examples/hello_world     # Run example
cargo run -- path/to/my_game          # Run custom game
```

### Running Tests

```powershell
cargo test                            # All tests — DO NOT run cargo build first
cargo test physics_tests              # Single module
cargo test -- --nocapture             # Show stdout from tests
RUST_LOG=debug cargo test -- --nocapture  # Debug output
```

> **Policy**: Run `cargo test` directly. Never prefix with `cargo build` — `cargo test` builds what it needs automatically. Do not create a separate build step before running tests.

### Quality Gates

```powershell
cargo clippy                          # Lint — must pass with 0 warnings
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
- **Module direction and tier system**: All source modules belong to one of four tiers plus two foundation layers. See the full tier table in [`docs/architecture.md`](../docs/architecture.md). Short form:
  - **Foundation**: `math` (leaf, no deps), `engine` (may import all)
  - **Tier 1 Basic Core**: `graphics`, `audio`, `physics`, `input`, `timer`, `filesystem`, `compute`, `data`, `image`, `sound`, `event`, `entity`, `window`, `thread` — may only import `math` + `engine`; no Tier 1 ↔ Tier 1 cross-imports
  - **Tier 2 Engine Extensions**: `particle`, `tilemap`, `scene`, `savegame`, `modding`, `graph`, `pathfinding`, `ai`, `dataframe`, `resource` — may import math, engine, and Tier 1; no Tier 2 ↔ Tier 2 cross-imports
  - **Tier 3 Gameplay Systems**: `combat`, `crafting`, `dialog`, `inventory`, `item`, `quest`, `stats`, `province_map` — may import Tier 1 and Tier 2; no Tier 3 ↔ Tier 3 cross-imports
  - **Tier 4 Platform Integrations** (future): Steam, Epic, etc. — must not be imported by lower tiers
  - `lua_api` is the bridge layer above all tiers; domain modules never import it
- **Physics backend**: rapier2d 0.32 provides rigid-body simulation with circles, rectangles, sensors, raycasting, joints, and collision event recording via `src/physics/`.

### Module Dependency Graph

```
math (leaf — no internal deps)
  ↑
engine ← Tier 1 (graphics, audio, physics, input, timer, filesystem,
  ↑              compute, data, image, sound, event, entity, window, thread)
  ↑
  ← Tier 2 (particle, tilemap, scene, savegame, modding, graph,
  ↑          pathfinding, ai, dataframe, resource)
  ↑
  ← Tier 3 (combat, crafting, dialog, inventory, item, quest, stats, province_map)
  ↑
  ← Tier 4 (future: Steam, Epic, platform SDKs)
  ↑
lua_api (integration layer — imports all tiers)
```

- `math` is the only module all other modules may freely import
- Tier 1 modules may only import `math` and `engine` — no Tier 1 ↔ Tier 1 cross-imports
- Tier 2 modules may import `math`, `engine`, and Tier 1 — no Tier 2 ↔ Tier 2 cross-imports
- Tier 3 modules may import Tier 1 and Tier 2 — no Tier 3 ↔ Tier 3 cross-imports
- Tier 4 (future) wraps external platform SDKs — not imported by lower tiers
- `lua_api` is the integration layer; it may import any module
- `engine` provides `SharedState`, `EngineError`, `Config`, `App`
- Domain modules never import `lua_api`

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

Luna2D has a **two-layer test system** — Rust integration tests and Lua BDD tests — both executed via `cargo test`.

**Rust integration tests** (`tests/<module>_tests.rs`)
- Auto-discovered by Cargo; one file per module
- Import from crate root: `use luna2d::module::Type;`
- Naming: `<subject>_<scenario>_<expected>` — no `test_` prefix
- Float: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats

**Lua BDD tests** (`tests/lua/`)
- Dispatched by `tests/lua/harness.rs` — every `.lua` file needs one `#[test]` entry there
- Framework (`tests/lua/init.lua`) provides: `describe` / `it` / `expect_equal` / `expect_near` / `expect_type` / `expect_error` etc.
- Every Lua test file ends with `test_summary()` — mandatory
- Layers: `unit/` (one module), `integration/` (cross-module), `stress/` (performance), `validation/` (negative-path), `golden/` (deterministic output)
- VM is headless: no GPU, no audio, no window — never call `luna.graphics.draw*` in tests

**VM helpers (Rust side):**
- `create_test_vm()` → full Lua VM with BDD framework loaded and `_test_results` global
- `make_vm()` → `(Rc<RefCell<SharedState>>, Lua)` for stateful Rust-side tests

**Adding a new Lua test:**
1. Create `tests/lua/unit/test_<module>.lua` using `describe`/`it`/`expect_*`
2. Add `#[test] fn lua_test_<module>() { run_lua_test("unit/test_<module>.lua"); }` to `tests/lua/harness.rs`
3. Run: `cargo test lua_test_<module>`

**Quality gates:**
- `cargo test` — all suites must exit 0
- `cargo clippy -- -D warnings` — must exit 0
- `python tools/test_coverage.py` — coverage analytics
- `python tools/collect_docs.py --report-missing` — lists undocumented public items (exit 1 if any)

**Constraints:**
- Lua tests MUST NOT require a window, GPU, or audio device
- New `luna.*` API functions require at least one Lua test before merge
- Stress tests live in `tests/stress/` (Rust) and `tests/lua/stress/` (Lua)
- Golden tests: expected files in `tests/golden/expected/`; actual output in `tests/golden/actual/` (git-ignored)

### File Structure

```
src/          — Rust source code (28 modules)
examples/     — Lua game examples (13 demos)
tests/        — Integration tests (28 test files + stress/ + lua/ + golden/)
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
| Run all tests | `cargo test` |
| Run one module | `cargo test physics_tests` |
| See stdout from tests | `cargo test -- --nocapture` |
| Debug log during tests | `RUST_LOG=debug cargo test -- --nocapture` |
| Format test output | `cargo test -- --format pretty` |

Test output files: none by default. Failures print inline. For structured reports, pipe to `cargo test 2>&1 | Tee-Object test_results.txt`.

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
1. Write a failing test in `tests/<module>_tests.rs` that names the expected behaviour
2. Run `cargo test <module>_tests` — confirm it fails
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
