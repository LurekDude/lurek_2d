# Plugin Architecture — Implementation Roadmap

## Phase Overview

| Phase | Name | Effort | Risk | Deliverable |
|-------|------|--------|------|-------------|
| 0 | Preparation | 1 week | LOW | Interface crate, build system changes |
| 1 | Cargo Workspace Split | 2–3 weeks | MEDIUM | `luna2d-core`, `luna2d-bin` crates; all tests pass |
| 2 | Plugin Loading | 1–2 weeks | MEDIUM | `libloading` integration; first `luna_gamedev.dll` |
| 3 | Plugin Ecosystem | 2 weeks | LOW | `luna_business.dll`, template, docs, examples |
| 4 | Host Vtable (Optional) | 3–4 weeks | HIGH | C-ABI host interface for GPU/audio access from plugins |
| 5 | Embeddable Library | 2 weeks | MEDIUM | `luna2d-core` usable from Python/C# frontends |
| 6 | Cross-Platform | 2–3 weeks | MEDIUM | macOS/Linux plugin loading; CI for all platforms |

**Total estimated scope**: 12–16 weeks if done sequentially. Phases 3–6 can partially
overlap.

---

## Phase 0 — Preparation

### Goal
Set up the workspace infrastructure and interface crate without touching any existing
module code. Zero risk of breaking anything.

### Tasks

- [ ] **P0.1** Create `crates/` directory structure
- [ ] **P0.2** Create `luna2d-plugin-api` crate:
  ```rust
  // crates/luna2d-plugin-api/src/lib.rs
  pub const API_VERSION: u32 = 1;

  /// Metadata embedded in every plugin DLL
  #[repr(C)]
  pub struct PluginDeclaration {
      pub api_version: u32,
      pub name: *const std::ffi::c_char,
      pub version: *const std::ffi::c_char,
  }
  ```
- [ ] **P0.3** Add `libloading = "0.8"` to workspace dependencies
- [ ] **P0.4** Add `[plugins]` section to `Config` struct and TOML parser in `config.rs`:
  ```rust
  #[derive(Debug, Clone, Serialize, Deserialize)]
  pub struct PluginsConfig {
      pub load: Vec<String>,
      pub search_paths: Vec<String>,
  }
  ```
- [ ] **P0.5** Add `plugins/` to `.gitignore` (DLL outputs are build artifacts)
- [ ] **P0.6** Create `tools/build_plugin.ps1` / `tools/build_plugin.sh` scripts
- [ ] **P0.7** Update `docs/CHANGELOG.md` with plugin preparation entry

### Acceptance Gate
- `cargo check` passes with new crates in workspace
- `conf.toml` parser accepts `[plugins]` section without errors
- Existing `cargo test` suite passes unchanged

---

## Phase 1 — Cargo Workspace Split

### Goal
Move code into separate crates within the same workspace. The binary output is
identical — all crates are still statically linked. This validates the dependency
boundaries before adding dynamic loading.

### Tasks

- [ ] **P1.1** Convert root `Cargo.toml` to a workspace:
  ```toml
  [workspace]
  members = [
      "crates/luna2d-core",
      "crates/luna2d-plugin-api",
      "crates/luna2d-gamedev",
      "crates/luna2d-bin",
  ]
  resolver = "2"

  [workspace.dependencies]
  mlua = { version = "0.9", default-features = false }
  log = "0.4"
  # ... shared deps
  ```

- [ ] **P1.2** Create `crates/luna2d-core/`:
  - Move Baseline + Tier 1 modules: `engine/`, `math/`, `graphics/`, `audio/`,
    `physics/`, `input/`, `timer/`, `window/`, `camera/`, `filesystem/`, `event/`,
    `image/`, `data/`, `serial/`, `entity/`, `savegame/`, `light/`, `animation/`,
    `thread/`, `log/`, `localization/`, `system/`, `modding/`, `compute/`, `network/`,
    `sound/`, `devtools/`, `debugbridge/`, `automation/`, `docs/`
  - Move their corresponding `lua_api/*_api.rs` files
  - Keep `create_lua_vm()` in `luna2d-core` but make it accept a plugin registrar
  - Export `pub fn create_lua_vm()` and `pub struct SharedState`

