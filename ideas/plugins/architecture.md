# Plugin Architecture — Technical Design

## Current Monolith

Today Lurek2D is a single Cargo binary crate:

```
src/
├── main.rs              ← entry point
├── lib.rs               ← library root
├── engine/              ← SharedState, Config, App, resource keys
├── math/                ← Baseline (Vec2, Mat3, Rect, Color, ...)
├── graphics/            ← Tier 1 — wgpu renderer
├── audio/               ← Tier 1 — rodio mixer
├── physics/             ← Tier 1 — rapier2d
├── input/               ← Tier 1 — keyboard/mouse/gamepad
├── timer/               ← Tier 1 — frame timing
├── ... (15 more T1)
├── particle/            ← Tier 2 — particle system
├── tilemap/             ← Tier 2 — tile maps
├── scene/               ← Tier 2 — scene stack
├── ai/                  ← Tier 2 — game AI
├── ... (10 more T2)
├── lua_api/             ← Bridge — 46 *_api.rs files
│   └── mod.rs           ← create_lua_vm() wires everything
└── bin/                 ← CLI argument handling
```

Dependencies: mlua 0.9 (LuaJIT vendored), wgpu 22, winit 0.30, rapier2d 0.32,
rodio 0.17, fontdue 0.9, gilrs 0.11, plus ~30 utility crates.

Binary size: ~20 MB (release, stripped).

---

## Target Architecture

### Layer 1 — Cargo Workspace (compile-time crate boundaries)

```
lurek2d/                       ← Cargo workspace root
├── Cargo.toml                ← [workspace] members
├── crates/
│   ├── lurek2d-core/          ← lib crate: Baseline + Tier 1 + bridge
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── engine/       ← SharedState, Config, App
│   │       ├── math/         ← Baseline
│   │       ├── graphics/     ← Tier 1
│   │       ├── audio/        ← Tier 1
│   │       ├── physics/      ← Tier 1
│   │       ├── input/        ← Tier 1
│   │       ├── timer/        ← Tier 1
│   │       ├── ... (all Tier 1 modules)
│   │       └── lua_api/      ← Core bindings only
│   │
│   ├── lurek2d-plugin-api/    ← Tiny interface crate (C-ABI types + version)
│   │   ├── Cargo.toml
│   │   └── src/lib.rs        ← PluginDecl, PLUGIN_API_VERSION, PluginRegistrar trait
│   │
│   ├── lurek2d-gamedev/       ← cdylib: Tier 2 game modules
│   │   ├── Cargo.toml        ← depends on lurek2d-plugin-api + mlua/module
│   │   └── src/
│   │       ├── lib.rs        ← exports luaopen_luna_gamedev
│   │       ├── particle/
│   │       ├── tilemap/
│   │       ├── scene/
│   │       ├── ai/
│   │       ├── pathfinding/
│   │       ├── gui/
│   │       └── ... (all Tier 2 game modules + their *_api.rs bindings)
│   │
│   ├── lurek2d-business/      ← cdylib: business/data domain
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs        ← exports luaopen_luna_business
│   │       ├── dataframe/
│   │       ├── pipeline/
│   │       ├── graph/
│   │       └── ...
│   │
│   └── lurek2d-bin/           ← binary crate: thin main.rs
│       ├── Cargo.toml        ← depends on lurek2d-core
│       └── src/main.rs       ← CLI parse, plugin discovery, event loop
│
├── plugins/                  ← Runtime plugin drop folder
│   ├── luna_gamedev.dll      ← built from lurek2d-gamedev
│   ├── luna_business.dll     ← built from lurek2d-business
│   └── ...                   ← third-party plugins
│
└── library/                  ← Tier 3 pure-Lua (unchanged)
```

### What Goes Where

| Crate | Modules | Output | Size Est. |
|-------|---------|--------|-----------|
| `lurek2d-core` | engine, math, graphics, audio, physics, input, timer, filesystem, window, camera, animation, event, image, thread, data, serial, entity, compute, sound, light, savegame, modding, localization, log, devtools, debugbridge, automation, system, docs, network, procgen, raycaster, spine | `libluna2d_core.rlib` (static, linked into bin) | ~15 MB |
| `lurek2d-gamedev` | particle, tilemap, scene, gui, overlay/fx, minimap, pathfinding, ai, graph, pipeline, patterns, terminal | `luna_gamedev.dll` | ~3 MB |
| `lurek2d-business` | dataframe (extended), pipeline (extended), graph (extended), reporting, analytics | `luna_business.dll` | ~2 MB |
| `lurek2d-bin` | main.rs only | `lurek2d.exe` | ~15 MB (links core statically) |
| `lurek2d-plugin-api` | C-ABI interface types | header-only-equivalent | ~10 KB |

