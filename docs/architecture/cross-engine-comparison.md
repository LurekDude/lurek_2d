# Cross-Engine Architectural Comparison — Luna2D Reference Study

> **Purpose**: Synthesize findings from 6 engine analyses into actionable recommendations for Luna2D development.

## Engine Comparison Matrix

| Dimension | Love2D | Solar2D | Gideros | ggez | macroquad | Luna2D Original |
|-----------|--------|---------|---------|------|-----------|-----------------|
| **Language** | C++ | C++ | C++ | Rust | Rust | C++ |
| **Scripting** | Lua (LuaJIT) | Lua | Lua (+ OOP) | None | None | Lua |
| **License** | zlib | MIT | MIT | MIT | MIT/Apache | MIT |
| **Rendering** | GL/Vk/Metal | GL/Vk/Metal | GL2/DX11/Metal | wgpu | miniquad (GLES2) | GLES 2.0 |
| **Physics** | Box2D | Box2D | LiquidFun plugin | None | Minimal subcrate | None |
| **Audio** | OpenAL | OpenAL | Custom + OpenAL | rodio | quad-snd | Custom |
| **Scene Mgmt** | None (Lua libs) | Composer (built-in) | Plugin | None | None | Scenes module |
| **Input Model** | Callbacks | Event listeners | Event dispatcher | Trait callbacks | Polling | Callbacks |
| **Architecture** | Module singletons | Scene graph/Display tree | OOP scene graph | Context + trait | Global unsafe | Engine singleton |
| **Target** | Desktop-first | Mobile-first | Mobile + desktop | Desktop only | Cross-platform | Mobile-first |

## Architectural Paradigms

### 1. Procedural/Callback Model (Love2D, ggez)
**Pattern**: Global functions or trait methods called by the engine. Draw with function calls. No retained objects required.
```
love.draw() → love.graphics.rectangle("fill", 10, 10, 100, 50)
```
**Pros**: Simple, low overhead, flexible, easy to learn
**Cons**: No automatic state management, manual draw ordering
**Luna2D alignment**: **HIGH** — This is Luna2D's model.

### 2. Scene Graph / Display Tree (Solar2D, Gideros)
**Pattern**: Objects created via factories, added to a display tree. Properties set on objects. Rendering is automatic.
```
local rect = display.newRect(10, 10, 100, 50)
rect.x = 200  -- moves automatically
```
**Pros**: Declarative, automatic rendering, property animation, event bubbling
**Cons**: Heavy per-object overhead, no procedural drawing, complex internals
**Luna2D alignment**: **LOW** — Too heavy for Luna2D's design philosophy.

### 3. Immediate Mode (macroquad)
**Pattern**: Functions draw directly to screen. No state retained between frames.
```
draw_rectangle(10.0, 10.0, 100.0, 50.0, RED);
```
**Pros**: Simplest possible API, zero boilerplate, fast iteration
**Cons**: No batching control, no retained state, rebuilds everything every frame
**Luna2D alignment**: **MEDIUM** — Luna2D's API looks immediate but uses a draw command queue internally.

## Consensus Patterns (4+ Engines Agree)

These patterns appear in most engines and should be considered proven:

| Pattern | Engines | Luna2D Status |
|---------|---------|---------------|
| Namespace-based API (`engine.*`) | All 5 with Lua | Implemented (`luna.*`) |
| Delta time in update callback | All 6 | Implemented |
| Factory functions for objects | Love2D, Solar2D, Gideros, ggez | Implemented |
| Asset loading from sandboxed paths | All 6 | Implemented (`GameFS`) |
| Texture atlas support | All 6 | Planned |
| Configure before start | 5 of 6 (conf.lua / config / builder) | Partial |
| Audio: load-once, play-many | All 6 | Implemented |
| Transform stack or camera | 5 of 6 | Implemented (Camera) |
| Easing functions | Love2D, Solar2D, Gideros | Implemented (`luna.math.easing`) |

## Unique Patterns Worth Adopting

### From Love2D
- **Overridable game loop** — `luna.run` could be defined in Lua for custom frame timing
- **`.love`/`.luna` archive distribution** — Single-file game packaging

### From Solar2D
- **Transition system** — `transition.to(obj, {time=500, x=200})` for declarative animation
- **Scene manager** — Built-in scene lifecycle (create → show → hide → destroy)
- **Content scaling** — Virtual resolution with automatic scaling modes

### From Gideros
- **MovieClip / Tween animation** — Keyframe animation with 15 easing types
- **Plugin lifecycle** — init/enterFrame/suspend/resume callback pattern for modules

### From ggez
- **Pipeline caching** — (shader, blend, format) key → cached GPU pipeline
- **InstanceArray** — GPU instanced rendering for sprite batching
- **VFS overlay** — Multiple search paths with zip archive support

### From macroquad
- **Automatic draw batching** — Transparent batching of same-state draws
- **Subcrate modularity** — Optional features in separate crates
- **Async loading concept** — Non-blocking asset loading

