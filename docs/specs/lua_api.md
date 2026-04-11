# `lua_api` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Bridge Layer — above all module tiers |
| **Status** | Implemented — Full |
| **Lua API** | All `lurek.*` namespaces |
| **Source** | `src/lua_api/` |
| **Rust Tests** | `—` (tested via Lua BDD tests) |
| **Lua Tests** | `tests/lua/` (all Lua BDD tests exercise lua_api) |

## Summary

The `lua_api` module is the bridge between the Rust engine and Lua game scripts.
It creates and configures the Lua VM, registers all `lurek.*` API tables, and
provides `UserData` wrappers that connect Lua values to typed resource keys in
`SharedState`. Every public Lua-facing capability lives here as a thin
translation layer — business logic stays in the domain modules below.

`create_lua_vm(state)` is the single entry point: it opens the allowed standard
libraries, registers every API module (one per subsystem), and returns a
fully-configured `mlua::Lua` VM ready to execute game scripts. Each API module
follows the same registration contract — `pub fn register(lua, luna_table, state)`.

## Architecture

```
src/lua_api/
├── mod.rs            — create_lua_vm(), VM init, StdLib selection, global nulling
├── userdata.rs       — LunaType trait, shared UserData patterns
├── graphics_api/     — lurek.graphic.*
├── audio_api.rs      — lurek.audio.*
├── input_api.rs      — lurek.input.*, lurek.keyboard.*, lurek.mouse.*, lurek.gamepad.*
├── timer_api.rs      — lurek.time.*
├── math_api.rs       — lurek.math.*
├── physics_api.rs    — lurek.physics.*
├── filesystem_api.rs — lurek.fs.*
├── window_api.rs     — lurek.window.*
├── event_api.rs      — lurek.signal.*
├── system_api.rs     — lurek.platform.*
├── particle_api.rs   — lurek.particles.*
├── data_api.rs       — lurek.data.*
├── image_api.rs      — lurek.img.*
├── sound_api.rs      — lurek.sound.*
├── thread_api/       — lurek.thread.*
├── terminal_api.rs   — lurek.terminal.*
└── ...               — (all other subsystem API files)
```

## Registration Pattern

Every API module MUST follow this exact signature:

```rust
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()>
```

Inside the function, clone `Rc` before moving into each closure:

```rust
// ── funcName ──────────────────────────────────
/// One-sentence description.
/// @param name : type
/// @return type
let s = state.clone();
tbl.set("funcName", lua.create_function(move |_, arg: Type| {
    Ok(s.borrow().method(arg))
})?)?;
```

**Rules:**
- Flat body using `let s = state.clone(); tbl.set(...)` — NOT wrapped in `{ }` block expressions.
- Section headers: `// ── Section ──────────────────────`
- Docstring style: ONLY `/// @param name : type` and `/// @return type` for lua_api files — **never** `# Parameters` / `# Returns`.
- Gold standard file: `src/lua_api/timer_api.rs`.

## Lua VM Sandbox

### Standard Library Allowlist — Open Only These

| Library     | mlua flag           | Reason kept              |
|-------------|---------------------|--------------------------|
| `math`      | `StdLib::MATH`      | Deterministic, pure      |
| `string`    | `StdLib::STRING`    | String manipulation      |
| `table`     | `StdLib::TABLE`     | Data structures          |
| `coroutine` | `StdLib::COROUTINE` | Cooperative tasks        |
| `utf8`      | `StdLib::UTF8`      | Text encoding            |

### Standard Library Denylist — Never Open

- **`os`** — system commands, clock, environment variables, process control
- **`io`** — raw file I/O bypasses `GameFS` entirely
- **`debug`** — bypasses metatables; allows arbitrary upvalue mutation; can undo sandbox restrictions set via `__index`/`__newindex`
- **`package` / `require`** — loads arbitrary Lua files or C extensions from the filesystem

### Global Nulling After VM Init

After opening allowed libs, nil out dangerous globals:

```lua
-- Dangerous globals nulled after VM init
_G["dofile"] = nil
_G["loadfile"] = nil
_G["require"] = nil
_G["print"] = nil          -- replaced by lurek.log.print
_G["collectgarbage"] = nil -- timing oracle
```

- `rawget` / `rawset` bypass `__index`/`__newindex` — nil them if any sandboxing relies on metatables.

### Module Loading — No `require`

- Lurek2D does **not** support Lua module loading via `require`. `require` is nil'd after VM init.
- For multi-file scripts, provide `lurek.include(path)` via `GameFS` with the same path validation rules.

