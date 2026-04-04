# Luna2D Original (C++) — Architectural Analysis

> **Source**: `references/luna2d-original/` | **Language**: C++ | **Scripting**: Lua | **License**: MIT

## Overview

The original Luna2D is a C++ 2D game engine created for mobile game development (iOS, Android) with a Qt-based desktop emulator for development. It is the predecessor and spiritual ancestor of the current Rust-based Luna2D. The engine features LuaJIT scripting, OpenGL ES 2.0 rendering, a scene system, and a services layer for mobile monetization (ads, analytics, IAP). The architecture follows a singleton pattern with a central `LUNAEngine` object owning all subsystems.

## Core Design Principles

1. **Singleton Engine** — `LUNAEngine` is a global singleton owning all subsystems as member pointers. `LUNAEngine::SharedEngine()` provides global access. All subsystems are accessible through the engine singleton.

2. **Custom Lua Binding System** — `LuaClass<T>` template for registering C++ classes in Lua. Metatable-based with `__index` and `__gc`. `LuaStack<T>` for type conversion. `LuaRef` for reference management.

3. **`luna.*` Global Namespace** — All Lua API calls use the `luna.*` global table. `luna.graphics.drawSprite()`, `luna.audio.play()`. This convention carries directly to the new Luna2D.

4. **Scene System** — Lua tables with lifecycle callbacks: `onPause`, `onResume`, `update(dt)`, `render()`, `onTouchDown/Moved/Up`. One active scene at a time. Simple and effective.

5. **Mobile-First Design** — OpenGL ES 2.0, touch input, content scaling, and service integrations (ads, analytics, IAP) designed for iOS/Android deployment.

6. **Qt Desktop Emulator** — Desktop development uses a Qt-based emulator that simulates mobile resolution, DPI, and touch input. Development happens on desktop, deployment on mobile.

7. **Platform Abstraction via Preprocessor** — `LUNA_PLATFORM_QT`, `LUNA_PLATFORM_ANDROID`, `LUNA_PLATFORM_IOS`, `LUNA_PLATFORM_WP`. Virtual base classes with per-platform implementations.

8. **Batched Vertex Rendering** — `LUNARenderer` batches vertices (8 floats per vertex: u, v, x, y, color) and submits to OpenGL in bulk. Automatic batch breaking on texture change.

9. **Asset Pipeline with Resolution Scaling** — `LUNAAssets` loads textures with automatic resolution suffix matching (@1x, @2x, @3x) based on device DPI. Texture atlases supported.

10. **Delta Time Smoothing** — 30-frame moving average of delta time to reduce frame-to-frame jitter. Max delta clamped to 1/10th second to prevent spiral of death.

11. **Service Abstraction** — `LUNAServices` provides plugins for ads, analytics, IAP, sharing, and notifications via platform-specific native code (Java/JNI for Android, ObjC for iOS).

12. **Custom Reflection System** — `LuaClass<T>` provides a lightweight reflection system for exposing C++ classes to Lua without code generation or external tools.

13. **Graphics Object Hierarchy** — `LUNADrawable` base → `LUNASprite`, `LUNAAnimation`, `LUNAText`, `LUNAMesh`, `LUNARadialMesh`, `LUNAParticleSystem`. Each can be rendered and transformed.

14. **Texture Region System** — `LUNATexture` → `LUNATextureAtlas` → `LUNATextureRegion`. Regions reference sub-rectangles of textures. Atlas loaded from JSON descriptor.

15. **Config-Driven Initialization** — `LUNAConfig` reads settings from a config file. Resolution policy, orientation, FPS target, log level.

## Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Game Code (main.lua)                                    │
│  luna.scenes.setCurrent(gameScene)                       │
│  gameScene = { update=fn, render=fn, onTouchDown=fn }    │
└──────────────┬──────────────────────────────────────────┘
               │ Lua callbacks