---

## Plugin Loading Mechanism

### Strategy: `libloading` + Raw `luaopen_*` Call

This avoids the LuaJIT symbol export problem entirely. The host owns the `lua_State*`,
loads each plugin DLL, finds the `luaopen_<name>` symbol, and passes in _its own_
`lua_State*` as a raw pointer.

```
┌──────────────────────────────────────────────────────┐
│                    lurek2d.exe                         │
│                                                      │
│  ┌──────────┐  ┌──────────────────────────────────┐  │
│  │ main.rs  │  │ lurek2d-core (static)             │  │
│  │          │→ │  engine, math, graphics, audio,  │  │
│  │ CLI args │  │  physics, input, timer, ...      │  │
│  │ conf.lua │  │  lua_api (core bindings)         │  │
│  │          │  │  create_lua_vm() → lua_State*    │  │
│  └──────────┘  └──────────────────────────────────┘  │
│        │                                             │
│        │  for each plugin in conf.toml.plugins:      │
│        │    lib = libloading::Library::new(path)      │
│        │    init = lib.get(b"luaopen_<name>")        │
│        │    init(lua_state_raw_ptr)                   │
│        ▼                                             │
│  ┌─────────────────┐  ┌─────────────────────┐       │
│  │ luna_gamedev.dll │  │ luna_business.dll   │       │
│  │                  │  │                     │       │
│  │ luaopen_luna_    │  │ luaopen_luna_       │       │
│  │   gamedev(L)     │  │   business(L)       │       │
│  │                  │  │                     │       │
│  │ Registers:       │  │ Registers:          │       │
│  │  lurek.tilemap    │  │  lurek.report        │       │
│  │  lurek.scene      │  │  lurek.analytics     │       │
│  │  lurek.ai         │  │  lurek.workflow      │       │
│  │  lurek.particles  │  │  ...                │       │
│  │  ...             │  │                     │       │
│  └─────────────────┘  └─────────────────────┘       │
└──────────────────────────────────────────────────────┘
```

### Boot Sequence (Detailed)

```
1. CLI args parsed             → game_path, extra flags
2. Config loaded               → conf.toml or conf.lua (temp VM)
3. App::new()                  → winit, wgpu, rodio, GameFS initialized
4. create_lua_vm()             → LuaJIT VM with core lurek.* registered
5. Plugin discovery:
   a. Read conf.toml [plugins] → ordered list of plugin names
   b. Scan plugins/ folder     → match names to .dll/.so/.dylib files
   c. For each plugin:
      i.   libloading::Library::new(path)
      ii.  Validate version:  lib.get(b"LUNA_PLUGIN_API_VERSION") → check == host
      iii. Get entry:         lib.get(b"luaopen_<name>") → fn(*mut lua_State)
      iv.  Call entry:        entry(lua.as_raw_state())
      v.   Log success/failure
6. Load main.lua               → user game code
7. lurek.init() callback
8. lurek.ready() callback
9. Event loop                  → process → render → repeat
```

### Configuration

```toml
# conf.toml
[plugins]
# Ordered list of plugin libraries to load at startup.
# Names map to files: "gamedev" → plugins/luna_gamedev.dll (.so / .dylib)
load = ["gamedev", "business"]

# Optional: custom plugin search paths (in addition to ./plugins/)
search_paths = ["C:/lurek2d/plugins", "/usr/local/lib/lurek2d/plugins"]

# Per-plugin configuration (forwarded to the plugin's init function)
[plugins.gamedev]
enable_tilemap = true
enable_ai = false

[plugins.business]
analytics_backend = "sqlite"
```

---

## ABI Contract

### Why Not Rust-to-Rust DLL?

Rust has **no stable ABI**. If the exe is compiled with `rustc 1.82` and the plugin with
`rustc 1.83`, struct layouts may differ silently — this is undefined behaviour.

Solutions:
- `abi_stable` crate: pins layout with `#[StableAbi]` derive — adds compile-time checks
- `stabby` crate: similar but newer, supports niche optimization
- C ABI only: `extern "C"` functions, `#[repr(C)]` structs — works always

### Our Choice: Lua C API as the ABI Boundary

Plugins communicate **only through the Lua C API** (`lua_State*`). This is:
- Stable across LuaJIT versions (unchanged since 2005)
- Language-agnostic (plugins can be C, C++, Rust, Zig, etc.)
- Already what `mlua`'s `module` feature does under the hood

