# Gideros — Architectural Analysis

> **Source**: `references/gideros/` | **Language**: C++ | **Scripting**: Lua | **License**: MIT

## Overview

Gideros is an open-source, cross-platform 2D game engine originally created by Atilim Cetin, with a design heavily influenced by Adobe Flash/ActionScript. It features a Sprite-based scene graph, a class-based Lua OOP system, and an extensive plugin architecture (40+ plugins). It targets mobile (iOS, Android), desktop (Windows, macOS, Linux), and web (HTML5) platforms. The engine distinguishes itself with a Flash-like display model (MovieClip, EventDispatcher) and a powerful plugin system.

## Core Design Principles

1. **Flash-Inspired Display Model** — Sprite base class mirrors Flash's Sprite/MovieClip hierarchy. EventDispatcher pattern, addChild/removeChild, hitTestPoint — all direct Flash analogues.

2. **Class-Based Lua OOP** — Gideros provides `Core.class()` for creating Lua classes with inheritance. Classes have constructors, methods, and parent class chains. `MyClass = Core.class(Sprite)`.

3. **Binder Pattern for Lua Bindings** — The `Binder` class provides a uniform way to register C++ classes in Lua with constructors, destructors, and method tables. `binder.createClass("Sprite", "EventDispatcher", create, destruct, functions)`.

4. **Plugin Architecture** — GGPlugin struct with lifecycle callbacks (main2, openUrl, enterFrame, suspend, resume). Plugins are dynamic libraries loaded by PluginManager. 40+ plugins available.

5. **Scene Graph Rendering** — Recursive Sprite::draw() traversal with transform composition. Parent transforms cascade to children. Clipping, color multiply, alpha inheritance.

6. **Multi-Backend Rendering** — Supports OpenGL 2.0, DirectX 11, Metal, and Vulkan via ShaderEngine abstraction. Backend selected per platform.

7. **MovieClip Animation** — Frame-based animation with tweens. MovieClip stores keyframes with target properties and easing functions. 15 easing types (Linear, Quad, Cubic, Sine, Expo, Back, Bounce, Elastic — each with In/Out/InOut).

8. **Platform Abstraction Layer (libgid)** — Low-level platform abstraction: `gapplication.h`, `ginput.h`, `gaudio.h`, `gtimer.h`, `ghttp.h`, `gfile.h`, `gevent.h`. Platform-specific implementations behind unified C API.

9. **Event Dispatcher Pattern** — Events flow through `EventDispatcher::dispatchEvent()`. Objects register listeners with `addEventListener`. Custom events supported.

10. **Automatic Garbage Collection Bridge** — C++ objects are ref-counted with weak references in the Binder system. When Lua GC collects a userdata, the C++ destructor runs.

11. **TileMap as First-Class Object** — Dedicated TileMap class for tile-based rendering with per-tile transforms, flip flags, color tinting. Grid-based culling for performance.

12. **3D-Capable Transform System** — Sprite transforms use 4x4 matrices. `setRotationX/Y/Z`, `setScaleX/Y/Z`, `set3DPosition` — 2.5D effects without a full 3D engine.

13. **Particle System** — Cocos2D-compatible particle format. XML/PEX file loading. Real-time particle editing in IDE.

14. **Integrated IDE** — Gideros Studio: project management, scene editor, live preview, particle editor, and documentation browser in one application.

15. **Sound→SoundChannel Pattern** — Load once (`Sound.new(path)`), play multiple instances (`sound:play()` returns a `SoundChannel`). Volume, pitch, looping, position per channel.

16. **Texture Atlas Support** — Built-in TexturePack class for sprite sheet management. Texture atlases loaded from descriptor files, individual regions accessed by name.

17. **HTTP Networking** — Built-in URL loader for HTTP requests. Async with progress and completion events.

18. **Application Events** — Lifecycle callbacks: `applicationStart`, `applicationSuspend`, `applicationResume`, `applicationExit`. Registered on the global `stage` object.

19. **Modular Dependencies** — Plugins declare dependencies on other plugins. The PluginManager resolves load order automatically.

20. **Scene Manager (via SceneManager plugin)** — Optional scene management with transition effects (Flip, Fade, MoveIn, Overlay, etc.). Not part of core but widely used.

## Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Game Code (main.lua)                                    │
│  MyScene = Core.class(Sprite) + Event handlers           │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Lua Class System + Binder                               │
│  Core.class(Base) → metatable chain with __index         │
│  Binder.createClass(name, base, ctor, dtor, methods)     │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Scene Graph                                             │
│  Stage (root Sprite)                                     │
│   ├── Bitmap (static images)                             │
│   ├── Shape (vector drawing)                             │
│   ├── TextField (text rendering)                         │
│   ├── TileMap (grid-based tiles)                         │
│   ├── MovieClip (animated sprites with tweens)           │
│   ├── Particles (particle systems)                       │
│   ├── Mesh (custom geometry)                             │
│   └── Sprite subclass (user-defined game objects)        │
└──────────────┬──────────────────────────────────────────┘
               │ EventDispatcher + recursive draw()
┌──────────────▼──────────────────────────────────────────┐
│  Engine Core                                             │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │Application│  Timer   │ Texture  │  Audio   │          │
│  │ (loop,   │Container │ Manager  │ (OpenAL  │          │
│  │  events) │(dt calc) │(atlas,   │ /custom) │          │
│  │          │          │ cache)   │          │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │  Input   │PluginMgr │ Shader   │ HTTP     │          │
│  │ (ginput) │(40+ DLLs)│ Engine   │ Loader   │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  libgid (Platform Abstraction)                           │
│  gapplication | ginput | gaudio | gfile | ghttp | gevent │
│  Platform: Win32 | macOS | Linux | iOS | Android | HTML5 │
└─────────────────────────────────────────────────────────┘
```

### Binder Registration Pattern

```cpp
// From spritebinder.cpp
static int createSprite(lua_State* L) {
    Binder binder(L);
    Sprite* sprite = new Sprite(application);
    binder.pushInstance("Sprite", sprite);
    return 1;
}

static int Sprite_addChild(lua_State* L) {
    Binder binder(L);
    Sprite* sprite = static_cast<Sprite*>(binder.getInstance("Sprite", 1));
    Sprite* child = static_cast<Sprite*>(binder.getInstance("Sprite", 2));
    sprite->addChild(child);
    return 0;
}