┌──────────────▼──────────────────────────────────────────┐
│  LUNAEngine (Singleton)                                  │
│  SharedEngine() → global access                          │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ lua      │ assets   │ graphics │  audio   │          │
│  │(LuaScript│(loader,  │(renderer,│(music,   │          │
│  │ VM)      │ cache,   │ sprites, │ sfx)     │          │
│  │          │ atlas)   │ text)    │          │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │ scenes   │  sizes   │  events  │ strings  │          │
│  │(scene    │(virtual  │(event    │(i18n)    │          │
│  │ stack)   │ res)     │ system)  │          │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │ config   │ services │  files   │   log    │          │
│  │(settings)│(ads/IAP) │(file I/O)│(logging) │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │ MainLoop()
┌──────────────▼──────────────────────────────────────────┐
│  Game Loop                                               │
│  OnUpdate() → calculate dt (smoothed) →                  │
│  Scenes::OnUpdate(dt) → Renderer::Begin() →              │
│  Scenes::OnRender() → Renderer::End()                    │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Platform Layer                                          │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ Qt       │ Android  │  iOS     │ WinPhone │          │
│  │(desktop  │(JNI,     │(ObjC,   │(WinRT)   │          │
│  │ emulator)│ GLSurf)  │ GLKit)  │          │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
│  OpenGL ES 2.0 / OpenGL 2.1                              │
└─────────────────────────────────────────────────────────┘
```

### Lua Binding Example

```cpp
// Register LUNASprite class in Lua
LuaClass<LUNASprite> clsSprite(lua);
clsSprite.SetConstructor<const LuaAny&>();
clsSprite.SetMethod("setTexture", &LUNASprite::SetTexture);
clsSprite.SetMethod("setTextureRegion", &LUNASprite::SetTextureRegion);
clsSprite.SetMethod("setShader", &LUNASprite::SetShader);
clsSprite.SetMethod("render", &LUNASprite::Render);
clsSprite.SetMethod("setPos", &LUNASprite::SetPos);
clsSprite.SetMethod("getX", &LUNASprite::GetX);
clsSprite.SetMethod("setX", &LUNASprite::SetX);
// ...

// Register under luna.graphics
lua->GetGlobalTable().GetTable("luna").GetTable("graphics")
    .SetField("Sprite", clsSprite);
```

### Scene System

```lua
-- Game scene as a Lua table
local gameScene = {}

function gameScene:update(dt)
    -- Game logic
    self.player:update(dt)
end

function gameScene:render()
    -- Draw game objects
    self.player:render()
    self.background:render()
end

function gameScene:onTouchDown(x, y)
    -- Handle touch
    self.player:jump()
end

-- Set active scene
luna.scenes.setCurrent(gameScene)
```

### Delta Time Smoothing

```cpp
// 30-frame moving average for delta time
const int SMOOTH_FRAMES = 30;
float smoothDt = 0;
std::deque<float> dtHistory;

void OnUpdate() {
    float rawDt = timer.GetDelta();
    rawDt = std::min(rawDt, 0.1f);  // Clamp to 100ms max

    dtHistory.push_back(rawDt);
    if (dtHistory.size() > SMOOTH_FRAMES) dtHistory.pop_front();

    smoothDt = std::accumulate(dtHistory.begin(), dtHistory.end(), 0.0f) / dtHistory.size();
    scenes->OnUpdate(smoothDt);
}
```

## Focus & Target Audience

- **Mobile game developers** — iOS and Android as primary targets
- **Solo developers** — Simple scene-based architecture, no complex frameworks
- **Lua game scripters** — Writers of game logic, not engine code
- **Commercial mobile games** — Service layer for ads, analytics, IAP

## Strong Points

| Strength | Details |
|----------|---------|
| **`luna.*` namespace** | Clean, consistent Lua API namespace. Directly inherited by new Luna2D. |
| **Scene system** | Simple and effective — Lua table with callbacks. No complex framework. |
| **LuaClass<T> binding** | Clean template-based binding. Method/property registration is concise. |
| **Delta time smoothing** | 30-frame moving average reduces jitter. Max clamp prevents spiral of death. |
| **Content scaling** | Resolution-independent rendering with DPI-aware asset loading. |
| **Qt desktop emulator** | Develop on desktop, deploy on mobile. Simulates target resolution. |
| **Texture atlas system** | JSON-descriptor-based atlas with named region access. Industry-standard approach. |
| **Batched rendering** | Automatic vertex batching with texture-change batch breaks. Efficient for mobile GPUs. |
| **Service abstraction** | Clean interface for platform-specific services (ads, analytics). Pluggable. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **C++ memory management** | Raw pointers, manual memory management, potential leaks. |
| **Mobile-only focus** | Qt emulator is a development tool, not a desktop target. No desktop distribution. |
| **OpenGL ES 2.0** | Fixed to one rendering API. No Vulkan, Metal, or compute shaders. |
| **Preprocessor-based platform** | `#ifdef LUNA_PLATFORM_*` throughout codebase. Fragile, hard to test. |
| **Singleton anti-pattern** | `LUNAEngine::SharedEngine()` is global state. Hard to test, hard to parallelize. |
| **No physics** | No built-in physics engine. Games must implement their own. |
| **Limited audio** | Basic music/sfx playback. No mixing, effects, or spatial audio. |
| **No desktop distribution** | Engine was designed for mobile app stores only. |
| **Service layer complexity** | JNI/ObjC bridges for ads, analytics, IAP add significant platform-specific code. |
| **Single scene** | Only one active scene at a time. No stacking, overlays, or parallel scenes. |

