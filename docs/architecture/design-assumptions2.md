# Luna2D — Design Assumptions

> **Source of truth** for binding architectural decisions.
> Do not propose changes to items marked **Active** without first opening a design-assumption update discussion.

---

## How to Read This Document

Each entry has a status:
- **Active** — In force. All code must comply. Do not violate without updating this document.
- **Proposed** — Under consideration. Not yet binding.
- **Retired** — Was active; now superseded. Kept for history.

---

## Platform and Runtime Constraints

| ID | Status | Constraint |
|----|--------|------------|
| A-01 | Active | Luna2D is a **runtime only** — no embedded visual editor or IDE. The VS Code extension is an opt-in DX layer, not part of the engine binary. |
| A-02 | Active | **Desktop only** — Windows/Linux/macOS x86_64 + ARM. Mobile (iOS/Android) and WASM are out of scope. |
| A-03 | Active | **2D graphics only** — no 3D scene graph or perspective pipeline. Raycasting columns and isometric projection are acceptable (they use 2D draw calls). |
| A-04 | Active | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core binary. Any future platform wrapper lives outside the active Baseline/Tier 1/Tier 2/Tier 3 stack. |
| B-01 | Active | **LuaJIT** is the primary scripting runtime. Lua 5.4 (`lua54` Cargo feature) is a non-shipping development fallback only. |
| B-02 | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal). No raw OpenGL path. |
| B-03 | Active | Games must run acceptably on **integrated GPUs** (Intel UHD, AMD APU). No feature requirements beyond wgpu baseline. |
| B-04 | Active | Concurrency lives in **Rust threads**. LuaJIT VMs cannot share state; Lua-to-Lua communication uses `Channel` objects. |
| B-05 | Active | **TOML** is the human-authored config format. JSON is for external interop only. YAML is not used anywhere. |

---

## Active Layer Model

The layer model defines dependency boundaries across the Rust runtime, the Lua bridge, and the shipped Lua standard library. See [`docs/architecture.md`](architecture.md) for the full descriptions and module tables.

| ID | Status | Constraint |
|----|--------|------------|
| T-01 | Active | The active stack is **Baseline + Tier 1 + Tier 2 + Tier 3**. Baseline is the always-on runtime substrate in `src/`; Tier 3 is Lunasome, the pure-Lua standard library in `library/`. |
| T-02 | Active | `lua_api` is the bridge layer that registers `luna.*`. It is not a numbered tier. |
| T-03 | Active | **Tier 1 Rust modules** may only import `math` and `engine`. No Tier 1 ↔ Tier 1 cross-imports. |
| T-04 | Active | **Tier 2 Rust modules** may import `math`, `engine`, and Tier 1 modules. No Tier 2 ↔ Tier 2 cross-imports. |
| T-05 | Active | **Tier 3** consists of pure-Lua libraries under `library/`. It consumes public `luna.*` APIs and must not depend on Rust internals. |
| T-06 | Active | No Rust domain module may import `lua_api`. The `lua_api` crate is the integration endpoint, not a reusable library tier. |
| T-07 | Active | Legacy gameplay-oriented Rust modules that still live under `src/` are migration-state code. Keep them buildable, but do not document them as the current Tier 3 layer. |
| T-08 | Proposed | Future Cargo feature flags may expose Baseline/Core/Extended/Lunasome build variants corresponding to the active layer model. Not yet implemented. |

---

## API Design Constraints

| ID | Status | Constraint |
|----|--------|------------|
| C-01 | Active | All Lua-facing APIs live under the `luna.*` namespace. No bare globals, no engine-prefixed names. |
| C-02 | Active | Every `lua_api` sub-module exposes exactly one `pub fn register(lua, luna, state)` function. |
| C-03 | Active | API functions must have sensible defaults — never require parameters a beginner would always pass as the same value. |
| C-04 | Active | Every callback (`luna.load`, `luna.update`, `luna.draw`, etc.) is optional. An empty `main.lua` is a valid game. |
| C-05 | Active | Lua API is **synchronous from the script's perspective**. Async work happens in Rust threads communicating via `Channel`. |

---

## Quality Gates

| ID | Status | Constraint |
|----|--------|------------|
| Q-01 | Active | `cargo test` must exit 0 before merge. |
| Q-02 | Active | `cargo clippy -- -D warnings` must exit 0 before merge. |
| Q-03 | Active | Every new public Rust API requires at least one integration test before merge. |
| Q-04 | Active | Every new `luna.*` Lua API function requires at least one Lua BDD test before merge. |
| Q-05 | Active | `python tools/collect_docs.py --report-missing` must exit 0 (no undocumented public items). |

---

## Retired Decisions

*(None yet — this section tracks superseded assumptions for historical context.)*
