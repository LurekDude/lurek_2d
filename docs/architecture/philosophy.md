# Luna2D — Philosophy and Design Assumptions

> **Source of truth** for first principles, binding architectural decisions, and project identity.
> Companion documents: [engine-architecture.md](engine-architecture.md) (runtime module structure) · [test-framework.md](test-framework.md) (test architecture).

---

## Table of Contents

1. [The Zen of Luna](#the-zen-of-luna)
2. [Core Idea](#core-idea)
3. [Project Identity](#project-identity)
4. [Decision Heuristics](#decision-heuristics)
5. [Platform and Runtime Constraints](#platform-and-runtime-constraints)
6. [Technology Stack Constraints](#technology-stack-constraints)
7. [Active Layer Model Constraints](#active-layer-model-constraints)
8. [API Design Constraints](#api-design-constraints)
9. [Quality Gate Constraints](#quality-gate-constraints)
10. [Constraint Status Model](#constraint-status-model)
11. [Retired Decisions](#retired-decisions)

---

## The Zen of Luna

These ten principles are the soul of the project. They are not aspirational guidelines — they are **binding constraints**. Every feature proposal, API design, and architectural decision must be checked against this list. If a choice violates a principle, the choice changes or the principle is formally amended — never silently overridden.

### 1. One Executable, One Install

The engine ships as a single binary. No installer, no runtime dependencies, no DLL side-loading, no "install SDK A, then framework B, then plugin C." A user downloads `luna2d` (or `luna2d.exe`), drops it next to `main.lua`, and runs. **~20 MB** target file size, forever.

This is the David vs. Goliath promise: a 20 MB engine competing with multi-gigabyte toolchains. If a feature would require the user to install a separate component, it either gets statically linked or it doesn't ship.

→ See [engine-architecture.md](engine-architecture.md) § Boot Sequence.

### 2. Lua Scripts Are the Game

The engine is a runtime. The game is Lua. Everything the game creator touches is `.lua` — logic, configuration, scene definitions, dialogue trees, UI layouts. Rust owns the GPU, the physics solver, and the OS layer. Lua owns everything the player experiences.

The `conf.lua` → `main.lua` → `luna.load()` → `luna.update(dt)` → `luna.draw()` pipeline is the only contract between engine and game. It is deliberately simple so that someone — human or AI — can look at it for ten seconds and know where to start.

→ See [engine-architecture.md](engine-architecture.md) § Callback Contract.

### 3. Engine Is Silent Unless Something Is Wrong

No startup banners. No debug chatter. No "asset pipeline started." The engine runs. If it needs to tell you something, it uses `log::warn!` or `log::error!` — and the message is actionable. `info!` is reserved for lifecycle events (loaded, shutdown). `debug!` is reserved for per-frame diagnostics behind `RUST_LOG=debug`.

Production builds must not produce any terminal output during normal operation.

### 4. Layer Model Is Load-Bearing

The Baseline → Tier 1 → Tier 2 → Tier 3 (Lunasome) layered architecture is not an organizational suggestion — it is a **structural invariant** enforced by import direction rules.

- `math` depends on nothing.
- `engine` depends on `math`.
- Tier 1 depends on Baseline only — no Tier 1 ↔ Tier 1 cross-imports.
- Tier 2 depends on Baseline + Tier 1 — no Tier 2 ↔ Tier 2 cross-imports.
- `lua_api` bridges everything — no domain module imports `lua_api`.
- `library/` (Tier 3) consumes public `luna.*` APIs — no Rust internals.

This is a DAG (directed acyclic graph). Circular dependencies are forbidden. Every proposed module must declare its tier before implementation starts.

→ See [engine-architecture.md](engine-architecture.md) § Active Layer Model, § Module Dependency Graph.

### 5. Tests Are Proof, Not Process

Tests exist to prove the engine works. They are not ceremony. Red → green → refactor is the rhythm, not a bureaucratic checklist.

- **Rust tests** prove internal contracts.
- **Lua BDD tests** prove the API surface from the user's perspective.
- **Golden tests** prove deterministic output.
- **Stress tests** prove the engine survives adversarial workloads.

If a test doesn't prove something that could break, delete it.

→ See [test-framework.md](test-framework.md) for the complete test architecture.

### 6. Platform Concerns Stay Outside the Stack

Steam, Epic, itch.io, Android, iOS, WASM — all of these are real, all are important, and none of them belong in the active Baseline → Tier 1 → Tier 2 → Tier 3 stack. The moment you couple a rendering call to a platform SDK, you've broken the portability of the entire stack below it.

Platform integrations live at Tier 4 (future) or in external wrapping binaries. They may never be imported by Tier 1, 2, or 3 modules.

### 7. Engine Runs on a Laptop from 2018

If it doesn't run on a 2018 laptop with an integrated GPU (Intel UHD 620, AMD Vega 8), it doesn't ship. Performance is measured on low-end hardware, not high-end developer machines.

This means:
- No features that require dedicated GPU memory >512 MB.
- No shader features beyond wgpu baseline capabilities.
- Frame budget: 16.6ms at 1080p on integrated graphics.
- Aggressive batching and culling — every draw call counts.

→ See constraint B-03 in [Technology Stack Constraints](#technology-stack-constraints).

### 8. Blank main.lua Is Valid

An empty `main.lua` produces a black window. No crash, no error, no complaint. Every `luna.*` callback is optional. This is the entry point for beginners: start with nothing, add one thing, see it work.

This principle constrains API design: every function must have sensible defaults. If a beginner would always pass the same value for a parameter, that value is the default and the parameter is optional.

→ See constraint C-04 in [API Design Constraints](#api-design-constraints).

### 9. Desktop First, Desktop Only

Windows, macOS, Linux — x86_64 and ARM. **No mobile. No WASM.** This is not a limitation; it is a focus decision.

Trying to support mobile and web would inject conditional compilation, touch-first interaction patterns, and deployment complexity into every module. The engine is better for the platforms it targets by ignoring the platforms it doesn't.

→ See constraint A-02 in [Platform and Runtime Constraints](#platform-and-runtime-constraints).

### 10. Lua Is Synchronous; Rust Is Parallel

From the script author's perspective, every `luna.*` call completes immediately and returns a result. There are no promises, no callbacks-after-callbacks, no async/await. The script is a linear, readable sequence of operations.

Behind the scenes, Rust runs background threads for audio decoding, physics stepping, and worker tasks. But the Lua VM never sees them. Cross-thread communication happens through `Channel` objects — a typed, thread-safe MPMC queue with `push`, `pop`, and `demand` (blocking pop).

Each worker thread gets its own Lua VM. Lua VMs cannot share state. This eliminates an entire category of concurrency bugs.

→ See [engine-architecture.md](engine-architecture.md) § Threading Model.

---

## Core Idea

Luna2D is the engine for people who think game engines have become too complicated.

A game is a `main.lua` file. The engine runs it. You write Lua; the engine owns the GPU, the physics solver, the audio mixer, and the threading model. You never see a `.dll`, a `.framework`, or a build system. You see `luna.update(dt)` and `luna.draw()`.

The competitive landscape is dominated by multi-gigabyte engines with visual editors, plugin marketplaces, and months-long learning curves. Luna2D is the opposite: one binary, one scripting language, one afternoon to learn.

**The AI angle**: Luna2D is the first game engine designed with AI copilots as first-class users. Every API is shaped so an AI agent can use it correctly from the docs alone. The CAG layer, the VS Code extension, and the documentation pipeline are all optimized for AI-assisted workflow. When an AI writes `luna.gfx.draw(img, x, y)`, it should work on the first try, every time.

---

## Project Identity

Luna2D's visual identity is built on a set of symbols that tell the David vs. Goliath story:

| Symbol | Meaning | Where It Appears |
|---|---|---|
| 🌙 Crescent Moon | Lua (Portuguese for "moon") — the scripting surface | Logo, splash screen |
| ⚙️ Gear / Pacman shape | Rust engine core — industrial-strength, consuming scripts | Logo (primary shape) |
| 🧊 Small Cube | The industry giants (Unity, Unreal, Godot) — orbiting Luna2D | Logo (accent) |
| Deep blue + orange palette | Night sky + warm engine glow | All branding materials |

**Naming convention**: "Luna" (engine) + "2D" (scope constraint). Short form: `luna2d`. Binary name: `luna2d` (Unix), `luna2d.exe` (Windows). Lua API prefix: `luna.*`.

---

## Decision Heuristics

When two paths are available and neither violates a principle above, use these heuristics to choose:

| Heuristic | Meaning |
|---|---|
| **Simpler is better** | Fewer moving parts. Fewer concepts. Fewer files. |
| **Explicit over implicit** | Name things directly. Avoid magic. If a Copilot agent can't infer it from the signature, it's too implicit. |
| **Defaults over configuration** | Ship the 80% case. Make the other 20% possible but optional. |
| **Rust performance, Lua ergonomics** | If the user touches it, it should feel Lua-native. If the engine owns it, optimize in Rust. |
| **Test the contract, not the implementation** | Tests should break when behavior changes, not when code is refactored. |
| **One canonical place** | Every rule, every pattern, every convention has exactly one source of truth. Reference it, don't duplicate it. |
| **AI-verifiable** | Could a Copilot agent use this API correctly without a clarifying question? If no, redesign. |

---

## Platform and Runtime Constraints

These are **active, binding decisions**. All code must comply. Do not propose changes without first opening a design-assumption update discussion.

| ID | Status | Constraint |
|---|---|---|
| **A-01** | Active | Luna2D is a **runtime only** — no embedded visual editor or IDE. The VS Code extension is an opt-in developer experience layer, not part of the engine binary. |
| **A-02** | Active | **Desktop only** — Windows / Linux / macOS, x86_64 + ARM. Mobile (iOS / Android) and WASM are out of scope. |
| **A-03** | Active | **2D graphics only** — no 3D scene graph, no perspective projection pipeline. Raycasting columns and isometric rendering are acceptable because they use 2D draw calls. |
| **A-04** | Active | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core engine binary. Platform wrappers live outside the Baseline → Tier 1 → Tier 2 → Tier 3 stack. |

---

## Technology Stack Constraints

| ID | Status | Constraint |
|---|---|---|
| **B-01** | Active | **LuaJIT** is the primary scripting runtime, vendored through mlua 0.9. Lua 5.4 (`lua54` Cargo feature) is a non-shipping development fallback — it exists for fallback testing and CI environments where LuaJIT is unavailable. |
| **B-02** | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal via the wgpu abstraction). No raw OpenGL path, no software fallback. |
| **B-03** | Active | Games must run acceptably on **integrated GPUs** (Intel UHD 620, AMD Vega 8 class). No feature requirements beyond wgpu baseline capabilities. Performance target: 60 FPS at 1080p with a reasonable draw call count. |
| **B-04** | Active | Concurrency lives in **Rust threads**. LuaJIT VMs are single-threaded and cannot share state. Inter-VM communication uses typed MPMC `Channel` objects. |
| **B-05** | Active | **TOML** is the human-authored configuration format. JSON is accepted for external interop (e.g., exported save files, API data). YAML is not used anywhere in the project. |

---

## Active Layer Model Constraints

These constraints formalize the [layer model](engine-architecture.md#active-layer-model) as enforceable rules.

| ID | Status | Constraint |
|---|---|---|
| **T-01** | Active | The active module stack is **Baseline + Tier 1 + Tier 2 + Tier 3**. Baseline is the always-on runtime substrate (`src/math/`, `src/engine/`). Tier 3 is **Lunasome**, the pure-Lua standard library (`library/`). |
| **T-02** | Active | `lua_api` is the **bridge layer** that registers `luna.*`. It is not a numbered tier. It may import all Rust tiers. |
| **T-03** | Active | **Tier 1** Rust modules may only import `math` and `engine`. No Tier 1 ↔ Tier 1 cross-imports. |
| **T-04** | Active | **Tier 2** Rust modules may import `math`, `engine`, and any Tier 1 module. No Tier 2 ↔ Tier 2 cross-imports. |
| **T-05** | Active | **Tier 3** consists of pure-Lua libraries under `library/`. They consume public `luna.*` APIs and must not depend on Rust engine internals. |
| **T-06** | Active | No Rust domain module may import `lua_api`. The `lua_api` crate is the integration endpoint, not a dependency. |
| **T-07** | Active | Legacy gameplay-oriented Rust modules still under `src/` are **migration-state**. Keep them buildable but do not document them as the current Tier 3 layer. Do not add features to them. |
| **T-08** | Proposed | Future Cargo feature flags may expose Baseline / Core / Extended / Lunasome build variants corresponding to the active layer model. Not yet implemented. |

---

## API Design Constraints

| ID | Status | Constraint |
|---|---|---|
| **C-01** | Active | All Lua-facing APIs live under the `luna.*` namespace. No bare globals, no engine-prefixed names, no alternative top-level tables. |
| **C-02** | Active | Every `lua_api` sub-module exposes exactly one `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`. |
| **C-03** | Active | API functions must have **sensible defaults** — never require parameters a beginner would always pass as the same value. Overloaded param counts are preferred over config tables for simple APIs. |
| **C-04** | Active | Every callback (`luna.load`, `luna.update`, `luna.draw`, `luna.keypressed`, etc.) is **optional**. An empty `main.lua` is a valid game. |
| **C-05** | Active | Lua API is **synchronous from the script's perspective**. Any asynchronous work happens in Rust threads and communicates results via `Channel`. The Lua VM never blocks on I/O or network. |

---

## Quality Gate Constraints

| ID | Status | Constraint |
|---|---|---|
| **Q-01** | Active | `cargo test` must exit 0 before any merge. All Rust and Lua tests must pass. |
| **Q-02** | Active | `cargo clippy -- -D warnings` must exit 0 before any merge. No suppressed warnings, no `#[allow(clippy::...)]` without a comment explaining why. |
| **Q-03** | Active | Every new public Rust API item (`pub fn`, `pub struct`, `pub enum`, `pub trait`) requires at least **one integration test** before merge. |
| **Q-04** | Active | Every new `luna.*` Lua API function requires at least **one Lua BDD test** before merge. |
| **Q-05** | Active | `python tools/collect_docs.py --report-missing` must exit 0 — no undocumented public items. Every `pub fn`, `pub struct`, `pub enum`, `pub trait`, and `pub type` must have a `///` doc comment. |

→ See [test-framework.md](test-framework.md) § Quality Gates for the complete test gate details.

---

## Constraint Status Model

Each design constraint has one of three statuses:

| Status | Meaning |
|---|---|
| **Active** | Binding. All code must comply. Violations require a design-assumption update discussion before implementation. |
| **Proposed** | Under consideration. Not yet binding. May be promoted to Active or withdrawn. |
| **Retired** | Was Active; now superseded by a newer decision. Kept for historical context in the Retired Decisions section below. |

To change a constraint's status:
1. Open a discussion or issue describing why the change is needed.
2. Reference the specific constraint ID (e.g., "Propose retiring A-04").
3. Get agreement from the project maintainer.
4. Update this document.
5. If the change affects the system prompt (`.github/copilot-instructions.md`), update it too.

---

## Retired Decisions

*(None yet — this section tracks superseded assumptions for historical context.)*
