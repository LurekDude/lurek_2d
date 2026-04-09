# Plugin Architecture — Step-by-Step Implementation Guide

## Prerequisites

Before starting, ensure:
- Rust stable ≥1.78 installed
- All tests pass: `cargo test`
- All clippy clean: `cargo clippy -- -D warnings`
- Working branch created: `git checkout -b feat/plugin-architecture`
- Current binary size noted for comparison

---

## Step 1 — Create Workspace Structure

### 1.1 Create Directory Skeleton

```powershell
mkdir crates
mkdir crates\lurek2d-plugin-api\src
mkdir crates\lurek2d-core\src
mkdir crates\lurek2d-gamedev\src
mkdir crates\lurek2d-bin\src
```

### 1.2 Create Plugin API Crate

This is the smallest possible crate — interface types only.

**File: `crates/lurek2d-plugin-api/Cargo.toml`**
```toml
[package]
name = "lurek2d-plugin-api"
version = "0.1.0"
edition = "2021"
description = "Plugin interface types for Lurek2D"

# No dependencies — this crate is pure types
```

**File: `crates/lurek2d-plugin-api/src/lib.rs`**
```rust
//! Plugin interface types for Lurek2D.
//!
//! This crate defines the contract between the Lurek2D host and plugin DLLs.
//! It has zero dependencies and uses only `#[repr(C)]` types.

use std::ffi::c_char;

/// Current plugin API version. Bump this on any breaking change to the
/// plugin loading contract.
pub const API_VERSION: u32 = 1;

/// Metadata embedded in every plugin DLL via a `#[no_mangle]` static.
#[repr(C)]
pub struct PluginDeclaration {
    /// Must equal `API_VERSION` at load time.
    pub api_version: u32,
    /// Null-terminated plugin name (e.g. "gamedev").
    pub name: *const c_char,
    /// Null-terminated semantic version (e.g. "0.1.0").
    pub version: *const c_char,
}

// Safety: PluginDeclaration contains only raw pointers to static strings.
unsafe impl Send for PluginDeclaration {}
unsafe impl Sync for PluginDeclaration {}

/// Type signature of the plugin entry point.
/// The host calls this with its own `lua_State*`.
pub type PluginEntryFn = unsafe extern "C" fn(L: *mut std::ffi::c_void) -> i32;
```

### 1.3 Verify

```powershell
cd crates\lurek2d-plugin-api
cargo check
cd ..\..
```

---

## Step 2 — Add Plugin Configuration to Config

### 2.1 Update `src/engine/config.rs`

Add after `ModulesConfig`:

```rust
/// Configuration for the plugin loading system.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginsConfig {
    /// Ordered list of plugin names to load at startup.
    /// Each name maps to a platform-specific file:
    ///   "gamedev" → luna_gamedev.dll (Win) / libluna_gamedev.so (Linux)
    #[serde(default)]
    pub load: Vec<String>,

    /// Additional directories to search for plugin files.
    /// Searched after the default `plugins/` directory.
    #[serde(default)]
    pub search_paths: Vec<String>,
}

impl Default for PluginsConfig {
    fn default() -> Self {
        Self {
            load: Vec::new(),
            search_paths: Vec::new(),
        }
    }
}
```

Add to `Config` struct:
```rust
pub struct Config {
    // ... existing fields ...
    pub plugins: PluginsConfig,
}
```

### 2.2 Verify

```powershell
cargo check
cargo test --test config_tests
```

---

## Step 3 — Implement Plugin Loader (in lurek2d-core)

### 3.1 Create `src/engine/plugin_loader.rs`

```rust
//! Runtime plugin discovery and loading.

use std::path::{Path, PathBuf};
use std::ffi::CStr;

use log::{info, warn, error};

use crate::engine::config::PluginsConfig;

/// Information about a discovered plugin file.
#[derive(Debug, Clone)]
pub struct PluginInfo {
    /// Human-readable name (e.g. "gamedev").
    pub name: String,
    /// Absolute path to the DLL/so/dylib file.
    pub path: PathBuf,
}

/// Error types for plugin operations.
#[derive(Debug)]
pub enum PluginError {
    /// DLL file not found in any search path.
    NotFound(String),
    /// Failed to load the DLL.
    LoadFailed(String, String),
    /// Missing required symbol in the DLL.
    MissingSymbol(String, String),
    /// Plugin API version does not match host.
    VersionMismatch { plugin: String, expected: u32, got: u32 },
    /// Plugin init function returned an error.
    InitFailed(String, String),
}

