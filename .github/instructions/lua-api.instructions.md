---
applyTo: "src/lua_api/**"
---

# Lua API Instructions

All files in `src/lua_api/` bind Rust engine state to the `luna.*` Lua namespace. Every binding must use the `register()` pattern, named `pub fn` functions (NOT anonymous closures), and `@param`/`@return` docstring tags so `gen_lua_api.py` can extract them.

## Core Rules

- **`luna.*` namespace only** — never external engine prefixes, `game.*`, or any other prefix
- **Registration pattern**: every file must expose `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- **Named `pub fn` REQUIRED** — never use anonymous closures inline; extract to a named `pub fn` and pass it to `create_function(fn_name)` or `add_method("name", Self::fn_name)`
- **Clone the Rc before closure capture**: when a named fn needs state, use `let s = state.clone();` and reference `s` inside the fn — see pattern below
- **Return `LuaResult<T>`** from all Lua-callable functions — never panic inside a Lua closure
- **No rendering inside Lua closures** — push a `DrawCommand` variant to `state.borrow_mut().draw_commands` and return; the engine renders after `luna.draw()` returns
- **String keys lowercase**: `"space"`, `"escape"`, `"a"`, `"left"` — never uppercase, never platform-specific names

## CRITICAL: Named Function Pattern

All Lua-visible functions MUST be named `pub fn` items for docstring extraction.

### Module functions (table binding)

```rust
// ✅ CORRECT — named fn, fully indexed by gen_lua_api.py and collect_docs.py
/// Creates a new image from a file path.
///
/// # Parameters
/// - `path` — `string` Relative path to the image file.
///
/// # Returns
/// `Image` The loaded image handle.
///
/// @param path : string
/// @return Image
pub fn new_image(lua: &Lua, path: String) -> LuaResult<LuaImage> {
    // implementation here
    todo!()
}

pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;
    graphics.set("newImage", lua.create_function(new_image)?)?;  // ← fn reference
    luna.set("graphics", graphics)?;
    Ok(())
}
```

### Functions that need SharedState

```rust
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;
    // Capture state in a closure that wraps the named fn
    let s = state.clone();
    graphics.set("draw", lua.create_function(move |lua, args| {
        draw_impl(lua, args, &s)
    })?)?;
    luna.set("graphics", graphics)?;
    Ok(())
}

/// Queues a draw command for rendering.
///
/// # Parameters
/// - `drawable` — `Image|Canvas|SpriteBatch` Any drawable object.
/// - `x` — `number` X coordinate.
/// - `y` — `number` Y coordinate.
///
/// # Returns
/// `nil`
///
/// @param drawable : Image
/// @param x : number
/// @param y : number
/// @return nil
pub fn draw_impl(
    _lua: &Lua,
    (drawable, x, y): (LuaValue, f32, f32),
    state: &Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    todo!()
}
```

### UserData methods

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
}

impl UserData for LuaImage {
    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("getWidth", Self::get_width);   // ← Self::fn reference
    }
}
```

## Docstring Format for Lua API Functions

Every `pub fn` that is Lua-visible MUST have BOTH formats:

| Format | Used by | Section |
|---|---|---|
| `# Parameters` / `# Returns` (Rustdoc) | `collect_docs.py` validation | Above `@param`/`@return` |
| `@param name : Type` / `@return Type` | `gen_lua_api.py` extraction | Below `# Returns` |

Both sections are required. `collect_docs.py` fails if `# Parameters`/`# Returns` are missing.
`gen_lua_api.py` fails to emit the function if `@param`/`@return` tags are absent.

### Naming Convention (Rust → Lua)

Rust `snake_case` function names map to Lua `camelCase` string keys:

| Rust fn name        | Lua key string    |
|---|---|
| `new_image`         | `"newImage"`      |
| `get_width`         | `"getWidth"`      |
| `set_volume`        | `"setVolume"`      |
| `is_key_down`       | `"isDown"`        |
| `play`              | `"play"`          |

