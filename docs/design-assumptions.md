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
| A-04 | Active | No distribution platform SDK integration (Steam, Epic, itch.io store APIs) in the core binary. Platform integrations belong in Tier 4 modules. |
| B-01 | Active | **LuaJIT** is the primary scripting runtime. Lua 5.4 (`lua54` Cargo feature) is a non-shipping development fallback only. |
| B-02 | Active | **wgpu 22** is the only renderer backend (Vulkan / DX12 / Metal). No raw OpenGL path. |
| B-03 | Active | Games must run acceptably on **integrated GPUs** (Intel UHD, AMD APU). No feature requirements beyond wgpu baseline. |
| B-04 | Active | Concurrency lives in **Rust threads**. LuaJIT VMs cannot share state; Lua-to-Lua communication uses `Channel` objects. |
| B-05 | Active | **TOML** is the human-authored config format. JSON is for external interop only. YAML is not used anywhere. |

---

## Module Tier System

The tier system defines dependency boundaries between modules. See [`docs/architecture.md`](architecture.md) for the full tier descriptions and module tables.

| ID | Status | Constraint |
|----|--------|------------|
| T-01 | Active | All source modules are assigned to exactly one tier (1, 2, or 3) or the Foundation layer (`math`, `engine`). Untiered modules are not permitted in production code. |
| T-02 | Active | **Tier 1 modules** may only import `math` and `engine`. No Tier 1 ↔ Tier 1 cross-imports. |
| T-03 | Active | **Tier 2 modules** may import `math`, `engine`, and Tier 1 modules. No Tier 2 ↔ Tier 2 cross-imports. |
| T-04 | Active | **Tier 3 modules** may import `math`, `engine`, Tier 1, and Tier 2 modules. No Tier 3 ↔ Tier 3 cross-imports. |
| T-05 | Active | No module at any tier may import `lua_api`. The `lua_api` crate is the integration endpoint, not a library. |
| T-06 | Active | **Tier 4 (Platform Integrations)** is reserved for future external SDK wrappers (Steam, Epic, etc.). Tier 4 modules must not be imported by any lower tier. |
| T-07 | Proposed | Future Cargo feature flags will enable Light / Standard / Extended / Platform build variants corresponding to tier subsets. Not yet implemented. |

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