The plugin receives a raw `*mut lua_State` and uses `mlua::Lua::init_from_ptr(L)` to get
a safe Rust `Lua` handle. Then it registers tables and functions exactly like the core does.

### Version Gating

Every plugin DLL exports two `#[no_mangle]` statics:

```rust
#[no_mangle]
pub static LUNA_PLUGIN_API_VERSION: u32 = 1;  // bump on breaking change

#[no_mangle]
pub static LUNA_PLUGIN_RUSTC_VERSION: &str = env!("RUSTC_VERSION");  // informational
```

The host checks `LUNA_PLUGIN_API_VERSION` at load time. Mismatch → skip + log warning.

---

## Plugin Crate Template

### Cargo.toml

```toml
[package]
name = "lurek2d-gamedev"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]  # produces .dll / .so / .dylib

[dependencies]
mlua = { version = "0.9", features = ["luajit", "module"] }
lurek2d-plugin-api = { path = "../lurek2d-plugin-api" }
```

### src/lib.rs

```rust
use mlua::prelude::*;

// Re-export version for host validation
#[no_mangle]
pub static LUNA_PLUGIN_API_VERSION: u32 = luna2d_plugin_api::API_VERSION;

/// Entry point called by the Lurek2D host.
/// Receives the host's lua_State* and registers lurek.tilemap, lurek.scene, etc.
#[no_mangle]
pub unsafe extern "C" fn luaopen_luna_gamedev(L: *mut mlua::lua_State) -> i32 {
    // Safety: L is a valid lua_State* owned by the host. We borrow it.
    let lua = unsafe { Lua::init_from_ptr(L) };
    match register_all(&lua) {
        Ok(()) => 0,
        Err(e) => {
            eprintln!("luna_gamedev plugin init failed: {e}");
            0
        }
    }
}

fn register_all(lua: &Lua) -> LuaResult<()> {
    let luna: LuaTable = lua.globals().get("lurek")?;

    // Each sub-module registers into the existing lurek.* namespace
    tilemap::register(lua, &luna)?;
    scene::register(lua, &luna)?;
    ai::register(lua, &luna)?;
    particle::register(lua, &luna)?;
    // ...
    Ok(())
}

mod tilemap;
mod scene;
mod ai;
mod particle;
```

---

## SharedState Challenge

### Problem

Core `lua_api` modules receive `Rc<RefCell<SharedState>>`. Plugins loaded as DLLs do
**not** have access to this because:
1. `SharedState` is a Rust type with unstable layout — cannot cross the DLL boundary
2. Even if sizes match, `Rc` reference counts are per-allocation — a clone in the DLL
   would not share the same counter

### Solutions (by complexity)

#### Solution 1 — Lua-Only Surface (Recommended for Phase 2)

Plugin does not access `SharedState`. It only uses `lua_State*` to:
- Create tables and functions
- Read/write Lua globals and `lurek.*` subtables
- Call existing `lurek.*` functions from within Rust (via `lurek.gfx.draw(...)`)

This covers 90% of use cases. A tilemap plugin doesn't need `SharedState` directly —
it manages its own grid data and calls `lurek.gfx.drawQuad()` to render tiles.

#### Solution 2 — Serialized State Snapshot (Phase 3)

Host serializes key state slices into a Lua table (`lurek._host_state`) that plugins can
read. Read-only, refreshed per frame:

```lua
-- Available to plugins (set by host before plugin functions execute)
lurek._host_state = {
    delta_time = 0.016,
    window_width = 1280,
    window_height = 720,
    mouse_x = 400,
    mouse_y = 300,
    frame_count = 12345,
}
```

#### Solution 3 — C-ABI Host Vtable (Phase 4, only if needed)

Export a `#[repr(C)]` struct of function pointers from the host:

```rust
#[repr(C)]
pub struct LunaHostVtable {
    pub get_delta_time: extern "C" fn() -> f32,
    pub get_window_size: extern "C" fn(*mut u32, *mut u32),
    pub schedule_draw_rect: extern "C" fn(x: f32, y: f32, w: f32, h: f32, color: u32),
    pub load_texture: extern "C" fn(path: *const c_char) -> u64,  // returns TextureKey as u64
    pub draw_texture: extern "C" fn(key: u64, x: f32, y: f32, w: f32, h: f32),
    // ... max ~50 carefully designed function pointers
}
```

Plugin receives `*const LunaHostVtable` alongside `lua_State*`. This allows direct
GPU queueing and resource management from plugins.

---

## Module Classification for Split

### Always in `lurek2d-core` (Baseline + Tier 1)

These form the minimal runtime. A script with just these is a complete app:

