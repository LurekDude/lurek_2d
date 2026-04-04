# Solar2D (Corona SDK) — Architectural Analysis

> **Source**: `references/solar2d/` | **Language**: C++ | **Scripting**: Lua | **License**: MIT

## Overview

Solar2D (formerly Corona SDK) is an open-source cross-platform game engine originally developed by Corona Labs, founded in 2009 by Walter Luh and Carlos Icaza — former Adobe Flash Lite engineers. It was commercially licensed as Corona SDK until 2020, when it was open-sourced under the MIT license and renamed Solar2D. The engine targets mobile-first development (iOS, Android) with desktop (Windows, macOS, Linux) and web (HTML5) support.

## Core Design Principles

1. **Scene Graph / Display Tree** — All rendering is organized as a tree of DisplayObjects. The Stage is the root. Groups contain children. Objects have properties (x, y, rotation, alpha, isVisible) that update rendering automatically. No manual draw calls.

2. **Object-Oriented Display Model** — Every visible entity is a DisplayObject with methods and properties. `display.newRect(x, y, w, h)` returns an object. You set `obj.x = 100` and it moves. This is fundamentally different from Love2D's procedural draw.

3. **Event-Driven Architecture** — Everything is events. Frame updates (`enterFrame`), touch input, collision, timers, network responses — all use `obj:addEventListener(eventName, handler)`. Events bubble up the display tree for touch/tap.

4. **Factory Pattern for Object Creation** — Objects are created via library factory functions: `display.newImage()`, `display.newText()`, `physics.addBody()`. No constructors, no `new` keyword.

5. **Property-Based Animation** — Object properties can be animated with `transition.to(obj, {time=1000, x=200, alpha=0})`. The transition system interpolates any numeric property.

6. **Mobile-First Design** — Built by ex-Flash Lite engineers for mobile games. Content scaling, auto-resolution, orientation handling, and mobile input (touch, accelerometer) are first-class.

7. **Plugin Marketplace** — Extensibility through a curated plugin marketplace. Plugins are `.tgz` archives registered in `build.settings`. Categories: ads, analytics, game networks, licensing.

8. **Configuration-Driven Setup** — `config.lua` defines content area, scaling mode, and FPS. `build.settings` defines platform-specific build options (permissions, icons, plugins).

9. **Immediate Physics Integration** — Physics bodies are attached directly to DisplayObjects. `physics.addBody(rect, "dynamic", {density=1.0})`. Collision events dispatch through the object.

10. **Automatic Memory Management** — DisplayObjects are garbage-collected when removed from the display tree. `obj:removeSelf()` or `display.remove(obj)` triggers cleanup.

11. **Content Scaling** — `config.lua` defines a virtual content area (e.g., 320×480). The engine scales to fit any screen resolution with configurable letterboxing or fill modes.

12. **Deferred Rendering** — CommandBuffer pattern collects geometry during scene traversal, then submits to GPU. Dirty flags on DisplayObjects minimize rebuild work.

13. **Timer and Transition Systems** — `timer.performWithDelay()` and `transition.to/from/moveTo/fadeIn/fadeOut` provide declarative time-based operations without manual delta-time tracking.

14. **Scene Management (Composer)** — Built-in scene manager (`composer`) handles scene transitions, overlays, and scene lifecycle (create, show, hide, destroy events).

15. **Cross-Platform Native Access** — Native API bridges (JNI for Android, ObjC for iOS) enable platform-specific features without modifying the core engine.

16. **Storyboard → Composer Evolution** — Replaced the legacy Storyboard API with Composer, showing willingness to evolve APIs while maintaining backward compatibility.

17. **Lua Proxy System** — C++ objects are exposed to Lua via LuaProxy with a VTable pattern. Properties use `__index/__newindex` metamethods for transparent access.

18. **Group-Based Organization** — DisplayGroups serve as containers for scene organization. `group:insert(child)` manages visual hierarchy and transform inheritance.

19. **Event Bubbling** — Touch events propagate up the display tree. A child's touch handler can consume the event (`return true`) or let it bubble to parent.

20. **Runtime Director** — `Rtt_Runtime` orchestrates Display, Scheduler, PhysicsWorld, and Platform. Clean separation between game simulation and platform services.

## Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Game Code (main.lua + config.lua + build.settings)      │
│  Scene modules via composer.gotoScene("game")            │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Lua Libraries                                           │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ display  │ physics  │transition│  timer   │          │
│  │(factory) │(Box2D)   │(tweens)  │(delayed) │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │ composer │  audio   │  system  │ network  │          │
│  │(scenes)  │(OpenAL)  │(info)    │(HTTP)    │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │ LuaProxy + VTable
┌──────────────▼──────────────────────────────────────────┐
│  Display Tree (Scene Graph)                              │
│  Stage                                                   │
│   ├── GroupObject ("background")                         │
│   │    ├── ImageFrameObject                              │
│   │    └── ShapeObject (RectObject, CircleObject)        │
│   ├── GroupObject ("game")                               │
│   │    ├── SpriteObject (with physics Body)              │
│   │    ├── TextObject                                    │
│   │    └── GroupObject (nested)                           │
│   └── GroupObject ("ui")                                 │
│        └── TextObject                                    │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Runtime (Rtt_Runtime)                                   │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ Display  │Scheduler │PhysWorld │ Platform │          │
│  │(scene,   │(timers,  │(Box2D    │(native   │          │
│  │ render)  │ events)  │ wrapper) │ bridge)  │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Rendering Backend                                       │
│  CommandBuffer → GeometryPool → GPU (GL/Vulkan/Metal)    │
└─────────────────────────────────────────────────────────┘
```

### Display Object Hierarchy

```
DisplayObject (base: x, y, rotation, xScale, yScale, alpha, isVisible)
 ├── ShapeObject (fill, stroke, path)
 │    ├── RectObject
 │    ├── CircleObject
 │    └── PolygonObject
 ├── GroupObject (children list, insert/remove)
 ├── ImageFrameObject (texture, sourceRect)
 ├── TextObject (text, font, fontSize, align)
 ├── SpriteObject (sprite sheet, sequences, play/pause)
 └── ParticleSystemObject (particle emitter)
```

### Event System

```lua
-- Object-level events (bubble up display tree)
rect:addEventListener("touch", function(event)
    if event.phase == "began" then
        -- handle touch start
    end
    return true  -- consume event
end)

-- Global events (broadcast)
Runtime:addEventListener("enterFrame", function(event)
    -- called every frame
end)

