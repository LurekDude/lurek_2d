# Plugin Architecture — Risk Assessment

## Risk Matrix

| ID | Risk | Likelihood | Impact | Severity | Mitigation |
|----|------|-----------|--------|----------|------------|
| R-01 | Rust ABI instability causes UB across DLL boundary | HIGH (certain if ignored) | CRITICAL | CRITICAL | Use Lua C API as sole boundary; never pass Rust types across DLLs |
| R-02 | LuaJIT symbol visibility on Windows | MEDIUM | HIGH | HIGH | Use `libloading` + explicit `luaopen_*` call instead of `package.cpath` |
| R-03 | Plugin crashes host process | HIGH | HIGH | HIGH | Plugins run in-process; crash = process crash. Validate inputs aggressively. Consider optional sandboxing in Phase 4 |
| R-04 | Plugin version mismatch silently corrupts state | MEDIUM | CRITICAL | HIGH | Mandatory `LUNA_PLUGIN_API_VERSION` check at load time; reject on mismatch |
| R-05 | Workspace refactor breaks 200+ existing tests | HIGH | MEDIUM | HIGH | Phase 1 is pure refactor — all tests must pass before proceeding. CI gate. |
| R-06 | Plugin cannot access SharedState for drawing | CERTAIN | MEDIUM | MEDIUM | Phase 2: plugins call `luna.gfx.*` via Lua; Phase 3: host vtable if needed |
| R-07 | Cross-platform DLL naming/loading differences | MEDIUM | LOW | LOW | Abstracted in `PluginLoader` with OS-specific filename mapping |
| R-08 | Binary size increases due to duplicated mlua | MEDIUM | LOW | LOW | Plugins use `mlua/module` (no vendored LuaJIT); symbols resolve from host |
| R-09 | Plugin load order affects luna.* namespace conflicts | LOW | MEDIUM | LOW | First-loaded wins; warn on namespace collision; document in conf.toml |
| R-10 | Debug workflow complexity increases | MEDIUM | MEDIUM | MEDIUM | Single-binary dev mode remains default; plugin split is deployment option |
| R-11 | Third-party plugins introduce security holes | MEDIUM | HIGH | HIGH | Lua sandbox still enforced; GameFS path guards active; document plugin trust model |
| R-12 | Performance overhead of Lua-mediated calls | LOW | LOW | LOW | Lua C API call overhead is <100ns per call; negligible vs per-frame budget |
| R-13 | Cargo workspace migration breaks `cargo test` workflow | MEDIUM | MEDIUM | MEDIUM | Keep existing test commands working via workspace-level Cargo.toml |
| R-14 | `Lua::init_from_ptr` safety in plugins | MEDIUM | HIGH | HIGH | Document contract: plugin must NOT call `lua.close()`; host owns lifetime |
| R-15 | Hot-reload of plugins during runtime | LOW | LOW | LOW | Not planned for Phase 1–3; design for it but don't implement |

---

## Critical Assumptions

### A1 — Lua C API Is Stable

**Assumption**: The `lua_State*` ABI (LuaJIT 2.1) will not change in ways that break
plugins compiled against it.

**Basis**: LuaJIT's C API has been stable since 2005. The API version in `luaconf.h` has
not changed. Mike Pall's design philosophy prioritizes binary compatibility.

**Risk if wrong**: Plugins would need recompilation if LuaJIT updates its `lua_State`
layout. Mitigation: pin LuaJIT version in `mlua-sys`.

### A2 — mlua `Lua::init_from_ptr` Is Sound

**Assumption**: `mlua 0.9` can safely wrap an externally-owned `lua_State*` via
`Lua::init_from_ptr(L)` without taking ownership of the state.

**Basis**: This is `mlua`'s documented API for the `module` feature. It's tested
upstream.

**Risk if wrong**: Double-free or use-after-free of the Lua state. Mitigation: the host
(not plugin) always creates and destroys the `lua_State`.

### A3 — Plugins Do Not Need Direct GPU Access (Phase 2)

**Assumption**: For the initial plugin system, calling `luna.gfx.drawQuad()`,
`luna.gfx.drawSprite()`, etc. via Lua is sufficient for plugin rendering.

**Basis**: Tier 2 modules already do this today — `tilemap_api.rs`, `scene_api.rs` etc.
build Lua tables and call back into `luna.gfx.*`.

**Risk if wrong**: Some advanced plugins (custom shaders, compute pipelines) may need
direct `wgpu` access. This is deferred to Phase 4 (C-ABI host vtable).