## Conditional Module Registration

`create_lua_vm()` in `src/lua_api/mod.rs` receives `modules: &ModulesConfig` as its second argument.
Three API files are **always** registered regardless of config: `math_api`, `log_api`, `event_api`.
All other 38 API files are guarded by their corresponding flag.

### Registration guard pattern

```rust
// Always registered (no guard)
math_api::register(&lua, &luna)?;
log_api::register(&lua, &luna)?;
event_api::register(&lua, &luna, state.clone())?;

// Guarded — disabled module means its luna.* table is absent (nil), not a stub
if modules.graphics {
    graphics_api::register(&lua, &luna, state.clone())?;
    font_api::register(&lua, &luna, state.clone())?;
    sprite_api::register(&lua, &luna)?;
}
if modules.audio    { audio_api::register(&lua, &luna, state.clone())?; }
if modules.input    { input_api::register(&lua, &luna, state.clone())?; }
if modules.physics  { physics_api::register(&lua, &luna)?; }
// ... one block per ModulesConfig flag
```

### API-to-flag mapping (all 41 API files)

| Flag | API files registered under this flag |
|---|---|
| always | math_api, log_api, event_api |
| `window` | window_api |
| `graphics` | graphics_api, font_api, sprite_api |
| `audio` | audio_api |
| `input` | input_api |
| `physics` | physics_api |
| `filesystem` | filesystem_api |
| `timer` | timer_api |
| `particle` | particle_api |
| `image` | image_api |
| `gui` | gui_api |
| `overlay` | overlay_api, postfx_api |
| `tilemap` | tilemap_api |
| `scene` | scene_api |
| `savegame` | savegame_api |
| `entity` | entity_api |
| `ai` | ai_api, steering_api |
| `pathfinding` | pathfinding_api |
| `thread` | thread_api |
| `graph` | graph_api |
| `data` | data_api, serial_api |
| `compute` | compute_api, dataframe_api |
| `minimap` | minimap_api |
| `modding` | modding_api |
| `pipeline` | pipeline_api, patterns_api |
| `system` | system_api |
| `localization` | localization_api |
| `debug` | debug_api, debugbridge_api, docs_api, automation_api |

See `engine.instructions.md` for dependency constraints (e.g. graphics → window).

## Layer / Boundary Rules

- `lua_api/mod.rs` owns `SharedState` struct definition and `create_lua_vm()` — no other file defines state
- Sub-API files (`graphics_api.rs`, `audio_api.rs`, etc.) must only import from `crate::graphics`, `crate::physics`, etc. — never cross-import between sub-API files
- Physics worlds stored separately from `SharedState` — use `Rc<RefCell<Vec<World>>>` passed alongside state

## Compliance

- Every new `luna.*` function MUST have `@param`/`@return` tags + `# Parameters`/`# Returns` rustdoc sections
- Every new `luna.*` function MUST be a named `pub fn`, not an anonymous closure
- Auto-generated reference: run `python tools/gen_lua_api.py` — validates `@param`/`@return` coverage
- Key names must match the mapping in `src/input/keyboard.rs::key_to_string()`
- All mouse button indices: 1 = left, 2 = right, 3 = middle
- Skeleton `src/lua_api/*_api.rs` files can be generated with `python tools/gen_lua_api_skeleton.py`

## Avoid

- Anonymous closures inline in `register()` — always extract to a named `pub fn`
- Missing `@param`/`@return` tags (breaks `gen_lua_api.py` extraction)
- Missing `# Parameters`/`# Returns` sections (breaks `collect_docs.py` validation)
- `.unwrap()` on `state.borrow()` — use `?` or handle the `BorrowError`
- Storing non-`Clone`/non-`'static` references in Lua closures
- Direct winit or wgpu API calls inside `lua_api/` — go through the engine abstraction
- Exposing internal engine types directly to Lua — wrap in safe userdata or return primitives
- Creating a new `Rc<RefCell<>>` for state that already exists in `SharedState`
