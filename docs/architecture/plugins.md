# Lurek2D Plugin Architecture (Proposed)

> **Status: Proposed.** Activates binding constraint **A-05** once accepted.
> See [philosophy.md § Platform and Runtime Constraints](philosophy.md#platform-and-runtime-constraints).
>
> Companion docs: [philosophy.md](philosophy.md) (binding constraints) ·
> [engine-architecture.md](engine-architecture.md) (module groups, `runtime::shared_state`) ·
> [README.md](README.md) (architecture index).

---

## Table of Contents

1. [Goals and non-goals](#1-goals-and-non-goals)
2. [Why plugins](#2-why-plugins)
3. [Plugin model](#3-plugin-model)
4. [Plugin tiers](#4-plugin-tiers)
5. [Candidate modules](#5-candidate-modules)
6. [Loading mechanism options](#6-loading-mechanism-options)
7. [Stability and ABI contract](#7-stability-and-abi-contract)
8. [Discovery and configuration](#8-discovery-and-configuration)
9. [Migration plan](#9-migration-plan)
10. [Comparison to other engines](#10-comparison-to-other-engines)
11. [Risks and open questions](#11-risks-and-open-questions)
12. [References](#12-references)

---

## 1. Goals and non-goals

### Goals

- **Hold core ≤ 15 MB stripped** on desktop targets (Windows / Linux / macOS, x86_64 + ARM). Constraint **A-05 (Proposed)** in [philosophy.md](philosophy.md#platform-and-runtime-constraints).
- **Optional features ship as plugins**, not as compile-time `cfg` thickets. A user who needs only sprites + audio + input must not pay binary size for AI, raycasting, dataframes, or the in-game terminal.
- **Documented third-party extension surface**. A community author building a Steam SDK wrapper, a custom physics adapter, or a domain-specific renderer should plug in via a stable Rust crate API rather than forking the engine.
- **Future Steam / Epic / itch.io SDK integration as a first-party plugin**, satisfying constraint **A-04** (no platform SDKs in the core binary) without requiring out-of-tree forks.
- **Zero-config user path for typical 2D games**. New users running `lurek2d main.lua` get a working renderer, audio, input, filesystem, window, camera, timer, event, ECS, scene, sprite, and tilemap out of the box.

### Non-goals

- **Hot-reload of native plugins** at runtime. Out of scope for v1; live-reload is reserved for pure-Lua content under `content/library/` and `content/plugins/`.
- **Arbitrary FFI sandboxing**. Plugins run with the same trust as the core engine. Users install plugins the same way they install the engine.
- **Mobile / WASM plugins**. Constraint **A-02** keeps the project desktop-only; plugin targets follow.
- **A package manager / marketplace**. Plugins are distributed as archives or source crates; discovery happens via documentation, not a registry.
- **Replacing existing pure-Lua extensibility**. Lunasome libraries under [content/library/](../../content/library/) remain the recommended path for game-side reuse.

---

## 2. Why plugins

The core binary is the product. Every byte added to the default build is paid for by every user, including those who never touch the feature it added. Lurek2D's identity — a single binary that runs Lua scripts on the desktop — depends on staying tight.

The current `src/` tree is dominated by a handful of large, optional-by-nature modules. Lines-of-code from the candidate evaluation in [P1_EVIDENCE.md § 5](../../work/docs-api-arch-specs-review-20260418/reports/P1_EVIDENCE.md):

| Module      |   LOC | Used by typical 2D game?                   |
| ----------- | ----: | ------------------------------------------ |
| `ai`        | 7 860 | No — most games ship a custom FSM.         |
| `tilemap`   | 7 776 | Yes — fundamental primitive.               |
| `ui`        | 6 882 | Sometimes — many games ship custom Lua UI. |
| `pathfind`  | 5 880 | Only with `ai` or strategy games.          |
| `physics`   | 4 921 | Often — but heavy `rapier2d` tree.         |
| `dataframe` | 4 411 | No — power-user only.                      |
| `raycaster` | 3 670 | No — Wolfenstein-style only.               |
| `compute`   | 3 652 | No — specialist GPU workloads.             |

Aggregate the optional-by-nature modules and the heavy crate trees they pull (`rapier2d`, `rusty_enet`, `tungstenite`, `csv`, `roxmltree`) and the saving on a stripped Linux release is conservatively **3–6 MB** plus reduced compile times for users who opt out.

The strip-binary argument is real on every platform, not just Linux. Windows Defender and macOS Gatekeeper both notarise / scan the binary on first launch; smaller binaries clear those gates faster. Drag-drop demos start within a second on cold systems instead of two to four.

Constraint **A-05** formalises this argument so it cannot be eroded by single-PR feature creep. Plugins are the mechanism A-05 relies on.

---

## 3. Plugin model

A **Lurek2D plugin** is a Rust crate that:

1. **Registers Rust types** into the running engine — typically into `runtime::shared_state` pools or as standalone subsystems.
2. **Registers a `lurek.<namespace>` Lua surface** through the same thin-binding pattern that `src/lua_api/` modules use today (Zen Rule 12, constraint **C-02**).
3. **Provides explicit init / teardown hooks** so the engine can load and (where applicable) unload it deterministically.
4. **Owns its own tests, docs, and Lua API reference**. A plugin is a peer of a `src/<module>/` directory, not a downstream consumer.

Plugins are **NOT**:

- Pure-Lua libraries — those live in [content/library/](../../content/library/) and follow the [library-authoring](../../.github/skills/library-authoring/SKILL.md) skill.
- Game scripts under `content/games/` — those use `lurek.*` and Lunasome.
- Pure asset bundles — those mount via `GameFS` or archive mounting.
- Mods loaded through the `mods` module — those are sandboxed Lua at runtime.

Each plugin owns one or more `lurek.<namespace>` tables and has its own slice of [docs/specs/](../specs/) and [docs/API/](../API/). When the candidate list (§5) becomes plugins, their existing specs and API references move with them.

A plugin exposes the same registration shape required by **C-02**:

```rust
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()>;
```

Plus the lifecycle entrypoints described in §7.

Lifecycle in order:

```
App::new(config)
   │
   ▼
PluginRegistry::discover()       ← scans built-in features (Option A) or plugins/ folder (Option B)
   │
   ▼
for each plugin in load order:
   plugin.on_load(state)         ← Rust-side init: open files, allocate pools
   plugin.register_lua(lua, ...) ← Lua-side: install the lurek.<name> table
   │
   ▼
lurek.init()                     ← game callback fires; plugin tables are visible
   ...
   game runs ...
App::shutdown()
   │
   ▼
for each plugin in reverse load order:
   plugin.on_unload(state)       ← release resources, flush state
```

Load order is deterministic: CORE-KEEP first (in module-group order: Foundations → Core Runtime → …), then TIER-1 in alphabetical order of `name()`, then TIER-2 in the order declared in `conf.lua`. THIRD-PARTY plugins follow TIER-1 / TIER-2 according to their installed location.

---

## 4. Plugin tiers

Four tiers, ordered by how aggressively the engine binds the plugin to the core distribution.

| Tier                   | Distribution                                                                               | Loaded                                                          | Disable strategy                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **CORE-KEEP**          | Compiled into the engine binary                                                            | Always                                                          | Cannot be disabled. Every game depends on it.                                |
| **TIER-1-PLUGIN**      | Ships as a separate dynamic library next to the binary (e.g. `plugins/ai.dll`)             | At engine startup if the file is present                        | User deletes the file, or sets `[plugins] disabled = ["ai"]` in `conf.toml`. |
| **TIER-2-PLUGIN**      | Built and shipped, but not loaded unless the game opts in                                  | When `conf.lua` declares `plugins = { "physics" }`              | Game omits the entry.                                                        |
| **THIRD-PARTY-PLUGIN** | Not shipped by Lurek2D. Built by a community author against the documented Rust crate API. | Discovered like TIER-1 (next to binary) or opted in like TIER-2 | User does not install it.                                                    |

The tier is a property of the **module**, not of the plugin loader: `ai` is always TIER-1, `physics` is always TIER-2, regardless of which loading mechanism (§6) the engine ships first.

CORE-KEEP modules are the floor of the engine identity. They are the modules a typical 2D game cannot run without:
`math`, `log`, `data`, `serial`, `runtime`, `event`, `timer`, `thread`, `filesystem`, `render`, `audio`, `input`, `image`, `window`, `camera`, `light`, `effect`, `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `sprite`, `i18n`, `graph`, `automation`, `app`, `lua_api`, `bin`, plus the documentation and tooling Edge modules.

---

## 5. Candidate modules

Source: [P1_EVIDENCE.md § 5 — Plugin candidate evaluation matrix](../../work/docs-api-arch-specs-review-20260418/reports/P1_EVIDENCE.md). Sorted by tier then LOC descending. Per user decision **D-1**, `physics` is **TIER-2-PLUGIN**.

| Module        |   LOC | Heavy deps                                       | Inbound callers (non `lua_api`) | Lua API surface                 | Tier          | Rationale                                                                                                |
| ------------- | ----: | ------------------------------------------------ | :-----------------------------: | ------------------------------- | ------------- | -------------------------------------------------------------------------------------------------------- |
| `ai`          | 7 860 | none                                             |                0                | `lurek.ai` (34 fn / 27 classes) | TIER-1-PLUGIN | Largest single optional surface. Most games don't ship FSM/BT/GOAP/HTN/MCTS at the engine level.         |
| `ui`          | 6 882 | none                                             |   1 (`runtime::shared_state`)   | `lurek.ui` (large)              | TIER-1-PLUGIN | Opinionated widget set; many games author UI in Lua directly.                                            |
| `pathfind`    | 5 880 | none                                             |                0                | `lurek.pathfind`                | TIER-1-PLUGIN | Paired with `ai`; co-extracted.                                                                          |
| `raycaster`   | 3 670 | none                                             |   1 (`runtime::shared_state`)   | `lurek.raycaster`               | TIER-1-PLUGIN | Wolf3D-style 2.5D only. Self-contained.                                                                  |
| `dataframe`   | 4 411 | `csv`                                            |                0                | `lurek.dataframe`               | TIER-1-PLUGIN | Power-user analytics; orthogonal to gameplay.                                                            |
| `network`     | 2 295 | `rusty_enet`, `ureq`, `tungstenite`, `rmp-serde` |                0                | `lurek.network`                 | TIER-1-PLUGIN | Heavy HTTP+WS+ENet+TLS tree. Most games are offline.                                                     |
| `terminal`    | 2 606 | none                                             |                0                | `lurek.terminal`                | TIER-1-PLUGIN | In-game dev REPL. Dev-only for shipping games.                                                           |
| `spine`       | 1 328 | custom Spine runtime                             |                0                | `lurek.spine`                   | TIER-1-PLUGIN | Proprietary format; niche.                                                                               |
| `physics`     | 4 921 | `rapier2d`, `rayon`                              |                0                | `lurek.physics` (19 fn)         | TIER-2-PLUGIN | Heavy `rapier2d` tree but most 2D games eventually need a solver — opt-in default ON in templates. (D-1) |
| `compute`     | 3 652 | none                                             |                0                | `lurek.compute` (11 fn)         | TIER-2-PLUGIN | GPU compute is specialist.                                                                               |
| `procgen`     | 3 021 | none                                             |                0                | `lurek.procgen`                 | TIER-2-PLUGIN | Keep noise/Perlin in core; move L-systems / WFC / dungeon generators.                                    |
| `mods`        |   672 | none                                             |                0                | `lurek.mods`                    | TIER-2-PLUGIN | Sandboxed mod loader; opt-in per game.                                                                   |
| `minimap`     | 1 574 | none                                             |                0                | `lurek.minimap` (1 fn)          | TIER-2-PLUGIN | Small; candidate for pure-Lua reimplementation in Lunasome on top of `tilemap`+`camera`.                 |
| `parallax`    |   708 | none                                             |   1 (`runtime::shared_state`)   | `lurek.parallax`                | TIER-2-PLUGIN | Tiny; strongest Lunasome reimplementation candidate.                                                     |
| `save`        |   803 | `serde`                                          |           (unchecked)           | `lurek.save`                    | TIER-2-PLUGIN | Thin wrapper over `filesystem` + `serial`; could become Lunasome.                                        |
| `debugbridge` |     — | TCP/WS server                                    |                0                | `lurek.debug.*`                 | TIER-2-PLUGIN | Dev-only. Already optional by intent.                                                                    |

**Coupling refactor required before any of these become dynamic plugins.** [src/runtime/shared_state.rs:26-37](../../src/runtime/shared_state.rs#L26) currently pool-holds `parallax`, `particle`, `raycaster`, `tilemap`, and `ui`. Five candidate modules are wired into the `SharedState` struct by direct `use crate::<m>::...` imports. Plugin extraction MUST first introduce a `SharedState` extension trait or per-plugin registration table so candidates can be removed from `SharedState` without breaking compile. This is migration step **M1** in §9.

---

## 6. Loading mechanism options

Three approaches, listed best-first for v1.

### Option A — Cargo features (compile-time)

Each plugin candidate becomes a Cargo feature on the root crate. The engine still ships as a single binary, but a `--no-default-features --features minimal` build excludes the modules that are not in the requested feature set.

- **Pros**: zero ABI risk, no `unsafe`, no dynamic loader code, all-Rust toolchain.
- **Cons**: not third-party-extensible (community plugins cannot ship without forking), produces multiple binaries (`lurek2d-core`, `lurek2d-full`), `conf.lua` `plugins = {...}` field is advisory only.
- **Recommendation**: ship this for v1. Solves the size problem (A-05) for Lurek2D's own modules; defers the third-party question.

### Option B — `libloading` dynamic libraries

Each plugin builds as a `cdylib` exposing a documented C ABI entry point. The engine scans `plugins/` next to the binary at startup and `dlopen`/`LoadLibrary`s each one.

- **Pros**: third-party plugins are possible, plugins can be installed without recompiling the engine, Steam SDK wrapper drops in cleanly.
- **Cons**: Rust has no stable ABI on stable channel; the C wrapper must marshal everything. Plugin and engine must agree exactly on Rust compiler + `mlua` versions, otherwise UB. Per-platform path resolution is brittle.
- **Recommendation**: defer to post-v1 (migration step M4). Use only for the Steam SDK wrapper and other true third-party use cases.

### Option C — Lua-first plugins (already available)

Many "plugin" candidates can be implemented in pure Lua against existing `lurek.*` APIs. The Lunasome library under [content/library/](../../content/library/) and the [library-authoring](../../.github/skills/library-authoring/SKILL.md) skill define this path.

- **Pros**: zero engine changes; immediate; hot-reloadable; no ABI surface.
- **Cons**: cannot expose new GPU / OS / native-FFI capabilities; performance ceiling is LuaJIT.
- **Recommendation**: use for `parallax`, `minimap`, `save`, and any candidate whose Rust footprint is mostly bookkeeping. Lunasome is already the right home for these.

**Recommended hybrid for v1**: Option A for engine modules + Option C for thin Rust wrappers, with Option B reserved for post-v1 third-party / platform SDK plugins.

Folder layout if Option B is enabled (post-v1):

```
lurek2d.exe (or lurek2d on Linux/macOS)
plugins/
├── ai.dll        (Windows)   |   ai.so   (Linux)   |   ai.dylib   (macOS)
├── physics.dll                |   physics.so         |   physics.dylib
└── steam.dll     (third-party)
assets/
main.lua
conf.toml
```

The loader scans `plugins/` exactly once, at engine boot, before the Lua VM is created. Failed plugins log a single error line and are skipped — the engine keeps booting.

---

## 7. Stability and ABI contract

The plugin Rust API is a single trait plus a registration helper. Both live in the (planned) `lurek_plugin_api` crate, which has only `mlua` and `runtime` types as public dependencies.

```rust
pub trait LurekPlugin: Send {
    /// Stable plugin identifier. Maps to `lurek.<name>` namespace.
    fn name(&self) -> &'static str;

    /// Register the plugin's `lurek.*` Lua surface. Same shape as C-02.
    fn register_lua(
        &self,
        lua: &Lua,
        luna: &LuaTable,
        state: Rc<RefCell<SharedState>>,
    ) -> LuaResult<()>;

    /// Engine boot hook. Called once after `app` is constructed and before `lurek.init`.
    fn on_load(&self, state: Rc<RefCell<SharedState>>) -> Result<(), EngineError> { Ok(()) }

    /// Engine shutdown hook. Called once during graceful quit.
    fn on_unload(&self, state: Rc<RefCell<SharedState>>) -> Result<(), EngineError> { Ok(()) }

    /// Semantic version of the plugin ABI this plugin was built against.
    fn abi_version(&self) -> u32 { CURRENT_ABI_VERSION }
}
```

**Versioning policy**: `LurekPlugin` is semver-locked on the `lurek_plugin_api` crate version. Major bump = ABI break = all plugins must be rebuilt.

**For Option B (dynamic) only**, plugins additionally export a C entry point inside a documented panic boundary:

```rust
#[no_mangle]
pub extern "C" fn lurek_plugin_init() -> *mut dyn LurekPlugin { ... }
```

Engine wraps the call in `std::panic::catch_unwind`, refuses to load the plugin if it panics, and never re-enters a panicked plugin.

The `lurek_plugin_api` crate ships a `plugin.toml` schema for plugin metadata. Required fields: `name`, `version`, `min_engine_version`, `max_engine_version`. Optional fields: `description`, `authors`, `license`, `homepage`, `repository`. The engine reads `plugin.toml` from a sibling location next to the `.dll` / `.so` / `.dylib` and refuses to load plugins outside the supported engine version range.

Compatibility policy: the engine guarantees binary compatibility within a MAJOR.MINOR series; plugins built against engine 0.20.x continue to load on 0.20.y. PATCH bumps never break the ABI; MINOR bumps may add new methods to `LurekPlugin` with default implementations; MAJOR bumps are free to break it.

---

## 8. Discovery and configuration

Plugins are declared in the game's `conf.lua` (or `conf.toml`):

```lua
function lurek.conf(t)
    t.window.width  = 1280
    t.plugins = { "physics", "ai", "raycaster" }
end
```

Resolution order:

1. **Static (Option A)**: `plugins = {...}` is checked against the compile-time feature set. Requested-but-missing entries warn at boot; unrequested-but-built entries register their `lurek.*` table without firing `on_load` until the game opts in.
2. **Dynamic (Option B)**: same `plugins = {...}` table is matched against `.dll` / `.so` / `.dylib` files in the `plugins/` folder next to the binary. Missing files produce a structured boot error pointing the user at the documented install path.

A `[plugins]` block in `conf.toml` may carry per-plugin configuration; the engine forwards the relevant table to each plugin's `on_load` via `SharedState::plugin_config(name)`. Example:

```toml
[plugins]
enabled  = ["physics", "ai", "raycaster"]
disabled = ["terminal"]

[plugins.physics]
gravity_y = -9.81
allow_sleep = true

[plugins.ai]
blackboard_capacity = 256
```

`enabled` is the authoritative list. `disabled` is consulted only when a plugin is auto-discovered (Option B) — it lets a user keep a `.dll` on disk while turning it off without deleting the file. Conflicts (`enabled` and `disabled` listing the same plugin) raise a boot error.

---

## 9. Migration plan

Phased to keep `cargo test` green at every step.

### M1 — Foundations: untangle `runtime::shared_state`

Refactor [src/runtime/shared_state.rs](../../src/runtime/shared_state.rs) so that the five plugin-candidate pools (`parallax`, `particle`, `raycaster`, `tilemap`, `ui`) are reachable through traits or a typed registry, not through direct `use crate::<m>` imports. After M1 the dependency arrow from `runtime` to those modules is gone. **Gate**: removing one of the five modules from the build no longer breaks compile in `runtime`.

### M2 — Compile-time plugins (Option A)

Introduce Cargo features `plugin-ai`, `plugin-ui`, `plugin-raycaster`, `plugin-physics`, `plugin-dataframe`, `plugin-network`, `plugin-terminal`, `plugin-spine`, `plugin-procgen`, `plugin-mods`. Default feature set is `[everything-on]` initially — no observable behaviour change. CI gains a build matrix: `--no-default-features` + each feature individually + a curated `minimal` set. **Gate**: every matrix cell builds and `cargo test --features <name>` passes.

### M3 — Size enforcement and A-05 promotion

Flip default features off for `minimal`. Measure the stripped release binary on Windows / Linux / macOS. If the stripped size meets ≤ 15 MB, promote **A-05** in [philosophy.md](philosophy.md#platform-and-runtime-constraints) from *Proposed* to *Active*, add a CI gate that rejects PRs pushing the stripped binary over budget, and update [README.md](../../README.md) to advertise the size guarantee. **Gate**: A-05 active; CI size budget green on all three platforms.

### M4 — Dynamic plugins (Option B), optional

Add the `libloading` path behind a `dynamic-plugins` Cargo feature. Port one TIER-1 plugin (recommended: `raycaster`, smallest with a clean boundary) as the proof. Document the third-party plugin author workflow. Plan the Steam SDK wrapper as the first third-party consumer. **Gate**: `raycaster.dll` loads on Windows, `raycaster.so` on Linux, `raycaster.dylib` on macOS; the in-tree `raycaster` module disappears from the static binary.

---

## 10. Comparison to other engines

| Engine                 | Plugin model                                                                   | Native ABI?  | Lua-first plugins? | Core size class             |
| ---------------------- | ------------------------------------------------------------------------------ | ------------ | ------------------ | --------------------------- |
| **LÖVE**               | None. Extensions are plain Lua libraries or LuaJIT FFI.                        | LuaJIT FFI   | Yes (de facto)     | ~6 MB                       |
| **Gideros**            | Closed-source plugin SDK (C++). Strong native story (mobile).                  | Yes          | Limited            | ~10–20 MB                   |
| **Solar2D**            | Lua frontend, monolithic Lua + native plugin server.                           | Yes (legacy) | Yes                | ~6–10 MB                    |
| **GameMaker**          | Extensions as DLLs / JS, marketplace-distributed. Tied to GMS.                 | Yes          | No (GML)           | ~100+ MB                    |
| **RPG Maker**          | Pure JS plugin model on top of NW.js / Electron.                               | No           | n/a (JS)           | ~80–150 MB                  |
| **Godot**              | GDExtension: stable C ABI since 4.1, first-class.                              | Yes (stable) | GDScript only      | ~60–100 MB                  |
| **Lurek2D (proposed)** | Hybrid: Cargo features (M2/M3), Lunasome Lua libs, optional `libloading` (M4). | Planned (M4) | Yes (Lunasome)     | **≤ 15 MB stripped (A-05)** |

Position: **simpler than Godot's GDExtension** (no full ABI surface to maintain in v1), **more native than RPG Maker's JS** (Rust + LuaJIT vs Electron), **smaller core than LÖVE-with-everything-bundled** (LÖVE ships every module always).

---

## 11. Risks and open questions

1. **Rust ABI stability**. Option B dynamic plugins on Rust stable require pinning rustc + `mlua` versions exactly between engine and plugin. Mitigation: ship a `lurek_plugin_api` crate with a published version table; refuse to load mismatched plugins.
2. **`runtime::shared_state` refactor scope**. M1 touches a hub used by every subsystem. Risk: regression in unrelated modules. Mitigation: do M1 as a no-op refactor first (introduce trait, route existing pools through it without removing them), then remove direct imports module-by-module.
3. **Plugin Lua VM access from worker threads**. Constraint **B-04**: LuaJIT VMs cannot share state. Plugin `on_load` must declare whether it spawns workers; the engine forbids workers from registering `lurek.*` functions on the main VM after boot. Open: where do plugin workers send their results? Probably the existing `Channel` API.
4. **Discovery on Linux `dlopen` paths**. `LD_LIBRARY_PATH`, `RPATH`, and AppImage layouts each surface plugins differently. Need a documented install layout before M4.
5. **Steam SDK licensing**. Steamworks SDK is closed and per-publisher licensed. The wrapper plugin must live in a separate repo with its own licence terms; Lurek2D core can never link it.
6. **Pure-Lua candidate evaluation**. `parallax`, `minimap`, `save` could collapse to Lunasome libraries instead of Rust plugins. Decision deferred to a separate session; this doc lists them as TIER-2 placeholders.
7. **Plugin testing harness**. Each plugin needs its own slice of [tests/lua/](../../tests/lua/). The Lua-first testing rule (philosophy.md, **C-04**) extends to plugins. Open: shared harness or per-plugin?
8. **Plugin docs in [docs/specs/](../specs/)**. When a module becomes a plugin, does its spec move to `docs/plugins/<name>.md`? Or does `docs/specs/<name>.md` gain a "Plugin: TIER-1" header? Recommendation: stay in `docs/specs/`; tier already lives in [docs/specs/README.md](../specs/README.md).
9. **Conf-file precedence**. If `conf.toml` and `conf.lua` both declare `plugins`, which wins? Existing engine policy: `conf.toml` preferred, `conf.lua` legacy fallback. Plugins inherit that.
10. **Versioning a TIER-1 plugin against multiple engine releases**. Plugin author needs to know which engine versions a given plugin is compatible with. Plugin manifest must carry `min_engine_version` / `max_engine_version`.
11. **Hot-disable in dev loop**. Iterating on a plugin currently means rebuilding the whole engine in Option A. We may want a developer-only Option B path that targets exactly one plugin, even before M4 lands as a shipping feature. Decision: defer to M4.
12. **Plugin discovery from VS Code extension**. The shipping VS Code extension ([extensions/vscode/](../../extensions/vscode/)) needs to know which plugins are present so its IntelliSense and run-with-profile commands match. Open: should the engine emit a `plugins.json` next to the binary at boot, or should the extension parse `Cargo.toml` features?

---

## 12. References

- [philosophy.md § Platform and Runtime Constraints](philosophy.md#platform-and-runtime-constraints) — A-04 (no platform SDKs in core), A-05 (Proposed: ≤ 15 MB).
- [philosophy.md § Active Module Group Constraints](philosophy.md#active-module-group-constraints) — T-08 (Steam SDK wrappers live outside the five-group stack).
- [engine-architecture.md § Module Group Model](engine-architecture.md#module-group-model) — five-tier responsibility model the plugin tiers map onto.
- [engine-architecture.md § State Architecture](engine-architecture.md#state-architecture) — `SharedState` design, the surface M1 refactors.
- [P1_EVIDENCE.md § 5](../../work/docs-api-arch-specs-review-20260418/reports/P1_EVIDENCE.md) — evidence file behind the candidate matrix in §5.
- [Godot GDExtension docs](https://docs.godotengine.org/en/stable/contributing/development/core_and_modules/gdextension.html) — closest peer model, source of the stable-ABI pattern.
- [Defold native extensions](https://defold.com/manuals/extensions/) — manifest-driven plugin model.
- [LÖVE wiki](https://love2d.org/wiki/) — counter-example: monolithic engine, Lua-first extensibility only.