| Module | lurek.* namespace | Justification |
|--------|-----------------|---------------|
| engine | (internal) | SharedState, Config, App — cannot be external |
| math | lurek.math | Leaf dependency, used everywhere |
| graphics | lurek.gfx | Core renderer — plugins draw via it |
| audio | lurek.audio | Core audio — plugins play via it |
| physics | lurek.physics | Core physics — fundamental subsystem |
| input | lurek.keyboard/mouse/gamepad | Core input — cannot be deferred |
| timer | lurek.time | Frame timing — fundamental |
| window | lurek.window | Window state — fundamental |
| camera | lurek.camera | View transform — needed by renderer |
| filesystem | lurek.fs | Sandboxed I/O — needed before plugins load |
| event | lurek.signal | Event bus — inter-module communication |
| image | lurek.img | CPU image ops — used by texture loading |
| data | lurek.data | Binary data — used by serialization |
| serial | lurek.codec | Format I/O — used by config loading |
| entity | lurek.entity | ECS — used by many higher modules |
| savegame | lurek.savegame | Save/load — core lifecycle |
| log | lurek.log | Logging — must be available immediately |
| system | lurek.platform | OS queries — boot-time |
| modding | lurek.modding | Mod discovery — affects asset search |
| localization | lurek.localization | L10n — needed early |
| thread | lurek.thread | Workers — core concurrency |
| animation | lurek.tween | Sprite animation — tight gfx coupling |
| light | lurek.light | 2D lighting — tight gfx coupling |

### `lurek2d-gamedev` Plugin (Tier 2 Game)

| Module | lurek.* namespace | Justification |
|--------|-----------------|---------------|
| particle | lurek.particles | Visual effect — not required for all apps |
| tilemap | lurek.tilemap | Genre-specific (RPG, strategy) |
| scene | lurek.scene | Scene management — optional pattern |
| gui | lurek.ui | Retained UI — many games use immediate |
| overlay/fx | lurek.postfx | Post-processing — optional visual layer |
| minimap | lurek.minimap | Genre-specific |
| pathfinding | lurek.pathfinding | Genre-specific (RPG, RTS) |
| ai | lurek.ai | Genre-specific |
| graph | lurek.graph | Specialized data structure |
| pipeline | lurek.pipeline | DAG orchestration |
| patterns | lurek.patterns | Design pattern helpers |
| terminal | lurek.terminal | Text-mode emulator |
| raycaster | lurek.raycaster | Retro rendering technique |
| spine | lurek.spine | Skeletal animation format |
| procgen | lurek.procgen | Procedural generation |

### `lurek2d-business` Plugin (Tier 2 Business)

| Module | lurek.* namespace | Justification |
|--------|-----------------|---------------|
| dataframe | lurek.dataframe | Tabular data processing |
| pipeline | lurek.pipeline | Workflow automation |
| graph | lurek.graph | Network/dependency analysis |
| (new) reporting | lurek.report | Report generation |
| (new) analytics | lurek.analytics | Event tracking and metrics |
| (new) workflow | lurek.workflow | Business process automation |
| (new) dashboard | lurek.dashboard | Data visualization widgets |

### Pure Lua Libraries (Tier 3, unchanged)

`library/` stays as pure Lua. These are already loaded via `require()`:

battle, cardgame, combat, crafting, dialog, doll, economy, inventory, item,
province_map, quest, stats

---

## Plugin Discovery Algorithm

```
function discover_plugins(conf: Config) -> Vec<PluginInfo>:
    search_paths = [
        game_dir / "plugins",
        exe_dir / "plugins",
        conf.plugins.search_paths...,
    ]

    for name in conf.plugins.load:
        for dir in search_paths:
            platform_name = match OS:
                Windows → "luna_{name}.dll"
                macOS   → "libluna_{name}.dylib"
                Linux   → "libluna_{name}.so"

            path = dir / platform_name
            if path.exists():
                yield PluginInfo { name, path, config: conf.plugins[name] }
                break
        else:
            log::warn!("Plugin '{name}' not found in any search path")
```

---

## Dependency Graph After Split

```
lurek2d-plugin-api          (no deps — pure types)
        ↑
        │
lurek2d-core                (mlua/luajit/vendored, wgpu, winit, rodio, ...)
        ↑                  ↑ (interface only)
        │                  │
lurek2d-bin ─────────────── │ ──→ libloading (runtime DLL loading)
                           │
lurek2d-gamedev ────────────┘ (mlua/module, cdylib)
lurek2d-business ───────────┘ (mlua/module, cdylib)
```

**Key rule**: Plugin crates depend on `lurek2d-plugin-api` only, never on `lurek2d-core`.
They get their Lua handle from the raw `lua_State*` pointer.
