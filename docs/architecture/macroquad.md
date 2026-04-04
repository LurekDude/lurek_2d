# macroquad — Architectural Analysis

> **Source**: `references/macroquad/` | **Language**: Rust | **Scripting**: None (native Rust API) | **License**: MIT/Apache-2.0

## Overview

macroquad is a minimalist Rust game library created by Fedor Logachev, designed for maximum simplicity and fast iteration. It uses global unsafe state, an async main pattern, and immediate-mode rendering to provide a "raylib-like" experience in Rust. The library prioritizes zero-boilerplate game development with minimal dependencies, compiling a clean project in ~16 seconds. It trades Rust safety conventions for ergonomics, targeting rapid prototyping and cross-platform deployment (desktop, mobile, WASM).

## Core Design Principles

1. **Global Unsafe State** — Thread-local `static CONTEXT` holding all engine state. `get_context()` accessor avoids borrow checker. All draw functions access state implicitly — no context parameter needed.

2. **Async Main Pattern** — `#[macroquad::main("Title")] async fn main()` wraps the game loop. `next_frame().await` yields to the engine for event processing and frame presentation. Game loop is a natural `loop {}` in Lua-like style.

3. **Immediate-Mode Rendering** — `draw_rectangle(x, y, w, h, color)` draws immediately. No retained objects, no scene graph, no draw command queue. Every frame starts fresh.

4. **Zero Boilerplate** — Minimal code to get something on screen. No struct, no trait implementation, no configuration. Just call draw functions in a loop.

5. **Automatic Batching** — QuadGl batches consecutive draw calls with the same texture/shader/pipeline into single GPU submissions. Transparent to the user.

6. **Miniquad Backend** — Uses miniquad as the platform/rendering backend (OpenGL ES 2.0/3.0, WebGL 1/2, Metal). Extremely portable, minimal dependencies.

7. **Managed Textures** — `TextureHandle` uses `Managed(Arc)` / `ManagedWeak` / `Unmanaged` variants. Automatic garbage collection reclaims unused textures per frame.

8. **Feature-Gated Audio** — Audio via `macroquad-audio` crate (wraps `quad-snd`) behind a feature flag. Minimal by default.

9. **Subcrate Organization** — Related functionality split into subcrates: `macroquad-particles`, `macroquad-platformer`, `macroquad-tiled`. Users opt in to only what they need.

10. **Event Buffering** — Input events buffered per frame. `is_key_pressed()` / `is_key_down()` / `is_key_released()` query buffered state. No callbacks.

11. **Cross-Platform from Day One** — WASM, iOS, Android, Windows, macOS, Linux all supported. miniquad handles platform abstraction.

12. **Minimal Dependencies** — Dependency tree is intentionally small. miniquad 0.4, glam 0.27, image 0.24, fontdue 0.9. Clean builds are fast.

13. **No Callbacks** — Unlike Love2D/ggez, macroquad uses polling instead of callbacks. No `on_key_pressed` — just check `is_key_pressed("space")` each frame.

14. **Coroutine-Based Sequencing** — `async/await` enables sequential game logic (level loading, cutscenes, dialogs) without state machines. `load_texture("path").await` for async loading.

15. **UI Module** — Built-in immediate-mode UI: `root_ui().window()`, buttons, text inputs, sliders. Based on megaui.