- [ ] **P1.3** Create `crates/luna2d-gamedev/` as a **lib crate** (not cdylib yet):
  - Move Tier 2 game modules: `particle/`, `tilemap/`, `scene/`, `gui/`, `fx/`,
    `minimap/`, `pathfinding/`, `ai/`, `graph/`, `pipeline/`, `patterns/`,
    `terminal/`, `raycaster/`, `spine/`, `procgen/`
  - Move their `lua_api/*_api.rs` files
  - For now, this crate depends on `luna2d-core` and is linked statically
  - Export: `pub fn register_all(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`

- [ ] **P1.4** Create `crates/luna2d-bin/`:
  - Move `src/main.rs` → `crates/luna2d-bin/src/main.rs`
  - Move `src/bin/` → `crates/luna2d-bin/src/bin/`
  - Depends on `luna2d-core` and `luna2d-gamedev` (static link)
  - `main()` calls `luna2d_core::create_lua_vm()` then `luna2d_gamedev::register_all()`

- [ ] **P1.5** Fix all `use crate::` paths in moved files
  - Core modules: `use crate::` → still `use crate::` (within luna2d-core)
  - Gamedev modules: `use crate::engine::SharedState` → `use luna2d_core::SharedState`
  - This is the bulk of the work — ~200 files need import updates

- [ ] **P1.6** Update `build.rs` for workspace layout
- [ ] **P1.7** Update `.cargo/config.toml` build output paths
- [ ] **P1.8** Fix all test crates (`tests/`) — update paths and dependencies
- [ ] **P1.9** Run full test suite: `cargo test` must pass
- [ ] **P1.10** Run `cargo clippy -- -D warnings` must pass
- [ ] **P1.11** Verify binary size is within 5% of pre-split size
- [ ] **P1.12** Update `docs/architecture/engine-architecture.md`
- [ ] **P1.13** Update all `src/<module>/AGENT.md` files with new crate paths
- [ ] **P1.14** Update `docs/CHANGELOG.md`

### Acceptance Gate
- `cargo test` — all tests pass (same count as before split)
- `cargo clippy -- -D warnings` — clean
- Binary size delta < 5%
- All existing `demos/` run correctly
- `cargo build --release` completes successfully

### Risk Mitigation
- Do this on a `feat/workspace-split` branch
- Commit after each task (P1.1, P1.2, etc.) so rollback is granular
- Run tests after every module move — catch import errors early
- Keep the old flat structure on `root` branch as fallback

---

## Phase 2 — Plugin Loading

### Goal
Add `libloading`-based plugin discovery and loading. Convert `luna2d-gamedev` from a
static lib to a cdylib. Verify that `luna_gamedev.dll` loads and registers the same
`luna.*` APIs.

### Tasks

- [ ] **P2.1** Implement `PluginLoader` in `luna2d-core`:
  ```rust
  // crates/luna2d-core/src/engine/plugin_loader.rs
  pub struct PluginLoader {
      loaded: Vec<libloading::Library>,  // keep DLLs alive
  }

  impl PluginLoader {
      pub fn new() -> Self;
      pub fn discover(config: &PluginsConfig) -> Vec<PluginInfo>;
      pub fn load(&mut self, info: &PluginInfo, lua: &Lua) -> Result<(), PluginError>;
      pub fn load_all(&mut self, config: &PluginsConfig, lua: &Lua) -> Vec<PluginError>;
  }
  ```

- [ ] **P2.2** Convert `luna2d-gamedev` to dual output:
  ```toml
  [lib]
  crate-type = ["rlib", "cdylib"]  # rlib for static linking, cdylib for plugin
  ```

- [ ] **P2.3** Add `luaopen_luna_gamedev` entry point to `luna2d-gamedev/src/lib.rs`
  - Use `std::panic::catch_unwind` at the boundary
  - Register all Tier 2 modules into `luna.*` via raw `lua_State*`

- [ ] **P2.4** Refactor `luna2d-gamedev` modules to NOT require `SharedState`:
  - Each module manages its own internal state
  - Rendering goes through `luna.gfx.*` Lua calls (not direct DrawCommand enqueue)
  - State queries use `luna.time.getDelta()`, `luna.window.getWidth()`, etc.
  - **THIS IS THE HARDEST TASK** — see "SharedState Decoupling" below