impl std::fmt::Display for PluginError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotFound(name) => write!(f, "plugin '{}' not found", name),
            Self::LoadFailed(name, err) => write!(f, "failed to load '{}': {}", name, err),
            Self::MissingSymbol(name, sym) => write!(f, "plugin '{}' missing symbol '{}'", name, sym),
            Self::VersionMismatch { plugin, expected, got } =>
                write!(f, "plugin '{}' API version mismatch: expected {}, got {}", plugin, expected, got),
            Self::InitFailed(name, err) => write!(f, "plugin '{}' init failed: {}", name, err),
        }
    }
}

impl std::error::Error for PluginError {}

/// Manages the lifecycle of dynamically-loaded plugins.
pub struct PluginLoader {
    /// Loaded libraries — kept alive for the duration of the program.
    /// Dropping a Library unloads the DLL.
    loaded: Vec<(String, libloading::Library)>,
}

impl PluginLoader {
    /// Creates an empty plugin loader.
    pub fn new() -> Self {
        Self { loaded: Vec::new() }
    }

    /// Discovers plugin files based on configuration.
    /// Returns a list of (name, path) pairs for plugins that exist on disk.
    pub fn discover(config: &PluginsConfig, exe_dir: &Path) -> Vec<PluginInfo> {
        let mut search_paths = vec![
            exe_dir.join("plugins"),
        ];
        for extra in &config.search_paths {
            search_paths.push(PathBuf::from(extra));
        }

        let mut found = Vec::new();
        for name in &config.load {
            let filename = platform_filename(name);
            let mut resolved = false;
            for dir in &search_paths {
                let path = dir.join(&filename);
                if path.exists() {
                    info!("Discovered plugin '{}' at {}", name, path.display());
                    found.push(PluginInfo {
                        name: name.clone(),
                        path,
                    });
                    resolved = true;
                    break;
                }
            }
            if !resolved {
                warn!("Plugin '{}' not found in search paths: {:?}", name, search_paths);
            }
        }
        found
    }

    /// Loads a single plugin and calls its entry point with the given lua_State*.
    ///
    /// # Safety
    /// `lua_state` must be a valid, non-null pointer to an active lua_State.
    pub unsafe fn load(
        &mut self,
        info: &PluginInfo,
        lua_state: *mut std::ffi::c_void,
    ) -> Result<(), PluginError> {
        // Load the shared library
        let lib = unsafe {
            libloading::Library::new(&info.path)
                .map_err(|e| PluginError::LoadFailed(info.name.clone(), e.to_string()))?
        };

        // Check API version
        let version_sym: libloading::Symbol<*const u32> = unsafe {
            lib.get(b"LUNA_PLUGIN_API_VERSION")
                .map_err(|_| PluginError::MissingSymbol(
                    info.name.clone(),
                    "LUNA_PLUGIN_API_VERSION".into(),
                ))?
        };
        let plugin_version = unsafe { **version_sym };
        if plugin_version != luna2d_plugin_api::API_VERSION {
            return Err(PluginError::VersionMismatch {
                plugin: info.name.clone(),
                expected: luna2d_plugin_api::API_VERSION,
                got: plugin_version,
            });
        }

        // Find the entry point: luaopen_luna_<name>
        let entry_symbol = format!("luaopen_luna_{}", info.name);
        let entry_fn: libloading::Symbol<luna2d_plugin_api::PluginEntryFn> = unsafe {
            lib.get(entry_symbol.as_bytes())
                .map_err(|_| PluginError::MissingSymbol(
                    info.name.clone(),
                    entry_symbol.clone(),
                ))?
        };

        // Call the entry point with the host's lua_State*
        info!("Loading plugin '{}'...", info.name);
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            unsafe { entry_fn(lua_state) }
        }));

        match result {
            Ok(0) => {
                info!("Plugin '{}' loaded successfully", info.name);
                self.loaded.push((info.name.clone(), lib));
                Ok(())
            }
            Ok(code) => Err(PluginError::InitFailed(
                info.name.clone(),
                format!("returned error code {}", code),
            )),
            Err(_) => Err(PluginError::InitFailed(
                info.name.clone(),
                "panicked during initialization".into(),
            )),
        }
    }

    /// Loads all discovered plugins. Returns errors for any that failed.
    pub unsafe fn load_all(
        &mut self,
        plugins: &[PluginInfo],
        lua_state: *mut std::ffi::c_void,
    ) -> Vec<PluginError> {
        let mut errors = Vec::new();
        for info in plugins {
            if let Err(e) = unsafe { self.load(info, lua_state) } {
                error!("Plugin load error: {}", e);
                errors.push(e);
            }
        }
        errors
    }

    /// Returns the number of successfully loaded plugins.
    pub fn loaded_count(&self) -> usize {
        self.loaded.len()
    }

    /// Returns the names of loaded plugins.
    pub fn loaded_names(&self) -> Vec<&str> {
        self.loaded.iter().map(|(name, _)| name.as_str()).collect()
    }
}

