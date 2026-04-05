---
name: lua-api-design
description: "Load this skill when designing or modifying the luna.* Lua API surface. It owns naming conventions, parameter patterns, callback contracts, and API consistency rules. Skip it for Rust internals or pure Lua scripting."
---

# Lua API Design — Luna2D Engine

## Load When

- Adding a new `luna.*` function
- Changing an existing API signature
- Designing callback conventions
- Reviewing API consistency across modules
- Creating or updating `src/lua_api/*_api.rs` files

## Owns

- `luna.*` namespace structure and naming conventions
- Function parameter order and type conventions
- Callback registration patterns
- API consistency across modules (graphics, audio, physics, etc.)
- Docstring format for Lua-visible functions (`@param`/`@return` tags)

## Does Not Cover

- Rust implementation of bindings → use `rust-coding` skill
- Writing Lua game scripts → use `lua-scripting` skill
- Performance of Lua/Rust boundary → use `performance-profiling` skill

## Live Repository Contracts

- `src/lua_api/mod.rs` — `create_lua_vm()`, SharedState, all module registrations
- `src/lua_api/*_api.rs` — per-module Lua bindings using named `pub fn` pattern
- `docs/API/lua_api_reference_generated.md` — auto-generated from `src/lua_api/`
- `tools/gen_lua_api.py` — scanner that extracts `pub fn` + `@param`/`@return` docstrings
- `tools/gen_lua_api_skeleton.py` — generates `src/lua_api/*_api.rs` skeletons from Rust docstrings

## Decision Rules

- **Namespace**: All functions under `luna.*` — NEVER external engine prefixes or any other prefix
- **Module pattern**: `luna.<module>.<function>()` (e.g., `luna.graphics.draw()`)
- **Registration**: Every API file exports `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- **Parameter conventions**: `dt` for delta time, `x, y` for coordinates, `key` for key names, `btn` for buttons
- **Key names**: Lowercase strings: `"space"`, `"escape"`, `"a"`, `"left"`, `"return"`
- **Return types**: `LuaResult<T>` for all Lua-callable functions
- **Error messages**: Descriptive, mention the function name and what went wrong
- **Callbacks**: `luna.load()`, `luna.update(dt)`, `luna.draw()`, `luna.keypressed(key)`, etc.
- **Consistency**: Similar functions across modules use the same parameter patterns
- **Documentation**: Every new function must have `@param`/`@return` docstring tags; auto-docs generated from these

## CRITICAL: Named Function Pattern (docstring-friendly)

All `src/lua_api/*_api.rs` files MUST use **named `pub fn`** instead of anonymous closures.
This is required so `collect_docs.py` and `gen_lua_api.py` can scan and index the API.

### Module-level functions (`luna.module.func()`)

**WRONG — anonymous closure, invisible to doc tools:**
```rust
luna.set("newImage", lua.create_function(move |lua, path: String| {
    // rustdoc cannot index this closure
    todo!()
})?)?;
```

**CORRECT — named fn, fully indexable:**
```rust
/// Creates a new image from the given path.
///
/// # Parameters
/// - `path` — `string` Path to the image file.
///
/// # Returns
/// `Image` The loaded image handle.
///
/// @param path : string
/// @return Image
pub fn new_image(_lua: &Lua, path: String) -> LuaResult<LuaImage> {
    todo!()
}

// In register():
luna.set("newImage", lua.create_function(new_image)?)?;
```

### UserData instance methods (`img:getWidth()`)

**CORRECT — named method referenced via `Self::fn`, fully indexable:**
```rust
pub struct LuaImage(TextureKey, Rc<RefCell<SharedState>>);

impl LuaImage {
    /// Returns the width of this image in pixels.
    ///
    /// # Returns
    /// `integer` Width in pixels.
    ///
    /// @return integer
    pub fn get_width(&self, _lua: &Lua, _: ()) -> LuaResult<u32> {
        todo!()
    }

    /// Releases the image and frees GPU memory.
    ///
    /// @return nil
    pub fn release(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaImage {
    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("getWidth", Self::get_width);   // ← direct fn reference
        methods.add_method("release", Self::release);
    }
}
```

## Docstring Format for Lua API Functions

Every `pub fn` in `src/lua_api/` that is Lua-visible MUST have:

1. **Rustdoc summary** — first `///` line, one sentence
2. **`# Parameters` section** — Rustdoc format (for `collect_docs.py`)
3. **`# Returns` section** — Rustdoc format (for `collect_docs.py`)
4. **`@param name : Type` tags** — one per parameter (for `gen_lua_api.py`)
5. **`@return Type` tag** — return type (for `gen_lua_api.py`)

```rust
/// Creates a sound source from a file.
///
/// Supports WAV, OGG, MP3, and FLAC. Use `"static"` for short SFX,
/// `"stream"` for music tracks.
///
/// # Parameters
/// - `path` — `string` Relative path to the audio file.
/// - `source_type` — `string` Either `"static"` or `"stream"`.
///
/// # Returns
/// `Source` An audio source handle.
///
/// @param path : string
/// @param source_type : string
/// @return Source
pub fn new_source(_lua: &Lua, (path, source_type): (String, String)) -> LuaResult<LuaSource> {
    todo!()
}
```

### Naming Convention (Rust → Lua)

| Rust function name  | Lua function name |
|---|---|
| `new_image`         | `"newImage"` |
| `get_width`         | `"getWidth"` |
| `draw_rectangle`    | `"rectangle"` (drop prefix for verbs) |
| `set_volume`        | `"setVolume"` |
| `is_down`           | `"isDown"` |

Rule: Rust `snake_case` → Lua `camelCase`. Exception: noun constructors use `new` prefix.

## Tool Integration

- `tools/gen_lua_api.py` scans `src/lua_api/**/*.rs` for:
  - `pub fn fn_name(` with `/// @param`/`/// @return` tags above it
  - `luna.set("luaName", lua.create_function(fn_name)?)` to map Rust fn to Lua name
  - `methods.add_method("luaName", Self::fn_name)` to map method names
- `tools/gen_lua_api_skeleton.py` auto-generates `src/lua_api/*_api.rs` from:
  - `src/<module>/*.rs` public types and functions with `# Parameters`/`# Returns` docs
  - Translates Rustdoc format into `@param`/`@return` tags in the skeleton
- `tools/collect_docs.py` validates docstring coverage for `pub fn` items in `src/lua_api/`