### A4 — Cargo Workspace Does Not Break Incremental Builds

**Assumption**: Splitting into a workspace with `luna2d-core`, `luna2d-bin`, and plugin
crates will not significantly worsen incremental build times.

**Basis**: Cargo workspaces share a `target/` (or in our case `build/`) directory and
dependency cache. Only changed crates recompile.

**Risk if wrong**: Developers experience slower iteration. Mitigation: measure build
times before/after split; keep the hot-path (core) as a single crate.

### A5 — conf.toml Plugin Section Is Sufficient

**Assumption**: A `[plugins]` section in `conf.toml` with a list of names and optional
per-plugin config is enough for plugin discovery.

**Basis**: This mirrors how game engines (Godot, Defold) handle plugin configuration.

**Risk if wrong**: Complex dependency graphs between plugins may need a manifest file.
Mitigation: defer plugin-to-plugin dependencies to Phase 4.

---

## Constraints Inherited from Design Assumptions

| Constraint | Source | Impact on Plugin Design |
|-----------|--------|------------------------|
| A-01: Runtime only — no editor | philosophy.md | Plugins don't need editor integration |
| A-02: Desktop only | philosophy.md | Plugins target Windows/macOS/Linux only (see cross-platform.md) |
| B-01: LuaJIT primary | philosophy.md | Plugins must target LuaJIT API; `lua54` feature may not be supported |
| B-02: wgpu 22 only | philosophy.md | No OpenGL plugin path; GPU plugins need wgpu if they want direct access |
| B-03: Integrated GPU target | philosophy.md | Plugin draw calls must not exceed per-frame budget |
| B-04: LuaJIT VMs don't share state | philosophy.md | Plugin init runs on the main VM; worker VMs don't load plugins |
| B-05: TOML config | philosophy.md | Plugin config is in `conf.toml`, not YAML or JSON |

---

## What Could Go Wrong: Worst-Case Scenarios

### Scenario 1 — Plugin Overwrites Core luna.* Function

A malicious or buggy plugin does `luna.math.lerp = my_bad_function`. This breaks all
existing code.

**Mitigation**: After plugin loading, the host can freeze core namespaces:
```lua
-- After all plugins loaded, before main.lua:
for _, key in ipairs(core_namespaces) do
    local mt = { __newindex = function() error("Cannot modify luna."..key) end }
    setmetatable(luna[key], mt)
end
```

### Scenario 2 — Plugin Leaks Memory

A plugin allocates Lua userdata or closures but never cleans up. Over time, memory
grows unbounded.

**Mitigation**: LuaJIT's garbage collector handles Lua-side allocations. For Rust-side
allocations in plugins, document that plugins must use `__gc` metamethods on userdata.

### Scenario 3 — Plugin Compiled with Wrong rustc Version

If a plugin DLL was compiled with `rustc 1.85` and the host with `rustc 1.82`, and they
share any Rust types, the result is UB.

**Mitigation**: They do NOT share Rust types. The boundary is `extern "C"` only (Lua C
API). The `LUNA_PLUGIN_RUSTC_VERSION` static is informational — the host logs it but
does not reject (since the ABI boundary is C, not Rust).

### Scenario 4 — Plugin Panics

A Rust panic in a plugin triggers stack unwinding. If this unwinds across the C/Lua
boundary (which is `extern "C"`), this is UB (unwinding through foreign frames).

**Mitigation**: Plugins must use `catch_unwind` at every `extern "C"` entry point:

```rust
#[no_mangle]
pub extern "C" fn luaopen_luna_gamedev(L: *mut lua_State) -> i32 {
    match std::panic::catch_unwind(|| unsafe { init(L) }) {
        Ok(result) => result,
        Err(_) => {
            // Log error, return 0 (no values pushed)
            0
        }
    }
}
```

---

## Decision Log

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| Lua C API as plugin boundary | Stable ABI, language-agnostic, proven | Rust-to-Rust FFI (ABI unstable), gRPC (too slow), WASM (too complex) |
| `libloading` for DLL loading | Cross-platform, well-maintained, minimal | `dlopen` directly (not cross-platform), `abi_stable` (too heavy for Phase 2) |
| Plugins register into existing `luna.*` | Transparent to game scripts | Separate namespace per plugin (breaks discoverability) |
| `conf.toml` for plugin list | Consistent with existing config | CLI args (less persistent), manifest.json (B-05 violation) |
| cdylib crate type | Standard Rust shared library | dylib (Rust-only, ABI unstable), staticlib (defeats purpose) |