- [ ] **P2.5** Update boot sequence in `luna2d-bin/src/main.rs`:
  ```rust
  let lua = luna2d_core::create_lua_vm(state.clone(), &config.modules)?;

  // Plugin loading
  let mut plugin_loader = PluginLoader::new();
  let plugins = PluginLoader::discover(&config.plugins);
  for info in &plugins {
      if let Err(e) = plugin_loader.load(info, &lua) {
          log::warn!("Failed to load plugin '{}': {}", info.name, e);
      }
  }
  ```

- [ ] **P2.6** Add plugin loading tests:
  - Test: discover returns empty when `plugins/` is missing
  - Test: discover finds `luna_gamedev.dll` in `plugins/`
  - Test: version mismatch is rejected
  - Test: missing `luaopen_*` symbol is handled gracefully
  - Test: loaded plugin's `luna.tilemap` functions are callable

- [ ] **P2.7** Build pipeline:
  - `cargo build -p luna2d-bin` → `luna2d.exe`
  - `cargo build -p luna2d-gamedev` → `luna_gamedev.dll`
  - Copy DLL to `plugins/` folder
  - `dist.ps1` updated to include `plugins/` in distribution

- [ ] **P2.8** Verify all existing demos work with the plugin-loaded gamedev modules
- [ ] **P2.9** Update docs, examples, CHANGELOG

### SharedState Decoupling (P2.4 Detail)

The current Tier 2 modules receive `Rc<RefCell<SharedState>>` and use it for:

1. **Reading frame state** (delta_time, window_size, mouse_pos) — replace with Lua calls
2. **Enqueuing DrawCommands** — replace with Lua calls to `luna.gfx.drawQuad()` etc.
3. **Accessing resource pools** (texture keys, font keys) — keep resource IDs as Lua
   integers/strings, let core resolve them
4. **Modifying shared state** (adding entities, events) — use `luna.entity.*`, `luna.signal.*`

Modules that heavily depend on SharedState:
- `particle/` — reads delta_time, enqueues draw commands → must use Lua bridge
- `tilemap/` — manages grid data (independent), renders via draw calls → straightforward
- `scene/` — pushes/pops scenes, calls lifecycle hooks → mostly Lua-side already
- `gui/` — renders widgets via draw commands → must use Lua bridge
- `ai/` — pure logic, no rendering → trivial to decouple
- `pathfinding/` — pure logic → trivial
- `graph/` — pure logic → trivial

### Acceptance Gate
- `luna_gamedev.dll` loads successfully at runtime
- All Tier 2 `luna.*` functions are available in Lua after plugin load
- All existing demos work identically
- Plugin loader handles errors gracefully (missing DLL, version mismatch, bad symbol)
- No `unsafe` without `// SAFETY:` comments

---

## Phase 3 — Plugin Ecosystem

### Goal
Create the business plugin, a plugin template for third parties, and comprehensive documentation.

### Tasks

- [ ] **P3.1** Create `luna2d-business` crate:
  - `dataframe` (enhanced tabular processing)
  - `pipeline` (workflow automation)
  - `graph` (network analysis)
  - New: `reporting` module (generate documents)
  - New: `analytics` module (event tracking)

- [ ] **P3.2** Create `crates/luna2d-plugin-template/`:
  - Minimal boilerplate for third-party plugin authors
  - `Cargo.toml`, `src/lib.rs` with `luaopen_*` scaffold
  - README with instructions

- [ ] **P3.3** Create `tools/new_plugin.ps1` — scaffolding script:
  ```powershell
  # Usage: .\tools\new_plugin.ps1 -Name "my_extension"
  # Creates: crates/luna2d-my-extension/ with boilerplate
  ```

- [ ] **P3.4** Write `docs/architecture/plugin-guide.md`:
  - How to create a plugin
  - How to register `luna.*` functions
  - How to access host APIs via Lua
  - How to test plugins
  - How to distribute plugins

- [ ] **P3.5** Create `examples/plugin_demo/` — demo showing plugin loading
- [ ] **P3.6** Add plugin tests to `tests/lua/unit/test_plugin_loading.lua`
- [ ] **P3.7** Update installer (`tools/dist/installer.nsi`) — install plugins to `plugins/`
- [ ] **P3.8** Update `dist.ps1` and `dist.sh` — include `plugins/` in archives

### Acceptance Gate
- `luna_business.dll` loads and provides `luna.dataframe`, `luna.pipeline`
- Template creates a working plugin from scratch
- Documentation reviewed and complete
- Example demo runs with plugin loaded

---

## Phase 4 — Host Vtable (Optional)

