# Lurek2D Handbook

> Onboarding manual for contributors and game authors. New here? Start at §3.
>
> Companion docs: [README.md](README.md) (one-page intro) · [CONTRIBUTING.md](CONTRIBUTING.md) (PR contract) ·
> [docs/architecture/](architecture/) (deep design) · [docs/specs/](specs/) (per-module reference) ·
> [docs/reports/](reports/) (auto-generated `lurek.*` and Rust references).

---

## Table of Contents

1. [What Lurek2D is](#1-what-lurek2d-is)
2. [Audience map](#2-audience-map)
3. [First 30 minutes](#3-first-30-minutes)
4. [Repository tour](#4-repository-tour)
5. [Build and run](#5-build-and-run)
6. [Writing your first game](#6-writing-your-first-game)
7. [Writing your first engine change](#7-writing-your-first-engine-change)
8. [Documentation system](#8-documentation-system)
9. [Testing](#9-testing)
10. [Quality gates and commits](#10-quality-gates-and-commits)
11. [Working with AI agents (CAG)](#11-working-with-ai-agents-cag)
12. [Where to look when stuck](#12-where-to-look-when-stuck)
13. [Glossary](#13-glossary)

---

## 1. What Lurek2D is

Lurek2D is a desktop 2D game engine written in Rust that loads and executes Lua scripts via LuaJIT. One binary, one scripting language, one afternoon to learn. Source under [src/](../src/) is organised into five responsibility groups — Foundations, Core Runtime, Platform Services, Feature Systems, and Edge/Integration — defined in [architecture/philosophy.md](architecture/philosophy.md) and inventoried in [architecture/engine-architecture.md](architecture/engine-architecture.md). Renderer is `wgpu` (Vulkan / DX12 / Metal); physics is `rapier2d`; audio is `rodio`. Engine version is **0.20.0** ([Cargo.toml](../Cargo.toml)). Licence is MIT. Desktop targets only — Windows, Linux, macOS on x86_64 and ARM (constraint **A-02**).

---

## 2. Audience map

Six personas. Each maps to the handbook sections that matter most.

| Persona      | Who you are                                       | Start here                                | Then read                                                         |
| ------------ | ------------------------------------------------- | ----------------------------------------- | ----------------------------------------------------------------- |
| **GameDev**  | Writing a game in Lua against `lurek.*`.          | §3 First 30 min · §6 First game           | §8 Docs · §9 Testing                                              |
| **EngDev**   | Modifying Rust source under `src/`.               | §3 · §7 First engine change               | §10 Quality gates · §8 Docs                                       |
| **Modder**   | Authoring a Lunasome library or sandboxed mod.    | §3 · §6 (Lua skeleton) · §11 (CAG skills) | [library-authoring](../.github/skills/library-authoring/SKILL.md) |
| **Player**   | Just running shipped games / demos.               | §3 (steps 1–4) only                       | —                                                                 |
| **GameTest** | Writing Lua BDD tests for game/library behaviour. | §3 · §9 Testing                           | [test-framework.md](architecture/test-framework.md)               |
| **EngTest**  | Writing Rust unit / integration / benches.        | §3 · §9 · §10                             | [test-framework.md](architecture/test-framework.md)               |

Personas are formalised in [architecture/cag-system.md § 4](architecture/cag-system.md#4-six-persona-model).

---

## 3. First 30 minutes

A working dev loop in five steps.

1. **Install Rust ≥ 1.78 (stable)**. The repo pins `stable` via [rust-toolchain.toml](../rust-toolchain.toml); `rustup` will pick it up automatically. You also need Python ≥ 3.10 for the docs / validation tooling.
2. **Clone**:
   ```bash
   git clone https://github.com/LurekDude/luna_2d.git
   cd luna_2d
   ```
3. **Build & run the splash screen**:
   ```bash
   cargo run
   ```
   The first build pulls and compiles the dependency tree (≈3–8 minutes on a modern laptop). After that, incremental builds finish in seconds. The splash window opens with no game loaded.
4. **Run a showcase game**:
   ```bash
   cargo run -- content/games/showcase/hello_world
   ```
   Or drag a folder from [content/games/](../content/games/) onto the running splash window.
5. **Open VS Code and accept the workspace extension recommendations** ([extensions/vscode/](../extensions/vscode/)). The Lurek2D Toolkit extension provides scaffolding, run/debug commands, the LuaCATS-driven IntelliSense for `lurek.*`, and the in-editor doc browser. The recommendations also pre-populate [.vscode/tasks.json](../.vscode/tasks.json) — every command in §5 is also a task.

Total cold-start time: about 30 minutes including the first build.

---

## 4. Repository tour

Authoritative layout lives in the system prompt's *Repository Layout* section ([.github/copilot-instructions.md](../.github/copilot-instructions.md)). One sentence per top-level folder:

| Folder                                      | Purpose                                                                                                                       |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [src/](../src/)                             | Rust engine source — 49 modules across the five responsibility groups.                                                        |
| [tests/](../tests/)                         | Rust + Lua test suites; Lua tests are registered manually in [tests/lua/harness.rs](../tests/lua/harness.rs).                 |
| [docs/](.)                                  | Architecture (`architecture/`), per-module specs (`specs/`), generated APIs (`API/`), and the changelog.                      |
| [tools/](../tools/)                         | Permanent CLI scripts: `validate/`, `audit/`, `fix/`, `docs/`, `dev/`, `demos/`, `dist/`, `github/`, `assets/`.               |
| [content/](../content/)                     | Lua content — `games/` (showcase apps), `examples/` (one-file API demos), `library/` (Lunasome libs), `layouts/`, `plugins/`. |
| [.github/](../.github/)                     | CAG layer — system prompt + agents/, skills/, prompts/. See §11.                                                              |
| [extensions/vscode/](../extensions/vscode/) | First-party VS Code extension.                                                                                                |
| [work/](../work/)                           | Active session folders; closed sessions move to `work/archive/`.                                                              |
| [assets/](../assets/)                       | Engine assets shipped with the binary (splash, window icon, embedded fonts).                                                  |
| [build/](../build/)                         | Cargo output (overrides `target/` via [.cargo/config.toml](../.cargo/config.toml)).                                           |

For canonical group-by-group module placement, see [architecture/engine-architecture.md § Complete Module Inventory](architecture/engine-architecture.md#complete-module-inventory).

---

## 5. Build and run

Cargo profiles:

- `cargo build` → `build/debug/lurek2d` — fast incremental, slow runtime, full debug symbols.
- `cargo build --release` → `build/release/lurek2d` — slow build, optimised binary (~20 MB stripped today; target is ≤ 15 MB once the [plugin architecture](architecture/plugins.md) lands).
- `cargo check` — type-check only; the fastest "did I break the build?" loop.

The `build/` directory is the configured Cargo `target-dir` ([.cargo/config.toml](../.cargo/config.toml)). Don't use `target/`.

Feature flags:

- Default: `lua-jit` — vendored LuaJIT 2.1 via `mlua` (constraint **B-01**).
- Fallback: `cargo build --no-default-features --features lua54` — Lua 5.4 for environments where LuaJIT cannot vendor.

Common workspace tasks (see [.vscode/tasks.json](../.vscode/tasks.json)) — invoke from VS Code's *Tasks: Run Task*:

| Task label                              | Equivalent CLI                                                                           |
| --------------------------------------- | ---------------------------------------------------------------------------------------- |
| `Build: Debug`                          | `cargo build`                                                                            |
| `Build: Release`                        | `cargo build --release`                                                                  |
| `Run Debug: Splash (drag-drop ready)`   | Launch `build/debug/lurek2d` without rebuilding                                          |
| `Run Release: Splash (drag-drop ready)` | Launch `build/release/lurek2d` without rebuilding                                        |
| `Test: All`                             | `cargo test`                                                                             |
| `Test: <Module> module`                 | `cargo test --test <module>_tests` (Math, Physics, Graphics, Audio, Input, Lua bindings) |
| `Lint: Clippy (deny warnings)`          | `cargo clippy -- -D warnings`                                                            |
| `Format: Check`                         | `cargo fmt --check`                                                                      |
| `Quality Gate: Full`                    | format check → clippy deny → test all (the canonical pre-PR sweep)                       |

Distribution:

- **Windows**: `Dist: Package Windows` task → `tools/dist/dist.ps1` builds release, copies into `dist/lurek2d-windows-x86_64/` and produces a zip. `Dist: NSIS Installer (Windows)` invokes `makensis tools/dist/installer.nsi`.
- **Linux / macOS**: `Dist: Package Linux / macOS` → `tools/dist/dist.sh` produces a `.tar.gz`.
- **Local install**: `Install: Local (Windows|Linux/macOS)` copies the binary into the user PATH.

---

## 6. Writing your first game

A Lurek2D game is a folder with a `main.lua` (mandatory) and an optional `conf.lua`. The engine fires four optional callbacks (constraint **C-04**: an empty `main.lua` is a valid game).

Smallest possible game — `content/games/showcase/my_game/main.lua`:

```lua
function lurek.load()
    -- One-time setup. Load assets, init state.
    state = { x = 100, y = 100 }
end

function lurek.update(dt)
    -- Per-frame logic. dt is seconds since last frame.
    if lurek.input.isKeyDown("right") then
        state.x = state.x + 200 * dt
    end
end

function lurek.draw()
    -- Per-frame render. Issue draw commands here.
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Move with → key", 20, 20)
    lurek.render.rectangle("fill", state.x, state.y, 32, 32)
end
```

Add a `conf.lua` next to it for window setup (optional):

```lua
function lurek.conf(t)
    t.window.title  = "My Game"
    t.window.width  = 800
    t.window.height = 600
end
```

Run it:

```bash
cargo run -- content/games/showcase/my_game
```

Or build once and drag the `my_game/` folder onto the splash window. Browse the full `lurek.*` surface in [docs/lua-api.md](lua-api.md). For Lua patterns and idioms, see the [lua-scripting](../.github/skills/lua-scripting/SKILL.md) skill.

**Adding assets**. Put a PNG next to `main.lua` and load it in `lurek.load`:

```lua
function lurek.load()
    state = { x = 100, y = 100 }
    state.player = lurek.render.newImage("player.png")
    state.click   = lurek.audio.newSource("click.ogg", "static")
end

function lurek.draw()
    lurek.render.draw(state.player, state.x, state.y)
end

function lurek.mousepressed(x, y, button)
    state.click:play()
end
```

Assets are resolved relative to the game folder by `GameFS`. The sandbox prevents `..` escapes. Supported image formats are PNG (always) and DDS (compressed). Audio formats are OGG Vorbis and WAV — see [Cargo.toml](../Cargo.toml) for the build-time format set. For more single-API examples, browse [content/examples/](../content/examples/).

---

## 7. Writing your first engine change

Workflow for a one-bug-or-feature PR against `src/`.

1. **Pick a module** under [src/](../src/) (e.g. `src/timer/`).
2. **Read its spec** at [docs/specs/timer.md](specs/timer.md) — types, functions, Lua API surface, current test paths. The spec is the canonical contract.
3. **Make the Rust change**. Follow the file-structure rules in [architecture/engine-architecture.md § Module Internal File Structure Standard](architecture/engine-architecture.md#module-internal-file-structure-standard): thin `mod.rs`, `<primary>.rs` for logic, no `impl LuaUserData` outside `src/lua_api/`, no `wgpu::*` outside `src/render/`. Every new `pub` item gets a `///` doc comment (constraint **Q-05**).
4. **Regenerate auto-spec sections**:
   ```bash
   python tools/gen_all_docs.py
   ```
   This rewrites the *Files / Types / Functions / Lua API Reference / References* sections of every affected spec and refreshes [docs/lua-api.md](lua-api.md), [docs/reports/rust-api.md](reports/rust-api.md), and [docs/lurek.lua](lurek.lua).
5. **Update the spec's manual sections** (`## Summary`, `## Notes`) only if behaviour changed in a user-visible way.
6. **Add tests** — Lua first. The Lua-first rule is binding: behaviour observable through `lurek.*` MUST be tested in Lua under [tests/lua/](../tests/lua/), and the new test file must be registered manually in [tests/lua/harness.rs](../tests/lua/harness.rs). Reach for [tests/rust/unit/](../tests/rust/unit/) only for internals not reachable from Lua.
7. **Run quality gates** (§10).
8. **Commit** with `type(scope): description` — see §10 for format.

For a deeper walkthrough including the Thin Wrapper Rule for new `lurek.*` APIs, load the [lua-rust-bridge](../.github/skills/lua-rust-bridge/SKILL.md) and [rust-coding](../.github/skills/rust-coding/SKILL.md) skills.

---

## 8. Documentation system

Three docs tiers. Each has a different lifecycle:

| Tier                         | Location                            | Lifecycle                                                                                                                                                       |
| ---------------------------- | ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Architecture (narrative)** | [docs/architecture/](architecture/) | Hand-written. Index at [architecture/README.md](architecture/README.md).                                                                                        |
| **Per-module specs**         | [docs/specs/](specs/)               | Mixed: `Summary` and `Notes` are manual prose; everything else is regenerated by `tools/docs/gen_module_specs.py`. Index at [specs/README.md](specs/README.md). |
| **Generated API references** | [docs/reports/](reports/)             | Fully auto-generated by `python tools/gen_all_docs.py`. Never hand-edit.                                                                                        |

The cross-artifact sync table in the system prompt ([.github/copilot-instructions.md § Cross-Artifact Sync](../.github/copilot-instructions.md)) tells you which docs to update when source changes. Regenerate generated docs after any public-API change. Module-spec manual-vs-auto rules are documented in [docs/specs/SPEC_TEMPLATE.md](specs/SPEC_TEMPLATE.md) and enforced by `python tools/audit/validate_agent_md.py`.

---

## 9. Testing

The Lua-first testing rule is binding (see [philosophy.md § Testing Constraints](architecture/philosophy.md#testing-constraints), constraints **TST-01**..**TST-04**): behaviour observable through `lurek.*` is tested in Lua. Rust unit tests under [tests/rust/unit/](../tests/rust/unit/) are reserved for internals not reachable through Lua bindings.

### Testing rules for contributors

- **Write Lua tests by default.** If your change affects anything a game script can see, test it under [tests/lua/](../tests/lua/).
- **Rust unit tests are for internals only.** Put them in [tests/rust/unit/<module>_tests.rs](../tests/rust/unit/). Never add `#[cfg(test)]` blocks inside `src/`.
- **Keep `src/lua_api/*_api.rs` and every `mod.rs` thin.** Business logic goes in `src/<module>/*.rs` sibling files. See **TST-03** and **TST-04** in [philosophy.md § Testing Constraints](architecture/philosophy.md#testing-constraints).

Full decision tree and banned-patterns list: [test-framework.md § Test placement](architecture/test-framework.md#test-placement).

Two test layers (full design in [architecture/test-framework.md](architecture/test-framework.md)):

- **Rust** — `cargo test`. Per-module suites under `tests/rust/unit/<module>_tests.rs`. Float comparisons use absolute tolerance, never `assert_eq!` on `f32`.
- **Lua BDD** — `cargo test lua_test_<category>_<name>`. Files under [tests/lua/](../tests/lua/) using `describe` / `it` / `expect_equal` from [tests/lua/init.lua](../tests/lua/init.lua). Every Lua test file must end with `test_summary()`.

Adding a new Lua test:

1. Create `tests/lua/<category>/test_<name>.lua`.
2. Add a matching `#[test] fn lua_test_<category>_<name>()` entry in [tests/lua/harness.rs](../tests/lua/harness.rs) — auto-discovery is intentionally not used.
3. Run: `cargo test lua_test_<category>_<name> -- --nocapture`.

Common test workspace tasks: `Test: All`, `Test: Math module`, `Test: Physics module`, `Test: Graphics module`, `Test: Audio module`, `Test: Input module`, `Test: Lua bindings`. See §5.

Evidence vs golden suites: evidence files produce artefacts (screenshots, logs); golden files are compare-only baselines. Audit with `python tools/audit/lua_evidence_golden_contract_audit.py`.

Skeleton of a Lua BDD test:

```lua
local t = require("tests.lua.init")

t.describe("timer", function()
    t.it("counts up monotonically", function()
        local first  = lurek.timer.getTime()
        local second = lurek.timer.getTime()
        t.expect_true(second >= first)
    end)
end)

t.test_summary()
```

For Rust tests, place per-module suites under `tests/rust/unit/<module>_tests.rs`. Name tests `<subject>_<scenario>_<expected>` (no `test_` prefix). Float comparisons must use absolute tolerance: `assert!((actual - expected).abs() < 1e-5)`.

---

## 10. Quality gates and commits

From the system prompt's *Quality Gates* section ([.github/copilot-instructions.md](../.github/copilot-instructions.md)) — run all of these before any commit:

- `cargo test && cargo clippy -- -D warnings` (constraints **Q-01**, **Q-02**).
- `python tools/validate/cag_validate.py` — gates the `.github/` CAG layer. Use `--baseline` to fail only on regressions.
- `python tools/audit/doc_coverage.py` and `python tools/audit/test_coverage.py` — coverage audits.
- `python tools/gen_all_docs.py` — regenerate generated API references after any public-API change.
- Add or extend an entry under the current version in [docs/CHANGELOG.md](CHANGELOG.md). Versioning is MAJOR.MINOR.PATCH; bumping MAJOR or MINOR also updates [Cargo.toml](../Cargo.toml).
- Confirm branch with `git rev-parse --abbrev-ref HEAD` and stage only the files you actually changed — never `git add .`.
- Commit format: `type(scope): description` where `type` ∈ {`feat`, `fix`, `refactor`, `test`, `docs`, `chore`}. **One logical change per commit.**

**Before pushing** checklist:

- [ ] All quality gates green locally.
- [ ] CHANGELOG entry added under the current version.
- [ ] Specs regenerated if you touched `src/<module>/*.rs` or `src/lua_api/*_api.rs`.
- [ ] Lua test added if you added or changed a `lurek.*` function (constraint **C-04**).
- [ ] Rust integration test added if you added a `pub fn` / `pub struct` / `pub enum` / `pub trait` (constraint **Q-03**).
- [ ] Branch is the right one (`git rev-parse --abbrev-ref HEAD`).
- [ ] Staged files match the logical change scope.

The full `Quality Gate: Full` workspace task (§5) bundles fmt + clippy + test in one click.

---

## 11. Working with AI agents (CAG)

The **CAG layer** (Context Augmented Guidance) lives under [.github/](../.github/) and customises how Copilot — or any agent honouring Markdown system prompts — works in this repo. Five artifact types: the system prompt, agents, skills, prompts, and companion files.

- **System prompt** ([.github/copilot-instructions.md](../.github/copilot-instructions.md)) is the only file always loaded; it teaches the agent how to find everything else.
- **Agents** under `.github/agents/` are workflow specialists (`Architect`, `Developer`, `Doc-Writer`, `Tester`, …). Each declares which personas it serves.
- **Skills** under `.github/skills/<name>/` are deep domain knowledge loaded on demand when the user task matches the skill's `description`.
- **Prompts** under `.github/prompts/<verb>-<noun>.prompt.md` are user-invocable playbooks, surfaced as slash commands. Example: `/run-quality-sweep`, `/audit-module`, `/create-demo`.

Full deep dive in [architecture/cag-system.md](architecture/cag-system.md). When working with an agent on a multi-step change, route through `Manager` — it engages `Planner` for ≥ 3-agent or ≥ 5-file tasks before any implementation.

Common slash prompts — each one is a parameterised playbook under [.github/prompts/](../.github/prompts/):

| Prompt                  | What it does                                                              |
| ----------------------- | ------------------------------------------------------------------------- |
| `/run-quality-sweep`    | Runs the full audit → diagnose → fix → verify cycle across the repo.      |
| `/run-quality-gates`    | Equivalent to the `Quality Gate: Full` task: fmt + clippy + test.         |
| `/run-cag-validation`   | Runs `tools/validate/cag_validate.py` and reports any errors / warnings.  |
| `/audit-module`         | Per-module quality audit (docs, tests, architecture, Lua bindings).       |
| `/create-demo`          | Scaffolds a new showcase under `content/games/showcase/<name>/`.          |
| `/create-engine-module` | Scaffolds a new `src/<module>/` skeleton + spec.                          |
| `/create-api-function`  | Adds a new `lurek.*` function across Rust, Lua bindings, docs, and tests. |
| `/fix-failing-tests`    | Diagnoses and repairs failing Rust or Lua tests.                          |
| `/review-code-quality`  | Reviewer agent quality pass before commit.                                |

All prompts are listed in [.github/prompts/](../.github/prompts/); browse there for the complete set.

---

## 12. Where to look when stuck

| Symptom                                      | Where to look                                                                                                                                                                     |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Build fails on a fresh clone                 | Verify Rust ≥ 1.78; delete `build/` and retry. See [build-system](../.github/skills/build-system/SKILL.md).                                                                       |
| `lurek.*` function isn't documented          | Run `python tools/gen_all_docs.py`; check [docs/lua-api.md](lua-api.md).                                                                                                  |
| Module's spec is out of date                 | `python tools/docs/gen_module_specs.py`; manual `Summary` / `Notes` are preserved.                                                                                                |
| Lua test runs but isn't registered           | Add a `#[test] fn lua_test_<category>_<name>()` in [tests/lua/harness.rs](../tests/lua/harness.rs).                                                                               |
| CAG validator fails                          | `python tools/validate/cag_validate.py --format text`; see [tools-cag-validation](../.github/skills/tools-cag-validation/SKILL.md).                                               |
| Game crashes only in release mode            | Reproduce with `cargo run --release`; load [dev-debugging](../.github/skills/dev-debugging/SKILL.md) skill.                                                                       |
| Don't know which module a feature belongs to | [architecture/engine-architecture.md § Complete Module Inventory](architecture/engine-architecture.md#complete-module-inventory).                                                 |
| Need to design a new `lurek.*` API           | [lua-api-design](../.github/skills/lua-api-design/SKILL.md) skill.                                                                                                                |
| Need to add a new module                     | [architecture/engine-architecture.md § Module Internal File Structure Standard](architecture/engine-architecture.md#module-internal-file-structure-standard) + `Architect` agent. |
| Need a new agent / skill / prompt            | [architecture/cag-system.md § 6 Authoring Guides](architecture/cag-system.md#6-authoring-guides).                                                                                 |
| Plugin / size question                       | [architecture/plugins.md](architecture/plugins.md).                                                                                                                               |

---

## 13. Glossary

| Term                                | Meaning                                                                                                                                                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`lurek.*`**                       | The single Lua API namespace. All scripting goes through it. Rule **C-01**, defined in [architecture/philosophy.md](architecture/philosophy.md).                                                                   |
| **CAG**                             | Context Augmented Guidance — the `.github/` layer customising AI workflows. [architecture/cag-system.md](architecture/cag-system.md).                                                                              |
| **CORE-KEEP**                       | Plugin tier for modules that always ship in the core binary. [architecture/plugins.md § 4](architecture/plugins.md#4-plugin-tiers).                                                                                |
| **DAG (no-cycles rule)**            | Module import graph must remain acyclic. Zen Rule 1 / constraint **T-03**, [architecture/philosophy.md](architecture/philosophy.md).                                                                               |
| **ECS**                             | Entity-Component-System. Lurek2D's lightweight implementation lives in `src/ecs/` ([docs/specs/ecs.md](specs/ecs.md)).                                                                                             |
| **Edge/Integration**                | The top responsibility group: `app`, `lua_api`, `devtools`, `debugbridge`, `docs`, `pipeline`, `bin`. [architecture/engine-architecture.md](architecture/engine-architecture.md#module-group-model).               |
| **GameFS**                          | Sandboxed filesystem facade preventing path traversal out of the game folder. `src/filesystem/`, [docs/specs/filesystem.md](specs/filesystem.md).                                                                  |
| **Lunasome**                        | Pure-Lua standard library at [content/library/](../content/library/). Consumes only public `lurek.*` APIs.                                                                                                         |
| **LuaJIT**                          | The shipping Lua runtime via `mlua` (constraint **B-01**). Lua 5.4 is a non-shipping fallback. [architecture/philosophy.md](architecture/philosophy.md).                                                           |
| **Persona**                         | One of six target user profiles (EngDev, GameDev, Modder, Player, GameTest, EngTest). [architecture/cag-system.md § 4](architecture/cag-system.md#4-six-persona-model).                                            |
| **Plugin tier**                     | One of CORE-KEEP / TIER-1-PLUGIN / TIER-2-PLUGIN / THIRD-PARTY-PLUGIN. [architecture/plugins.md § 4](architecture/plugins.md#4-plugin-tiers).                                                                      |
| **`RenderCommand`**                 | The single GPU-agnostic enum that every renderer-bound subsystem emits. [architecture/render-command-architecture.md](architecture/render-command-architecture.md).                                                |
| **`SharedState`**                   | The `Rc<RefCell<...>>` hub holding every runtime resource pool. `src/runtime/shared_state.rs`. [architecture/engine-architecture.md § State Architecture](architecture/engine-architecture.md#state-architecture). |
| **Skill**                           | On-demand domain knowledge under `.github/skills/<name>/SKILL.md`, loaded when the user task matches. [architecture/cag-system.md § 2](architecture/cag-system.md#2-file-type-catalog).                            |
| **Sweep**                           | The end-of-session CAG-Architect review confirming `.github/` changes are valid. [architecture/cag-system.md § 7](architecture/cag-system.md#7-end-of-session-cag-sweep-contract).                                 |
| **Thin Wrapper Rule**               | `src/lua_api/<module>_api.rs` owns ALL `impl LuaUserData` and `mlua` imports; domain modules under `src/<module>/` stay pure-Rust. Zen Rule 12 / constraint **T-02**.                                              |
| **TOML / `conf.toml` / `conf.lua`** | TOML is the human-authored config format (constraint **B-05**); per-game config lives in `conf.toml` (preferred) or `conf.lua` (legacy fallback).                                                                  |
| **`work/<session>/`**               | Per-session scratch folder with `scripts/`, `handovers/`, `reports/`, `data/`, `examples/`, `other/`, `temp/`, `logs/`. Closed sessions move to `work/archive/`.                                                   |
| **`mlua`**                          | Rust binding crate to LuaJIT / Lua 5.4. Owns all `impl LuaUserData` boundaries inside `src/lua_api/`.                                                                                                              |
| **`wgpu`**                          | Cross-platform GPU abstraction (Vulkan / DX12 / Metal). Constraint **B-02** — only renderer backend in Lurek2D.                                                                                                    |
| **`rapier2d`**                      | The 2D rigid-body physics engine used by `src/physics/`. Heavy crate tree — part of the case for plugin tier-2.                                                                                                    |
| **Quality Gate**                    | The set of must-pass checks before a commit: tests, clippy, CAG validator, doc coverage. §10.                                                                                                                      |
| **Spec**                            | Per-module reference at [docs/specs/<module>.md](specs/), mixing manual `Summary`/`Notes` with auto-regenerated sections.                                                                                          |