/// Maps a plugin name to the platform-specific filename.
fn platform_filename(name: &str) -> String {
    #[cfg(target_os = "windows")]
    { format!("luna_{name}.dll") }
    #[cfg(target_os = "macos")]
    { format!("libluna_{name}.dylib") }
    #[cfg(target_os = "linux")]
    { format!("libluna_{name}.so") }
    #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
    { format!("libluna_{name}.so") }  // Fallback for other Unix
}
```

### 3.2 Register Module

In `src/engine/mod.rs`:
```rust
pub mod plugin_loader;
```

### 3.3 Add Dependency

In `Cargo.toml`:
```toml
[dependencies]
libloading = "0.8"
lurek2d-plugin-api = { path = "crates/lurek2d-plugin-api" }
```

### 3.4 Verify

```powershell
cargo check
```

---

## Step 4 — Integrate Plugin Loading into Boot Sequence

### 4.1 Update `src/engine/app.rs`

After `create_lua_vm()` returns, add plugin loading:

```rust
// After creating the Lua VM:
let lua_state_ptr = lua.as_raw_state() as *mut std::ffi::c_void;

// Plugin loading
let mut plugin_loader = PluginLoader::new();
let exe_dir = std::env::current_exe()
    .ok()
    .and_then(|p| p.parent().map(|d| d.to_path_buf()))
    .unwrap_or_else(|| PathBuf::from("."));

let discovered = PluginLoader::discover(&config.plugins, &exe_dir);
if !discovered.is_empty() {
    info!("Discovered {} plugin(s), loading...", discovered.len());
    let errors = unsafe { plugin_loader.load_all(&discovered, lua_state_ptr) };
    for err in &errors {
        warn!("Plugin error: {}", err);
    }
    info!("{} plugin(s) loaded successfully", plugin_loader.loaded_count());
}

// Store plugin_loader in App so libraries stay alive
// (dropping the loader unloads the DLLs)
```

### 4.2 Verify

```powershell
cargo test
cargo run -- demos/hello_world  # Should work identically (no plugins configured)
```

---

## Step 5 — Create First Plugin (lurek2d-gamedev)

### 5.1 Create Crate

**File: `crates/lurek2d-gamedev/Cargo.toml`**
```toml
[package]
name = "lurek2d-gamedev"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
mlua = { version = "0.9", features = ["luajit", "vendored", "module"] }
lurek2d-plugin-api = { path = "../lurek2d-plugin-api" }
```

**File: `crates/lurek2d-gamedev/src/lib.rs`**
```rust
//! Lurek2D Game Development Plugin.
//!
//! Provides Tier 2 game-specific modules: tilemap, scene, ai, particles, etc.

use mlua::prelude::*;

/// Plugin API version — must match the host's version.
#[no_mangle]
pub static LUNA_PLUGIN_API_VERSION: u32 = luna2d_plugin_api::API_VERSION;

/// Entry point called by the Lurek2D host.
///
/// # Safety
/// `L` must be a valid, non-null pointer to an active `lua_State` owned by the host.
#[no_mangle]
pub unsafe extern "C" fn luaopen_luna_gamedev(L: *mut std::ffi::c_void) -> i32 {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        let lua = unsafe { Lua::init_from_ptr(L as *mut _) };
        register_all(&lua)
    })) {
        Ok(Ok(())) => 0,   // Success
        Ok(Err(e)) => {
            eprintln!("[luna_gamedev] registration error: {e}");
            1
        }
        Err(_) => {
            eprintln!("[luna_gamedev] panic during initialization");
            2
        }
    }
}

fn register_all(lua: &Lua) -> LuaResult<()> {
    let globals = lua.globals();
    let luna: LuaTable = globals.get("lurek")?;

    // Register each module into the existing lurek.* namespace
    // Start with one module as a proof of concept:
    register_hello(lua, &luna)?;

    Ok(())
}