## Things to Reimplement in Luna2D

### High Priority — Direct Heritage

1. **`luna.*` Namespace** — Already implemented. The new Luna2D preserves the original's namespace convention exactly.

2. **Scene System Concept** — The original's "Lua table with update/render/onTouchDown callbacks" is simple and effective. Luna2D should offer this as a built-in library pattern, even though the core uses Love2D-style global callbacks.

3. **Delta Time Smoothing** — The 30-frame moving average and max-delta clamp are proven techniques. Luna2D's timer module should implement similar smoothing.

4. **Content Scaling** — Resolution-independent virtual coordinates with DPI-aware asset loading. Essential for multi-resolution support.

5. **Texture Atlas with Named Regions** — JSON/dictionary-based atlas descriptors with `atlas:getRegion("player_run_1")`. Standard pattern, well-tested in original.

6. **Batched Rendering** — Automatic vertex batching with state-change batch breaks. The original's 8-float-per-vertex format is simple and fast.

### Medium Priority — Worth Preserving

7. **LuaClass Registration Style** — The original's `.SetMethod("setX", &Class::SetX)` pattern maps well to mlua's approach. Keep the binding style familiar.

8. **Config File** — Settings file for resolution policy, FPS target, orientation. Simple and useful.

9. **Asset Resolution Suffixes** — @1x/@2x/@3x suffixed asset files loaded based on device DPI. Good for mobile targets.

### Lower Priority

10. **Localization (Strings)** — `LUNAStrings` for i18n. Useful for commercial games, low priority for engine core.

11. **Particle System** — The original had a particle system. Luna2D already plans one.

## Things to Avoid

1. **Global Singleton Pattern** — `LUNAEngine::SharedEngine()` creates global mutable state. The new Luna2D correctly uses `Rc<RefCell<SharedState>>` with explicit ownership.

2. **Preprocessor Platform Abstraction** — `#ifdef LUNA_PLATFORM_*` is fragile and impossible to test comprehensively. Rust's trait-based abstraction and Cargo feature flags are superior.

3. **Raw Pointer Ownership** — C++ manual memory management with raw `new/delete`. Rust's ownership model eliminates this entire class of bugs.

4. **OpenGL Direct Calls** — Hardcoded to GL ES 2.0. The new Luna2D's wgpu backend abstracts over all modern APIs.

5. **Mobile-Only Architecture** — The original assumed mobile deployment with desktop as a development tool. New Luna2D correctly targets desktop first with mobile as a future goal.

6. **Service Layer** — Ads, analytics, IAP, sharing — these are commercial mobile concerns. Open-source Luna2D doesn't need this complexity. If needed, they can be Lua libraries.

7. **Qt Dependency** — Qt is a massive dependency for a desktop emulator. The new Luna2D uses winit, which is lightweight and cross-platform.

8. **Single-Scene Limitation** — Only one scene active at a time with no stacking. Luna2D should support scene overlays (e.g., pause menu over game).

9. **Vertex Format Lock-in** — 8 floats per vertex (u, v, x, y, color) is rigid. The new Luna2D's wgpu backend supports custom vertex formats.

## Luna2D Integration Notes

The original Luna2D is the **direct predecessor** of the current project. The new Rust-based Luna2D preserves several core design decisions:

| Original (C++) | New (Rust) | Status |
|----------------|------------|--------|
| `luna.*` namespace | `luna.*` namespace | Preserved |
| Scene table callbacks | `luna.load/update/draw` + future scene system | Evolved |
| LuaClass<T> binding | mlua `register()` pattern | Modernized |
| OpenGL ES 2.0 | wgpu (Vulkan/DX12/Metal/GL) | Upgraded |
| Singleton engine | `Rc<RefCell<SharedState>>` | Safer |
| Preprocessor platforms | Cargo features + traits | Cleaner |
| Qt emulator | winit native window | Simplified |
| Raw pointers | Ownership + borrowing | Memory safe |

Key evolution decisions that should be maintained:

1. **Keep `luna.*` namespace** — Brand identity and API continuity from the original
2. **Keep scene concept** — But make it a Lua library pattern, not a core module
3. **Keep delta smoothing** — Proven technique from original's production use
4. **Keep texture atlas** — Standard asset management pattern
5. **Drop services layer** — Commercial mobile features don't belong in an open-source engine
6. **Drop mobile-first** — Desktop is the primary target; mobile comes later via wgpu portability

The original Luna2D proves the viability of a "Lua + compact engine" approach for 2D game development. The new Rust version improves on every technical dimension (safety, performance, rendering capabilities) while preserving the developer-facing design philosophy.
