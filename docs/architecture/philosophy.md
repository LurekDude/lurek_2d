# Lurek2D — Philosophy and Design Assumptions

> **Source of truth** for first principles, binding architectural decisions, and project identity.
> Companion documents: [engine-architecture.md](engine-architecture.md) (runtime module structure) · [test-framework.md](test-framework.md) (test architecture).

---

## Table of Contents

1. [The Zen of Lurek 2.0](#the-zen-of-lurek-20)
2. [Core Idea](#core-idea)
3. [Project Identity](#project-identity)
4. [Decision Heuristics](#decision-heuristics)
5. [Platform and Runtime Constraints](#platform-and-runtime-constraints)
6. [Technology Stack Constraints](#technology-stack-constraints)
7. [Active Module Group Constraints](#active-module-group-constraints)
8. [API Design Constraints](#api-design-constraints)
9. [Testing Constraints](#testing-constraints)
10. [Quality Gate Constraints](#quality-gate-constraints)
11. [Constraint Status Model](#constraint-status-model)
12. [Retired Decisions](#retired-decisions)

---

## The Zen of Lurek 2.0

These fifteen rules are the structural soul of Lurek2D. They are not aspirational guidelines — they are **binding constraints**. Every feature proposal, API design, and architectural decision must be checked against this list. If a choice violates a rule, the choice changes or the rule is formally amended — never silently overridden.

The module grouping (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration) is **loose and practical**. It does not say "never import from the same group." It says: "you know what each module belongs to and what it should not be doing." The one hard invariant is **no cycles**.

### 1. No Cycles, Ever

Do not fight horizontal imports — fight cycles. The module import graph is a DAG. If adding an import creates a cycle, the design is wrong, not the rule.

### 2. Composition Root Is One-Way

`app` and `lua_api` can know everything. Nothing below them imports `app` or any binding module.

### 3. Depend on Contracts, Not Backends

A Feature Systems module may depend on the `render` facade. It must never depend on backend GPU details. Platform Services expose pure-Rust contracts — the backend is an implementation detail.

### 4. Runtime Stays Boring

`runtime` owns errors, config, IDs, commands, and traits. It does not know about the event loop, VM boot, or debug overlays. If it starts getting interesting, something is leaking in.

### 5. World Is a Registry, Not a God Brain

`world` can hold services and resources. Domain logic belongs in Feature Systems modules, not in `world`. If `world` grows business logic, extract it.

### 6. Same-Group Imports Are Allowed When Stable and Acyclic

Pragmatism beats dogma. A `tilemap` importing scene state from `scene` is fine — both are Feature Systems, and there is no cycle. The test is always: "does this create a cycle?" Not: "are these in the same group?"

### 7. Split by Reason to Change, Not by File Length

A new module is born when it has a different responsibility, not when a file hits 800 lines. Do not create modules for the sake of organization alone.

### 8. Draw Is a Projection Layer

If a module has a complex state → render-commands transformation, extract a `draw.rs`. If it doesn't, don't do it ritually.

### 9. Pure Logic Stays Pure

`math`, `procgen`, `graph`, `nav`, serializers — these must never need render, audio, input, or Lua. If a Foundations module reaches for a GPU type, it has been misplaced.

### 10. CPU State and Runtime Resources Must Stay Separate

Serializable game state must not require a GPU handle, OS window, or VM reference. State types belong in domain modules; runtime resources belong in `world` pools.

### 11. Tooling Lives at the Edge

`devtools`, `debugbridge`, `docs`, and `automation` must not dictate the shape of core or domain modules. They observe; they never own.

### 12. Bindings Are Thin and One-Directional

The Lua bridge maps API calls onto domain functions. Domain modules never know the bridge exists. `lua_api` files contain no business logic — only glue.

### 13. Tests Follow Responsibility

A unit test for a private algorithm can live locally in the module. A contract test or integration test lives in `tests/`. Test placement follows module responsibility, not convenience.

### 14. Merge Weak Modules Fast

If a module has no clear, distinct responsibility, merge it into the module it most closely serves. Artificial boundaries are worse than large modules with clear ownership.

### 15. Optimise for Human and AI Readability

From a module's name and its public API, it should be obvious whether it is core, a runtime service, a feature, or a bridge. Documentation is part of design. A function with no doc comment is incomplete.


## Core Idea

Lurek2D is the engine for people who think game engines have become too complicated.

A game is a `main.lua` file. The engine runs it. You write Lua; the engine owns the GPU, the physics solver, the audio mixer, and the threading model. You never see a `.dll`, a `.framework`, or a build system. You see `lurek.process(dt)` and `lurek.render()`.

The competitive landscape is dominated by multi-gigabyte engines with visual editors, plugin marketplaces, and months-long learning curves. Lurek2D is the opposite: one binary, one scripting language, one afternoon to learn.

**The AI angle**: Lurek2D is the first game engine designed with AI copilots as first-class users. Every API is shaped so an AI agent can use it correctly from the docs alone. The CAG layer, the VS Code extension, and the documentation pipeline are all optimized for AI-assisted workflow. When an AI writes `lurek.render.draw(img, x, y)`, it should work on the first try, every time.

---

## Project Identity

Lurek2D's visual identity is built on a set of symbols that tell the David vs. Goliath story:

| Symbol                     | Meaning                                                               | Where It Appears       |
| -------------------------- | --------------------------------------------------------------------- | ---------------------- |
| 🌙 Crescent Moon            | Lua (Portuguese for "moon") — the scripting surface                   | Logo, splash screen    |
| ⚙️ Gear / Pacman shape      | Rust engine core — industrial-strength, consuming scripts             | Logo (primary shape)   |
| 🧊 Small Cube               | The industry giants (Engine G, Engine H, Engine C) — orbiting Lurek2D | Logo (accent)          |
| Deep blue + orange palette | Night sky + warm engine glow                                          | All branding materials |

**Naming convention**: "Luna" (engine) + "2D" (scope constraint). Short form: `lurek2d`. Binary name: `lurek2d` (Unix), `lurek2d.exe` (Windows). Lua API prefix: `lurek.*`.

---

## Decision Heuristics

When two paths are available and neither violates a principle above, use these heuristics to choose:

| Heuristic                                     | Meaning                                                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Simpler is better**                         | Fewer moving parts. Fewer concepts. Fewer files.                                                               |
| **Explicit over implicit**                    | Name things directly. Avoid magic. If a Copilot agent can't infer it from the signature, it's too implicit.    |
| **Defaults over configuration**               | Ship the 80% case. Make the other 20% possible but optional.                                                   |
| **Rust performance, Lua ergonomics**          | If the user touches it, it should feel Lua-native. If the engine owns it, optimize in Rust.                    |
| **Test the contract, not the implementation** | Tests should break when behavior changes, not when code is refactored.                                         |
| **One canonical place**                       | Every rule, every pattern, every convention has exactly one source of truth. Reference it, don't duplicate it. |
| **AI-verifiable**                             | Could a Copilot agent use this API correctly without a clarifying question? If no, redesign.                   |

---

## Platform and Runtime Constraints

These are **active, binding decisions**. All code must comply. Do not propose changes without first opening a design-assumption update discussion.

| ID       | Status   | Constraint                                                                                                                                                                                   |
| -------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **A-01** | Active   | Lurek2D is a **runtime only** — no embedded visual editor or IDE. The VS Code extension is an opt-in developer experience layer, not part of the engine binary.                              |
| **A-02** | Active   | **Desktop only** — Windows / Linux / macOS, x86_64 + ARM. Mobile (iOS / Android) and WASM are out of scope.                                                                                  |
| **A-03** | Active   | **2D graphics only** — no 3D scene graph, no perspective projection pipeline. Raycasting columns and isometric rendering are acceptable because they use 2D draw calls.                      |
| **A-04** | Active   | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core engine binary. Platform wrappers live outside the five-group module stack entirely — constraint T-08. |
| **A-05** | Proposed | **A-05 (Proposed)** — Core binary stays ≤ 10 MB stripped on desktop targets. Optional subsystems ship as plugins; plugin size is additional and unbudgeted.                                  |

> **A-05 status note**: Currently *Proposed* (not yet binding). It becomes Active when the plugin system described in [plugins.md](plugins.md) is accepted and a baseline stripped-binary measurement is recorded.

---

## Technology Stack Constraints

| ID       | Status | Constraint                                                                                                                                                                                                                       |
| -------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **B-01** | Active | **LuaJIT** is the primary scripting runtime, vendored through mlua 0.9. Lua 5.4 (`lua54` Cargo feature) is a non-shipping development fallback — it exists for fallback testing and CI environments where LuaJIT is unavailable. |
| **B-02** | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal via the wgpu abstraction). No raw OpenGL path, no software fallback.                                                                                             |
| **B-03** | Active | Games must run acceptably on **integrated GPUs** (Intel UHD 620, AMD Vega 8 class). No feature requirements beyond wgpu baseline capabilities. Performance target: 60 FPS at 1080p with a reasonable draw call count.            |
| **B-04** | Active | Concurrency lives in **Rust threads**. LuaJIT VMs are single-threaded and cannot share state. Inter-VM communication uses typed MPMC `Channel` objects.                                                                          |
| **B-05** | Active | **TOML** is the human-authored configuration format. JSON is accepted for external interop (e.g., exported save files, API data). YAML is not used anywhere in the project.                                                      |

---

## Active Module Group Constraints

These constraints formalize the [module group model](engine-architecture.md#module-group-model) as enforceable rules. The old Baseline / Tier 1 / Tier 2 / Tier 3 naming is retired — see [Retired Decisions](#retired-decisions).

| ID       | Status | Constraint                                                                                                                                                                                                                       |
| -------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **T-01** | Active | The active module structure uses **five responsibility groups**: Foundations, Core Runtime, Platform Services, Feature Systems, and Edge/Integration. See [engine-architecture.md](engine-architecture.md) § Module Group Model. |
| **T-02** | Active | `lua_api` (`src/lua_api/`) is the **binding layer** that registers `lurek.*`. It sits in the Edge/Integration group. It may import all Rust groups. No domain module may import `lua_api`.                                       |
| **T-03** | Active | **No cycles, ever.** The module import graph must remain a DAG. Same-group imports are allowed provided they are acyclic and stable. See Rule 1 and Rule 6 above.                                                                |
| **T-04** | Active | **Composition root is one-way.** `app` and `lua_api` may depend on any module below them. No module below them may import `app` or any `lua_api` binding module.                                                                 |
| **T-05** | Active | **Lunasome** (`library/`) is the pure-Lua standard library. It consumes public `lurek.*` APIs only — no Rust engine internals, no `require` of engine source files.                                                      |
| **T-06** | Active | **Foundations group modules** (`math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns`) must never import render, audio, input, physics, or Lua APIs. See Rule 9.                                |
| **T-07** | Active | **Edge/Integration group modules** (`devtools`, `debugbridge`, `automation`) are never imported by domain modules. They are optional components compiled only for development builds.                                            |
| **T-08** | Active | Platform SDK integrations (Steam, Epic, itch.io store APIs) must not be imported by any module in Foundations, Core Runtime, Platform Services, or Feature Systems groups. They belong to external wrapping binaries only.       |

---

## API Design Constraints

| ID       | Status | Constraint                                                                                                                                                                                                                      |
| -------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **C-01** | Active | All Lua-facing APIs live under the `lurek.*` namespace. No bare globals, no engine-prefixed names, no alternative top-level tables.                                                                                             |
| **C-02** | Active | Every `lua_api` sub-module exposes exactly one `pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`.                                                                                 |
| **C-03** | Active | API functions must have **sensible defaults** — never require parameters a beginner would always pass as the same value. Overloaded param counts are preferred over config tables for simple APIs.                              |
| **C-04** | Active | Every callback (`lurek.init`, `lurek.ready`, `lurek.process`, `lurek.process_physics`, `lurek.process_late`, `lurek.render`, `lurek.render_ui`, `lurek.keypressed`, etc.) is **optional**. An empty `main.lua` is a valid game. |
| **C-05** | Active | Lua API is **synchronous from the script's perspective**. Any asynchronous work happens in Rust threads and communicates results via `Channel`. The Lua VM never blocks on I/O or network.                                      |

---

## Testing Constraints

These constraints formalise test placement and the layering rules that keep `src/lua_api/*_api.rs` and every `mod.rs` thin. They are binding; new code must comply. Existing violations are migration-scheduled under session [`testing-cleanup-20260420`](../../work/testing-cleanup-20260420/reports/plan.md) and its tiered follow-ups.

| ID         | Status | Constraint                                                                                                                                                                                                                                                                                                                          |
| ---------- | ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **TST-01** | Active | **Lua-first testing.** Any behaviour reachable through the `lurek.*` Lua API MUST be tested in [tests/lua/](../../tests/lua/). Rust tests MUST NOT duplicate `lurek.*`-reachable coverage. See [test-framework.md § Test placement](test-framework.md#test-placement).                                                              |
| **TST-02** | Active | **Centralised Rust unit tests.** Rust unit tests for private / internal-only code live in `tests/rust/unit/<module>_tests.rs`. Inline `#[cfg(test)] mod tests` blocks inside `src/**/*.rs` are **banned** — new additions fail review; existing ones are migration-scheduled.                                                       |
| **TST-03** | Active | **Thin Lua API wrappers.** `src/lua_api/<module>_api.rs` contains ONLY `impl LuaUserData`, `UserData` registration, and type conversions. Business logic (math, state machines, algorithms, branching on game state) MUST live in the corresponding domain module under `src/<module>/` as pure Rust. Reinforces Zen Rule 12.      |
| **TST-04** | Active | **Thin `mod.rs`.** Every `mod.rs` contains ONLY `pub mod X;`, `pub use X::*;`, module-level attributes, and doc comments. Function / struct / enum / trait / `impl` definitions MUST live in sibling files (e.g. `src/<module>/facade.rs`, `src/<module>/register.rs`). Reinforces Zen Rule 7.                                      |

> **Enforcement.** Audit scripts under `tools/audit/` (authored in session `testing-cleanup-20260420`, phase P3) scan the tree for TST-02, TST-03, and TST-04 violations. TST-01 is enforced by `Reviewer` and by `tools/audit/test_coverage.py`. See [test-framework.md § Test placement](test-framework.md#test-placement) for the decision tree and banned-patterns list.

---

## Quality Gate Constraints

| ID       | Status | Constraint                                                                                                                                                                                       |
| -------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Q-01** | Active | `cargo test` must exit 0 before any merge. All Rust and Lua tests must pass.                                                                                                                     |
| **Q-02** | Active | `cargo clippy -- -D warnings` must exit 0 before any merge. No suppressed warnings, no `#[allow(clippy::...)]` without a comment explaining why.                                                 |
| **Q-03** | Active | Every new public Rust API item (`pub fn`, `pub struct`, `pub enum`, `pub trait`) requires at least **one integration test** before merge.                                                        |
| **Q-04** | Active | Every new `lurek.*` Lua API function requires at least **one Lua BDD test** before merge.                                                                                                        |
| **Q-05** | Active | `python tools/collect_docs.py --report-missing` must exit 0 — no undocumented public items. Every `pub fn`, `pub struct`, `pub enum`, `pub trait`, and `pub type` must have a `///` doc comment. |

→ See [test-framework.md](test-framework.md) § Quality Gates for the complete test gate details.

---

## Constraint Status Model

Each design constraint has one of three statuses:

| Status       | Meaning                                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------- |
| **Active**   | Binding. All code must comply. Violations require a design-assumption update discussion before implementation.      |
| **Proposed** | Under consideration. Not yet binding. May be promoted to Active or withdrawn.                                       |
| **Retired**  | Was Active; now superseded by a newer decision. Kept for historical context in the Retired Decisions section below. |

To change a constraint's status:
1. Open a discussion or issue describing why the change is needed.
2. Reference the specific constraint ID (e.g., "Propose retiring A-04").
3. Get agreement from the project maintainer.
4. Update this document.
5. If the change affects the system prompt (`.github/copilot-instructions.md`), update it too.

---

## Retired Decisions

These decisions were once **Active** constraints but have been superseded. They are kept for historical context.

### Retired: Strict Tier Numbering (T-03-old, T-04-old)

**Original (Zen of Luna, c. v0.4):**
- T-03: Tier 1 modules may only import `math` and `engine`. **No Tier 1 ↔ Tier 1 cross-imports.**
- T-04: Tier 2 modules may import Baseline and any Tier 1 module. **No Tier 2 ↔ Tier 2 cross-imports.**

**Why retired:** The blanket ban on same-tier imports was a proxy for the real invariant (no cycles). It was overly conservative and ruled out legitimate stable acyclic imports between modules at the same conceptual level. For example, `tilemap` importing scene transition state from `scene` is correct design — both are Feature Systems modules, and there is no cycle.

**Replaced by:** T-03 (Active): No cycles, ever. Same-group imports are allowed when stable and acyclic. See Principle 1 and Principle 6 above.

---

### Retired: Baseline → Tier 1 → Tier 2 → Tier 3 Naming (T-01-old)

**Original (Zen of Luna, c. v0.4):**
- T-01: The active module stack is **Baseline + Tier 1 + Tier 2 + Tier 3**. Baseline is `src/math/` and `src/engine/`.

**Why retired:** The Baseline/Tier nomenclature became misleading as the engine grew. `src/engine/` was a monolith that mixed config, resource keys, app state, and boot logic — not a clean substrate. The tier numbers implied a linear progression that did not match actual import topology. The new five-group model (Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration) is more accurate and more legible for both humans and AI agents.

**Replaced by:** T-01 (Active): Five responsibility groups. See [engine-architecture.md](engine-architecture.md) § Module Group Model.

---

### Retired: Tier 4 as the Platform Integration Slot

**Original (Zen of Luna, c. v0.4):**
- Principle 6: "Platform integrations live at Tier 4 (future) or in external wrapping binaries."

**Why retired:** "Tier 4" was never defined or implemented. The concept is now captured cleanly in constraint T-08 (Active): platform SDK wrappers live entirely outside the five-group module stack.

**Replaced by:** T-08 (Active) and constraint A-04 (Active, updated).