-- Collision events
physics.addBody(ball, "dynamic")
ball:addEventListener("collision", function(event)
    if event.phase == "began" then
        -- handle collision start
    end
end)
```

## Focus & Target Audience

- **Mobile game developers** — Content scaling, touch input, accelerometer, app store integration
- **Solo developers and small studios** — One codebase → iOS + Android + Desktop
- **Flash/ActionScript refugees** — Display tree model familiar to Flash developers
- **Rapid mobile prototyping** — Live builds, instant preview on device
- **Casual/hyper-casual games** — Simple API, fast iteration, plugin ecosystem for monetization

## Strong Points

| Strength | Details |
|----------|---------|
| **Scene graph paradigm** | Display tree with property-based rendering eliminates manual draw calls. Set `obj.x = 100` and it renders. |
| **Event system** | Unified event model for input, physics, timers, and custom events. Event bubbling for touch. |
| **Content scaling** | Automatic resolution adaptation with configurable scaling modes. Write once, run on any screen. |
| **Composer scene manager** | Built-in scene lifecycle management with transitions and overlays. |
| **Transition system** | Declarative property animation: `transition.to(obj, {time=500, x=200, rotation=360})`. |
| **Physics integration** | Bodies attached directly to DisplayObjects. Collision events on objects. No separate world management. |
| **Plugin ecosystem** | 200+ plugins for ads, analytics, social, etc. One-line integration in `build.settings`. |
| **Live builds** | Preview on device without full recompile cycle. |
| **Automatic cleanup** | Remove display object → physics body, listeners, and resources cleaned up. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **Scene graph overhead** | Every visual element is a full object with properties, events, transform hierarchy. Heavy for particle-heavy or sprite-dense games. |
| **No immediate-mode drawing** | Can't just call `drawRect(x, y, w, h)` — must create a display object. Inappropriate for procedural/generative graphics. |
| **Legacy API cruft** | Storyboard (deprecated), widget library (partially maintained), inconsistent naming across modules. |
| **Plugin marketplace dependency** | Core engine lacks features that require paid plugins in the commercial era. Some plugins are unmaintained post-open-source. |
| **Mobile-first bias** | Desktop support is secondary. No Linux installer, limited desktop GPU features. |
| **Complex C++ codebase** | Runtime is vast C++ with platform-specific code, JNI/ObjC bridges, multiple renderers. Hard to contribute. |
| **No ECS pattern** | Object management is manual group hierarchy. No component composition. |
| **Limited shader support** | Custom shaders are possible but complex and poorly documented compared to Love2D. |
| **Box2D coupling** | Physics is tightly coupled to the display tree. Hard to use physics without display objects. |

## Things to Reimplement in Luna2D

### High Priority — Valuable Patterns

1. **Transition/Tween System** — `transition.to(obj, {time=500, x=200})` is excellent for game scripting. Luna2D should offer a Lua-level tween library or built-in `luna.transition` module.

2. **Timer Module** — `timer.performWithDelay(1000, callback, count)` eliminates manual delta accumulation in Lua. Simple to implement, high value.

3. **Content Scaling** — Virtual coordinate system with automatic scaling to physical resolution. Essential for multi-resolution support.

4. **Scene Manager Pattern** — Built-in scene lifecycle (create → show → hide → destroy) with transitions. Implementable in Lua but worth providing as a default library.

5. **Event System Concepts** — Though Luna2D uses callbacks (Love2D style), consider supporting `addEventListener`-style event registration for collision events and custom game events.

### Medium Priority — Worth Studying

6. **Property-Based Animation** — Animating object properties declaratively is more ergonomic than manual interpolation in `update(dt)`.

7. **Display Object Cleanup** — Automatic resource cleanup when objects are removed. Luna2D should ensure Lua objects release Rust resources on GC.

8. **Group/Layer Organization** — Named groups for rendering order management (background, game, UI layers).

### Lower Priority — Niche

9. **Widget Library** — Button, scrollview, picker widgets. Useful for game UI but complex to maintain.

10. **Network Module** — HTTP requests and async downloads. Useful but tangential to game engine core.

## Things to Avoid

1. **Mandatory Scene Graph** — Solar2D forces every visual element into a display tree. Luna2D should keep Love2D-style immediate-mode drawing as primary, with optional retained objects (sprites, text).

2. **Plugin Marketplace Model** — Solar2D's commercial plugin marketplace created dependency on third-party maintainers. Many plugins died when Corona Labs closed. Luna2D should keep all essential features in-engine.

3. **Deep Display Object Hierarchy** — Solar2D's DisplayObject → ShapeObject → RectObject class hierarchy is over-engineered for 2D games. Keep drawing primitives flat.

4. **Properties via Metamethods** — Solar2D uses `__index/__newindex` to expose `obj.x`, `obj.rotation` as properties. This is magical and hard to debug. Prefer explicit methods (`obj:getX()`, `obj:setX()`), or use properties only for simple containers.

5. **Physics-Display Coupling** — Solar2D attaches physics bodies directly to display objects. This makes sense for their scene graph but would be inappropriate for Luna2D's decoupled module architecture. Keep physics and graphics independent.

6. **Configuration Complexity** — Solar2D requires `config.lua`, `build.settings`, and sometimes `main_shell.lua`. Luna2D should use a single optional config file.

7. **Mobile-First Assumptions** — Solar2D's content scaling, DPI handling, and touch-primary input assume mobile. Luna2D targets desktop first and should design accordingly.

8. **Service Layer** — Solar2D's ads/analytics/IAP service abstraction was necessary for commercial mobile games but adds complexity Luna2D doesn't need as an open-source engine.

## Luna2D Integration Notes

Solar2D's **scene graph model** is fundamentally different from Luna2D's **Love2D-inspired immediate-mode** approach. However, several Solar2D patterns are worth adapting:

- **Transition/tween system** → Implement as `luna.transition` module or Lua library
- **Timer module** → Enhanced `luna.timer` with delayed callbacks
- **Content scaling** → Virtual resolution support in Luna2D's window/camera system
- **Scene manager** → Provide as an example/library pattern, not a core module
- **Event concepts** → Consider `addEventListener` for collision callbacks alongside direct callbacks

The key lesson from Solar2D: **declarative property animation and scene management dramatically improve developer productivity for game scripting**. Luna2D can offer these at the Lua level without adopting the heavy scene graph architecture.

Solar2D's history also warns against **commercial plugin dependency** — when the company behind it closed, many plugins became unmaintained. Luna2D's open-source, batteries-included approach is the safer path.