static int loader(lua_State* L) {
    // ...
    binder.createClass("Sprite", "EventDispatcher", createSprite, destroySprite, spriteFunctions);
    binder.createClass("Bitmap", "Sprite", createBitmap, destroyBitmap, bitmapFunctions);
    // ...
}
```

### Game Loop

```cpp
// Application::enterFrame()
void Application::enterFrame() {
    timerContainer_.tick();          // Process timers
    stage_->enterFrame(lastFrameTime_);  // Recursive update

    // Render
    ShaderEngine::Engine->reset();
    stage_->draw(ShaderEngine::Engine->currentTransform(), 0, 0, 255, 255);

    // Collect garbage
    lua_gc(L, LUA_GCSTEP, 1);
}
```

## Focus & Target Audience

- **Flash/ActionScript developers** transitioning to Lua — familiar OOP model and display hierarchy
- **Mobile game developers** — iOS/Android as primary targets
- **Plugin consumers** — Developers who need pre-built integrations (physics, networking, UI, ads)
- **IDEs users** — Developers who prefer an integrated development environment over text editor + terminal
- **Animation-heavy games** — MovieClip system with easing curves for complex animations

## Strong Points

| Strength | Details |
|----------|---------|
| **OOP class system** | `Core.class(Base)` provides proper inheritance in Lua. Cleaner than raw metatables. |
| **Plugin ecosystem** | 40+ plugins: LiquidFun, ImGui, LuaSocket, JSON, Spine, Facebook, AdMob. Modular architecture. |
| **MovieClip animation** | Keyframe animation with 15 easing types and property interpolation. Powerful for UI and character animation. |
| **Binder pattern** | Uniform, mechanical C++→Lua binding. All classes follow same registration pattern. |
| **TileMap class** | First-class tile rendering with per-tile color and flip. Grid-based culling. |
| **3D transforms** | 4x4 matrix transforms enable 2.5D effects without full 3D engine overhead. |
| **Integrated IDE** | Gideros Studio provides project management, preview, and particle editing. |
| **Event dispatcher** | Flash-style event bubbling. Custom events. Clean listener registration. |
| **Platform abstraction** | libgid provides clean C API for platform services. Easy to port. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **Flash legacy** | Flash-inspired design feels dated. DisplayList model trades flexibility for convention. |
| **Smaller community** | Much smaller than Love2D or Solar2D. Fewer tutorials, Stack Overflow answers, and community libraries. |
| **Scene graph overhead** | Every visual element is a Sprite subclass with full transform, event, and hierarchy overhead. |
| **IDE dependency** | Gideros Studio is the expected workflow. Not well-suited for developers preferring CLI or other editors. |
| **Complex C++ codebase** | Multi-platform C++ with platform-specific code, dynamic plugin loading, and multiple rendering backends. |
| **No procedural drawing** | Like Solar2D, you must create objects to draw. No `drawRect()` for quick prototyping. |
| **Plugin quality varies** | 40+ plugins but maintenance status varies widely. Some are outdated or broken. |
| **OOP overhead** | Class system adds indirection. Every object has a metatable chain, event system, and parent class lookup. |
| **Limited documentation** | Documentation exists but is less comprehensive than Love2D's wiki. |

## Things to Reimplement in Luna2D

### High Priority — Valuable Patterns

1. **Easing Functions Library** — Gideros has 15 easing types (Linear, Quad, Cubic, Sine, Expo, Back, Bounce, Elastic — In/Out/InOut variants). Luna2D's `luna.math.easing` should provide the same set.

2. **MovieClip / Tween Animation** — Keyframe animation with property interpolation. Implement as a Lua library (`luna.animation` or similar) that tweens object properties over time.

3. **Sound → SoundChannel Pattern** — Load audio once, play multiple instances. Each play returns a channel with independent volume/pitch/looping. Luna2D should follow this pattern.

4. **TileMap as Module** — Gideros's TileMap class with per-tile color, flip, and grid-based culling is a good model for Luna2D's tilemap module.

5. **Texture Atlas Support** — Named regions from a sprite sheet descriptor file. Luna2D should support TexturePacker-compatible formats.

### Medium Priority — Worth Studying

6. **Plugin Loading Pattern** — GGPlugin struct with lifecycle callbacks is clean. While Luna2D won't use dynamic loading, the callback lifecycle (init, enterFrame, suspend, resume) pattern is useful for module design.

7. **Particle System** — Cocos2D-compatible particle format. Standard exchange format for particle effects.

8. **Event Dispatcher Concepts** — While Luna2D uses callbacks, Gideros's event dispatcher with typed events and listener lists is worth considering for future extensibility.

### Lower Priority — Niche

9. **3D Transforms** — 4x4 matrices for 2.5D effects. Useful but complex. Could be a future Luna2D feature.

10. **HTTP Networking** — URL loader with async events. Orthogonal to game engine core.

## Things to Avoid

1. **OOP-First Lua Binding** — Gideros forces OOP with `Core.class()`. Luna2D should keep Love2D-style procedural API as the primary interface. Let users build OOP on top if desired.

2. **Scene Graph as Core Architecture** — Gideros makes the scene graph the center of everything. Luna2D's draw-command queue is more flexible and performant for 2D games.

3. **Flash-Era Design Patterns** — MovieClip, DisplayList, EventDispatcher — these patterns are from Flash's era. Modern game engines have moved toward ECS, immediate-mode rendering, or hybrid approaches.

4. **IDE Coupling** — Gideros Studio is tightly coupled to the engine. Luna2D correctly targets VS Code and CLI workflows.

5. **Dynamic Plugin Loading** — DLL/SO loading at runtime adds complexity, security concerns, and cross-platform headaches. Luna2D should compile all modules into the binary with Cargo features.

6. **Complex Class Hierarchy** — `EventDispatcher → Sprite → Bitmap → AnimatedBitmap` creates deep hierarchies. Luna2D should keep data types flat and composable.

7. **GC-Bridged Reference Counting** — Gideros bridges Lua GC with C++ ref counting, which can cause leaks or dangling references. Rust's ownership model is cleaner.

## Luna2D Integration Notes

Gideros's primary contribution to Luna2D thinking is in the **animation and asset management** space:

- **Easing functions** → Directly portable to `luna.math.easing` (already partially implemented)
- **Tween/MovieClip patterns** → Implement as Lua library using `luna.timer` and `luna.graphics`
- **Sound channel pattern** → Model Luna2D's audio API on the Sound→SoundChannel separation
- **TileMap class** → Reference for Luna2D's tilemap module design
- **Texture atlas** → Support sprite sheet descriptor files

The core lesson from Gideros: **a robust animation system with easing curves is essential for game scripting**. Even without a scene graph, Luna2D should provide tween utilities that operate on Lua tables or userdata properties.

However, Gideros's **Flash-era OOP model** and **scene graph architecture** are not appropriate for Luna2D. Love2D's procedural approach is simpler, more flexible, and more aligned with modern indie game development patterns.
