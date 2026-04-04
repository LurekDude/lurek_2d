# Love2D — Architectural Analysis

> **Source**: `references/love2D/` | **Language**: C++ | **Scripting**: Lua (LuaJIT) | **License**: zlib

## Overview

Love2D (LÖVE) is a free, open-source 2D game framework written in C++ with Lua scripting. It is the primary inspiration for Luna2D's API surface and developer experience. First released in 2008, it has powered notable games including Balatro, Gravity Circuit, and Move or Die. It targets desktop (Windows, Linux, macOS) and mobile (iOS, Android) platforms.

## Core Design Principles

1. **Simplicity-First API** — Every function is designed to be callable with minimal arguments. Sensible defaults everywhere. `love.graphics.rectangle("fill", 10, 10, 100, 50)` — no setup required.

2. **Callback-Driven Game Loop** — The engine invokes user-defined global functions (`love.load`, `love.update(dt)`, `love.draw`) in a predictable sequence. No class instantiation needed.

3. **Lua-Side Loop Ownership** — The game loop (`love.run()`) is implemented in Lua and returns a closure. Users can override it for custom frame timing, fixed-timestep, or headless operation.

4. **Module Singleton Pattern** — Each subsystem (graphics, audio, physics, etc.) is a C++ singleton registered as a Lua table field under `love.*`. Modules are independent and can be individually enabled/disabled.

5. **Flat Namespace** — All API calls live under `love.module.function()`. No deep nesting. No required OOP. Objects returned from factory functions have methods, but the primary API is procedural.

6. **Multi-Backend Rendering** — Graphics module abstracts over OpenGL, Vulkan, and Metal backends via a renderer selection layer. The user never interacts with the backend directly.

7. **Transform Stack** — Graphics state (color, transform, scissor) is managed via a push/pop stack. `love.graphics.push()` / `love.graphics.pop()` bracket transformations.

8. **Reference-Counted Objects** — All C++ objects exposed to Lua extend `Object` with `retain()/release()` reference counting, managed via `Proxy` userdata in Lua.

9. **Event Pump Architecture** — OS events flow through `love.event.pump()` → `love.event.poll()` → dispatch via `love.handlers` table lookup. Each event type has a named handler.

10. **Configuration via `conf.lua`** — Game settings (window size, modules to load, identity) declared in a separate `conf.lua` file, processed before the game starts.

11. **Filesystem Sandboxing** — `love.filesystem` provides a virtual filesystem with a writeable save directory per-game. No raw OS path access from Lua.

12. **Box2D Integration** — Physics is a first-class module wrapping Box2D. Physics objects (World, Body, Fixture, Shape, Joint) are created via `love.physics.*` factory functions.

13. **Embedded Lua Helpers** — Each module optionally embeds Lua code (e.g., `wrap_Graphics.lua`) compiled into the C++ binary, providing higher-level convenience functions.

14. **Cross-Platform Consistency** — Same API surface on all platforms. Platform-specific code is encapsulated behind SDL, OpenAL, and per-backend renderer implementations.

15. **Community Library Ecosystem** — Core engine is deliberately minimal. Advanced features (ECS, tilemaps, networking, animation) are provided by community Lua libraries (anim8, STI, bump.lua, etc.).

## Core Architecture

```
┌─────────────────────────────────────────────────────┐
│  User Game (main.lua + conf.lua)                     │
│  love.load() / love.update(dt) / love.draw()        │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│  love.run() — Lua-side game loop closure             │
│  event.pump → handlers dispatch → update → draw     │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│  Module Layer (C++ singletons)                       │
│  ┌──────────┬──────────┬──────────┬──────────┐      │
│  │ Graphics │  Audio   │ Physics  │  Window  │      │
│  │(OGL/Vk/  │ (OpenAL) │ (Box2D)  │  (SDL)   │      │
│  │  Metal)  │          │          │          │      │
│  ├──────────┼──────────┼──────────┼──────────┤      │
│  │Filesystem│  Input   │  Timer   │  Event   │      │
│  │(PhysFS)  │(Keyboard │(DeltaTime│ (Pump/   │      │
│  │          │Mouse/Joy)│  FPS)    │  Poll)   │      │
│  └──────────┴──────────┴──────────┴──────────┘      │
└──────────────┬──────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────┐
│  Common Layer                                        │
│  Module.h (base class) | Object.h (ref counting)    │
│  Variant.h (Lua↔C++ type bridge) | types.h (RTTI)   │
└─────────────────────────────────────────────────────┘
```

### Module Registration Pattern

```cpp
// Each module registers via luaopen_love_* function
extern "C" int luaopen_love_graphics(lua_State *L) {
    auto *graphics = Module::getInstance<Graphics>(Module::M_GRAPHICS);
    luax_register_type(L, &Graphics::type, functions);
    return 1;
}

// Functions registered as static luaL_Reg array
static const luaL_Reg functions[] = {
    { "draw", w_draw },
    { "clear", w_clear },
    { "print", w_print },
    { 0, 0 }
};
```

### Game Loop (Lua-side)

```lua
function love.run()
    if love.load then love.load(love.parsedGameArguments) end
    if love.timer then love.timer.step() end
    return function()
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then return a or 0 end
                love.handlers[name](a,b,c,d,e,f)
            end
        end
        local dt = love.timer and love.timer.step() or 0
        if love.update then love.update(dt) end
        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
            if love.draw then love.draw() end
            love.graphics.present()
        end
        if love.timer then love.timer.sleep(0.001) end
    end
end
```

## Focus & Target Audience