/// Proof-of-concept: registers lurek.plugin_test namespace
fn register_hello(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    tbl.set("greet", lua.create_function(|_, name: String| {
        Ok(format!("Hello from luna_gamedev plugin, {}!", name))
    })?)?;

    tbl.set("version", lua.create_function(|_, ()| {
        Ok(env!("CARGO_PKG_VERSION"))
    })?)?;

    lurek.set("plugin_test", tbl)?;
    Ok(())
}
```

### 5.2 Build Plugin

```powershell
cargo build -p lurek2d-gamedev
# Output: build/debug/luna_gamedev.dll (Windows)
```

### 5.3 Test Plugin Loading

```powershell
# Copy DLL to plugins folder
mkdir plugins
copy build\debug\luna_gamedev.dll plugins\

# Create test conf.toml with plugins section
# Or add to existing conf.toml:
# [plugins]
# load = ["gamedev"]

# Run with plugin
cargo run -- demos/hello_world
# Should see: "Discovered 1 plugin(s), loading..."
# Should see: "Plugin 'gamedev' loaded successfully"
```

---

## Step 6 — Move Tier 2 Modules to Plugin

This is the most labor-intensive step. Do one module at a time.

### 6.1 Process for Each Module

Taking `tilemap` as an example:

1. **Copy `src/tilemap/` → `crates/lurek2d-gamedev/src/tilemap/`**
2. **Copy `src/lua_api/tilemap_api.rs` → `crates/lurek2d-gamedev/src/tilemap_api.rs`**
3. **Update imports**:
   - Replace `use crate::engine::SharedState` → remove; use Lua-only surface
   - Replace `use crate::math::*` → `use luna2d_core::math::*` (if core is a dep)
     OR re-implement needed math types locally
4. **Refactor SharedState access**:
   - `state.borrow().delta_time` → call `lurek.time.getDelta()` via Lua
   - `state.borrow_mut().draw_commands.push(...)` → call `lurek.gfx.drawQuad()` via Lua
5. **Register in `register_all()`**:
   ```rust
   tilemap::register(lua, &luna)?;
   ```
6. **Remove from `src/lua_api/mod.rs`**: delete the `tilemap_api::register(...)` line
7. **Remove from `src/`**: delete `src/tilemap/` (it now lives in the plugin)
8. **Test**:
   ```powershell
   cargo build -p lurek2d-gamedev
   copy build\debug\luna_gamedev.dll plugins\
   cargo run -- demos/tilemap_demo  # Must work identically
   ```

### 6.2 Module Migration Order

Migrate in order of independence (least SharedState coupling first):

1. **ai** — pure logic, no rendering → trivial
2. **pathfinding** — pure logic → trivial
3. **graph** — pure data structure → trivial
4. **pipeline** — DAG orchestration → trivial
5. **patterns** — design pattern helpers → trivial
6. **scene** — mostly Lua-side lifecycle → medium
7. **tilemap** — grid data (independent) + draw calls → medium
8. **terminal** — character grid + draw calls → medium
9. **minimap** — draws to sub-region → medium
10. **particle** — frame-dependent, draw commands → hard
11. **gui** — input + draw commands → hard
12. **fx/overlay** — post-processing → hard (needs render pipeline access)
13. **procgen** — depends on math → medium
14. **raycaster** — draw commands → medium
15. **spine** — animation data + draw → medium

### 6.3 The SharedState Decoupling Pattern

For modules that currently use `SharedState`, replace direct access with Lua calls:

**Before** (in core):
```rust
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let s = state.clone();
    tbl.set("update", lua.create_function(move |_, ()| {
        let dt = s.borrow().delta_time;
        let mut s = s.borrow_mut();
        s.draw_commands.push(DrawCommand::Rect { ... });
        Ok(())
    })?)?;
}
```

**After** (in plugin):
```rust
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    tbl.set("update", lua.create_function(|lua, ()| {
        // Read state via Lua API
        let luna: LuaTable = lua.globals().get("lurek")?;
        let time: LuaTable = lurek.get("time")?;
        let dt: f64 = time.call_method("getDelta", ())?;

        // Draw via Lua API
        let gfx: LuaTable = lurek.get("gfx")?;
        gfx.call_method("drawRect", (x, y, w, h, color))?;

        Ok(())
    })?)?;
}
```

---

## Step 7 — Convert to Workspace (Full)

Once plugin loading works with a few modules, convert the entire repo to a workspace.

### 7.1 Root `Cargo.toml`

```toml
[workspace]
members = [
    "crates/lurek2d-core",
    "crates/lurek2d-plugin-api",
    "crates/lurek2d-gamedev",
    "crates/lurek2d-bin",
]
resolver = "2"