### Goal
For plugins that need direct engine access (custom shaders, audio buses, new draw
commands), provide a C-ABI vtable of host capabilities.

### Tasks

- [ ] **P4.1** Design `LunaHostVtable` — define which functions to expose:
  - `schedule_draw_*` functions for custom draw commands
  - `load_texture`, `unload_texture` for resource management
  - `play_sound`, `stop_sound` for audio
  - `get_delta_time`, `get_frame_count` for state queries
  - Max ~50 function pointers — keep surface small

- [ ] **P4.2** Update `luna2d-plugin-api` with vtable type
- [ ] **P4.3** Implement vtable population in `luna2d-core`
- [ ] **P4.4** Update `PluginLoader` to pass vtable pointer alongside `lua_State*`
- [ ] **P4.5** Create example: 3D raycasting plugin using vtable for custom draw commands
- [ ] **P4.6** Add `abi_stable` or `stabby` for safe complex-type passing (if needed)
- [ ] **P4.7** Document vtable API, versioning, and forward-compatibility rules

### Acceptance Gate
- Plugin can enqueue custom DrawCommands via vtable
- vtable version check works
- Example 3D raycasting plugin renders correctly

---

## Phase 5 — Embeddable Library Mode

### Goal
Allow `luna2d-core` to be used as a library by external frontends (Python, C#, Electron).

### Tasks

- [ ] **P5.1** Create C header (`luna2d.h`) via `cbindgen`
- [ ] **P5.2** Expose core init/step/render functions as `extern "C"`:
  ```rust
  #[no_mangle]
  pub extern "C" fn luna2d_init(config_path: *const c_char) -> *mut LunaContext;
  #[no_mangle]
  pub extern "C" fn luna2d_step(ctx: *mut LunaContext, dt: f32);
  #[no_mangle]
  pub extern "C" fn luna2d_render(ctx: *mut LunaContext);
  #[no_mangle]
  pub extern "C" fn luna2d_shutdown(ctx: *mut LunaContext);
  ```
- [ ] **P5.3** Build `luna2d-core` as both `rlib` and `cdylib`
- [ ] **P5.4** Create Python bindings via `PyO3` or ctypes wrapper
- [ ] **P5.5** Create example: Python script that embeds Luna2D for data visualization
- [ ] **P5.6** Create example: C# (Unity/Godot) embedding Luna2D as a scripting layer

### Acceptance Gate
- Python can `import luna2d`, call `luna2d.init()`, execute Lua script, get results
- C header is correct and compiles in a C project

---

## Phase 6 — Cross-Platform Plugins

### Goal
Ensure plugin loading works on all desktop platforms. See [cross-platform.md](cross-platform.md).

### Tasks

- [ ] **P6.1** macOS: test `.dylib` loading, code signing, `@rpath`/`@loader_path`
- [ ] **P6.2** Linux: test `.so` loading, `RUNPATH`, `LD_LIBRARY_PATH`
- [ ] **P6.3** CI: build plugins for all three platforms in GitHub Actions
- [ ] **P6.4** Cross-compilation: document building plugins for other platforms
- [ ] **P6.5** Update dist scripts for platform-specific plugin bundling

### Acceptance Gate
- Plugins load on Windows, macOS, and Linux
- CI produces plugin DLLs for all platforms
- Distribution archives include platform-correct plugin binaries

---

## Future Phases (Not Scheduled)

### Phase 7 — Plugin Hot-Reload
Unload and reload a plugin DLL without restarting the host. Requires:
- Tracking which `luna.*` functions a plugin registered
- Unregistering them before unload
- Reloading the new DLL and re-registering
- High complexity, deferred until demand exists

### Phase 8 — Plugin Marketplace
A registry (like crates.io) for Luna2D plugins:
- `luna plugin install tilemap-advanced`
- Downloads pre-built DLLs to `plugins/`
- Version pinning in `conf.toml`

### Phase 9 — WASM Plugin Sandbox
Run plugins in a WASM sandbox (wasmtime) for security:
- Plugin cannot crash the host
- Memory and CPU limits
- Full isolation from filesystem
- Significant performance overhead

### Phase 10 — Mobile Plugin Loading
iOS and Android dynamic library support:
- iOS: `dlopen` on jailbroken devices; App Store forbids code loading
- Android: `.so` loading via `dlopen` — feasible
- Would require relaxing design assumption A-02
