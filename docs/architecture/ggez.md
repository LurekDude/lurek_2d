# ggez — Architectural Analysis

> **Source**: `references/ggez/` | **Language**: Rust | **Scripting**: None (native Rust API) | **License**: MIT

## Overview

ggez is a Rust game framework inspired by Love2D, aiming to provide a "lightweight game framework for making 2D games with minimum friction." It is the closest architectural reference to Luna2D in the Rust ecosystem, sharing the same Love2D-inspired design philosophy but implemented as a pure Rust library (no Lua scripting). Originally created by Simon Heath (icefox), ggez uses wgpu for rendering, winit for windowing, and rodio for audio — the same technology stack as Luna2D.

## Core Design Principles

1. **EventHandler Trait** — Games implement a Rust trait with `update(&mut self, ctx)` and `draw(&mut self, ctx)` methods plus optional input callbacks. This is the Rust equivalent of Love2D's callback model.

2. **Context as Subsystem Container** — A single `Context` struct holds all engine subsystems: graphics, audio, input, filesystem, timer. Passed as `&mut` to every callback. No global state.

3. **Canvas-Based Rendering** — Drawing happens on a `Canvas` (render pass). `Canvas::from_frame(ctx, color)` for the screen. `Canvas::from_image(ctx, image)` for offscreen. `canvas.draw(&drawable, params)` renders.

4. **DrawParam Builder** — All draw operations use `DrawParam` for position, rotation, scale, offset (anchor point), color, and z-index. Builder pattern with chaining: `DrawParam::new().dest(pos).rotation(angle)`.

5. **Trait-Based Drawables** — `Drawable` trait implemented by `Mesh`, `Image`, `Text`, `InstanceArray`, `Canvas`. Uniform drawing API regardless of object type.

6. **GameError Enum** — Comprehensive error handling with a `GameError` enum (30+ variants) and `GameResult<T>` type alias. All fallible operations return `Result`.

7. **Virtual Filesystem (VFS)** — `OverlayFS` with multiple search paths: `resources/` folder, `.zip` archives, and user data directory. Sandboxed file access with no raw OS paths.

8. **Builder Pattern Configuration** — `ContextBuilder::new("game", "author").window_mode(wm).build()` configures the entire engine. Optional modules can be disabled.

9. **Feature-Gated Optional Modules** — Gamepad support requires `gamepad` feature flag (depends on gilrs). Audio can be optionally excluded.

10. **Z-Index Draw Ordering** — Canvas tracks z-index per draw call. Draw order determined by z-value, then submission order. Enables out-of-order drawing with correct layering.

11. **Image-Based Texture System** — `Image` wraps a GPU texture. Created from file paths or raw pixel data. Supports nearest/linear filtering, wrap modes.

12. **Mesh with Lyon Tessellation** — `Mesh` type for custom geometry. Lyon crate tessellates filled and stroked shapes. Circle, rectangle, polygon, rounded rectangle primitives.

13. **InstanceArray for Batching** — `InstanceArray` batches many draws of the same image with different transforms. GPU instanced rendering for sprites.

14. **Text with glyph_brush** — `Text` type wraps glyph_brush for font rendering. Multiple text fragments with different fonts/colors/sizes in one text object.

15. **Pipeline Caching** — Render pipelines cached by (shader, blend mode, texture format) key. Avoids redundant pipeline creation per frame.

## Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User Game (impl EventHandler)                           │
│  fn update(&mut self, ctx: &mut Context) → GameResult    │
│  fn draw(&mut self, ctx: &mut Context) → GameResult      │
│  fn key_down_event(...), fn mouse_button_down_event(...) │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  ggez::event::run(ctx, event_loop, game)                 │
│  winit EventLoop → dispatch to EventHandler methods      │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Context (subsystem container, passed as &mut)            │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ gfx      │ audio    │ time     │  fs      │          │
│  │(Graphics │(Audio    │(Timer    │(Overlay  │          │
│  │ Context) │ Context) │ Context) │  FS)     │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │ keyboard │  mouse   │ gamepad  │ conf     │          │
│  │(Keyboard │(Mouse    │(Gamepad  │(settings,│          │
│  │ Context) │ Context) │ Context) │ quit)    │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Rendering (Canvas → DrawQueue → wgpu RenderPass)        │
│  ┌──────────────────────────────────────────────┐       │
│  │ Canvas (render target: screen or Image)       │       │
│  │  .draw(&Drawable, DrawParam)                  │       │
│  │  → DrawQueue (z-sorted draw commands)         │       │
│  │  → Pipeline cache (shader+blend+format key)   │       │
│  │  → wgpu: bind groups, vertex uploads, passes  │       │
│  └──────────────────────────────────────────────┘       │
│  Drawables: Image | Mesh | Text | InstanceArray          │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Dependencies                                            │
│  wgpu 26 | winit 0.30 | lyon 1.0 | glam 0.30           │
│  rodio 0.21 | gilrs 0.11 | glyph_brush 0.7 | image 0.25│
└─────────────────────────────────────────────────────────┘
```

### EventHandler Trait

```rust
pub trait EventHandler<E = GameError> {
    fn update(&mut self, ctx: &mut Context) -> Result<(), E>;
    fn draw(&mut self, ctx: &mut Context) -> Result<(), E>;

