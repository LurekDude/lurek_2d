# Lurek2D Ecosystem Research � Are We Game Yet?

**Source**: [arewegameyet.rs/#ecosystem](https://arewegameyet.rs/#ecosystem)
**Research date**: 2026-03-29
**Purpose**: Survey the Rust game-dev ecosystem and identify what can realistically be reimplemented or integrated into Lurek2D.

> Note: This document is a historical research snapshot. References below to `minifb`/`tiny-skia` as Lurek2D's main runtime predate the current `winit` + `wgpu` primary stack. See `docs/architecture.md` for the current architecture.

---

## Table of Contents

- [Lurek2D Ecosystem Research � Are We Game Yet?](#lurek2d-ecosystem-research--are-we-game-yet)
	- [Table of Contents](#table-of-contents)
	- [Current Lurek2D State](#current-lurek2d-state)
		- [What Exists](#what-exists)
		- [Key Gaps](#key-gaps)
	- [Ecosystem Categories Overview](#ecosystem-categories-overview)
	- [Category-by-Category Analysis](#category-by-category-analysis)
		- [2D Rendering](#2d-rendering)
		- [Audio](#audio)
		- [Physics](#physics)
		- [ECS (Entity Component System)](#ecs-entity-component-system)
		- [Input](#input)
		- [Math](#math)
		- [Animation](#animation)
		- [Text Rendering](#text-rendering)
		- [Scripting Languages](#scripting-languages)
		- [Networking](#networking)
		- [UI](#ui)
		- [AI](#ai)
		- [Shaders](#shaders)
		- [Tools](#tools)
		- [Windowing](#windowing)
	- [Prioritized Implementation Roadmap](#prioritized-implementation-roadmap)
		- [Priority 1 � High Impact, Low Effort](#priority-1--high-impact-low-effort)
		- [Priority 2 � High Impact, Medium Effort](#priority-2--high-impact-medium-effort)
		- [Priority 3 � Medium Impact, Medium Effort](#priority-3--medium-impact-medium-effort)
		- [Priority 4 � Stretch Goals](#priority-4--stretch-goals)
	- [Crates Worth Integrating Directly](#crates-worth-integrating-directly)
	- [Features Lurek2D Should Build Natively](#features-lurek2d-should-build-natively)
	- [Out of Scope for Lurek2D](#out-of-scope-for-lurek2d)

---

## Current Lurek2D State

Lurek2D is a software-rendered (tiny-skia � Pixmap � u32 buffer � minifb) 2D game engine with Lua 5.4 scripting (via mlua). Below is a condensed gap summary derived from codebase exploration.

### What Exists

| Module | Status |
|--------|--------|
| **Graphics** | tiny-skia shapes (rect, circle, ellipse, triangle, polygon, line), texture blit (`DrawImage`), bitmap-font `Print`, Color, Sprite, Camera (not yet integrated into draw) |
| **Audio** | rodio Mixer, AudioSource, play/stop/volume |
| **Physics** | AABB World + Body, gravity, impulse resolution, restitution |
| **Input** | KeyboardState, MouseState, GamepadState (not Lua-exposed), minifb key names |
| **Math** | Vec2, Mat3, Rect |
| **Timer** | Clock: delta, total, FPS, frame count |
| **Filesystem** | Sandboxed read/write, path-traversal guard |
| **Lua API** | 10 modules: graphics, audio, input, window, physics, filesystem, math, timer, event, system |
| **Engine** | App game loop, Config, EngineError, callback invocation |

### Key Gaps

- No sprite animation, particle system, or tilemap rendering
- AABB-only physics (no circles, no rotation, no joints, no friction)
- Audio: no loop, no pause, no pitch, no 3D spatial
- Input: no mouse wheel, no gamepad exposure to Lua, no text input
- No TTF/scalable font rendering
- Camera exists but transform not applied during draw
- No ECS
- No networking
- No scene management
- No debug/overlay tooling

---

## Ecosystem Categories Overview

| Category | Crate Count | Lurek2D Relevance |
|----------|------------|-----------------|
| 2D Rendering | 30 | **High** � already uses tiny-skia; other crates offer upgrades |
| Audio | 29 | **High** � already uses rodio; gaps in features |
| Physics | 15 | **High** � replace/augment custom AABB with rapier2d |
| ECS | 17 | **Medium** � optional architectural enhancement |
| Input | 7 | **High** � gamepad support via gilrs |
| Math | 21 | **High** � glam/nalgebra can replace/extend custom Vec2/Mat3 |
| Animation | 3 | **Medium** � tweening library for smooth motion |
| Text Rendering | 6 | **High** � TTF fonts via fontdue or ab_glyph |
| Scripting Languages | 23 | **Low** � already uses mlua (currently optimal choice) |
| Networking | 19 | **Low-Medium** � multiplayer is stretch-goal territory |
| UI | 14 | **Medium** � debug overlay via egui or yakui |
| AI | 9 | **Low-Medium** � pathfinding useful for game logic |
| Shaders | 15 | **Low** � software renderer cannot use GPU shaders directly |
| Tools | 42 | **Medium** � asset pipeline, tiled maps, noise generation |
| Windowing | 9 | **Low** � already uses minifb adequately |

---

## Category-by-Category Analysis

### 2D Rendering

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `tiny-skia` 0.12.0 | 5.8M | 1,517 | **Already used** � software rendering backbone |
| `image` 0.25.10 | 19.3M | 5,700 | **Already used** � texture loading |
| `wgpu` 29.0.0 | 4.2M | 16,732 | GPU rendering � would replace tiny-skia entirely |
| `pixels` 0.15.0 | 72K | 2,087 | GPU pixel buffer � alternative to minifb's framebuffer |
| `femtovg` 0.20.4 | 260K | 905 | Antialiased 2D vector drawing over OpenGL/Metal |
| `lyon` 1.0.19 | 440K | 2,546 | GPU tessellation for vector paths |
| `miniquad` 0.4.8 | 151K | 1,964 | Cross-platform context + rendering, WebAssembly-friendly |
| `blit` 0.8.5 | 1,350 | 26 | Sprite blitting on raw pixel buffers � close to Lurek2D model |
| `rotsprite` 0.1.4 | 424 | 39 | Software sprite rotation algorithm � could improve rotating sprites |
| `piston2d-graphics` 0.45.0 | 92K | 483 | Abstract 2D rendering backend |

**Lurek2D gaps this addresses:**

1. **Sprite blending / draw modes** � `tiny-skia`'s `BlendMode` enum supports `SourceOver`, `Multiply`, `Screen`, `Overlay`, `Hardlight`, `ColorDodge`, `Difference`, `Exclusion`, `Hue`, `Saturation`, `Plus` etc. Lurek2D currently only ever uses `SourceOver`. Exposing these through `RenderCommand::SetBlendMode` would unlock per-sprite blending from Lua.

2. **Camera transform integration** � Camera struct already exists with a world-to-screen `Mat3`. The missing step is applying it in `Renderer::flush()` before drawing each `DrawImage` or shape. Implementation is straightforward: multiply sprite position through `camera.view_matrix()`.

3. **Z-ordering / draw layers** � Lurek2D draws in call order. A `RenderCommand::SetLayer(i32)` variant + stable-sort in `flush()` would support depth control from Lua without changing the API contract.

4. **9-slice images** � Useful for UI panels. Can be implemented natively using 9 `DrawImage` calls with pre-split rects; no new crate needed.

5. **Render-to-texture / canvas** � `tiny-skia` supports drawing into any `Pixmap`. Adding a `RenderCommand::BeginCanvas/EndCanvas` pair that creates a temporary Pixmap and saves it as a texture would enable render targets from Lua.

6. **Sprite batching** � Currently each `DrawImage` is an independent skia call. For performance with hundreds of sprites, caching a sprite sheet into a single Pixmap and UV-slicing would help. This is a custom implementation; no crate does it for the tiny-skia model.

7. **Software pixel shaders** � Since we control the pixel buffer, Lua could define a per-pixel callback invoked on a region (like a `lurek.render.effect(fn, x, y, w, h)`). This would be a Lurek2D-specific innovation not available in hardware-accelerated engines.

**Verdict on GPU upgrade:** Migrating to `wgpu` or `pixels` would deliver major framerate improvements (hardware acceleration vs. CPU painting) but would break the architecture fundamentally. This is a future major-version concern, not an incremental improvement. The current tiny-skia pipeline is coherent, testable, and cross-platform without native dependencies beyond a window.

---

### Audio

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `rodio` 0.22.2 | 1.2M | 2,296 | **Already used** � playback backbone |
| `kira` 0.12.0 | 85K | 1,004 | Expressive game audio: tweens, sequences, spatial |
| `cpal` 0.17.3 | 2.1M | 3,609 | Low-level cross-platform audio I/O (rodio's backend) |
| `oddio` 0.7.4 | 7.7K | 161 | Lightweight game audio, good API design |
| `Engine K-sound` 0.36.2 | 4.6K | 8,958 | Engine K engine's sound system |
| `claxon` 0.4.3 | 467K | 321 | Pure Rust FLAC decoder |
| `hound` 3.5.1 | 2.3M | 603 | WAV encoding/decoding |
| `lewton` 0.10.2 | 920K | 286 | Pure Rust Vorbis decoder |
| `ambisonic` 0.4.1 | 583 | 90 | 3D spatialized audio |
| `sfxr` 0.1.4 | 195 | 54 | Procedural retro sound effects generator |
| `usfx` 0.1.5 | 263 | 56 | Realtime procedural sound effects |

**Lurek2D gaps this addresses:**

1. **Loop control** � `rodio 0.22` supports `Sink::repeat_infinite()` and `Source::repeat_infinite()`. The Lurek2D `Mixer::play()` method just needs a `looping: bool` parameter. Estimated effort: trivial � change one `rodio` call.

2. **Pause/resume** � `rodio::Sink::pause()` and `Sink::play()` already exist. Lurek2D stores a `Sink` per AudioSource; just expose these methods.

3. **Pitch/speed** � `rodio::Source::speed(ratio: f32)` is available. Expose as `lurek.audio.setPitch(source, 1.5)`.

4. **Master volume** � `rodio::OutputStreamHandle` doesn't expose global volume directly. A workaround is wrapping all sources with `.amplify(master_volume)` before `.append()`. Alternatively, kira provides this natively.

5. **Fade in/out** � `rodio::Source::fade_in(duration)` exists. Custom fade-out requires time-tracking. `kira` has built-in tweening for this.

6. **Tracking playing state** � `rodio::Sink::empty()` returns `true` when playback ends. This can be polled on `lurek.update()` to fire completion events.

7. **Multiple concurrent sounds of same source** � Currently each AudioSource has one Sink. Multiple concurrent plays (e.g., firing many bullets) need a Sink pool per source.

8. **Spatial audio** � `ambisonic` crate can 3D-position sounds. However, for a 2D engine, simple pan-left/pan-right based on screen X is usually sufficient and implementable with `rodio::Source::amplify()` on separate L/R channels.

9. **Procedural sound effects** � `sfxr`/`usfx` generate retro sound effects programmatically. Could be exposed as `lurek.audio.newEffect(descriptor)` � interesting for game jams.

**Consideration on switching to `kira`:** `kira 0.12` has significantly better game-audio ergonomics (sequences, tweens, track routing) than `rodio`. Migration would replace `src/audio/mixer.rs` entirely. `kira` uses rodio's `cpal` backend internally. Given rodio's limitations, this is worth evaluating for a future audio module rewrite.

---

### Physics

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `rapier2d` 0.32.0 | 89.6K | 5,219 | Gold standard 2D physics � rigid bodies, joints, convex shapes |
| `rapier3d` 0.32.0 | 183K | 5,219 | 3D counterpart (out of scope for Lurek2D) |
| `collider` 0.3.1 | 479 | 95 | Continuous 2D collision detection only |
| `wrapped2d` 0.4.2 | 883 | 65 | Rust binding for a physics simulation library |
| `nphysics2d` 0.24.0 | 3K | 1,645 | Superseded by rapier2d |
| `salva2d` 0.9.0 | 4.6K | 661 | 2D particle fluid simulation |

**Lurek2D gaps this addresses:**

The current physics module is limited to AABB rectangle bodies. This is sufficient for simple platformers but breaks for any game needing circles, rotated shapes, or joints.

**Option A � Augment native physics:**
- Add circle collision detection (analytical circle-circle and circle-AABB intersection)
- Add friction coefficient to `Body` and apply velocity damping during resolution
- Add angular velocity `f32` field to `Body` and rotate the AABB accordingly
- Add raycast query: iterate bodies and test ray-rect intersection

**Option B � Integrate `rapier2d`:**
- Replace `src/physics/` entirely with a thin wrapper around `rapier2d`
- Lurek2D Lua API would remain identical (`lurek.physics.*`) but backed by rapier
- Supports: circles, convex polygons, rotation, joints, sensors, raycasts, collision groups
- `rapier2d` adds ~400KB to binary size
- Removes the ability to keep physics "pure Rust, no C" � rapier is pure Rust ?
- Main cost: API impedance; rapier uses `RigidBodyHandle`/`ColliderHandle` while Lurek2D uses a flat integer body ID

**Option B is strongly recommended** for any game beyond simplistic demos. The custom AABB engine duplicates work that rapier solves comprehensively.

**rapier2d integration sketch:**

```lua
-- Existing API would remain compatible:
local world = lurek.physics.newWorld(0, -9.8)
local player = lurek.physics.newBody(world, "dynamic", 10, 200, 32, 32)
lurek.physics.step(world, dt)
local x, y = lurek.physics.getBodyPosition(player)

-- New capabilities enabled:
local circle = lurek.physics.newCircleBody(world, "dynamic", 100, 100, 16)  -- radius
local sensor  = lurek.physics.newSensor(world, 50, 50, 32, 32)              -- non-solid trigger
local joint   = lurek.physics.newJoint(world, bodyA, bodyB, "fixed")
local hit     = lurek.physics.raycast(world, x1, y1, x2, y2)               -- returns nil or table
```

---

### ECS (Entity Component System)

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `bevy_ecs` 0.18.1 | 1.1M | 45,219 | Best-in-class; Engine D's core ECS |
| `hecs` 0.11.0 | 56K | 1,259 | Minimal, ergonomic, no magic |
| `specs` 0.20.0 | 70K | 2,602 | Parallel ECS (Engine J-era, still active) |
| `shipyard` 0.11.2 | 13.6K | 840 | All-at-once view API |
| `legion` 0.4.0 | 21K | 1,704 | High-performance, archetype-based |
| `evenio` 0.6.0 | 575 | 149 | Event-driven ECS |
| `flax` 0.7.1 | 211 | 92 | Ergonomic archetypical ECS |

**Lurek2D relationship:**

Lurek2D does not have an ECS. The engine uses a flat shared state model (`SharedState` via `Rc<RefCell<>>`). Whether to add ECS depends on what game developers need.

**Arguments for adding ECS:**

- Game objects (enemies, bullets, tiles) become hard to manage as the game grows
- ECS enables clean separation of data (components) from behavior (systems)
- `hecs` is small, no macros, pure Rust, embeddable � 56K downloads/month signals real use
- Could expose a minimal ECS from Lua: `lurek.ecs.newEntity()`, `lurek.ecs.addComponent(entity, "position", {x=0, y=0})`

**Arguments against native ECS in Lurek2D:**

- Lua's table-based OOP already provides a lightweight entity model
- A Lua-side ECS library (pure Lua tables + metatables) would be simpler than wrapping a Rust ECS through Lua bindings
- Engine D ECS has significant integration cost given its ownership model
- `hecs` entities are `u64` handles � manageable from Lua with a lookup table

**Recommendation:** Implement a lightweight Lua-side entity system first (just a `lurek.ecs` module backed by Lua tables), documented as the canonical approach. Only add a Rust-backed ECS if performance benchmarking reveals the Lua approach as a bottleneck.

---

### Input

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `gilrs` 0.11.1 | 945K | 86 | **Best gamepad library** � cross-platform, SDL-backed |
| `leafwing-input-manager` 0.20.0 | 54K | 912 | Action-based input mapping (Engine D-only) |
| `stick` 0.13.0 | 1.3K | 82 | Async gamepad/joystick library |

**Lurek2D gaps this addresses:**

1. **Gamepad support** � `gilrs` is the obvious choice. `GamepadState` struct exists in `src/input/` but isn't integrated into the minifb event loop. Adding gilrs:
   - Add `gilrs` to `Cargo.toml`
   - Poll `Gilrs::next_event()` in the game loop
   - Update `GamepadState` with button/axis values
   - Expose as `lurek.input.gamepad.*`

2. **Mouse wheel** � `minifb` exposes `Window::get_scroll_xy()` which returns `(f64, f64)`. This already exists in the dependency; just needs to be read in the event loop and propagated to `MouseState`.

3. **Text input** � `minifb` doesn't expose typed characters; this is a known limitation. Migrating the window to `winit` would unlock full IME text input events. This is a medium-effort change requiring engine-layer surgery.

4. **Keyboard modifiers** � minifb exposes `KeyRepeat` and `Key` but not modifier state. The workaround is tracking shift/ctrl/alt keys manually as any other key in `KeyboardState`.

5. **Mouse relative mode** � `minifb` doesn't support cursor lock. This limits first-person style controls. Would require winit or SDL2.

**gilrs integration effort:** Low. About 50 lines of Rust to poll and map gamepad events into the existing `GamepadState` struct.

---

### Math

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `glam` 0.32.1 | 26.6M | 1,917 | Most popular game math, SIMD, Vec2/Vec3/Vec4/Mat3/Mat4 |
| `nalgebra` 0.34.1 | 11.1M | 4,678 | Generic linear algebra, includes n-dim matrices |
| `cgmath` 0.18.0 | 1.3M | 1,198 | Classic graphics math library |
| `euclid` 0.22.14 | 7.9M | 482 | Typed geometry primitives |
| `vek` 0.17.2 | 113K | 308 | Swiss army knife for game math |
| `ultraviolet` 0.10.0 | 125K | 790 | Fast, SIMD-optimized math |
| `palette` 0.7.6 | 1.3M | 810 | Color science: convert, manipulate, perceptual spaces |
| `splines` 5.0.0 | 65K | � | Spline interpolation (Catmull-Rom, Bezier) |
| `noise` 0.9.0 | 253K | 1,056 | Procedural noise (Perlin, Simplex, Worley, Fbm) |

**Lurek2D gaps this addresses:**

Lurek2D has a hand-rolled `Vec2`, `Mat3`, and `Rect`. These are minimal but correct. The question is whether to replace them with `glam` or extend them.

**Case for keeping custom math:**
- No external dependency for math
- Vec2/Mat3/Rect are simple and cover all current use cases
- Avoids forcing `glam` types through FFI with mlua

**Case for adopting `glam`:**
- `glam 0.32` is 26.6M downloads/month � production-grade and battle-tested
- Provides `Vec3`, `Vec4`, `Mat4`, `Quat`, `Affine2`, `Affine3A` � all tested with SIMD
- Most ecosystem crates expect `glam` types; switching now avoids impedance later
- `glam::Vec2` is `#[repr(C)]` � compatible with raw pointer passing

**Additions to implement natively (regardless of glam decision):**

1. **Easing functions** � `ease_in_quad(t)`, `ease_out_cubic(t)`, `ease_in_out_sine(t)`, etc. These are pure Rust math, no crate needed. Expose as `lurek.math.easeIn(t)`, `lurek.math.easeOut(t)`, etc.

2. **Perlin/Simplex noise** � Via `noise` crate or implement a minimal Simplex noise (?80 lines of Rust). Expose as `lurek.math.noise(x, y)` and `lurek.math.noise(x, y, z)`. Critical for procedural generation.

3. **Spline interpolation** � For smooth camera paths, Bezier curves for projectiles etc. `splines` crate handles Catmull-Rom and Bezier cleanly. Alternatively: 4-parameter cubic Bezier can be implemented in ~30 lines.

4. **Color math** � `palette` provides perceptual color blending (LCh, HSLuv). For Lurek2D, a simpler addition would be HSV-RGB conversion on the `Color` struct to enable `lerp_hue()`.

5. **Random number generation** � Current `lurek.math.random()` defers to Lua's `math.random`. A seeded PRNG exposed as `lurek.math.newRandom(seed)` would enable reproducible procedural content.

---

### Animation

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `pareen` 0.3.3 | 65 | 52 | Parameterized tweening (functional, composable) |
| `ozz-animation-rs` 0.11.0 | 344 | 43 | Skeletal animation runtime (ozz-animation port) |
| `natura` � | 72 | Spring animation � natural physics-based motion |

**Also from Tools:**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `keyframe` 1.1.1 | 65.6K | 138 | Easing functions + keyframe animation |

**Lurek2D gaps this addresses:**

Lurek2D has no animation system. The most impactful additions are:

1. **Sprite sheet animation** � Slice a texture into frames (`frames: Vec<Rect>`), advance frame index by `fps * dt`, draw current frame. This is ~50 lines of Lua or Rust, no crate needed. Implement as a `Sprite` extension or a `lurek.animation.newAnim(image, frames, fps)` API.

2. **Tweening** � Smoothly animate any numeric value over time: `lurek.animation.to(target_table, {x=200, y=300}, 1.5, "easeInOut")`. The `keyframe` crate provides easing curves. A tween manager can be implemented entirely in Lua using `lurek.timer.getDelta()`.

3. **Spring animations** � `natura`'s spring model (critically damped spring) creates natural-feeling motion without keyframe data. Very useful for UI bouncing, camera snapping. Pure Rust, ~60 lines.

**Recommendation:** Implement sprite animation and easing functions natively in Lurek2D (both in Rust for the core and Lua examples for usage). Use the `keyframe` crate's easing function definitions as a reference but implement the 12 standard easing curves (linear, quad, cubic, sine, expo, circ, bounce, back, elastic � in/out/inout variants) as pure Rust math in `src/math/`.

---

### Text Rendering

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `fontdue` 0.9.3 | 1.5M | 1,619 | Fast no_std TTF rasterizer, pure Rust, no FreeType |
| `ab_glyph` 0.2.32 | 5.1M | 436 | TTF/OTF glyph loading and rasterization |
| `rusttype` 0.9.3 | 1.3M | � | Older TrueType rasterizer (still widely used) |
| `bmfont` 0.3.3 | 417 | 9 | Bitmap font config parser (.fnt format) |

**Lurek2D current state:**

Lurek2D uses a hardcoded embedded bitmap font for `lurek.render.print()`. It renders ASCII characters only, at a fixed size, with no font choices. This is functional but limiting.

**What to implement:**

1. **TTF font loading via `fontdue`** � `fontdue` is pure Rust, no_std compatible, self-contained. It can rasterize any TTF/OTF glyph to a grayscale bitmap that then gets blitted via `tiny-skia`. Integration steps:
   - Add `fontdue` to `Cargo.toml`
   - Implement `FontAtlas` struct: loads font, rasterizes all printable ASCII at a given `px_size` into a tiny-skia `Pixmap` atlas
   - Store atlas as a `Texture` in the renderer
   - `RenderCommand::Print` variant gains a `font_id: u32` and `size: f32` field
   - Expose via `lurek.render.newFont(path, size)` � handle, `lurek.render.print(text, x, y, font)`

2. **Glyph metrics** � After adding fontdue, expose `lurek.render.getTextWidth(text, font)` and `lurek.render.getTextHeight(font)` for layout calculations.

3. **Bitmap font parser (.fnt)** � `bmfont` crate parses Angelcode .fnt atlas format. This allows designers to use tools like Hiero or Littera to generate custom pixel-art fonts, which get loaded at runtime. Complements TTF for retro aesthetics.

**`fontdue` vs `ab_glyph`:**
- `fontdue` rasterizes entire glyphs to bitmaps � perfect for tiny-skia (we blit the bitmap into the Pixmap)
- `ab_glyph` provides glyph outlines + rasterization � more flexible but more code
- For Lurek2D's software renderer, `fontdue` is the better fit

---

### Scripting Languages

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `mlua` 0.11.6 | 637K | 2,637 | **Already used** � Lua 5.4, vendored, async support |
| `rhai` 1.24.0 | 1.1M | 5,229 | Embedded scripting in Rust, no_std support |
| `rune` 0.14.1 | 11K | 2,174 | Dynamic Rust-like scripting language |
| `gluon` 0.18.2 | 1K | 3,391 | Statically-typed ML-like embedded language |
| `mun` � | 2,111 | Statically-typed hot-reload scripting |

**Lurek2D relationship:**

Lurek2D is specifically designed around Lua (inspired by a similar game engine). The `mlua` crate version `0.11.6` is current and well-maintained. The scripting language is not up for replacement.

**Interesting alternatives (for documentation purposes):**

- `rhai` would make sense if Lurek2D wanted to drop the Lua dependency and use a Rust-native scripting language. Rhai has a similar API philosophy but Lua's ecosystem (Luarocks modules, prevalence in game tools, a similar game engine compatibility for comparison) makes it harder to justify.
- `mun` uses ahead-of-time compilation with hot reload � could improve performance for scripting-heavy games, but requires a separate language and toolchain.

**Recommendation:** Keep mlua. Consider documenting how to add Lua standard library extensions (e.g., fennel transpiler, teal type checker) as optional overlays.

---

### Networking

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `quinn` 0.11.9 | 39.3M | 4,981 | QUIC transport protocol |
| `renet` 2.0.0 | 28K | 897 | Client-server multiplayer with auth |
| `ggrs` 0.11.1 | 12.3K | 637 | P2P rollback netcode (GGPO port) |
| `matchbox_socket` 0.14.0 | 10.9K | 1,118 | WebRTC P2P (including WASM) |
| `laminar` 0.5.0 | 22.7K | 867 | Semi-reliable UDP |
| `lightyear` 0.26.4 | 8.1K | 953 | Engine D-specific server-client networking |
| `message-io` 0.19.0 | 10K | 1,194 | Event-driven multi-transport networking |

**Lurek2D relationship:**

Lurek2D has no networking. This is intentional � single-player games are the primary target.

**Considerations for adding networking:**

- A `lurek.network` module with socket-level TCP/UDP would cover most use cases
- `message-io` provides a clean event-driven API over TCP/UDP/websocket � wrappable around Lua callbacks
- `renet` provides higher-level game networking (auth, channels, reliability) but has dependencies
- `ggrs` rollback netcode is the gold standard for fighting games and precise multiplayer � very complex to integrate
- Recommendation: Add a minimal UDP socket via `std::net::UdpSocket` as a first pass before introducing crate dependencies

**WASM note:** `matchbox_socket` enables WebRTC P2P that works in both native and WASM builds. If Lurek2D ever targets browsers, this becomes the networking answer.

---

### UI

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `egui` 0.33.3 | 3.0M | 28,469 | Immediate mode GUI, easy to integrate |
| `iced` 0.14.0 | 290K | 29,927 | Elm-inspired retained-mode GUI |
| `imgui` 0.12.0 | 34K | 2,978 | C dear imgui bindings |
| `yakui` 0.3.0 | 11.4K | 316 | UI library specifically for games |
| `raui` 0.70.17 | 569 | 410 | Renderer-agnostic UI |

**Lurek2D relationship:**

Lurek2D has no UI library. In-game UI (health bars, buttons, menus) is built manually with shape drawing. A developer tooling/debug overlay is also absent.

**Two distinct use cases:**

**A) In-game UI for game developers:**
- Simple panel/button/text primitives
- Should work with the existing RenderCommand queue
- Best approach: implement a `lurek.ui` Lua module built on top of existing `lurek.render.*` primitives
- No Rust crate needed � pure Lua

**B) Developer tools / debug overlay:**
- Runtime inspection of game state, tweak variables
- `egui` is the obvious choice: 3M downloads/month, integrates easily over any pixel buffer
- `egui` can render to a `Pixmap` via `egui-skia` or by blitting egui's output texture onto the frame
- Could power a `lurek.debug` module: print variables on screen, tweak numbers live, visualize physics bodies
- `inline_tweak` crate (8.4K downloads/month) is simpler � tweak numeric constants by changing source and hot-reloading; good for game feel tuning

**Recommendation:** Add `egui` as an optional debug-mode feature (`--features debug-ui`). This won't affect release builds but gives developers live inspection tools.

---

### AI

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `pathfinding` 4.15.0 | 218K | 1,044 | A*, Dijkstra, BFS, DFS, Fringe |
| `bonsai-bt` 0.11.0 | 6.9K | 439 | Behavior trees |
| `big-brain` 0.22.0 | 1.9K | 1,291 | Utility AI (Engine D-specific) |
| `navmesh` 0.12.1 | 1.1K | 53 | Nav meshes + path following |

**Lurek2D relationship:**

No AI subsystem exists. Game AI logic is implemented in Lua scripts.

**What to add:**

1. **Pathfinding** � The `pathfinding` crate's `astar` is pure Rust, no external dependencies, framework-independent. Exposing it to Lua as `lurek.pathfind.astar(grid, start, goal)` would be high value for top-down RPGs, tower defense, etc.
   - Input: a Lua table as 2D grid, start/goal as {x, y} tables
   - Output: a Lua array of {x, y} waypoints
   - Estimated implementation: 80 lines of Rust binding code

2. **Behavior trees** � `bonsai-bt` is general enough to work outside Engine D. Could be used from Rust, with Lua-defined action callbacks. High complexity to expose through Lua FFI.

3. **Steering behaviors** � Seek, flee, arrive, wander, avoid � pure Rust math on `Vec2`. Simple to implement natively in ~200 lines without any crate. Expose as `lurek.ai.seek(position, target, speed)` � `Vec2`.

**Recommendation:** Add pathfinding first via `pathfinding` crate (A*). Steering behaviors should be implemented natively. Behavior trees are optional tooling.

---

### Shaders

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `naga` 29.0.0 | 4.6M | 16,732 | WGSL/GLSL/HLSL/SPIR-V translator |
| `wgpu` 29.0.0 | 4.2M | 16,732 | WebGPU API (shader-capable) |
| `shaderc` 0.10.1 | 181K | 285 | Vulkan shader compiler |

**Lurek2D relationship:**

Lurek2D is a software renderer � it does not use GPU shaders. All shading is done by tiny-skia's CPU-side paint operations.

**What is possible within the software model:**

1. **Custom pixel effects (software shaders)** � Since Lurek2D owns the raw u32 pixel buffer, it can apply per-pixel transformations post-rendering:
   - Grayscale: `for pixel in buffer { apply_grayscale(pixel) }`
   - Scanlines/CRT effect: darken every even row
   - Color grading: LUT-based color remapping
   - Vignette: darken edges by distance from center
   - Pixelate: downsample, upsample
   These can be exposed as `lurek.render.setPostProcess("grayscale")` or via a Lua-defined function invoked per-pixel.

2. **tiny-skia Paint operations** � `tiny-skia` supports `BlendMode` (multiple blend equations) and `FilterQuality`. No GPU needed; these are all CPU-side effects.

**GPU shader note:** Adding wgpu-based rendering is a major architectural investment. The reference analysis in `docs/technical/postfx.md` and `docs/technical/graphics_ext.md` likely cover this. It would unlock real-time shaders but require replacing tiny-skia with a GPU pipeline. This is a multi-month effort and would break backward compatibility with software-renderer assumptions.

---

### Tools

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `tiled` 0.15.0 | 23.4K | 294 | Load Tiled map editor .tmx files |
| `assets_manager` 0.13.8 | 6K | 161 | Asset loading + hot reloading |
| `noise` 0.9.0 | 253K | 1,056 | Procedural noise generation |
| `keyframe` 1.1.1 | 65.6K | 138 | Easing functions + keyframe animation |
| `aseprite` 0.1.3 | 772 | 32 | Load pixel art tools sprite animation files |
| `hex2d` 1.1.0 | 1.5K | 65 | Hexagonal grid math |
| `rectangle-pack` 0.4.2 | 690K | 82 | Texture atlas packing |
| `inline_tweak` 1.2.4 | 8.4K | 203 | Live value tweaking at runtime |
| `modio` 0.14.2 | 475 | 22 | mod.io modding platform integration |
| `profiling` 1.0.17 | 8.7M | 390 | Thin profiler crate abstraction |

**Lurek2D gaps this addresses:**

1. **Tiled map loading** � The `tiled` crate loads `.tmx` XML files from the Tiled Map Editor (industry-standard tilemap tool). This would enable `lurek.tilemap.load("level1.tmx")` for instant level design workflows.

2. **Asset hot reload** � `assets_manager` watches file changes and reloads assets automatically. Combined with a live Lua script reload, this would dramatically speed up game development iteration.

3. **Procedural noise** � `noise` crate provides Perlin, Simplex, Worley, Value, and fractal combinations. Essential for terrain generation, texture variation, AI wandering. Expose as `lurek.math.perlin(x, y, seed)`.

4. **Texture atlas packing** � `rectangle-pack` bins rectangles optimally. Useful for baking multiple sprites into a single texture and reducing draw calls.

5. **Profiling** � `profiling` crate adds `profiling::scope!("name")` annotations that integrate with Superluminal, Tracy, or Chrome tracing. Valuable for performance debugging.

6. **pixel art tools loading** � `aseprite` crate loads `.ase`/`.aseprite` files including animation frames, layers, and tags. Since many pixel artists use pixel art tools, this would be valuable: `lurek.render.newAnimFrompixel art tools("hero.aseprite")`.

---

### Windowing

**Ecosystem crates (active, notable):**

| Crate | Downloads/mo | Stars | Notes |
|-------|-------------|-------|-------|
| `winit` 0.30.13 | 6.1M | 5,883 | The most widely used Rust windowing library |
| `minifb` 0.28.0 | 670K | 1,177 | **Already used** � simple pixel buffer window |
| `sdl2` 0.38.0 | 755K | 2,939 | SDL2 bindings � mature C library |
| `sdl3` 0.17.3 | 18K | 323 | SDL3 bindings (new main branch) |
| `softbuffer` 0.4.8 | 2.9M | 474 | Software buffer via winit |
| `glutin` 0.32.3 | 3.8M | 2,078 | OpenGL context + window |

**Lurek2D relationship:**

Lurek2D uses `minifb 0.27`. `minifb 0.28.0` (latest) added improvements. The windowing layer is adequate for the current software-rendering model.

**Migration considerations:**

- **To `winit` + `softbuffer`:** This is the "modern" approach � winit handles windowing/input/events, softbuffer provides the pixel buffer. Would unlock text input (IME), mouse wheel, multi-window, and DPI awareness. Downside: more code to maintain.
- **To `sdl2`/`sdl3`:** SDL provides a complete multimedia layer (window + input + audio + joystick). Could replace both `minifb` and `rodio` with a single dependency tree. However, SDL requires native C library linking (complicates build).
- **Stay with `minifb`:** Simple, single-file integration, adequate for current feature set. Known limitation: no scroll wheel, no text events, no cursor locking.

**Recommendation:** Pin `minifb` upgrade to `0.28.0` for bug fixes. Plan a future migration to `winit` + `softbuffer` if text input or DPI scaling becomes a requirement. Document the migration path but don't execute prematurely.

---

## Prioritized Implementation Roadmap

The following is a prioritized backlog of features to add to Lurek2D, ordered by impact � effort.

### Priority 1 � High Impact, Low Effort

| Feature | Effort | Impact | Module | Crate/Approach |
|---------|--------|--------|--------|---------------|
| Mouse wheel support | 1h | High | Input | `minifb::Window::get_scroll_xy()` already exists |
| Audio loop + pause/resume | 2h | High | Audio | `rodio::Sink::pause()` / `Sink::repeat_infinite()` |
| Gamepad exposure to Lua | 4h | High | Input + Lua | Expose existing `GamepadState` via `lurek.input.gamepad.*` |
| Camera integration in renderer | 4h | High | Graphics | Apply `camera.view_matrix()` in `Renderer::flush()` |
| Draw layer Z-ordering | 4h | High | Graphics | Add `RenderCommand::SetLayer(i32)`, sort in `flush()` |
| gilrs gamepad polling | 8h | High | Input | Add `gilrs` crate, poll in game loop |
| Audio pitch control | 2h | Medium | Audio | `rodio::Source::speed(ratio)` |
| Easing functions | 4h | High | Math | Native Rust math, expose via `lurek.math.*` |

### Priority 2 � High Impact, Medium Effort

| Feature | Effort | Impact | Module | Crate/Approach |
|---------|--------|--------|--------|---------------|
| TTF font rendering | 2�3 days | High | Graphics | `fontdue` crate, FontAtlas texture |
| Sprite sheet animation | 1 day | High | Graphics | New `Animation` type, Lua API |
| Perlin/Simplex noise | 1 day | Medium | Math | `noise` crate or custom 80-line impl |
| rapier2d physics | 1 week | High | Physics | Replace/wrap existing physics module |
| Procedural sound fx | 1 day | Medium | Audio | `sfxr` or `usfx` crate integration |
| Tiled map loading | 2 days | High | Lua API | `tiled` crate, new `lurek.tilemap.*` |
| More blend modes | 1 day | Medium | Graphics | Expose `tiny-skia` BlendMode in Lua |

### Priority 3 � Medium Impact, Medium Effort

| Feature | Effort | Impact | Module | Crate/Approach |
|---------|--------|--------|--------|---------------|
| pixel art tools loader | 2 days | Medium | Graphics | `aseprite` crate |
| Pathfinding (A*) | 2 days | Medium | AI | `pathfinding` crate, Lua grid API |
| kira audio upgrade | 1 week | High | Audio | Replace rodio with kira for richer audio |
| Spring animation | 1 day | Medium | Math | Port `natura` spring model |
| Asset hot reload | 3 days | High | Filesystem | `assets_manager` crate |
| render-to-texture | 3 days | Medium | Graphics | Offscreen Pixmap, new RenderCommand variants |

### Priority 4 � Stretch Goals

| Feature | Effort | Impact | Module | Crate/Approach |
|---------|--------|--------|--------|---------------|
| Networking (UDP socket) | 1 week | Low-Med | New module | `std::net::UdpSocket` + lua bindings |
| Behavior trees | 2 weeks | Low | AI | `bonsai-bt` crate or native impl |
| Debug egui overlay | 1 week | Medium | Dev tools | `egui` crate, optional feature |
| GPU rendering (wgpu) | 2+ months | Very High | Graphics | Architecture rewrite |
| ECS backend | 2+ weeks | Medium | New module | `hecs` crate |
| WASM target | 1+ month | High | Engine | Requires winit + wasm-pack |

---

## Crates Worth Integrating Directly

These crates have clear integration paths and would meaningfully close current gaps:

| Crate | Version | Purpose | Why Lurek2D |
|-------|---------|---------|-----------|
| `gilrs` | 0.11 | Gamepad input | `GamepadState` exists, needs backend |
| `fontdue` | 0.9 | TTF font rasterizer | Zero C deps, perfect for tiny-skia blit model |
| `noise` | 0.9 | Procedural noise | Essential for World generation, animation variation |
| `keyframe` | 1.1 | Easing curves | Clean API, produces `f32` outputs directly usable in Lua |
| `tiled` | 0.15 | Tiled .tmx loader | Level design standard format |
| `aseprite` | 0.1 | pixel art tools sprite loader | Pixel artist's standard tool |
| `pathfinding` | 4.15 | A* + graph algorithms | No_std, pure Rust, composable |
| `rapier2d` | 0.32 | Full physics engine | Pure Rust, replaces custom AABB |
| `kira` | 0.12 | Expressive game audio | Supersedes rodio for game use cases |
| `profiling` | 1.0 | Performance profiling | Thin abstraction, zero overhead in release |

---

## Features Lurek2D Should Build Natively

These features are well within Lurek2D's own design space and should be implemented in-house rather than through external crates. They are small enough to control fully and important enough to design for the `lurek.*` API specifically:

1. **Sprite shader callbacks** � A Lua-callable per-pixel hook on a region of the screen
2. **Spring animation** � ~60-line port of `natura`'s spring model
3. **Easing functions** � 12 standard curves, pure math
4. **Scene management skeleton** � A `lurek.scene` module that manages screen transitions
5. **In-game debug overlay** � Print variables on screen without a full UI framework
6. **Tween manager** � Supported by Lua tables + `lurek.timer.getDelta()`
7. **Basic steering AI** � Seek/flee/arrive implemented as `Vec2`-returning functions
8. **9-slice rendering** � 9 `DrawImage` calls, no new RenderCommand needed
9. **`lurek.math.clamp()`, `lerp()`, `map()` extensions** � Small but commonly needed
10. **Simple particle system** � `ParticleEmitter` struct with position/velocity/lifetime table

---

## Out of Scope for Lurek2D

These ecosystem areas are architecturally incompatible with Lurek2D's design goals (2D, software-rendered, Lua-scripted) or require major rewrites:

| Area | Reason |
|------|--------|
| 3D rendering (wgpu, three-d, rafx) | Lurek2D is 2D-only by design |
| GPU shaders (naga, shaderc, rust-gpu) | No GPU pipeline; incompatible with tiny-skia model |
| VR (openxr, Engine C-rust) | Out of 2D engine scope |
| 3D physics (rapier3d, physx, nphysics3d) | 3D is out of scope |
| Engine D ECS (bevy_ecs) | Engine D's ECS tightly couples to its entire framework |
| Full game engines (Engine D, Engine K, Engine C-rust) | Lurek2D IS a game engine; these are competitors |
| 3D format loaders (gltf, obj) | No 3D mesh support in scope |
| Skeletal animation (ozz-animation-rs) | Requires 3D/mesh pipeline |
| HLSL/GLSL shader compilation | No GPU targets |
| Alternative scripting languages (rhai, rune, gluon) | Lua is the language contract |

---

*Generated by research from arewegameyet.rs (2026-03-23 snapshot) cross-referenced against Lurek2D src/ module exploration. Crate versions and download numbers reflect March 2026 data.*