- **Indie game developers** and **game jam participants** (10th most popular on itch.io in 2018)
- **Beginners** learning game development — minimal boilerplate
- **Rapid prototyping** — code → run → iterate cycle is near-instant
- **2D games** exclusively — no 3D support in core (community 3D libraries exist)

## Strong Points

| Strength | Details |
|----------|---------|
| **API simplicity** | Smallest possible function signatures. No setup ceremony. One file = working game. |
| **Lua-overridable loop** | `love.run()` can be replaced entirely. Enables fixed timestep, headless mode, custom frame logic. |
| **Mature ecosystem** | 16+ years of development, massive community library catalog, extensive wiki documentation. |
| **Multi-backend rendering** | OpenGL, Vulkan, Metal — backend selection transparent to users. |
| **Proven in production** | Balatro (2024), Gravity Circuit (2023), Move or Die (2016) — commercially successful games. |
| **Self-contained distribution** | `.love` file (renamed .zip) contains entire game. Single executable + .love = portable. |
| **Excellent documentation** | Wiki with every function documented, examples, and community tutorials. |
| **Shader support** | GLSL-based custom shaders with simple API (`love.graphics.newShader`). |
| **Cross-platform** | Windows, macOS, Linux, iOS, Android from same codebase. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **No scene management** | No built-in scene/state machine. Every game reinvents it or uses a library. |
| **No built-in ECS** | No entity/component system. Object management is entirely manual. |
| **No UI framework** | No buttons, text inputs, or layout system. Community libraries fill the gap. |
| **Single-threaded rendering** | All rendering on main thread. `love.thread` exists but is limited. |
| **No built-in networking** | LuaSocket/enet available but not deeply integrated. No multiplayer framework. |
| **C++ codebase complexity** | Large C++ codebase with multiple backends makes contributing difficult. |
| **Mobile support is secondary** | Desktop-first design. Mobile builds require platform-specific setup. |
| **No hot reload** | Changes require restarting the game (vs. Solar2D's live builds). |
| **Reference counting overhead** | Manual retain/release for C++ objects creates GC pressure at Lua boundary. |

## Things to Reimplement in Luna2D

### High Priority — Already Aligned

1. **Callback model** (`luna.load`, `luna.update(dt)`, `luna.draw`) — Already implemented. This is Luna2D's foundation.

2. **Flat namespace** (`luna.graphics.rectangle()`, `luna.audio.play()`) — Already implemented. Keep this pattern for all new modules.

3. **Module singleton pattern** — Each module registers itself under `luna.*`. Luna2D's `register()` function per API file mirrors this.

4. **Configuration system** — Love2D's `conf.lua` is simple and effective. Luna2D should support a similar per-game configuration file.

5. **Filesystem sandboxing** — Love2D's per-game save directory with no raw path access is a good security model. Luna2D's `GameFS` follows this pattern.

### Medium Priority — Worth Adapting

6. **Transform stack** — `push()/pop()` for graphics state. Useful for camera transforms and nested rendering.

7. **Canvas/offscreen rendering** — `love.graphics.newCanvas()` for render-to-texture. Essential for post-processing.

8. **Shader API** — `love.graphics.newShader()` with user WGSL (Luna2D's equivalent of GLSL).

9. **`.love` file packaging** — Single-file game distribution. Luna2D could support `.luna` archives.

10. **Overridable game loop** — Allow `luna.run` to be defined in Lua for custom frame timing.

### Lower Priority — Nice to Have

11. **Thread module** — `love.thread` for background loading. Useful but complex in Rust.

12. **Video playback** — `love.video` for cutscenes. Niche feature.

## Things to Avoid

1. **C++ reference counting** — Rust's ownership model eliminates the need for manual retain/release. Use `Rc<RefCell<>>` or `Arc` where needed, but prefer ownership transfer.

2. **Lua-side game loop** — Love2D's `love.run()` in Lua is elegant but means the engine has less control over frame timing. Luna2D's Rust-side `ApplicationHandler` game loop with Lua callbacks is better for performance and safety.

3. **Multi-backend renderer abstraction** — Love2D maintains OpenGL, Vulkan, AND Metal backends simultaneously. This is massive maintenance burden. Luna2D uses wgpu, which already abstracts over all backends in one codebase.

4. **Box2D direct wrapping** — Love2D wraps Box2D's complex API (World, Body, Fixture, Shape, Joint). Luna2D's custom AABB physics is simpler for 2D games and avoids the C dependency.

5. **SDL dependency** — Love2D uses SDL for windowing/input. Luna2D uses winit, which is Rust-native and better integrated.

6. **Embedded Lua helpers in C++ strings** — Love2D embeds Lua code as C string constants. This is hard to maintain. Keep Lua code as separate files.

## Luna2D Integration Notes

Love2D is the **primary reference** for Luna2D's API design. The key differences are:

- **Language**: C++ → Rust (safer, no manual memory management)
- **Graphics**: OpenGL/Vulkan/Metal → wgpu (unified cross-platform GPU abstraction)
- **Windowing**: SDL → winit (Rust-native, ApplicationHandler pattern)
- **Audio**: OpenAL → rodio (Rust-native)
- **Physics**: Box2D → Custom AABB (simpler, no C dependency)
- **Loop ownership**: Lua → Rust (better performance control, Lua only has callbacks)

The fundamental philosophy — "Lua scripting + flat namespace + callback model + minimal boilerplate" — is **fully preserved** in Luna2D. Any new module added to Luna2D should follow Love2D's naming conventions and API ergonomics while leveraging Rust's type system and memory safety.