    // Optional callbacks with default no-op implementations
    fn key_down_event(&mut self, ctx: &mut Context, input: KeyInput, repeated: bool) -> Result<(), E> { Ok(()) }
    fn mouse_button_down_event(&mut self, ctx: &mut Context, btn: MouseButton, x: f32, y: f32) -> Result<(), E> { Ok(()) }
    fn gamepad_button_down_event(&mut self, ctx: &mut Context, btn: GamepadButton, id: GamepadId) -> Result<(), E> { Ok(()) }
    fn resize_event(&mut self, ctx: &mut Context, w: f32, h: f32) -> Result<(), E> { Ok(()) }
    fn on_error(&mut self, ctx: &mut Context, origin: &str, e: E) -> bool { true } // true = crash
    // ... 15+ more callbacks
}
```

### Canvas Drawing

```rust
fn draw(&mut self, ctx: &mut Context) -> GameResult {
    let mut canvas = Canvas::from_frame(ctx, Color::BLACK);

    // Draw image at position
    canvas.draw(&self.image, DrawParam::new().dest([100.0, 200.0]));

    // Draw with rotation and scale
    canvas.draw(&self.sprite, DrawParam::new()
        .dest([400.0, 300.0])
        .rotation(self.angle)
        .scale([2.0, 2.0])
        .offset([0.5, 0.5])  // center anchor
    );

    // Draw mesh
    canvas.draw(&self.mesh, DrawParam::default());

    // Draw text
    canvas.draw(&self.text, DrawParam::new().dest([10.0, 10.0]).color(Color::WHITE));

    // Finish and present
    canvas.finish(ctx)?;
    Ok(())
}
```

## Focus & Target Audience

- **Rust developers** wanting to make 2D games without C/C++ dependencies
- **Love2D users** familiar with the callback model who want Rust performance and safety
- **Prototypers** who need a quick path from idea to running game in Rust
- **Framework users** — ggez is a framework, not an engine. Users build game systems on top.

## Strong Points

| Strength | Details |
|----------|---------|
| **Same tech stack as Luna2D** | wgpu, winit, rodio, gilrs — identical dependencies. Proven architecture for Luna2D to study. |
| **EventHandler trait** | Clean Rust API for game callbacks. Default implementations for all optional handlers. |
| **Canvas abstraction** | Unified draw target for screen and offscreen rendering. Z-index sorting. |
| **DrawParam builder** | Ergonomic, chainable draw parameters. One type for all drawable customization. |
| **Comprehensive error handling** | `GameError` enum covers every failure mode. No panics in library code. |
| **VFS filesystem** | Overlay filesystem with zip support. Sandboxed. Excellent model for game data management. |
| **Pipeline caching** | Render pipeline reuse by (shader, blend, format) key. Avoids per-frame GPU pipeline creation. |
| **Built-in primitives** | Lyon tessellation for circles, rectangles, polygons. No manual vertex construction needed. |
| **InstanceArray** | GPU instanced rendering for sprite batching. Orders of magnitude faster than individual draws. |
| **Clean Rust idioms** | Builder pattern, trait objects, Result types, feature gates — idiomatic Rust throughout. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **No scripting** | Pure Rust — every game is a compiled binary. No Lua or other scripting support. |
| **`&mut Context` everywhere** | Every operation requires `&mut Context` reference. Verbose function signatures. |
| **No scene management** | Like Love2D, no built-in scene/state machine. |
| **Limited shader API** | Custom shaders require manual wgpu pipeline setup. Less accessible than Love2D's GLSL shaders. |
| **No audio effects** | Basic playback only. No filters, spatial audio, or audio graphs. |
| **Maintenance concerns** | Development pace has slowed. Breaking changes between major versions (0.5 → 0.6 → 0.7 → 0.8 → 0.9). |
| **No physics** | No built-in physics module. Users must integrate rapier or other crates manually. |
| **Text rendering complexity** | glyph_brush integration works but is complex. Font loading, fragment building, and cache management. |
| **Desktop only** | No mobile or web targets. Focus on Windows/macOS/Linux. |

## Things to Reimplement in Luna2D

### High Priority — Direct Reference

1. **Canvas/Render Target Pattern** — ggez's `Canvas::from_frame()` / `Canvas::from_image()` with `canvas.draw()` is the right abstraction for Luna2D's rendering. Map to `luna.graphics.setCanvas()` on the Lua side.

2. **DrawParam Pattern** — Position, rotation, scale, offset, color as a parameter struct. Luna2D's draw commands should use a similar approach, exposed as optional Lua table arguments.

3. **Pipeline Caching** — Cache GPU render pipelines by (shader, blend mode, texture format) key. Essential for wgpu performance. Luna2D should adopt this directly.

4. **VFS / Overlay Filesystem** — Sandboxed filesystem with search paths. Luna2D's `GameFS` should support overlay paths like ggez: game resources, user data directory, zip archives.

5. **InstanceArray Batching** — GPU instanced rendering for many sprites with the same texture. Luna2D should support `luna.graphics.newSpriteBatch()` backed by instance arrays.

6. **GameError Enum Pattern** — Comprehensive error enum with `From` impls for conversion. Luna2D's `EngineError` should follow ggez's pattern for error categorization.

### Medium Priority — Worth Adapting

7. **Z-Index Draw Ordering** — Allow specifying z-index on draw calls for correct layering without manual draw order management.

8. **Lyon Tessellation** — Use lyon for filled/stroked shapes (circles, polygons, rounded rects). Avoids hand-rolling vertex generation.

9. **Feature-Gated Modules** — Optional modules via Cargo features (e.g., gamepad support). Keeps the default build smaller.

10. **Context Builder Pattern** — `ContextBuilder::new().window_mode(...).build()` for configuration. Luna2D could use a similar pattern for engine initialization from Rust side.

### Lower Priority

11. **Image filtering/wrapping** — Per-image nearest/linear filter and clamp/repeat wrap mode settings.

12. **MSAA Canvas** — Multi-sample anti-aliasing render targets.

## Things to Avoid

1. **No Scripting** — ggez's biggest limitation for game development. Luna2D's Lua scripting is a major advantage. Don't adopt ggez's "compile everything" model.

2. **`&mut Context` Passing** — ggez passes `&mut Context` to every function. This works in Rust but would be clunky through a Lua FFI. Luna2D rightly uses `Rc<RefCell<SharedState>>` with Lua closures instead.

3. **Drawable Trait Complexity** — ggez's `Drawable` trait requires implementing `draw()` and `dimensions()`. For Lua bindings, function-based drawing (`luna.graphics.draw(image, x, y)`) is simpler.

4. **Breaking Version Changes** — ggez has had significant API breaks between versions (Canvas API changed completely in 0.8→0.9). Luna2D should stabilize its API early and maintain backward compatibility.

5. **Desktop-Only Target** — ggez doesn't support mobile or web. Luna2D should keep future platform expansion in mind even while focusing on desktop.

6. **Complex Text API** — ggez's `TextFragment` + `TextLayout` API is powerful but complex. Luna2D should provide a simpler `luna.graphics.print(text, x, y)` (like Love2D) with advanced options as optional.

## Luna2D Integration Notes

ggez is **the most architecturally relevant reference** for Luna2D because they share the same stack:

| Component | ggez | Luna2D |
|-----------|------|--------|
| Rendering | wgpu 26 | wgpu 22 |
| Windowing | winit 0.30 | winit 0.30 |
| Audio | rodio 0.21 | rodio 0.17 |
| Gamepad | gilrs 0.11 | gilrs (planned) |
| Math | glam 0.30 | Custom Vec2/Mat3 |
| Image | image 0.25 | image 0.24 |

Key architecture differences:

- **ggez is a library** (user writes Rust) vs. **Luna2D is an engine** (user writes Lua). This fundamentally changes the API surface design.
- **ggez uses `&mut Context`** for borrow-checked state access vs. **Luna2D uses `Rc<RefCell<SharedState>>`** for Lua closure compatibility.
- **ggez uses the Drawable trait** vs. **Luna2D uses DrawCommand enum** for a queue-based approach.
- **ggez has no physics** vs. **Luna2D has built-in AABB physics**.

The primary learnings from ggez for Luna2D:
1. **Pipeline caching strategy** — essential for wgpu performance
2. **Canvas/render target abstraction** — clean API for offscreen rendering
3. **VFS overlay filesystem** — proper sandboxed game file access
4. **Error handling patterns** — comprehensive GameError enum
5. **Instance array batching** — GPU-accelerated sprite batching