### GameFS Path Validation

Applied in `src/filesystem/vfs.rs` and enforced at the Lua boundary:

1. **Canonicalize** the joined path (`game_root + "/" + user_path`) before any I/O.
2. **Prefix check**: after canonicalization the result MUST start with `game_root`; reject otherwise.
3. **Null-byte rejection**: reject any path containing `\0` before joining — Rust `Path` silently truncates at null bytes on some platforms.
4. **Deny absolute paths**: reject any user-supplied path starting with `/`, `\`, or a drive letter (`C:`).

### Error Message Hygiene

- Catch Lua errors at the engine boundary (`engine/app.rs`).
- Strip Rust source paths (`src/...`) from error strings before displaying to the user.
- Expose only: script file name, Lua line number, and the error message itself.
- Never forward raw `LuaError::RuntimeError` with internal engine paths directly to game scripts.

## UserData Pattern

All major resource types are `mlua::UserData` objects:

```rust
pub struct LuaImage {
    pub key: TextureKey,
    pub width: u32,
    pub height: u32,
}

impl LuaUserData for LuaImage {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.width));
        methods.add_method("getHeight", |_, this, ()| Ok(this.height));
    }
}
```

**Rules:**
- `UserData` types hold only the resource key + cached metadata (width, height, etc.)
- Actual GPU resources live in `SharedState` keyed by `TextureKey`, `FontKey`, etc.
- Implement `LunaType` trait for `type()`, `typeOf()`, and `__tostring` metamethods.
- Use `lua.to_value()` / `lua.from_value()` for Lua↔Rust table conversions; avoid manual field iteration.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | VM creation, StdLib selection, global nulling, module registration |
| `userdata.rs` | `LunaType` trait, shared UserData patterns |
| `graphics_api/` | `lurek.graphic.*` — drawing, images, fonts, canvases, shaders |
| `audio_api.rs` | `lurek.audio.*` — sources, playback, volume, buses |
| `input_api.rs` | `lurek.input.*`, `lurek.keyboard.*`, `lurek.mouse.*`, `lurek.gamepad.*`, `lurek.touch.*` |
| `timer_api.rs` | `lurek.time.*` — delta time, FPS, sleep (Gold standard for docstring format) |
| `math_api.rs` | `lurek.math.*` — trig, random, noise, transforms, Bezier |
| `physics_api.rs` | `lurek.physics.*` — worlds, bodies, joints, raycasting |
| `filesystem_api.rs` | `lurek.fs.*` — sandboxed I/O, file handles, archives |
| `window_api.rs` | `lurek.window.*` — fullscreen, VSync, display info, clipboard |
| `event_api.rs` | `lurek.signal.*` — event queue, quit |
| `system_api.rs` | `lurek.platform.*` — OS info, openURL, locales |
| `particle_api.rs` | `lurek.particles.*` — emitters, config, rendering |
| `data_api.rs` | `lurek.data.*` — binary data, compression, hashing, encoding |
| `image_api.rs` | `lurek.img.*` — CPU pixel buffers, pixel manipulation |
| `sound_api.rs` | `lurek.sound.*` — decoded PCM audio samples |
| `thread_api/` | `lurek.thread.*` — worker threads, channels |
| `terminal_api.rs` | `lurek.terminal.*` — in-game developer terminal |

## Key Design Invariants

1. **All bindings under `lurek.*`** — never external engine prefixes, never bare globals.
2. **Sensible defaults** — never require parameters a beginner would always pass as the same value.
3. **Every callback is optional** — check existence before calling, never error on missing callbacks.
4. **Synchronous from Lua's perspective** — async work happens in Rust threads via `Channel`.
5. **Validate at the boundary** — return descriptive `LuaError` messages, never panic on bad Lua input.
6. **Error propagation** — use `?` throughout; convert at the Lua boundary with `.map_err(LuaError::external)`.
7. **Domain modules never import lua_api** — `lua_api` is the integration endpoint, not a shared utility.

## References

| Module     | Relationship  | Notes                                                        |
|------------|---------------|--------------------------------------------------------------|
| `engine`   | Imports from  | `SharedState`, all resource keys                            |
| `math`     | Imports from  | Pure types used across all API modules                      |
| All Tier 1 | Imports from  | Domain logic stays in domain modules; lua_api is thin wrapper |
| All Tier 2 | Imports from  | Same pattern — lua_api bridges but doesn't own logic         |
