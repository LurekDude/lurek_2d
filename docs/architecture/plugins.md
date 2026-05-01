# Lurek2D — Plugin Architecture (Proposed)

**Status: Proposed.** Activates binding constraint **A-05** once accepted.

Companion documents: [philosophy.md](philosophy.md) · [engine-architecture.md](engine-architecture.md)

---

## Table of Contents

1. [Goals and Non-Goals](#goals-and-non-goals)
2. [Why Plugins](#why-plugins)
3. [Plugin Model](#plugin-model)
4. [Plugin Tiers](#plugin-tiers)
5. [Candidate Modules](#candidate-modules)
6. [Loading Mechanism Options](#loading-mechanism-options)
7. [Stability and ABI Contract](#stability-and-abi-contract)
8. [Discovery and Configuration](#discovery-and-configuration)
9. [Migration Plan](#migration-plan)
10. [Comparison to Other Engines](#comparison-to-other-engines)
11. [Risks and Open Questions](#risks-and-open-questions)

---

## Goals and Non-Goals

### Goals

- **Core binary ≤ 10 MB stripped** on Windows / Linux / macOS x86_64 + ARM — constraint **A-05 (Proposed)**.
- **Optional features ship as plugins**, not compile-time `cfg` thickets. A user who needs only sprites + audio + input must not pay binary size for AI, raycasting, dataframes, or the in-game terminal.
- **Documented third-party extension surface.** Community authors building Steam SDK wrappers or custom physics adapters plug in via a stable Rust crate API rather than forking the engine.
- **Zero-config user path.** Running `lurek2d main.lua` gets a working renderer, audio, input, filesystem, window, camera, timer, event, ECS, scene, sprite, and tilemap out of the box.

### Non-Goals

- Hot-reload of native plugins at runtime (reserved for pure-Lua content in `library/`)
- Arbitrary FFI sandboxing — plugins run with the same trust as the core engine
- Mobile / WASM plugins — constraint A-02 keeps the project desktop-only
- A package manager or marketplace
- Replacing pure-Lua extensibility — Lunasome libraries in `library/` remain the recommended path for game-side reuse

---

## Why Plugins

The current `src/` tree is dominated by large, optional-by-nature modules. Evidence from `work/docs-api-arch-specs-review-20260418/reports/P1_EVIDENCE.md`:

| Module | LOC | Used by typical 2D game? |
|--------|----:|--------------------------|
| `ai` | 7 860 | No — most games ship a custom FSM |
| `tilemap` | 7 776 | Yes — fundamental primitive |
| `ui` | 6 882 | Sometimes — many games use custom Lua UI |
| `pathfind` | 5 880 | Only with `ai` or strategy games |
| `physics` | 4 921 | Often — but heavy `rapier2d` tree |
| `dataframe` | 4 411 | No — power-user only |
| `raycaster` | 3 670 | No — Wolfenstein-style only |
| `compute` | 3 652 | No — specialist GPU workloads |

Extracting optional-by-nature modules and their heavy crate trees (`rapier2d`, `rusty_enet`, `tungstenite`, `csv`) saves conservatively **3–6 MB** on a stripped Linux release plus reduced compile times. Smaller binaries also clear Windows Defender and macOS Gatekeeper faster on first launch.

Constraint **A-05** formalises this argument so it cannot be eroded by single-PR feature creep.

---

## Plugin Model

A Lurek2D plugin is a Rust crate that:

1. **Registers Rust types** into `runtime::shared_state` pools or as standalone subsystems
2. **Registers a `lurek.<namespace>` Lua surface** using the same thin-binding pattern as `src/lua_api/` (Zen Rule 12, C-02)
3. **Provides explicit init / teardown hooks** for deterministic lifecycle
4. **Owns its own tests, docs, and Lua API reference**

Plugins are **NOT** pure-Lua libraries (`library/`), game scripts (`content/games/`), asset bundles, or sandboxed mods (`mods` module).

**Registration shape (C-02 compliant):**

```rust
pub fn register(
    lua: &Lua,
    lurek: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()>;
```

**Lifecycle:**

```
App::new(config)
   → PluginRegistry::discover()
   → for each plugin in load order:
       plugin.on_load(state)
       plugin.register_lua(lua, ...)
   → lurek.init()   ← game fires; plugin tables are visible
   ... game runs ...
App::shutdown()
   → for each plugin in reverse load order:
       plugin.on_unload(state)
```

Load order: CORE-KEEP (Foundations → Core Runtime → …) then TIER-1 (alphabetical) then TIER-2 (declaration order in `conf.lua`).

---

## Plugin Tiers

| Tier | Distribution | Loaded | Disable strategy |
|------|-------------|--------|----------------|
| **CORE-KEEP** | Compiled into binary | Always | Cannot be disabled |
| **TIER-1-PLUGIN** | Separate `.dll`/`.so`/`.dylib` next to binary | At startup if file is present | Delete file or `[plugins] disabled = ["ai"]` in `conf.toml` |
| **TIER-2-PLUGIN** | Built and shipped, not loaded unless game opts in | When `conf.lua` declares `plugins = { "physics" }` | Game omits the entry |
| **THIRD-PARTY-PLUGIN** | Built by community author | Like TIER-1 or TIER-2 | User does not install it |

**CORE-KEEP modules** (always compiled in): `math`, `log`, `data`, `serial`, `runtime`, `event`, `timer`, `thread`, `filesystem`, `render`, `audio`, `input`, `image`, `window`, `camera`, `light`, `effect`, `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `sprite`, `i18n`, `graph`, `automation`, `app`, `lua_api`, `bin`, plus documentation and tooling Edge modules.

---

## Candidate Modules

Sorted by tier then LOC descending. Per user decision **D-1**, `physics` is TIER-2-PLUGIN.

| Module | LOC | Heavy deps | Tier | Rationale |
|--------|----:|-----------|------|-----------|
| `ai` | 7 860 | none | TIER-1 | Largest optional surface. Most games don't need engine-level FSM/BT/GOAP/HTN/MCTS. |
| `ui` | 6 882 | none | TIER-1 | Opinionated widget set; many games author UI in Lua directly. |
| `pathfind` | 5 880 | none | TIER-1 | Paired with `ai`; co-extracted. |
| `raycaster` | 3 670 | none | TIER-1 | Wolf3D-style 2.5D only. Self-contained. |
| `dataframe` | 4 411 | `csv` | TIER-1 | Power-user analytics; orthogonal to gameplay. |
| `network` | 2 295 | `rusty_enet`, `ureq`, `tungstenite`, `rmp-serde` | TIER-1 | Heavy HTTP+WS+ENet+TLS tree. Most games are offline. |
| `terminal` | 2 606 | none | TIER-1 | In-game dev REPL. Dev-only for shipping games. |
| `spine` | 1 328 | custom Spine runtime | TIER-1 | Proprietary format; niche. |
| `physics` | 4 921 | `rapier2d`, `rayon` | TIER-2 | Heavy tree but most 2D games eventually need a solver. Default ON in templates. |
| `compute` | 3 652 | none | TIER-2 | GPU compute is specialist. |
| `procgen` | 3 021 | none | TIER-2 | Keep noise/Perlin in core; move L-systems/WFC/dungeon generators. |
| `mods` | 672 | none | TIER-2 | Sandboxed mod loader; opt-in per game. |
| `minimap` | 1 574 | none | TIER-2 | Candidate for pure-Lua reimplementation in Lunasome. |
| `parallax` | 708 | none | TIER-2 | Tiny; strongest Lunasome reimplementation candidate. |
| `save` | 803 | `serde` | TIER-2 | Thin wrapper over `filesystem` + `serial`; could become Lunasome. |
| `debugbridge` | — | TCP/WS server | TIER-2 | Dev-only. Already optional by intent. |

**Coupling refactor required before extraction.** `src/runtime/shared_state.rs` currently holds `parallax`, `particle`, `raycaster`, `tilemap`, and `ui` via direct `use crate::<m>` imports. Plugin extraction requires first introducing a `SharedState` extension trait or per-plugin registration table — migration step M1.

---

## Loading Mechanism Options

### Option A — Cargo features (recommended for v1)

Each plugin candidate becomes a Cargo feature on the root crate. Single binary; `--no-default-features --features minimal` build excludes unrequested modules.

**Pros:** Zero ABI risk, no `unsafe`, no dynamic loader code, all-Rust toolchain.  
**Cons:** Not third-party-extensible; produces multiple binary SKUs; `conf.lua` `plugins = {...}` is advisory only.  
**Recommendation:** Ship this for v1.

### Option B — `libloading` dynamic libraries (post-v1)

Each plugin builds as a `cdylib`. Engine scans `plugins/` next to binary at startup and `dlopen`/`LoadLibrary`s each one.

**Pros:** True third-party plugins; Steam SDK wrapper drops in cleanly.  
**Cons:** Rust has no stable ABI on stable channel; plugin + engine must agree on exact rustc + `mlua` versions.  
**Recommendation:** Defer to post-v1 (migration step M4). Use only for Steam SDK and similar.

### Option C — Pure Lua (already available)

Many candidates can be reimplemented in pure Lua against existing `lurek.*` APIs. Lunasome (`library/`) is the right home.

**Recommendation:** Use for `parallax`, `minimap`, `save`, and any candidate whose Rust footprint is mostly bookkeeping.

**Recommended hybrid for v1:** Option A for engine modules + Option C for thin Lua wrappers, with Option B reserved for post-v1 third-party/platform SDK plugins.

---

## Stability and ABI Contract

The plugin Rust API is a single trait plus a registration helper in the planned `lurek_plugin_api` crate (only `mlua` + `runtime` types as public dependencies):

```rust
pub trait LurekPlugin: Send {
    fn name(&self) -> &'static str;
    fn register_lua(&self, lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>;
    fn on_load(&self, state: Rc<RefCell<SharedState>>) -> Result<(), EngineError> { Ok(()) }
    fn on_unload(&self, state: Rc<RefCell<SharedState>>) -> Result<(), EngineError> { Ok(()) }
    fn abi_version(&self) -> u32 { CURRENT_ABI_VERSION }
}
```

**For Option B (dynamic) only**, plugins additionally export a C entry point inside a panic boundary:

```rust
#[no_mangle]
pub extern "C" fn lurek_plugin_init() -> *mut dyn LurekPlugin { ... }
```

Engine wraps the call in `std::panic::catch_unwind`, refuses to load panicking plugins, never re-enters a panicked plugin.

**Versioning policy:** `LurekPlugin` is semver-locked on `lurek_plugin_api`. Major bump = ABI break = all plugins must be rebuilt. Compatibility: binary-compatible within a MAJOR.MINOR series (0.20.x → 0.20.y). PATCH bumps never break ABI; MINOR bumps may add methods with default impls; MAJOR bumps are free to break.

**Plugin manifest** (`plugin.toml`): `name`, `version`, `min_engine_version`, `max_engine_version` are required. Engine refuses to load plugins outside the supported engine version range.

---

## Discovery and Configuration

Plugins declared in `conf.lua` (or `conf.toml`):

```lua
function lurek.conf(t)
    t.window.width  = 1280
    t.plugins = { "physics", "ai", "raycaster" }
end
```

```toml
[plugins]
enabled  = ["physics", "ai", "raycaster"]
disabled = ["terminal"]

[plugins.physics]
gravity_y = -9.81
allow_sleep = true
```

`enabled` is the authoritative list. `disabled` is consulted only for auto-discovered TIER-1 plugins — lets a user keep a `.dll` on disk while turning it off. Conflicts (`enabled` and `disabled` listing the same plugin) raise a boot error.

Conf-file precedence: `conf.toml` preferred, `conf.lua` legacy fallback. Plugins inherit that rule.

---

## Migration Plan

All steps keep `cargo test` green throughout.

| Step | Goal | Gate |
|------|------|------|
| **M1** — Untangle `shared_state` | Introduce extension trait / typed registry so the five candidate pools (`parallax`, `particle`, `raycaster`, `tilemap`, `ui`) are no longer direct `use crate::<m>` imports in `runtime`. | Removing one module no longer breaks compile in `runtime`. |
| **M2** — Cargo features | Introduce features `plugin-ai`, `plugin-ui`, `plugin-raycaster`, `plugin-physics`, etc. Default is everything-on. CI gains a build matrix. | Every matrix cell builds; `cargo test --features <name>` passes. |
| **M3** — Size enforcement, A-05 promotion | Flip default features off for `minimal`. Measure stripped binary on all three platforms. If ≤ 10 MB, promote A-05 to Active, add CI size budget gate. | A-05 Active; CI size budget green on Windows / Linux / macOS. |
| **M4** — Dynamic plugins (optional) | Add `libloading` path behind `dynamic-plugins` feature. Port `raycaster` as proof. Document third-party plugin workflow. | `raycaster.dll/.so/.dylib` loads on all platforms; in-tree `raycaster` disappears from static binary. |

---

## Comparison to Other Engines

| Engine | Plugin model | Core size |
|--------|-------------|---------|
| LÖVE | None — plain Lua libs or LuaJIT FFI | ~6 MB |
| Solar2D | Lua frontend + native plugin server | ~6–10 MB |
| Godot | GDExtension (stable C ABI since 4.1) | ~60–100 MB |
| Lurek2D (proposed) | Cargo features (M2/M3), Lunasome Lua libs, optional `libloading` (M4) | **≤ 10 MB stripped (A-05)** |

Position: simpler than Godot's GDExtension (no full ABI surface to maintain in v1), more native than RPG Maker's JS, smaller core than LÖVE-with-everything-bundled.

---

## Risks and Open Questions

1. **Rust ABI stability.** Option B dynamic plugins on Rust stable require pinning rustc + `mlua` versions exactly. Mitigation: `lurek_plugin_api` crate with a published version table; refuse mismatched plugins.
2. **`shared_state` refactor scope.** M1 touches a hub used by every subsystem. Mitigation: introduce trait first as a no-op refactor, then remove direct imports module-by-module.
3. **Plugin Lua VM access from worker threads.** B-04: LuaJIT VMs cannot share state. Plugin `on_load` must declare whether it spawns workers. Workers cannot register `lurek.*` functions on the main VM after boot.
4. **`dlopen` paths on Linux.** `LD_LIBRARY_PATH`, `RPATH`, and AppImage layouts surface plugins differently. Needs a documented install layout before M4.
5. **Steam SDK licensing.** Steamworks SDK is closed and per-publisher licensed. Wrapper plugin must live in a separate repo; Lurek2D core can never link it.
6. **Lua-candidate evaluation.** `parallax`, `minimap`, `save` could become Lunasome libraries instead of Rust plugins. Decision deferred.
7. **Plugin testing harness.** Each plugin needs its own `tests/lua/` slice. Open: shared harness or per-plugin?
8. **Spec location.** When a module becomes a plugin, its spec stays in `docs/specs/<name>.md` with a "Plugin: TIER-1" header. Tier is also recorded in `docs/specs/README.md`.
9. **VS Code extension integration.** The extension needs to know which plugins are present for IntelliSense and run-with-profile commands. Open: emit `plugins.json` at boot, or parse `Cargo.toml` features?