### From Luna2D Original
- **Scene table pattern** — Lua table with update/render callbacks
- **Delta time smoothing** — 30-frame moving average for stable dt
- **Resolution-aware assets** — @1x/@2x/@3x suffix matching

## Anti-Patterns to Avoid (Lessons from Failures)

| Anti-Pattern | Engine(s) | Why Avoid |
|-------------|-----------|-----------|
| Global mutable singleton | macroquad, Luna2D Original | Unsafe, untestable, blocks parallelism |
| Scene graph as mandatory | Solar2D, Gideros | Heavy overhead, forces OOP, limits flexibility |
| Plugin marketplace dependency | Solar2D | Plugins die when company shuts down |
| Preprocessor platform abstraction | Luna2D Original | Fragile, untestable, grows combinatorially |
| Multi-renderer backends | Love2D, Gideros | Massive maintenance burden (vs. wgpu which handles this) |
| OOP-first Lua API | Gideros | Adds indirection, harder to learn, unnecessary for 2D games |
| Desktop as emulator only | Luna2D Original, Solar2D | Limits audience, artificial constraint |
| Breaking version changes | ggez | Destroys ecosystem, fragments community |
| No error handling / panic | macroquad | Unacceptable for a framework/engine |

## Recommended Priority for Luna2D Feature Migration

### Tier 1 — Core (Already Aligned or In Progress)
- [x] `luna.*` callback model (Love2D pattern)
- [x] Flat namespace API
- [x] Sandboxed filesystem
- [x] wgpu rendering (ggez stack)
- [x] rodio audio
- [x] Camera transforms
- [x] Easing functions
- [x] DrawCommand queue
- [x] AABB physics

### Tier 2 — High Value, Implement Next
- [ ] **Sprite batching / InstanceArray** (ggez pattern) — Major performance gain for sprite-heavy games
- [ ] **Pipeline caching** (ggez pattern) — Essential wgpu performance optimization
- [ ] **Texture atlas** (all engines) — Standard asset management, every engine has it
- [ ] **Transition/tween system** (Solar2D/Gideros) — Declarative property animation in Lua
- [ ] **Content scaling** (Solar2D/Luna2D Original) — Virtual resolution for multi-resolution support
- [ ] **Timer module enhancement** — `luna.timer.after(delay, callback)` (Solar2D pattern)

### Tier 3 — Medium Value, Builds Complete Feature Set
- [ ] **Offscreen rendering / Canvas** (Love2D/ggez) — Render-to-texture for post-processing
- [ ] **Scene manager library** (Solar2D/Luna2D Original) — Lua library for scene lifecycle
- [ ] **Particle system** (Gideros/Luna2D Original) — Standardized particle effects
- [ ] **VFS overlay with zip support** (Love2D/ggez) — Single-file game distribution
- [ ] **Configuration file** (Love2D conf.lua) — Per-game settings

### Tier 4 — Nice to Have, Lower Priority
- [ ] **Immediate-mode UI** (macroquad) — Debug/development UI
- [ ] **Text rendering improvements** (ggez glyph_brush) — Multi-style text, rich formatting
- [ ] **Network/HTTP** (Gideros/Solar2D) — Async web requests
- [ ] **Game archive format** (Love2D .love) — `.luna` single-file distribution
- [ ] **Overridable game loop** (Love2D) — `luna.run()` definable in Lua

## Technology Stack Comparison

| Layer | Love2D | ggez | macroquad | Luna2D |
|-------|--------|------|-----------|--------|
| **Window** | SDL 2.x | winit 0.30 | miniquad | winit 0.30 |
| **Rendering** | OpenGL/Vulkan/Metal | wgpu 26 | GLES2/WebGL/Metal | wgpu 22 |
| **Math** | Custom | glam 0.30 | glam 0.27 | Custom Vec2/Mat3 |
| **Audio** | OpenAL | rodio 0.21 | quad-snd | rodio 0.17 |
| **Input** | SDL | winit + gilrs | miniquad | winit + gilrs |
| **Text** | FreeType + HarfBuzz | glyph_brush | fontdue | Embedded bitmap |
| **Images** | Custom loaders | image 0.25 | image 0.24 | image 0.24 |
| **Physics** | Box2D | None | Minimal | Custom AABB |
| **Scripting** | LuaJIT (built-in) | None | None | LuaJIT (mlua) |
| **Tessellation** | Custom | lyon 1.0 | Custom | Custom |

Luna2D's stack is closest to **ggez** in technology but closest to **Love2D** in API philosophy. This is the right combination — modern Rust infrastructure with proven Lua game-dev ergonomics.

## Summary

Luna2D should:
1. **Keep** the Love2D callback model — it's the proven developer experience
2. **Study** ggez for Rust + wgpu patterns — same technology, shared solutions
3. **Adapt** Solar2D/Gideros animation and scene patterns — as Lua libraries, not core architecture
4. **Learn** from macroquad's simplicity — keep the API minimal and productive
5. **Preserve** the original Luna2D's naming and design identity — `luna.*` namespace, scene concepts
6. **Avoid** scene graphs, global unsafe state, plugin marketplaces, and multi-backend renderers