[workspace.dependencies]
mlua = { version = "0.9", default-features = false }
wgpu = "22"
winit = "0.30"
rapier2d = "0.32"
rodio = "0.17"
fontdue = "0.9"
log = "0.4"
env_logger = "0.11"
serde = { version = "1", features = ["derive"] }
toml = "0.8"
image = "0.25"
libloading = "0.8"
lurek2d-plugin-api = { path = "crates/lurek2d-plugin-api" }
```

### 7.2 Move src/ → crates/lurek2d-core/src/

```powershell
# Move all source except main.rs and bin/
xcopy /E /I src crates\lurek2d-core\src
# Remove Tier 2 modules that went to lurek2d-gamedev
rmdir /S /Q crates\lurek2d-core\src\tilemap
rmdir /S /Q crates\lurek2d-core\src\scene
# ... etc
```

### 7.3 Create lurek2d-bin

```powershell
# src/main.rs → crates/lurek2d-bin/src/main.rs
move src\main.rs crates\lurek2d-bin\src\main.rs
```

### 7.4 Fix All Imports

This is the most tedious step. Use a script to automate:

```powershell
# Auto-replace crate:: with luna2d_core:: in gamedev plugin files
Get-ChildItem -Recurse crates\lurek2d-gamedev\src\*.rs | ForEach-Object {
    (Get-Content $_.FullName) -replace 'use crate::engine::', 'use luna2d_core::engine::' |
    Set-Content $_.FullName
}
```

### 7.5 Verify

```powershell
cargo check --workspace
cargo test --workspace
cargo clippy --workspace -- -D warnings
```

---

## Step 8 — Update CI/CD and Distribution

### 8.1 GitHub Actions

Update the CI workflow to build all workspace members:

```yaml
- name: Build all crates
  run: cargo build --workspace --release

- name: Test all crates
  run: cargo test --workspace

- name: Package plugins
  run: |
    mkdir -p dist/plugins
    cp build/release/luna_gamedev.dll dist/plugins/  # Windows
    # cp build/release/libluna_gamedev.so dist/plugins/  # Linux
```

### 8.2 Distribution Scripts

Update `tools/dist/dist.ps1`:
```powershell
# Build main binary
cargo build -p lurek2d-bin --release

# Build plugins
cargo build -p lurek2d-gamedev --release

# Copy to dist folder
Copy-Item build\release\lurek2d.exe dist\
Copy-Item build\release\luna_gamedev.dll dist\plugins\
```

### 8.3 NSIS Installer

Add plugin installation section to `tools/dist/installer.nsi`:
```nsi
Section "Game Development Plugin" SEC_GAMEDEV
    SetOutPath "$INSTDIR\plugins"
    File "dist\plugins\luna_gamedev.dll"
SectionEnd
```

---

## Step 9 — Documentation and Examples

### 9.1 Plugin Author Guide

Create `docs/architecture/plugin-guide.md`:
- How plugins work
- How to create a plugin
- How to test a plugin
- How to distribute a plugin

### 9.2 Example Plugin

Create `examples/plugin_hello/`:
- Minimal plugin that adds `lurek.hello.greet(name)`
- Shows the complete workflow from creation to loading

### 9.3 Update Existing Docs

- `docs/architecture/engine-architecture.md` — add plugin loading layer
- `docs/CHANGELOG.md` — new version entry
- `README.md` — mention plugin support
- All `src/<module>/AGENT.md` — update crate paths

---

## Verification Checklist

After all steps are complete:

- [ ] `cargo check --workspace` — no errors
- [ ] `cargo test --workspace` — all tests pass (same count as pre-split)
- [ ] `cargo clippy --workspace -- -D warnings` — clean
- [ ] `cargo build --release -p lurek2d-bin` — produces `lurek2d.exe`
- [ ] `cargo build --release -p lurek2d-gamedev` — produces `luna_gamedev.dll`
- [ ] Binary size of `lurek2d.exe` < pre-split binary size
- [ ] `luna_gamedev.dll` size < 5 MB
- [ ] All demos work with plugin loading enabled
- [ ] All demos work with `conf.toml` plugins = [] (no plugins — core only)
- [ ] Plugin version mismatch is rejected with a clear error
- [ ] Missing plugin DLL produces a warning, not a crash
- [ ] `docs/CHANGELOG.md` updated
- [ ] `docs/architecture/engine-architecture.md` updated
- [ ] All affected `AGENT.md` files updated