## Core Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User Game                                               │
│  #[macroquad::main("Title")]                             │
│  async fn main() {                                       │
│      loop {                                              │
│          // update logic                                 │
│          draw_*();      // immediate-mode rendering      │
│          next_frame().await;  // yield to engine          │
│      }                                                   │
│  }                                                       │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Global State (unsafe static CONTEXT, thread_assert)     │
│  get_context() → &mut Context                            │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ screen   │ quad_gl  │ input    │  camera  │          │
│  │(size,dpi)│(batched  │(keys,   │(active   │          │
│  │          │ draw)    │ mouse,  │ camera)  │          │
│  │          │          │ touch)  │          │          │
│  ├──────────┼──────────┼──────────┼──────────┤          │
│  │ textures │  fonts   │  audio  │ storage  │          │
│  │(managed, │(fontdue) │(quad_   │(cookie   │          │
│  │ GC'd)   │          │ snd)    │ based)   │          │
│  └──────────┴──────────┴──────────┴──────────┘          │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  QuadGl (batched rendering)                              │
│  DrawCall { vertices, indices, texture, model, pipeline }│
│  Auto-batch: same texture+pipeline → merge               │
│  Flush on state change or frame end                      │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  miniquad (platform + GPU backend)                       │
│  OpenGL ES 2.0/3.0 | WebGL 1/2 | Metal                  │
│  Window | Input | Audio | File I/O                       │
│  ┌──────────┬──────────┬──────────┐                     │
│  │ Windows  │  macOS   │  WASM   │                     │
│  │ Linux    │  iOS     │ Android │                     │
│  └──────────┴──────────┴──────────┘                     │
└─────────────────────────────────────────────────────────┘
```

### Async Main Pattern

```rust
use macroquad::prelude::*;

#[macroquad::main("Game")]
async fn main() {
    // Load assets (async)
    let texture = load_texture("player.png").await.unwrap();

    let mut x = 100.0;
    let mut y = 100.0;

    loop {
        // Update
        if is_key_down(KeyCode::Right) { x += 200.0 * get_frame_time(); }
        if is_key_down(KeyCode::Left)  { x -= 200.0 * get_frame_time(); }

        // Draw
        clear_background(BLACK);
        draw_texture(&texture, x, y, WHITE);
        draw_rectangle(50.0, 50.0, 100.0, 50.0, RED);
        draw_text("Hello!", 20.0, 20.0, 30.0, GREEN);

        next_frame().await;
    }
}
```

### Automatic Batching

```rust
// These three draws are batched into ONE GPU call
// (same texture, same pipeline)
draw_texture(&atlas, 100.0, 100.0, WHITE);
draw_texture(&atlas, 200.0, 100.0, WHITE);
draw_texture(&atlas, 300.0, 100.0, WHITE);

// This starts a NEW batch (different texture)
draw_texture(&other_tex, 400.0, 100.0, WHITE);
```

## Focus & Target Audience

- **Rapid prototypers** — Minimum code to get visuals on screen
- **Game jam developers** — Fast compilation, minimal setup, immediate results
- **Cross-platform developers** — Especially WASM/web deployment
- **Beginners** — Simple API hides complexity. No lifetime management, no trait implementations.
- **raylib/Processing users** — Similar "call functions, things appear" mental model

## Strong Points

| Strength | Details |
|----------|---------|
| **Minimal boilerplate** | 10 lines to a working game. No struct, trait, or config. |
| **Fast compilation** | ~16s clean build. Minimal dependency tree. |
| **WASM support** | First-class web deployment via miniquad's WebGL backend. |
| **Async loading** | `load_texture("path").await` is natural for asset loading. No callbacks or futures management. |
| **Automatic batching** | Transparent draw call batching. Good default performance without manual optimization. |
| **Cross-platform** | Windows, macOS, Linux, iOS, Android, WASM from one codebase. |
| **Subcrate modularity** | Particles, platformer physics, and tiled maps as optional subcrates. |
| **Built-in UI** | Immediate-mode UI for debug tools and simple game UI. |
| **Coroutine sequences** | `async/await` for sequential game logic (cutscenes, dialogs, loading screens). |
| **Input polling** | `is_key_pressed()` / `is_key_down()` — simple per-frame queries. No callback registration. |

## Weak Points

| Weakness | Details |
|----------|---------|
| **Global unsafe state** | Thread-local unsafe static. Violates Rust safety guarantees. Not `Send`/`Sync`. |
| **No retained state** | Immediate-mode means no persistent drawables. Every frame rebuilds from scratch. |
| **Limited audio** | Basic playback only. No mixing, effects, spatial audio. Feature-gated. |
| **No physics** | Platformer physics subcrate is minimal. No general-purpose physics engine. |
| **OpenGL ES 2.0 baseline** | miniquad targets GL ES 2.0 for compatibility. No compute shaders, limited GPU features. |
| **No scripting** | Pure Rust. Not suitable for non-programmer game designers. |
| **Single-threaded** | Global state requires single-thread execution. No parallelism. |
| **No scene management** | No built-in scenes, states, or transitions. |
| **Error handling** | Many functions return `Option` or panic. Less structured than ggez's `GameResult`. |
| **Unsafe everywhere** | Multiple `unsafe` blocks in core. Memory safety not guaranteed. |

## Things to Reimplement in Luna2D

### High Priority — Valuable Patterns

1. **Automatic Draw Batching** — macroquad's transparent batching of consecutive draw calls with the same state is excellent. Luna2D's draw command queue should batch automatically when possible.

2. **Input Polling API** — `is_key_pressed()` / `is_key_down()` / `is_key_released()` is simpler than callback-only input. Luna2D already has `luna.keyboard.isDown()` — ensure parity with `isPressed`/`isReleased` (one-frame edge detection).

3. **Async Asset Loading Pattern** — While Luna2D won't use Rust async, the concept of non-blocking asset loading is valuable. Consider `luna.graphics.newImage()` that returns immediately with a placeholder and loads in background.

4. **Subcrate Modularity** — macroquad's particles, platformer, and tiled as separate crates is a good model. Luna2D's tilemap, particle, and future modules should be independent crate features.

5. **Minimal Default Dependencies** — Keep the core small. Gate optional subsystems (gamepad, compute, AI) behind Cargo features.

### Medium Priority — Worth Studying

6. **Camera API Simplicity** — macroquad's camera is set-and-forget: `set_camera(&cam)` → all draws use it → `set_default_camera()` restores. Luna2D should have similar simplicity.

7. **Managed Texture GC** — Automatic cleanup of unreferenced textures each frame. Luna2D should ensure Lua-side texture handles properly release GPU resources.

8. **Built-in UI** — Simple immediate-mode UI for debug tools. Not a priority but useful for development.

### Lower Priority

9. **Storage API** — macroquad's cookie-based storage for WASM. Relevant for future web target.

10. **Coroutine Sequences** — Lua coroutines can provide similar sequential flow for cutscenes and loading screens.

## Things to Avoid

1. **Global Unsafe State** — macroquad's core design decision. Violates Rust's safety model. Luna2D correctly uses `Rc<RefCell<SharedState>>` instead.

2. **Immediate-Mode Only** — No retained state means expensive scenes must be rebuilt every frame. Luna2D's draw command queue with optional sprite batching is more efficient for complex scenes.

3. **No Error Handling** — macroquad panics or returns `Option` for many operations. Luna2D should always use `Result<T, E>` and never panic in library code.

4. **Single-Threaded Assumption** — macroquad enforces single-thread with `thread_assert::same_thread()`. Luna2D should be single-threaded for Lua but not architecturally prevent future threading.

5. **OpenGL ES 2.0 Baseline** — miniquad targets the lowest common GPU denominator. Luna2D's wgpu backend targets modern GPUs with compute shader support.

6. **No Structured Input** — macroquad's polling-only input with no callbacks means you can miss events. Luna2D should provide both polling AND callbacks (which it does).

7. **Macro-Based Main** — `#[macroquad::main]` hides the game loop behind a proc macro. Luna2D should keep the game loop explicit and visible (which it does via `ApplicationHandler`).

8. **Texture Handle Complexity** — Managed/ManagedWeak/Unmanaged variants with frame-level GC add complexity. Rust ownership + Lua GC integration is cleaner.

## Luna2D Integration Notes

macroquad represents the **extreme simplicity end** of the framework design spectrum. Key lessons:

| macroquad Choice | Luna2D Equivalent | Why |
|-----------------|-------------------|-----|
| Global unsafe state | `Rc<RefCell<SharedState>>` | Rust safety with Lua closure compatibility |
| Async main | `ApplicationHandler` game loop | winit integration, explicit loop control |
| Immediate-mode draw | DrawCommand queue | Allows batching, z-sorting, and deferred rendering |
| Polling-only input | Callbacks + polling | Both paradigms for maximum flexibility |
| miniquad (GL ES 2.0) | wgpu (modern GPUs) | Compute shaders, advanced rendering features |
| No scripting | Lua via mlua | Non-programmer-accessible game development |

What Luna2D should learn from macroquad:
1. **API simplicity matters** — `draw_rectangle(x, y, w, h, color)` is the gold standard for ergonomics
2. **Automatic batching is transparent** — Users shouldn't need to think about draw call optimization
3. **Fast compilation enables fast iteration** — Keep dependency count minimal
4. **Subcrates for optional features** — Don't bloat the core with niche modules
5. **Input polling is essential** — Not just callbacks, also frame-by-frame state queries

macroquad proves that a tiny, simple API can be extremely productive. Luna2D should strive for Love2D/macroquad-level simplicity in its Lua API while keeping Rust-level correctness underneath.
